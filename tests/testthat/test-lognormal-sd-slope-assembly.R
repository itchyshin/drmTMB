test_that("lognormal SD can target one independent mu slope", {
  groups <- 8L
  repeats <- 3L
  group <- rep(seq_len(groups), each = repeats)
  dat <- data.frame(
    y = exp(0.2 + seq_len(length(group)) / 100),
    x = rep(seq(-1, 1, length.out = repeats), groups),
    w = rep(seq(-1, 1, length.out = groups), each = repeats),
    z = cos(seq_along(group) / 4),
    id = factor(group)
  )
  key <- 'sd(id, dpar = "mu", coef = "x")'

  spec <- drm_build_lognormal_ls_spec(bf(
    y ~ x + (0 + x | id),
    sigma ~ z,
    sd(id, dpar = "mu", coef = "x") ~ w
  ), dat)

  expect_identical(spec$random_scale$mu$dpars, key)
  expect_identical(spec$random_scale$mu$target_identity[[key]]$dpar, "mu")
  expect_identical(spec$random_scale$mu$target_identity[[key]]$coef, "x")
  expect_identical(spec$random_scale$mu$re_sd_row0, seq_len(groups) - 1L)
  expect_equal(
    unname(spec$random_scale$mu$X_list[[key]][, "w"]),
    seq(-1, 1, length.out = groups)
  )
})

test_that("lognormal independent-slope SD recovers and matches its marginal likelihood", {
  set.seed(20261021)
  groups <- 96L
  repeats <- 10L
  group <- rep(seq_len(groups), each = repeats)
  id <- factor(paste0("g", group), levels = paste0("g", seq_len(groups)))
  x <- rep(seq(-1.5, 1.5, length.out = repeats), groups)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[group]
  alpha <- c(`(Intercept)` = log(0.4), w = 0.35)
  sigma <- 0.4
  tau <- exp(alpha[[1L]] + alpha[[2L]] * w_group)
  slope <- stats::rnorm(groups, sd = tau)
  dat <- data.frame(
    y = exp(0.25 + 0.4 * x + slope[group] * x + stats::rnorm(length(x), sd = sigma)),
    x = x,
    w = w,
    id = id
  )
  target <- 'sd(id, dpar = "mu", coef = "x")'

  fit <- drmTMB::drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, sd(id, dpar = "mu", coef = "x") ~ w),
    family = lognormal(), data = dat
  )

  expect_identical(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  alpha_hat <- coef(fit, target)
  expect_lt(abs(alpha_hat[["w"]] - alpha[["w"]]), 0.25)
  sd_prediction <- predict(fit, dpar = target)
  expect_named(sd_prediction, levels(dat$id))
  expect_gt(sd_prediction[[length(sd_prediction)]], sd_prediction[[1L]])

  beta_hat <- coef(fit, "mu")
  sigma_hat <- exp(unname(coef(fit, "sigma")[["(Intercept)"]]))
  marginal_loglik <- 0
  for (g in levels(dat$id)) {
    idx <- which(dat$id == g)
    x_g <- dat$x[idx]
    tau_g <- exp(alpha_hat[["(Intercept)"]] + alpha_hat[["w"]] * dat$w[idx[[1L]]])
    V_g <- tau_g^2 * tcrossprod(x_g) + diag(sigma_hat^2, length(idx))
    chol_g <- chol(V_g)
    residual <- log(dat$y[idx]) - beta_hat[["(Intercept)"]] - beta_hat[["x"]] * x_g
    whitened <- forwardsolve(t(chol_g), residual)
    marginal_loglik <- marginal_loglik - 0.5 * (
      length(idx) * log(2 * pi) +
        2 * sum(log(diag(chol_g))) + sum(whitened^2)
    ) - sum(log(dat$y[idx]))
  }
  expect_equal(as.numeric(logLik(fit)), marginal_loglik, tolerance = 1e-5)

  fit_constant <- drmTMB::drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, sd(id, dpar = "mu", coef = "x") ~ 1),
    family = lognormal(), data = dat
  )
  fit_ordinary <- drmTMB::drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1),
    family = lognormal(), data = dat
  )
  expect_identical(fit_constant$opt$convergence, 0L)
  expect_true(isTRUE(fit_constant$sdr$pdHess))
  expect_identical(fit_ordinary$opt$convergence, 0L)
  expect_true(isTRUE(fit_ordinary$sdr$pdHess))
  expect_equal(as.numeric(logLik(fit_constant)), as.numeric(logLik(fit_ordinary)),
               tolerance = 1e-5)
  simulated <- stats::simulate(fit, nsim = 1L, seed = 20261022L)
  expect_true(all(is.finite(as.matrix(simulated)) & as.matrix(simulated) > 0))
})
