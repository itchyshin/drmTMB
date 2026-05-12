new_corpairs_biv_data <- function(
  n = 220,
  beta_rho12 = c(0.15, 0.35),
  seed = 20260574
) {
  set.seed(seed)
  x <- stats::rnorm(n)
  z1 <- stats::rnorm(n)
  z2 <- stats::rnorm(n)
  w <- stats::rnorm(n)
  mu1 <- 0.25 + 0.5 * x
  mu2 <- -0.1 - 0.35 * x
  sigma1 <- exp(-0.25 + 0.2 * z1)
  sigma2 <- exp(0.05 - 0.15 * z2)
  eta_rho12 <- beta_rho12[[1L]] + beta_rho12[[2L]] * w
  rho12 <- 0.99999999 * tanh(eta_rho12)
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  data.frame(
    y1 = mu1 + sigma1 * e1,
    y2 = mu2 + sigma2 * e2,
    x = x,
    z1 = z1,
    z2 = z2,
    w = w
  )
}

new_corpairs_group_data <- function(n_id = 24, n_each = 6, seed = 20260575) {
  set.seed(seed)
  n <- n_id * n_each
  ID <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  sd0 <- 0.5
  sd1 <- 0.35
  rho <- 0.45
  u0 <- sd0 * z0
  u1 <- sd1 * (rho * z0 + sqrt(1 - rho^2) * z1)
  y <- 0.2 + 0.65 * x + u0[ID] + u1[ID] * x + stats::rnorm(n, sd = 0.45)
  data.frame(y = y, x = x, ID = ID)
}

new_corpairs_mu_sigma_data <- function(
  n_id = 18L,
  n_each = 6L,
  rho_group = 0.45,
  seed = 20260642
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  z_mu <- stats::rnorm(n_id)
  z_sigma <- stats::rnorm(n_id)
  sd_mu <- 0.55
  sd_sigma <- 0.35
  b_mu <- sd_mu * z_mu
  a_sigma <- sd_sigma *
    (rho_group * z_mu + sqrt(1 - rho_group^2) * z_sigma)
  sigma <- exp(-0.7 + 0.2 * z + a_sigma[id])
  data.frame(
    y = stats::rnorm(n, mean = 0.2 + 0.5 * x + b_mu[id], sd = sigma),
    x = x,
    z = z,
    id = id
  )
}

new_corpairs_sigma_group_data <- function(
  n_id = 30L,
  n_each = 8L,
  seed = 20260652
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  sd0 <- 0.45
  sd1 <- 0.30
  rho <- 0.45
  a0 <- sd0 * z0
  a1 <- sd1 * (rho * z0 + sqrt(1 - rho^2) * z1)
  sigma <- exp(log(0.5) + 0.2 * z + a0[id] + a1[id] * z)
  data.frame(
    y = stats::rnorm(n, mean = 0.2 + 0.5 * x, sd = sigma),
    x = x,
    z = z,
    id = id
  )
}

test_that("corpairs summarizes predictor-dependent residual rho12", {
  dat <- new_corpairs_biv_data()
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~w
    ),
    family = c(gaussian(), gaussian()),
    data = dat
  )

  pairs <- corpairs(fit)

  expect_equal(nrow(pairs), 1L)
  expect_equal(pairs$level, "residual")
  expect_equal(pairs$class, "residual")
  expect_equal(pairs$parameter, "rho12")
  expect_equal(pairs$from_response, "y1")
  expect_equal(pairs$to_response, "y2")
  expect_equal(pairs$n_values, nrow(dat))
  expect_equal(pairs$estimate, mean(rho12(fit)), tolerance = 1e-12)
  expect_equal(
    pairs$link_estimate,
    mean(rho12(fit, type = "link")),
    tolerance = 1e-12
  )
  expect_lt(pairs$min, pairs$max)
  expect_equal(pairs$modelled, TRUE)
  expect_equal(nrow(corpairs(fit, level = "group")), 0L)

  fit_no_frame <- fit
  fit_no_frame$model$model_frame <- NULL
  pairs_no_frame <- corpairs(fit_no_frame)
  expect_equal(pairs_no_frame$from_response, "y1")
  expect_equal(pairs_no_frame$to_response, "y2")
})

test_that("corpairs keeps response labels for mvbind bivariate shorthand", {
  dat <- new_corpairs_biv_data(
    n = 160,
    beta_rho12 = c(0.2, -0.15),
    seed = 20260577
  )
  fit <- drmTMB(
    bf(
      mvbind(y1, y2) ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~w
    ),
    family = c(gaussian(), gaussian()),
    data = dat
  )

  pairs <- corpairs(fit)

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nrow(pairs), 1L)
  expect_equal(pairs$level, "residual")
  expect_equal(pairs$from_response, "y1")
  expect_equal(pairs$to_response, "y2")
  expect_equal(pairs$parameter, "rho12")
  expect_equal(pairs$estimate, mean(rho12(fit)), tolerance = 1e-12)
})

