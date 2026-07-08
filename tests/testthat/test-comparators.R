test_that("Gaussian random intercepts agree with lme4 on an overlapping model", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260512)
  n_id <- 30
  n_each <- 8
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  u_id <- stats::rnorm(n_id, sd = 0.6)
  dat$y <- stats::rnorm(
    n,
    mean = 0.4 + 0.7 * dat$x + u_id[dat$id],
    sd = 0.5
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id)),
    family = gaussian(),
    data = dat
  )
  fit_lme4 <- lme4::lmer(y ~ x + (1 | id), data = dat, REML = FALSE)

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(lme4::VarCorr(fit_lme4)$id, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(stats::AIC(fit), stats::AIC(fit_lme4), tolerance = 1e-4)
  expect_equal(stats::BIC(fit), stats::BIC(fit_lme4), tolerance = 1e-4)
})

test_that("Gaussian REML random intercepts agree with lme4", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260609)
  n_id <- 30
  n_each <- 8
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  u_id <- stats::rnorm(n_id, sd = 0.6)
  dat$y <- stats::rnorm(
    n,
    mean = 0.4 + 0.7 * dat$x + u_id[dat$id],
    sd = 0.5
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id)),
    family = gaussian(),
    data = dat,
    REML = TRUE
  )
  fit_lme4 <- lme4::lmer(y ~ x + (1 | id), data = dat, REML = TRUE)

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$estimator, "REML")
  expect_true(fit$REML)
  expect_equal(fit$model$tmb_random_names, c("u_mu", "beta_mu"))
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(lme4::VarCorr(fit_lme4)$id, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    attr(stats::logLik(fit), "df"),
    attr(stats::logLik(fit_lme4), "df")
  )
  expect_equal(attr(stats::logLik(fit), "estimator"), "REML")
  expect_true(all(is.finite(diag(stats::vcov(fit))[c(
    "mu:(Intercept)",
    "mu:x"
  )])))
})

test_that("Gaussian REML weights match row duplication", {
  set.seed(20260610)
  n_id <- 12
  n_each <- 6
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  u_id <- stats::rnorm(n_id, sd = 0.6)
  dat$y <- stats::rnorm(
    n,
    mean = 0.4 + 0.7 * dat$x + u_id[dat$id],
    sd = 0.5
  )
  w <- rep(c(1, 2, 3), length.out = n)
  dat_expanded <- dat[rep(seq_len(n), w), , drop = FALSE]

  fit_weighted <- drmTMB(
    bf(y ~ x + (1 | id)),
    family = gaussian(),
    data = dat,
    weights = w,
    REML = TRUE
  )
  fit_expanded <- drmTMB(
    bf(y ~ x + (1 | id)),
    family = gaussian(),
    data = dat_expanded,
    REML = TRUE
  )

  expect_equal(fit_weighted$estimator, "REML")
  expect_true(fit_weighted$REML)
  expect_equal(
    fit_weighted$model$tmb_random_names,
    c("u_mu", "beta_mu")
  )
  expect_equal(stats::weights(fit_weighted), w)

  # Integer likelihood weights are row log-likelihood multipliers, so a
  # weighted REML fit must reproduce the REML fit on the row-expanded data,
  # including the restricted log-likelihood and its degrees of freedom.
  expect_equal(
    unname(coef(fit_weighted, "mu")),
    unname(coef(fit_expanded, "mu")),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit_weighted$sdpars$mu),
    unname(fit_expanded$sdpars$mu),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit_weighted)[[1L]],
    stats::sigma(fit_expanded)[[1L]],
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit_weighted)),
    as.numeric(stats::logLik(fit_expanded)),
    tolerance = 1e-4
  )
  expect_equal(
    attr(stats::logLik(fit_weighted), "df"),
    attr(stats::logLik(fit_expanded), "df")
  )
  expect_equal(attr(stats::logLik(fit_weighted), "estimator"), "REML")

  vcov_mu <- diag(stats::vcov(fit_weighted))[c(
    "mu:(Intercept)",
    "mu:x"
  )]
  expect_true(all(is.finite(vcov_mu)))
  expect_true(all(vcov_mu > 0))

  # REML inflates the variance-component relative to ML on the same weighted
  # data; the random-intercept SD should be larger and remain sensible.
  fit_ml <- drmTMB(
    bf(y ~ x + (1 | id)),
    family = gaussian(),
    data = dat,
    weights = w,
    REML = FALSE
  )
  expect_true(is.finite(fit_weighted$sdpars$mu))
  expect_true(fit_weighted$sdpars$mu > 0)
  expect_gt(fit_weighted$sdpars$mu, fit_ml$sdpars$mu)
})

