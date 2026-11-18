binomial_animal_q2_ainv_fixture <- function(groups = 80L, repeats = 24L,
                                             seed = 202610295L) {
  set.seed(seed)
  ids <- paste0("id", seq_len(groups))
  group_levels <- ids[sample(seq_len(groups))]
  A <- outer(seq_len(groups), seq_len(groups),
             function(i, j) 0.3^abs(i - j))
  dimnames(A) <- list(group_levels, group_levels)
  group_index <- rep(seq_len(groups), each = repeats)
  id <- factor(group_levels[group_index], levels = group_levels)
  z0_group <- sample(rep(c(-1, 1), length.out = groups))
  z1_group <- sample(rep(c(-1, 1), length.out = groups))
  z0 <- z0_group[group_index]
  z1 <- z1_group[group_index]
  x <- rep(seq(-1.2, 1.2, length.out = repeats), groups)

  alpha0 <- c(`(Intercept)` = -0.6, z0 = 0.5)
  alpha1 <- c(`(Intercept)` = -0.75, z1 = 0.6)
  rho <- 0.4
  tau0 <- exp(alpha0[[1L]] + alpha0[[2L]] * z0_group)
  tau1 <- exp(alpha1[[1L]] + alpha1[[2L]] * z1_group)
  latent0 <- drop(t(chol(A)) %*% stats::rnorm(groups))
  latent1_independent <- drop(t(chol(A)) %*% stats::rnorm(groups))
  latent1 <- rho * latent0 + sqrt(1 - rho^2) * latent1_independent
  eta <- -0.1 + 0.25 * x + tau0[group_index] * latent0[group_index] +
    x * tau1[group_index] * latent1[group_index]
  y <- stats::rbinom(length(id), 1L, stats::plogis(eta))
  list(data = data.frame(y, x, z0, z1, id), A = A,
       alpha0 = alpha0, alpha1 = alpha1, rho = rho)
}

test_that("Binomial animal q2 Ainv targets cross the Julia bridge", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  fx <- binomial_animal_q2_ainv_fixture()
  Ainv <- solve(fx$A)
  formula <- bf(
    y ~ x + animal(1 + x | id, Ainv = Ainv),
    sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0,
    sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1
  )
  payload <- drm_julia_structured_payload(
    formula, "binomial", fx$data, environment()
  )
  expect_identical(payload$kwarg, "Ainv")
  expect_equal(unname(payload$matrix), unname(Ainv), tolerance = 0)

  native <- drmTMB(
    formula, family = stats::binomial(), data = fx$data, engine = "tmb"
  )
  julia <- drmTMB(
    formula, family = stats::binomial(), data = fx$data, engine = "julia"
  )
  expect_equal(native$opt$convergence, 0L)
  expect_true(is_converged(julia))
  expect_equal(as.numeric(logLik(julia)), as.numeric(logLik(native)),
               tolerance = 0.15)

  dpars <- vapply(formula$entries[-1L], function(entry) {
    drm_julia_sd_public_dpar(parse_sd_lhs(entry$lhs))
  }, character(1L))
  for (dpar in dpars) {
    native_coef <- coef(native, dpar = dpar)
    julia_coef <- coef(julia, dpar = dpar)
    expect_named(julia_coef, names(native_coef))
    expect_equal(unname(julia_coef), unname(native_coef), tolerance = 0.4)
    expect_equal(unname(predict(julia, dpar = dpar)),
                 unname(predict(native, dpar = dpar)), tolerance = 0.15)
  }

  draws <- simulate(julia, nsim = 1L, seed = 202610296L)
  expect_equal(nrow(draws), nrow(fx$data))
  expect_true(all(draws[[1L]] %in% c(0L, 1L)))
  expected_draw <- withr::with_seed(202610296L, {
    groups <- unique(as.character(fx$data$id))
    group_index <- match(as.character(fx$data$id), groups)
    coefficient_correlation <- unname(julia$corpars$mu[[
      "cor((Intercept),x | id)"
    ]])
    R <- matrix(c(1, coefficient_correlation,
                  coefficient_correlation, 1), nrow = 2L)
    standard <- matrix(stats::rnorm(2L * length(groups)), nrow = 2L)
    random_effects <- t(chol(R)) %*% standard %*% chol(fx$A)
    sd_intercept <- as.numeric(predict(julia, dpar = dpars[[1L]]))
    sd_slope <- as.numeric(predict(julia, dpar = dpars[[2L]]))
    random_effects <- random_effects * rbind(sd_intercept, sd_slope)
    eta <- as.numeric(predict(
      julia, newdata = fx$data, dpar = "mu", type = "link"
    )) + random_effects[1L, group_index] +
      fx$data$x * random_effects[2L, group_index]
    stats::rbinom(nrow(fx$data), size = julia$model$trials,
                  prob = stats::plogis(eta))
  })
  expect_identical(draws$sim_1, as.integer(expected_draw))
})
