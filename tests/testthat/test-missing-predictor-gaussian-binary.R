# #963 option (a): one Gaussian mi() plus one binary mi(), independent models.
# Not impute_joint. Not FIML. Gaussian response only.

gaussian_binary_mi_data <- function(
  n = 400,
  seed = 96303,
  missingness = c("mcar", "mar")
) {
  missingness <- match.arg(missingness)
  set.seed(seed)
  x <- rnorm(n)
  m <- 0.20 + 0.70 * x + rnorm(n, sd = 0.45)
  b <- rbinom(n, 1L, stats::plogis(-0.20 + 0.90 * x))
  y <- 0.30 + 0.80 * m + 0.90 * b + 0.25 * x + rnorm(n, sd = 0.50)
  dat <- data.frame(y = y, m = m, b = b, x = x)
  if (identical(missingness, "mcar")) {
    dat$m[seq_len(n) %% 5L == 0L] <- NA_real_
    dat$b[seq_len(n) %% 7L == 0L] <- NA_integer_
  } else {
    # Outcome-dependent MAR: larger y more likely to drop a predictor.
    dat$m[y > quantile(y, 0.72)] <- NA_real_
    dat$b[y > quantile(y, 0.78)] <- NA_integer_
  }
  dat
}

fit_gaussian_binary_mi <- function(dat, order = c("gaussian_first", "binary_first")) {
  order <- match.arg(order)
  f <- if (identical(order, "gaussian_first")) {
    bf(y ~ mi(m) + mi(b) + x, sigma ~ 1)
  } else {
    bf(y ~ mi(b) + mi(m) + x, sigma ~ 1)
  }
  drmTMB(
    f,
    data = dat,
    impute = list(
      m = impute_model(m ~ x, family = gaussian()),
      b = impute_model(b ~ x, family = binomial())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

test_that("one Gaussian plus one binary mi() fits in either formula order", {
  dat <- gaussian_binary_mi_data(missingness = "mcar")
  fit_a <- fit_gaussian_binary_mi(dat, "gaussian_first")
  fit_b <- fit_gaussian_binary_mi(dat, "binary_first")

  expect_equal(nobs(fit_a), nrow(dat))
  expect_named(fit_a$missing_data$predictors, c("m", "b"), ignore.order = TRUE)
  expect_equal(fit_a$missing_data$predictors$m$model_row, which(is.na(dat$m)))
  expect_equal(fit_a$missing_data$predictors$b$model_row, which(is.na(dat$b)))
  expect_true(all(is.finite(coef(fit_a, "mu"))))
  expect_true(all(is.finite(coef(fit_a, "mi_m"))))
  expect_true(all(is.finite(coef(fit_a, "mi_b"))))
  expect_lt(max(abs(fit_a$obj$gr(fit_a$opt$par))), 1e-2)
  expect_equal(nrow(imputed(fit_a, "m")), sum(is.na(dat$m)))
  expect_equal(nrow(imputed(fit_a, "b")), sum(is.na(dat$b)))
  # Formula order must not change the likelihood.
  expect_equal(as.numeric(logLik(fit_a)), as.numeric(logLik(fit_b)), tolerance = 1e-6)
})

test_that("one Gaussian plus one binary mi() recover MCAR coefficients", {
  dat <- gaussian_binary_mi_data(n = 600, missingness = "mcar")
  fit <- fit_gaussian_binary_mi(dat)
  mu <- coef(fit, "mu")
  expect_equal(unname(mu[["mi(m)"]]), 0.80, tolerance = 0.20)
  expect_equal(unname(mu[["mi(b)"]]), 0.90, tolerance = 0.30)
  expect_equal(unname(mu[["x"]]), 0.25, tolerance = 0.25)
  expect_equal(unname(coef(fit, "mi_m")), c(0.20, 0.70), tolerance = 0.20)
  expect_equal(unname(coef(fit, "mi_b")), c(-0.20, 0.90), tolerance = 0.35)
})

test_that("one Gaussian plus one binary mi() recover MAR coefficients", {
  dat <- gaussian_binary_mi_data(n = 600, missingness = "mar")
  fit <- fit_gaussian_binary_mi(dat)
  mu <- coef(fit, "mu")
  expect_equal(unname(mu[["mi(m)"]]), 0.80, tolerance = 0.25)
  expect_equal(unname(mu[["mi(b)"]]), 0.90, tolerance = 0.35)
})

test_that("Gaussian plus binary mi() are sentinel-invariant at missing rows", {
  dat <- gaussian_binary_mi_data(missingness = "mcar")
  fit <- fit_gaussian_binary_mi(dat)
  tmb_data <- fit$model$tmb_data
  # The binary term is promoted to the primary slot; the Gaussian is second.
  expect_identical(as.integer(tmb_data$mi_family), 1L)
  miss_b <- as.integer(tmb_data$mi_missing_index) + 1L
  miss_m <- as.integer(tmb_data$mi_missing_index2) + 1L
  expect_true(length(miss_b) > 0L)
  expect_true(length(miss_m) > 0L)

  data_a <- tmb_data
  data_b <- tmb_data
  data_a$mi_x[miss_b] <- 1
  data_a$mi_x2[miss_m] <- -1e6
  data_b$mi_x[miss_b] <- 0
  data_b$mi_x2[miss_m] <- 1e6

  obj_a <- missing_response_retaped_object(fit, data_a)
  obj_b <- missing_response_retaped_object(fit, data_b)
  par <- fit$opt$par
  expect_equal(obj_a$fn(par), obj_b$fn(par), tolerance = 1e-8)
  expect_equal(obj_a$gr(par), obj_b$gr(par), tolerance = 1e-8, ignore_attr = TRUE)
})

test_that("other mixed pairs and non-Gaussian responses are still refused", {
  dat <- gaussian_binary_mi_data(missingness = "mcar")
  dat$k <- rpois(nrow(dat), 2)
  dat$k[seq_len(nrow(dat)) %% 9L == 0L] <- NA_integer_
  # Gaussian + count: not in this cell.
  expect_error(
    drmTMB(
      bf(y ~ mi(m) + mi(k) + x, sigma ~ 1),
      data = dat,
      impute = list(
        m = impute_model(m ~ x, family = gaussian()),
        k = impute_model(k ~ x, family = poisson())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "Gaussian"
  )
  # Two binary terms: not in this cell.
  dat$b2 <- rbinom(nrow(dat), 1L, 0.5)
  dat$b2[seq_len(nrow(dat)) %% 11L == 0L] <- NA_integer_
  expect_error(
    drmTMB(
      bf(y ~ mi(b) + mi(b2) + x, sigma ~ 1),
      data = dat,
      impute = list(
        b = impute_model(b ~ x, family = binomial()),
        b2 = impute_model(b2 ~ x, family = binomial())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "Gaussian"
  )
  # Non-Gaussian response with Gaussian + binary.
  dat$yc <- rpois(nrow(dat), 2)
  expect_error(
    drmTMB(
      bf(yc ~ mi(m) + mi(b) + x),
      family = poisson(),
      data = dat,
      impute = list(
        m = impute_model(m ~ x, family = gaussian()),
        b = impute_model(b ~ x, family = binomial())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "exactly one"
  )
})

test_that("binary mi() posterior probabilities condition on the Gaussian mi() value", {
  dat <- gaussian_binary_mi_data(missingness = "mcar")
  # Rows 35, 70, 105, ... miss both predictors.
  both <- which(is.na(dat$m) & is.na(dat$b))
  expect_true(length(both) > 0L)
  fit <- fit_gaussian_binary_mi(dat)
  mu <- coef(fit, "mu")
  mib <- coef(fit, "mi_b")
  sig <- exp(unname(coef(fit, "sigma")[[1L]]))
  m_hat <- imputed(fit, "m", rows = "all", se = FALSE)$estimate
  prior1 <- stats::plogis(mib[[1L]] + mib[[2L]] * dat$x)
  rest <- mu[["(Intercept)"]] + mu[["mi(m)"]] * m_hat + mu[["x"]] * dat$x
  lik1 <- stats::dnorm(dat$y, rest + mu[["mi(b)"]], sig)
  lik0 <- stats::dnorm(dat$y, rest, sig)
  expected <- prior1 * lik1 / (prior1 * lik1 + (1 - prior1) * lik0)
  got <- imputed(fit, "b", rows = "all", se = FALSE)$estimate
  expect_equal(got[both], expected[both], tolerance = 1e-6)
})
