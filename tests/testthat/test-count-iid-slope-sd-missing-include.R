# Poisson and NB2 SD regression with miss_control(response = "include") for
# two shapes that the structured-intercept admission (batch 21) left refused:
#
#   (iid)   one ordinary intercept plus one structured intercept, each with its
#           own SD formula:
#             y ~ x + <provider>(1 | id, ...) + (1 | site)
#             sd(id, level = <level>) ~ z_id;  sd(site) ~ z_site
#           providers: relmat, animal, phylo.
#   (slope) a structured slope-only term with its own SD formula:
#             y ~ x + <provider>(0 + x | id, ...);  sd(id, level = <level>) ~ z
#           providers: relmat (K and Q), animal (A, Ainv and pedigree), phylo,
#           spatial.
#
# Claim. A response coded NA contributes no likelihood term: the C++ observed_y
# mask drops only that row's density, and every latent node (structured and
# ordinary) keeps its Gaussian prior. So (a) when no group is wholly missing the
# include fit equals the complete-case fit on the observed rows to 1e-8;
# (b) when a structured group is wholly NA its node stays inside the latent
# vector under the prior, and the include fit must match an oracle that keeps
# that prior term. An empty node is a prior-only Gaussian block, so it also
# integrates out exactly and the complete-case fit agrees (measured, not
# assumed; the oracle is the primary check). NA rows still get predictions.
#
# Oracle (independent of drmTMB's likelihood): a dense Laplace marginal over
# the stacked latent vector f = (u, v), u ~ N(0, Sigma) over the G structured
# nodes and v ~ N(0, I) over the S site nodes (absent for the slope shape),
#   eta_i = eta0_i + J[i, ] f,
#   J[i, g]     = tau_g * (x_i for the slope shape, 1 otherwise),
#   J[i, G + s] = tau_site_s,
# scored only on observed rows, with the fixed part and the SD surfaces taken
# from the fit:  ll(f*) - f*' P f* / 2 - log|Sigma_full| / 2 - log|H| / 2,
# H = J' diag(info) J + P, P = blockdiag(Sigma^-1, I). Empty groups keep their
# column, so they keep the prior term.
# Disclosure: for phylo and spatial, Sigma is built with
# drmTMB:::drm_phylo_tip_covariance and drmTMB:::drm_spatial_coords_precision,
# which are part of what is under test only through name alignment (the data
# order is deliberately different from the covariance order).
#
# Tolerances were fixed before the first run and none was loosened:
# include vs complete-case logLik 1e-8, oracle 1e-6 (relative), bug-sensitivity
# gap > 0.05.

cis_levels <- function(n_id) sprintf("id%02d", seq_len(n_id))

cis_make_sigma <- function(kind, n_id, seed) {
  lev <- cis_levels(n_id)
  set.seed(seed)
  if (identical(kind, "phylo")) {
    tree <- ape::rcoal(n_id)
    tree$tip.label <- sample(lev)
    return(list(Sigma = drmTMB:::drm_phylo_tip_covariance(tree), tree = tree,
                coords = NULL))
  }
  if (identical(kind, "spatial")) {
    theta <- seq(0, 2 * pi, length.out = n_id + 1L)[-1L]
    ring <- data.frame(x = cos(theta), y = sin(theta), row.names = lev)
    coords <- ring[sample(lev), , drop = FALSE]
    P <- as.matrix(drmTMB:::drm_spatial_coords_precision(
      coords, site = lev, group = "id"
    )$precision)[lev, lev]
    return(list(Sigma = solve(P), tree = NULL, coords = coords))
  }
  base <- 1.6 * 0.45^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(base) <- list(lev, lev)
  order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  list(Sigma = base[order, order], tree = NULL, coords = NULL)
}

cis_spec <- list(
  relmat_K = list(kind = "relmat", level = "relmat",
                  term = "relmat(%s | id, K = K)"),
  relmat_Q = list(kind = "relmat", level = "relmat",
                  term = "relmat(%s | id, Q = Q)"),
  animal_A = list(kind = "animal", level = "animal",
                  term = "animal(%s | id, A = K)"),
  animal_Ainv = list(kind = "animal", level = "animal",
                     term = "animal(%s | id, Ainv = Q)"),
  animal_ped = list(kind = "animal", level = "animal",
                    term = "animal(%s | id, pedigree = pedigree)"),
  phylo = list(kind = "phylo", level = "phylogenetic",
               term = "phylo(%s | id, tree = tree)"),
  spatial = list(kind = "spatial", level = "spatial",
                 term = "spatial(%s | id, coords = coords)")
)

