julia_binomial_relmat_sd_parity_fixture <- function(seed = 20261021L,
                                                     groups = 80L,
                                                     repeats = 20L) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(groups))
  # Deliberately permute labelled K relative to first-seen data groups. The
  # irregular exponential kernel and varying marginal scales make the matrix
  # non-invariant to reversal and give it a non-unit diagonal, so the seeded
  # simulation oracle can detect ignored or misaligned covariance structure.
  kernel_order <- rev(seq_len(groups))
  coordinate <- (seq_len(groups) / groups)^1.7
  marginal_scale <- seq(0.95, 1.05, length.out = groups)
  ordered_coordinate <- coordinate[kernel_order]
  ordered_scale <- marginal_scale[kernel_order]
  K <- outer(ordered_scale, ordered_scale) *
    exp(-abs(outer(ordered_coordinate, ordered_coordinate, `-`)) / 0.22)
  dimnames(K) <- list(id_levels[kernel_order], id_levels[kernel_order])
  z_group <- sample(rep(c(-1, 1), each = groups / 2L))
  alpha <- c(`(Intercept)` = log(0.65), z = 0.4)
  sd_kernel <- exp(alpha[[1L]] + alpha[["z"]] * z_group[kernel_order])
  effect_kernel <- drop(t(chol(K)) %*% stats::rnorm(groups)) * sd_kernel
  names(effect_kernel) <- id_levels[kernel_order]
  effect <- effect_kernel[id_levels]

  id <- rep(id_levels, each = repeats)
  x <- rep(seq(-1, 1, length.out = repeats), groups)
  z <- rep(z_group, each = repeats)
  eta <- -0.2 + 0.45 * x + effect[id]
  y <- stats::rbinom(length(id), size = 1L, prob = stats::plogis(eta))
  list(
    data = data.frame(id = factor(id, levels = id_levels), x, z, y),
    K = K,
    alpha = alpha,
    latent_sd = stats::setNames(
      exp(alpha[[1L]] + alpha[["z"]] * z_group), id_levels
    )
  )
}

