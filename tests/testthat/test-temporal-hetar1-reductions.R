pkgload::load_all(".", compile = TRUE, quiet = TRUE)
source(testthat::test_path("helper-temporal-hetar1-reference.R"))

test_that("hetar1 dense covariance reduces to AR1 and its diagonal limit", {
  id <- rep(c("a", "b"), each = 4L)
  occasion <- rep(0:3, times = 2L)
  sigma <- 0.4
  sd <- rep(0.7, 4L)
  phi <- -0.45
  V <- hetar1_dense_covariance(id, occasion, sd, sigma, phi)
  expected <- matrix(0, length(id), length(id))
  for (series in unique(id)) {
    rows <- which(id == series)
    expected[rows, rows] <- 0.7^2 * phi^abs(outer(occasion[rows], occasion[rows], "-"))
  }
  diag(expected) <- diag(expected) + sigma^2
  expect_equal(V, expected, tolerance = 1e-12)

  unequal_sd <- c(0.3, 0.5, 0.8, 1.1)
  diagonal <- hetar1_dense_covariance(id, occasion, unequal_sd, sigma, 0)
  expect_equal(diag(diagonal), rep(unequal_sd^2 + sigma^2, times = 2L), tolerance = 1e-12)
  expect_equal(diagonal[row(diagonal) != col(diagonal)], rep(0, sum(row(diagonal) != col(diagonal))))
})

test_that("hetar1 has no cross-series covariance and detects the D factors", {
  id <- rep(c("a", "b"), each = 3L)
  occasion <- rep(0:2, times = 2L)
  V <- hetar1_dense_covariance(id, occasion, c(0.2, 0.7, 1.1), 0.3, 0.5)
  expect_equal(V[id == "a", id == "b"], matrix(0, 3, 3))
  expect_false(isTRUE(all.equal(
    V[1:3, 1:3],
    0.7^2 * 0.5^abs(outer(occasion[1:3], occasion[1:3], "-")) + diag(0.3^2, 3)
  )))
})

test_that("hetar1 native likelihood preserves raw gaps, ID blocks, and separate scales", {
  set.seed(202609112L)
  dat <- expand.grid(
    id = sprintf("s%02d", seq_len(12L)), occasion = c(0L, 3L, 6L),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  dat$x <- rep(c(-1, 1), length.out = nrow(dat))
  dat$y <- 0.1 + 0.4 * dat$x + rnorm(nrow(dat), sd = 0.6)
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = occasion, structure = "hetar1"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  )
  par <- fit$opt$par
  expected <- hetar1_dense_nll_at(fit, par)
  expect_equal(-as.numeric(stats::logLik(fit)), expected, tolerance = 1e-6)

  names_par <- names(par)
  sd_temporal <- exp(unname(par[names_par == "log_sd_temporal"]))
  sigma <- exp(unname(par[match("beta_sigma", names_par)]))
  wrong_scale <- hetar1_dense_nll(
    fit$model$y, as.matrix(fit$model$X$mu),
    unname(par[names_par == "beta_mu"]), dat$id, dat$occasion,
    rep(sigma, length(sd_temporal)), mean(sd_temporal),
    tanh(unname(par[match("theta_temporal", names_par)]))
  )
  expect_gt(abs(expected - wrong_scale), 1e-4)
})
