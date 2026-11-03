# Batch 34: fitted() and residuals() on engine = "julia" fits with a structured
# relmat(), animal() or spatial() mean field return the conditional mean, as
# native fitted() does. DRModels.jl exports the per-row link-scale contribution
# of the field at its conditional (inner Laplace) mode and the mode itself; the
# R side rebuilds linkinv(linkfun(population mean) + eta_re).
#
# The first blocks are non-live (payload parsing, the rebuild for every link,
# the population-level fallback when no payload is present). The last blocks
# are live native-vs-Julia checks on shuffled-row fixtures, skipped unless Julia
# and DRM_JL_PATH are available. Tolerances fixed before the live runs:
#   fitted():    max |julia - native| / max |native| <= 1e-4
#   residuals(): max |julia - native| / max |native residual| <= 1e-4
# Emulated bug: the population-level value (modes at zero), which is what these
# routes returned before, must sit at least 100 times above that tolerance from
# native on every fixture (relative gap >= 1e-2). One fixture per route; no
# standard error, coverage, calibration or broad parity claim.

b34_fake_fit <- function(model_type, link, population, eta_re, residual_pop = NULL) {
  family <- switch(
    model_type,
    binomial = stats::binomial(link = link),
    poisson = stats::poisson(),
    gaussian = stats::gaussian(),
    NULL
  )
  structure(
    list(
      model = list(model_type = model_type),
      family = family,
      formula = bf(y ~ x),
      fitted = population,
      residuals = if (is.null(residual_pop)) rep(0, length(population)) else residual_pop,
      conditional_structured = if (is.null(eta_re)) {
        NULL
      } else {
        list(kind = "structured_eta_re_v1", eta_re = eta_re, modes = list(c(0.1, -0.2)))
      }
    ),
    class = "drmTMB_julia"
  )
}

test_that("structured conditional payload is parsed to plain vectors", {
  raw <- list(
    kind = "structured_eta_re_v1",
    eta_re = list(0.5, -0.25, 0),
    modes = list(list(1, 2), list(3))
  )
  plain <- drm_julia_conditional_structured_plain(raw)
  expect_identical(plain$kind, "structured_eta_re_v1")
  expect_identical(plain$eta_re, c(0.5, -0.25, 0))
  expect_identical(plain$modes, list(c(1, 2), 3))
  expect_null(drm_julia_conditional_structured_plain(NULL))
})

test_that("a failed conditional export warns and keeps the population-level value", {
  plain <- drm_julia_conditional_structured_plain(list(kind = "structured_eta_re_v1_failed"))
  expect_identical(plain, list(kind = "structured_eta_re_v1_failed"))
  population <- exp(c(-0.8, 0.2, 1.1))
  fit <- b34_fake_fit("poisson", "log", population, NULL)
  fit$conditional_structured <- plain
  expect_warning(
    value <- fitted(fit),
    "could not compute the conditional mode"
  )
  expect_equal(value, population, tolerance = 1e-12)
})

test_that("the conditional mean is linkinv(linkfun(population) + eta_re) for every link", {
  eta_re <- c(0.4, -0.3, 0.05, 0.9)
  eta0 <- c(-0.8, 0.2, 1.1, -1.5)
  cases <- list(
    list("gaussian", "identity", eta0, eta0 + eta_re),
    list("poisson", "log", exp(eta0), exp(eta0 + eta_re)),
    list("nbinom2", "log", exp(eta0), exp(eta0 + eta_re)),
    list("gamma", "log", exp(eta0), exp(eta0 + eta_re)),
    list("binomial", "logit", stats::plogis(eta0), stats::plogis(eta0 + eta_re)),
    list("binomial", "probit", stats::pnorm(eta0), stats::pnorm(eta0 + eta_re)),
    list("binomial", "cloglog", -expm1(-exp(eta0)), -expm1(-exp(eta0 + eta_re)))
  )
  for (case in cases) {
    fit <- b34_fake_fit(case[[1L]], case[[2L]], case[[3L]], eta_re)
    expect_equal(
      fitted(fit), case[[4L]], tolerance = 1e-12,
      info = paste(case[[1L]], case[[2L]])
    )
    # the response residual is re-based from the bridge residual y - population
    y <- case[[3L]] + 0.1
    fit$residuals <- y - case[[3L]]
    expect_equal(
      residuals(fit), y - case[[4L]], tolerance = 1e-12,
      info = paste(case[[1L]], case[[2L]], "residuals")
    )
  }
})

