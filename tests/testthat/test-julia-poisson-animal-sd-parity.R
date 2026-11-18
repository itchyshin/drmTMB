poisson_animal_sd_parity_fixture <- function(
  groups = 36L,
  repeats = 18L,
  seed = 20261023L
) {
  set.seed(seed)
  id_levels <- paste0("animal_", seq_len(groups))
  covariance <- outer(
    seq_len(groups), seq_len(groups),
    function(i, j) 0.45^abs(i - j)
  )
  matrix_order <- sample(seq_len(groups))
  A <- covariance[matrix_order, matrix_order, drop = FALSE]
  dimnames(A) <- list(id_levels[matrix_order], id_levels[matrix_order])

  z_group <- rep(c(-1, 1), each = groups / 2L)
  latent <- drop(t(chol(covariance)) %*% stats::rnorm(groups))
  alpha <- c(`(Intercept)` = -0.55, z = 0.38)
  group_effect <- exp(alpha[[1L]] + alpha[["z"]] * z_group) * latent
  id <- factor(rep(id_levels, each = repeats), levels = id_levels)
  eta <- 0.25 + group_effect[as.integer(id)]
  y <- stats::rpois(length(id), exp(eta))

  list(
    data = data.frame(y = y, z = rep(z_group, each = repeats), id = id),
    A = A,
    alpha = alpha
  )
}

test_that("Poisson animal-intercept A SD regression agrees across engines", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  fixture <- poisson_animal_sd_parity_fixture()
  A <- fixture$A
  expect_equal(unname(diag(A)), rep(1, nrow(A)), tolerance = 1e-12)

  formula <- bf(
    y ~ animal(1 | id, A = A),
    sd(id, level = "animal") ~ z
  )
  native <- drmTMB(
    formula,
    family = stats::poisson(),
    data = fixture$data,
    engine = "tmb"
  )
  julia <- drmTMB(
    formula,
    family = stats::poisson(),
    data = fixture$data,
    engine = "julia"
  )

  expect_equal(native$opt$convergence, 0L)
  expect_true(isTRUE(native$sdr$pdHess))
  expect_equal(julia$opt$convergence, 0L)

  dpar <- "sd_animal(id)"
  native_coef <- coef(native, dpar = dpar)
  julia_coef <- coef(julia, dpar = dpar)
  expect_named(native_coef, c("(Intercept)", "z"))
  expect_named(julia_coef, names(native_coef))
  expect_true(all(is.finite(native_coef)))
  expect_true(all(is.finite(julia_coef)))
  expect_gt(unname(native_coef[["z"]]), 0)
  expect_gt(unname(julia_coef[["z"]]), 0)
  expect_lt(abs(unname(native_coef[["z"]]) - fixture$alpha[["z"]]), 0.55)
  expect_lt(abs(unname(julia_coef[["z"]]) - fixture$alpha[["z"]]), 0.55)
  expect_equal(unname(julia_coef), unname(native_coef), tolerance = 1e-4)
  expect_equal(
    as.numeric(logLik(julia)), as.numeric(logLik(native)),
    tolerance = 1e-3
  )

  native_sd <- predict(native, dpar = dpar)
  julia_sd <- predict(julia, dpar = dpar)
  names(native_sd) <- sub("^sd_animal\\(id\\):", "", names(native_sd))
  names(julia_sd) <- sub("^sd_animal\\(id\\):", "", names(julia_sd))
  expect_setequal(names(julia_sd), names(native_sd))
  expect_equal(
    unname(julia_sd[names(native_sd)]), unname(native_sd),
    tolerance = 1e-4
  )

  native_parameters <- predict_parameters(
    native, dpar = dpar, include_newdata = FALSE
  )
  julia_parameters <- predict_parameters(
    julia, dpar = dpar, include_newdata = FALSE
  )
  expect_setequal(unique(native_parameters$dpar), dpar)
  expect_setequal(unique(julia_parameters$dpar), dpar)
  native_by_group <- setNames(native_parameters$estimate, native_parameters$row_label)
  julia_by_group <- setNames(julia_parameters$estimate, julia_parameters$row_label)
  expect_setequal(names(julia_by_group), names(native_by_group))
  expect_equal(
    unname(julia_by_group[names(native_by_group)]),
    unname(native_by_group),
    tolerance = 1e-4
  )
})
