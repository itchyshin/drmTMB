new_nongaussian_mu_slope_base <- function(
  n_id = 26,
  n_each = 8,
  seed = 20260528
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rep(seq(-1.25, 1.25, length.out = n_each), times = n_id)
  x <- x + stats::rnorm(length(x), sd = 0.03)
  slope_raw <- stats::qnorm((seq_len(n_id) - 0.5) / n_id)
  slope <- 0.48 * as.numeric(scale(slope_raw))
  names(slope) <- levels(id)
  eta_mu <- 0.15 + 0.42 * x + slope[id] * x
  list(
    data = data.frame(id = id, x = x),
    eta_mu = eta_mu,
    slope = slope
  )
}

new_nongaussian_mu_slope_data <- function(family, seed = 20260528) {
  base <- new_nongaussian_mu_slope_base(seed = seed)
  dat <- base$data
  if (identical(family, "student")) {
    sigma <- 0.38
    nu <- 10
    dat$y <- base$eta_mu + sigma * stats::rt(nrow(dat), df = nu)
  } else if (identical(family, "lognormal")) {
    dat$y <- stats::rlnorm(nrow(dat), meanlog = base$eta_mu, sdlog = 0.28)
  } else if (identical(family, "gamma")) {
    mu <- exp(base$eta_mu)
    sigma <- 0.32
    dat$y <- stats::rgamma(
      nrow(dat),
      shape = 1 / sigma^2,
      scale = mu * sigma^2
    )
  } else if (identical(family, "beta")) {
    mu <- stats::plogis(base$eta_mu)
    phi <- 34
    dat$y <- stats::rbeta(nrow(dat), shape1 = mu * phi, shape2 = (1 - mu) * phi)
  } else if (identical(family, "beta_binomial")) {
    mu <- stats::plogis(base$eta_mu)
    phi <- 36
    trials <- rep(18L, nrow(dat))
    p <- stats::rbeta(nrow(dat), shape1 = mu * phi, shape2 = (1 - mu) * phi)
    success <- stats::rbinom(nrow(dat), size = trials, prob = p)
    dat$success <- success
    dat$failure <- trials - success
  } else if (identical(family, "truncated_nbinom2")) {
    mu <- exp(base$eta_mu)
    sigma <- 0.36
    size <- 1 / sigma^2
    y <- stats::rnbinom(nrow(dat), mu = mu, size = size)
    while (any(y == 0L)) {
      zero <- y == 0L
      y[zero] <- stats::rnbinom(sum(zero), mu = mu[zero], size = size)
    }
    dat$y <- y
  } else {
    stop("Unknown family")
  }
  list(data = dat, slope = base$slope)
}

fit_nongaussian_mu_slope <- function(family, data) {
  if (identical(family, "student")) {
    return(drmTMB(
      bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1),
      family = student(),
      data = data
    ))
  }
  if (identical(family, "lognormal")) {
    return(drmTMB(
      bf(y ~ x + (0 + x | id), sigma ~ 1),
      family = lognormal(),
      data = data
    ))
  }
  if (identical(family, "gamma")) {
    return(drmTMB(
      bf(y ~ x + (0 + x | id), sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = data
    ))
  }
  if (identical(family, "beta")) {
    return(drmTMB(
      bf(y ~ x + (0 + x | id), sigma ~ 1),
      family = beta(),
      data = data
    ))
  }
  if (identical(family, "beta_binomial")) {
    return(drmTMB(
      bf(cbind(success, failure) ~ x + (0 + x | id), sigma ~ 1),
      family = beta_binomial(),
      data = data
    ))
  }
  if (identical(family, "truncated_nbinom2")) {
    return(drmTMB(
      bf(y ~ x + (0 + x | id), sigma ~ 1),
      family = truncated_nbinom2(),
      data = data
    ))
  }
  stop("Unknown family")
}

expect_nongaussian_mu_slope_fit <- function(fit, truth) {
  slope_label <- "(0 + x | id)"
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(isTRUE(fit$sdr$pdHess), TRUE)
  expect_equal(fit$model$random$mu$n_terms, 1L)
  expect_equal(fit$model$random$mu$labels, slope_label)
  expect_equal(fit$model$random$mu$value[, 1], fit$model$data$x)
  expect_named(fit$sdpars$mu, slope_label)
  expect_gt(unname(fit$sdpars$mu[[slope_label]]), 0.03)
  expect_equal(drmTMB:::has_ordinary_mu_random_effects(fit), TRUE)
  expect_equal(drmTMB:::n_mu_random_effect_terms(fit), 1L)
  expect_equal(ranef(fit, "mu"), fit$random_effects$mu)
  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    as.vector(fit$model$X$mu %*% coef(fit, "mu")) +
      drmTMB:::mu_random_effect_contribution(fit),
    tolerance = 1e-8
  )
  expect_length(fitted(fit), nrow(fit$model$data))

  slope_effects <- fit$random_effects$mu$terms[[slope_label]]
  expect_equal(length(slope_effects), length(truth$slope))
  expect_gt(abs(stats::cor(slope_effects, truth$slope)), 0.25)

  targets <- profile_targets(fit)
  expect_equal(any(targets$parm == paste0("sd:mu:", slope_label)), TRUE)
  chk <- check_drm(fit)
  replication <- chk[chk$check == "mu_random_effect_replication", ]
  expect_equal(replication$status, "ok")
  design <- chk[chk$check == "mu_random_effect_design", ]
  expect_equal(design$status, "ok")
}

test_that("non-Gaussian mu supports independent numeric random slopes", {
  families <- c(
    "student",
    "lognormal",
    "gamma",
    "beta",
    "beta_binomial",
    "truncated_nbinom2"
  )
  for (i in seq_along(families)) {
    family <- families[[i]]
    sim <- new_nongaussian_mu_slope_data(family, seed = 20260528 + i)
    fit <- fit_nongaussian_mu_slope(family, sim$data)
    expect_nongaussian_mu_slope_fit(fit, sim)
  }
})
