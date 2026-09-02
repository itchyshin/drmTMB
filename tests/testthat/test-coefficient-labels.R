# Design 258 S7: the coefficient-label PRODUCER contract, drmTMB half.
#
# (a) drm_julia_bridge_payload_coef_labels() builds the payload's `coef_labels`
#     field: base-R public column names, per dpar, straight from
#     stats::model.matrix() on the same data/env the rest of the payload uses.
# (b) drm_julia_bridge_coef_labels() (R/julia-coefficient-labels.R) is the
#     EXISTING validator for DRM.jl's echoed `bridge_formula_labels_v1` map --
#     unchanged by this slice, exercised here with stub engine `result`
#     fixtures built from design 258 S2's ten constructs.
# (c) drm_julia_bridge_check_coef_labels() is the new fail-closed rule for
#     when the engine returns NO map: compare its raw names against the
#     payload's base-R names, per dpar, by exact string/order equality; abort
#     naming DRM.jl on any mismatch, pass through silently when they match.
#
# No live Julia is used anywhere in this file: `result` objects are hand-built
# fixtures, not fits.

# A minimally valid `bridge_formula_labels_v1` result for a given public/raw
# pairing (mirrors label_fixture() in test-julia-bridge-coef-labels.R, kept
# local and self-contained here since this file exercises the CONTRACT, not
# the validator's internals).
stub_bridge_result <- function(public, raw) {
  n <- length(public)
  list(
    coef_label_contract = "bridge_formula_labels_v1",
    coef_names = public,
    raw_coef_names = raw,
    coef_name_map = stats::setNames(as.list(raw), public),
    vcov_names = public,
    coefficients = seq_len(n) / 10,
    vcov = diag(n) + outer(seq_len(n), seq_len(n)) / 100
  )
}

# Runs both halves of the producer contract for one design-258-S2 construct:
# (1) the REAL producer, drm_julia_bridge_payload_coef_labels(), reads the
#     base-R public term names straight off model.matrix() for `formula`/`data`;
# (2) a STUB engine map pairs those same base-R names (dpar-prefixed with `_`,
#     the validator's public spelling) against `raw` synthetic names, and the
#     EXISTING validator accepts it and returns the public spelling unchanged.
expect_construct_base_r_labels <- function(formula, data, dpar, raw_terms) {
  produced <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = formula,
    data = data,
    env = environment()
  )
  public_terms <- produced[[dpar]]
  expect_true(!is.null(public_terms))
  expect_length(public_terms, length(raw_terms))

  public <- paste0(dpar, "_", public_terms)
  raw <- paste0(dpar, "_", raw_terms)
  result <- stub_bridge_result(public, raw)
  labels <- drmTMB:::drm_julia_bridge_coef_labels(result)
  expect_identical(labels$public, public)
  expect_identical(labels$raw, raw)
  # The public spelling drmTMB shows is base-R's, not DRM.jl's synthetic one.
  expect_identical(drmTMB:::drm_julia_split_coef_name(labels$public)$term, public_terms)
  invisible(labels)
}

construct_data <- function() {
  set.seed(1)
  n <- 24
  data.frame(
    y = rnorm(n),
    x = rnorm(n),
    z = rnorm(n),
    grp = factor(rep(c("lo", "mid", "hi"), length.out = n)),
    g = factor(rep(c("a", "b"), length.out = n)),
    h = factor(rep(c(10, 20), length.out = n))
  )
}

test_that("construct 1: I() yields base-R public labels through a stub engine map", {
  d <- construct_data()
  expect_construct_base_r_labels(
    drmTMB::bf(y ~ x + I(x^2)), d, "mu",
    c("(Intercept)", "x", "__bridge_I_1")
  )
})

test_that("construct 2: factor() yields base-R public labels through a stub engine map", {
  d <- construct_data()
  expect_construct_base_r_labels(
    drmTMB::bf(y ~ factor(grp)), d, "mu",
    c("(Intercept)", "__bridge_factor_1: lo", "__bridge_factor_1: mid")
  )
})