test_that("without a payload the population-level bridge slot is kept", {
  population <- c(1.5, 2.5, 0.5)
  fit <- b34_fake_fit("poisson", NULL, population, NULL, residual_pop = c(0.1, 0.2, 0.3))
  expect_identical(fitted(fit), population)
  expect_identical(residuals(fit), c(0.1, 0.2, 0.3))
})

test_that("a payload that does not match the fit is refused, not guessed", {
  fit <- b34_fake_fit("poisson", NULL, c(1, 2, 3), c(0.1, 0.2))
  expect_error(fitted(fit), "structured conditional payload")
  nonfinite <- b34_fake_fit("poisson", NULL, c(1, 2, 3), c(0.1, NA, 0.2))
  expect_error(fitted(nonfinite), "structured conditional payload")
  unsupported <- b34_fake_fit("beta", NULL, c(0.1, 0.2, 0.3), c(0.1, 0.2, 0.3))
  expect_error(fitted(unsupported), "structured conditional payload")
})

b34_live_setup <- function(.local_envir = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path, .local_envir = .local_envir)
  drm_test_local_julia_home(.local_envir = .local_envir)
}

b34_family <- function(family_type, link = "logit") {
  switch(
    family_type,
    gaussian = gaussian(),
    poisson = poisson(),
    nbinom2 = nbinom2(),
    gamma = Gamma(link = "log"),
    binomial = binomial(link = link)
  )
}

# Shuffled-row fixture: the data rows are in random order (so the first-seen
# group order differs from the factor level order), K has a non-unit diagonal,
# and spatial coordinates are named in factor-level order.
b34_fixture <- function(family_type, structure, slope, seed, link = "logit",
                        n_group = 30L, n_each = 12L) {
  set.seed(seed)
  id_levels <- paste0("g", seq_len(n_group))
  scale <- seq(0.7, 1.6, length.out = n_group)
  coords <- NULL
  if (identical(structure, "spatial")) {
    coords <- cbind(east = stats::rnorm(n_group), north = stats::rnorm(n_group))
    rownames(coords) <- id_levels
    distance <- as.matrix(stats::dist(coords))
    range <- stats::median(distance[upper.tri(distance)])
    K <- exp(-distance / range) + 1e-6 * diag(n_group)
  } else {
    K <- outer(scale, scale) *
      outer(seq_len(n_group), seq_len(n_group), function(i, j) 0.4^abs(i - j))
  }
  dimnames(K) <- list(id_levels, id_levels)
  z_group <- rep(c(-1, 1), length.out = n_group)
  u <- exp(-0.6 + 0.5 * z_group) * as.vector(t(chol(K)) %*% stats::rnorm(n_group))
  id_index <- sample(rep(seq_len(n_group), each = n_each))
  x <- stats::rnorm(length(id_index))
  dat <- data.frame(
    id = factor(id_levels[id_index], levels = id_levels),
    x = x, z = z_group[id_index]
  )
  loading <- if (slope) x else 1
  eta <- 0.3 + 0.2 * x + loading * u[id_index]
  dat$y <- switch(
    family_type,
    gaussian = eta + stats::rnorm(length(eta), 0, 0.5),
    poisson = stats::rpois(length(eta), exp(eta)),
    nbinom2 = stats::rnbinom(length(eta), size = 1 / 0.42^2, mu = exp(eta)),
    gamma = stats::rgamma(length(eta), shape = 1 / 0.35^2,
                          rate = (1 / 0.35^2) / exp(eta)),
    binomial = stats::rbinom(length(eta), 1L, switch(
      link,
      logit = stats::plogis(eta - 0.2),
      probit = stats::pnorm(eta - 0.2),
      cloglog = -expm1(-exp(eta - 0.2))
    ))
  )
  expect_false(identical(unique(as.character(dat$id)), id_levels))
  list(K = K, A = K, coords = coords, dat = dat, id_levels = id_levels)
}