# shape: "iid" (structured intercept + ordinary site intercept) or "slope"
# (structured slope-only). na_groups: structured group positions (in the
# covariance order) made wholly NA.
cis_fixture <- function(provider, family, shape, seed, n_id = 24L, n_each = 8L,
                        n_site = 12L, na_groups = integer(0)) {
  spec <- cis_spec[[provider]]
  if (identical(provider, "animal_ped")) {
    # Founders only: A = I, so the Sigma for the oracle is the identity.
    lev <- cis_levels(n_id)
    sm <- list(Sigma = diag(n_id), tree = NULL, coords = NULL)
    dimnames(sm$Sigma) <- list(lev, lev)
  } else {
    sm <- cis_make_sigma(spec$kind, n_id, seed)
  }
  Sigma <- sm$Sigma
  lev <- rownames(Sigma)
  set.seed(seed + 1L)
  z_group <- stats::setNames(
    seq(-1, 1, length.out = n_id)[sample.int(n_id)], lev
  )
  # The iid shape uses a steeper structured SD slope: with 0.5 the
  # reversed-SD sensitivity gap for poisson relmat was 0.02, below the 0.05 bar
  # declared before the first run (a fixture-power problem; the bar and every
  # agreement tolerance are unchanged).
  tau <- exp(log(0.5) + (if (identical(shape, "iid")) 0.9 else 0.5) * z_group)
  u <- stats::setNames(as.vector(t(chol(Sigma)) %*% stats::rnorm(n_id)), lev)
  data_levels <- rev(lev)
  id <- factor(rep(data_levels, each = n_each), levels = data_levels)
  n <- length(id)
  x <- stats::rnorm(n)
  site_levels <- sprintf("s%02d", seq_len(n_site))
  site <- factor(site_levels[c(seq_len(n_site),
                               sample.int(n_site, n - n_site, TRUE))],
                 levels = site_levels)
  z_site <- stats::setNames(
    seq(-1, 1, length.out = n_site)[sample.int(n_site)], site_levels
  )
  tau_site <- exp(log(0.5) + 0.5 * z_site)
  v <- stats::setNames(stats::rnorm(n_site) * tau_site, site_levels)
  struct <- tau[as.character(id)] * u[as.character(id)]
  eta <- 0.3 + 0.3 * x +
    if (identical(shape, "slope")) x * struct else struct + v[as.character(site)]
  y <- if (identical(family, "poisson")) {
    stats::rpois(n, exp(eta))
  } else {
    stats::rnbinom(n, size = 1 / 0.4^2, mu = exp(eta))
  }
  dat <- data.frame(y = y, x = x, id = id, site = site,
                    z = as.numeric(z_group[as.character(id)]),
                    z_id = as.numeric(z_group[as.character(id)]),
                    z_site = as.numeric(z_site[as.character(site)]))
  dat$y[seq_len(n) %% 5L == 2L] <- NA
  for (g in na_groups) dat$y[as.character(dat$id) == lev[g]] <- NA
  pedigree <- data.frame(id = lev, dam = NA_character_, sire = NA_character_,
                         stringsAsFactors = FALSE)
  Qmat <- solve(Sigma)
  dimnames(Qmat) <- dimnames(Sigma)
  list(data = dat, K = Sigma, Q = Qmat, tree = sm$tree, coords = sm$coords, pedigree = pedigree, Sigma = Sigma,
  site_levels = site_levels, provider = provider, family = family,
  shape = shape, spec = spec)
}