test_that("corpairs reports ordinary group-level correlation labels", {
  dat <- new_corpairs_group_data()
  fit <- drmTMB(
    bf(y ~ x + (1 + x | p | ID)),
    family = gaussian(),
    data = dat
  )

  pairs <- corpairs(fit)
  cor_estimate <- unname(fit$corpars$mu[["cor((Intercept),x | p | ID)"]])

  expect_equal(nrow(pairs), 1L)
  expect_equal(pairs$level, "group")
  expect_equal(pairs$group, "ID")
  expect_equal(pairs$block, "p")
  expect_equal(pairs$from_dpar, "mu")
  expect_equal(pairs$to_dpar, "mu")
  expect_equal(pairs$from_coef, "(Intercept)")
  expect_equal(pairs$to_coef, "x")
  expect_equal(pairs$class, "mean-slope")
  expect_equal(pairs$from_response, "y")
  expect_equal(pairs$to_response, "y")
  expect_equal(pairs$parameter, "cor((Intercept),x | p | ID)")
  expect_equal(pairs$estimate, cor_estimate, tolerance = 1e-12)
  expect_equal(
    pairs$link_estimate,
    atanh(cor_estimate / 0.999999),
    tolerance = 1e-12
  )
  expect_false(grepl("rho12", pairs$parameter, fixed = TRUE))
  expect_equal(corpairs(fit, class = "mean-slope"), pairs)

  fit_no_frame <- fit
  fit_no_frame$model$model_frame <- NULL
  pairs_no_frame <- corpairs(fit_no_frame)
  expect_equal(pairs_no_frame$from_response, "y")
  expect_equal(pairs_no_frame$to_response, "y")
})

test_that("corpairs reports residual-scale random-slope correlations", {
  dat <- new_corpairs_sigma_group_data()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z + (1 + z | id)),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 300, iter.max = 300)
  )

  pairs <- corpairs(fit)
  scale_slope <- corpairs(fit, class = "scale-slope")
  cor_label <- "cor((Intercept),z | id)"
  cor_estimate <- unname(fit$corpars$sigma[[cor_label]])

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nrow(pairs), 1L)
  expect_equal(pairs, scale_slope)
  expect_equal(pairs$level, "group")
  expect_equal(pairs$group, "id")
  expect_equal(pairs$block, NA_character_)
  expect_equal(pairs$from_dpar, "sigma")
  expect_equal(pairs$to_dpar, "sigma")
  expect_equal(pairs$from_response, "y")
  expect_equal(pairs$to_response, "y")
  expect_equal(pairs$from_coef, "(Intercept)")
  expect_equal(pairs$to_coef, "z")
  expect_equal(pairs$class, "scale-slope")
  expect_equal(pairs$parameter, cor_label)
  expect_equal(pairs$estimate, cor_estimate, tolerance = 1e-12)
  expect_equal(
    pairs$link_estimate,
    atanh(cor_estimate / 0.999999),
    tolerance = 1e-12
  )
  expect_false(grepl("rho12", pairs$parameter, fixed = TRUE))
})

test_that("corpairs reports mean-scale random-intercept correlations", {
  dat <- new_corpairs_mu_sigma_data()
  fit <- drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 300, iter.max = 300)
  )

  pairs <- corpairs(fit)
  mean_scale <- corpairs(fit, class = "mean-scale")
  cor_label <- "cor(mu:(Intercept),sigma:(Intercept) | p | id)"
  cor_estimate <- unname(fit$corpars$mu_sigma[[cor_label]])

  expect_equal(nrow(pairs), 1L)
  expect_equal(pairs, mean_scale)
  expect_equal(pairs$level, "group")
  expect_equal(pairs$group, "id")
  expect_equal(pairs$block, "p")
  expect_equal(pairs$from_dpar, "mu")
  expect_equal(pairs$to_dpar, "sigma")
  expect_equal(pairs$from_response, "y")
  expect_equal(pairs$to_response, "y")
  expect_equal(pairs$from_coef, "(Intercept)")
  expect_equal(pairs$to_coef, "(Intercept)")
  expect_equal(pairs$class, "mean-scale")
  expect_equal(pairs$parameter, cor_label)
  expect_equal(pairs$estimate, cor_estimate, tolerance = 1e-12)
  expect_equal(
    pairs$link_estimate,
    atanh(cor_estimate / 0.999999),
    tolerance = 1e-12
  )
  expect_false(grepl("rho12", pairs$parameter, fixed = TRUE))

  fit_no_frame <- fit
  fit_no_frame$model$model_frame <- NULL
  pairs_no_frame <- corpairs(fit_no_frame)
  expect_equal(pairs_no_frame$from_response, "y")
  expect_equal(pairs_no_frame$to_response, "y")
})

test_that("corpairs returns an empty table when no correlations are fitted", {
  dat <- data.frame(y = c(-0.4, 0.1, 0.7, 1.0, 1.3), x = c(-1, 0, 1, 2, 3))
  fit <- drmTMB(bf(y ~ x), family = gaussian(), data = dat)

  pairs <- corpairs(fit)

  expect_equal(nrow(pairs), 0L)
  expect_named(
    pairs,
    c(
      "level",
      "group",
      "block",
      "from_dpar",
      "to_dpar",
      "from_coef",
      "to_coef",
      "from_response",
      "to_response",
      "class",
      "parameter",
      "estimate",
      "min",
      "max",
      "n_values",
      "link_estimate",
      "link_min",
      "link_max",
      "modelled"
    )
  )
})
