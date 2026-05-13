new_biv_gaussian_data <- function(
  n = 500,
  beta_rho12 = atanh(0.4),
  seed = 20260512
) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z1 = stats::rnorm(n),
    z2 = stats::rnorm(n),
    w = stats::rnorm(n)
  )
  beta_mu1 <- c(0.25, 0.55)
  beta_mu2 <- c(-0.15, -0.4)
  beta_sigma1 <- c(-0.35, 0.25)
  beta_sigma2 <- c(0.05, -0.2)

  mu1 <- beta_mu1[[1L]] + beta_mu1[[2L]] * dat$x
  mu2 <- beta_mu2[[1L]] + beta_mu2[[2L]] * dat$x
  sigma1 <- exp(beta_sigma1[[1L]] + beta_sigma1[[2L]] * dat$z1)
  sigma2 <- exp(beta_sigma2[[1L]] + beta_sigma2[[2L]] * dat$z2)
  eta_rho12 <- beta_rho12[[1L]] +
    if (length(beta_rho12) > 1L) {
      beta_rho12[[2L]] * dat$w
    } else {
      0
    }
  rho12 <- tanh(eta_rho12)

  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  dat$y1 <- mu1 + sigma1 * e1
  dat$y2 <- mu2 + sigma2 * e2

  list(
    data = dat,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    beta_sigma1 = beta_sigma1,
    beta_sigma2 = beta_sigma2,
    beta_rho12 = beta_rho12
  )
}

mvn_loglik_biv <- function(y, mu, Sigma) {
  U <- chol(Sigma)
  z <- forwardsolve(t(U), y - mu)
  -0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(U))) + sum(z^2))
}

new_biv_gaussian_known_v_data <- function(
  n = 160,
  residual_rho = -0.35,
  sampling_cor = 0.6,
  seed = 20260516
) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n))
  beta_mu1 <- c(0.2, 0.5)
  beta_mu2 <- c(-0.1, -0.35)
  sigma1 <- 0.45
  sigma2 <- 0.55
  mu1 <- beta_mu1[[1L]] + beta_mu1[[2L]] * dat$x
  mu2 <- beta_mu2[[1L]] + beta_mu2[[2L]] * dat$x
  v1 <- stats::runif(n, min = 0.01, max = 0.04)
  v2 <- stats::runif(n, min = 0.01, max = 0.05)
  V <- meta_vcov_bivariate(v1 = v1, v2 = v2, cor12 = sampling_cor)

  y_stack <- numeric(2L * n)
  for (i in seq_len(n)) {
    S_i <- matrix(
      c(
        v1[[i]] + sigma1^2,
        sampling_cor * sqrt(v1[[i]] * v2[[i]]) + residual_rho * sigma1 * sigma2,
        sampling_cor * sqrt(v1[[i]] * v2[[i]]) + residual_rho * sigma1 * sigma2,
        v2[[i]] + sigma2^2
      ),
      nrow = 2L
    )
    y_stack[(2L * i - 1L):(2L * i)] <- as.vector(
      c(mu1[[i]], mu2[[i]]) + t(chol(S_i)) %*% stats::rnorm(2L)
    )
  }
  dat$y1 <- y_stack[seq.int(1L, by = 2L, length.out = n)]
  dat$y2 <- y_stack[seq.int(2L, by = 2L, length.out = n)]

  list(
    data = dat,
    V = V,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    sigma1 = sigma1,
    sigma2 = sigma2,
    residual_rho = residual_rho,
    sampling_cor = sampling_cor
  )
}

new_biv_gaussian_mu_re_data <- function(
  n_id = 60,
  n_each = 7,
  rho_group = 0.45,
  residual_rho = 0.25,
  seed = 2026051101
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  beta_mu1 <- c(0.2, 0.45)
  beta_mu2 <- c(-0.15, -0.35)
  sigma1 <- 0.35
  sigma2 <- 0.45
  sd_mu1 <- 0.55
  sd_mu2 <- 0.65

  u1 <- stats::rnorm(n_id)
  u2 <- rho_group * u1 + sqrt(1 - rho_group^2) * stats::rnorm(n_id)
  b1 <- sd_mu1 * u1
  b2 <- sd_mu2 * u2
  e1 <- stats::rnorm(n)
  e2 <- residual_rho * e1 + sqrt(1 - residual_rho^2) * stats::rnorm(n)

  dat <- data.frame(id = id, x = x)
  dat$y1 <- beta_mu1[[1L]] + beta_mu1[[2L]] * x + b1[id] + sigma1 * e1
  dat$y2 <- beta_mu2[[1L]] + beta_mu2[[2L]] * x + b2[id] + sigma2 * e2

  list(
    data = dat,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    sigma1 = sigma1,
    sigma2 = sigma2,
    sd_mu = c(
      "mu1:(1 | p | id)" = sd_mu1,
      "mu2:(1 | p | id)" = sd_mu2
    ),
    rho_group = rho_group,
    residual_rho = residual_rho
  )
}