cis_formula <- function(fx, with_sd_site = TRUE, with_sd_struct = TRUE) {
  K <- fx$K
  Q <- fx$Q[rownames(fx$K), rownames(fx$K)]
  tree <- fx$tree
  coords <- fx$coords
  pedigree <- fx$pedigree
  slope <- identical(fx$shape, "slope")
  term <- sprintf(fx$spec$term, if (slope) "0 + x" else "1")
  rhs <- paste("y ~ x +", term, if (!slope) "+ (1 | site)")
  parts <- rhs
  if (with_sd_struct) {
    parts <- c(parts, sprintf('sd(id, level = "%s") ~ %s', fx$spec$level,
                              if (slope) "z" else "z_id"))
  }
  if (!slope && with_sd_site) parts <- c(parts, "sd(site) ~ z_site")
  if (identical(fx$family, "nbinom2")) {
    parts <- append(parts, "sigma ~ 1", after = 1L)
  }
  eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", "))))
}

cis_fit <- function(fx, include = TRUE, ...) {
  f <- cis_formula(fx, ...)
  dat <- if (include) fx$data else fx$data[!is.na(fx$data$y), , drop = FALSE]
  K <- fx$K
  Q <- fx$Q[rownames(fx$K), rownames(fx$K)]
  tree <- fx$tree
  pedigree <- fx$pedigree
  coords <- fx$coords
  if (!include && !is.null(coords)) {
    coords <- coords[rownames(coords) %in% as.character(dat$id), ,
                     drop = FALSE]
  }
  # The complete-case spatial fit needs one coordinate row per remaining id;
  # rebuild the formula so `coords` resolves to the restricted table.
  if (!include && !is.null(fx$coords)) {
    fx$coords <- coords
    f <- cis_formula(fx, ...)
  }
  drmTMB(
    f,
    family = if (identical(fx$family, "poisson")) stats::poisson() else nbinom2(),
    data = dat,
    missing = if (include) miss_control(response = "include") else miss_control(),
    control = drm_control(se = FALSE)
  )
}

cis_sd_names <- function(fit) {
  nm <- grep("^sd", names(fit$sdpars), value = TRUE)
  list(site = grep("site", nm, value = TRUE),
       struct = grep("site", nm, value = TRUE, invert = TRUE))
}

cis_oracle <- function(fx, fit, tau_group = NULL, na_as_zero = FALSE) {
  dat <- fx$data
  Sigma <- fx$Sigma
  lev <- rownames(Sigma)
  nm <- cis_sd_names(fit)
  slope <- identical(fx$shape, "slope")
  if (is.null(tau_group)) tau_group <- unname(predict(fit, dpar = nm$struct)[lev])
  stopifnot(length(tau_group) == length(lev), all(is.finite(tau_group)))
  tau_site <- if (!slope) unname(predict(fit, dpar = nm$site)[fx$site_levels])
  mu_coef <- coef(fit, "mu")
  eta0 <- as.numeric(mu_coef[["(Intercept)"]] + mu_coef[["x"]] * dat$x)
  size <- if (identical(fx$family, "nbinom2")) {
    1 / exp(coef(fit, "sigma")[["(Intercept)"]])^2
  }
  y <- dat$y
  observed <- if (na_as_zero) rep(TRUE, nrow(dat)) else !is.na(y)
  y[is.na(y)] <- 0
  n <- nrow(dat)
  G <- length(lev)
  S <- if (slope) 0L else length(fx$site_levels)
  g <- match(as.character(dat$id), lev)
  J <- matrix(0, n, G + S)
  J[cbind(seq_len(n), g)] <- tau_group[g] * (if (slope) dat$x else 1)
  if (!slope) {
    s <- match(as.character(dat$site), fx$site_levels)
    J[cbind(seq_len(n), G + s)] <- tau_site[s]
  }
  P <- matrix(0, G + S, G + S)
  P[seq_len(G), seq_len(G)] <- solve(Sigma)
  if (S > 0L) P[G + seq_len(S), G + seq_len(S)] <- diag(S)
  logdet_Sigma <- as.numeric(determinant(Sigma, logarithm = TRUE)$modulus)
  parts <- function(f) {
    eta <- eta0 + as.vector(J %*% f)
    mu <- exp(eta)
    if (is.null(size)) {
      list(ll = sum(stats::dpois(y[observed], mu[observed], log = TRUE)),
           score = (y - mu) * observed, info = mu * observed)
    } else {
      list(ll = sum(stats::dnbinom(y[observed], size = size, mu = mu[observed],
                                   log = TRUE)),
           score = (y - mu) * size / (size + mu) * observed,
           info = size * mu * (size + y) / (size + mu)^2 * observed)
    }
  }
  objective <- function(f) parts(f)$ll - 0.5 * sum(f * (P %*% f))
  hess <- function(f) crossprod(J, parts(f)$info * J) + P
  f <- rep(0, G + S)
  for (iter in seq_len(300L)) {
    p <- parts(f)
    grad <- as.vector(crossprod(J, p$score)) - as.vector(P %*% f)
    step <- as.vector(solve(hess(f), grad))
    old <- objective(f)
    a <- 1
    while (objective(f + a * step) < old - 1e-12 && a > 1e-8) a <- a / 2
    f <- f + a * step
    if (max(abs(a * step)) < 1e-12) break
  }
  p <- parts(f)
  stopifnot(max(abs(as.vector(crossprod(J, p$score)) - as.vector(P %*% f))) <
              1e-7)
  logdet_H <- as.numeric(determinant(hess(f), logarithm = TRUE)$modulus)
  objective(f) - 0.5 * logdet_Sigma - 0.5 * logdet_H
}