test_that("Poisson random intercepts agree with lme4 on an overlapping model", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260620)
  n_id <- 32
  n_each <- 9
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  u_id <- stats::rnorm(n_id, sd = 0.45)
  dat$y <- stats::rpois(n, exp(0.25 - 0.35 * dat$x + u_id[dat$id]))

  fit <- drmTMB(
    bf(y ~ x + (1 | id)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  fit_lme4 <- lme4::glmer(
    y ~ x + (1 | id),
    family = stats::poisson(link = "log"),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 5e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(lme4::VarCorr(fit_lme4)$id, "stddev")),
    tolerance = 5e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 5e-4
  )
})

test_that("Poisson independent random slopes agree with lme4 on an overlapping model", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260622)
  n_id <- 36
  n_each <- 12
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  u0 <- stats::rnorm(n_id, sd = 0.35)
  u1 <- stats::rnorm(n_id, sd = 0.30)
  dat$y <- stats::rpois(
    n,
    exp(0.30 - 0.20 * dat$x + u0[dat$id] + u1[dat$id] * dat$x)
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id) + (0 + x | id)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  fit_lme4 <- lme4::glmer(
    y ~ x + (1 | id) + (0 + x | id),
    family = stats::poisson(link = "log"),
    data = dat
  )
  sd_lme4 <- unname(unlist(lapply(
    lme4::VarCorr(fit_lme4),
    function(term) attr(term, "stddev")
  )))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-3
  )
  expect_equal(
    unname(fit$sdpars$mu),
    sd_lme4,
    tolerance = 1e-3
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-3
  )
})

test_that("Gaussian independent random slopes agree with lme4 on an overlapping model", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260514)
  n_id <- 36
  n_each <- 9
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  u0 <- stats::rnorm(n_id, sd = 0.5)
  u1 <- stats::rnorm(n_id, sd = 0.4)
  dat$y <- stats::rnorm(
    n,
    mean = 0.25 + 0.65 * dat$x + u0[dat$id] + u1[dat$id] * dat$x,
    sd = 0.45
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id) + (0 + x | id)),
    family = gaussian(),
    data = dat
  )
  fit_lme4 <- lme4::lmer(
    y ~ x + (1 | id) + (0 + x | id),
    data = dat,
    REML = FALSE
  )
  sd_lme4 <- unname(unlist(lapply(
    lme4::VarCorr(fit_lme4),
    function(term) attr(term, "stddev")
  )))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    sd_lme4,
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
})

test_that("Gaussian correlated random slopes agree with lme4 on an overlapping model", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260521)
  n_id <- 32
  n_each <- 8
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  sd0 <- 0.5
  sd1 <- 0.35
  rho_re <- 0.4
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  u0 <- sd0 * z0
  u1 <- sd1 * (rho_re * z0 + sqrt(1 - rho_re^2) * z1)
  dat$y <- stats::rnorm(
    n,
    mean = 0.25 + 0.65 * dat$x + u0[dat$id] + u1[dat$id] * dat$x,
    sd = 0.45
  )

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id)),
    family = gaussian(),
    data = dat
  )
  fit_lme4 <- lme4::lmer(y ~ x + (1 + x | id), data = dat, REML = FALSE)
  vc_lme4 <- lme4::VarCorr(fit_lme4)$id

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(vc_lme4, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$corpars$mu),
    unname(attr(vc_lme4, "correlation")[1, 2]),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
})

