test_that("multiple ordinary SD targets retain distinct Julia coefficient labels", {
  dat <- data.frame(
    y = c(0L, 1L, 0L, 1L),
    x = c(-1, 1, -0.5, 0.5),
    id_g = factor(c("a", "a", "b", "b")),
    id_h = factor(c("u", "v", "u", "v")),
    w = c(-1, -1, 1, 1),
    v = c(-1, 1, -1, 1)
  )
  formula <- bf(
    y ~ x + (1 | id_g) + (1 | id_h),
    sd(id_g) ~ w,
    sd(id_h) ~ v
  )

  labels <- drm_julia_bridge_payload_coef_labels(
    formula,
    dat,
    environment(),
    family_type = "binomial"
  )

  target_g <- "sdtarget_69645f677c6969647c6d757c6e6f6e657c6e6f6e65"
  target_h <- "sdtarget_69645f687c6969647c6d757c6e6f6e657c6e6f6e65"
  expect_setequal(names(labels), c("mu", target_g, target_h))
  expect_identical(labels[[target_g]], c("(Intercept)", "w"))
  expect_identical(labels[[target_h]], c("(Intercept)", "v"))

  fit <- list(
    formula = formula,
    coefficients = stats::setNames(
      list(1, 2),
      c(target_g, target_h)
    )
  )
  sd_entries <- Filter(function(entry) {
    !is.null(entry$lhs) && is_random_scale_lhs(entry$lhs)
  }, formula$entries)
  targets <- lapply(sd_entries, function(entry) parse_sd_lhs(entry$lhs))
  expect_identical(drm_julia_sd_fit_block(fit, targets[[1L]]), target_g)
  expect_identical(drm_julia_sd_fit_block(fit, targets[[2L]]), target_h)
})

test_that("crossed Bernoulli SD regressions keep target-specific Julia outputs", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")

  # Independent crossed effects: each SD predictor varies between, and is
  # constant within, its own grouping factor. This is a bridge-routing smoke,
  # not a broad recovery or uncertainty-calibration claim.
  set.seed(20261023L)
  ng <- 40L
  nh <- 40L
  repeats <- 4L
  levels_g <- paste0("g", seq_len(ng))
  levels_h <- paste0("h", seq_len(nh))
  dat <- expand.grid(id_g = levels_g, id_h = levels_h, rep = seq_len(repeats))
  dat$id_g <- factor(dat$id_g, levels = levels_g)
  dat$id_h <- factor(dat$id_h, levels = levels_h)
  dat$x <- stats::rnorm(nrow(dat))
  z_g <- seq(-1, 1, length.out = ng)
  z_h <- seq(-1, 1, length.out = nh)
  dat$w <- z_g[as.integer(dat$id_g)]
  dat$v <- z_h[as.integer(dat$id_h)]
  b_g <- stats::rnorm(ng, sd = exp(log(0.45) + 0.30 * z_g))
  b_h <- stats::rnorm(nh, sd = exp(log(0.50) - 0.25 * z_h))
  dat$y <- stats::rbinom(
    nrow(dat), 1L,
    stats::plogis(-0.2 + 0.4 * dat$x + b_g[as.integer(dat$id_g)] +
                    b_h[as.integer(dat$id_h)])
  )
  formula <- bf(
    y ~ x + (1 | id_g) + (1 | id_h),
    sd(id_g) ~ w,
    sd(id_h) ~ v
  )
  native <- drmTMB(
    formula, family = stats::binomial(), data = dat, engine = "tmb"
  )
  julia <- drmTMB(
    formula, family = stats::binomial(), data = dat, engine = "julia"
  )

  expect_true(is_converged(native))
  expect_true(is_converged(julia))
  expect_true(isTRUE(native$sdr$pdHess))
  for (target in c("sd(id_g)", "sd(id_h)")) {
    group <- sub("^sd\\(([^)]+)\\)$", "\\1", target)
    native_alpha <- coef(native, dpar = target)
    julia_alpha <- coef(julia, dpar = target)
    expect_named(julia_alpha, names(native_alpha))
    expect_true(all(is.finite(julia_alpha)))
    expect_equal(unname(julia_alpha), unname(native_alpha), tolerance = 0.02)
    expect_named(
      julia$sdpars[[target]],
      paste0(target, ":", levels(dat[[group]]))
    )

    native_sd <- predict(native, dpar = target)
    julia_sd <- predict(julia, dpar = target)
    expect_setequal(names(julia_sd), names(native_sd))
    expect_equal(
      unname(julia_sd[ names(native_sd) ]),
      unname(native_sd),
      tolerance = 0.03
    )
    native_table <- predict_parameters(
      native, dpar = target, include_newdata = FALSE
    )
    julia_table <- predict_parameters(
      julia, dpar = target, include_newdata = FALSE
    )
    expect_identical(julia_table$row_label, native_table$row_label)
    expect_equal(julia_table$estimate, native_table$estimate, tolerance = 0.03)
  }
  expect_lt(abs(as.numeric(logLik(native)) - as.numeric(logLik(julia))), 1e-3)

  # Julia fits must retain the same target identity through R serialization.
  # The non-Gaussian DRM.jl Laplace route integrates its random effects and
  # does not return conditional modes, so the public simulator is marginal.
  saved_fit <- tempfile(fileext = ".rds")
  on.exit(unlink(saved_fit), add = TRUE)
  saveRDS(julia, saved_fit)
  restored <- readRDS(saved_fit)
  expect_identical(coef(restored), coef(julia))
  for (target in c("sd(id_g)", "sd(id_h)")) {
    expect_identical(
      predict(restored, dpar = target),
      predict(julia, dpar = target)
    )
  }

  sim_seed <- 20261024L
  fixed_eta <- predict(
    restored, newdata = dat, dpar = "mu", type = "link"
  )
  set.seed(sim_seed)
  expected_eta <- unname(fixed_eta)
  for (target in c("sd(id_g)", "sd(id_h)")) {
    group <- sub("^sd\\(([^)]+)\\)$", "\\1", target)
    group_values <- as.character(dat[[group]])
    group_levels <- unique(group_values)
    sd_values <- predict(restored, dpar = target)
    group_sd <- unname(sd_values[group_levels])
    latent <- stats::rnorm(length(group_levels), sd = group_sd)
    expected_eta <- expected_eta + latent[match(group_values, group_levels)]
  }
  expected <- stats::rbinom(
    nrow(dat), size = 1L, prob = stats::plogis(expected_eta)
  )
  simulated <- simulate(restored, nsim = 1L, seed = sim_seed)
  expect_identical(as.integer(simulated$sim_1), expected)
  expect_identical(
    simulate(julia, nsim = 1L, seed = sim_seed), simulated
  )
})