cis_cases <- list(
  iid = c("relmat_K", "animal_A", "phylo"),
  slope = c("relmat_K", "animal_A", "phylo", "spatial")
)
cis_families <- c("poisson", "nbinom2")

cis_partial_check <- function(provider, family, shape, seed) {
  fx <- cis_fixture(provider, family, shape, seed)
  dat <- fx$data
  nm <- NULL
  expect_true(anyNA(dat$y))
  expect_true(all(tapply(!is.na(dat$y), dat$id, any)))
  expect_true(all(tapply(!is.na(dat$y), dat$site, any)))
  expect_false(identical(levels(dat$id), rownames(fx$Sigma)))
  inc <- cis_fit(fx, include = TRUE)
  cc <- cis_fit(fx, include = FALSE)
  expect_equal(as.integer(inc$opt$convergence), 0L)
  expect_equal(as.integer(cc$opt$convergence), 0L)
  expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(cc)),
               tolerance = 1e-8)
  expect_equal(unname(coef(inc, "mu")), unname(coef(cc, "mu")),
               tolerance = 1e-5)
  nm <- cis_sd_names(inc)
  expect_equal(unname(coef(inc, nm$struct)), unname(coef(cc, nm$struct)),
               tolerance = 1e-5)
  if (identical(shape, "iid")) {
    expect_equal(unname(coef(inc, nm$site)), unname(coef(cc, nm$site)),
                 tolerance = 1e-5)
  }
  expect_equal(nobs(inc), sum(!is.na(dat$y)))
  oracle <- cis_oracle(fx, inc)
  expect_equal(as.numeric(logLik(inc)), oracle, tolerance = 1e-6)
  # Emulated bugs move the oracle: NA scored as an observed zero, and the SD
  # surface attached to the wrong structured groups.
  expect_gt(abs(cis_oracle(fx, inc, na_as_zero = TRUE) - oracle), 0.05)
  tau_hat <- predict(inc, dpar = nm$struct)[rownames(fx$Sigma)]
  expect_gt(abs(cis_oracle(fx, inc, tau_group = rev(unname(tau_hat))) - oracle),
            0.05)
  mu_hat <- predict(inc, dpar = "mu")
  expect_length(mu_hat, nrow(dat))
  expect_true(all(is.finite(mu_hat[is.na(dat$y)])))
  expect_length(tau_hat, nrow(fx$Sigma))
  expect_true(all(is.finite(tau_hat) & tau_hat > 0))
  invisible(list(inc = inc, cc = cc, fx = fx))
}