test_that("Gaussian REML correlated random slopes agree with lme4", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260610)
  n_id <- 32
  n_each <- 8
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  sd0 <- 0.5
  sd1 <- 0.35
  rho_re <- 0.4
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  u0 <- sd0 * z0
  u1 <- sd1 * (rho_re * z0 + sqrt(1 - rho_re^2) * z1)
  dat$y <- stats::rnorm(
    n,
    mean = 0.25 + 0.65 * dat$x + u0[dat$id] + u1[dat$id] * dat$x,
    sd = 0.45
  )

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id)),
    family = gaussian(),
    data = dat,
    REML = TRUE
  )
  fit_lme4 <- lme4::lmer(y ~ x + (1 + x | id), data = dat, REML = TRUE)
  vc_lme4 <- lme4::VarCorr(fit_lme4)$id

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(vc_lme4, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$corpars$mu),
    unname(attr(vc_lme4, "correlation")[1, 2]),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    attr(stats::logLik(fit), "df"),
    attr(stats::logLik(fit_lme4), "df")
  )
})

test_that("labelled Gaussian correlated random slopes agree with lme4 semantics", {
  testthat::skip_if_not_installed("lme4")

  set.seed(20260538)
  n_id <- 32
  n_each <- 8
  n <- n_id * n_each
  dat <- data.frame(
    ID = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n),
    f = factor(rep(c("control", "treated"), length.out = n))
  )
  sd0 <- 0.5
  sd1 <- 0.35
  rho_re <- 0.4
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  u0 <- sd0 * z0
  u1 <- sd1 * (rho_re * z0 + sqrt(1 - rho_re^2) * z1)
  dat$y <- stats::rnorm(
    n,
    mean = 0.25 +
      0.65 * dat$x +
      0.2 * (dat$f == "treated") +
      u0[dat$ID] +
      u1[dat$ID] * dat$x,
    sd = 0.45
  )

  fit <- drmTMB(
    bf(y ~ x + f + (1 + x | p | ID)),
    family = gaussian(),
    data = dat
  )
  fit_lme4 <- lme4::lmer(y ~ x + f + (1 + x | ID), data = dat, REML = FALSE)
  vc_lme4 <- lme4::VarCorr(fit_lme4)$ID

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(vc_lme4, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$corpars$mu),
    unname(attr(vc_lme4, "correlation")[1, 2]),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
})

test_that("REML rejects unsupported first-slice neighbours", {
  set.seed(20260611)
  n_id <- 8
  n_each <- 4
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    vi = stats::runif(n, 0.02, 0.05)
  )
  dat$x_dup <- dat$x
  dat$y <- stats::rnorm(n, 0.4 + 0.7 * dat$x, sd = 0.5)
  dat$count <- stats::rpois(n, exp(0.4 + 0.2 * dat$x))
  tree <- structure(
    list(
      edge = matrix(
        c(
          15,
          13,
          15,
          14,
          13,
          9,
          13,
          10,
          9,
          1,
          9,
          2,
          10,
          3,
          10,
          4,
          14,
          11,
          14,
          12,
          11,
          5,
          11,
          6,
          12,
          7,
          12,
          8
        ),
        ncol = 2,
        byrow = TRUE
      ),
      edge.length = rep(1, 14),
      tip.label = as.character(seq_len(n_id)),
      Nnode = 7L
    ),
    class = "phylo"
  )

  expect_error(
    drmTMB(
      bf(count ~ x + (1 | id)),
      family = stats::poisson(),
      data = dat,
      REML = TRUE
    ),
    "univariate and bivariate Gaussian"
  )
  # A fixed-effect sigma ~ x is now supported under REML (validated in
  # test-reml-heteroscedastic.R); the rejected scale-side neighbour is a scale
  # random effect.
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ 1),
      family = gaussian(),
      data = dat,
      REML = TRUE
    ),
    # Message sharpened in 83521a01: `sd_phylo(...) ~ .` is admitted under REML,
    # so the rejection now names the *ordinary* direct scale specifically.
    "direct ordinary random-effect scale"
  )
  # The missing-data gate now fires only when the engine actually ENGAGES: on
  # complete-case data `response = "include"` is an exact no-op (A. Mizuno,
  # 2026-07-08). Introduce real missingness to exercise the rejection.
  dat_missing_response <- dat
  dat_missing_response$y[[2L]] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = gaussian(),
      data = dat_missing_response,
      missing = miss_control(response = "include"),
      REML = TRUE
    ),
    "missing-data engine"
  )
  expect_no_error(suppressWarnings(
    drmTMB(
      bf(y ~ x),
      family = gaussian(),
      data = dat,
      missing = miss_control(response = "include"),
      REML = TRUE
    )
  ))
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = gaussian(),
      data = dat,
      control = drm_control(sparse_fixed = TRUE),
      REML = TRUE
    ),
    "sparse fixed-effect"
  )
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = gaussian(),
      data = dat,
      control = drm_control(aggregate_gaussian = TRUE),
      REML = TRUE
    ),
    "Gaussian row aggregation"
  )
  # Ordinary `sigma` random effects under REML were admitted in `feba9018`
  # (S5 parity); recovery is validated in test-reml-ordinary-sigma.R.
  expect_no_error(suppressWarnings(
    drmTMB(
      bf(y ~ x, sigma ~ 1 + (1 | id)),
      family = gaussian(),
      data = dat,
      REML = TRUE
    )
  ))
  # q > 2 labelled covariance blocks under REML were admitted in `1b3e852b`
  # (ML/REML parity). This asserts the *validator* admits the shape; the tiny
  # 8x4 fixture is below the within-group replication floor, so the optimizer
  # may warn -- fit quality is gated by the recovery ladders, not here.
  expect_no_error(suppressWarnings(
    drmTMB(
      bf(y ~ x + (1 + x + z | p | id), sigma ~ 1),
      family = gaussian(),
      data = dat,
      REML = TRUE
    )
  ))
  # Mean-side phylo() under REML is supported (validated in
  # test-reml-phylo-location.R). PURE scale-side phylo (`sigma ~ ... phylo(...)`,
  # no mean-side phylo) is now ALSO supported -- admitted and debiasing-validated
  # in test-reml-phylo-location.R -- so it is no longer a rejected neighbour here.
  # (Matched mean+scale phylo remains rejected; see test-reml-phylo-location.R.)
  expect_error(
    drmTMB(
      bf(y ~ x + x_dup, sigma ~ 1),
      family = gaussian(),
      data = dat,
      REML = TRUE
    ),
    "full-rank dense"
  )
})

