lognormal_sigma_sd_regression_dgp <- function(groups = 400L, repeats = 24L,
                                             seed = 20261021L) {
  set.seed(seed)
  group_w <- seq(-1, 1, length.out = groups)
  tau <- exp(log(0.32) + 0.4 * group_w)
  b <- stats::rnorm(groups, sd = tau)
  id <- factor(rep(seq_len(groups), each = repeats))
  w <- group_w[as.integer(id)]
  y <- stats::rlnorm(
    length(id),
    meanlog = 0.2,
    sdlog = exp(-0.4 + b[as.integer(id)])
  )
  list(
    data = data.frame(y = y, w = w, id = id),
    truth = c("(Intercept)" = log(0.32), w = 0.4),
    group_w = group_w
  )
}

lognormal_sigma_slope_sd_regression_dgp <- function(
  groups = 160L,
  repeats = 16L,
  seed = 20261025L
) {
  set.seed(seed)
  group_w <- seq(-1, 1, length.out = groups)
  tau <- exp(log(0.28) + 0.35 * group_w)
  group_effect <- stats::rnorm(groups, sd = tau)
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- rep(rep(c(-1, 1), length.out = repeats), times = groups)
  w <- group_w[as.integer(id)]
  sigma <- exp(-0.4 + x * group_effect[as.integer(id)])
  y <- stats::rlnorm(length(id), meanlog = 0.2, sdlog = sigma)
  list(
    data = data.frame(y = y, x = x, w = w, id = id),
    truth = c("(Intercept)" = log(0.28), w = 0.35),
    group_w = group_w
  )
}

test_that("the SD target parser retains explicit distributional parameters", {
  target <- drmTMB:::parse_sd_lhs(quote(sd(id, dpar = "sigma")))
  expect_identical(target$group, "id")
  expect_identical(target$target_dpar, "sigma")
  expect_identical(target$dpar, 'sd(id, dpar = "sigma")')
})

test_that("lognormal sigma random-intercept SD can depend on a group predictor", {
  sim <- lognormal_sigma_sd_regression_dgp()
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1 + (1 | id), sd(id, dpar = "sigma") ~ w),
    family = lognormal(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  estimate <- coef(fit, dpar = 'sd(id, dpar = "sigma")')
  expect_named(estimate, names(sim$truth))
  expect_equal(unname(estimate), unname(sim$truth), tolerance = 0.20)
  targets <- drmTMB:::drm_profile_targets(fit)
  sd_targets <- targets[
    targets$dpar == 'sd(id, dpar = "sigma")' &
      targets$target_class == "fixed-effect",
    , drop = FALSE
  ]
  expect_identical(sd_targets$tmb_parameter, rep("beta_sd_sigma", 2L))
  expect_true(all(sd_targets$profile_ready))
  expect_true(all(is.finite(vcov(fit, dpar = 'sd(id, dpar = "sigma")'))))

  predicted <- predict(fit, dpar = 'sd(id, dpar = "sigma")')
  expect_length(predicted, length(sim$group_w))
  expect_true(all(predicted > 0))
  expect_equal(
    unname(predicted),
    unname(exp(estimate[[1L]] + estimate[[2L]] * sim$group_w)),
    tolerance = 1e-10
  )
  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  sigma_contribution <- drmTMB:::sigma_random_effect_contribution(
    fit,
    dpar = "sigma"
  )
  expect_equal(
    unname(sigma_link),
    unname(fixed_sigma + sigma_contribution),
    tolerance = 1e-8
  )
  expect_equal(sigma(fit), exp(sigma_link), tolerance = 1e-8)
  simulated <- simulate(fit, nsim = 2L, seed = 20261024L)
  expect_s3_class(simulated, "data.frame")
  expect_equal(dim(simulated), c(nrow(sim$data), 2L))
  expect_true(all(is.finite(as.matrix(simulated)) & as.matrix(simulated) > 0))

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  reloaded <- readRDS(path)
  expect_equal(
    predict(reloaded, dpar = 'sd(id, dpar = "sigma")'),
    predicted
  )
})