test_that("construct 3: poly() yields base-R public labels through a stub engine map", {
  d <- construct_data()
  expect_construct_base_r_labels(
    drmTMB::bf(y ~ poly(x, 3)), d, "mu",
    c("(Intercept)", "__bridge_poly3c1_1", "__bridge_poly3c2_2", "__bridge_poly3c3_3")
  )
})

test_that("construct 4: crossed poly() yields base-R public labels through a stub engine map", {
  d <- construct_data()
  expect_construct_base_r_labels(
    drmTMB::bf(y ~ z * poly(x, 2)), d, "mu",
    c(
      "(Intercept)", "z", "__bridge_poly2c1_1", "__bridge_poly2c2_2",
      "z & __bridge_poly2c1_1", "z & __bridge_poly2c2_2"
    )
  )
})

test_that("construct 5: powers (...)^k yield base-R public labels through a stub engine map", {
  d <- construct_data()
  expect_construct_base_r_labels(
    drmTMB::bf(y ~ (x + z)^2), d, "mu",
    c("(Intercept)", "x", "z", "x & z")
  )
})

test_that("construct 6: scale() yields base-R public labels through a stub engine map", {
  d <- construct_data()
  expect_construct_base_r_labels(
    drmTMB::bf(y ~ scale(x)), d, "mu",
    c("(Intercept)", "__bridge_scale_1")
  )
})

test_that("construct 7: reversed two-factor interaction yields base-R public labels through a stub engine map", {
  d <- construct_data()
  expect_construct_base_r_labels(
    drmTMB::bf(y ~ g + factor(h) + factor(h):g), d, "mu",
    c(
      "(Intercept)", "g: b", "__bridge_factor_1: 20.0",
      "__bridge_factor_1: 20.0 & g: b"
    )
  )
})

test_that("construct 8: unary-plus arithmetic yields base-R public labels through a stub engine map", {
  d <- construct_data()
  expect_construct_base_r_labels(
    drmTMB::bf(y ~ I(+x)), d, "mu",
    c("(Intercept)", "__bridge_I_1")
  )
})

test_that("construct 9: explicitly parenthesised arithmetic yields base-R public labels through a stub engine map", {
  d <- construct_data()
  expect_construct_base_r_labels(
    drmTMB::bf(y ~ I(x + (z + 2))), d, "mu",
    c("(Intercept)", "__bridge_I_1")
  )
})

test_that("construct 10: decimal-spelled integer exponent yields base-R public labels through a stub engine map", {
  d <- construct_data()
  # Same formula shape as construct 1 (`I(x^2)`); design 258 S2 lists it
  # separately because the exponent is float-coerced on the Julia side while
  # staying an ordinary base-R I() term here.
  expect_construct_base_r_labels(
    drmTMB::bf(y ~ I(x^2)), d, "mu",
    c("(Intercept)", "__bridge_I_1")
  )
})

test_that("validator reorder: a shuffled vcov_names aborts, no positional guessing", {
  d <- construct_data()
  result <- stub_bridge_result(
    c("mu_(Intercept)", "mu_x", "mu_I(x^2)"),
    c("mu_(Intercept)", "mu_x", "mu___bridge_I_1")
  )
  result$vcov_names <- rev(result$vcov_names)
  expect_error(drmTMB:::drm_julia_bridge_coef_labels(result), "covariance label order")
})

test_that("validator duplicate: a repeated public name aborts, no positional guessing", {
  result <- stub_bridge_result(
    c("mu_(Intercept)", "mu_x", "mu_I(x^2)"),
    c("mu_(Intercept)", "mu_x", "mu___bridge_I_1")
  )
  result$coef_names[2] <- result$coef_names[1]
  expect_error(drmTMB:::drm_julia_bridge_coef_labels(result), "missing or duplicate")
})

