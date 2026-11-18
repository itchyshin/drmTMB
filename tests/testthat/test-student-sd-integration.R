student_sd_laplace_loglik <- function(data, mu, sigma, nu, alpha) {
  rows <- split(seq_len(nrow(data)), data$id)
  sum(vapply(rows, function(i) {
    w <- data$w[i[[1L]]]
    tau <- exp(alpha[["(Intercept)"]] + alpha[["w"]] * w)
    nll <- function(b) {
      -sum(stats::dt((data$y[i] - mu - b) / sigma, df = nu, log = TRUE) -
             log(sigma)) -
        stats::dnorm(b, mean = 0, sd = tau, log = TRUE)
    }
    radius <- max(20, 5 * tau + max(abs(data$y[i] - mu)) + 5)
    mode <- stats::optimize(nll, interval = c(-radius, radius), tol = 1e-11)$minimum
    residual <- data$y[i] - mu - mode
    curvature <- 1 / tau^2 + sum(
      (nu + 1) * (nu * sigma^2 - residual^2) /
        (nu * sigma^2 + residual^2)^2
    )
    if (!is.finite(curvature) || curvature <= 0) {
      stop("Student random-intercept Laplace curvature is not positive.",
           call. = FALSE)
    }
    -nll(mode) + 0.5 * log(2 * pi) - 0.5 * log(curvature)
  }, numeric(1L)))
}

student_sd_slope_laplace_loglik <- function(data, mu, sigma, nu, alpha) {
  rows <- split(seq_len(nrow(data)), data$id)
  sum(vapply(rows, function(i) {
    w <- data$w[i[[1L]]]
    tau <- exp(alpha[["(Intercept)"]] + alpha[["w"]] * w)
    loading <- data$x[i]
    nll <- function(b) {
      -sum(stats::dt((data$y[i] - mu[i] - b * loading) / sigma,
                     df = nu, log = TRUE) - log(sigma)) -
        stats::dnorm(b, mean = 0, sd = tau, log = TRUE)
    }
    radius <- max(20, 5 * tau + max(abs(data$y[i] - mu[i])) + 5)
    mode <- stats::optimize(nll, interval = c(-radius, radius),
                            tol = 1e-11)$minimum
    residual <- data$y[i] - mu[i] - mode * loading
    curvature <- 1 / tau^2 + sum(
      (nu + 1) * (nu * sigma^2 - residual^2) /
        (nu * sigma^2 + residual^2)^2 * loading^2
    )
    if (!is.finite(curvature) || curvature <= 0) {
      stop("Student random-slope Laplace curvature is not positive.",
           call. = FALSE)
    }
    -nll(mode) + 0.5 * log(2 * pi) - 0.5 * log(curvature)
  }, numeric(1L)))
}

test_that("Student SD regression fits and extracts coefficients", {
  set.seed(17017)
  groups <- 36L
  repeats <- 10L
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[group]
  b <- rnorm(groups, sd = exp(-0.25 + 0.35 * w_group))
  dat <- data.frame(
    y = 0.4 + b[group] + rt(length(group), df = 7) * 0.65,
    x = rnorm(length(group)), w = w, id = factor(group)
  )
  fit <- drmTMB(
    bf(y ~ 1 + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w),
    family = student(), data = dat
  )
  expect_true(is_converged(fit))
  co <- coef(fit)
  expect_true(all(c("(Intercept)", "w") %in% names(co[["sd(id)"]])))
  student_mu <- unname(coef(fit, dpar = "mu")[["(Intercept)"]])
  student_sigma <- exp(unname(coef(fit, dpar = "sigma")[["(Intercept)"]]))
  student_nu <- 2 + exp(unname(coef(fit, dpar = "nu")[["(Intercept)"]]))
  oracle <- student_sd_laplace_loglik(
    dat, student_mu, student_sigma, student_nu, coef(fit, dpar = "sd(id)")
  )
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-5)
  wrong_group <- dat
  reversed_w <- stats::setNames(
    rev(seq(-1, 1, length.out = groups)), levels(dat$id)
  )
  wrong_group$w <- unname(reversed_w[as.character(wrong_group$id)])
  wrong_oracle <- student_sd_laplace_loglik(
    wrong_group, student_mu, student_sigma, student_nu,
    coef(fit, dpar = "sd(id)")
  )
  expect_gt(abs(wrong_oracle - oracle), 0.1)
  sd_se <- sqrt(vcov(fit)["sd(id):w", "sd(id):w"])
  expect_lt(abs(unname(co[["sd(id)"]][["w"]]) - 0.35), 2 * sd_se)
  sd_prediction <- predict(fit, dpar = "sd(id)")
  expect_true(all(is.finite(sd_prediction)))
  expect_true(all(diff(unname(sd_prediction)) > 0))
  simulated <- simulate(fit, nsim = 1L, seed = 17018)
  expect_equal(nrow(simulated), nrow(dat))
  restored_path <- tempfile(fileext = ".rds")
  saveRDS(fit, restored_path)
  restored <- readRDS(restored_path)
  expect_equal(predict(restored, dpar = "sd(id)"), sd_prediction)
  unlink(restored_path)

  target <- "fixef:sd(id):w"
  profile_ci <- suppressMessages(confint(
    fit, parm = target, method = "profile", level = 0.95
  ))
  expect_identical(profile_ci$parm, target)
  expect_true(all(is.finite(c(profile_ci$lower, profile_ci$upper))))
  boot_ci <- suppressMessages(confint(
    fit, parm = target, method = "bootstrap", R = 2L, seed = 17019
  ))
  expect_true(all(is.finite(as.matrix(boot_ci))))
  boot_diagnostics <- attr(boot_ci, "bootstrap.diagnostics", exact = TRUE)
  expect_equal(nrow(boot_diagnostics), 2L)
  expect_true(any(boot_diagnostics$refit_status == "ok"))

  constant <- drmTMB(
    bf(y ~ 1 + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ 1),
    family = student(), data = dat
  )
  baseline <- drmTMB(
    bf(y ~ 1 + (1 | id), sigma ~ 1, nu ~ 1),
    family = student(), data = dat
  )
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(baseline)),
               tolerance = 1e-5)
})

