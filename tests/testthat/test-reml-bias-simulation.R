# ML vs REML bias for a random-effect variance component. ML underestimates the
# random-effect SD because it ignores the degrees of freedom spent on the mean
# fixed effects; REML corrects this. A small Monte Carlo demonstrates the
# property across replicates (replacing the single-seed inequality with an
# averaged one): the mean REML SD is larger than the mean ML SD and closer to
# the truth. Kept small and skipped on CRAN.

test_that("REML reduces the downward bias of a random-effect SD on average", {
  skip_on_cran()
  truth_sd <- 0.8
  n_id <- 18L
  n_each <- 4L
  n_rep <- 40L
  ml_sd <- numeric(n_rep)
  reml_sd <- numeric(n_rep)
  form <- bf(y ~ x + (1 | id), sigma ~ 1)
  for (r in seq_len(n_rep)) {
    set.seed(1000L + r)
    n <- n_id * n_each
    id <- factor(rep(seq_len(n_id), each = n_each))
    x <- stats::rnorm(n)
    u <- stats::rnorm(n_id, 0, truth_sd)
    y <- 0.3 + 0.6 * x + u[id] + stats::rnorm(n, 0, 0.5)
    dat <- data.frame(y = y, x = x, id = id)
    fit_ml <- suppressWarnings(
      drmTMB(form, family = gaussian(), data = dat)
    )
    fit_reml <- suppressWarnings(
      drmTMB(form, family = gaussian(), data = dat, REML = TRUE)
    )
    ml_sd[r] <- as.numeric(fit_ml$sdpars$mu[[1L]])
    reml_sd[r] <- as.numeric(fit_reml$sdpars$mu[[1L]])
  }
  mean_ml <- mean(ml_sd)
  mean_reml <- mean(reml_sd)
  # REML is less downward-biased: its mean SD is larger than ML's...
  expect_gt(mean_reml, mean_ml)
  # ...and closer to the truth.
  expect_lt(abs(mean_reml - truth_sd), abs(mean_ml - truth_sd))
  # ML is downward-biased here (sanity check on the regime).
  expect_lt(mean_ml, truth_sd)
})