new_biv_gaussian_sigma_re_data <- function(
  n_id = 48,
  n_each = 8,
  rho_scale = 0.45,
  residual_rho = 0.20,
  seed = 2026051201
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z1 <- stats::rnorm(n_id)
  z2 <- stats::rnorm(n_id)
  beta_mu1 <- c(0.2, 0.45)
  beta_mu2 <- c(-0.1, -0.35)
  beta_sigma1 <- log(0.38)
  beta_sigma2 <- log(0.52)
  sd_sigma1 <- 0.28
  sd_sigma2 <- 0.34

  b1 <- sd_sigma1 * z1
  b2 <- sd_sigma2 * (rho_scale * z1 + sqrt(1 - rho_scale^2) * z2)
  e1 <- stats::rnorm(n)
  e2 <- residual_rho * e1 + sqrt(1 - residual_rho^2) * stats::rnorm(n)

  dat <- data.frame(id = id, x = x)
  dat$y1 <- beta_mu1[[1L]] + beta_mu1[[2L]] * x + exp(beta_sigma1 + b1[id]) * e1
  dat$y2 <- beta_mu2[[1L]] + beta_mu2[[2L]] * x + exp(beta_sigma2 + b2[id]) * e2

  list(
    data = dat,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    beta_sigma = c(beta_sigma1, beta_sigma2),
    sd_sigma = c(
      "sigma1:(1 | p | id)" = sd_sigma1,
      "sigma2:(1 | p | id)" = sd_sigma2
    ),
    rho_scale = rho_scale,
    residual_rho = residual_rho
  )
}

new_biv_gaussian_joint_re_data <- function(
  n_id = 70,
  n_each = 9,
  rho_mu = 0.45,
  rho_scale = 0.35,
  beta_rho12 = c(atanh(0.12), 0.22),
  seed = 2026051304
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  beta_mu1 <- c(0.15, 0.35)
  beta_mu2 <- c(-0.20, -0.30)
  beta_sigma1 <- log(0.38)
  beta_sigma2 <- log(0.52)
  sd_mu1 <- 0.50
  sd_mu2 <- 0.60
  sd_sigma1 <- 0.35
  sd_sigma2 <- 0.42

  z_mu1 <- stats::rnorm(n_id)
  z_mu2 <- rho_mu * z_mu1 + sqrt(1 - rho_mu^2) * stats::rnorm(n_id)
  z_sigma1 <- stats::rnorm(n_id)
  z_sigma2 <- rho_scale * z_sigma1 + sqrt(1 - rho_scale^2) * stats::rnorm(n_id)
  b_mu1 <- sd_mu1 * z_mu1
  b_mu2 <- sd_mu2 * z_mu2
  b_sigma1 <- sd_sigma1 * z_sigma1
  b_sigma2 <- sd_sigma2 * z_sigma2
  rho12 <- tanh(beta_rho12[[1L]] + beta_rho12[[2L]] * x)
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)

  dat <- data.frame(id = id, x = x)
  dat$y1 <- beta_mu1[[1L]] +
    beta_mu1[[2L]] * x +
    b_mu1[id] +
    exp(beta_sigma1 + b_sigma1[id]) * e1
  dat$y2 <- beta_mu2[[1L]] +
    beta_mu2[[2L]] * x +
    b_mu2[id] +
    exp(beta_sigma2 + b_sigma2[id]) * e2

  list(
    data = dat,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    beta_sigma = c(beta_sigma1, beta_sigma2),
    sd_mu = c(
      "mu1:(1 | pm | id)" = sd_mu1,
      "mu2:(1 | pm | id)" = sd_mu2
    ),
    sd_sigma = c(
      "sigma1:(1 | ps | id)" = sd_sigma1,
      "sigma2:(1 | ps | id)" = sd_sigma2
    ),
    rho_mu = rho_mu,
    rho_scale = rho_scale,
    beta_rho12 = beta_rho12
  )
}

expect_abs_error_below <- function(actual, expected, tolerance) {
  expect_lt(max(abs(unname(actual) - unname(expected))), tolerance)
}

test_that("drmTMB fits bivariate Gaussian models with constant rho12", {
  sim <- new_biv_gaussian_data(n = 900, beta_rho12 = atanh(0.4))

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_abs_error_below(coef(fit, "mu1"), sim$beta_mu1, 0.12)
  expect_abs_error_below(coef(fit, "mu2"), sim$beta_mu2, 0.12)
  expect_abs_error_below(coef(fit, "sigma1"), sim$beta_sigma1, 0.12)
  expect_abs_error_below(coef(fit, "sigma2"), sim$beta_sigma2, 0.12)
  expect_abs_error_below(coef(fit, "rho12"), sim$beta_rho12, 0.12)
  expect_length(predict(fit), nrow(sim$data))
  expect_true(all(abs(predict(fit, dpar = "rho12")) < 1))
  expect_equal(rho12(fit), predict(fit, dpar = "rho12"), tolerance = 1e-12)
  expect_equal(
    rho12(fit, type = "link"),
    predict(fit, dpar = "rho12", type = "link"),
    tolerance = 1e-12
  )
})