test_that("Gaussian sd(id) intercept-only random-effect scale agrees with lme4", {
  testthat::skip_if_not_installed("lme4")

  sim <- new_gaussian_re_scale_data(
    n_id = 30,
    n_each = 8,
    alpha = c(`(Intercept)` = log(0.6), w = 0),
    beta_sigma = c(`(Intercept)` = log(0.5), z = 0),
    seed = 20260560
  )
  dat <- sim$data

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ 1),
    family = gaussian(),
    data = dat
  )
  fit_lme4 <- lme4::lmer(y ~ x + (1 | id), data = dat, REML = FALSE)

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(lme4::fixef(fit_lme4)),
    tolerance = 1e-4
  )
  expect_equal(
    exp(unname(coef(fit, "sd(id)")[[1L]])),
    unname(attr(lme4::VarCorr(fit_lme4)$id, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]],
    stats::sigma(fit_lme4),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_lme4)),
    tolerance = 1e-4
  )
})

test_that("Gaussian fixed-effect location-scale agrees with glmmTMB dispersion", {
  suppressWarnings(testthat::skip_if_not_installed("glmmTMB"))

  set.seed(20260620)
  n <- 240
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.30, x = -0.45)
  beta_sigma <- c(`(Intercept)` = log(0.55), z = 0.25)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat
  )
  fit_glmmTMB <- suppressWarnings(glmmTMB::glmmTMB(
    y ~ x,
    dispformula = ~z,
    family = gaussian(),
    data = dat
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(glmmTMB::fixef(fit_glmmTMB)$cond),
    tolerance = 1e-4
  )
  expect_equal(
    unname(coef(fit, "sigma")),
    unname(glmmTMB::fixef(fit_glmmTMB)$disp),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_glmmTMB)),
    tolerance = 1e-4
  )
})

test_that("Gaussian random-intercept location-scale agrees with glmmTMB dispersion", {
  suppressWarnings(testthat::skip_if_not_installed("glmmTMB"))

  set.seed(20260621)
  n_id <- 24
  n_each <- 8
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.20, x = 0.50)
  beta_sigma <- c(`(Intercept)` = log(0.45), z = -0.20)
  sd_id <- 0.35
  u_id <- stats::rnorm(n_id, sd = sd_id)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x + u_id[dat$id]
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )
  fit_glmmTMB <- suppressWarnings(glmmTMB::glmmTMB(
    y ~ x + (1 | id),
    dispformula = ~z,
    family = gaussian(),
    data = dat
  ))
  vc_glmmTMB <- glmmTMB::VarCorr(fit_glmmTMB)$cond$id

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(glmmTMB::fixef(fit_glmmTMB)$cond),
    tolerance = 1e-4
  )
  expect_equal(
    unname(coef(fit, "sigma")),
    unname(glmmTMB::fixef(fit_glmmTMB)$disp),
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit$sdpars$mu),
    unname(attr(vc_glmmTMB, "stddev")),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_glmmTMB)),
    tolerance = 1e-4
  )
})

