biv_student_loglik_oracle <- function(
  y1,
  y2,
  mu1,
  mu2,
  sigma1,
  sigma2,
  nu,
  rho12
) {
  z1 <- (y1 - mu1) / sigma1
  z2 <- (y2 - mu2) / sigma2
  one_minus_rho2 <- 1 - rho12^2
  q <- (z1^2 - 2 * rho12 * z1 * z2 + z2^2) / one_minus_rho2
  sum(
    -log(2 * pi) -
      log(sigma1) -
      log(sigma2) -
      0.5 * log(one_minus_rho2) -
      ((nu + 2) / 2) * log1p(q / nu)
  )
}

simulate_biv_student_truth <- function(
  n,
  beta1,
  beta2,
  sigma1,
  sigma2,
  nu,
  rho12
) {
  x <- seq(-1, 1, length.out = n)
  z1 <- stats::rnorm(n)
  z2 <- rho12 * z1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  shared_scale <- sqrt(nu / stats::rchisq(n, df = nu))
  data.frame(
    x = x,
    y1 = beta1[[1L]] + beta1[[2L]] * x + sigma1 * z1 * shared_scale,
    y2 = beta2[[1L]] + beta2[[2L]] * x + sigma2 * z2 * shared_scale
  )
}

biv_student_test_formula <- function() {
  bf(
    mu1 = y1 ~ x,
    mu2 = y2 ~ x,
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    nu = ~ 1,
    rho12 = ~ 1
  )
}

test_that("biv_student oracle has the required symmetries and limits", {
  y1 <- c(-1.2, 0.1, 0.8)
  y2 <- c(0.4, -0.6, 1.5)
  mu1 <- c(-0.2, 0.0, 0.3)
  mu2 <- c(0.5, -0.1, 0.7)
  sigma1 <- 0.55
  sigma2 <- 1.20
  nu <- 6.5
  rho <- -0.72

  original <- biv_student_loglik_oracle(
    y1, y2, mu1, mu2, sigma1, sigma2, nu, rho
  )
  swapped <- biv_student_loglik_oracle(
    y2, y1, mu2, mu1, sigma2, sigma1, nu, rho
  )
  expect_equal(original, swapped, tolerance = 1e-12)

  gaussian_loglik <- function(y1, y2, mu1, mu2, sigma1, sigma2, rho) {
    z1 <- (y1 - mu1) / sigma1
    z2 <- (y2 - mu2) / sigma2
    q <- (z1^2 - 2 * rho * z1 * z2 + z2^2) / (1 - rho^2)
    sum(
      -log(2 * pi) - log(sigma1) - log(sigma2) -
        0.5 * log(1 - rho^2) - 0.5 * q
    )
  }
  expect_equal(
    biv_student_loglik_oracle(
      y1, y2, mu1, mu2, sigma1, sigma2, 1e8, rho
    ),
    gaussian_loglik(y1, y2, mu1, mu2, sigma1, sigma2, rho),
    tolerance = 1e-6
  )

  expect_true(is.finite(biv_student_loglik_oracle(
    y1 = 0.2, y2 = -0.3, mu1 = 0, mu2 = 0,
    sigma1 = 0.4, sigma2 = 1.7, nu = 2.001, rho12 = 0.999
  )))
})

test_that("zero rho is non-product at finite nu but factors in the Gaussian limit", {
  y1 <- 2.1
  y2 <- -1.7
  sigma1 <- 0.8
  sigma2 <- 1.3
  finite_nu <- 5
  joint_finite <- biv_student_loglik_oracle(
    y1, y2, 0, 0, sigma1, sigma2, finite_nu, 0
  )
  product_finite <- stats::dt(y1 / sigma1, df = finite_nu, log = TRUE) -
    log(sigma1) +
    stats::dt(y2 / sigma2, df = finite_nu, log = TRUE) -
    log(sigma2)
  expect_gt(abs(joint_finite - product_finite), 1e-3)

  large_nu <- 1e8
  joint_limit <- biv_student_loglik_oracle(
    y1, y2, 0, 0, sigma1, sigma2, large_nu, 0
  )
  product_limit <- stats::dt(y1 / sigma1, df = large_nu, log = TRUE) -
    log(sigma1) +
    stats::dt(y2 / sigma2, df = large_nu, log = TRUE) -
    log(sigma2)
  expect_equal(joint_limit, product_limit, tolerance = 1e-6)

  set.seed(6400)
  n <- 50000
  z1 <- stats::rnorm(n)
  z2 <- stats::rnorm(n)
  shared <- sqrt(finite_nu / stats::rchisq(n, finite_nu))
  residual1 <- z1 * shared
  residual2 <- z2 * shared
  expect_lt(abs(stats::cor(residual1, residual2)), 0.025)
  expect_gt(stats::cor(residual1^2, residual2^2), 0.10)
})