test_that("lognormal sigma random-slope SD can depend on a group predictor", {
  sim <- lognormal_sigma_slope_sd_regression_dgp()
  fit <- drmTMB(
    bf(
      y ~ 1,
      sigma ~ 1 + (0 + x | id),
      sd(id, dpar = "sigma", coef = "x") ~ w
    ),
    family = lognormal(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  estimate <- coef(fit, dpar = 'sd(id, dpar = "sigma", coef = "x")')
  expect_named(estimate, names(sim$truth))
  expect_equal(unname(estimate), unname(sim$truth), tolerance = 0.25)
  predicted <- predict(
    fit,
    dpar = 'sd(id, dpar = "sigma", coef = "x")'
  )
  expect_length(predicted, length(sim$group_w))
  expect_equal(
    unname(predicted),
    unname(exp(estimate[[1L]] + estimate[[2L]] * sim$group_w)),
    tolerance = 1e-10
  )
})

test_that("lognormal sigma random slopes need a matching SD formula", {
  sim <- lognormal_sigma_slope_sd_regression_dgp(groups = 12L, repeats = 4L)
  expect_error(
    drmTMB(
      bf(y ~ 1, sigma ~ 1 + (0 + x | id)),
      family = lognormal(),
      data = sim$data
    ),
    "random slopes"
  )
})


test_that("lognormal sigma SD slope profile works on an informative smoke fit", {
  sim <- lognormal_sigma_sd_regression_dgp(
    groups = 120L,
    repeats = 12L,
    seed = 20261022L
  )
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1 + (1 | id), sd(id, dpar = "sigma") ~ w),
    family = lognormal(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  targets <- profile_targets(fit)
  target <- targets$parm[
    targets$dpar == 'sd(id, dpar = "sigma")' & targets$term == "w"
  ]
  expect_length(target, 1L)
  ci <- confint(
    fit,
    parm = target,
    level = 0.95,
    method = "profile",
    trace = FALSE
  )

  expect_identical(ci$parm, target)
  expect_equal(ci$level, 0.95)
  expect_equal(ci$conf.status, "profile")
  expect_false(ci$profile.boundary)
  expect_true(all(is.finite(c(ci$lower, ci$upper))))
  expect_lt(ci$lower, sim$truth[["w"]])
  expect_gt(ci$upper, sim$truth[["w"]])

  bootstrap_ci <- confint(
    fit,
    parm = target,
    level = 0.95,
    method = "bootstrap",
    R = 3L,
    seed = 20261023L,
    parallel = "none",
    refit_control = drm_control(se = FALSE)
  )
  diagnostics <- attr(bootstrap_ci, "bootstrap.diagnostics", exact = TRUE)
  expect_identical(bootstrap_ci$parm, target)
  expect_identical(bootstrap_ci$method, "bootstrap")
  expect_identical(bootstrap_ci$conf.status, "bootstrap")
  expect_identical(bootstrap_ci$bootstrap.n, 3L)
  expect_identical(bootstrap_ci$bootstrap.failed, 0L)
  expect_s3_class(diagnostics, "data.frame")
  expect_equal(nrow(diagnostics), 3L)
  expect_identical(diagnostics$parm, rep(target, 3L))
  expect_true(all(diagnostics$refit_converged))
  expect_true(all(diagnostics$target_available))
  expect_true(all(diagnostics$draw_used))
})

test_that("constant lognormal sigma SD agrees with the legacy intercept fit", {
  sim <- lognormal_sigma_sd_regression_dgp(
    groups = 36L,
    repeats = 12L,
    seed = 20261022L
  )
  legacy <- drmTMB(
    bf(y ~ 1, sigma ~ 1 + (1 | id)),
    family = lognormal(),
    data = sim$data
  )
  constant <- drmTMB(
    bf(y ~ 1, sigma ~ 1 + (1 | id), sd(id, dpar = "sigma") ~ 1),
    family = lognormal(),
    data = sim$data
  )

  expect_equal(legacy$opt$convergence, 0)
  expect_equal(constant$opt$convergence, 0)
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(legacy)),
               tolerance = 1e-5)
  expect_equal(
    unname(coef(constant, dpar = 'sd(id, dpar = "sigma")')),
    unname(log(legacy$sdpars$sigma)),
    tolerance = 1e-4
  )
})

test_that("lognormal sigma SD predictors must be constant within group", {
  sim <- lognormal_sigma_sd_regression_dgp(groups = 8L, repeats = 3L)
  sim$data$w <- seq_len(nrow(sim$data))

  expect_error(
    drmTMB(
      bf(y ~ 1, sigma ~ 1 + (1 | id), sd(id, dpar = "sigma") ~ w),
      family = lognormal(),
      data = sim$data
    ),
    "constant within"
  )
})