test_that("the Julia Binomial relmat SD bridge preserves its selected target", {
  K <- diag(4L)
  dimnames(K) <- list(paste0("id", 1:4), paste0("id", 1:4))
  data <- data.frame(
    id = factor(rep(paste0("id", 1:4), each = 2)),
    z = rep(c(-1, 1), each = 4), x = rep(c(-1, 1), 4),
    y = c(0, 1, 0, 1, 1, 1, 0, 0)
  )
  formula <- bf(
    y ~ x + relmat(1 | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  target <- parse_sd_lhs(formula$entries[[2L]]$lhs)

  expect_true(drm_julia_binomial_relmat_sd_route_admitted(formula))
  expect_identical(drm_julia_structured_family_tag("binomial", formula), "binomial")
  expect_identical(drm_julia_formula_spec(formula)[[2L]], "sd(id, relmat) ~ z")
  expect_identical(drm_julia_formula_lhs(formula$entries[[2L]]), "sd(id, relmat)")
  expect_identical(drm_julia_sd_target_block(target), "sd")
  payload <- drm_julia_structured_payload(
    formula, "binomial", data, environment()
  )
  expect_identical(payload$formula[[2L]], "sd(id, relmat) ~ z")
  expect_true("sd" %in% names(payload$coef_labels))

  coefficients <- list(
    mu = c(`(Intercept)` = -0.2, x = 0.45),
    sd = c(`(Intercept)` = log(0.5), z = 0.35)
  )
  fit <- list(
    formula = formula, data = data, coefficients = coefficients,
    sd_regression_offsets = numeric()
  )
  expected <- exp(log(0.5) + 0.35 * c(-1, -1, 1, 1))
  predicted <- drm_julia_predict_sd(fit, target$dpar)
  expect_equal(unname(predicted), expected, tolerance = 1e-12)
  expect_equal(
    unname(drm_julia_sdpars(coefficients, formula, data)[[target$dpar]]),
    expected, tolerance = 1e-12
  )
  expect_identical(drm_julia_sd_fit_block(fit, target), "sd")
  expect_identical(drm_julia_lss_dpar_aliases(fit)[[target$dpar]], "sd")

  wrong_group <- bf(
    y ~ x + relmat(1 | id, K = K),
    sd(other, level = "relmat") ~ z
  )
  extra_iid <- bf(
    y ~ x + (1 | site) + relmat(1 | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  expect_false(drm_julia_binomial_relmat_sd_route_admitted(wrong_group))
  expect_false(drm_julia_binomial_relmat_sd_route_admitted(extra_iid))
  expect_error(
    drm_julia_structured_family_tag("binomial"),
    "general-covariance structured terms"
  )
})

test_that("Julia Binomial relmat SD matches native TMB on the same data", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")

  fx <- julia_binomial_relmat_sd_parity_fixture()
  K <- fx$K
  formula <- bf(
    y ~ x + relmat(1 | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  native <- drmTMB(
    formula, family = stats::binomial(), data = fx$data, engine = "tmb"
  )
  julia <- drmTMB(
    formula, family = stats::binomial(), data = fx$data, engine = "julia"
  )

  # This is a point-parity fixture. TMB's stricter is_converged() also checks
  # whether every derived SE is non-pathological; keep that inference gate
  # separate from the optimizer and Hessian checks below.
  expect_equal(native$opt$convergence, 0L)
  expect_true(isTRUE(native$sdr$pdHess))
  expect_equal(julia$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(julia)), as.numeric(logLik(native)),
               tolerance = 0.1)

  dpar <- "sd_relmat(id)"
  native_coef <- coef(native, dpar = dpar)
  julia_coef <- coef(julia, dpar = dpar)
  expect_named(julia_coef, names(native_coef))
  expect_equal(unname(julia_coef), unname(native_coef), tolerance = 0.1)
  expect_equal(unname(julia_coef), unname(fx$alpha), tolerance = 0.45)

  native_sd <- predict(native, dpar = dpar)
  julia_sd <- predict(julia, dpar = dpar)
  names(native_sd) <- sub("^sd_relmat\\(id\\):", "", names(native_sd))
  names(julia_sd) <- sub("^sd_relmat\\(id\\):", "", names(julia_sd))
  expect_setequal(names(julia_sd), names(native_sd))
  expect_equal(unname(julia_sd[names(native_sd)]), unname(native_sd),
               tolerance = 0.1)
  expect_equal(unname(julia_sd[ names(fx$latent_sd) ]),
               unname(fx$latent_sd), tolerance = 0.3)
  expect_true(all(is.finite(predict_parameters(
    julia, dpar = dpar, include_newdata = FALSE
  )$estimate)))

  fit_path <- tempfile(fileext = ".rds")
  on.exit(unlink(fit_path), add = TRUE)
  saveRDS(julia, fit_path)
  julia_reloaded <- readRDS(fit_path)
  expect_equal(coef(julia_reloaded, dpar = dpar), julia_coef)
  reloaded_sd <- predict(julia_reloaded, dpar = dpar)
  names(reloaded_sd) <- sub("^sd_relmat\\(id\\):", "", names(reloaded_sd))
  expect_equal(reloaded_sd, julia_sd)
  expect_equal(
    predict_parameters(julia_reloaded, dpar = dpar,
                       include_newdata = FALSE)$estimate,
    predict_parameters(julia, dpar = dpar,
                       include_newdata = FALSE)$estimate
  )

  simulation_seed <- 20261029L
  draws <- simulate(julia, nsim = 1L, seed = simulation_seed)
  expect_equal(nrow(draws), nrow(fx$data))
  expect_named(draws, "sim_1")
  expect_true(all(draws$sim_1 %in% c(0L, 1L)))
  expect_false(isTRUE(all.equal(diag(fx$K), rep(1, nrow(fx$K)))))
  expect_false(isTRUE(all.equal(
    unname(fx$K),
    unname(fx$K[rev(seq_len(nrow(fx$K))), rev(seq_len(nrow(fx$K))), drop = FALSE])
  )))

  # Independently reconstruct the first marginal draw. This checks covariance
  # ordering and scale, group-to-row mapping, and the fixed-effect predictor.
  groups <- unique(as.character(julia$data$id))
  covariance <- fx$K[groups, groups, drop = FALSE]
  set.seed(simulation_seed)
  latent_standard <- drop(t(chol(covariance)) %*% stats::rnorm(length(groups)))
  group_sd <- julia_sd[groups]
  latent <- group_sd * latent_standard
  eta <- predict(julia, newdata = julia$data, dpar = "mu", type = "link")
  expected <- stats::rbinom(
    nrow(julia$data), size = julia$model$trials,
    prob = stats::plogis(eta + latent[match(as.character(julia$data$id), groups)])
  )
  expect_identical(draws$sim_1, expected)

  repeated_draws <- simulate(julia, nsim = 1L, seed = simulation_seed)
  expect_identical(draws, repeated_draws)
})