test_that("shared nu preserves Student margins and exposes unequal-nu misspecification", {
  y <- 0.65
  mu <- -0.1
  sigma <- 0.75
  nu <- 7
  marginal_from_joint <- stats::integrate(
    function(y2) {
      exp(vapply(y2, function(value) {
        biv_student_loglik_oracle(
          y, value, mu, 0.2, sigma, 1.1, nu, 0.45
        )
      }, numeric(1L)))
    },
    lower = -Inf,
    upper = Inf,
    rel.tol = 1e-9
  )$value
  marginal_t <- stats::dt((y - mu) / sigma, df = nu) / sigma
  expect_equal(marginal_from_joint, marginal_t, tolerance = 1e-7)

  # A common nu cannot reproduce two different marginal tail shapes. This
  # source-level diagnostic keeps the shared-nu restriction visible without
  # turning a misspecified fit into recovery evidence.
  nu1 <- 6
  nu2 <- 12
  excess_kurtosis <- function(df) 6 / (df - 4)
  expect_gt(
    abs(excess_kurtosis(nu1) - excess_kurtosis(nu2)),
    2
  )
})

test_that("biv_student constructor and spec use the distinct shared-nu route", {
  family <- biv_student()
  expect_s3_class(family, "drm_family")
  expect_identical(family$name, "biv_student")
  expect_identical(
    family$dpars,
    c("mu1", "mu2", "sigma1", "sigma2", "nu", "rho12")
  )
  expect_identical(unname(family$links[["nu"]]), "logm2")
  expect_identical(unname(family$links[["rho12"]]), "atanh_guarded")

  dat <- data.frame(
    x = seq(-1, 1, length.out = 8),
    y1 = c(-0.4, -0.1, 0.2, 0.5, 0.4, 0.9, 1.1, 1.3),
    y2 = c(0.7, 0.4, 0.6, 0.2, 0.1, -0.2, -0.1, -0.5)
  )
  spec <- drmTMB:::drm_build_biv_student_spec(
    biv_student_test_formula(),
    dat
  )
  expect_identical(spec$model_type, "biv_student")
  expect_identical(spec$tmb_data$model_type, 20L)
  expect_equal(dim(spec$X$nu), c(nrow(dat), 1L))
  expect_equal(unname(spec$start$beta_nu), log(8))
  expect_false("beta_nu" %in% names(spec$map))
})

test_that("biv_student TMB objective remains exact on the Gaussian nu boundary", {
  set.seed(64001)
  dat <- simulate_biv_student_truth(
    n = 80,
    beta1 = c(0.2, 0.3),
    beta2 = c(-0.1, -0.25),
    sigma1 = 0.7,
    sigma2 = 1.1,
    nu = 8,
    rho12 = 0.2
  )
  fit <- drmTMB(
    biv_student_test_formula(),
    family = biv_student(),
    data = dat
  )
  boundary_nu <- 1e15
  par <- fit$obj$par
  par[grepl("^beta_nu", names(par))] <- log(boundary_nu - 2)
  par_list <- fit$obj$env$parList(par)
  mu1 <- as.vector(fit$model$X$mu1 %*% par_list$beta_mu1)
  mu2 <- as.vector(fit$model$X$mu2 %*% par_list$beta_mu2)
  sigma1 <- exp(as.vector(fit$model$X$sigma1 %*% par_list$beta_sigma1))
  sigma2 <- exp(as.vector(fit$model$X$sigma2 %*% par_list$beta_sigma2))
  rho <- 0.999999 * tanh(as.vector(
    fit$model$X$rho12 %*% par_list$beta_rho12
  ))
  expect_equal(
    -fit$obj$fn(par),
    biv_student_loglik_oracle(
      dat$y1, dat$y2, mu1, mu2, sigma1, sigma2, boundary_nu, rho
    ),
    tolerance = 1e-8
  )
})