b34_formula <- function(structure, slope, K, A, coords, Ainv = NULL) {
  lhs <- if (slope) "0 + x" else "1"
  term <- switch(
    structure,
    relmat = sprintf("relmat(%s | id, K = K)", lhs),
    animal = sprintf("animal(%s | id, A = A)", lhs),
    animalinv = sprintf("animal(%s | id, Ainv = Ainv)", lhs),
    spatial = sprintf("spatial(%s | id, coords = coords)", lhs)
  )
  level <- if (identical(structure, "animalinv")) "animal" else structure
  eval(str2lang(sprintf(
    "bf(y ~ x + %s, sd(id, level = \"%s\") ~ z)", term, level
  )))
}

# Returns the relative gaps so the caller can report them.
b34_compare <- function(julia, native, tol = 1e-4) {
  fn <- as.numeric(fitted(native))
  fj <- as.numeric(fitted(julia))
  rn <- as.numeric(residuals(native))
  rj <- as.numeric(residuals(julia))
  population <- as.numeric(julia$fitted)
  gap_fitted <- max(abs(fj - fn)) / max(abs(fn))
  gap_resid <- max(abs(rj - rn)) / max(abs(rn))
  gap_population <- max(abs(population - fn)) / max(abs(fn))
  expect_lt(gap_fitted, tol, label = "relative fitted gap")
  expect_lt(gap_resid, tol, label = "relative residual gap")
  # emulated bug: the old population-level value is far above the tolerance
  expect_gt(gap_population, 100 * tol, label = "population-level gap")
  expect_false(is.null(julia$conditional_structured))
  message(
    "B34 gaps: fitted ", signif(gap_fitted, 3), "; residuals ", signif(gap_resid, 3),
    "; population-level vs native ", signif(gap_population, 3)
  )
  invisible(c(fitted = gap_fitted, residuals = gap_resid, population = gap_population))
}

b34_routes <- list(
  list("gaussian", "relmat", FALSE, "logit"),
  list("gaussian", "animal", FALSE, "logit"),
  list("gaussian", "spatial", FALSE, "logit"),
  list("gaussian", "relmat", TRUE, "logit"),
  list("poisson", "relmat", FALSE, "logit"),
  list("poisson", "animal", FALSE, "logit"),
  list("poisson", "spatial", FALSE, "logit"),
  list("poisson", "relmat", TRUE, "logit"),
  list("nbinom2", "relmat", FALSE, "logit"),
  list("nbinom2", "animal", FALSE, "logit"),
  list("nbinom2", "spatial", FALSE, "logit"),
  list("nbinom2", "relmat", TRUE, "logit"),
  list("gamma", "relmat", FALSE, "logit"),
  list("gamma", "animal", FALSE, "logit"),
  list("gamma", "spatial", FALSE, "logit"),
  list("gamma", "relmat", TRUE, "logit"),
  list("binomial", "relmat", FALSE, "logit"),
  list("binomial", "animal", FALSE, "logit"),
  list("binomial", "spatial", FALSE, "logit"),
  list("binomial", "relmat", TRUE, "logit"),
  list("binomial", "relmat", FALSE, "probit"),
  list("binomial", "animal", FALSE, "cloglog"),
  list("poisson", "animalinv", FALSE, "logit"),
  list("binomial", "animalinv", FALSE, "logit")
)