test_that("Gamma mean model agrees with base glm on an overlapping model", {
  set.seed(20260595)
  n <- 240
  dat <- data.frame(x = stats::rnorm(n))
  beta_mu <- c(0.2, -0.35)
  cv <- 0.55
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  dat$biomass <- stats::rgamma(n, shape = 1 / cv^2, scale = mu * cv^2)

  fit <- drmTMB(
    bf(biomass ~ x),
    family = stats::Gamma(link = "log"),
    data = dat
  )
  fit_glm <- stats::glm(
    biomass ~ x,
    family = stats::Gamma(link = "log"),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_glm)),
    tolerance = 1e-4
  )
})

test_that("negative-binomial 2 mean-dispersion agrees with MASS glm.nb", {
  testthat::skip_if_not_installed("MASS")

  set.seed(20260618)
  n <- 260
  dat <- data.frame(x = stats::rnorm(n))
  beta_mu <- c(`(Intercept)` = 0.25, x = -0.40)
  sigma <- 0.55
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  dat$count <- stats::rnbinom(n, size = 1 / sigma^2, mu = mu)

  fit <- drmTMB(
    bf(count ~ x, sigma ~ 1),
    family = nbinom2(),
    data = dat
  )
  fit_mass <- MASS::glm.nb(count ~ x, data = dat)

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_mass)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(sigma(fit)[[1L]]),
    unname(1 / sqrt(fit_mass$theta)),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_mass)),
    tolerance = 1e-4
  )
})

gaussian_full_reml_loglik <- function(y, X, Sigma) {
  chol_sigma <- chol(Sigma)
  solve_sigma <- function(B) {
    backsolve(chol_sigma, forwardsolve(t(chol_sigma), B))
  }
  sigma_inv_x <- solve_sigma(X)
  xt_sigma_inv_x <- crossprod(X, sigma_inv_x)
  beta <- solve(xt_sigma_inv_x, crossprod(X, solve_sigma(y)))
  resid <- y - X %*% beta
  quadratic <- as.numeric(crossprod(resid, solve_sigma(resid)))
  n <- length(y)
  p <- ncol(X)
  log_det_sigma <- determinant(Sigma, logarithm = TRUE)$modulus[[1L]]
  log_det_xt_sigma_inv_x <-
    determinant(xt_sigma_inv_x, logarithm = TRUE)$modulus[[1L]]
  -0.5 *
    ((n - p) * log(2 * pi) + log_det_sigma + log_det_xt_sigma_inv_x + quadratic)
}

gaussian_metafor_reml_shift <- function(X) {
  0.5 * determinant(crossprod(X), logarithm = TRUE)$modulus[[1L]]
}

test_that("Gaussian meta-analysis agrees with metafor for ML tau2", {
  testthat::skip_if_not_installed("metafor")

  set.seed(20260513)
  n <- 80
  dat <- data.frame(
    x = stats::rnorm(n),
    vi = stats::runif(n, min = 0.01, max = 0.08)
  )
  tau <- 0.25
  dat$yi <- stats::rnorm(
    n,
    mean = 0.2 - 0.4 * dat$x,
    sd = sqrt(dat$vi + tau^2)
  )

  fit <- drmTMB(
    bf(yi ~ x + meta_V(V = vi)),
    family = gaussian(),
    data = dat
  )
  fit_metafor <- metafor::rma.uni(
    yi = yi,
    vi = vi,
    mods = ~x,
    data = dat,
    method = "ML"
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_metafor)),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]]^2,
    fit_metafor$tau2,
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_metafor)),
    tolerance = 1e-4
  )
})

