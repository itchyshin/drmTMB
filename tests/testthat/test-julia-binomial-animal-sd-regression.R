binomial_animal_slope_sd_bridge_data <- function(
  groups = 64L,
  repeats = 32L,
  seed = 20261022L
) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(groups))
  kernel_order <- sample(seq_len(groups))
  A <- outer(seq_len(groups), seq_len(groups), function(i, j) 0.35^abs(i - j))
  dimnames(A) <- list(id_levels[kernel_order], id_levels[kernel_order])
  z_group <- rep(c(-1, 1), length.out = groups)
  alpha <- c(`(Intercept)` = -0.45, z = 0.65)
  latent_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  latent <- as.vector(t(chol(A)) %*% stats::rnorm(groups)) * latent_sd
  names(latent) <- id_levels[kernel_order]
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_levels[kernel_order[id_index]], levels = id_levels[kernel_order])
  x <- rep(seq(-1.2, 1.2, length.out = repeats), groups)
  z <- z_group[id_index]
  eta <- -0.1 + 0.3 * x + x * latent[as.character(id)]
  y <- stats::rbinom(length(id), size = 1L, prob = stats::plogis(eta))
  list(
    data = data.frame(y, x, z, id),
    A = A,
    alpha = alpha,
    groups = groups
  )
}

binomial_animal_intercept_ainv_bridge_data <- function(
  groups = 64L,
  repeats = 30L,
  seed = 20261023L
) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(groups))
  order <- sample(seq_len(groups))
  correlation <- outer(seq_len(groups), seq_len(groups),
                        function(i, j) 0.35^abs(i - j))
  marginal_scale <- seq(0.8, 1.25, length.out = groups)
  A <- tcrossprod(marginal_scale) * correlation
  dimnames(A) <- list(id_levels[order], id_levels[order])
  z_group <- seq(-1, 1, length.out = groups)[order]
  alpha <- c(`(Intercept)` = -0.45, z = 0.55)
  latent <- as.vector(t(chol(A)) %*% stats::rnorm(groups)) *
    exp(alpha[[1L]] + alpha[[2L]] * z_group)
  names(latent) <- id_levels[order]
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_levels[order[id_index]], levels = id_levels[order])
  z <- z_group[id_index]
  eta <- -0.25 + latent[as.character(id)]
  y <- stats::rbinom(length(id), size = 1L, prob = stats::plogis(eta))
  list(data = data.frame(y, z, id), A = A, alpha = alpha, groups = groups)
}

test_that("the Julia animal-slope SD bridge gate stays exact", {
  A <- matrix(
    c(1, 0.2, 0.2, 1), nrow = 2L,
    dimnames = list(paste0("id", 1:2), paste0("id", 1:2))
  )
  data <- data.frame(
    y = c(0, 1, 0, 1), x = c(-1, 1, -1, 1), z = rep(c(-1, 1), 2),
    id = factor(rep(paste0("id", 1:2), each = 2))
  )
  formula <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )

  expect_true(drm_julia_binomial_animal_sd_slope_route_admitted(formula))
  expect_identical(drm_julia_structured_family_tag("binomial", formula), "binomial")
  spec <- drm_julia_formula_spec(formula)
  expect_identical(names(spec)[[2L]], "sd(id, animal)")
  expect_identical(spec[[2L]], "sd(id, animal) ~ z")
  payload <- drm_julia_structured_payload(formula, "binomial", data, environment())
  expect_identical(payload$formula[[2L]], "sd(id, animal) ~ z")
  expect_equal(unname(payload$matrix), unname(A), tolerance = 0)
  expect_identical(names(payload$structured_sd_scales), "animal(0 + x | id)")
  expect_identical(unname(payload$structured_sd_scales), 1)
  labels <- drm_julia_bridge_payload_coef_labels(
    formula, data, environment(), family_type = "binomial"
  )
  expect_true("sd" %in% names(labels))
  expect_false("resd" %in% names(labels))

  wrong_group <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sd(other, level = "animal") ~ z
  )
  extra_iid <- bf(
    y ~ x + (1 | site) + animal(0 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  multiple_animal_coefs <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  expect_false(drm_julia_binomial_animal_sd_slope_route_admitted(wrong_group))
  expect_false(drm_julia_binomial_animal_sd_slope_route_admitted(extra_iid))
  expect_false(drm_julia_binomial_animal_sd_slope_route_admitted(multiple_animal_coefs))
  expect_error(
    drm_julia_structured_family_tag("student", formula),
    "structured combinations"
  )
})