test_that("bivariate Gaussian supports labelled mu1/mu2 random-intercept covariance blocks", {
  sim <- new_biv_gaussian_mu_re_data()

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = sim$data
  )

  fixed_mu1 <- as.vector(
    stats::model.matrix(~x, sim$data) %*% coef(fit, "mu1")
  )
  fixed_mu2 <- as.vector(
    stats::model.matrix(~x, sim$data) %*% coef(fit, "mu2")
  )
  pairs <- corpairs(fit)
  group_pair <- pairs[pairs$level == "group", , drop = FALSE]
  residual_pair <- pairs[pairs$level == "residual", , drop = FALSE]

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_abs_error_below(coef(fit, "mu1"), sim$beta_mu1, 0.22)
  expect_abs_error_below(coef(fit, "mu2"), sim$beta_mu2, 0.15)
  expect_abs_error_below(
    c(mean(stats::sigma(fit)$sigma1), mean(stats::sigma(fit)$sigma2)),
    c(sim$sigma1, sim$sigma2),
    0.12
  )
  expect_abs_error_below(fit$sdpars$mu, sim$sd_mu, 0.22)
  expect_lt(abs(unname(fit$corpars$mu) - sim$rho_group), 0.28)
  expect_lt(abs(tanh(unname(coef(fit, "rho12"))) - sim$residual_rho), 0.12)
  expect_named(
    fit$corpars$mu,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)"
  )
  expect_equal(length(fit$random_effects$mu$values), 2 * nlevels(sim$data$id))
  expect_gt(stats::sd(predict(fit, dpar = "mu1") - fixed_mu1), 0.05)
  expect_gt(stats::sd(predict(fit, dpar = "mu2") - fixed_mu2), 0.05)
  expect_equal(
    predict(fit, newdata = sim$data[1:3, ], dpar = "mu1"),
    fixed_mu1[1:3],
    tolerance = 1e-12
  )
  expect_equal(group_pair$from_dpar, "mu1")
  expect_equal(group_pair$to_dpar, "mu2")
  expect_equal(group_pair$group, "id")
  expect_equal(group_pair$block, "p")
  expect_equal(group_pair$from_response, "y1")
  expect_equal(group_pair$to_response, "y2")
  expect_equal(group_pair$class, "mean-mean")
  expect_equal(group_pair$estimate, unname(fit$corpars$mu), tolerance = 1e-12)
  expect_equal(residual_pair$from_dpar, "residual")
  expect_equal(residual_pair$to_dpar, "residual")
  expect_equal(residual_pair$parameter, "rho12")
  expect_equal(residual_pair$class, "residual")
  expect_equal(residual_pair$from_response, "y1")
  expect_equal(residual_pair$to_response, "y2")
  expect_equal(nrow(corpairs(fit, level = "group")), 1L)
  expect_equal(nrow(corpairs(fit, level = "residual")), 1L)
  expect_equal(nrow(corpairs(fit, class = "mean-mean")), 1L)
  expect_equal(nrow(corpairs(fit, class = "residual")), 1L)
  expect_equal(nrow(corpairs(fit, group = "id")), 1L)
  expect_equal(nrow(corpairs(fit, block = "p")), 1L)
  expect_equal(nrow(corpairs(fit, group = "missing")), 0L)
  expect_equal(nrow(corpairs(fit, block = "missing")), 0L)
})

