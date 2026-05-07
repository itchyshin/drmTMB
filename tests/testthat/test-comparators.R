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
    bf(yi ~ x + meta_known_V(V = vi)),
    family = gaussian(),
    data = dat
  )
  fit_metafor <- metafor::rma.uni(
    yi = yi,
    vi = vi,
    mods = ~ x,
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