test_that("Student independent-slope SD regression recovers and routes targets", {
  set.seed(17020)
  groups <- 48L
  repeats <- 12L
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[group]
  x <- rnorm(length(group))
  alpha <- c("(Intercept)" = -0.65, w = 0.35)
  b <- rnorm(groups, sd = exp(alpha[["(Intercept)"]] + alpha[["w"]] * w_group))
  dat <- data.frame(
    y = 0.2 + 0.45 * x + b[group] * x + rt(length(group), df = 7) * 0.65,
    x = x, w = w, id = factor(group)
  )
  target <- 'sd(id, dpar = "mu", coef = "x")'
  fit <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
       sd(id, dpar = "mu", coef = "x") ~ w),
    family = student(), data = dat
  )

  expect_true(is_converged(fit))
  estimate <- coef(fit, dpar = target)
  expect_true(all(c("(Intercept)", "w") %in% names(estimate)))
  expect_lt(abs(unname(estimate[["w"]] - alpha[["w"]])), 0.5)
  location <- as.vector(fit$model$X$mu %*% coef(fit, dpar = "mu"))
  sigma <- exp(unname(coef(fit, dpar = "sigma")[[1L]]))
  nu <- 2 + exp(unname(coef(fit, dpar = "nu")[[1L]]))
  oracle <- student_sd_slope_laplace_loglik(
    dat, location, sigma, nu, estimate
  )
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-5)

  reversed <- dat
  reversed_w <- stats::setNames(rev(w_group), levels(dat$id))
  reversed$w <- unname(reversed_w[as.character(reversed$id)])
  wrong_oracle <- student_sd_slope_laplace_loglik(
    reversed, location, sigma, nu, estimate
  )
  expect_gt(abs(wrong_oracle - oracle), 0.1)

  sd_prediction <- predict(fit, dpar = target)
  expect_true(all(is.finite(sd_prediction)))
  expect_true(all(diff(unname(sd_prediction)) > 0))
  expect_equal(length(simulate(fit, nsim = 1L, seed = 17021)[[1L]]),
               nrow(dat))
  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  expect_equal(predict(readRDS(path), dpar = target), sd_prediction)
  unlink(path)

  target_name <- paste0("fixef:", target, ":w")
  profile_ci <- suppressMessages(confint(
    fit, parm = target_name, method = "profile", level = 0.95
  ))
  expect_identical(profile_ci$parm, target_name)
  expect_true(all(is.finite(c(profile_ci$lower, profile_ci$upper))))
  boot_ci <- suppressMessages(confint(
    fit, parm = target_name, method = "bootstrap", R = 2L, seed = 17022
  ))
  expect_true(all(is.finite(as.matrix(boot_ci))))
  boot_diagnostics <- attr(boot_ci, "bootstrap.diagnostics", exact = TRUE)
  expect_equal(nrow(boot_diagnostics), 2L)
  expect_true(any(boot_diagnostics$refit_status == "ok"))

  constant <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
       sd(id, dpar = "mu", coef = "x") ~ 1),
    family = student(), data = dat
  )
  baseline <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1),
    family = student(), data = dat
  )
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(baseline)),
               tolerance = 1e-5)
  expect_equal(coef(constant, dpar = "mu"), coef(baseline, dpar = "mu"),
               tolerance = 1e-4)
})
