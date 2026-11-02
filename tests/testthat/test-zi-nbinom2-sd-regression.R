zi_nbinom2_sd_assembly_data <- function(groups = 24L, repeats = 8L) {
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  data.frame(
    y = rep(0:5, length.out = length(group)),
    w = w_group[group],
    id = factor(group)
  )
}

test_that("zero-inflated NB2 SD regression assembles one ordinary mu intercept", {
  dat <- zi_nbinom2_sd_assembly_data()
  spec <- drm_build_nbinom2_spec(
    bf(y ~ 1 + (1 | id), sigma ~ 1, zi ~ 1, sd(id) ~ w),
    dat
  )

  expect_identical(spec$model_type, "zi_nbinom2")
  expect_equal(spec$random$mu$n_re, nlevels(dat$id))
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true("u_mu" %in% spec$random_names)
})

test_that("zero-inflated NB2 SD regression assembles a selected independent mu slope", {
  dat <- zi_nbinom2_sd_assembly_data()
  dat$x <- rep(seq(-1, 1, length.out = 8L), times = nlevels(dat$id))
  spec <- drm_build_nbinom2_spec(
    bf(y ~ 1 + (0 + x | id), sigma ~ 1, zi ~ 1,
       sd(id, coef = "x") ~ w),
    dat
  )

  expect_identical(spec$model_type, "zi_nbinom2")
  expect_identical(spec$random$mu$labels, "(0 + x | id)")
  expect_equal(spec$random$mu$n_re, nlevels(dat$id))
  expect_identical(spec$random_scale$mu$dpars, 'sd(id, coef = "x")')
  expect_true(all(spec$random_scale$mu$re_sd_row >= 0L))
})

zi_nbinom2_sd_fixture <- function(groups = 64L, repeats = 20L,
                                  seed = 2026101831L) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  x <- stats::rnorm(length(group))
  alpha <- c(`(Intercept)` = log(0.55), w = 0.4)
  sigma <- 0.32
  zi <- 0.18
  u <- stats::rnorm(groups)
  mu <- exp(0.25 + 0.3 * x + exp(alpha[[1L]] + alpha[[2L]] * w_group[group]) * u[group])
  structural_zero <- stats::rbinom(length(group), 1L, zi) == 1L
  y <- stats::rnbinom(length(group), size = 1 / sigma^2, mu = mu)
  y[structural_zero] <- 0L
  list(
    data = data.frame(y = y, x = x, w = w_group[group], id = factor(group)),
    alpha = alpha,
    sigma = sigma,
    zi = zi
  )
}

zi_nbinom2_sd_laplace_oracle <- function(data, beta_mu, beta_sigma, beta_zi,
                                         alpha, random_coef = NULL) {
  rows <- split(seq_len(nrow(data)), data$id)
  sum(vapply(rows, function(i) {
    eta <- beta_mu[[1L]] + beta_mu[["x"]] * data$x[i]
    eta_zi <- beta_zi[[1L]]
    sigma <- exp(beta_sigma[[1L]])
    size <- 1 / sigma^2
    tau <- exp(alpha[[1L]] + alpha[[2L]] * data$w[i[[1L]]])
    nll <- function(u) {
      re_design <- if (is.null(random_coef)) 1 else data[[random_coef]][i]
      mu <- exp(eta + tau * u * re_design)
      log_nb <- stats::dnbinom(data$y[i], size = size, mu = mu, log = TRUE)
      log_dens <- ifelse(
        data$y[i] == 0,
        log(plogis(eta_zi) + (1 - plogis(eta_zi)) * exp(log_nb)),
        log1p(-plogis(eta_zi)) + log_nb
      )
      -sum(log_dens) - stats::dnorm(u, log = TRUE)
    }
    opt <- stats::optimize(nll, interval = c(-8, 8), tol = 1e-10)
    h <- stats::optimHess(opt$minimum, nll)
    -nll(opt$minimum) - 0.5 * log(h) + 0.5 * log(2 * pi)
  }, numeric(1L)))
}

zi_nbinom2_sd_slope_fixture <- function(groups = 64L, repeats = 24L,
                                        seed = 2026101834L) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  x <- stats::rnorm(length(group))
  alpha <- c(`(Intercept)` = log(0.45), w = 0.35)
  sigma <- 0.32
  zi <- 0.18
  u <- stats::rnorm(groups)
  mu <- exp(0.2 + 0.25 * x + exp(alpha[[1L]] + alpha[[2L]] * w_group[group]) *
              u[group] * x)
  structural_zero <- stats::rbinom(length(group), 1, zi) == 1
  y <- stats::rnbinom(length(group), size = 1 / sigma^2, mu = mu)
  y[structural_zero] <- 0L
  list(
    data = data.frame(y = y, x = x, w = w_group[group], id = factor(group)),
    alpha = alpha,
    sigma = sigma,
    zi = zi
  )
}

