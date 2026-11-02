# Intercept-plus-slope (q = 2) random-effect SD regression with
# miss_control(response = "include").
#
# Routes covered
#   * Gaussian ordinary correlated q2, y ~ x + (1 + x | id), one SD formula per
#     coefficient (sd(id, coef = "(Intercept)") and sd(id, coef = "x")).
#   * Poisson, NB2 and Gamma(log) animal q2, animal(1 + x | id, A = A) with one
#     sd(id, level = "animal", dpar = "mu", coef = ...) formula per coefficient.
#     NB2 and Gamma also have the labelled form animal(1 + x | p | id, A = A)
#     with a cross-coefficient correlation (Poisson labelled animal with SDs is
#     refused for a structural reason that is independent of include).
#
# Claim. A response coded NA contributes no likelihood term: the C++ observed_y
# mask removes only that row's density, and the q2 latent prior (independent
# fields, or R (x) A when labelled) is applied to every node whether or not it
# has an observed row. So (a) when every group keeps one observed row the
# include fit equals the complete-case fit on the observed rows; (b) when a
# whole group is NA the include fit keeps that group's nodes under the prior
# and must match an oracle that keeps the prior term. A prior-only block of a
# Gaussian field integrates out exactly, so in (b) the include fit also equals
# the complete-case fit that never saw the group (checked, not assumed).
#
# Oracles (written here, sharing no code with the engine).
#   Gaussian: exact marginal. Each group's observed response vector is normal
#   with covariance Z S_g Z' + sigma^2 I, S_g = D_g R D_g. A group with no
#   observed row contributes log 1 = 0, which is the prior-keeping answer.
#   Poisson, NB2, Gamma: dense Laplace marginal over the 2G latent vector
#   u ~ N(0, R (x) A), eta_i = eta0_i + tau0[g] u0[g] + x_i tau1[g] u1[g],
#   scored on observed rows only:
#     ll(u*) - u*' S^-1 u* / 2 - log|S| / 2 - log|H| / 2,
#     H = D' diag(info) D + S^-1.
#   Empty groups keep their rows in D as zeros, so they keep the prior term.
#   The fixed part, SD surfaces, sigma and rho are read from the fit; the
#   latent mode is re-solved by Newton iterations in R.
#
# Tolerances were fixed before the first run and none was loosened:
# include vs complete-case logLik 1e-8, oracle 1e-6 relative, bug-sensitivity
# gap > 0.05.

q2i_n_id <- 24L
q2i_n_each <- 8L
q2i_levels <- sprintf("id%02d", seq_len(q2i_n_id))

# Covariance order differs from data order (data runs in reverse), so a wrong
# alignment of rows to nodes would move the oracle.
q2i_make_A <- function() {
  base <- 1.6 * 0.45^abs(outer(seq_len(q2i_n_id), seq_len(q2i_n_id), `-`))
  dimnames(base) <- list(q2i_levels, q2i_levels)
  order <- c(seq.int(1L, q2i_n_id, by = 2L), seq.int(2L, q2i_n_id, by = 2L))
  base[order, order]
}

q2i_group_covariates <- function() {
  list(
    s0 = stats::setNames(rep(c(-1, 1), length.out = q2i_n_id), q2i_levels),
    s1 = stats::setNames(rep(c(1, -1, -1, 1), length.out = q2i_n_id),
                         q2i_levels)
  )
}

# Roughly 20 percent of rows NA in a regular pattern; na_groups (positions in
# q2i_levels) are made entirely NA.
q2i_mask <- function(dat, na_groups) {
  dat$y[seq_len(nrow(dat)) %% 5L == 2L] <- NA
  for (g in na_groups) dat$y[as.character(dat$id) == q2i_levels[g]] <- NA
  dat
}