for (cis_shape in names(cis_cases)) {
  for (cis_family in cis_families) {
    for (cis_provider in cis_cases[[cis_shape]]) {
      local({
        shape <- cis_shape
        family <- cis_family
        provider <- cis_provider
        seed <- 2026110300L + 100L * match(shape, names(cis_cases)) +
          10L * match(provider, names(cis_spec)) + match(family, cis_families)
        label <- sprintf("%s %s %s SD", family, provider, shape)
        test_that(sprintf("%s include equals complete-case and the oracle",
                          label), {
          skip_on_cran()
          if (identical(provider, "phylo")) skip_if_not_installed("ape")
          cis_partial_check(provider, family, shape, seed)
        })
        test_that(sprintf("%s include keeps the prior for an all-NA group",
                          label), {
          skip_on_cran()
          if (identical(provider, "phylo")) skip_if_not_installed("ape")
          fx <- cis_fixture(provider, family, shape, seed + 5L,
                            na_groups = c(3L, 17L))
          dat <- fx$data
          lev <- rownames(fx$Sigma)
          empty <- as.character(dat$id) %in% lev[c(3L, 17L)]
          expect_true(all(is.na(dat$y[empty])) && sum(empty) == 16L)
          inc <- cis_fit(fx, include = TRUE)
          expect_equal(as.integer(inc$opt$convergence), 0L)
          oracle <- cis_oracle(fx, inc)
          expect_equal(as.numeric(logLik(inc)), oracle, tolerance = 1e-6)
          cc <- cis_fit(fx, include = FALSE)
          expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(cc)),
                       tolerance = 1e-8)
          expect_gt(abs(cis_oracle(fx, inc, na_as_zero = TRUE) - oracle), 0.05)
          expect_equal(nobs(inc), sum(!is.na(dat$y)))
          nm <- cis_sd_names(inc)
          sd_hat <- predict(inc, dpar = nm$struct)
          expect_length(sd_hat, length(lev))
          expect_true(all(is.finite(sd_hat) & sd_hat > 0))
          expect_true(all(is.finite(predict(inc, dpar = "mu")[empty])))
        })
      })
    }
  }
}

# Alternative slope-only parametrisations (Q, Ainv, pedigree) go through the
# same likelihood. The oracle is already checked on K / A / tree / coords, so
# here the claim is equality with the complete-case fit and with the K-form
# include fit of the same data.
test_that("slope-only SD include agrees across Q, Ainv and pedigree inputs", {
  skip_on_cran()
  for (family in cis_families) {
    for (provider in c("relmat_Q", "animal_Ainv")) {
      base <- if (identical(provider, "relmat_Q")) "relmat_K" else "animal_A"
      seed <- 2026113900L + match(family, cis_families)
      fx <- cis_fixture(provider, family, "slope", seed)
      fx_base <- cis_fixture(base, family, "slope", seed)
      inc <- cis_fit(fx, include = TRUE)
      cc <- cis_fit(fx, include = FALSE)
      ref <- cis_fit(fx_base, include = TRUE)
      expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(cc)),
                   tolerance = 1e-8, info = paste(family, provider))
      expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(ref)),
                   tolerance = 1e-5, info = paste(family, provider))
      expect_equal(as.numeric(logLik(inc)),
                   cis_oracle(fx, inc), tolerance = 1e-6,
                   info = paste(family, provider))
    }
    fx <- cis_fixture("animal_ped", family, "slope", 2026113950L)
    inc <- cis_fit(fx, include = TRUE)
    cc <- cis_fit(fx, include = FALSE)
    expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(cc)),
                 tolerance = 1e-8, info = paste(family, "pedigree"))
    expect_equal(as.numeric(logLik(inc)), cis_oracle(fx, inc),
                 tolerance = 1e-6, info = paste(family, "pedigree"))
  }
})

# An ordinary SD formula beside a structured intercept that has no SD formula
# of its own is the same iid gate; it is admitted under include too.
test_that("ordinary SD beside a plain structured intercept admits include", {
  skip_on_cran()
  for (family in cis_families) {
    fx <- cis_fixture("relmat_K", family, "iid", 2026113990L +
                        match(family, cis_families))
    inc <- cis_fit(fx, include = TRUE, with_sd_struct = FALSE)
    cc <- cis_fit(fx, include = FALSE, with_sd_struct = FALSE)
    expect_equal(as.integer(inc$opt$convergence), 0L)
    expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(cc)),
                 tolerance = 1e-8, info = family)
    expect_equal(unname(coef(inc, "mu")), unname(coef(cc, "mu")),
                 tolerance = 1e-5, info = family)
    expect_equal(nobs(inc), sum(!is.na(fx$data$y)))
  }
})

