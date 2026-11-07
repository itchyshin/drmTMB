beta_binomial_sigma_sd_data <- function(groups = 8L, repeats = 5L) {
  group_index <- rep(seq_len(groups), each = repeats)
  group_w <- seq(-1, 1, length.out = groups)
  trials <- rep(18L, length(group_index))
  mu <- stats::plogis(0.15)
  sigma <- exp(-0.7 + 0.35 * group_w[group_index])
  concentration <- 1 / sigma^2
  probability <- stats::rbeta(
    length(group_index), mu * concentration, (1 - mu) * concentration
  )
  successes <- stats::rbinom(length(group_index), trials, probability)
  data.frame(
    success = successes,
    failure = trials - successes,
    w = group_w[group_index],
    id = factor(group_index)
  )
}

test_that("Beta-binomial sigma SD targets assemble against sigma random intercepts", {
  dat <- beta_binomial_sigma_sd_data()
  spec <- drm_build_beta_binomial_spec(
    bf(
      cbind(success, failure) ~ 1,
      sigma ~ 1 + (1 | id),
      sd(id, dpar = "sigma") ~ w
    ),
    dat
  )

  expect_identical(spec$random$sigma$n_terms, 1L)
  expect_identical(spec$random_scale$sigma$dpars, "sd(id, dpar = \"sigma\")")
  expect_equal(
    unname(spec$random_scale$sigma$X_list[[1L]][, "w"]),
    seq(-1, 1, length.out = 8L)
  )
  expect_equal(spec$random_scale$sigma$target_identity[[1L]]$dpar, "sigma")
  expect_true("u_sigma" %in% spec$random_names)

  dat$w[[1L]] <- dat$w[[1L]] + 0.25
  expect_error(
    drm_build_beta_binomial_spec(
      bf(
        cbind(success, failure) ~ 1,
        sigma ~ 1 + (1 | id),
        sd(id, dpar = "sigma") ~ w
      ),
      dat
    ),
    "Predictor w varies within id level"
  )
})

beta_binomial_sigma_sd_recovery_data <- function(
  groups = 72L, repeats = 18L, seed = 20261024L
) {
  set.seed(seed)
  group_w <- seq(-1, 1, length.out = groups)
  tau <- exp(log(0.32) + 0.4 * group_w)
  b_sigma <- stats::rnorm(groups, sd = tau)
  id <- factor(rep(seq_len(groups), each = repeats))
  n <- length(id)
  x <- stats::rnorm(n)
  trials <- rep(24L, n)
  mu <- stats::plogis(0.15 + 0.25 * x)
  sigma <- exp(-0.65 + b_sigma[as.integer(id)])
  concentration <- 1 / sigma^2
  probability <- stats::rbeta(
    n, shape1 = mu * concentration, shape2 = (1 - mu) * concentration
  )
  success <- stats::rbinom(n, size = trials, prob = probability)
  list(
    data = data.frame(
      success = success, failure = trials - success, x = x,
      w = group_w[as.integer(id)], id = id
    ),
    truth = c("(Intercept)" = log(0.32), w = 0.4),
    group_w = stats::setNames(group_w, levels(id))
  )
}

test_that("Beta-binomial sigma SD regression recovers a group-level trend", {
  sim <- beta_binomial_sigma_sd_recovery_data()
  fit <- drmTMB(
    bf(
      cbind(success, failure) ~ x,
      sigma ~ 1 + (1 | id),
      sd(id, dpar = "sigma") ~ w
    ),
    family = beta_binomial(),
    data = sim$data
  )

  target <- 'sd(id, dpar = "sigma")'
  estimate <- coef(fit, dpar = target)
  expect_equal(fit$opt$convergence, 0)
  expect_named(estimate, names(sim$truth))
  expect_true(all(abs(unname(estimate) - unname(sim$truth)) < 0.35))
  expect_true(all(is.finite(vcov(fit, dpar = target))))
  expect_named(
    fit$sdpars[[target]], paste0(target, ":", levels(sim$data$id))
  )
  expect_equal(
    unname(predict(fit, dpar = target)),
    unname(exp(estimate[[1L]] + estimate[[2L]] * sim$group_w)),
    tolerance = 1e-10
  )
  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  sigma_re <- drmTMB:::sigma_random_effect_contribution(fit, dpar = "sigma")
  expect_equal(sigma_link, fixed_sigma + sigma_re, tolerance = 1e-8)
  expect_equal(sigma(fit), exp(sigma_link), tolerance = 1e-8)

  simulated <- simulate(fit, nsim = 2L, re.form = NA, seed = 20261025L)
  expect_equal(nrow(simulated), nrow(sim$data))
  expect_equal(ncol(simulated), 2L)

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  reloaded <- readRDS(path)
  expect_equal(predict(reloaded, dpar = target), predict(fit, dpar = target))

  boot <- confint(
    fit,
    parm = paste0("fixef:", target, ":", names(estimate)),
    method = "bootstrap",
    R = 2L,
    seed = 20261026L
  )
  expect_true(all(is.finite(boot$conf.low) | is.na(boot$conf.low)))
  expect_true(all(is.finite(boot$conf.high) | is.na(boot$conf.high)))
  expect_equal(nrow(boot), length(estimate))
})

