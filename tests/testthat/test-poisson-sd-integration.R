test_that("Poisson latent SD has named coefficients and an independent likelihood", {
  sim <- poisson_sd_fixture(groups = 50L, repeats = 12L)
  fit <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w),
                poisson(), sim$data)
  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-3)
  health <- check_drm(fit)
  expect_equal(health$status[health$check == "logsigma_clamp_active"], "ok")
  expect_named(coef(fit, "sd(id)"), c("(Intercept)", "w"))
  expect_true(all(c("sd(id):(Intercept)", "sd(id):w") %in%
                  rownames(vcov(fit))))
  expect_named(fit$sdpars, "sd(id)")
  expect_equal(unname(predict(fit, dpar = "sd(id)")),
               unname(fit$sdpars[["sd(id)"]]), tolerance = 1e-7)
  table <- predict_parameters(fit, dpar = "sd(id)", include_newdata = FALSE)
  expect_identical(table$row_label,
                   fit$model$random_scale$mu$group_levels_list[["sd(id)"]])
  expect_equal(table$estimate, unname(predict(fit, dpar = "sd(id)")))
  oracle <- poisson_sd_laplace_oracle(sim$data, coef(fit, "mu"),
                                       coef(fit, "sd(id)"))
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6)
  wrong <- poisson_sd_laplace_oracle(sim$data, coef(fit, "mu"),
                                     coef(fit, "sd(id)"),
                                     reverse_group_w = TRUE)
  expect_gt(abs(wrong - oracle), 0.01)
  expect_lt(abs(coef(fit, "sd(id)")[["w"]] - sim$alpha[["w"]]), 0.35)
  targets <- profile_targets(fit)
  row <- targets[targets$parm == "fixef:sd(id):w", , drop = FALSE]
  expect_equal(row$tmb_parameter, "beta_sd_mu")
  expect_equal(row$index, 2L)
})

test_that("Poisson scalar adaptive reference is distinct from Laplace", {
  sim <- poisson_sd_fixture(groups = 6L, repeats = 5L,
                             seed = 2026101720L)
  first <- which(sim$data$id == levels(sim$data$id)[[1L]])
  eta <- -0.2 + 0.35 * sim$data$x[first]
  tau <- sim$tau_group[[1L]]
  adaptive <- poisson_sd_scalar_log_marginal(sim$data$y[first], eta, tau,
                                              "adaptive")
  laplace <- poisson_sd_scalar_log_marginal(sim$data$y[first], eta, tau,
                                             "laplace")
  expect_true(is.finite(adaptive))
  expect_true(is.finite(laplace))
  expect_lt(abs(adaptive - laplace), 0.2)
  expect_gt(abs(poisson_sd_scalar_log_marginal(sim$data$y[first], eta,
                                               tau * 1.7, "adaptive") -
                  adaptive), 0.001)
})

test_that("constant Poisson SD preserves the ordinary likelihood", {
  dat <- poisson_sd_fixture(groups = 50L, repeats = 12L,
                             seed = 2026101721L)$data
  ordinary <- drmTMB(bf(y ~ x + (1 | id)), poisson(), dat)
  scaled <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ 1), poisson(), dat)
  expect_equal(as.numeric(logLik(scaled)), as.numeric(logLik(ordinary)),
               tolerance = 1e-5)
  expect_equal(unname(coef(scaled, "mu")), unname(coef(ordinary, "mu")),
               tolerance = 1e-4)
  expect_equal(unname(predict(scaled, dpar = "sd(id)")),
               rep(unname(ordinary$sdpars$mu[[1L]]), nlevels(dat$id)),
               tolerance = 1e-4)
})

