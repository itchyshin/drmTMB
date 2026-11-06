test_that("native and Julia NB2 independent-slope SD fits agree on seeded data", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  sim <- nbinom2_sd_slope_fixture(
    groups = 48L,
    repeats = 20L,
    seed = 2026101824L
  )
  formula <- bf(y ~ x + (0 + x | id), sigma ~ 1,
                sd(id, coef = "x") ~ w)
  fit_tmb <- drmTMB(
    formula, family = nbinom2(), data = sim$data, engine = "tmb"
  )
  sd_dpar <- grep("^sd\\(", names(fit_tmb$coefficients), value = TRUE)
  expect_length(sd_dpar, 1L)
  fit_julia <- drmTMB(
    formula, family = nbinom2(), data = sim$data, engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_julia, dpar = sd_dpar), c("(Intercept)", "w"))
  expect_gt(coef(fit_julia, dpar = sd_dpar)[["w"]], 0)
  expect_equal(
    unname(coef(fit_julia, dpar = sd_dpar)),
    unname(coef(fit_tmb, dpar = sd_dpar)),
    tolerance = 0.4
  )
  expect_equal(length(fit_julia$sdpars[[sd_dpar]]), nlevels(sim$data$id))
  row_sd <- predict(fit_julia, newdata = sim$data, dpar = sd_dpar)
  expect_length(row_sd, nrow(sim$data))
  expect_equal(
    unname(row_sd),
    unname(fit_julia$sdpars[[sd_dpar]])[as.integer(sim$data$id)],
    tolerance = 1e-10
  )
  expect_setequal(names(fit_julia$bridge$dpars), c("mu", "sigma"))
})

nbinom2_animal_sd_bridge_fixture <- function(
  groups = 40L,
  repeats = 24L,
  seed = 20261022L
) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(groups))
  A <- outer(seq_len(groups), seq_len(groups), function(i, j) 0.35^abs(i - j))
  dimnames(A) <- list(id_levels, id_levels)
  z_group <- rep(c(-1, 1), length.out = groups)
  alpha <- c(`(Intercept)` = -0.65, z = 0.4)
  latent <- exp(alpha[[1L]] + alpha[[2L]] * z_group) *
    as.vector(t(chol(A)) %*% stats::rnorm(groups))
  x <- stats::rnorm(groups * repeats)
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_levels[id_index], levels = id_levels)
  z <- z_group[id_index]
  mu <- exp(0.35 + 0.25 * x + latent[id_index])
  sigma <- 0.42
  size <- 1 / sigma^2
  y <- stats::rnbinom(length(mu), size = size, mu = mu)
  list(data = data.frame(y, x, z, id), A = A, alpha = alpha)
}

test_that("NB2 animal-intercept SD bridge preserves the selected target", {
  sim <- nbinom2_animal_sd_bridge_fixture(groups = 8L, repeats = 2L)
  A <- sim$A
  formula <- bf(
    y ~ x + animal(1 | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal") ~ z
  )

  expect_identical(drm_julia_structured_family_tag("nbinom2", formula), "nbinom2")
  spec <- drm_julia_formula_spec(formula)
  expect_identical(spec[["sd(id, animal)"]], "sd(id, animal) ~ z")
  payload <- drm_julia_structured_payload(formula, "nbinom2", sim$data, environment())
  expect_identical(payload$kwarg, "A")
  expect_identical(payload$formula[["sd(id, animal)"]], "sd(id, animal) ~ z")
  expect_identical(payload$coef_labels$sd, c("(Intercept)", "z"))
  expect_equal(unname(payload$matrix), unname(A), tolerance = 0)
})

test_that("NB2 animal-intercept SD fitting runs through the Julia bridge", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  sim <- nbinom2_animal_sd_bridge_fixture()
  A <- sim$A
  formula <- bf(
    y ~ x + animal(1 | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal") ~ z
  )
  fit_tmb <- drmTMB(formula, family = nbinom2(), data = sim$data, engine = "tmb")
  fit_julia <- drmTMB(formula, family = nbinom2(), data = sim$data, engine = "julia")

  tmb_vcov_diagonal <- diag(vcov(fit_tmb))
  tmb_sd_variances <- tmb_vcov_diagonal[
    startsWith(names(tmb_vcov_diagonal), "sd_animal(id):")
  ]
  expect_length(tmb_sd_variances, length(sim$alpha))
  expect_true(all(is.finite(tmb_sd_variances)))

  expect_true(
    is_converged(fit_tmb),
    info = paste(
      "TMB optimizer convergence:", fit_tmb$opt$convergence,
      "Hessian positive definite:", fit_tmb$sdr$pdHess,
      "convergence status:", convergence_status(fit_tmb),
      "uncertainty degenerate:", drmTMB:::drm_inference_degenerate(fit_tmb),
      "fixed design rank deficient:", drmTMB:::drm_fixed_effect_rank_deficient(fit_tmb),
      "SEs pathological:", drmTMB:::drm_standard_errors_pathological(fit_tmb)
    )
  )
  expect_true(
    is_converged(fit_julia),
    info = paste(
      "Julia optimizer convergence:", fit_julia$opt$convergence,
      "reported converged:", fit_julia$diagnostics$converged
    )
  )
  for (fit in list(fit_tmb, fit_julia)) {
    sd_coef <- coef(fit, dpar = "sd_animal(id)")
    expect_named(sd_coef, c("(Intercept)", "z"))
    expect_gt(sd_coef[["z"]], 0)
    expect_lt(abs(sd_coef[["z"]] - sim$alpha[["z"]]), 0.65)
    expect_length(fit$sdpars[["sd_animal(id)"]], nlevels(sim$data$id))
  }
  julia_group_sd <- predict(fit_julia, dpar = "sd_animal(id)")
  expect_length(julia_group_sd, nlevels(sim$data$id))
  expect_true(all(is.finite(julia_group_sd)))

  sd_dpar <- "sd_animal(id)"
  expect_equal(
    unname(coef(fit_julia, dpar = sd_dpar)),
    unname(coef(fit_tmb, dpar = sd_dpar)),
    tolerance = 0.1
  )
  expect_equal(
    as.numeric(logLik(fit_julia)),
    as.numeric(logLik(fit_tmb)),
    tolerance = 0.1
  )

  group_newdata <- sim$data[!duplicated(sim$data$id), c("id", "z"), drop = FALSE]
  expected_groups <- levels(sim$data$id)
  tmb_prediction <- predict_parameters(
    fit_tmb, newdata = group_newdata, dpar = sd_dpar
  )
  julia_prediction <- predict_parameters(
    fit_julia, newdata = group_newdata, dpar = sd_dpar
  )
  tmb_order <- match(expected_groups, as.character(tmb_prediction$id))
  julia_order <- match(expected_groups, as.character(julia_prediction$id))
  expect_false(anyNA(tmb_order))
  expect_false(anyNA(julia_order))
  expect_equal(
    julia_prediction$estimate[julia_order],
    tmb_prediction$estimate[tmb_order],
    tolerance = 0.1
  )
})