q2i_fixture <- function(family, labelled = FALSE, seed = 20261102L,
                        na_groups = integer(0)) {
  set.seed(seed)
  cv <- q2i_group_covariates()
  data_levels <- rev(q2i_levels)
  id <- factor(rep(data_levels, each = q2i_n_each), levels = data_levels)
  x <- rep(seq(-1, 1, length.out = q2i_n_each), times = q2i_n_id)
  tau0 <- exp(log(0.5) + 0.35 * cv$s0)
  tau1 <- exp(log(0.35) - 0.35 * cv$s1)
  A <- NULL
  rho <- 0
  if (identical(family, "gaussian")) {
    rho <- 0.4
    z0 <- stats::rnorm(q2i_n_id)
    z1 <- stats::rnorm(q2i_n_id)
    u0 <- stats::setNames(z0, q2i_levels)
    u1 <- stats::setNames(rho * z0 + sqrt(1 - rho^2) * z1, q2i_levels)
  } else {
    A <- q2i_make_A()
    lev <- rownames(A)
    L <- t(chol(A))
    if (labelled) rho <- 0.5
    z0 <- as.vector(L %*% stats::rnorm(q2i_n_id))
    z1 <- as.vector(L %*% stats::rnorm(q2i_n_id))
    u0 <- stats::setNames(z0, lev)
    u1 <- stats::setNames(rho * z0 + sqrt(1 - rho^2) * z1, lev)
  }
  gid <- as.character(id)
  eta <- 0.3 + 0.3 * x + tau0[gid] * u0[gid] + x * tau1[gid] * u1[gid]
  y <- switch(
    family,
    gaussian = eta + 0.5 * stats::rnorm(length(eta)),
    poisson = stats::rpois(length(eta), exp(eta)),
    nbinom2 = stats::rnbinom(length(eta), size = 1 / 0.4^2, mu = exp(eta)),
    gamma = stats::rgamma(length(eta), shape = 6, rate = 6 / exp(eta))
  )
  dat <- data.frame(
    y = y, x = x, id = id, s0 = as.numeric(cv$s0[gid]),
    s1 = as.numeric(cv$s1[gid])
  )
  list(data = q2i_mask(dat, na_groups), A = A, family = family,
       labelled = labelled, rho = rho)
}

q2i_formula <- function(fx) {
  A <- fx$A  # found by animal(..., A = A) through the formula environment
  env <- environment()
  if (identical(fx$family, "gaussian")) {
    return(bf(
      y ~ x + (1 + x | id), sigma ~ 1,
      sd(id, coef = "(Intercept)") ~ s0,
      sd(id, coef = "x") ~ s1
    ))
  }
  term <- if (fx$labelled) {
    "animal(1 + x | p | id, A = A)"
  } else {
    "animal(1 + x | id, A = A)"
  }
  mu_formula <- stats::as.formula(paste("y ~ x +", term))
  environment(mu_formula) <- env
  sd0 <- sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ s0
  sd1 <- sd(id, level = "animal", dpar = "mu", coef = "x") ~ s1
  if (identical(fx$family, "poisson")) {
    bf(mu_formula, sd0, sd1)
  } else {
    bf(mu_formula, sigma ~ 1, sd0, sd1)
  }
}

q2i_family <- function(family) {
  switch(family, gaussian = stats::gaussian(), poisson = stats::poisson(),
         nbinom2 = nbinom2(), gamma = stats::Gamma(link = "log"))
}

q2i_fit <- function(fx, include = TRUE) {
  dat <- fx$data
  if (!include) dat <- dat[!is.na(dat$y), , drop = FALSE]
  drmTMB(
    q2i_formula(fx), family = q2i_family(fx$family), data = dat,
    missing = if (include) miss_control(response = "include") else miss_control(),
    control = drm_control(se = FALSE)
  )
}

q2i_cache <- new.env(parent = emptyenv())
q2i_cached <- function(fx_args, include) {
  key <- paste(fx_args$family, fx_args$labelled, include,
               paste(fx_args$na_groups, collapse = "-"))
  if (is.null(q2i_cache[[key]])) {
    fx <- do.call(q2i_fixture, fx_args)
    q2i_cache[[key]] <- list(fx = fx, fit = q2i_fit(fx, include = include))
  }
  q2i_cache[[key]]
}

# Per-coefficient SD surfaces by group, taken from the fitted coefficients.
q2i_tau <- function(fit, fx) {
  keys <- if (identical(fx$family, "gaussian")) {
    c('sd(id, coef = "(Intercept)")', 'sd(id, coef = "x")')
  } else {
    c('sd_animal(id, dpar = "mu", coef = "(Intercept)")',
      'sd_animal(id, dpar = "mu", coef = "x")')
  }
  cv <- q2i_group_covariates()
  b0 <- coef(fit, keys[[1L]])
  b1 <- coef(fit, keys[[2L]])
  list(
    tau0 = exp(b0[[1L]] + b0[[2L]] * cv$s0),
    tau1 = exp(b1[[1L]] + b1[[2L]] * cv$s1)
  )
}