for (b34_route in b34_routes) {
  local({
    route <- b34_route
    family_type <- route[[1L]]
    structure <- route[[2L]]
    slope <- route[[3L]]
    link <- route[[4L]]
    label <- paste(
      family_type, structure, if (slope) "slope" else "intercept",
      if (identical(family_type, "binomial")) link else ""
    )
    test_that(paste("Julia fitted() and residuals() are conditional:", label), {
      b34_live_setup()
      seed <- 20261301L + sum(utf8ToInt(label))
      fx <- b34_fixture(family_type, structure, slope, seed, link)
      K <- fx$K
      A <- fx$A
      coords <- fx$coords
      Ainv <- solve(K)
      dimnames(Ainv) <- dimnames(K)
      form <- b34_formula(structure, slope, K, A, coords, Ainv)
      fam <- b34_family(family_type, link)
      native <- drmTMB(form, family = fam, data = fx$dat, engine = "tmb",
                       control = drm_control(se = FALSE))
      julia <- drmTMB(form, family = fam, data = fx$dat, engine = "julia")
      b34_compare(julia, native)
    })
  })
}

test_that("exported modes are in first-seen group order and match the row contributions", {
  b34_live_setup()
  for (family_type in c("gaussian", "poisson")) {
    fx <- b34_fixture(family_type, "relmat", FALSE, 20261340L)
    K <- fx$K
    form <- b34_formula("relmat", FALSE, K, NULL, NULL)
    julia <- drmTMB(form, family = b34_family(family_type), data = fx$dat,
                    engine = "julia")
    payload <- julia$conditional_structured
    labels <- as.character(fx$dat$id)
    first_seen <- unique(labels)
    expect_length(payload$modes, 1L)
    mode <- payload$modes[[1L]]
    expect_length(mode, length(first_seen))
    # group SDs by level name (the fitted sd(id, relmat) multiplier)
    sd_by_level <- predict(julia, dpar = "sd_relmat(id)")
    expect_true(all(first_seen %in% names(sd_by_level)))
    expected <- unname(sd_by_level[labels] * mode[match(labels, first_seen)])
    expect_equal(payload$eta_re, expected, tolerance = 1e-6, info = family_type)
    # emulated bug: modes read in factor-level order are far from the right ones
    wrong <- unname(sd_by_level[labels] * mode[match(labels, fx$id_levels)])
    expect_gt(max(abs(payload$eta_re - wrong)), 1e-2, label = "wrong-order gap")
  }
})

