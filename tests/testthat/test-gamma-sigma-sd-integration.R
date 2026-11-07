gamma_sigma_sd_recovery_data <- function(
  groups = 56L,
  repeats = 18L,
  slope = 0.45,
  seed = 20261025L
) {
  set.seed(seed)
  group_w <- seq(-1, 1, length.out = groups)
  tau <- exp(-1.05 + slope * group_w)
  b_sigma <- stats::rnorm(groups, sd = tau)
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  x <- stats::rnorm(length(id))
  mu <- exp(0.2 + 0.25 * x)
  sigma <- exp(-0.55 + b_sigma[id_index])
  y <- stats::rgamma(
    length(id),
    shape = 1 / sigma^2,
    scale = mu * sigma^2
  )
  list(
    data = data.frame(y, x, w = group_w[id_index], id),
    truth = c("(Intercept)" = -1.05, w = slope),
    group_w = group_w
  )
}

test_that("Gamma sigma random-effect SD recovers a group-scale trend", {
  sim <- gamma_sigma_sd_recovery_data()
  target <- 'sd(id, dpar = "sigma")'
  fit <- drmTMB(
    bf(
      y ~ x,
      sigma ~ 1 + (1 | id),
      sd(id, dpar = "sigma") ~ w
    ),
    family = Gamma(link = "log"),
    data = sim$data,
    control = drm_control(optimizer_preset = "careful")
  )

  estimate <- stats::coef(fit, dpar = target)
  vc <- stats::vcov(fit)
  coefficient_labels <- paste0(target, ":", names(sim$truth))
  standard_error <- sqrt(diag(vc[coefficient_labels, coefficient_labels]))
  expect_true(is_converged(fit))
  expect_named(estimate, names(sim$truth))
  expect_true(all(is.finite(standard_error) & standard_error > 0))
  expect_lt(
    max(abs(unname(estimate) - unname(sim$truth)) / standard_error),
    2.5
  )

  predicted <- predict(fit, dpar = target)
  expect_length(predicted, length(sim$group_w))
  expect_true(all(is.finite(predicted) & predicted > 0))
  expect_gt(predicted[[length(predicted)]], predicted[[1L]])

  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  sigma_re <- drmTMB:::sigma_random_effect_contribution(fit, dpar = "sigma")
  fixed_sigma <- as.vector(fit$model$X$sigma %*% stats::coef(fit, "sigma"))
  expect_equal(sigma_link, fixed_sigma + sigma_re, tolerance = 1e-8)
  expect_equal(sigma(fit), exp(sigma_link), tolerance = 1e-8)

  simulated <- simulate(fit, nsim = 1L, seed = 20261026L)
  expect_equal(nrow(simulated), nrow(sim$data))
  expect_true(all(is.finite(as.matrix(simulated))))

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  reloaded <- readRDS(path)
  expect_equal(
    predict(reloaded, dpar = target),
    predicted
  )
})
