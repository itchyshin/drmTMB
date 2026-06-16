# Guard tests for the Gaussian log-sigma soft-clamp.
# See docs/design/170-sigma-phylo-conditioning-and-logsigma-clamp.md.

test_that("log-sigma clamp is inactive (identity) for a well-posed Gaussian fit", {
  # A normal location-scale fit keeps log_sigma well inside the [-12, 12] band,
  # so the clamp is ~identity and the fit is unchanged from the unclamped model.
  set.seed(101)
  n <- 80
  x <- stats::rnorm(n)
  mu <- 0.3 + 0.5 * x
  log_sigma <- -0.2 + 0.3 * x
  y <- stats::rnorm(n, mu, exp(log_sigma))
  d <- data.frame(y = y, x = x)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    data = d,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  report <- fit$obj$report()
  # clamp band is [-12, 12]; a healthy fit must stay strictly inside it
  expect_true(all(report$log_sigma > -11.5 & report$log_sigma < 11.5))
  expect_true(is.finite(fit$opt$objective))
})

test_that("log-sigma clamp keeps a pathological scale-phylo fit finite instead of overflowing", {
  skip_on_cran()
  skip_if_not_installed("ape")
  # One observation per tip + a phylo field on sigma + heavy-tailed outliers is a
  # near-degenerate per-tip scale model. Without the clamp the inner Laplace solve
  # overshoots (sigma -> ~1e11), the objective blows up to ~1e5 and emits NaNs.
  # With the clamp the objective stays finite and the fit is returned for
  # check_drm() to flag (it will NOT be a clean convergence -- that is honest).
  set.seed(202)
  n_tip <- 160
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("t", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  L <- t(chol(A))
  z <- as.vector(L %*% stats::rnorm(n_tip))
  x <- stats::rnorm(n_tip)
  species <- factor(tree$tip.label, levels = tree$tip.label)
  y <- 0.2 + 0.5 * x + 0.5 * z + stats::rnorm(n_tip, 0, exp(-0.3))
  y[c(5L, 40L, 120L)] <- y[c(5L, 40L, 120L)] + c(45, -50, 55) # extreme residuals
  d <- data.frame(y = y, x = x, species = species)

  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ x + phylo(1 | species, tree = tree)
  )
  fit <- drmTMB(form, data = d, control = drm_control(se = FALSE))

  expect_true(is.finite(fit$opt$objective))
  expect_false(is.nan(fit$opt$objective))
  # the fitted log_sigma is bounded by the clamp band
  report <- fit$obj$report()
  expect_true(all(is.finite(report$log_sigma)))
  # clamp is identity in [-12, 12] and saturates within a margin to [-15, 15]
  expect_true(max(report$log_sigma) <= 15 + 1e-6)
  expect_true(min(report$log_sigma) >= -15 - 1e-6)
})

test_that("the default log-sigma clamp band is unchanged (-12, 12, margin 3)", {
  set.seed(101)
  n <- 80
  x <- stats::rnorm(n)
  y <- stats::rnorm(n, 0.3 + 0.5 * x, exp(-0.2 + 0.3 * x))
  d <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ x), data = d, control = drm_control(se = FALSE))
  expect_equal(fit$model$tmb_data$use_logsigma_clamp, 1L)
  expect_equal(fit$model$tmb_data$logsigma_clamp, c(-12, 12, 3))
})

test_that("logsigma_clamp band is configurable through drm_control()", {
  set.seed(101)
  n <- 80
  x <- stats::rnorm(n)
  y <- stats::rnorm(n, 0.3 + 0.5 * x, exp(-0.2 + 0.3 * x))
  d <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    data = d,
    control = drm_control(
      se = FALSE,
      logsigma_clamp = c(-20, 20),
      logsigma_clamp_margin = 2
    )
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_equal(fit$model$tmb_data$use_logsigma_clamp, 1L)
  expect_equal(fit$model$tmb_data$logsigma_clamp, c(-20, 20, 2))
})

test_that("disabling logsigma_clamp removes the guard so the inner solve overshoots", {
  skip_on_cran()
  skip_if_not_installed("ape")
  set.seed(202)
  n_tip <- 160
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("t", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  L <- t(chol(A))
  z <- as.vector(L %*% stats::rnorm(n_tip))
  x <- stats::rnorm(n_tip)
  species <- factor(tree$tip.label, levels = tree$tip.label)
  y <- 0.2 + 0.5 * x + 0.5 * z + stats::rnorm(n_tip, 0, exp(-0.3))
  y[c(5L, 40L, 120L)] <- y[c(5L, 40L, 120L)] + c(45, -50, 55)
  d <- data.frame(y = y, x = x, species = species)
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ x + phylo(1 | species, tree = tree)
  )
  fit_off <- suppressWarnings(drmTMB(
    form,
    data = d,
    control = drm_control(se = FALSE, logsigma_clamp = NULL)
  ))
  fit_on <- suppressWarnings(drmTMB(
    form,
    data = d,
    control = drm_control(se = FALSE)
  ))
  # The control plumbs through deterministically (platform-independent): the
  # guard is off for the NULL fit and on (default band) otherwise. The C++
  # `if (use_logsigma_clamp == 1)` branch then skips the soft-clamp when off.
  # (We do not assert the optimizer's warning text: whether the unclamped inner
  # solve emits an NA/NaN evaluation is optimizer/BLAS-path dependent.)
  expect_equal(fit_off$model$tmb_data$use_logsigma_clamp, 0L)
  expect_equal(fit_on$model$tmb_data$use_logsigma_clamp, 1L)
  expect_equal(fit_on$model$tmb_data$logsigma_clamp, c(-12, 12, 3))
})

test_that("drm_control() validates the log-sigma clamp arguments", {
  expect_error(drm_control(logsigma_clamp = c(12, -12)), "logsigma_clamp")
  expect_error(drm_control(logsigma_clamp = c(1, 2, 3)), "logsigma_clamp")
  expect_error(drm_control(logsigma_clamp = "x"), "logsigma_clamp")
  expect_error(drm_control(logsigma_clamp_margin = -1), "logsigma_clamp_margin")
  expect_error(drm_control(logsigma_clamp_margin = c(1, 2)), "logsigma_clamp_margin")
})