test_that("iid and slope-only SD include fences that stay closed", {
  fx_n <- 12L
  lev <- cis_levels(fx_n)
  set.seed(20261103L)
  dat <- data.frame(
    y = stats::rpois(fx_n * 4L, 3), x = stats::rnorm(fx_n * 4L),
    id = factor(rep(lev, each = 4L), levels = lev),
    site = factor(rep(seq_len(4L), length.out = fx_n * 4L)),
    z = rep(seq(-1, 1, length.out = fx_n), each = 4L)
  )
  dat$z_site <- as.numeric(dat$site)
  dat$y[c(2L, 9L)] <- NA
  K <- 1.4 * 0.5^abs(outer(seq_len(fx_n), seq_len(fx_n), `-`))
  dimnames(K) <- list(lev, lev)
  theta <- seq(0, 2 * pi, length.out = fx_n + 1L)[-1L]
  coords <- data.frame(x = cos(theta), y = sin(theta), row.names = lev)
  inc <- miss_control(response = "include")
  sd_id <- sd(id, level = "relmat") ~ z
  sd_site <- sd(site) ~ z_site

  # Admitted shapes build without fitting.
  expect_no_error(drm_build_poisson_spec(
    bf(y ~ x + relmat(1 | id, K = K) + (1 | site), sd_id, sd_site), dat,
    missing = inc))
  expect_no_error(drm_build_nbinom2_spec(
    bf(y ~ x + relmat(1 | id, K = K) + (1 | site), sigma ~ 1, sd_id, sd_site),
    dat, missing = inc))
  expect_no_error(drm_build_poisson_spec(
    bf(y ~ x + relmat(0 + x | id, K = K), sd_id), dat, missing = inc))
  expect_no_error(drm_build_nbinom2_spec(
    bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1, sd_id), dat,
    missing = inc))

  # Zero-inflated iid and slope-only SD stay refused.
  expect_error(drm_build_poisson_spec(
    bf(y ~ x + relmat(1 | id, K = K) + (1 | site), zi ~ 1, sd_id, sd_site),
    dat, missing = inc),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses")
  expect_error(drm_build_poisson_spec(
    bf(y ~ x + relmat(0 + x | id, K = K), zi ~ 1, sd_id), dat, missing = inc),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses")
  expect_error(drm_build_nbinom2_spec(
    bf(y ~ x + relmat(1 | id, K = K) + (1 | site), sigma ~ 1, zi ~ 1, sd_id,
       sd_site), dat, missing = inc),
    "complete\\s+data")
  expect_error(drm_build_nbinom2_spec(
    bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1, zi ~ 1, sd_id), dat,
    missing = inc),
    "complete\\s+data")

  # A spatial intercept with an ordinary SD formula is not an iid provider.
  sd_sp <- sd(id, level = "spatial") ~ z
  expect_error(drm_build_poisson_spec(
    bf(y ~ x + spatial(1 | id, coords = coords) + (1 | site), sd_sp, sd_site),
    dat, missing = inc),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses")
  expect_error(drm_build_nbinom2_spec(
    bf(y ~ x + spatial(1 | id, coords = coords) + (1 | site), sigma ~ 1, sd_sp,
       sd_site), dat, missing = inc))

  # Two SD formulas on a q1 structured slope (no such route) and an ordinary
  # random effect beside a slope-only structured term stay refused.
  expect_error(drm_build_poisson_spec(
    bf(y ~ x + relmat(0 + x | id, K = K) + (1 | site), sd_id, sd_site), dat,
    missing = inc),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses")
  expect_error(drm_build_nbinom2_spec(
    bf(y ~ x + relmat(0 + x | id, K = K) + (1 | site), sigma ~ 1, sd_id,
       sd_site), dat, missing = inc),
    "complete\\s+data")

  # Intercept-plus-slope (q2) structured SD stays refused (receipted pins in
  # test-count-structured-q2-more-providers-sd.R).
  sd_a <- sd(id, level = "relmat", coef = "(Intercept)") ~ z
  sd_b <- sd(id, level = "relmat", coef = "x") ~ z
  expect_error(drm_build_poisson_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sd_a, sd_b), dat, missing = inc),
    "complete\\s+responses")
  expect_error(drm_build_nbinom2_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1, sd_a, sd_b), dat,
    missing = inc),
    "complete\\s+data")

  # Without include the default drop policy is unchanged.
  spec <- drm_build_poisson_spec(
    bf(y ~ x + relmat(0 + x | id, K = K), sd_id), dat)
  expect_identical(length(spec$y), sum(!is.na(dat$y)))
})
