test_that("Bernoulli SD regression recovers its named latent-scale target", {
  sim <- binomial_sd_fixture()
  fit <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w),
                family = binomial(), data = sim$data)

  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)
  expect_named(coef(fit), c("mu", "sd(id)"))
  expect_named(coef(fit, "sd(id)"), c("(Intercept)", "w"))
  expect_lt(max(abs(coef(fit, "sd(id)") - sim$alpha)), 0.35)
  expect_named(fit$sdpars, "sd(id)")
  expect_true(all(predict(fit, dpar = "sd(id)") > 0))
  expect_equal(length(predict(fit, dpar = "sd(id)")), nlevels(sim$data$id))
  expect_true(all(c("sd(id):(Intercept)", "sd(id):w") %in%
                    rownames(stats::vcov(fit))))
  expect_equal(sigma(fit), rep(1, nobs(fit)))
})

test_that("Bernoulli SD regression recovers one independent random slope", {
  set.seed(2026101811L)
  groups <- 80L
  repeats <- 40L
  id <- factor(rep(seq_len(groups), each = repeats))
  w_group <- seq(-1, 1, length.out = groups)
  w <- rep(w_group, each = repeats)
  x <- stats::rnorm(length(id))
  alpha <- c("(Intercept)" = -0.7, w = 0.4)
  slope_sd <- exp(alpha[[1L]] + alpha[[2L]] * w_group)
  b <- stats::rnorm(groups, sd = slope_sd)
  probability <- stats::plogis(0.2 + 0.35 * x + b[as.integer(id)] * x)
  y <- stats::rbinom(length(id), size = 1L, prob = probability)
  dat <- data.frame(y, x, w, id)

  fit <- drmTMB(bf(y ~ x + (0 + x | id), sd(id) ~ w),
                family = binomial(), data = dat)
  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)
  expect_named(coef(fit, "sd(id)"), c("(Intercept)", "w"))
  expect_equal(sign(coef(fit, "sd(id)")[["w"]]), sign(alpha[["w"]]))
  expect_lt(abs(coef(fit, "sd(id)")[["w"]] - alpha[["w"]]), 0.45)
  expect_equal(unname(predict(fit, dpar = "sd(id)")),
               exp(coef(fit, "sd(id)")[[1L]] + coef(fit, "sd(id)")[[2L]] * w_group),
               tolerance = 1e-7)
  prediction <- predict_parameters(fit, dpar = "sd(id)", include_newdata = FALSE)
  expect_identical(prediction$row_label, levels(id))
  expect_equal(prediction$estimate, unname(predict(fit, dpar = "sd(id)")))

  response_draws <- stats::simulate(fit, nsim = 2L, seed = 2026101812L)
  expect_equal(dim(response_draws), c(nrow(dat), 2L))
  expect_true(all(unlist(response_draws, use.names = FALSE) %in% c(0, 1)))
  set.seed(2026101813L)
  selected <- c(1L, nrow(dat))
  latent_draws <- replicate(1200L,
    drm_ordinary_random_effect_draws(fit)$mu[selected]
  )
  scales <- predict(fit, dpar = "sd(id)")
  expected_variance_ratio <-
    (dat$x[selected[[2L]]] * tail(scales, 1L) /
       (dat$x[selected[[1L]]] * scales[[1L]]))^2
  expect_equal(var(latent_draws[2L, ]) / var(latent_draws[1L, ]),
               unname(expected_variance_ratio), tolerance = 0.25)

  profile <- suppressMessages(confint(
    fit, parm = "sd(id):w", method = "profile"
  ))
  expect_equal(nrow(profile), 1L)
  expect_true(all(is.finite(profile$lower) & is.finite(profile$upper) &
                    profile$upper > profile$lower))
  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  stored <- readRDS(path)
  expect_equal(predict(stored, dpar = "sd(id)"),
               predict(fit, dpar = "sd(id)"))

  beta <- coef(fit, "mu")
  alpha_hat <- coef(fit, "sd(id)")
  slope_oracle <- sum(vapply(split(seq_len(nrow(dat)), dat$id), function(rows) {
    eta <- beta[[1L]] + beta[[2L]] * dat$x[rows]
    tau <- exp(alpha_hat[[1L]] + alpha_hat[[2L]] * dat$w[rows[[1L]]])
    joint_nll <- function(random_slope) {
      -sum(stats::dbinom(
        dat$y[rows], size = 1L,
        prob = stats::plogis(eta + random_slope * dat$x[rows]), log = TRUE
      )) - stats::dnorm(random_slope, sd = tau, log = TRUE)
    }
    mode <- stats::optimize(joint_nll, c(-15 * tau, 15 * tau), tol = 1e-10)$minimum
    p <- stats::plogis(eta + mode * dat$x[rows])
    hessian <- 1 / tau^2 + sum(p * (1 - p) * dat$x[rows]^2)
    joint_nll(mode) + 0.5 * log(hessian) - 0.5 * log(2 * pi)
  }, numeric(1L)))
  expect_equal(-as.numeric(logLik(fit)), slope_oracle, tolerance = 1e-6)

  constant <- drmTMB(bf(y ~ x + (0 + x | id), sd(id) ~ 1),
                     family = binomial(), data = dat)
  ordinary <- drmTMB(bf(y ~ x + (0 + x | id)),
                     family = binomial(), data = dat)
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(ordinary)),
               tolerance = 1e-6)
  expect_equal(coef(constant, "mu"), coef(ordinary, "mu"), tolerance = 1e-4)
  bootstrap <- suppressMessages(confint(
    constant,
    parm = "sd(id):(Intercept)",
    method = "bootstrap",
    R = 2L,
    seed = 2026101815L
  ))
  diagnostics <- attr(bootstrap, "bootstrap.diagnostics", exact = TRUE)
  expect_equal(nrow(diagnostics), 2L)
  expect_true(any(diagnostics$refit_status == "ok"))
})

