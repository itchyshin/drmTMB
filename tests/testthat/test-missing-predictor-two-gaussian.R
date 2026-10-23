# Phase 1 first cell: two independent Gaussian mi() terms (#963 option b).
# Not impute_joint. Not FIML. Not mixed families.

two_independent_gaussian_mi_data <- function(
  n = 240,
  seed = 96302,
  missingness = c("mcar", "mar")
) {
  missingness <- match.arg(missingness)
  set.seed(seed)
  x <- rnorm(n)
  m1 <- 0.20 + 0.70 * x + rnorm(n, sd = 0.45)
  m2 <- -0.10 + 0.55 * x + rnorm(n, sd = 0.40)
  y <- 0.30 + 0.80 * m1 + 0.60 * m2 + 0.25 * x + rnorm(n, sd = 0.50)
  dat <- data.frame(y = y, m1 = m1, m2 = m2, x = x)
  if (identical(missingness, "mcar")) {
    dat$m1[seq_len(n) %% 5L == 0L] <- NA_real_
    dat$m2[seq_len(n) %% 7L == 0L] <- NA_real_
  } else {
    # Outcome-dependent MAR: larger y more likely to drop a mediator.
    dat$m1[y > quantile(y, 0.72)] <- NA_real_
    dat$m2[y > quantile(y, 0.80)] <- NA_real_
  }
  dat
}

fit_two_independent_gaussian_mi <- function(dat) {
  drmTMB(
    bf(y ~ mi(m1) + mi(m2) + x, sigma ~ 1),
    data = dat,
    impute = list(
      m1 = impute_model(m1 ~ x, family = gaussian()),
      m2 = impute_model(m2 ~ x, family = gaussian())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

test_that("two independent Gaussian mi() terms retain both predictors", {
  dat <- two_independent_gaussian_mi_data(missingness = "mcar")
  fit <- fit_two_independent_gaussian_mi(dat)

  expect_equal(nobs(fit), nrow(dat))
  expect_named(fit$missing_data$predictors, c("m1", "m2"), ignore.order = TRUE)
  expect_equal(
    fit$missing_data$predictors$m1$model_row,
    which(is.na(dat$m1))
  )
  expect_equal(
    fit$missing_data$predictors$m2$model_row,
    which(is.na(dat$m2))
  )
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_m1"))))
  expect_true(all(is.finite(coef(fit, "mi_m2"))))
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-2)
  expect_error(imputed(fit), "variable")
  expect_equal(nrow(imputed(fit, "m1")), sum(is.na(dat$m1)))
  expect_equal(nrow(imputed(fit, "m2")), sum(is.na(dat$m2)))
})

test_that("two independent Gaussian mi() recover MCAR coefficients", {
  dat <- two_independent_gaussian_mi_data(n = 400, missingness = "mcar")
  fit <- fit_two_independent_gaussian_mi(dat)
  mu <- unname(coef(fit, "mu"))
  expect_equal(mu, c(0.30, 0.80, 0.60, 0.25), tolerance = 0.20)
  expect_equal(unname(coef(fit, "mi_m1")), c(0.20, 0.70), tolerance = 0.20)
  expect_equal(unname(coef(fit, "mi_m2")), c(-0.10, 0.55), tolerance = 0.20)
})

test_that("two independent Gaussian mi() recover MAR coefficients", {
  dat <- two_independent_gaussian_mi_data(n = 500, missingness = "mar")
  fit <- fit_two_independent_gaussian_mi(dat)
  mu <- unname(coef(fit, "mu"))
  expect_equal(mu[[1L]], 0.30, tolerance = 0.25)
  expect_equal(mu[[2L]], 0.80, tolerance = 0.25)
  expect_equal(mu[[3L]], 0.60, tolerance = 0.25)
})

test_that("two independent Gaussian mi() are sentinel-invariant at missing rows", {
  dat <- two_independent_gaussian_mi_data(missingness = "mcar")
  fit <- fit_two_independent_gaussian_mi(dat)
  tmb_data <- fit$model$tmb_data
  miss1 <- as.integer(tmb_data$mi_missing_index) + 1L
  miss2 <- as.integer(tmb_data$mi_missing_index2) + 1L
  expect_true(length(miss1) > 0L)
  expect_true(length(miss2) > 0L)

  data_a <- tmb_data
  data_b <- tmb_data
  data_a$mi_x[miss1] <- 1e6
  data_a$mi_x2[miss2] <- -1e6
  data_b$mi_x[miss1] <- -1e6
  data_b$mi_x2[miss2] <- 1e6
  expect_false(identical(data_a$mi_x[miss1], data_b$mi_x[miss1]))
  expect_false(identical(data_a$mi_x2[miss2], data_b$mi_x2[miss2]))

  obj_a <- missing_response_retaped_object(fit, data_a)
  obj_b <- missing_response_retaped_object(fit, data_b)
  par <- fit$opt$par
  expect_equal(obj_a$fn(par), obj_b$fn(par), tolerance = 1e-8)
  expect_equal(obj_a$gr(par), obj_b$gr(par), tolerance = 1e-8, ignore_attr = TRUE)
})

test_that("three independent mi() terms are still refused", {
  dat <- two_independent_gaussian_mi_data(missingness = "mcar")
  dat$m3 <- dat$x + rnorm(nrow(dat), sd = 0.3)
  dat$m3[seq_len(nrow(dat)) %% 11L == 0L] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ mi(m1) + mi(m2) + mi(m3) + x, sigma ~ 1),
      data = dat,
      impute = list(
        m1 = impute_model(m1 ~ x, family = gaussian()),
        m2 = impute_model(m2 ~ x, family = gaussian()),
        m3 = impute_model(m3 ~ x, family = gaussian())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "k > 2"
  )
})

test_that("poisson still refuses two mi() terms", {
  dat <- two_independent_gaussian_mi_data(missingness = "mcar")
  dat$y <- rpois(nrow(dat), lambda = 2)
  expect_error(
    drmTMB(
      bf(y ~ mi(m1) + mi(m2) + x),
      family = poisson(),
      data = dat,
      impute = list(
        m1 = impute_model(m1 ~ x, family = gaussian()),
        m2 = impute_model(m2 ~ x, family = gaussian())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "exactly one"
  )
})
