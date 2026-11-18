test_that("animal Ainv is aligned and preserved by the Julia structured payload", {
  matrix_levels <- c("animal_c", "animal_a", "animal_b")
  Ainv <- matrix(
    c(2.0, 0.2, 0.1,
      0.2, 1.8, 0.15,
      0.1, 0.15, 1.5),
    nrow = 3L,
    dimnames = list(matrix_levels, matrix_levels)
  )
  data <- data.frame(
    y = c(0, 1, 1, 0, 2, 1),
    z = rep(c(-1, 0, 1), each = 2L),
    id = factor(rep(c("animal_a", "animal_b", "animal_c"), each = 2L))
  )
  formula <- bf(
    y ~ animal(1 | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )

  payload <- drm_julia_structured_payload(
    formula, "poisson", data, environment()
  )
  expected_order <- unique(as.character(data$id))
  matrix_index <- match(expected_order, matrix_levels)

  expect_identical(payload$kwarg, "Ainv")
  expect_equal(
    unname(payload$matrix),
    unname(Ainv[matrix_index, matrix_index, drop = FALSE])
  )
  expect_identical(payload$formula[["mu"]], "y ~ animal(1 | id)")

  no_sd_formula <- bf(y ~ animal(1 | id, Ainv = Ainv))
  expect_error(
    drm_julia_structured_payload(
      no_sd_formula, "poisson", data, environment()
    ),
    "only for supported Poisson or Binomial animal SD regression routes"
  )
})

poisson_animal_ainv_sd_fixture <- function(
  groups = 36L,
  repeats = 18L,
  seed = 20261023L
) {
  set.seed(seed)
  id_levels <- paste0("animal_", seq_len(groups))
  R <- outer(seq_len(groups), seq_len(groups), function(i, j) 0.45^abs(i - j))
  Ainv_unordered <- solve(R)
  matrix_order <- sample(seq_len(groups))
  Ainv <- Ainv_unordered[matrix_order, matrix_order, drop = FALSE]
  dimnames(Ainv) <- list(id_levels[matrix_order], id_levels[matrix_order])

  z_group <- rep(c(-1, 1), each = groups / 2L)
  latent <- drop(t(chol(R)) %*% stats::rnorm(groups))
  alpha <- c(`(Intercept)` = -0.55, z = 0.38)
  group_effect <- exp(alpha[[1L]] + alpha[["z"]] * z_group) * latent
  id <- factor(rep(id_levels, each = repeats), levels = id_levels)
  eta <- 0.25 + group_effect[as.integer(id)]
  y <- stats::rpois(length(id), exp(eta))
  data <- data.frame(y, z = rep(z_group, each = repeats), id)
  list(data = data, Ainv = Ainv, alpha = alpha)
}

test_that("Poisson animal-intercept Ainv SD regression agrees across engines", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  fixture <- poisson_animal_ainv_sd_fixture()
  Ainv <- fixture$Ainv
  formula <- bf(
    y ~ animal(1 | id, Ainv = Ainv),
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
  expect_lt(abs(unname(julia_coef[["z"]]) - fixture$alpha[["z"]]), 0.55)
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