test_that("validator incomplete: a missing map entry aborts, no positional guessing", {
  result <- stub_bridge_result(
    c("mu_(Intercept)", "mu_x", "mu_I(x^2)"),
    c("mu_(Intercept)", "mu_x", "mu___bridge_I_1")
  )
  result$coef_name_map[["mu_x"]] <- NULL
  expect_error(drmTMB:::drm_julia_bridge_coef_labels(result), "incomplete label map")
})

test_that("no map: absent bridge_formula_labels_v1 fails closed and names DRM.jl in the abort", {
  coef_names <- c("mu_(Intercept)", "mu_x", "mu___bridge_I_1")
  coef_labels <- list(mu = c("(Intercept)", "x", "I(x^2)"))
  expect_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(coef_names, coef_labels),
    "DRM\\.jl"
  )
})

test_that("no map: identical plain-term names pass through without aborting", {
  coef_names <- c("mu_(Intercept)", "mu_x", "sigma_(Intercept)")
  coef_labels <- list(mu = c("(Intercept)", "x"), sigma = c("(Intercept)"))
  expect_no_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(coef_names, coef_labels)
  )
})

test_that("no map: an absent payload coef_labels dpar is skipped, not checked", {
  coef_names <- c("mu_(Intercept)", "mu___bridge_I_1")
  # `sigma` has no plain fixed-effect entry in coef_labels (e.g. it carries a
  # structured term), so it is simply not compared -- only `mu` would fail
  # closed, and `mu` is absent from coef_labels here too.
  coef_labels <- list()
  expect_no_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(coef_names, coef_labels)
  )
})

test_that("new_drmTMB_julia end-to-end: no map, matching payload names fit without aborting", {
  d <- data.frame(y = seq_len(12), x = seq_len(12) / 12, g = factor(rep(c("a", "b"), 6)))
  formula <- drmTMB::bf(y ~ x + I(x^2), sigma ~ 1)
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = formula, family_type = "gaussian", data = d, env = environment()
  )
  raw_public <- c(
    paste0("mu_", payload$coef_labels$mu),
    paste0("sigma_", payload$coef_labels$sigma)
  )
  result <- list(
    coef_names = raw_public,
    coefficients = seq_along(raw_public) / 10,
    vcov = diag(length(raw_public)),
    loglik = -10, aic = 30, bic = 32, df = length(raw_public), nobs = 12L,
    converged = TRUE, fitted = rep(0, 12), residuals = rep(0, 12), sigma = 1,
    corpairs = list()
  )
  fit <- drmTMB:::new_drmTMB_julia(
    result, quote(drmTMB()), formula, gaussian(), d, "gaussian",
    bridge_payload = payload
  )
  expect_identical(names(fit$coefficients$mu), payload$coef_labels$mu)
  expect_identical(drmTMB:::coefficient_labels(fit)[1:3], paste0("mu:", payload$coef_labels$mu))
})

test_that("new_drmTMB_julia end-to-end: no map, mismatched payload names abort naming DRM.jl", {
  d <- data.frame(y = seq_len(12), x = seq_len(12) / 12)
  formula <- drmTMB::bf(y ~ I(x^2))
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = formula, family_type = "gaussian", data = d, env = environment()
  )
  result <- list(
    coef_names = c("mu_(Intercept)", "mu___bridge_I_1"),
    coefficients = c(0.1, 0.2),
    vcov = diag(2),
    loglik = -10, aic = 30, bic = 32, df = 2L, nobs = 12L,
    converged = TRUE, fitted = rep(0, 12), residuals = rep(0, 12), sigma = 1,
    corpairs = list()
  )
  expect_error(
    drmTMB:::new_drmTMB_julia(
      result, quote(drmTMB()), formula, gaussian(), d, "gaussian",
      bridge_payload = payload
    ),
    "DRM\\.jl"
  )
})
