test_that("Poisson slope SD matches an independent coefficient-weighted likelihood", {
  sim <- poisson_slope_sd_reference_fixture(seed = 2026101731L,
                                            groups = 160L, repeats = 16L)
  key <- 'sd(id, coef = "x")'
  fit <- drmTMB(bf(y ~ x + (0 + x | id), sd(id, coef = "x") ~ w),
                poisson(), sim$data)
  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-3)
  expect_named(coef(fit, key), c("(Intercept)", "w"))
  oracle <- poisson_slope_sd_group_log_marginal(sim$data, coef(fit, "mu"),
                                                coef(fit, key))
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6)
  wrong <- poisson_slope_sd_group_log_marginal(sim$data, coef(fit, "mu"),
    coef(fit, key), slope_x = rep(1, nrow(sim$data)))
  expect_gt(abs(wrong - oracle), 0.1)
  expect_lt(abs(coef(fit, key)[["w"]] - sim$alpha[["w"]]), 0.35)
  expect_equal(unname(predict(fit, dpar = key)),
    unname(exp(coef(fit, key)[[1L]] + coef(fit, key)[[2L]] * sim$w_by_group)),
    tolerance = 1e-7)
  tab <- predict_parameters(fit, dpar = key, include_newdata = FALSE)
  expect_identical(tab$row_label, levels(sim$data$id))
  expect_equal(tab$estimate, unname(predict(fit, dpar = key)))
  targets <- profile_targets(fit)
  target <- targets[targets$parm == paste0("fixef:", key, ":w"), , drop = FALSE]
  expect_identical(target$tmb_parameter, "beta_sd_mu")
  expect_identical(target$index, 2L)
  interval <- suppressMessages(confint(fit, parm = paste0(key, ":w"),
                                         method = "profile"))
  expect_equal(nrow(interval), 1L)
  expect_true(all(is.finite(interval$lower) & is.finite(interval$upper) &
                    interval$upper > interval$lower))
  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  expect_equal(predict(readRDS(path), dpar = key), predict(fit, dpar = key))
  response_draws <- simulate(fit, nsim = 2L, seed = 2026101735L)
  expect_equal(dim(response_draws), c(nrow(sim$data), 2L))
  expect_true(all(response_draws >= 0 & response_draws == floor(response_draws)))
  set.seed(2026101732L)
  selected <- c(1L, nrow(sim$data))
  latent <- replicate(1000L, drm_ordinary_random_effect_draws(fit)$mu[selected])
  scales <- predict(fit, dpar = key)
  expected <- (sim$data$x[selected[2L]] * tail(scales, 1L) /
               (sim$data$x[selected[1L]] * scales[[1L]]))^2
  expect_equal(var(latent[2L, ]) / var(latent[1L, ]),
               unname(expected), tolerance = 0.25)
})

test_that("constant Poisson slope SD reduces to the existing independent slope", {
  dat <- poisson_slope_sd_reference_fixture(seed = 2026101733L,
                                             groups = 80L, repeats = 12L)$data
  base <- drmTMB(bf(y ~ x + (0 + x | id)), poisson(), dat)
  scaled <- drmTMB(bf(y ~ x + (0 + x | id), sd(id) ~ 1), poisson(), dat)
  expect_equal(as.numeric(logLik(scaled)), as.numeric(logLik(base)),
               tolerance = 1e-5)
  expect_equal(coef(scaled, "mu"), coef(base, "mu"), tolerance = 1e-4)
  expect_equal(unname(predict(scaled, dpar = "sd(id)")),
               rep(unname(base$sdpars$mu[[1L]]), nlevels(dat$id)),
               tolerance = 1e-4)
  boot <- suppressMessages(confint(scaled, parm = "sd(id):(Intercept)",
    method = "bootstrap", R = 2L, seed = 2026101734L))
  diagnostics <- attr(boot, "bootstrap.diagnostics", exact = TRUE)
  expect_equal(nrow(diagnostics), 2L)
  expect_true(any(diagnostics$refit_status == "ok"))
})