test_that("bivariate Gaussian supports labelled sigma1/sigma2 random-intercept covariance blocks", {
  sim <- new_biv_gaussian_sigma_re_data()

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~ 1 + (1 | p | id),
      sigma2 = ~ 1 + (1 | p | id),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = sim$data,
    control = list(eval.max = 300, iter.max = 300)
  )

  fixed_sigma1 <- as.vector(
    stats::model.matrix(~1, sim$data) %*% coef(fit, "sigma1")
  )
  fixed_sigma2 <- as.vector(
    stats::model.matrix(~1, sim$data) %*% coef(fit, "sigma2")
  )
  sigma1_link <- predict(fit, dpar = "sigma1", type = "link")
  sigma2_link <- predict(fit, dpar = "sigma2", type = "link")
  pairs <- corpairs(fit)
  group_pair <- pairs[pairs$level == "group", , drop = FALSE]
  residual_pair <- pairs[pairs$level == "residual", , drop = FALSE]
  smry <- summary(fit)
  targets <- profile_targets(fit)
  chk <- check_drm(fit)
  scale_cov <- chk[chk$check == "biv_sigma_random_effect_covariance", ]

  sd_sigma1 <- "sd:sigma:sigma1:(1 | p | id)"
  sd_sigma2 <- "sd:sigma:sigma2:(1 | p | id)"
  cor_sigma <- "cor:sigma:cor(sigma1:(Intercept),sigma2:(Intercept) | p | id)"
  sigma_targets <- targets[
    match(c(sd_sigma1, sd_sigma2, cor_sigma), targets$parm),
  ]

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$sdr$pdHess, TRUE)
  expect_abs_error_below(coef(fit, "mu1"), sim$beta_mu1, 0.18)
  expect_abs_error_below(coef(fit, "mu2"), sim$beta_mu2, 0.18)
  expect_abs_error_below(coef(fit, "sigma1"), sim$beta_sigma[[1L]], 0.25)
  expect_abs_error_below(coef(fit, "sigma2"), sim$beta_sigma[[2L]], 0.25)
  expect_abs_error_below(fit$sdpars$sigma, sim$sd_sigma, 0.22)
  expect_lt(abs(unname(fit$corpars$sigma) - sim$rho_scale), 0.35)
  expect_lt(abs(tanh(unname(coef(fit, "rho12"))) - sim$residual_rho), 0.15)
  expect_named(
    fit$corpars$sigma,
    "cor(sigma1:(Intercept),sigma2:(Intercept) | p | id)"
  )
  expect_equal(
    length(fit$random_effects$sigma$values),
    2 * nlevels(sim$data$id)
  )
  expect_gt(stats::sd(sigma1_link - fixed_sigma1), 0.03)
  expect_gt(stats::sd(sigma2_link - fixed_sigma2), 0.03)
  expect_equal(stats::sigma(fit)$sigma1, exp(sigma1_link), tolerance = 1e-12)
  expect_equal(stats::sigma(fit)$sigma2, exp(sigma2_link), tolerance = 1e-12)
  expect_equal(
    predict(fit, newdata = sim$data[1:3, ], dpar = "sigma1", type = "link"),
    fixed_sigma1[1:3],
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = sim$data[1:3, ], dpar = "sigma2", type = "link"),
    fixed_sigma2[1:3],
    tolerance = 1e-12
  )

  expect_equal(group_pair$from_dpar, "sigma1")
  expect_equal(group_pair$to_dpar, "sigma2")
  expect_equal(group_pair$group, "id")
  expect_equal(group_pair$block, "p")
  expect_equal(group_pair$class, "scale-scale")
  expect_equal(
    group_pair$estimate,
    unname(fit$corpars$sigma),
    tolerance = 1e-12
  )
  expect_equal(residual_pair$parameter, "rho12")
  expect_equal(residual_pair$class, "residual")
  expect_equal(nrow(corpairs(fit, level = "group")), 1L)
  expect_equal(nrow(corpairs(fit, class = "scale-scale")), 1L)
  expect_equal(nrow(corpairs(fit, class = "mean-mean")), 0L)
  expect_equal(nrow(corpairs(fit, block = "p")), 1L)

  expect_true(all(
    c(sd_sigma1, sd_sigma2, cor_sigma) %in% rownames(smry$parameters)
  ))
  expect_equal(smry$parameters[sd_sigma1, "component"], "random-effect-sd")
  expect_equal(smry$parameters[sd_sigma2, "component"], "random-effect-sd")
  expect_equal(
    smry$parameters[cor_sigma, "component"],
    "random-effect-correlation"
  )
  expect_equal(
    smry$parameters[cor_sigma, "estimate"],
    unname(fit$corpars$sigma)
  )
  expect_equal(
    sigma_targets$tmb_parameter,
    c("log_sd_sigma", "log_sd_sigma", "eta_cor_sigma")
  )
  expect_equal(
    sigma_targets$target_class,
    c(
      "random-effect-sd",
      "random-effect-sd",
      "random-effect-correlation"
    )
  )
  expect_equal(sigma_targets$index, c(1L, 2L, 1L))
  expect_true(all(sigma_targets$profile_ready))
  expect_equal(scale_cov$status, "ok")
  expect_match(scale_cov$value, "n_groups=48")
  expect_match(scale_cov$value, "min_group_n=8")
  expect_match(scale_cov$message, "scale-scale")
})

