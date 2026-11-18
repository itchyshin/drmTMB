binomial_animal_q2_bridge_fixture <- function(groups = 120L, repeats = 32L,
                                             seed = 20261028L,
                                             link = "logit") {
  set.seed(seed)
  ids <- paste0("id", seq_len(groups))
  order <- sample(seq_len(groups))
  group_levels <- ids[order]
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
  probability <- switch(
    link,
    logit = stats::plogis(eta),
    probit = stats::pnorm(eta),
    cloglog = -expm1(-exp(eta))
  )
  y <- stats::rbinom(length(id), 1L, probability)
  list(data = data.frame(y, x, z0, z1, id), A = A, link = link,
       alpha0 = alpha0, alpha1 = alpha1, rho = rho)
}

binomial_animal_q2_bridge_formula <- function(A) {
  bf(
    y ~ x + animal(1 + x | id, A = A),
    sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0,
    sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1
  )
}

test_that("Julia admits the exact Binomial animal q2 SD target pair", {
  fx <- binomial_animal_q2_bridge_fixture(groups = 8L, repeats = 6L)
  A <- fx$A
  env <- environment()
  formula <- binomial_animal_q2_bridge_formula(A)

  expect_true(drm_julia_binomial_animal_q2_sd_route_admitted(formula))
  expect_identical(
    drm_julia_structured_family_tag("binomial", formula), "binomial"
  )

  spec <- drm_julia_formula_spec(formula)
  expect_length(spec, 3L)
  expect_identical(
    spec[[2L]], "sd(id, animal, coef(intercept)) ~ z0"
  )
  expect_identical(spec[[3L]], "sd(id, animal, coef(x)) ~ z1")

  payload <- drm_julia_structured_payload(
    formula, "binomial", fx$data, env
  )
  expect_identical(payload$kwarg, "A")
  expect_equal(unname(payload$matrix), unname(fx$A), tolerance = 0)
  expect_identical(payload$formula[[2L]], "sd(id, animal, coef(intercept)) ~ z0")
  expect_identical(payload$formula[[3L]], "sd(id, animal, coef(x)) ~ z1")
  labels <- drm_julia_bridge_payload_coef_labels(
    formula, fx$data, env, family_type = "binomial"
  )
  expect_identical(labels[["recov"]], "id:atanh_rho")
  structured_parameters <- drm_julia_structured_parameters(
    stats::setNames(0.2, "recov_id:atanh_rho"), formula
  )
  expect_named(
    structured_parameters$corpars$mu,
    "cor((Intercept),x | id)"
  )
  expect_equal(
    unname(structured_parameters$corpars$mu),
    0.99999999 * tanh(0.2)
  )

  general_slope <- bf(
    y ~ growth + animal(1 + growth | id, A = A),
    sd(id, level = "animal", coef = "(Intercept)") ~ z0,
    sd(id, level = "animal", coef = "growth") ~ z1
  )
  expect_true(drm_julia_binomial_animal_q2_sd_route_admitted(general_slope))

  missing_target <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sd(id, level = "animal", coef = "x") ~ z1
  )
  wrong_group <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sd(other, level = "animal", coef = "(Intercept)") ~ z0,
    sd(id, level = "animal", coef = "x") ~ z1
  )
  extra_iid <- bf(
    y ~ x + (1 | site) + animal(1 + x | id, A = A),
    sd(id, level = "animal", coef = "(Intercept)") ~ z0,
    sd(id, level = "animal", coef = "x") ~ z1
  )
  expect_false(drm_julia_binomial_animal_q2_sd_route_admitted(missing_target))
  expect_false(drm_julia_binomial_animal_q2_sd_route_admitted(wrong_group))
  expect_false(drm_julia_binomial_animal_q2_sd_route_admitted(extra_iid))
  for (link in c("probit", "cloglog")) {
    expect_no_error(
      drm_julia_refuse_binomial_nonlogit_sd(
        formula, stats::binomial(link = link)
      )
    )
    expect_identical(
      drm_julia_structured_family_tag("binomial", formula, link = link),
      paste0("binomial_", link)
    )
  }
})

