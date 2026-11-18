poisson_animal_slope_sd_parity_fixture <- function(
  seed = 20261022L,
  groups = 80L,
  repeats = 24L
) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(groups))
  kernel_order <- sample(seq_len(groups))
  A <- outer(seq_len(groups), seq_len(groups), function(i, j) {
    0.25^abs(i - j)
  })
  A <- A[kernel_order, kernel_order, drop = FALSE]
  dimnames(A) <- list(id_levels[kernel_order], id_levels[kernel_order])
  z_group <- rep(c(-1, 1), each = groups / 2L)
  alpha <- c(`(Intercept)` = log(0.65), z = 0.5)
  slope <- drop(t(chol(A)) %*% stats::rnorm(groups)) *
    exp(alpha[[1L]] + alpha[["z"]] * z_group[kernel_order])
  names(slope) <- id_levels[kernel_order]
  id_index <- rep(seq_len(groups), each = repeats)
  x <- rep(seq(-1, 1, length.out = repeats), groups)
  id <- factor(
    id_levels[kernel_order[id_index]],
    levels = id_levels[kernel_order]
  )
  z <- z_group[kernel_order[id_index]]
  eta <- 0.2 + 0.3 * x + x * slope[as.character(id)]
  y <- stats::rpois(length(id), exp(eta))
  list(
    data = data.frame(y, x, z, id),
    A = A,
    alpha = alpha
  )
}

test_that("the Poisson animal-slope SD bridge admits only its fitted route", {
  A <- diag(4L)
  dimnames(A) <- list(paste0("id", 1:4), paste0("id", 1:4))
  data <- data.frame(
    y = c(0, 1, 2, 0, 1, 1, 0, 2),
    x = rep(c(-1, 1), 4),
    z = rep(c(-1, -1, 1, 1), each = 2),
    id = factor(rep(paste0("id", 1:4), each = 2))
  )
  formula <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )

  expect_true(drm_julia_poisson_animal_sd_slope_route_admitted(formula))
  expect_identical(drm_julia_structured_family_tag("poisson", formula), "poisson")
  payload <- drm_julia_structured_payload(
    formula, "poisson", data, environment()
  )
  expect_identical(payload$formula[[2L]], "sd(id, animal) ~ z")
  expect_true("sd" %in% names(payload$coef_labels))

  wrong_group <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sd(other, level = "animal") ~ z
  )
  extra_iid <- bf(
    y ~ x + (1 | site) + animal(0 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  multiple_animal_coefficients <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  expect_false(drm_julia_poisson_animal_sd_slope_route_admitted(wrong_group))
  expect_false(drm_julia_poisson_animal_sd_slope_route_admitted(extra_iid))
  expect_false(drm_julia_poisson_animal_sd_slope_route_admitted(
    multiple_animal_coefficients
  ))
})

test_that("Poisson animal-slope SD regression agrees across engines", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  fx <- poisson_animal_slope_sd_parity_fixture()
  A <- fx$A
  formula <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  native <- drmTMB(
    formula,
    family = stats::poisson(),
    data = fx$data,
    engine = "tmb",
    control = drm_control(se = FALSE)
  )
  julia <- drmTMB(
    formula,
    family = stats::poisson(),
    data = fx$data,
    engine = "julia"
  )

  dpar <- "sd_animal(id)"
  expect_equal(native$opt$convergence, 0L)
  expect_equal(julia$opt$convergence, 0L)
  native_coef <- coef(native, dpar = dpar)
  julia_coef <- coef(julia, dpar = dpar)
  expect_named(julia_coef, names(native_coef))
  expect_true(all(is.finite(julia_coef)))
  expect_gt(unname(julia_coef[["z"]]), 0)
  expect_lt(abs(unname(julia_coef[["z"]]) - fx$alpha[["z"]]), 0.1)
  expect_equal(unname(julia_coef), unname(native_coef), tolerance = 1e-4)
  expect_equal(as.numeric(logLik(julia)), as.numeric(logLik(native)),
               tolerance = 1e-3)

  native_sd <- predict(native, dpar = dpar)
  julia_sd <- predict(julia, dpar = dpar)
  names(native_sd) <- sub("^sd_animal\\(id\\):", "", names(native_sd))
  names(julia_sd) <- sub("^sd_animal\\(id\\):", "", names(julia_sd))
  expect_setequal(names(julia_sd), names(native_sd))
  expect_equal(unname(julia_sd[names(native_sd)]), unname(native_sd),
               tolerance = 1e-4)
})