test_that("bivariate Gaussian keeps mu and sigma covariance blocks distinct", {
  sim <- new_biv_gaussian_joint_re_data()

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | pm | id),
      mu2 = y2 ~ x + (1 | pm | id),
      sigma1 = ~ 1 + (1 | ps | id),
      sigma2 = ~ 1 + (1 | ps | id),
      rho12 = ~x
    ),
    family = biv_gaussian(),
    data = sim$data,
    control = list(eval.max = 500, iter.max = 500)
  )

  pairs <- corpairs(fit)
  group_pairs <- pairs[pairs$level == "group", , drop = FALSE]
  mean_pair <- pairs[pairs$class == "mean-mean", , drop = FALSE]
  scale_pair <- pairs[pairs$class == "scale-scale", , drop = FALSE]
  residual_pair <- pairs[pairs$class == "residual", , drop = FALSE]
  smry <- summary(fit)
  targets <- profile_targets(fit)
  chk <- check_drm(fit)
  cov_checks <- chk[
    chk$check %in%
      c(
        "biv_mu_random_effect_covariance",
        "biv_sigma_random_effect_covariance"
      ),
  ]

  target_names <- c(
    "sd:mu:mu1:(1 | pm | id)",
    "sd:mu:mu2:(1 | pm | id)",
    "cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | pm | id)",
    "sd:sigma:sigma1:(1 | ps | id)",
    "sd:sigma:sigma2:(1 | ps | id)",
    "cor:sigma:cor(sigma1:(Intercept),sigma2:(Intercept) | ps | id)"
  )
  joint_targets <- targets[match(target_names, targets$parm), ]

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$sdr$pdHess, TRUE)
  expect_abs_error_below(coef(fit, "mu1"), sim$beta_mu1, 0.12)
  expect_abs_error_below(coef(fit, "mu2"), sim$beta_mu2, 0.12)
  expect_abs_error_below(coef(fit, "sigma1"), sim$beta_sigma[[1L]], 0.18)
  expect_abs_error_below(coef(fit, "sigma2"), sim$beta_sigma[[2L]], 0.18)
  expect_abs_error_below(fit$sdpars$mu, sim$sd_mu, 0.18)
  expect_abs_error_below(fit$sdpars$sigma, sim$sd_sigma, 0.18)
  expect_lt(abs(unname(fit$corpars$mu) - sim$rho_mu), 0.25)
  expect_lt(abs(unname(fit$corpars$sigma) - sim$rho_scale), 0.18)
  expect_abs_error_below(coef(fit, "rho12"), sim$beta_rho12, 0.12)
  expect_equal(
    fit$model$random$mu$coef_names,
    c("(Intercept)", "(Intercept)")
  )
  expect_equal(fit$model$random$mu$group_names, c("id", "id"))
  expect_equal(fit$model$random$mu$covariance_labels, c("pm", "pm"))
  expect_equal(
    fit$model$random$sigma$coef_names,
    c("(Intercept)", "(Intercept)")
  )
  expect_equal(fit$model$random$sigma$group_names, c("id", "id"))
  expect_equal(fit$model$random$sigma$covariance_labels, c("ps", "ps"))

  expect_equal(nrow(pairs), 3L)
  expect_equal(nrow(group_pairs), 2L)
  expect_equal(nrow(mean_pair), 1L)
  expect_equal(nrow(scale_pair), 1L)
  expect_equal(nrow(residual_pair), 1L)
  expect_equal(nrow(corpairs(fit, group = "id")), 2L)
  expect_equal(nrow(corpairs(fit, block = "pm")), 1L)
  expect_equal(nrow(corpairs(fit, block = "ps")), 1L)
  expect_equal(mean_pair$block, "pm")
  expect_equal(mean_pair$from_dpar, "mu1")
  expect_equal(mean_pair$to_dpar, "mu2")
  expect_equal(mean_pair$estimate, unname(fit$corpars$mu), tolerance = 1e-12)
  expect_equal(scale_pair$block, "ps")
  expect_equal(scale_pair$from_dpar, "sigma1")
  expect_equal(scale_pair$to_dpar, "sigma2")
  expect_equal(
    scale_pair$estimate,
    unname(fit$corpars$sigma),
    tolerance = 1e-12
  )
  expect_equal(residual_pair$parameter, "rho12")
  expect_equal(residual_pair$modelled, TRUE)
  expect_gt(residual_pair$max - residual_pair$min, 0.05)

  expect_true(all(target_names %in% rownames(smry$parameters)))
  expect_equal(
    smry$parameters[target_names[3L], "component"],
    "random-effect-correlation"
  )
  expect_equal(
    smry$parameters[target_names[6L], "component"],
    "random-effect-correlation"
  )
  expect_equal(
    joint_targets$tmb_parameter,
    c(
      "log_sd_mu",
      "log_sd_mu",
      "eta_cor_mu",
      "log_sd_sigma",
      "log_sd_sigma",
      "eta_cor_sigma"
    )
  )
  expect_equal(joint_targets$index, c(1L, 2L, 1L, 1L, 2L, 1L))
  expect_true(all(joint_targets$profile_ready))
  expect_equal(cov_checks$status, c("ok", "ok"))
  expect_match(cov_checks$value, "n_groups=70", all = FALSE)
  expect_match(cov_checks$message, "covariance", all = FALSE)
  expect_match(cov_checks$message, "scale-scale", all = FALSE)
})

