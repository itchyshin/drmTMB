poisson_animal_ainv_slope_sd_fixture <- function(
  seed = 20261024L,
  groups = 80L,
  repeats = 24L
) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(groups))
  matrix_order <- sample(seq_len(groups))
  data_order <- sample(seq_len(groups))
  A <- outer(seq_len(groups), seq_len(groups), function(i, j) {
    0.25^abs(i - j)
  })
  A <- A[matrix_order, matrix_order, drop = FALSE]
  dimnames(A) <- list(id_levels[matrix_order], id_levels[matrix_order])
  Ainv <- solve(A)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  alpha <- c(`(Intercept)` = log(0.65), z = 0.5)
  slope <- drop(t(chol(A)) %*% stats::rnorm(groups)) *
    exp(alpha[[1L]] + alpha[["z"]] * z_group[matrix_order])
  names(slope) <- id_levels[matrix_order]
  id_index <- rep(data_order, each = repeats)
  x <- rep(seq(-1, 1, length.out = repeats), groups)
  id <- factor(
    id_levels[id_index],
    levels = id_levels[data_order]
  )
  z <- z_group[id_index]
  eta <- 0.2 + 0.3 * x + x * slope[as.character(id)]
  y <- stats::rpois(length(id), exp(eta))
  list(data = data.frame(y, x, z, id), Ainv = Ainv, alpha = alpha)
}

test_that("Poisson animal-slope Ainv is aligned in the Julia bridge payload", {
  fixture <- poisson_animal_ainv_slope_sd_fixture(groups = 8L, repeats = 3L)
  Ainv <- fixture$Ainv
  formula <- bf(
    y ~ x + animal(0 + x | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )
  payload <- drm_julia_structured_payload(
    formula, "poisson", fixture$data, environment()
  )
  expected_order <- unique(as.character(fixture$data$id))
  matrix_index <- match(expected_order, rownames(Ainv))

  expect_identical(payload$kwarg, "Ainv")
  expect_equal(
    unname(payload$matrix),
    unname(Ainv[matrix_index, matrix_index, drop = FALSE])
  )
  expect_identical(payload$formula[["mu"]], "y ~ x + animal(0 + x | id)")
})

test_that("Poisson animal-slope Ainv SD regression agrees across engines", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  fixture <- poisson_animal_ainv_slope_sd_fixture()
  Ainv <- fixture$Ainv
  formula <- bf(
    y ~ x + animal(0 + x | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )
  native <- drmTMB(
    formula,
    family = stats::poisson(),
    data = fixture$data,
    engine = "tmb",
    control = drm_control(se = FALSE)
  )
  julia <- drmTMB(
    formula,
    family = stats::poisson(),
    data = fixture$data,
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
  expect_lt(abs(unname(julia_coef[["z"]]) - fixture$alpha[["z"]]), 0.1)
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