test_that("biv_student matches closed-form and mvtnorm likelihood oracles", {
  skip_if_not_installed("drmTMB")
  skip_if_not_installed("mvtnorm")
  set.seed(6401)
  dat <- simulate_biv_student_truth(
    n = 120,
    beta1 = c(0.2, 0.45),
    beta2 = c(-0.3, -0.25),
    sigma1 = 0.55,
    sigma2 = 0.85,
    nu = 7,
    rho12 = 0.35
  )
  fit <- drmTMB(
    biv_student_test_formula(),
    family = biv_student(),
    data = dat
  )

  mu1 <- predict(fit, dpar = "mu1")
  mu2 <- predict(fit, dpar = "mu2")
  sigma1 <- predict(fit, dpar = "sigma1")
  sigma2 <- predict(fit, dpar = "sigma2")
  nu <- predict(fit, dpar = "nu")
  rho <- rho12(fit)
  expect_equal(
    as.numeric(logLik(fit)),
    biv_student_loglik_oracle(
      dat$y1,
      dat$y2,
      mu1,
      mu2,
      sigma1,
      sigma2,
      nu,
      rho
    ),
    tolerance = 1e-7
  )

  scatter <- matrix(
    c(sigma1[[1L]]^2,
      rho[[1L]] * sigma1[[1L]] * sigma2[[1L]],
      rho[[1L]] * sigma1[[1L]] * sigma2[[1L]],
      sigma2[[1L]]^2),
    nrow = 2L
  )
  mvtnorm_loglik <- sum(vapply(seq_len(nrow(dat)), function(i) {
    mvtnorm::dmvt(
      c(dat$y1[[i]], dat$y2[[i]]),
      delta = c(mu1[[i]], mu2[[i]]),
      sigma = scatter,
      df = nu[[i]],
      log = TRUE,
      type = "shifted"
    )
  }, numeric(1L)))
  expect_equal(as.numeric(logLik(fit)), mvtnorm_loglik, tolerance = 1e-7)

  swapped_dat <- transform(dat, y1 = dat$y2, y2 = dat$y1)
  swapped_fit <- drmTMB(
    biv_student_test_formula(),
    family = biv_student(),
    data = swapped_dat
  )
  expect_equal(
    as.numeric(logLik(swapped_fit)),
    as.numeric(logLik(fit)),
    tolerance = 1e-6
  )
  expect_equal(
    predict(swapped_fit, dpar = "sigma1"),
    predict(fit, dpar = "sigma2"),
    tolerance = 1e-5
  )
  expect_equal(
    predict(swapped_fit, dpar = "sigma2"),
    predict(fit, dpar = "sigma1"),
    tolerance = 1e-5
  )
})

test_that("biv_student methods preserve scale, mean, correlation, and shared mixing", {
  skip_if_not_installed("drmTMB")
  set.seed(6402)
  dat <- simulate_biv_student_truth(
    n = 90,
    beta1 = c(0.1, 0.3),
    beta2 = c(-0.2, 0.15),
    sigma1 = 0.5,
    sigma2 = 0.75,
    nu = 6,
    rho12 = -0.25
  )
  fit <- drmTMB(
    biv_student_test_formula(),
    family = biv_student(),
    data = dat
  )

  expect_equal(
    fitted(fit),
    cbind(
      mu1 = predict(fit, dpar = "mu1"),
      mu2 = predict(fit, dpar = "mu2")
    )
  )
  scales <- sigma(fit)
  expect_s3_class(scales, "drmTMB_biv_sigma")
  expect_equal(scales$sigma1, predict(fit, dpar = "sigma1"))
  expect_equal(scales$sigma2, predict(fit, dpar = "sigma2"))
  expect_true(all(predict(fit, dpar = "nu") > 2))
  expect_true(all(abs(rho12(fit)) < 1))

  params <- predict_parameters(fit)
  expect_setequal(
    unique(params$dpar),
    c("mu1", "mu2", "sigma1", "sigma2", "nu", "rho12")
  )
  pair <- corpairs(fit)
  expect_true(any(pair$parameter == "rho12"))
  fit_summary <- summary(fit)
  expect_s3_class(fit_summary, "summary.drmTMB")
  expect_false(any(fit_summary$parameters$profile_ready))
  direct_rows <- fit_summary$parameters$dpar %in%
    c("sigma1", "sigma2", "rho12")
  expect_true(all(
    fit_summary$parameters$profile_note[direct_rows] ==
      "family_interval_deferred"
  ))

  seed <- 6403
  sim <- simulate(fit, nsim = 1, seed = seed)
  mu1 <- predict(fit, dpar = "mu1")
  mu2 <- predict(fit, dpar = "mu2")
  sigma1 <- predict(fit, dpar = "sigma1")
  sigma2 <- predict(fit, dpar = "sigma2")
  nu <- predict(fit, dpar = "nu")
  rho <- rho12(fit)
  set.seed(seed)
  z1 <- stats::rnorm(length(mu1))
  z2 <- rho * z1 + sqrt(1 - rho^2) * stats::rnorm(length(mu1))
  shared_scale <- sqrt(nu / stats::rchisq(length(mu1), df = nu))
  expect_equal(sim$sim_1_y1, mu1 + sigma1 * z1 * shared_scale)
  expect_equal(sim$sim_1_y2, mu2 + sigma2 * z2 * shared_scale)

  diagnostics <- check_drm(fit)
  expect_true(all(c("rho12_boundary", "student_nu") %in% diagnostics$check))
})