test_that("Poisson SD prediction and marginal simulation retain target mapping", {
  dat <- poisson_sd_fixture(groups = 36L, repeats = 8L,
                             seed = 2026101722L)$data
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  fit <- drmTMB(bf(
    y ~ x + (1 | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w
  ), poisson(), dat)
  grid <- data.frame(w = c(-0.5, 0, 0.5))
  expected <- exp(coef(fit, key)[[1L]] + coef(fit, key)[[2L]] * grid$w)
  expect_equal(unname(predict(fit, dpar = key, newdata = grid)),
               unname(expected), tolerance = 1e-7)
  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  stored <- readRDS(path)
  expect_equal(predict(stored, dpar = key, newdata = grid),
               predict(fit, dpar = key, newdata = grid))
  marginal <- simulate(fit, nsim = 2L, seed = 2026101723L)
  expect_equal(dim(marginal), c(nrow(dat), 2L))
  selected <- c(1L, nrow(dat))
  set.seed(2026101724L)
  latent <- replicate(1000L, {
    draw <- drm_ordinary_random_effect_draws(fit)$mu
    draw[selected]
  })
  ratio <- var(latent[2L, ]) / var(latent[1L, ])
  sd_group <- predict(fit, dpar = key)
  expected_ratio <- (sd_group[[36L]] / sd_group[[1L]])^2
  expect_equal(ratio, expected_ratio, tolerance = 0.2)
})

test_that("Poisson SD bootstrap refits retain the selected parameter", {
  dat <- poisson_sd_fixture(groups = 36L, repeats = 8L,
                             seed = 2026101725L)$data
  fit <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w), poisson(), dat)
  boot <- suppressMessages(confint(fit, parm = "sd(id):w",
                                method = "bootstrap", R = 2L,
                                seed = 2026101726L))
  diagnostics <- attr(boot, "bootstrap.diagnostics", exact = TRUE)
  expect_equal(nrow(diagnostics), 2L)
  expect_true(any(diagnostics$refit_status == "ok"))
})

test_that("a scalar Poisson label preserves fitting and public target identity", {
  dat <- poisson_sd_fixture(groups = 50L, repeats = 12L,
                             seed = 2026101727L)$data
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)", block = "p")'
  plain <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w), poisson(), dat)
  labelled <- drmTMB(bf(
    y ~ x + (1 | p | id),
    sd(id, dpar = "mu", coef = "(Intercept)", block = "p") ~ w
  ), poisson(), dat)
  expect_equal(labelled$opt$convergence, 0L)
  expect_true(labelled$sdr$pdHess)
  expect_lt(max(abs(labelled$obj$gr(labelled$opt$par))), 1e-3)
  expect_equal(as.numeric(logLik(labelled)), as.numeric(logLik(plain)),
               tolerance = 1e-7)
  expect_equal(coef(labelled, "mu"), coef(plain, "mu"), tolerance = 1e-6)
  expect_equal(coef(labelled, key), coef(plain, "sd(id)"), tolerance = 1e-6)
  expect_equal(unname(predict(labelled, dpar = key)),
               unname(predict(plain, dpar = "sd(id)")), tolerance = 1e-6)
  expect_identical(labelled$model$random$mu$n_cors, 0L)
  row <- profile_targets(labelled)
  row <- row[row$parm == paste0("fixef:", key, ":w"), , drop = FALSE]
  expect_equal(row$tmb_parameter, "beta_sd_mu")
  expect_equal(row$index, 2L)
  tab <- predict_parameters(labelled, dpar = key, include_newdata = FALSE)
  expect_identical(tab$row_label, levels(dat$id))
  set.seed(2026101728L)
  draw_labelled <- drm_ordinary_random_effect_draws(labelled)$mu
  set.seed(2026101728L)
  draw_plain <- drm_ordinary_random_effect_draws(plain)$mu
  expect_equal(draw_labelled, draw_plain, tolerance = 1e-6)
  stored_path <- tempfile(fileext = ".rds")
  saveRDS(labelled, stored_path)
  expect_equal(predict(readRDS(stored_path), dpar = key),
               predict(labelled, dpar = key))
  ordinary <- drmTMB(bf(y ~ x + (1 | p | id)), poisson(), dat)
  constant <- drmTMB(bf(y ~ x + (1 | p | id), sd(id, block = "p") ~ 1),
                     poisson(), dat)
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(ordinary)),
               tolerance = 1e-5)
  expect_equal(unname(predict(constant, dpar = 'sd(id, block = "p")')),
               rep(unname(ordinary$sdpars$mu[[1L]]), nlevels(dat$id)),
               tolerance = 1e-4)
})
