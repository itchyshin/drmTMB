# Whole-package covr lane w7 (27 Nov): ranks 18–20 after skipping 16–17
# already claimed on open 1127cov PRs (#1944 phylo-utils, #1933 family-dpq).

scalar_sd_fixture <- function(exprs = list(quote(1 | id)), dpar = "mu") {
  data <- data.frame(
    id = factor(rep(c("g1", "g2"), each = 2L)),
    x = 1:4
  )
  terms <- lapply(exprs, parse_random_mu_term, dpar = dpar)
  re <- build_random_mu_structure(terms, data)
  list(data = data, terms = terms, re = re)
}

sd_entry <- function(lhs, dpar = "mu") {
  list(lhs = lhs, dpar = dpar)
}

test_that("drm_scalar_sd_mu_targets() admits intercepts and guarded slopes", {
  intercept <- scalar_sd_fixture()
  out <- drm_scalar_sd_mu_targets(
    list(sd_entry(quote(sd(id)))),
    intercept$terms,
    intercept$re,
  family_label = "Test",
    allow_slopes = TRUE,
    allow_independent_same_group = TRUE
  )
  expect_length(out, 1L)
  expect_equal(out[[1L]]$identity$coef, "(Intercept)")

  slope <- scalar_sd_fixture(list(quote(0 + x | id)))
  out_slope <- drm_scalar_sd_mu_targets(
    list(sd_entry(quote(sd(id, coef = "x")))),
    slope$terms,
    slope$re,
    family_label = "Test",
    allow_slopes = TRUE
  )
  expect_equal(out_slope[[1L]]$identity$coef, "x")

  expect_error(
    drm_scalar_sd_mu_targets(
      list(sd_entry(quote(sd(id)))),
      slope$terms,
      slope$re,
      family_label = "Test",
      allow_slopes = FALSE
    ),
    "does not support"
  )
})

test_that("drm_scalar_sd_mu_targets() rejects duplicate formulas and empty inventories", {
  expect_identical(
    drm_scalar_sd_mu_targets(list(), list(), empty_random_mu_structure(4L), "Test"),
    list()
  )

  fixture <- scalar_sd_fixture()
  expect_error(
    drm_scalar_sd_mu_targets(
      list(sd_entry(quote(sd(id)))),
      list(),
      empty_random_mu_structure(nrow(fixture$data)),
      family_label = "Test"
    ),
    "No random-effect term matches"
  )

  two <- scalar_sd_fixture(list(quote(1 | id), quote(0 + x | id)))
  out <- drm_scalar_sd_mu_targets(
    list(sd_entry(quote(sd(id, coef = "x")))),
    two$terms,
    two$re,
    family_label = "Test",
    allow_slopes = TRUE,
    allow_independent_same_group = TRUE
  )
  expect_equal(out[[1L]]$identity$coef, "x")

  dup_entries <- list(
    sd_entry(quote(sd(id, coef = "(Intercept)"))),
    sd_entry(quote(sd(id, coef = "(Intercept)")))
  )
  expect_error(
    drm_scalar_sd_mu_targets(
      dup_entries,
      fixture$terms,
      fixture$re,
      family_label = "Test"
    ),
    "Duplicate random-effect scale formula"
  )
})

test_that("drm_binomial_sd_mu_targets() is the binomial mu admission adapter", {
  fixture <- scalar_sd_fixture(list(quote(1 | id)), "mu")
  entry <- list(sd_entry(quote(sd(id))))
  binomial <- drm_binomial_sd_mu_targets(entry, fixture$terms, fixture$re)
  generic <- drm_scalar_sd_mu_targets(
    entry,
    fixture$terms,
    fixture$re,
    family_label = "Binomial",
    allow_slopes = TRUE,
    allow_independent_same_group = TRUE,
    allow_correlated_q2 = TRUE,
    allow_correlated_blocks = TRUE
  )
  expect_equal(binomial, generic)
})