test_that("composed Gaussian family syntax routes to bivariate Gaussian", {
  sim <- new_biv_gaussian_data(
    n = 400,
    beta_rho12 = atanh(0.3),
    seed = 20260561
  )

  fit_c <- drmTMB(
    drm_formula(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )
  fit_list <- drmTMB(
    drm_formula(mu1 = y1 ~ x, mu2 = y2 ~ x),
    family = list(gaussian(), gaussian()),
    data = sim$data
  )

  expect_equal(fit_c$model$model_type, "biv_gaussian")
  expect_equal(fit_list$model$model_type, "biv_gaussian")
  expect_equal(fit_c$opt$convergence, 0)
  expect_equal(fit_list$opt$convergence, 0)
  expect_abs_error_below(coef(fit_c, "rho12"), atanh(0.3), 0.15)
})

test_that("mvbind shorthand expands to identical bivariate location formulas", {
  sim <- new_biv_gaussian_data(
    n = 360,
    beta_rho12 = atanh(0.25),
    seed = 20260562
  )

  fit_explicit <- drmTMB(
    drm_formula(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )
  fit_mvbind <- drmTMB(
    drm_formula(
      mvbind(y1, y2) ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )

  expect_equal(fit_mvbind$opt$convergence, 0)
  expect_equal(fit_mvbind$model$model_type, "biv_gaussian")
  expect_equal(
    fit_mvbind$model$dpars,
    c("mu1", "mu2", "sigma1", "sigma2", "rho12")
  )
  expect_equal(fit_mvbind$model$y1, sim$data$y1)
  expect_equal(fit_mvbind$model$y2, sim$data$y2)
  expect_equal(
    as.numeric(stats::logLik(fit_mvbind)),
    as.numeric(stats::logLik(fit_explicit)),
    tolerance = 1e-8
  )
  expect_equal(
    coef(fit_mvbind, "mu1"),
    coef(fit_explicit, "mu1"),
    tolerance = 1e-8
  )
  expect_equal(
    coef(fit_mvbind, "mu2"),
    coef(fit_explicit, "mu2"),
    tolerance = 1e-8
  )
})

test_that("drmTMB recovers predictor-dependent bivariate rho12", {
  sim <- new_biv_gaussian_data(
    n = 1200,
    beta_rho12 = c(-0.1, 0.45),
    seed = 20260513
  )

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~w
    ),
    family = biv_gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_abs_error_below(coef(fit, "rho12"), sim$beta_rho12, 0.12)
  expect_equal(
    predict(fit, dpar = "rho12", type = "link"),
    as.vector(stats::model.matrix(~w, sim$data) %*% coef(fit, "rho12")),
    tolerance = 1e-12
  )
  expect_true(all(abs(predict(fit, dpar = "rho12")) < 1))

  pearson <- residuals(fit, type = "pearson")
  expect_lt(abs(stats::cor(pearson[, "y1"], pearson[, "y2"])), 0.08)
  expect_lt(abs(stats::sd(pearson[, "y1"]) - 1), 0.1)
  expect_lt(abs(stats::sd(pearson[, "y2"]) - 1), 0.1)

  newdata <- data.frame(
    x = c(-0.5, 0.2),
    z1 = c(0, 1),
    z2 = c(1, 0),
    w = c(-1, 1)
  )
  expect_equal(length(predict(fit, newdata = newdata, dpar = "rho12")), 2)
  expect_equal(
    rho12(fit, newdata = newdata),
    predict(fit, newdata = newdata, dpar = "rho12"),
    tolerance = 1e-12
  )
})

test_that("bivariate rho12 handles near-zero and negative correlations", {
  targets <- c(near_zero = 0.02, negative = -0.45)
  for (i in seq_along(targets)) {
    sim <- new_biv_gaussian_data(
      n = 700,
      beta_rho12 = atanh(targets[[i]]),
      seed = 20260520 + i
    )
    fit <- drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~z1,
        sigma2 = ~z2,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = sim$data
    )

    expect_equal(fit$opt$convergence, 0)
    expect_lt(abs(tanh(unname(coef(fit, "rho12"))) - targets[[i]]), 0.12)
  }
})

test_that("bivariate rho12 handles high positive and high negative correlations", {
  targets <- c(high_positive = 0.8, high_negative = -0.8)
  for (i in seq_along(targets)) {
    sim <- new_biv_gaussian_data(
      n = 1200,
      beta_rho12 = atanh(targets[[i]]),
      seed = 20260620 + i
    )
    fit <- drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~z1,
        sigma2 = ~z2,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = sim$data
    )

    rho_hat <- predict(fit, dpar = "rho12")

    expect_equal(fit$opt$convergence, 0)
    expect_equal(fit$sdr$pdHess, TRUE)
    expect_lt(abs(tanh(unname(coef(fit, "rho12"))) - targets[[i]]), 0.15)
    expect_lt(max(abs(rho_hat)), 1)
    expect_equal(rho_hat, rho12(fit), tolerance = 1e-12)
  }
})

