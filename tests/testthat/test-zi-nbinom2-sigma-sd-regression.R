test_that("zero-inflated NB2 sigma SD formula assembles on its matching random intercept", {
  group <- rep(seq_len(12L), each = 5L)
  dat <- data.frame(
    y = rep(0:4, length.out = length(group)),
    id = factor(group),
    w = rep(seq(-1, 1, length.out = 12L), each = 5L)
  )
  spec <- drmTMB:::drm_build_nbinom2_spec(
    drmTMB::bf(
      y ~ 1,
      sigma ~ 1 + (1 | id),
      zi ~ 1,
      sd(id, dpar = "sigma") ~ w
    ),
    dat
  )

  expect_identical(spec$model_type, "zi_nbinom2")
  expect_identical(spec$random_scale$sigma$dpars, 'sd(id, dpar = "sigma")')
  expect_identical(spec$tmb_data$has_sd_sigma_model, 1L)
  expect_length(spec$start$beta_sd_sigma, 2L)
  expect_true("u_sigma" %in% spec$random_names)
})

zi_nbinom2_sigma_sd_fixture <- function(groups = 96L, repeats = 30L,
                                        seed = 2026102511L,
                                        sd_slope = 0.38) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  group_w <- seq(-1, 1, length.out = groups)
  alpha <- c(`(Intercept)` = log(0.28), w = sd_slope)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * group_w)
  u <- stats::rnorm(groups, sd = tau)
  mu <- exp(0.45)
  sigma <- exp(-0.55 + u[group])
  zi <- 0.16
  y <- stats::rnbinom(length(group), size = 1 / sigma^2, mu = mu)
  y[stats::rbinom(length(group), 1L, zi) == 1L] <- 0L
  list(
    data = data.frame(
      y = y,
      id = factor(group),
      w = group_w[group]
    ),
    alpha = alpha,
    group_w = stats::setNames(group_w, levels(factor(group)))
  )
}

test_that("zero-inflated NB2 sigma SD regression recovers and predicts group SDs", {
  sim <- zi_nbinom2_sigma_sd_fixture()
  target <- 'sd(id, dpar = "sigma")'
  fit <- drmTMB::drmTMB(
    drmTMB::bf(
      y ~ 1,
      sigma ~ 1 + (1 | id),
      zi ~ 1,
      sd(id, dpar = "sigma") ~ w
    ),
    family = nbinom2(),
    data = sim$data,
    control = list(eval.max = 600, iter.max = 600)
  )

  alpha_hat <- stats::coef(fit, dpar = target)
  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_named(alpha_hat, names(sim$alpha))
  expect_lt(abs(alpha_hat[["w"]] - sim$alpha[["w"]]), 0.55)
  expect_true(all(is.finite(stats::vcov(fit, dpar = target))))

  expected_sd <- exp(alpha_hat[[1L]] + alpha_hat[[2L]] * sim$group_w)
  predicted_sd <- stats::predict(fit, dpar = target)
  expect_named(predicted_sd, names(sim$group_w))
  expect_equal(unname(predicted_sd), unname(expected_sd), tolerance = 1e-10)

  fixed_sigma <- as.vector(fit$model$X$sigma %*% stats::coef(fit, "sigma"))
  sigma_link <- stats::predict(fit, dpar = "sigma", type = "link")
  sigma_re <- drmTMB:::sigma_random_effect_contribution(fit, dpar = "sigma")
  expect_equal(sigma_link, fixed_sigma + sigma_re, tolerance = 1e-8)
  expect_equal(stats::sigma(fit), exp(sigma_link), tolerance = 1e-8)

  restored_path <- tempfile(fileext = ".rds")
  on.exit(unlink(restored_path), add = TRUE)
  saveRDS(fit, restored_path)
  restored <- readRDS(restored_path)
  expect_equal(stats::coef(restored, dpar = target), alpha_hat)
  expect_equal(stats::predict(restored, dpar = target), predicted_sd)

  simulated <- stats::simulate(fit, nsim = 2L, seed = 2026102513L)
  expect_equal(dim(simulated), c(nrow(sim$data), 2L))
  expect_true(all(as.matrix(simulated) >= 0))
})

test_that("constant ZI-NB2 sigma SD formula preserves the constant-SD likelihood", {
  sim <- zi_nbinom2_sigma_sd_fixture(
    groups = 96L, repeats = 30L, seed = 2026102512L, sd_slope = 0
  )
  common <- list(family = nbinom2(), data = sim$data,
                 control = list(eval.max = 600, iter.max = 600))
  constant <- drmTMB::drmTMB(
    drmTMB::bf(y ~ 1, sigma ~ 1 + (1 | id), zi ~ 1),
    family = common$family, data = common$data, control = common$control
  )
  regression <- drmTMB::drmTMB(
    drmTMB::bf(y ~ 1, sigma ~ 1 + (1 | id), zi ~ 1,
               sd(id, dpar = "sigma") ~ 1),
    family = common$family, data = common$data, control = common$control
  )
  expect_equal(constant$opt$convergence, 0L)
  expect_equal(regression$opt$convergence, 0L)
  expect_true(isTRUE(constant$sdr$pdHess))
  expect_true(isTRUE(regression$sdr$pdHess))
  expect_equal(as.numeric(stats::logLik(regression)),
               as.numeric(stats::logLik(constant)), tolerance = 1e-5)
})

test_that("ZI-NB2 sigma SD design rejects within-group predictor variation", {
  sim <- zi_nbinom2_sigma_sd_fixture(groups = 12L, repeats = 5L)
  sim$data$w[[1L]] <- sim$data$w[[1L]] + 0.1
  expect_error(
    drmTMB:::drm_build_nbinom2_spec(
      drmTMB::bf(
        y ~ 1,
        sigma ~ 1 + (1 | id),
        zi ~ 1,
        sd(id, dpar = "sigma") ~ w
      ),
      sim$data
    ),
    "varies within id level"
  )
})
