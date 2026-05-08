new_biv_gaussian_data <- function(n = 500, beta_rho12 = atanh(0.4),
                                  seed = 20260512) {
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
  eta_rho12 <- beta_rho12[[1L]] + if (length(beta_rho12) > 1L) {
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

expect_abs_error_below <- function(actual, expected, tolerance) {
  expect_lt(max(abs(unname(actual) - unname(expected))), tolerance)
}

test_that("drmTMB fits bivariate Gaussian models with constant rho12", {
  sim <- new_biv_gaussian_data(n = 900, beta_rho12 = atanh(0.4))

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~ z1,
      sigma2 = ~ z2,
      rho12 = ~ 1
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

test_that("composed Gaussian family syntax routes to bivariate Gaussian", {
  sim <- new_biv_gaussian_data(n = 400, beta_rho12 = atanh(0.3), seed = 20260561)

  fit_c <- drmTMB(
    drm_formula(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~ z1,
      sigma2 = ~ z2,
      rho12 = ~ 1
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
      sigma1 = ~ z1,
      sigma2 = ~ z2,
      rho12 = ~ w
    ),
    family = biv_gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_abs_error_below(coef(fit, "rho12"), sim$beta_rho12, 0.12)
  expect_equal(
    predict(fit, dpar = "rho12", type = "link"),
    as.vector(stats::model.matrix(~ w, sim$data) %*% coef(fit, "rho12")),
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
        sigma1 = ~ z1,
        sigma2 = ~ z2,
        rho12 = ~ 1
      ),
      family = biv_gaussian(),
      data = sim$data
    )

    expect_equal(fit$opt$convergence, 0)
    expect_lt(abs(tanh(unname(coef(fit, "rho12"))) - targets[[i]]), 0.12)
  }
})

test_that("bivariate Gaussian methods return expected structures", {
  sim <- new_biv_gaussian_data(n = 160, beta_rho12 = atanh(0.25), seed = 20260514)
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
    family = biv_gaussian(),
    data = sim$data
  )

  sig <- stats::sigma(fit)
  sims <- simulate(fit, nsim = 2, seed = 1)
  res <- residuals(fit)
  pearson <- residuals(fit, type = "pearson")

  expect_equal(fit$opt$convergence, 0)
  expect_named(sig, c("sigma1", "sigma2"))
  expect_equal(length(sig$sigma1), nrow(sim$data))
  expect_equal(dim(sims), c(nrow(sim$data), 4))
  expect_equal(dim(res), c(nrow(sim$data), 2))
  expect_equal(dim(pearson), c(nrow(sim$data), 2))

  labels <- unlist(lapply(names(coef(fit)), function(dpar) {
    paste0(dpar, ":", names(coef(fit, dpar)))
  }), use.names = FALSE)
  expect_equal(rownames(stats::vcov(fit)), labels)
  expect_equal(colnames(stats::vcov(fit)), labels)
  expect_equal(rownames(summary(fit)$coefficients), labels)
})

test_that("rho12 response-scale transform stays inside the correlation boundary", {
  eta <- c(-1e6, -20, 0, 20, 1e6)
  rho12 <- drmTMB:::rho_response(eta)

  expect_true(all(abs(rho12) < 1))
  expect_equal(rho12[[3L]], 0)
})

test_that("bivariate Gaussian uses complete cases across all parameter formulas", {
  sim <- new_biv_gaussian_data(n = 60, beta_rho12 = c(0.1, 0.2), seed = 20260515)
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
      sigma1 = ~ z1,
      sigma2 = ~ z2,
      rho12 = ~ w
    ),
    family = biv_gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_equal(sum(is.na(fit$data[c("y1", "y2", "x", "z1", "z2", "w")])), 0)
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
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~ x, rho12 = ~ 1),
      family = biv_gaussian(),
      data = dat
    ),
    "at most one"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + meta_known_V(V = vi), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat
    ),
    "does not support.*meta_known_V"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + (1 | id), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat
    ),
    "unsupported model terms"
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
})