q2i_rho <- function(fit, fx) {
  if (identical(fx$family, "gaussian")) {
    return(unname(fit$corpars$mu[[1L]]))
  }
  if (fx$labelled) unname(fit$corpars$animal[[1L]]) else 0
}

q2i_gaussian_oracle <- function(fx, fit, swap_sd = FALSE) {
  dat <- fx$data
  tau <- q2i_tau(fit, fx)
  if (swap_sd) tau <- list(tau0 = tau$tau1, tau1 = tau$tau0)
  beta <- coef(fit, "mu")
  sigma <- exp(coef(fit, "sigma")[[1L]])
  rho <- q2i_rho(fit, fx)
  R <- matrix(c(1, rho, rho, 1), 2L, 2L)
  total <- 0
  for (g in q2i_levels) {
    rows <- which(as.character(dat$id) == g & !is.na(dat$y))
    if (length(rows) == 0L) next  # an empty group integrates to one
    x <- dat$x[rows]
    Z <- cbind(1, x)
    D <- diag(c(tau$tau0[[g]], tau$tau1[[g]]))
    covariance <- Z %*% (D %*% R %*% D) %*% t(Z) + diag(sigma^2, length(rows))
    resid <- dat$y[rows] - (beta[[1L]] + beta[[2L]] * x)
    chol_factor <- chol(covariance)
    white <- backsolve(chol_factor, resid, transpose = TRUE)
    total <- total - 0.5 * length(rows) * log(2 * pi) -
      sum(log(diag(chol_factor))) - 0.5 * sum(white^2)
  }
  total
}

q2i_laplace_oracle <- function(fx, fit, na_as_one = FALSE, swap_sd = FALSE) {
  dat <- fx$data
  A <- fx$A
  lev <- rownames(A)
  tau <- q2i_tau(fit, fx)
  tau0 <- tau$tau0[lev]
  tau1 <- tau$tau1[lev]
  if (swap_sd) {
    tmp <- tau0
    tau0 <- tau1
    tau1 <- tmp
  }
  rho <- q2i_rho(fit, fx)
  mu_coef <- coef(fit, "mu")
  eta0 <- as.numeric(mu_coef[["(Intercept)"]] + mu_coef[["x"]] * dat$x)
  disp <- if (identical(fx$family, "poisson")) {
    NA_real_
  } else {
    exp(coef(fit, "sigma")[["(Intercept)"]])
  }
  y <- dat$y
  observed <- if (na_as_one) rep(TRUE, nrow(dat)) else !is.na(y)
  y[is.na(y)] <- 1
  n <- nrow(dat)
  G <- length(lev)
  g <- match(as.character(dat$id), lev)
  D <- matrix(0, n, 2L * G)
  D[cbind(seq_len(n), g)] <- tau0[g]
  D[cbind(seq_len(n), G + g)] <- dat$x * tau1[g]
  R <- matrix(c(1, rho, rho, 1), 2L, 2L)
  Sigma <- kronecker(R, A)
  Sinv <- solve(Sigma)
  logdet_S <- as.numeric(determinant(Sigma, logarithm = TRUE)$modulus)
  parts <- function(u) {
    eta <- eta0 + as.vector(D %*% u)
    mu <- exp(eta)
    switch(
      fx$family,
      poisson = list(
        ll = sum(stats::dpois(y[observed], mu[observed], log = TRUE)),
        score = (y - mu) * observed,
        info = mu * observed
      ),
      nbinom2 = {
        size <- 1 / disp^2
        list(
          ll = sum(stats::dnbinom(y[observed], size = size, mu = mu[observed],
                                  log = TRUE)),
          score = (y - mu) * size / (size + mu) * observed,
          info = size * mu * (size + y) / (size + mu)^2 * observed
        )
      },
      gamma = {
        shape <- 1 / disp^2
        list(
          ll = sum(stats::dgamma(y[observed], shape = shape,
                                 rate = shape / mu[observed], log = TRUE)),
          score = shape * (y / mu - 1) * observed,
          info = shape * y / mu * observed
        )
      }
    )
  }
  objective <- function(u) parts(u)$ll - 0.5 * sum(u * (Sinv %*% u))
  hess <- function(u) crossprod(D, parts(u)$info * D) + Sinv
  u <- rep(0, 2L * G)
  for (iter in seq_len(300L)) {
    p <- parts(u)
    grad <- as.vector(crossprod(D, p$score)) - as.vector(Sinv %*% u)
    step <- as.vector(solve(hess(u), grad))
    old <- objective(u)
    s <- 1
    while (objective(u + s * step) < old - 1e-12 && s > 1e-8) s <- s / 2
    u <- u + s * step
    if (max(abs(s * step)) < 1e-12) break
  }
  p <- parts(u)
  stopifnot(max(abs(as.vector(crossprod(D, p$score)) -
                      as.vector(Sinv %*% u))) < 1e-7)
  logdet_H <- as.numeric(determinant(hess(u), logarithm = TRUE)$modulus)
  objective(u) - 0.5 * logdet_S - 0.5 * logdet_H
}