test_that("Julia admits Binomial animal-intercept SD regression with Ainv", {
  id <- factor(rep(paste0("id", 1:4), each = 2L))
  data <- data.frame(
    y = c(0L, 1L, 0L, 0L, 1L, 1L, 0L, 1L),
    z = rep(c(-1, 1), 4L),
    id = id
  )
  A <- outer(seq_len(4L), seq_len(4L), function(i, j) 0.4^abs(i - j))
  dimnames(A) <- list(paste0("id", 1:4), paste0("id", 1:4))
  Ainv <- solve(A)
  Ainv <- solve(A)
  formula <- bf(
    y ~ animal(1 | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )

  expect_true(drm_julia_binomial_animal_sd_intercept_route_admitted(formula))
  expect_identical(drm_julia_structured_family_tag("binomial", formula), "binomial")
  payload <- drm_julia_structured_payload(
    formula, "binomial", data, environment()
  )
  expect_identical(payload$kwarg, "Ainv")
  expect_equal(unname(payload$matrix), unname(Ainv), tolerance = 0)
  expect_identical(names(payload$structured_sd_scales), "animal(1 | id)")
  expect_error(
    drm_julia_structured_family_tag(
      "binomial", bf(y ~ animal(1 | id, Ainv = Ainv))
    ),
    "general-covariance structured terms"
  )
})

test_that("Julia admits non-logit Binomial animal and relmat SD routes", {
  A <- outer(seq_len(4L), seq_len(4L), function(i, j) 0.4^abs(i - j))
  dimnames(A) <- list(paste0("id", 1:4), paste0("id", 1:4))
  animal_intercept_A <- bf(
    y ~ animal(1 | id, A = A),
    sd(id, level = "animal") ~ z
  )
  animal_intercept_Ainv <- bf(
    y ~ animal(1 | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )
  animal_slope <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  relmat_intercept <- bf(
    y ~ relmat(1 | id, K = A),
    sd(id, level = "relmat") ~ z
  )
  formulas <- list(
    animal_intercept_A,
    animal_intercept_Ainv,
    animal_slope,
    relmat_intercept
  )

  expect_true(drm_julia_binomial_animal_sd_intercept_route_admitted(
    animal_intercept_A
  ))
  expect_true(drm_julia_binomial_animal_sd_intercept_route_admitted(
    animal_intercept_Ainv
  ))
  expect_true(drm_julia_binomial_animal_sd_slope_route_admitted(animal_slope))
  expect_true(drm_julia_binomial_relmat_sd_route_admitted(relmat_intercept))
  for (link in c("probit", "cloglog")) {
    for (formula in formulas) {
      expect_no_error(drm_julia_refuse_binomial_nonlogit_sd(
        formula, stats::binomial(link = link)
      ))
    }
  }
})

test_that("Binomial animal-intercept SD with Ainv agrees across engines", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  sim <- binomial_animal_intercept_ainv_bridge_data()
  A <- sim$A
  Ainv <- solve(A)
  formula <- bf(
    y ~ animal(1 | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )
  fit_tmb <- drmTMB(
    formula, family = stats::binomial(), data = sim$data, engine = "tmb"
  )
  fit_julia <- drmTMB(
    formula, family = stats::binomial(), data = sim$data, engine = "julia"
  )
  formula_A <- bf(
    y ~ animal(1 | id, A = A),
    sd(id, level = "animal") ~ z
  )
  fit_tmb_A <- drmTMB(
    formula_A, family = stats::binomial(), data = sim$data, engine = "tmb"
  )
  fit_julia_A <- drmTMB(
    formula_A, family = stats::binomial(), data = sim$data, engine = "julia"
  )

  tmb_sd <- coef(fit_tmb, dpar = "sd_animal(id)")
  julia_sd <- coef(fit_julia, dpar = "sd_animal(id)")
  tmb_sd_A <- coef(fit_tmb_A, dpar = "sd_animal(id)")
  julia_sd_A <- coef(fit_julia_A, dpar = "sd_animal(id)")
  expect_true(all(is.finite(tmb_sd)))
  expect_true(all(is.finite(julia_sd)))
  expect_true(all(is.finite(tmb_sd_A)))
  expect_true(all(is.finite(julia_sd_A)))
  expect_named(julia_sd, names(tmb_sd))
  expect_named(julia_sd_A, names(tmb_sd_A))
  expect_lt(abs(unname(tmb_sd[["z"]] - sim$alpha[["z"]])), 0.55)
  expect_lt(abs(unname(julia_sd[["z"]] - sim$alpha[["z"]])), 0.55)
  expect_lt(abs(unname(julia_sd[["z"]] - tmb_sd[["z"]])), 0.35)
  expect_lt(abs(unname(tmb_sd_A[["z"]] - sim$alpha[["z"]])), 0.55)
  expect_lt(abs(unname(julia_sd_A[["z"]] - sim$alpha[["z"]])), 0.55)
  expect_lt(abs(unname(julia_sd_A[["z"]] - tmb_sd_A[["z"]])), 0.35)
  expect_equal(unname(tmb_sd_A), unname(tmb_sd), tolerance = 0.02)
  expect_equal(unname(julia_sd_A), unname(julia_sd), tolerance = 0.02)
  expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
               tolerance = 0.02)
  expect_equal(as.numeric(logLik(fit_julia_A)), as.numeric(logLik(fit_tmb_A)),
               tolerance = 0.02)
  expect_equal(as.numeric(logLik(fit_tmb_A)), as.numeric(logLik(fit_tmb)),
               tolerance = 0.02)
  expect_equal(as.numeric(logLik(fit_julia_A)), as.numeric(logLik(fit_julia)),
               tolerance = 0.02)
  expect_length(fit_julia$sdpars[["sd_animal(id)"]], sim$groups)
  expect_equal(
    unname(fit_julia_A$sdpars[["sd_animal(id)"]]),
    unname(fit_julia$sdpars[["sd_animal(id)"]]),
    tolerance = 0.02
  )
  expect_equal(
    unname(predict(fit_julia, dpar = "sd_animal(id)")),
    unname(fit_julia$sdpars[["sd_animal(id)"]]),
    tolerance = 1e-10
  )
})

test_that("Julia animal SD prediction uses its fitted sd coefficient block", {
  sim <- binomial_animal_slope_sd_bridge_data(groups = 8L, repeats = 2L)
  A <- sim$A
  formula <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  coefficients <- list(
    mu = c(`(Intercept)` = -0.1, x = 0.3),
    sd = c(`(Intercept)` = -0.45, z = 0.65)
  )
  fit <- list(
    formula = formula, data = sim$data, coefficients = coefficients,
    sd_regression_offsets = numeric()
  )

  predicted <- drm_julia_predict_sd(fit, "sd_animal(id)")
  expected <- exp(-0.45 + 0.65 * sim$data$z[!duplicated(sim$data$id)])
  expect_length(predicted, sim$groups)
  expect_equal(unname(predicted), unname(expected), tolerance = 1e-12)
  expect_equal(
    unname(drm_julia_sdpars(coefficients, formula, sim$data)[["sd_animal(id)"]]),
    unname(expected), tolerance = 1e-12
  )
})

test_that("Binomial animal-slope SD regression passes through the Julia bridge", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  sim <- binomial_animal_slope_sd_bridge_data()
  A <- sim$A
  formula <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  fit_tmb <- drmTMB(
    formula, family = stats::binomial(), data = sim$data, engine = "tmb"
  )
  fit_julia <- drmTMB(
    formula, family = stats::binomial(), data = sim$data, engine = "julia"
  )

  tmb_sd <- coef(fit_tmb, dpar = "sd_animal(id)")
  julia_sd <- coef(fit_julia, dpar = "sd_animal(id)")
  expect_true(all(is.finite(tmb_sd)))
  expect_true(all(is.finite(julia_sd)))
  expect_named(julia_sd, names(tmb_sd))
  expect_lt(abs(unname(julia_sd[["z"]] - sim$alpha[["z"]])), 0.55)
  expect_lt(abs(unname(tmb_sd[["z"]] - sim$alpha[["z"]])), 0.55)
  expect_lt(abs(unname(julia_sd[["z"]] - tmb_sd[["z"]])), 0.70)
  expect_length(fit_julia$sdpars[["sd_animal(id)"]], sim$groups)
  expect_equal(
    unname(predict(fit_julia, dpar = "sd_animal(id)")),
    unname(fit_julia$sdpars[["sd_animal(id)"]]),
    tolerance = 1e-10
  )

  draws <- simulate(fit_julia, nsim = 1L, seed = 20261029L)
  expect_equal(nrow(draws), nrow(sim$data))
  expect_named(draws, "sim_1")
  expect_true(all(draws$sim_1 %in% c(0L, 1L)))
  expected_draw <- withr::with_seed(20261029L, {
    groups <- unique(as.character(sim$data$id))
    group_index <- match(as.character(sim$data$id), groups)
    latent <- as.vector(
      t(chol(fit_julia$bridge_payload$matrix)) %*% stats::rnorm(length(groups))
    )
    group_sd <- as.numeric(predict(fit_julia, dpar = "sd_animal(id)"))
    eta <- as.numeric(predict(
      fit_julia, newdata = sim$data, dpar = "mu", type = "link"
    )) + sim$data$x * group_sd[group_index] * latent[group_index]
    stats::rbinom(nrow(sim$data), size = fit_julia$model$trials,
                  prob = stats::plogis(eta))
  })
  expect_identical(draws$sim_1, as.integer(expected_draw))
})
