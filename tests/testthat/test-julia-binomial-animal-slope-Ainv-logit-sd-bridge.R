test_that("Julia Binomial animal-slope SD regression accepts Ainv with logit", {
  A <- outer(seq_len(4L), seq_len(4L), function(i, j) 0.4^abs(i - j))
  Ainv <- solve(A)
  formula <- bf(
    y ~ x + animal(0 + x | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )
  dat <- data.frame(
    y = c(0L, 1L, 0L, 1L), x = c(-1, 1, -1, 1), z = c(-1, -1, 1, 1),
    id = factor(c("a", "a", "b", "b"), levels = c("a", "b"))
  )

  expect_identical(
    drm_julia_structured_family_tag("binomial", formula, link = "logit"),
    "binomial"
  )
  payload <- drm_julia_structured_payload(
    formula, "binomial", dat, environment()
  )
  expect_identical(payload$kwarg, "Ainv")
  expect_equal(payload$matrix, Ainv)

  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  groups <- 80L
  repeats <- 32L
  set.seed(202610273L)
  id_levels <- paste0("animal_", seq_len(groups))
  A <- outer(seq_len(groups), seq_len(groups), function(i, j) 0.35^abs(i - j))
  dimnames(A) <- list(id_levels, id_levels)
  Ainv <- solve(A)
  z_group <- sample(rep(c(-1, 1), each = groups / 2L))
  alpha <- c(`(Intercept)` = -0.7, z = 0.4)
  slope_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  covariance <- tcrossprod(slope_sd) * A
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_levels[id_index], levels = id_levels)
  x <- stats::rnorm(groups * repeats)
  z <- z_group[id_index]
  set.seed(202610274L)
  latent_slope <- as.vector(t(chol(covariance)) %*% stats::rnorm(groups))
  eta <- -0.1 + 0.35 * x + x * latent_slope[id_index]
  probability <- stats::plogis(eta)
  data <- data.frame(
    y = stats::rbinom(length(id), 1L, probability), x = x, z = z, id = id
  )

  fit_formula <- bf(
    y ~ x + animal(0 + x | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )
  fit_tmb <- drmTMB(
    fit_formula, family = stats::binomial("logit"), data = data,
    engine = "tmb", control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    fit_formula, family = stats::binomial("logit"), data = data,
    engine = "julia"
  )

  target <- "sd_animal(id)"
  beta_tmb <- coef(fit_tmb, dpar = target)
  beta_julia <- coef(fit_julia, dpar = target)
  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(beta_julia, names(alpha))
  expect_true(all(is.finite(beta_tmb)))
  expect_true(all(is.finite(beta_julia)))
  expect_lt(abs(unname(beta_tmb[["z"]] - alpha[["z"]])), 0.5)
  expect_lt(abs(unname(beta_julia[["z"]] - alpha[["z"]])), 0.5)
  expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
               tolerance = 0.1)

  group_data <- data.frame(
    id = factor(id_levels, levels = id_levels), z = z_group
  )
  sd_tmb <- predict(fit_tmb, newdata = group_data, dpar = target)
  sd_julia <- predict(fit_julia, newdata = group_data, dpar = target)
  expect_equal(as.numeric(sd_julia),
               exp(unname(beta_julia[["(Intercept)"]] + beta_julia[["z"]] * z_group)),
               tolerance = 1e-8)
  expect_equal(as.numeric(sd_julia), as.numeric(sd_tmb), tolerance = 0.2)
})