test_that("Bernoulli independent intercept and slope SDs can vary by group covariates", {
  set.seed(2026101816L)
  groups <- 160L
  repeats <- 32L
  id <- factor(rep(seq_len(groups), each = repeats))
  w_group <- seq(-1, 1, length.out = groups)
  v_group <- rep(c(-1, 1), length.out = groups)
  w <- rep(w_group, each = repeats)
  v <- rep(v_group, each = repeats)
  x <- stats::rnorm(length(id))
  alpha_intercept <- c("(Intercept)" = -0.75, w = 0.35)
  alpha_slope <- c("(Intercept)" = -1.0, v = 0.30)
  sd_intercept <- exp(alpha_intercept[[1L]] + alpha_intercept[[2L]] * w_group)
  sd_slope <- exp(alpha_slope[[1L]] + alpha_slope[[2L]] * v_group)
  b_intercept <- stats::rnorm(groups, sd = sd_intercept)
  b_slope <- stats::rnorm(groups, sd = sd_slope)
  probability <- stats::plogis(
    0.15 + 0.35 * x + b_intercept[as.integer(id)] +
      b_slope[as.integer(id)] * x
  )
  dat <- data.frame(
    y = stats::rbinom(length(id), size = 1L, prob = probability),
    x, w, v, id
  )
  key_intercept <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  key_slope <- 'sd(id, dpar = "mu", coef = "x")'

  fit <- drmTMB(bf(
    y ~ x + (1 | id) + (0 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ v
  ), family = binomial(), data = dat)

  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)
  expect_equal(sign(coef(fit, key_intercept)[["w"]]), sign(alpha_intercept[["w"]]))
  expect_equal(sign(coef(fit, key_slope)[["v"]]), sign(alpha_slope[["v"]]))
  expect_lt(abs(coef(fit, key_intercept)[["w"]] - alpha_intercept[["w"]]), 0.55)
  expect_lt(abs(coef(fit, key_slope)[["v"]] - alpha_slope[["v"]]), 0.55)
  expect_equal(
    unname(predict(fit, dpar = key_intercept)),
    exp(coef(fit, key_intercept)[[1L]] + coef(fit, key_intercept)[[2L]] * w_group),
    tolerance = 1e-7
  )
  expect_equal(
    unname(predict(fit, dpar = key_slope)),
    exp(coef(fit, key_slope)[[1L]] + coef(fit, key_slope)[[2L]] * v_group),
    tolerance = 1e-7
  )

  beta <- coef(fit, "mu")
  alpha0 <- coef(fit, key_intercept)
  alpha1 <- coef(fit, key_slope)
  oracle <- sum(vapply(seq_len(groups), function(g) {
    rows <- which(as.integer(id) == g)
    tau0 <- exp(alpha0[[1L]] + alpha0[[2L]] * w_group[[g]])
    tau1 <- exp(alpha1[[1L]] + alpha1[[2L]] * v_group[[g]])
    joint_nll <- function(b) {
      eta <- beta[[1L]] + beta[[2L]] * x[rows] + b[[1L]] + b[[2L]] * x[rows]
      -sum(stats::dbinom(dat$y[rows], 1L, stats::plogis(eta), log = TRUE)) -
        stats::dnorm(b[[1L]], 0, tau0, log = TRUE) -
        stats::dnorm(b[[2L]], 0, tau1, log = TRUE)
    }
    mode <- stats::optim(c(0, 0), joint_nll, method = "BFGS", hessian = TRUE)
    det_h <- determinant(mode$hessian, logarithm = TRUE)
    expect_equal(mode$convergence, 0L)
    expect_gt(det_h$sign, 0)
    mode$value + 0.5 * as.numeric(det_h$modulus) - log(2 * pi)
  }, numeric(1L)))
  expect_equal(-as.numeric(logLik(fit)), oracle, tolerance = 2e-5)
})

