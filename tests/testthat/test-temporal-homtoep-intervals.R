pkgload::load_all('.', compile = TRUE, quiet = TRUE)

homtoep_profile_fit <- function() {
  set.seed(202609130)
  dat <- expand.grid(id = sprintf('s%02d', 1:20), occasion = c(0L, 2L, 4L, 6L))
  dat$x <- rep(c(-1, 1), length.out = nrow(dat))
  dat$y <- 0.3 + 0.4 * dat$x + stats::rnorm(nrow(dat), sd = 0.7)
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = occasion, structure = 'homtoep'), sigma ~ 1),
    data = dat, family = stats::gaussian(), REML = FALSE
  )
}

test_that('homtoep internal mean-effect profile reoptimizes covariance parameters', {
  fit <- homtoep_profile_fit()
  profile <- drmTMB:::drm_profile_confint(
    fit, parm = 'fixef:mu:x', level = 0.95,
    profile_engine = 'tmbprofile', profile_precision = 'fast', profile_maxit = 50L
  )
  expect_identical(profile$parm, 'fixef:mu:x')
  expect_identical(profile$method, 'profile')
  expect_identical(profile$profile.engine, 'tmbprofile')
  expect_identical(profile$conf.status, 'profile')
  expect_true(is.finite(profile$lower) && is.finite(profile$upper))
  expect_lt(profile$lower, unname(stats::coef(fit)$mu[['x']]))
  expect_gt(profile$upper, unname(stats::coef(fit)$mu[['x']]))
  expect_error(stats::confint(fit, method = 'profile'), 'Toeplitz profile intervals')
})
