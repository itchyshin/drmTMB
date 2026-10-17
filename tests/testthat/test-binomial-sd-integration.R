test_that("Bernoulli SD regression recovers its named latent-scale target", {
  sim <- binomial_sd_fixture()
  fit <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w),
                family = binomial(), data = sim$data)

  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)
  expect_named(coef(fit), c("mu", "sd(id)"))
  expect_named(coef(fit, "sd(id)"), c("(Intercept)", "w"))
  expect_lt(max(abs(coef(fit, "sd(id)") - sim$alpha)), 0.35)
  expect_named(fit$sdpars, "sd(id)")
  expect_true(all(predict(fit, dpar = "sd(id)") > 0))
  expect_equal(length(predict(fit, dpar = "sd(id)")), nlevels(sim$data$id))
  expect_true(all(c("sd(id):(Intercept)", "sd(id):w") %in%
                    rownames(stats::vcov(fit))))
  expect_equal(sigma(fit), rep(1, nobs(fit)))
})

test_that("Bernoulli SD likelihood agrees with an independent Laplace oracle", {
  dat <- binomial_sd_fixture(groups = 50L, repeats = 12L)$data
  fit <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w),
                family = binomial(), data = dat)
  oracle <- binomial_sd_laplace_oracle(dat, coef(fit, "mu"),
                                      coef(fit, "sd(id)"))
  expect_equal(-as.numeric(logLik(fit)), oracle, tolerance = 1e-6)
  wrong <- coef(fit, "sd(id)")
  wrong[[2L]] <- -wrong[[2L]] + 0.7
  expect_gt(abs(binomial_sd_laplace_oracle(dat, coef(fit, "mu"), wrong) -
                  oracle), 0.01)
})

test_that("constant Bernoulli SD formulas preserve the existing model", {
  dat <- binomial_sd_fixture(groups = 60L, repeats = 12L)$data
  ordinary <- drmTMB(bf(y ~ x + (1 | id)), binomial(), dat)
  scaled <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ 1), binomial(), dat)
  expect_equal(as.numeric(logLik(scaled)), as.numeric(logLik(ordinary)),
               tolerance = 1e-6)
  expect_equal(coef(scaled, "mu"), coef(ordinary, "mu"), tolerance = 1e-4)
  expect_equal(unname(predict(scaled, dpar = "sd(id)")),
               rep(unname(ordinary$sdpars$mu[[1L]]), nlevels(dat$id)),
               tolerance = 1e-4)
})

test_that("binomial SD prediction and stored fits preserve group coding", {
  dat <- binomial_sd_fixture(groups = 60L, repeats = 12L, trials = 5L)$data
  fit <- drmTMB(bf(cbind(y, failure) ~ x + (1 | id), sd(id) ~ w),
                binomial(), dat)
  grid <- data.frame(w = c(-0.5, 0, 0.5))
  expected <- exp(coef(fit, "sd(id)")[[1L]] +
                    coef(fit, "sd(id)")[[2L]] * grid$w)
  expect_equal(unname(predict(fit, dpar = "sd(id)", newdata = grid)),
               expected, tolerance = 1e-7)
  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  stored <- readRDS(path)
  expect_equal(predict(stored, dpar = "sd(id)", newdata = grid),
               predict(fit, dpar = "sd(id)", newdata = grid))
  expect_equal(coef(stored, "sd(id)"), coef(fit, "sd(id)"))
})