q2i_oracle <- function(fx, fit, ...) {
  if (identical(fx$family, "gaussian")) {
    q2i_gaussian_oracle(fx, fit, swap_sd = isTRUE(list(...)$swap_sd))
  } else {
    q2i_laplace_oracle(fx, fit, ...)
  }
}

q2i_cases <- list(
  list(family = "gaussian", labelled = FALSE),
  list(family = "poisson", labelled = FALSE),
  list(family = "nbinom2", labelled = FALSE),
  list(family = "nbinom2", labelled = TRUE),
  list(family = "gamma", labelled = FALSE),
  list(family = "gamma", labelled = TRUE)
)
q2i_label <- function(case) {
  paste(case$family, if (case$labelled) "labelled" else "unlabelled")
}

test_that("q2 include equals complete-case and the oracle when no group is wholly missing", {
  skip_on_cran()
  for (case in q2i_cases) {
    info <- q2i_label(case)
    inc <- q2i_cached(c(case, list(na_groups = integer(0))), TRUE)
    cc <- q2i_cached(c(case, list(na_groups = integer(0))), FALSE)
    fx <- inc$fx
    fit <- inc$fit
    expect_identical(fit$missing_data$response_policy, "include", info = info)
    expect_identical(fit$opt$convergence, 0L, info = info)
    expect_identical(cc$fit$opt$convergence, 0L, info = info)
    n_obs <- sum(!is.na(fx$data$y))
    expect_lt(n_obs, nrow(fx$data))
    expect_identical(as.integer(nobs(fit)), n_obs, info = info)
    expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(cc$fit)),
                 tolerance = 1e-8, info = info)
    expect_equal(unname(coef(fit, "mu")), unname(coef(cc$fit, "mu")),
                 tolerance = 1e-6, info = info)
    for (key in setdiff(names(coef(fit)), "mu")) {
      expect_equal(unname(coef(fit, key)), unname(coef(cc$fit, key)),
                   tolerance = 1e-6, info = paste(info, key))
    }
    oracle <- q2i_oracle(fx, fit)
    expect_equal(as.numeric(logLik(fit)), oracle,
                 tolerance = 1e-6, info = info)
    # The oracle can disagree with a wrong implementation.
    if (!identical(fx$family, "gaussian")) {
      expect_gt(abs(q2i_oracle(fx, fit, na_as_one = TRUE) - oracle), 0.05)
    }
    expect_gt(abs(q2i_oracle(fx, fit, swap_sd = TRUE) - oracle), 0.05)
    if (isTRUE(case$labelled) || identical(fx$family, "gaussian")) {
      expect_gt(abs(q2i_rho(fit, fx)), 0)
    }
  }
})

test_that("q2 include gives finite predictions for NA rows and every group SD", {
  skip_on_cran()
  for (case in q2i_cases) {
    info <- q2i_label(case)
    inc <- q2i_cached(c(case, list(na_groups = integer(0))), TRUE)
    fx <- inc$fx
    fit <- inc$fit
    mu_hat <- predict(fit, dpar = "mu")
    expect_length(mu_hat, nrow(fx$data))
    expect_true(all(is.finite(mu_hat)), info = info)
    tau <- q2i_tau(fit, fx)
    expect_true(all(is.finite(c(tau$tau0, tau$tau1)) &
                      c(tau$tau0, tau$tau1) > 0), info = info)
  }
})

