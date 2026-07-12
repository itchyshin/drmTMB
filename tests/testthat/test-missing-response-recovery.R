test_that("Gaussian missing responses recover fixed and random parameters", {
  set.seed(2026071101)
  n_id <- 36L
  n_each <- 12L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rnorm(length(id))
  z <- rnorm(length(id))
  truth_mu <- c(0.35, 0.55)
  truth_sigma <- c(-0.25, 0.22)
  truth_sd <- 0.7
  u <- rnorm(n_id, sd = truth_sd)
  u <- u - mean(u)
  dat <- data.frame(id = id, x = x, z = z)
  dat$y <- rnorm(
    nrow(dat),
    truth_mu[[1L]] + truth_mu[[2L]] * x + u[id],
    exp(truth_sigma[[1L]] + truth_sigma[[2L]] * z)
  )
  dat <- missing_response_mask_mcar_within_group(
    dat, "y", "id", seed = 2026071102
  )
  expect_equal(mean(is.na(dat$y)), 0.25)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = dat,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )

  expect_lt(max(abs(unname(coef(fit, "mu")) - truth_mu)), 0.18)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - truth_sigma)), 0.15)
  expect_lt(max(abs(unname(fit$sdpars$mu) - truth_sd)), 0.25)
  expect_gt(cor(fit$random_effects$mu$values, u), 0.6)
  expect_equal(nobs(fit), 0.75 * nrow(dat))
})

test_that("bivariate Gaussian partial responses recover fixed and q2 parameters", {
  set.seed(2026071103)
  n_id <- 60L
  n_each <- 8L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rnorm(length(id))
  truth_mu1 <- c(0.2, 0.45)
  truth_mu2 <- c(-0.15, -0.35)
  truth_sigma <- c(0.35, 0.45)
  truth_sd <- c(0.55, 0.65)
  truth_group_rho <- 0.45
  truth_residual_rho <- 0.25
  u1 <- rnorm(n_id)
  u2 <- truth_group_rho * u1 +
    sqrt(1 - truth_group_rho^2) * rnorm(n_id)
  b1 <- truth_sd[[1L]] * u1
  b2 <- truth_sd[[2L]] * u2
  e1 <- rnorm(length(id))
  e2 <- truth_residual_rho * e1 +
    sqrt(1 - truth_residual_rho^2) * rnorm(length(id))
  dat <- data.frame(id = id, x = x)
  dat$y1 <- truth_mu1[[1L]] + truth_mu1[[2L]] * x + b1[id] +
    truth_sigma[[1L]] * e1
  dat$y2 <- truth_mu2[[1L]] + truth_mu2[[2L]] * x + b2[id] +
    truth_sigma[[2L]] * e2
  dat <- missing_response_mask_mcar_within_group(
    dat, "y1", "id", seed = 2026071104
  )
  dat <- missing_response_mask_mcar_within_group(
    dat, "y2", "id", seed = 2026071105
  )
  expect_equal(mean(is.na(dat$y1)), 0.25)
  expect_equal(mean(is.na(dat$y2)), 0.25)

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )

  expect_lt(max(abs(unname(coef(fit, "mu1")) - truth_mu1)), 0.22)
  expect_lt(max(abs(unname(coef(fit, "mu2")) - truth_mu2)), 0.18)
  expect_lt(
    max(abs(c(mean(sigma(fit)$sigma1), mean(sigma(fit)$sigma2)) - truth_sigma)),
    0.12
  )
  expect_lt(max(abs(unname(fit$sdpars$mu) - truth_sd)), 0.24)
  expect_lt(abs(unname(fit$corpars$mu) - truth_group_rho), 0.3)
  expect_lt(
    abs(tanh(unname(coef(fit, "rho12"))) - truth_residual_rho),
    0.14
  )
})

test_that("Poisson missing responses recover fixed and random parameters", {
  set.seed(2026071106)
  n_id <- 48L
  n_each <- 12L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rnorm(length(id))
  truth_mu <- c(0.35, -0.3)
  truth_sd <- 0.55
  u <- rnorm(n_id, sd = truth_sd)
  dat <- data.frame(id = id, x = x)
  dat$count <- rpois(nrow(dat), exp(truth_mu[[1L]] + truth_mu[[2L]] * x + u[id]))
  dat <- missing_response_mask_mcar_within_group(
    dat, "count", "id", seed = 2026071107
  )
  expect_equal(mean(is.na(dat$count)), 0.25)

  fit <- drmTMB(
    bf(count ~ x + (1 | id)),
    family = poisson(),
    data = dat,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )

  expect_lt(max(abs(unname(coef(fit, "mu")) - truth_mu)), 0.25)
  expect_lt(abs(unname(fit$sdpars$mu) - truth_sd), 0.25)
  expect_gt(cor(fit$random_effects$mu$values, u), 0.4)
})

test_that("NB2 missing responses recover fixed, dispersion, and random parameters", {
  set.seed(2026071108)
  n_id <- 48L
  n_each <- 12L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rnorm(length(id))
  z <- rnorm(length(id))
  truth_mu <- c(0.35, -0.25)
  truth_sigma <- c(-0.7, 0.2)
  truth_sd <- 0.45
  u <- rnorm(n_id, sd = truth_sd)
  mu <- exp(truth_mu[[1L]] + truth_mu[[2L]] * x + u[id])
  sigma_value <- exp(truth_sigma[[1L]] + truth_sigma[[2L]] * z)
  dat <- data.frame(id = id, x = x, z = z)
  dat$count <- rnbinom(nrow(dat), size = 1 / sigma_value^2, mu = mu)
  dat <- missing_response_mask_mcar_within_group(
    dat, "count", "id", seed = 2026071109
  )
  expect_equal(mean(is.na(dat$count)), 0.25)

  fit <- drmTMB(
    bf(count ~ x + (1 | id), sigma ~ z),
    family = nbinom2(),
    data = dat,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )

  expect_lt(max(abs(unname(coef(fit, "mu")) - truth_mu)), 0.25)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - truth_sigma)), 0.25)
  expect_lt(abs(unname(fit$sdpars$mu) - truth_sd), 0.3)
  expect_gt(cor(fit$random_effects$mu$values, u), 0.3)
})

test_that("beta missing responses recover fixed, dispersion, and random parameters", {
  set.seed(2026071110)
  n_id <- 48L
  n_each <- 12L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rnorm(length(id))
  z <- rnorm(length(id))
  truth_mu <- c(-0.3, 0.7)
  truth_sigma <- c(-0.85, 0.16)
  truth_sd <- 0.55
  u <- rnorm(n_id, sd = truth_sd)
  u <- u - mean(u)
  mu <- plogis(truth_mu[[1L]] + truth_mu[[2L]] * x + u[id])
  sigma_value <- exp(truth_sigma[[1L]] + truth_sigma[[2L]] * z)
  phi <- 1 / sigma_value^2
  dat <- data.frame(id = id, x = x, z = z)
  dat$prop <- rbeta(nrow(dat), mu * phi, (1 - mu) * phi)
  dat <- missing_response_mask_mcar_within_group(
    dat, "prop", "id", seed = 2026071111
  )
  expect_equal(mean(is.na(dat$prop)), 0.25)

  fit <- drmTMB(
    bf(prop ~ x + (1 | id), sigma ~ z),
    family = beta(),
    data = dat,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )

  expect_lt(max(abs(unname(coef(fit, "mu")) - truth_mu)), 0.25)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - truth_sigma)), 0.3)
  expect_lt(abs(unname(fit$sdpars$mu) - truth_sd), 0.3)
  expect_gt(cor(fit$random_effects$mu$values, u), 0.4)
})