test_that("bivariate Gaussian methods return expected structures", {
  sim <- new_biv_gaussian_data(
    n = 160,
    beta_rho12 = atanh(0.25),
    seed = 20260514
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
    family = biv_gaussian(),
    data = sim$data
  )

  fitted_mu <- stats::fitted(fit)
  sig <- stats::sigma(fit)
  sims <- simulate(fit, nsim = 2, seed = 1)
  res <- residuals(fit)
  pearson <- residuals(fit, type = "pearson")

  expect_equal(fit$opt$convergence, 0)
  expect_equal(dim(fitted_mu), c(nrow(sim$data), 2))
  expect_equal(colnames(fitted_mu), c("mu1", "mu2"))
  expect_equal(
    fitted_mu[, "mu1"],
    predict(fit, dpar = "mu1"),
    tolerance = 1e-12
  )
  expect_equal(
    fitted_mu[, "mu2"],
    predict(fit, dpar = "mu2"),
    tolerance = 1e-12
  )
  expect_equal(stats::nobs(fit), nrow(sim$data))
  expect_equal(stats::df.residual(fit), fit$nobs - fit$df)
  expect_equal(
    stats::deviance(fit),
    -2 * as.numeric(stats::logLik(fit)),
    tolerance = 1e-12
  )
  expect_named(sig, c("sigma1", "sigma2"))
  expect_equal(length(sig$sigma1), nrow(sim$data))
  expect_equal(dim(sims), c(nrow(sim$data), 4))
  expect_equal(dim(res), c(nrow(sim$data), 2))
  expect_equal(dim(pearson), c(nrow(sim$data), 2))

  labels <- unlist(
    lapply(names(coef(fit)), function(dpar) {
      paste0(dpar, ":", names(coef(fit, dpar)))
    }),
    use.names = FALSE
  )
  expect_equal(rownames(stats::vcov(fit)), labels)
  expect_equal(colnames(stats::vcov(fit)), labels)
  expect_equal(rownames(summary(fit)$coefficients), labels)
})

test_that("bivariate Gaussian known V likelihood matches a base R MVN calculation", {
  sim <- new_biv_gaussian_known_v_data(n = 45, seed = 20260517)
  V <- sim$V

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + meta_known_V(V = V),
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )

  mu1 <- predict(fit, dpar = "mu1")
  mu2 <- predict(fit, dpar = "mu2")
  sigma1 <- predict(fit, dpar = "sigma1")
  sigma2 <- predict(fit, dpar = "sigma2")
  rho <- predict(fit, dpar = "rho12")
  Sigma <- fit$model$V_known
  i1 <- seq.int(1L, by = 2L, length.out = fit$nobs)
  i2 <- i1 + 1L
  Sigma[cbind(i1, i1)] <- Sigma[cbind(i1, i1)] + sigma1^2
  Sigma[cbind(i2, i2)] <- Sigma[cbind(i2, i2)] + sigma2^2
  Sigma[cbind(i1, i2)] <- Sigma[cbind(i1, i2)] + rho * sigma1 * sigma2
  Sigma[cbind(i2, i1)] <- Sigma[cbind(i2, i1)] + rho * sigma1 * sigma2

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$V_known_type, "matrix")
  expect_true(isTRUE(fit$model$has_known_v))
  expect_equal(
    as.numeric(stats::logLik(fit)),
    mvn_loglik_biv(
      as.vector(rbind(fit$model$y1, fit$model$y2)),
      as.vector(rbind(mu1, mu2)),
      Sigma
    ),
    tolerance = 1e-6
  )
})

test_that("bivariate Gaussian known V recovers residual rho12 separately from sampling correlation", {
  sim <- new_biv_gaussian_known_v_data(
    n = 150,
    residual_rho = -0.35,
    sampling_cor = 0.65,
    seed = 20260518
  )
  V <- sim$V

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + meta_known_V(V = V),
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(abs(tanh(coef(fit, "rho12")) - sim$residual_rho), 0.22)
  expect_gt(abs(tanh(coef(fit, "rho12")) - sim$sampling_cor), 0.5)
  sims <- simulate(fit, nsim = 2, seed = 1)
  pearson <- residuals(fit, type = "pearson")
  expect_equal(dim(sims), c(nrow(sim$data), 4))
  expect_equal(dim(pearson), c(nrow(sim$data), 2))
  expect_true(all(is.finite(pearson)))
})

test_that("bivariate Gaussian likelihood weights are complete-row multipliers", {
  sim <- new_biv_gaussian_data(
    n = 120,
    beta_rho12 = atanh(0.35),
    seed = 20260564
  )

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )
  fit_double <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data,
    weights = rep(2, nrow(sim$data))
  )

  expect_equal(stats::weights(fit_double), rep(2, nrow(sim$data)))
  expect_equal(coef(fit_double, "mu1"), coef(fit, "mu1"), tolerance = 1e-5)
  expect_equal(coef(fit_double, "mu2"), coef(fit, "mu2"), tolerance = 1e-5)
  expect_equal(coef(fit_double, "rho12"), coef(fit, "rho12"), tolerance = 1e-5)
  expect_equal(
    as.numeric(stats::logLik(fit_double)),
    2 * as.numeric(stats::logLik(fit)),
    tolerance = 1e-4
  )
})

test_that("rho12 response-scale transform stays inside the correlation boundary", {
  eta <- c(-1e6, -20, 0, 20, 1e6)
  rho12 <- drmTMB:::rho_response(eta)

  expect_true(all(abs(rho12) < 1))
  expect_equal(rho12[[3L]], 0)
})