test_that("zero-inflated NB2 SD intercept recovers with an independent Laplace check", {
  sim <- zi_nbinom2_sd_fixture()
  fit <- drmTMB::drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, zi ~ 1, sd(id) ~ w),
    family = nbinom2(), data = sim$data
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  alpha_hat <- stats::coef(fit, "sd(id)")
  expect_named(alpha_hat, c("(Intercept)", "w"))
  expect_gt(alpha_hat[["w"]], 0)
  expect_lt(abs(alpha_hat[["w"]] - sim$alpha[["w"]]), 0.5)
  expect_named(fit$sdpars, "sd(id)")
  sd_prediction <- stats::predict(fit, dpar = "sd(id)")
  expect_equal(length(sd_prediction), nlevels(sim$data$id))

  oracle <- zi_nbinom2_sd_laplace_oracle(
    sim$data,
    stats::coef(fit, "mu"),
    stats::coef(fit, "sigma"),
    stats::coef(fit, "zi"),
    alpha_hat
  )
  expect_equal(as.numeric(stats::logLik(fit)), oracle, tolerance = 1e-4)

  wrong_group_data <- sim$data
  group_w <- tapply(wrong_group_data$w, wrong_group_data$id, `[`, 1L)
  wrong_group_data$w <- rev(unname(group_w))[as.integer(wrong_group_data$id)]
  wrong_oracle <- zi_nbinom2_sd_laplace_oracle(
    wrong_group_data,
    stats::coef(fit, "mu"),
    stats::coef(fit, "sigma"),
    stats::coef(fit, "zi"),
    alpha_hat
  )
  expect_gt(abs(oracle - wrong_oracle), 1e-5)

  restored_path <- tempfile(fileext = ".rds")
  on.exit(unlink(restored_path), add = TRUE)
  saveRDS(fit, restored_path)
  restored <- readRDS(restored_path)
  expect_equal(stats::coef(restored, "sd(id)"), alpha_hat)
  expect_equal(stats::predict(restored, dpar = "sd(id)"), sd_prediction)

  simulated <- stats::simulate(fit, nsim = 2L, seed = 2026101832L)
  expect_equal(dim(simulated), c(nrow(sim$data), 2L))
  expect_true(all(as.matrix(simulated) >= 0))
})

test_that("zero-inflated NB2 independent slope SD recovers with a Laplace check", {
  sim <- zi_nbinom2_sd_slope_fixture()
  fit <- drmTMB::drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, zi ~ 1,
       sd(id, coef = "x") ~ w),
    family = nbinom2(), data = sim$data
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  alpha_hat <- stats::coef(fit, 'sd(id, coef = "x")')
  expect_named(alpha_hat, c("(Intercept)", "w"))
  expect_gt(alpha_hat[["w"]], 0)
  expect_lt(abs(alpha_hat[["w"]] - sim$alpha[["w"]]), 0.55)
  expect_named(fit$sdpars, 'sd(id, coef = "x")')

  oracle <- zi_nbinom2_sd_laplace_oracle(
    sim$data,
    stats::coef(fit, "mu"),
    stats::coef(fit, "sigma"),
    stats::coef(fit, "zi"),
    alpha_hat,
    random_coef = "x"
  )
  expect_equal(as.numeric(stats::logLik(fit)), oracle, tolerance = 1e-4)

  sd_prediction <- stats::predict(fit, dpar = 'sd(id, coef = "x")')
  expect_equal(length(sd_prediction), nlevels(sim$data$id))
  expect_true(all(is.finite(sd_prediction) & sd_prediction > 0))
})

test_that("zero-inflated NB2 SD target rejects a random slope and varying group predictor", {
  dat <- zi_nbinom2_sd_fixture(groups = 16L, repeats = 4L)$data
  dat$x <- stats::rnorm(nrow(dat))
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ 1 + (1 + x | id), sigma ~ 1, zi ~ 1, sd(id) ~ w), dat
    ),
    "intercept"
  )

  dat$w <- stats::rnorm(nrow(dat))
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ 1 + (1 | id), sigma ~ 1, zi ~ 1, sd(id) ~ w), dat
    ),
    "varies within id level"
  )
})

test_that("zero-inflated NB2 SD regression rejects unvalidated combinations", {
  sim <- zi_nbinom2_sd_fixture(groups = 16L, repeats = 4L)
  missing_data <- sim$data
  missing_data$y[[1L]] <- NA_integer_
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ 1 + (1 | id), sigma ~ 1, zi ~ 1, sd(id) ~ w),
      missing_data,
      missing = miss_control(response = "include")
    ),
    "currently requires complete data"
  )

  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ 1 + (1 | id), sigma ~ 1 + (1 | id), zi ~ 1, sd(id) ~ w),
      sim$data
    ),
    "Only the exact zero-inflated NB2"
  )

  coords <- data.frame(x = seq_len(nlevels(sim$data$id)),
                       y = rev(seq_len(nlevels(sim$data$id))))
  rownames(coords) <- levels(sim$data$id)
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ 1 + spatial(1 | id, coords = coords), sigma ~ 1,
         zi ~ 1, sd(id) ~ w),
      sim$data
    ),
    "not yet admitted with structured random effects"
  )
})

test_that("constant zero-inflated NB2 SD formula preserves the existing likelihood", {
  sim <- zi_nbinom2_sd_fixture(groups = 28L, repeats = 8L,
                               seed = 2026101833L)
  ordinary <- drmTMB::drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, zi ~ 1),
    family = nbinom2(), data = sim$data
  )
  scaled <- drmTMB::drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, zi ~ 1, sd(id) ~ 1),
    family = nbinom2(), data = sim$data
  )
  expect_equal(ordinary$opt$convergence, 0L)
  expect_equal(scaled$opt$convergence, 0L)
  expect_true(isTRUE(ordinary$sdr$pdHess))
  expect_true(isTRUE(scaled$sdr$pdHess))
  expect_equal(as.numeric(stats::logLik(scaled)),
               as.numeric(stats::logLik(ordinary)), tolerance = 1e-5)
})