test_that("drm_eval_call_weights() resolves scalar and data-frame weights", {
  data <- data.frame(w = c(1, 2, 1), y = 1:3)
  env <- environment()
  call <- call("drmTMB", y ~ 1, weights = 2)
  expect_equal(drm_eval_call_weights(call, data, env), 2)

  call_df <- call("drmTMB", y ~ 1, weights = quote(w))
  expect_equal(drm_eval_call_weights(call_df, data, env), c(1, 2, 1))

  bare <- call("drmTMB", y ~ 1)
  expect_null(drm_eval_call_weights(bare, data, env))

  bad <- call("drmTMB", y ~ 1, weights = quote(matrix(1:4, 2)))
  expect_error(
    drm_eval_call_weights(bad, data, env),
    "must be a numeric vector"
  )
})

test_that("Julia mi() route refuses non-unit weights", {
  expect_false(drm_abort_julia_mi_nonunit_weights(NULL))
  expect_false(drm_abort_julia_mi_nonunit_weights(rep(1, 3)))
  expect_error(
    drm_abort_julia_mi_nonunit_weights(c(2, 1)),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
})

test_that("mi quadrature abort helpers recognise beta and gamma terms", {
  gamma <- list(enabled = TRUE, family = "gamma")
  beta <- list(enabled = TRUE, family = "beta")
  expect_true(drm_mi_term_uses_quadrature_abort(gamma))
  expect_true(drm_mi_term_uses_quadrature_abort(beta))
  expect_false(drm_mi_term_uses_quadrature_abort(list(enabled = TRUE, family = "gaussian")))
  spec <- list(missing_predictor = beta, missing_predictor2 = list(enabled = FALSE))
  expect_true(drm_spec_uses_mi_quadrature_abort(spec))
  expect_identical(
    drm_mi_quadrature_abort_families(),
    c("gamma", "beta", "zero_one_beta")
  )
})

test_that("drm_dpar_component() maps public parameter names to components", {
  expect_equal(drm_dpar_component("mu"), "location")
  expect_equal(drm_dpar_component("mu2"), "location")
  expect_equal(drm_dpar_component("sigma1"), "distributional-scale")
  expect_equal(drm_dpar_component("rho12"), "residual-correlation")
  expect_equal(drm_dpar_component("nu"), "shape")
  expect_equal(drm_dpar_component("zi"), "probability")
  expect_equal(drm_dpar_component("sd(id)"), "random-effect-sd-model")
  expect_equal(drm_dpar_component("custom_dpar"), "distributional-parameter")
})

test_that("predict_parameters ordering and newdata expansion honour reserved columns", {
  messy <- data.frame(
    row = 1:2,
    dpar = c("mu", "sigma"),
    estimate = c(0.1, 0.2),
    extra = 3:4,
    stringsAsFactors = FALSE
  )
  ordered <- predict_parameters_order_columns(messy)
  expect_equal(
    names(ordered)[1:4],
    c("row", "dpar", "estimate", "extra")
  )

  grid <- data.frame(x = 1:2, row = c(9, 8))
  wide <- predict_parameters_newdata_columns(grid, n_dpar = 2L)
  expect_equal(nrow(wide), 4L)
  expect_true("newdata_row" %in% names(wide))
  expect_equal(wide$x, rep(1:2, times = 2L))
})

test_that("predict_parameters_inverse_link_derivative() matches link contracts", {
  gauss <- list(model = list(model_type = "gaussian"))
  expect_equal(
    predict_parameters_inverse_link_derivative(gauss, "mu", c(-1, 0, 1)),
    rep(1, 3)
  )
  expect_equal(
    predict_parameters_inverse_link_derivative(gauss, "sigma", 0),
    1,
    tolerance = 1e-8
  )

  beta_obj <- list(model = list(model_type = "beta"))
  eta <- qlogis(c(0.2, 0.5, 0.8))
  deriv <- predict_parameters_inverse_link_derivative(beta_obj, "mu", eta)
  expect_equal(deriv, plogis(eta) * (1 - plogis(eta)))

  local_mocked_bindings(
    drm_dpar_link = function(object, dpar) "not_a_link",
    .package = "drmTMB"
  )
  expect_error(
    predict_parameters_inverse_link_derivative(gauss, "mu", 0),
    "unknown inverse-link derivative"
  )
})