test_that("Bernoulli SD likelihood agrees with an independent Laplace oracle", {
  dat <- binomial_sd_fixture(groups = 50L, repeats = 12L)$data
  fit <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w),
                family = binomial(), data = dat)
  oracle <- binomial_sd_laplace_oracle(dat, coef(fit, "mu"),
                                      coef(fit, "sd(id)"))
  expect_equal(-as.numeric(logLik(fit)), oracle, tolerance = 1e-6)
  wrong <- coef(fit, "sd(id)")
  wrong[[2L]] <- -wrong[[2L]] + 0.7
  expect_gt(abs(binomial_sd_laplace_oracle(dat, coef(fit, "mu"), wrong) -
                  oracle), 0.01)
})

test_that("constant Bernoulli SD formulas preserve the existing model", {
  dat <- binomial_sd_fixture(groups = 60L, repeats = 12L)$data
  ordinary <- drmTMB(bf(y ~ x + (1 | id)), binomial(), dat)
  scaled <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ 1), binomial(), dat)
  expect_equal(as.numeric(logLik(scaled)), as.numeric(logLik(ordinary)),
               tolerance = 1e-6)
  expect_equal(coef(scaled, "mu"), coef(ordinary, "mu"), tolerance = 1e-4)
  expect_equal(unname(predict(scaled, dpar = "sd(id)")),
               rep(unname(ordinary$sdpars$mu[[1L]]), nlevels(dat$id)),
               tolerance = 1e-4)
})

test_that("binomial SD prediction and stored fits preserve group coding", {
  dat <- binomial_sd_fixture(groups = 60L, repeats = 12L, trials = 5L)$data
  fit <- drmTMB(bf(cbind(y, failure) ~ x + (1 | id), sd(id) ~ w),
                binomial(), dat)
  grid <- data.frame(w = c(-0.5, 0, 0.5))
  expected <- exp(coef(fit, "sd(id)")[[1L]] +
                    coef(fit, "sd(id)")[[2L]] * grid$w)
  expect_equal(unname(predict(fit, dpar = "sd(id)", newdata = grid)),
               expected, tolerance = 1e-7)
  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  stored <- readRDS(path)
  expect_equal(predict(stored, dpar = "sd(id)", newdata = grid),
               predict(fit, dpar = "sd(id)", newdata = grid))
  expect_equal(coef(stored, "sd(id)"), coef(fit, "sd(id)"))
})

