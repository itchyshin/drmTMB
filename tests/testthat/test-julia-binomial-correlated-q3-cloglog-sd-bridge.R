test_that("Julia bridge fits and simulates correlated q3 cloglog SD regression", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  groups <- 160L
  repeats <- 32L
  id <- factor(rep(seq_len(groups), each = repeats))
  w0_group <- rep(c(-1, 1), each = groups / 2L)
  w1_group <- rep(c(-1, -1, 1, 1), length.out = groups)
  w2_group <- rep(c(-1, 1, 1, -1), length.out = groups)
  w0 <- w0_group[as.integer(id)]
  w1 <- w1_group[as.integer(id)]
  w2 <- w2_group[as.integer(id)]
  x1 <- rep(seq(-1.2, 1.2, length.out = repeats), times = groups)
  x2 <- rep(c(-1, 1), length.out = length(id))
  alpha <- list(
    c("(Intercept)" = -0.7, w0 = 0.45),
    c("(Intercept)" = -0.65, w1 = 0.4),
    c("(Intercept)" = -0.75, w2 = 0.5)
  )
  partial <- c(0.35, -0.25, 0.4)
  chol_r <- rbind(
    c(1, 0, 0),
    c(partial[[1L]], sqrt(1 - partial[[1L]]^2), 0),
    c(partial[[2L]], sqrt(1 - partial[[2L]]^2) * partial[[3L]],
      sqrt(1 - partial[[2L]]^2) * sqrt(1 - partial[[3L]]^2))
  )
  tau <- rbind(
    exp(alpha[[1L]][[1L]] + alpha[[1L]][[2L]] * w0_group),
    exp(alpha[[2L]][[1L]] + alpha[[2L]][[2L]] * w1_group),
    exp(alpha[[3L]][[1L]] + alpha[[3L]][[2L]] * w2_group)
  )
  set.seed(202610283L)
  latent <- chol_r %*% matrix(stats::rnorm(3L * groups), nrow = 3L)
  random <- tau * latent
  eta <- -0.7 + 0.2 * x1 - 0.15 * x2 +
    random[1L, as.integer(id)] +
    random[2L, as.integer(id)] * x1 +
    random[3L, as.integer(id)] * x2
  dat <- data.frame(
    y = stats::rbinom(length(id), size = 1L, prob = -expm1(-exp(eta))),
    x1, x2, w0, w1, w2, id
  )
  formula <- bf(
    y ~ x1 + x2 + (1 + x1 + x2 | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
    sd(id, dpar = "mu", coef = "x1") ~ w1,
    sd(id, dpar = "mu", coef = "x2") ~ w2
  )
  targets <- c(
    'sd(id, dpar = "mu", coef = "(Intercept)")',
    'sd(id, dpar = "mu", coef = "x1")',
    'sd(id, dpar = "mu", coef = "x2")'
  )
  prediction_data <- data.frame(
    id = factor(levels(id), levels = levels(id)),
    w0 = w0_group, w1 = w1_group, w2 = w2_group
  )

  expect_true(drm_julia_binomial_sd_link_route_admitted(
    formula, data = dat, link = "cloglog"
  ))
  fit_tmb <- drmTMB(
    formula, family = stats::binomial(link = "cloglog"), data = dat,
    engine = "tmb", control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    formula, family = stats::binomial(link = "cloglog"), data = dat,
    engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_length(fit_julia$corpars$mu, 3L)
  expect_named(fit_julia$corpars$mu, names(fit_tmb$corpars$mu))
  expect_equal(fit_julia$corpars$mu, fit_tmb$corpars$mu, tolerance = 0.2)
  for (i in seq_along(targets)) {
    julia_coef <- coef(fit_julia, targets[[i]])
    expect_named(julia_coef, names(alpha[[i]]))
    expect_equal(julia_coef, coef(fit_tmb, targets[[i]]), tolerance = 0.2)
    expect_equal(julia_coef[[2L]], alpha[[i]][[2L]], tolerance = 0.4)
    expect_equal(
      predict(fit_julia, dpar = targets[[i]], newdata = prediction_data),
      predict(fit_tmb, dpar = targets[[i]], newdata = prediction_data),
      tolerance = 0.2,
      info = targets[[i]]
    )
  }
  simulated <- simulate(fit_julia, nsim = 1L, seed = 202610284L)
  expect_true(all(unlist(simulated) %in% 0:1))
})