test_that("biv_student rejects deferred first-slice syntax and intervals", {
  skip_if_not_installed("drmTMB")
  dat <- data.frame(
    x = seq(-1, 1, length.out = 12),
    y1 = seq(-0.5, 0.8, length.out = 12),
    y2 = seq(0.7, -0.6, length.out = 12),
    id = rep(letters[1:4], each = 3)
  )
  base_formula <- biv_student_test_formula()

  expect_error(
    drmTMB(
      base_formula,
      family = biv_student(),
      data = transform(dat, y1 = replace(y1, 3, NA_real_))
    ),
    "complete, finite"
  )
  expect_error(
    drmTMB(
      base_formula,
      family = biv_student(),
      data = transform(dat, y2 = replace(y2, 4, Inf))
    ),
    "complete, finite"
  )
  expect_error(
    drmTMB(
      base_formula,
      family = biv_student(),
      data = dat,
      weights = rep(1, nrow(dat))
    ),
    "does not support"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + offset(x), mu2 = y2 ~ x, nu = ~ 1),
      family = biv_student(),
      data = dat
    ),
    "offset"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + (1 | id), mu2 = y2 ~ x, nu = ~ 1),
      family = biv_student(),
      data = dat
    ),
    "fixed-effect"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ mi(x), mu2 = y2 ~ x, nu = ~ 1),
      family = biv_student(),
      data = dat
    ),
    "does not support.*mi"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ x, nu = ~ 1),
      family = biv_student(),
      data = dat
    ),
    "intercept-only"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, nu = ~ x),
      family = biv_student(),
      data = dat
    ),
    "intercept-only"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~ x),
      family = biv_student(),
      data = dat
    ),
    "intercept-only"
  )
  zero_intercept_formulas <- list(
    bf(
      mu1 = y1 ~ x, mu2 = y2 ~ x,
      sigma1 = ~ 0 + x, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1
    ),
    bf(
      mu1 = y1 ~ x, mu2 = y2 ~ x,
      sigma1 = ~ 1, sigma2 = ~ x - 1, nu = ~ 1, rho12 = ~ 1
    ),
    bf(
      mu1 = y1 ~ x, mu2 = y2 ~ x,
      sigma1 = ~ 1, sigma2 = ~ 1, nu = ~ 0 + x, rho12 = ~ 1
    ),
    bf(
      mu1 = y1 ~ x, mu2 = y2 ~ x,
      sigma1 = ~ 1, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 0 + x
    )
  )
  for (candidate in zero_intercept_formulas) {
    expect_error(
      drmTMB(candidate, family = biv_student(), data = dat),
      "intercept-only"
    )
  }
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, nu1 = ~ 1, nu2 = ~ 1),
      family = biv_student(),
      data = dat
    ),
    "nu1"
  )
  expect_error(
    drmTMB(
      base_formula,
      family = biv_student(),
      data = dat,
      REML = TRUE
    ),
    "REML"
  )
  expect_error(
    drmTMB(
      base_formula,
      family = biv_student(),
      data = dat,
      penalty = drm_phylo_penalty()
    ),
    "penalty"
  )
  expect_error(
    drmTMB(
      base_formula,
      family = biv_student(),
      data = dat,
      engine = "julia"
    ),
    "engine"
  )

  fit <- suppressWarnings(
    drmTMB(base_formula, family = biv_student(), data = dat)
  )
  expect_error(confint(fit), "not implemented")
  expect_error(profile(fit), "not implemented")
  expect_error(corpairs(fit, conf.int = TRUE), "not implemented")
  expect_error(summary(fit, conf.int = TRUE), "not implemented")
  expect_error(predict_parameters(fit, conf.int = TRUE), "not implemented")
  expect_error(residuals(fit), "not implemented")
  expect_error(residuals(fit, type = "pearson"), "not implemented")
  expect_error(residuals(fit, type = "quantile"), "not implemented")
  expect_error(
    fitted_distribution(fit),
    "does not yet cover model type"
  )
  expect_equal(nrow(profile_targets(fit)), 0L)
})