test_that("Binomial animal q2 SD targets cross the Julia bridge", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  fx <- binomial_animal_q2_bridge_fixture()
  A <- fx$A
  formula <- binomial_animal_q2_bridge_formula(A)
  native <- drmTMB(
    formula, family = stats::binomial(), data = fx$data, engine = "tmb"
  )
  julia <- drmTMB(
    formula, family = stats::binomial(), data = fx$data, engine = "julia"
  )

  expect_equal(native$opt$convergence, 0L)
  expect_true(isTRUE(native$sdr$pdHess))
  expect_equal(julia$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(julia)), as.numeric(logLik(native)),
               tolerance = 0.1)

  targets <- lapply(formula$entries[-1L], function(entry) {
    parse_sd_lhs(entry$lhs)
  })
  dpars <- vapply(targets, drm_julia_sd_public_dpar, character(1L))
  expect_length(unique(dpars), 2L)
  for (i in seq_along(targets)) {
    native_coef <- coef(native, dpar = dpars[[i]])
    julia_coef <- coef(julia, dpar = dpars[[i]])
    truth <- if (targets[[i]]$target_coef %in% c("intercept", "(Intercept)")) {
      fx$alpha0
    } else {
      fx$alpha1
    }
    expect_named(julia_coef, names(native_coef))
    expect_true(all(is.finite(julia_coef)))
    expect_equal(unname(julia_coef), unname(native_coef), tolerance = 0.4)
    expect_lt(max(abs(unname(julia_coef) - truth[names(julia_coef)])), 0.75)
    expect_lt(max(abs(unname(native_coef) - truth[names(native_coef)])), 0.75)

    native_sd <- predict(native, dpar = dpars[[i]])
    julia_sd <- predict(julia, dpar = dpars[[i]])
    expect_named(julia_sd, names(native_sd))
    expect_equal(unname(julia_sd), unname(native_sd), tolerance = 0.1)
    parameter_predictions <- predict_parameters(
      julia, dpar = dpars[[i]], include_newdata = FALSE
    )
    expect_identical(unique(parameter_predictions$dpar), dpars[[i]])
    expect_true(all(is.finite(parameter_predictions$estimate)))
  }

  fit_path <- tempfile(fileext = ".rds")
  on.exit(unlink(fit_path), add = TRUE)
  saveRDS(julia, fit_path)
  reloaded <- readRDS(fit_path)
  for (dpar in dpars) {
    expect_equal(coef(reloaded, dpar = dpar), coef(julia, dpar = dpar))
    expect_equal(predict(reloaded, dpar = dpar), predict(julia, dpar = dpar))
  }

  draws <- simulate(julia, nsim = 1L, seed = 20261029L)
  expect_equal(nrow(draws), nrow(fx$data))
  expect_true(all(draws[[1L]] %in% c(0L, 1L)))
  expected_draw <- withr::with_seed(20261029L, {
    groups <- unique(as.character(fx$data$id))
    group_index <- match(as.character(fx$data$id), groups)
    coefficient_correlation <- unname(julia$corpars$mu[[
      "cor((Intercept),x | id)"
    ]])
    R <- matrix(c(1, coefficient_correlation,
                  coefficient_correlation, 1), nrow = 2L)
    standard <- matrix(stats::rnorm(2L * length(groups)), nrow = 2L)
    random_effects <- t(chol(R)) %*% standard %*% chol(fx$A)
    sd_intercept <- as.numeric(predict(
      julia, dpar = dpars[[1L]]
    ))
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

test_that("probit and cloglog animal q2 SD targets cross the Julia bridge", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  for (link in c("probit", "cloglog")) {
    fx <- binomial_animal_q2_bridge_fixture(
      groups = 80L, repeats = 32L,
      seed = if (link == "probit") 202610291L else 202610292L,
      link = link
    )
    formula <- binomial_animal_q2_bridge_formula(fx$A)
    family <- stats::binomial(link = link)
    native <- drmTMB(
      formula, family = family, data = fx$data, engine = "tmb"
    )
    julia <- drmTMB(
      formula, family = family, data = fx$data, engine = "julia"
    )
    expect_equal(native$opt$convergence, 0L, info = link)
    expect_true(is_converged(julia), info = link)
    expect_equal(as.numeric(logLik(julia)), as.numeric(logLik(native)),
                 tolerance = 0.15, info = link)

    targets <- lapply(formula$entries[-1L], function(entry) {
      parse_sd_lhs(entry$lhs)
    })
    dpars <- vapply(targets, drm_julia_sd_public_dpar, character(1L))
    for (i in seq_along(dpars)) {
      native_coef <- coef(native, dpar = dpars[[i]])
      julia_coef <- coef(julia, dpar = dpars[[i]])
      truth <- if (targets[[i]]$target_coef %in% c("intercept", "(Intercept)")) {
        fx$alpha0
      } else {
        fx$alpha1
      }
      expect_named(julia_coef, names(native_coef), info = link)
      expect_true(all(is.finite(julia_coef)), info = link)
      expect_equal(unname(julia_coef), unname(native_coef),
                   tolerance = 0.5, info = link)
      expect_true(
        max(abs(unname(julia_coef) - truth[names(julia_coef)])) < 0.8,
        info = link
      )
      julia_sd <- predict(julia, dpar = dpars[[i]])
      native_sd <- predict(native, dpar = dpars[[i]])
      expect_named(julia_sd, names(native_sd), info = link)
      expect_equal(unname(julia_sd), unname(native_sd),
                   tolerance = 0.2, info = link)
    }
    draws <- simulate(julia, nsim = 1L, seed = 202610293L)
    expect_equal(nrow(draws), nrow(fx$data), info = link)
    expect_true(all(draws[[1L]] %in% c(0L, 1L)), info = link)
  }
})
