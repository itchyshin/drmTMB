test_that("Binomial crossed intercepts retain separate SD regressions", {
  skip_on_cran()

  set.seed(20261029L)
  ng <- 40L
  nh <- 40L
  repeats <- 4L
  levels_g <- paste0("g", seq_len(ng))
  levels_h <- paste0("h", seq_len(nh))
  dat <- expand.grid(
    id_g = levels_g,
    id_h = levels_h,
    rep = seq_len(repeats)
  )
  dat$id_g <- factor(dat$id_g, levels = levels_g)
  dat$id_h <- factor(dat$id_h, levels = levels_h)
  dat$x <- stats::rnorm(nrow(dat))
  z_g <- seq(-1, 1, length.out = ng)
  z_h <- seq(-1, 1, length.out = nh)
  dat$w <- z_g[as.integer(dat$id_g)]
  dat$v <- z_h[as.integer(dat$id_h)]
  alpha_g <- c(`(Intercept)` = log(0.45), w = 0.30)
  alpha_h <- c(`(Intercept)` = log(0.50), v = -0.25)
  b_g <- stats::rnorm(
    ng, sd = exp(alpha_g[[1L]] + alpha_g[[2L]] * z_g)
  )
  b_h <- stats::rnorm(
    nh, sd = exp(alpha_h[[1L]] + alpha_h[[2L]] * z_h)
  )
  dat$y <- stats::rbinom(
    nrow(dat), 1L,
    stats::plogis(-0.2 + 0.4 * dat$x +
      b_g[as.integer(dat$id_g)] + b_h[as.integer(dat$id_h)])
  )

  fit <- drmTMB(
    bf(
      y ~ x + (1 | id_g) + (1 | id_h),
      sd(id_g) ~ w,
      sd(id_h) ~ v
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_true(is_converged(fit))
  expect_true(is.finite(as.numeric(logLik(fit))))
  coef_g <- coef(fit, dpar = "sd(id_g)")
  coef_h <- coef(fit, dpar = "sd(id_h)")
  expect_gt(coef_g[["w"]], 0)
  expect_lt(abs(coef_g[["w"]] - alpha_g[["w"]]), 0.45)
  expect_lt(coef_h[["v"]], 0)
  expect_lt(abs(coef_h[["v"]] - alpha_h[["v"]]), 0.45)

  pred_g <- predict(fit, dpar = "sd(id_g)")
  pred_h <- predict(fit, dpar = "sd(id_h)")
  expect_equal(
    unname(pred_g),
    as.vector(exp(stats::model.matrix(~w, data.frame(w = z_g)) %*% coef_g)),
    tolerance = 1e-8
  )
  expect_equal(
    unname(pred_h),
    as.vector(exp(stats::model.matrix(~v, data.frame(v = z_h)) %*% coef_h)),
    tolerance = 1e-8
  )

  simulated <- simulate(fit, nsim = 1L, seed = 202610291L)[[1L]]
  expect_length(simulated, nrow(dat))
  expect_true(all(simulated %in% 0:1))
})