test_that("Gaussian REML meta-analysis with diagonal known V agrees with metafor estimates", {
  testthat::skip_if_not_installed("metafor")

  set.seed(20260610)
  n <- 80
  dat <- data.frame(
    x = stats::rnorm(n),
    vi = stats::runif(n, min = 0.01, max = 0.08)
  )
  tau <- 0.25
  dat$yi <- stats::rnorm(
    n,
    mean = 0.2 - 0.4 * dat$x,
    sd = sqrt(dat$vi + tau^2)
  )

  fit <- drmTMB(
    bf(yi ~ x + meta_V(V = vi)),
    family = gaussian(),
    data = dat,
    REML = TRUE
  )
  fit_metafor <- metafor::rma.uni(
    yi = yi,
    vi = vi,
    mods = ~x,
    data = dat,
    method = "REML"
  )

  sigma_hat <- stats::sigma(fit)[[1L]]
  Sigma <- diag(dat$vi + sigma_hat^2)
  manual_loglik <- gaussian_full_reml_loglik(dat$yi, fit$model$X$mu, Sigma)
  metafor_shift <- gaussian_metafor_reml_shift(fit$model$X$mu)

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$estimator, "REML")
  expect_true(fit$REML)
  expect_equal(fit$model$V_known_type, "diagonal")
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_metafor)),
    tolerance = 1e-4
  )
  expect_equal(
    sigma_hat^2,
    fit_metafor$tau2,
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    manual_loglik,
    tolerance = 1e-6
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_metafor)) - metafor_shift,
    tolerance = 1e-6
  )
  expect_equal(attr(stats::logLik(fit), "df"), 3L)
})

test_that("dense known-V Gaussian meta-analysis agrees with metafor rma.mv", {
  testthat::skip_if_not_installed("metafor")

  set.seed(20260590)
  n <- 36
  dat <- data.frame(
    x = stats::rnorm(n),
    obs = factor(seq_len(n))
  )
  V <- 0.012 * outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  beta_mu <- c(0.15, -0.45)
  tau <- 0.28
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x
  Sigma <- V + diag(tau^2, n)
  dat$yi <- as.vector(mu + t(chol(Sigma)) %*% stats::rnorm(n))

  fit <- drmTMB(
    bf(yi ~ x + meta_V(V = V)),
    family = gaussian(),
    data = dat
  )
  fit_metafor <- metafor::rma.mv(
    yi = yi,
    V = V,
    mods = ~x,
    random = ~ 1 | obs,
    data = dat,
    method = "ML"
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_metafor)),
    tolerance = 1e-4
  )
  expect_equal(
    stats::sigma(fit)[[1L]]^2,
    fit_metafor$sigma2[[1L]],
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_metafor)),
    tolerance = 1e-4
  )
})

test_that("Gaussian REML meta-analysis with dense known V agrees with metafor estimates", {
  testthat::skip_if_not_installed("metafor")

  set.seed(20260611)
  n <- 36
  dat <- data.frame(
    x = stats::rnorm(n),
    obs = factor(seq_len(n))
  )
  V <- 0.012 * outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  beta_mu <- c(0.15, -0.45)
  tau <- 0.28
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x
  Sigma <- V + diag(tau^2, n)
  dat$yi <- as.vector(mu + t(chol(Sigma)) %*% stats::rnorm(n))

  fit <- drmTMB(
    bf(yi ~ x + meta_V(V = V)),
    family = gaussian(),
    data = dat,
    REML = TRUE
  )
  fit_metafor <- metafor::rma.mv(
    yi = yi,
    V = V,
    mods = ~x,
    random = ~ 1 | obs,
    data = dat,
    method = "REML"
  )

  sigma_hat <- stats::sigma(fit)[[1L]]
  Sigma_hat <- V + diag(sigma_hat^2, n)
  manual_loglik <- gaussian_full_reml_loglik(dat$yi, fit$model$X$mu, Sigma_hat)
  metafor_shift <- gaussian_metafor_reml_shift(fit$model$X$mu)

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$estimator, "REML")
  expect_true(fit$REML)
  expect_equal(fit$model$V_known_type, "matrix")
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_metafor)),
    tolerance = 1e-4
  )
  expect_equal(
    sigma_hat^2,
    fit_metafor$sigma2[[1L]],
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    manual_loglik,
    tolerance = 1e-6
  )
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_metafor)) - metafor_shift,
    tolerance = 1e-6
  )
  expect_equal(attr(stats::logLik(fit), "df"), 3L)
})