test_that("q2 include with two wholly missing groups keeps the prior term", {
  skip_on_cran()
  na_groups <- c(5L, 17L)
  for (case in q2i_cases) {
    info <- q2i_label(case)
    args <- c(case, list(na_groups = na_groups))
    inc <- q2i_cached(args, TRUE)
    cc <- q2i_cached(args, FALSE)
    fx <- inc$fx
    fit <- inc$fit
    for (g in na_groups) {
      expect_true(all(is.na(fx$data$y[as.character(fx$data$id) ==
                                        q2i_levels[g]])))
    }
    expect_identical(fit$opt$convergence, 0L, info = info)
    expect_identical(as.integer(nobs(fit)), sum(!is.na(fx$data$y)), info = info)
    oracle <- q2i_oracle(fx, fit)
    expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6, info = info)
    # A wholly missing group integrates out of a Gaussian prior block.
    expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(cc$fit)),
                 tolerance = 1e-8, info = info)
    # Every group, including the wholly missing ones, keeps a finite SD.
    tau <- q2i_tau(fit, fx)
    expect_true(all(is.finite(c(tau$tau0, tau$tau1))), info = info)
    if (!identical(fx$family, "gaussian")) {
      expect_gt(abs(q2i_oracle(fx, fit, na_as_one = TRUE) - oracle), 0.05)
    }
    expect_gt(abs(q2i_oracle(fx, fit, swap_sd = TRUE) - oracle), 0.05)
  }
})

test_that("q2 include fences stay refused with message patterns", {
  skip_on_cran()
  inc <- miss_control(response = "include")
  cv <- q2i_group_covariates()
  fx <- q2i_fixture("poisson")
  A <- fx$A
  K <- A
  d <- fx$data
  d$zi_dummy <- 1
  sd_a <- function(coef, rhs, level = "animal") {
    stats::as.formula(sprintf(
      'sd(id, level = "%s", dpar = "mu", coef = "%s") ~ %s', level, coef, rhs
    ))
  }
  a0 <- sd_a("(Intercept)", "s0")
  a1 <- sd_a("x", "s1")
  r0 <- sd_a("(Intercept)", "s0", "relmat")
  r1 <- sd_a("x", "s1", "relmat")

  # Poisson: relmat q2, zero-inflated animal q2, labelled animal q2.
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), r0, r1),
           family = stats::poisson(), data = d, missing = inc),
    "complete\\s+responses"
  )
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | id, A = A), zi ~ 1, a0, a1),
           family = stats::poisson(), data = d, missing = inc),
    "complete\\s+responses"
  )
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | p | id, A = A), a0, a1),
           family = stats::poisson(), data = d, missing = inc),
    "one\\s+structured\\s+coefficient"
  )

  # NB2: relmat q2 and zero-inflated animal q2.
  fx_nb <- q2i_fixture("nbinom2")
  d_nb <- fx_nb$data
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1, r0, r1),
           family = nbinom2(), data = d_nb, missing = inc),
    "requires\\s+complete\\s+data"
  )
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | id, A = A), sigma ~ 1, zi ~ 1, a0, a1),
           family = nbinom2(), data = d_nb, missing = inc),
    "requires\\s+complete\\s+data|zero|inflat"
  )

  # Gamma: relmat q2 and one-sided animal SD formula.
  fx_g <- q2i_fixture("gamma")
  d_g <- fx_g$data
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1, r0, r1),
           family = stats::Gamma(link = "log"), data = d_g, missing = inc),
    "requires\\s+complete\\s+responses"
  )
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | id, A = A), sigma ~ 1, a0),
           family = stats::Gamma(link = "log"), data = d_g, missing = inc),
    "requires\\s+complete\\s+responses"
  )

  # Admitted shapes build under include, and without include the default drop
  # policy is unchanged (NA rows dropped).
  fit_default <- drmTMB(
    bf(y ~ x + animal(1 + x | id, A = A), a0, a1),
    family = stats::poisson(), data = d, control = drm_control(se = FALSE)
  )
  expect_identical(as.integer(nobs(fit_default)), sum(!is.na(d$y)))
})