# Binomial animal q2 (correlated intercept and slope, each with an SD formula).
# Native TMB reaches a different optimum on this fixture (log-likelihood
# differs), so the comparator is an independent base-R dense Newton solve of the
# inner problem at the JULIA estimates, with a hand-built Kronecker prior; it
# calls no drmTMB or DRModels.jl code.
test_that("Julia Binomial animal q2 fitted() equals the dense conditional-mode oracle", {
  b34_live_setup()
  set.seed(20261401L)
  G <- 40L
  m <- 20L
  ids <- paste0("g", seq_len(G))
  sc <- seq(0.8, 1.5, length.out = G)
  A <- outer(sc, sc) * outer(seq_len(G), seq_len(G), function(i, j) 0.4^abs(i - j))
  dimnames(A) <- list(ids, ids)
  L <- t(chol(A))
  rho <- 0.4
  b0 <- as.vector(L %*% stats::rnorm(G))
  b1 <- rho * b0 + sqrt(1 - rho^2) * as.vector(L %*% stats::rnorm(G))
  z0g <- rep(c(-1, 1), length.out = G)
  z1g <- rep(c(1, -1), length.out = G)
  s0 <- exp(-0.3 + 0.3 * z0g)
  s1 <- exp(-0.5 + 0.3 * z1g)
  idx <- sample(rep(seq_len(G), each = m))
  x <- stats::rnorm(length(idx))
  d <- data.frame(id = factor(ids[idx], levels = ids), x = x,
                  z0 = z0g[idx], z1 = z1g[idx])
  eta <- -0.2 + 0.3 * x + s0[idx] * b0[idx] + x * s1[idx] * b1[idx]
  d$y <- stats::rbinom(length(eta), 1L, stats::plogis(eta))
  expect_false(identical(unique(as.character(d$id)), ids))
  form <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0,
    sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1
  )
  julia <- drmTMB(form, family = stats::binomial(), data = d, engine = "julia")
  expect_false(is.null(julia$conditional_structured))
  expect_length(julia$conditional_structured$modes, 2L)

  labels <- as.character(d$id)
  first_seen <- unique(labels)
  gi <- match(labels, first_seen)
  Qa <- solve(A[first_seen, first_seen])
  cf <- julia$coefficients
  s0g <- exp(cf[[2L]][1L] + cf[[2L]][2L] * tapply(d$z0, gi, function(v) v[1L]))
  s1g <- exp(cf[[3L]][1L] + cf[[3L]][2L] * tapply(d$z1, gi, function(v) v[1L]))
  rho_hat <- as.numeric(julia$bridge$dpars$correlation[1L])
  Qj <- kronecker(Qa, solve(matrix(c(1, rho_hat, rho_hat, 1), 2L)))
  eta0 <- cf[[1L]][1L] + cf[[1L]][2L] * d$x
  b <- rep(0, 2L * G)
  for (iter in 1:200) {
    e <- eta0 + s0g[gi] * b[2L * gi - 1L] + d$x * s1g[gi] * b[2L * gi]
    p <- stats::plogis(e)
    d1 <- p - d$y
    d2 <- p * (1 - p)
    grad <- as.vector(Qj %*% b)
    H <- Qj
    for (i in seq_along(gi)) {
      j0 <- 2L * gi[i] - 1L
      j1 <- 2L * gi[i]
      l0 <- s0g[gi[i]]
      l1 <- d$x[i] * s1g[gi[i]]
      grad[j0] <- grad[j0] + l0 * d1[i]
      grad[j1] <- grad[j1] + l1 * d1[i]
      H[j0, j0] <- H[j0, j0] + d2[i] * l0^2
      H[j0, j1] <- H[j0, j1] + d2[i] * l0 * l1
      H[j1, j0] <- H[j1, j0] + d2[i] * l0 * l1
      H[j1, j1] <- H[j1, j1] + d2[i] * l1^2
    }
    step <- solve(H, grad)
    b <- b - step
    if (max(abs(step)) < 1e-12) break
  }
  oracle <- as.numeric(stats::plogis(
    eta0 + s0g[gi] * b[2L * gi - 1L] + d$x * s1g[gi] * b[2L * gi]
  ))
  fj <- as.numeric(fitted(julia))
  gap_fitted <- max(abs(oracle - fj)) / max(abs(oracle))
  gap_population <- max(abs(oracle - as.numeric(julia$fitted))) / max(abs(oracle))
  modes <- julia$conditional_structured$modes
  gap_modes <- max(
    max(abs(modes[[1L]] - b[seq(1L, 2L * G, 2L)])),
    max(abs(modes[[2L]] - b[seq(2L, 2L * G, 2L)]))
  )
  expect_lt(gap_fitted, 1e-4)
  expect_lt(gap_modes, 1e-4)
  expect_gt(gap_population, 1e-2)
  # residuals are y - fitted on the proportion scale
  expect_equal(as.numeric(residuals(julia)), d$y - oracle, tolerance = 1e-4)
  message(
    "B34 q2 oracle gaps: fitted ", signif(gap_fitted, 3), "; modes ",
    signif(gap_modes, 3), "; population-level vs oracle ", signif(gap_population, 3)
  )
})