test_that("bivariate Gaussian uses complete cases across all parameter formulas", {
  sim <- new_biv_gaussian_data(
    n = 60,
    beta_rho12 = c(0.1, 0.2),
    seed = 20260515
  )
  dat <- sim$data
  dat$y1[2] <- NA_real_
  dat$y2[5] <- NA_real_
  dat$x[11] <- NA_real_
  dat$z1[17] <- NA_real_
  dat$z2[23] <- NA_real_
  dat$w[31] <- NA_real_
  keep <- stats::complete.cases(dat[c("y1", "y2", "x", "z1", "z2", "w")])

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~w
    ),
    family = biv_gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_equal(sum(is.na(fit$data[c("y1", "y2", "x", "z1", "z2", "w")])), 0)
})

test_that("bivariate Gaussian known V removes paired rows and columns consistently", {
  sim <- new_biv_gaussian_known_v_data(n = 12, seed = 20260519)
  dat <- sim$data
  V <- sim$V
  dat$y1[3] <- NA_real_
  pair <- (2L * 3L - 1L):(2L * 3L)
  V[pair, ] <- NA_real_
  V[, pair] <- NA_real_
  diag(V)[pair] <- c(0.02, 0.03)

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + meta_known_V(V = V),
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = dat
  )

  keep <- stats::complete.cases(dat[c("y1", "y2", "x")])
  pair_keep <- as.vector(rbind(keep, keep))
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$V_known, sim$V[pair_keep, pair_keep])
})

test_that("bivariate Gaussian rejects unsupported Phase 3 syntax clearly", {
  dat <- data.frame(
    y1 = stats::rnorm(20),
    y2 = stats::rnorm(20),
    x = stats::rnorm(20),
    vi = rep(0.02, 20),
    id = rep(1:4, each = 5)
  )

  expect_error(
    drmTMB(bf(mu1 = y1 ~ x), family = biv_gaussian(), data = dat),
    "mu2"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~x, rho12 = ~1),
      family = biv_gaussian(),
      data = dat
    ),
    "at most one"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~ x + (1 | p | id)),
      family = biv_gaussian(),
      data = dat
    ),
    "within-observation"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + meta_known_V(V = vi), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat
    ),
    "2n.*2n"
  )
  V <- diag(rep(0.01, 40))
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + meta_known_V(V = V), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat,
      weights = rep(1.5, nrow(dat))
    ),
    "full.*meta_known_V.*covariance"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + meta_known_V(V = V),
        mu2 = y2 ~ x + meta_known_V(V = V)
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "Only one.*meta_known_V"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + (1 | id), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat
    ),
    "one matching random-intercept"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + (1 | id), mu2 = y2 ~ x + (1 | id)),
      family = biv_gaussian(),
      data = dat
    ),
    "shared covariance-block label"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + (1 | p | id), mu2 = y2 ~ x + (1 | q | id)),
      family = biv_gaussian(),
      data = dat
    ),
    "same covariance-block label"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ 1 + (1 | p | id),
        sigma2 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "one matching random-intercept"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ 1 + (1 | id),
        sigma2 = ~ 1 + (1 | id)
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "shared covariance-block label"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ 1 + (1 | p | id),
        sigma2 = ~ 1 + (1 | q | id)
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "same covariance-block label"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + (1 | p | id),
        mu2 = y2 ~ x + (1 | p | id),
        sigma1 = ~ 1 + (1 | p | id),
        sigma2 = ~ 1 + (1 | p | id),
        rho12 = ~x
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "Reusing one bivariate covariance-block label"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + meta_known_V(V = V), mu2 = y2 ~ x + (1 | p | id)),
      family = biv_gaussian(),
      data = dat
    ),
    "cannot yet be combined"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + meta_known_V(V = V),
        mu2 = y2 ~ x,
        sigma1 = ~ 1 + (1 | p | id),
        sigma2 = ~ 1 + (1 | p | id)
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "cannot yet be combined"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + (1 + x | p | id),
        mu2 = y2 ~ x + (1 + x | p | id),
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~x
      ),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "Only bivariate random intercepts"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + phylo(1 | id, tree = tree), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat
    ),
    "planned, not implemented"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
      family = c(gaussian(), poisson()),
      data = dat
    ),
    "Mixed-response bivariate families"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
      family = c(gaussian(), gaussian(), gaussian()),
      data = dat
    ),
    "one-response and two-response models only"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
      family = list(gaussian(), gaussian(), gaussian()),
      data = dat
    ),
    "one-response and two-response models only"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y1, y2) ~ x),
      family = gaussian(),
      data = dat
    ),
    "mvbind.*only available"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y1, y2, y3) ~ x),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "exactly two"
  )
  expect_error(
    drmTMB(
      bf(mu1 = mvbind(y1, y2) ~ x, mu2 = y2 ~ x),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "unnamed"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y1, y2) ~ x, mu2 = y2 ~ x),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "cannot be combined"
  )
})
