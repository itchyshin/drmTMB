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
