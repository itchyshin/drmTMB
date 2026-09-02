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
  bridge_payload <- list(coef_labels = list(mu = c("(Intercept)", "x", "I(x^2)")))
  expect_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(coef_names, bridge_payload),
    "DRM\\.jl"
  )
})

test_that("no map: identical plain-term names pass through without aborting", {
  coef_names <- c("mu_(Intercept)", "mu_x", "sigma_(Intercept)")
  bridge_payload <- list(coef_labels = list(mu = c("(Intercept)", "x"), sigma = c("(Intercept)")))
  expect_no_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(coef_names, bridge_payload)
  )
})

test_that("no map: a bridge_payload with no coef_labels field at all (structured/joint/xfam routes) is skipped, not checked", {
  # Rose S9 attack A10: `drm_julia_structured_payload()` and
  # `drm_julia_biv_known_structured_payload()` never set `coef_labels` on
  # their own payloads (design 258 S7.4). Those routes are out of THIS
  # contract's scope, so the check must tell "field absent" apart from
  # "field present but empty" (the vacuity tests below).
  coef_names <- c("mu_(Intercept)", "mu___bridge_I_1")
  expect_no_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(coef_names, list())
  )
  expect_no_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(coef_names, NULL)
  )
})

# --- Rose S9 (2026-09-02) repair: random-effect bars never reach model.matrix() ---
# (design 258 S7.1, gate S3-G7). Attack A2b: a bare `(1 | g)` has
# `entry$structured` of length 0 (it carries no `random` field at all), so the
# OLD skip-when-structured producer let `1 | g` reach `stats::model.matrix()`,
# which misparses `|` as logical-OR and fabricates a column `"1 | gTRUE"`.

test_that("random-effect bars: a bare (1 | g) never reaches model.matrix and yields fixed-effect-only mu labels", {
  d <- construct_data()
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = drmTMB::bf(mu = y ~ x + (1 | g), sigma = ~1),
    data = d,
    env = environment()
  )
  expect_identical(labels$mu, c("(Intercept)", "x"))
  expect_false(any(grepl("\\|", labels$mu)))
  expect_false(any(grepl("gTRUE", labels$mu)))
})

test_that("random-effect bars: a correlated random slope (1 + x | g) also strips to fixed-effect-only labels", {
  d <- construct_data()
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = drmTMB::bf(mu = y ~ z + (1 + x | g), sigma = ~1),
    data = d,
    env = environment()
  )
  expect_identical(labels$mu, c("(Intercept)", "z"))
  expect_false(any(grepl("\\|", labels$mu)))
})

# --- Rose S9 repair: a phylo dpar's fixed-effect block is CHECKED, not exempt ---
# (design 258 S7.1, gate S3-G8). Attack A2: `drm_julia_has_structured_term()`
# is FALSE for a phylo formula, so such a fit stays on the MAIN bridge and
# reaches the fail-closed check -- but the old "skip when entry$structured is
# non-empty" producer left the mean-side (mu) block permanently unlabelled,
# which then made A5's vacuity hole silently pass every phylogenetic fit.

test_that("phylo: a mu dpar carrying a phylo() term still gets labels for its fixed-effect block", {
  set.seed(1)
  d <- data.frame(
    y = rnorm(20), x = rnorm(20),
    g = factor(rep(letters[1:4], 5)), sp = paste0("s", 1:20)
  )
  tr <- ape::rtree(20)
  tr$tip.label <- d$sp
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = drmTMB::bf(mu = y ~ x + g + phylo(1 | sp, tree = tr), sigma = ~x),
    data = d,
    env = environment()
  )
  expect_identical(labels$mu, c("(Intercept)", "x", "gb", "gc", "gd"))
  expect_identical(labels$sigma, c("(Intercept)", "x"))
})

# --- Rose S9 repair: the MAP path also cross-checks against drmTMB's own
# base-R spelling (design 258 S7.3, gate S3-G9). D-202: base-R wins even over
# an engine that supplies a validated, self-consistent map -- a validated map
# is necessary but not sufficient.

test_that("map cross-check: a permutation of drmTMB's own public labels aborts naming DRM.jl (attack A3)", {
  d <- data.frame(y = seq_len(12), x = seq_len(12) / 12)
  formula <- drmTMB::bf(y ~ x)
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = formula, family_type = "gaussian", data = d, env = environment()
  )
  result <- list(
    coef_label_contract = "bridge_formula_labels_v1",
    coef_names = c("mu_x", "mu_(Intercept)"), # swapped vs drmTMB's own order
    raw_coef_names = c("mu_x", "mu_Intercept"),
    coef_name_map = list("mu_x" = "mu_x", "mu_(Intercept)" = "mu_Intercept"),
    vcov_names = c("mu_x", "mu_(Intercept)"),
    coefficients = c(0.5, 10),
    vcov = diag(2)
  )
  expect_error(
    drmTMB:::new_drmTMB_julia(
      result, quote(drmTMB()), formula, gaussian(), d, "gaussian",
      bridge_payload = payload
    ),
    "DRM\\.jl"
  )
})

test_that("map cross-check: public names DRM.jl never produced from drmTMB's model.matrix abort (attack A3c)", {
  d <- data.frame(y = seq_len(12), x = seq_len(12) / 12)
  formula <- drmTMB::bf(y ~ x)
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = formula, family_type = "gaussian", data = d, env = environment()
  )
  result <- list(
    coef_label_contract = "bridge_formula_labels_v1",
    coef_names = c("mu_beta_one", "mu_beta_two"), # invented, never in model.matrix
    raw_coef_names = c("mu_x1", "mu_x2"),
    coef_name_map = list("mu_beta_one" = "mu_x1", "mu_beta_two" = "mu_x2"),
    vcov_names = c("mu_beta_one", "mu_beta_two"),
    coefficients = c(0.5, 10),
    vcov = diag(2)
  )
  expect_error(
    drmTMB:::new_drmTMB_julia(
      result, quote(drmTMB()), formula, gaussian(), d, "gaussian",
      bridge_payload = payload
    ),
    "DRM\\.jl"
  )
})

# --- Rose S9 repair: no vacuity (design 258 S7.3, gate S3-G10). Attack A1: an
# empty `coef_labels` on the MAIN bridge (the field is present, i.e. this
# route IS under the contract) used to return NULL silently. Attack A5: an
# engine fixed-effect dpar with no payload label used to pass by iterating
# only `names(coef_labels)`, never the engine's own dpar set.

test_that("no vacuity: an empty coef_labels field on the main bridge aborts as an internal invariant failure", {
  coef_names <- c("mu_(Intercept)", "mu_x")
  expect_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(coef_names, list(coef_labels = list())),
    "internal invariant|report this"
  )
})

test_that("no vacuity: a fixed-effect dpar the engine returns but the payload never labelled (unlabelled) aborts", {
  coef_names <- c("mu_(Intercept)", "mu_x", "sigma_GARBAGE & junk")
  bridge_payload <- list(coef_labels = list(mu = c("(Intercept)", "x")))
  expect_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(coef_names, bridge_payload),
    "sigma"
  )
})

test_that("no vacuity: variance-component blocks (resd_/recov_/phylocov_) are excluded from the unlabelled-dpar check", {
  coef_names <- c("mu_(Intercept)", "mu_x", "resd_g_(Intercept)", "phylocov_Sigma_a:L11")
  bridge_payload <- list(coef_labels = list(mu = c("(Intercept)", "x")))
  expect_no_error(
    drmTMB:::drm_julia_bridge_check_coef_labels(coef_names, bridge_payload)
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