test_that("constant beta-binomial sigma SD matches the constant-SD model", {
  sim <- beta_binomial_sigma_sd_recovery_data(groups = 36L, repeats = 14L)
  constant_formula <- bf(
    cbind(success, failure) ~ x,
    sigma ~ 1 + (1 | id)
  )
  sd_formula <- bf(
    cbind(success, failure) ~ x,
    sigma ~ 1 + (1 | id),
    sd(id, dpar = "sigma") ~ 1
  )

  fit_constant <- drmTMB(
    constant_formula, family = beta_binomial(), data = sim$data
  )
  fit_sd <- drmTMB(
    sd_formula, family = beta_binomial(), data = sim$data
  )
  target <- 'sd(id, dpar = "sigma")'

  expect_equal(
    as.numeric(logLik(fit_sd)),
    as.numeric(logLik(fit_constant)),
    tolerance = 1e-6
  )
  expect_equal(
    unname(coef(fit_sd, dpar = target)[[1L]]),
    log(unname(fit_constant$sdpars$sigma[["(1 | id)"]])),
    tolerance = 1e-5
  )
})

beta_binomial_sigma_slope_recovery_data <- function(
  groups = 60L, repeats = 24L, seed = 20261029L
) {
  set.seed(seed)
  group_z <- rep(c(-1, 1), each = groups / 2L)
  id <- factor(rep(seq_len(groups), each = repeats))
  n <- length(id)
  x <- stats::rnorm(n)
  w <- stats::rnorm(n)
  tau <- exp(log(0.35) + 0.25 * group_z)
  b_sigma <- stats::rnorm(groups, sd = tau)
  sigma <- exp(-0.55 + x * b_sigma[as.integer(id)])
  mu <- stats::plogis(-0.15 + 0.45 * w)
  trials <- rep(24L, n)
  concentration <- 1 / sigma^2
  probability <- stats::rbeta(
    n, shape1 = mu * concentration, shape2 = (1 - mu) * concentration
  )
  success <- stats::rbinom(n, size = trials, prob = probability)
  data.frame(
    success = success, failure = trials - success, x = x, w = w,
    z = group_z[as.integer(id)], id = id
  )
}

test_that("Beta-binomial sigma SD regression recovers an independent slope", {
  dat <- beta_binomial_sigma_slope_recovery_data()
  target <- 'sd(id, dpar = "sigma", coef = "x")'
  fit <- drmTMB(
    bf(
      cbind(success, failure) ~ w,
      sigma ~ 1 + (0 + x | id),
      sd(id, dpar = "sigma", coef = "x") ~ z
    ),
    family = beta_binomial(), data = dat
  )

  estimate <- coef(fit, dpar = target)
  expect_equal(fit$opt$convergence, 0)
  expect_named(estimate, c("(Intercept)", "z"))
  expect_true(all(abs(unname(estimate) - c(log(0.35), 0.25)) < 0.45))
  expect_length(fit$sdpars[[target]], nlevels(dat$id))
  group_z <- dat$z[!duplicated(dat$id)]
  expect_equal(
    unname(predict(fit, dpar = target)),
    unname(exp(estimate[[1L]] + estimate[[2L]] * group_z)),
    tolerance = 1e-8
  )
  expect_true(all(is.finite(sigma(fit))))

  simulated <- simulate(fit, nsim = 1L, re.form = NA, seed = 20261030L)
  expect_equal(nrow(simulated), nrow(dat))
  expect_equal(ncol(simulated), 1L)

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  reloaded <- readRDS(path)
  expect_equal(predict(reloaded, dpar = target), predict(fit, dpar = target))
})

test_that("constant beta-binomial sigma-slope SD matches the existing model", {
  dat <- beta_binomial_sigma_slope_recovery_data(
    groups = 36L, repeats = 14L, seed = 20261031L
  )
  formula_constant <- bf(
    cbind(success, failure) ~ w,
    sigma ~ 1 + (0 + x | id)
  )
  formula_sd <- bf(
    cbind(success, failure) ~ w,
    sigma ~ 1 + (0 + x | id),
    sd(id, dpar = "sigma", coef = "x") ~ 1
  )
  fit_constant <- drmTMB(
    formula_constant, family = beta_binomial(), data = dat
  )
  fit_sd <- drmTMB(formula_sd, family = beta_binomial(), data = dat)
  target <- 'sd(id, dpar = "sigma", coef = "x")'

  expect_equal(fit_constant$opt$convergence, 0)
  expect_equal(fit_sd$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit_sd)), as.numeric(logLik(fit_constant)),
               tolerance = 1e-6)
  expect_equal(
    exp(unname(coef(fit_sd, dpar = target)[[1L]])),
    unname(fit_constant$sdpars$sigma[["(0 + x | id)"]]),
    tolerance = 1e-5
  )
})
