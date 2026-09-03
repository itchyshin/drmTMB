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

# --- Wire format (design 258 S7.1, corrected 2026-09-02): the Julia call
# carries only formula/family/data/tree/options, so `coef_labels` must travel
# INSIDE options for DRM.jl to echo it. Gate S3-G14.

test_that("options carry coef_labels: the payload's options$coef_labels is the per-dpar base-R label list DRM.jl echoes", {
  d <- data.frame(y = seq_len(12), x = seq_len(12) / 12, grp = factor(rep(c("hi", "lo", "mid"), 4)))
  formula <- drmTMB::bf(y ~ x + I(x^2) + factor(grp), sigma ~ x)
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = formula, family_type = "gaussian", data = d, env = environment()
  )
  expect_true(is.list(payload$options$coef_labels))
  # wire form: list-of-strings per dpar (JuliaCall length-1 unboxing guard); R-side copy stays character
  expect_identical(payload$options$coef_labels, lapply(payload$coef_labels, as.list))
  expect_identical(unlist(payload$options$coef_labels$mu), c("(Intercept)", "x", "I(x^2)", "factor(grp)lo", "factor(grp)mid"))
  expect_identical(unlist(payload$options$coef_labels$sigma), c("(Intercept)", "x"))
})

test_that("options carry coef_labels: REML and the label field coexist in options", {
  d <- data.frame(y = seq_len(12), x = seq_len(12) / 12)
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = drmTMB::bf(y ~ x), family_type = "gaussian", data = d, env = environment(), method = "REML"
  )
  expect_identical(payload$options$method, "REML")
  expect_identical(unlist(payload$options$coef_labels$mu), c("(Intercept)", "x"))
})

# --- N1 (2026-09-03): widen the ONE producer contract to the remaining
# payload builders (design 258 S7.4/S7.5) -- structured (relmat/animal/
# spatial), bivariate q=2 known-structured, joint, and cross-family (xfam).
# No live Julia in this section: each unit test builds the payload/axes
# directly and checks base-R names + the extra blocks DRM.jl's echo demands
# for blocks with no `formula$entries` counterpart (discovered empirically,
# see the producer's comments in R/julia-bridge.R).

test_that("structured payload: coef_labels covers mu/sigma from the formula and the resd block DRM.jl also fits", {
  set.seed(1)
  n <- 12
  g <- factor(rep(c("a", "b", "c"), each = 4))
  K <- diag(3)
  rownames(K) <- colnames(K) <- levels(g)
  d <- data.frame(y = rnorm(n), x = rnorm(n), g = g)
  payload <- drmTMB:::drm_julia_structured_payload(
    formula = drmTMB::bf(mu = y ~ x + relmat(1 | g, K = K)),
    family_type = "gaussian",
    data = d,
    env = environment()
  )
  expect_identical(payload$coef_labels$mu, c("(Intercept)", "x"))
  # `sigma` is not in the formula at all -- DRM.jl still fits an intercept-only
  # dispersion block by default (N1's default-dpar-labels finding).
  expect_identical(payload$coef_labels$sigma, "(Intercept)")
  # `resd` has no `formula$entries` counterpart: DRM.jl's own synthetic name
  # for the general-covariance random-effect SD, echoed back unchanged.
  expect_identical(payload$coef_labels$resd, "g")
  expect_identical(payload$options$coef_labels, lapply(payload$coef_labels, as.list))
})

test_that("known-structured payload: coef_labels covers mu1/mu2/sigma1/sigma2/rho12 and the phylocov block DRM.jl also fits", {
  set.seed(2)
  n <- 12
  g <- factor(rep(c("a", "b", "c"), each = 4))
  K <- diag(3)
  rownames(K) <- colnames(K) <- levels(g)
  d <- data.frame(y1 = rnorm(n), y2 = rnorm(n), x1 = rnorm(n), g = g)
  payload <- drmTMB:::drm_julia_biv_known_structured_payload(
    formula = drmTMB::bf(
      mu1 = y1 ~ x1 + relmat(1 | p | g, K = K),
      mu2 = y2 ~ x1 + relmat(1 | p | g, K = K)
    ),
    family_type = "biv_gaussian",
    data = d,
    env = environment()
  )
  expect_identical(payload$coef_labels$mu1, c("(Intercept)", "x1"))
  expect_identical(payload$coef_labels$mu2, c("(Intercept)", "x1"))
  # sigma1/sigma2/rho12 are not in the formula: DRM.jl still fits all three by
  # default (N1's default-dpar-labels finding, biv_gaussian branch).
  expect_identical(payload$coef_labels$sigma1, "(Intercept)")
  expect_identical(payload$coef_labels$sigma2, "(Intercept)")
  expect_identical(payload$coef_labels$rho12, "(Intercept)")
  # `phylocov` has no `formula$entries` counterpart: the shared relmat term's
  # 2x2 among-axis covariance, SAME naming convention as the q4 phylo route.
  expect_identical(
    payload$coef_labels$phylocov,
    c("Sigma_a:L11", "Sigma_a:L21", "Sigma_a:L22")
  )
  expect_identical(payload$options$coef_labels, lapply(payload$coef_labels, as.list))
})

test_that("joint payload: mu/sigma/predictor names are base-R model.matrix() spelling by construction", {
  dat <- data.frame(
    y = c(0.2, 0.5, NA, 1.1, 1.4, 1.8, 2.1, NA, 2.6),
    x = c(-.5, NA, .1, .4, NA, .9, 1.2, 1.4, .7),
    z = c(-1, -.7, -.3, 0, .2, .5, .8, 1, 1.3),
    g = factor(c("lo", "hi", "lo", "hi", "lo", "hi", "lo", "hi", "lo"))
  )
  formula <- drmTMB::bf(y ~ mi(x) + g, sigma ~ g)
  prepared <- drmTMB:::drm_julia_joint_prepare(
    formula = formula, family = gaussian(), data = dat, env = environment(),
    weights_missing = TRUE, control = drm_control(), impute = list(x = x ~ z),
    missing = miss_control(response = "include", predictor = "model")
  )
  # `mu_names` is the fixed-effect model.matrix() spelling with the mi(x)
  # column substituted for `x` -- there is no round trip through DRM.jl's own
  # naming to translate: `drm_bridge_joint()` builds `coef_names` DIRECTLY
  # from these payload fields (R/joint_missing_bridge.jl, DRM.jl), so the
  # joint route is under design 258's contract by construction.
  expect_identical(
    prepared$payload$mu_names,
    sub("^x$", "mi(x)", colnames(stats::model.matrix(~ x + g, dat)))
  )
  expect_identical(prepared$payload$sigma_names, colnames(stats::model.matrix(~g, dat)))
  expect_identical(prepared$payload$predictor_names, colnames(stats::model.matrix(~z, dat)))
})

test_that("cross-family payload (xfam): axis coef_names are base-R model.matrix() spelling by construction", {
  set.seed(4)
  n <- 30
  d <- data.frame(
    y1 = rpois(n, 3), y2 = rnorm(n), x = rnorm(n),
    g = factor(rep(c("a", "b"), n / 2))
  )
  # `drm_julia_xfam_axes()` builds each axis's design straight from R's own
  # `model.matrix()` and never asks DRM.jl for a name at all -- `fit_mixed_family`
  # (a different Julia function from `drm_bridge`) returns only numeric
  # coefficient vectors, which the R side names itself. The xfam route is
  # under design 258's contract by construction, the same way the joint route
  # is.
  axes <- drmTMB:::drm_julia_xfam_axes(
    formula = drmTMB::bf(mu1 = y1 ~ x + g, mu2 = y2 ~ x),
    data = d,
    env = environment(),
    tags = c("poisson", "gaussian")
  )
  expect_identical(axes$mu1$coef_names, colnames(stats::model.matrix(~ x + g, d)))
  expect_identical(axes$mu2$coef_names, colnames(stats::model.matrix(~x, d)))
})

# --- Live tests: DRM.jl's echo actually accepts these labels and returns
# base-R public names end to end. Skipped -- never failed -- when live Julia
# is unavailable, matching the rest of this suite's convention
# (`drm_skip_live_julia()`); the fixture path is read from `DRM_JL_PATH`
# only, never a machine-specific path.

test_that("live echo: a relmat structured Julia fit reports base-R public names matching the TMB engine", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  jl_path <- Sys.getenv("DRM_JL_PATH", "")
  skip_if_not(nzchar(jl_path) && dir.exists(jl_path), "DRM_JL_PATH not available")

  set.seed(21)
  n <- 40
  g <- factor(rep(letters[1:5], each = 8))
  K <- diag(5)
  rownames(K) <- colnames(K) <- levels(g)
  grp <- factor(sample(c("lo", "hi"), n, TRUE))
  x <- rnorm(n)
  y <- rnorm(n) + 0.3 * x + as.numeric(grp == "hi") * 0.4
  d <- data.frame(y = y, x = x, grp = grp, g = g)

  form <- drmTMB::bf(mu = y ~ x + factor(grp) + relmat(1 | g, K = K))
  fj <- drmTMB(form, family = gaussian(), data = d, engine = "julia")
  ft <- drmTMB(form, family = gaussian(), data = d)

  expect_false(is.null(fj$bridge_public_coef_labels))
  expect_identical(names(coef(fj, "mu")), names(coef(ft, "mu")))
  expect_true(all(grepl("^resd_|^sigma_", setdiff(
    fj$bridge_public_coef_labels$public,
    paste0("mu_", names(coef(fj, "mu")))
  ))))
})

test_that("live echo: a cross-family Julia fit reports base-R public names", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  jl_path <- Sys.getenv("DRM_JL_PATH", "")
  skip_if_not(nzchar(jl_path) && dir.exists(jl_path), "DRM_JL_PATH not available")

  set.seed(22)
  n <- 60
  d <- data.frame(
    y1 = rpois(n, 3), y2 = rnorm(n), x = rnorm(n),
    grp = factor(rep(c("a", "b"), n / 2))
  )
  fx <- drmTMB(
    drmTMB::bf(mu1 = y1 ~ x + grp, mu2 = y2 ~ x),
    family = c(poisson(), gaussian()), data = d, engine = "julia"
  )
  expect_true(inherits(fx, "drmTMB_julia_xfam"))
  expect_identical(names(coef(fx, "mu1")), colnames(stats::model.matrix(~ x + grp, d)))
  expect_identical(names(coef(fx, "mu2")), colnames(stats::model.matrix(~x, d)))
})

test_that("live echo: a joint missing-predictor Julia fit reports base-R public names", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  jl_path <- Sys.getenv("DRM_JL_PATH", "")
  skip_if_not(nzchar(jl_path) && dir.exists(jl_path), "DRM_JL_PATH not available")

  set.seed(23)
  dat <- data.frame(
    y = c(0.2, 0.5, NA, 1.1, 1.4, 1.8, 2.1, NA, 2.6, 1.0, 1.3, 0.9),
    x = c(-.5, NA, .1, .4, NA, .9, 1.2, 1.4, .7, .2, -.3, .5),
    z = c(-1, -.7, -.3, 0, .2, .5, .8, 1, 1.3, .1, .4, .6),
    g = factor(rep(c("lo", "hi"), 6))
  )
  fj <- drmTMB(
    drmTMB::bf(y ~ mi(x) + g, sigma ~ g),
    family = gaussian(), data = dat, engine = "julia",
    impute = list(x = x ~ z),
    missing = miss_control(response = "include", predictor = "model")
  )
  expect_true(inherits(fj, "drmTMB_julia_joint"))
  expect_identical(
    names(coef(fj, "mu")),
    sub("^x$", "mi(x)", colnames(stats::model.matrix(~ x + g, dat)))
  )
})

test_that("live predict on a structured Julia fit aligns factor and interaction terms without any punctuation rewrite", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  jl_path <- Sys.getenv("DRM_JL_PATH", "")
  skip_if_not(nzchar(jl_path) && dir.exists(jl_path), "DRM_JL_PATH not available")

  set.seed(24)
  n <- 60
  g <- factor(rep(letters[1:6], each = 10))
  K <- diag(6)
  rownames(K) <- colnames(K) <- levels(g)
  grp <- factor(sample(c("lo", "mid"), n, TRUE))
  z <- rnorm(n)
  x <- rnorm(n)
  y <- rnorm(n) + 0.3 * x + as.numeric(grp == "mid") * 0.5 + 0.2 * x * z
  d <- data.frame(y = y, x = x, grp = grp, g = g, z = z)

  fj <- drmTMB(
    drmTMB::bf(mu = y ~ x * z + factor(grp) + relmat(1 | g, K = K)),
    family = gaussian(), data = d, engine = "julia"
  )
  nd <- d[1:5, ]
  pr <- predict(fj, newdata = nd, type = "link")
  expect_length(pr, 5L)
  expect_true(all(is.finite(pr)))
})

# --- N1 repair (2026-09-03): Rose adversarial pass, "the WORST" refutation
# and the "neighbour hole". A bare univariate `phylo(1 | group)` random
# intercept aborted the echo on ALREADY-MERGED main (same class of gap as the
# base-bridge default-sigma fix), and a user-written `sigma` formula on a
# dispersionless family aborted it too, in the opposite direction.

test_that("dispersionless sigma: a user-written sigma formula on poisson/binomial is refused, not silently sent to the echo", {
  d <- data.frame(y = seq_len(12), x = seq_len(12) / 12)
  for (fam in c("poisson", "binomial")) {
    expect_error(
      drmTMB:::drm_julia_bridge_payload_coef_labels(
        formula = drmTMB::bf(y ~ x, sigma ~ 1),
        data = d,
        env = environment(),
        family_type = fam
      ),
      "does not support a .sigma. formula"
    )
  }
  # A formula with no sigma entry at all is unaffected -- only `sigma` itself
  # is refused, not the mu block or the family.
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = drmTMB::bf(y ~ x),
    data = d,
    env = environment(),
    family_type = "poisson"
  )
  expect_identical(labels$mu, c("(Intercept)", "x"))
  expect_null(labels$sigma)
})

test_that("structured payload: the resd block for phylo, not just relmat/animal/spatial, is labelled (unit, offline)", {
  set.seed(1)
  n <- 12
  tr <- ape::rtree(n)
  d <- data.frame(y = rnorm(n), x = rnorm(n), species = tr$tip.label)
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = drmTMB::bf(y ~ x + phylo(1 | species, tree = tr), sigma ~ 1),
    data = d,
    env = environment(),
    family_type = "gaussian"
  )
  expect_identical(labels$mu, c("(Intercept)", "x"))
  expect_identical(labels$resd, "species")

  # The coupled LSS route (a `sd(group)`/`sd_phylo(group)` dpar on the SAME
  # group) reports the random-effect covariance through that block INSTEAD --
  # no separate `resd` for that group.
  labels_lss <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = drmTMB::bf(
      y ~ x + phylo(1 | species, tree = tr), sigma ~ x,
      sd(species, level = "phylogenetic") ~ 1
    ),
    data = d,
    env = environment(),
    family_type = "gaussian"
  )
  expect_null(labels_lss$resd)
  expect_identical(labels_lss$sd_phylo, "(Intercept)")

  # A bivariate q4 phylo formula reports the covariance through `phylocov`
  # instead -- `resd` must NOT be added there (it would itself abort the
  # echo, "supplies names for unknown dpar").
  q4_formula <- drmTMB::bf(
    mu1 = y ~ x + phylo(1 | species, tree = tr),
    mu2 = y ~ x + phylo(1 | species, tree = tr),
    sigma1 = ~ phylo(1 | species, tree = tr), sigma2 = ~ phylo(1 | species, tree = tr)
  )
  labels_q4 <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = q4_formula, data = d, env = environment(), family_type = "biv_gaussian"
  )
  expect_null(labels_q4$resd)
  expect_identical(labels_q4$phylocov, drmTMB:::drm_julia_phylocov_block_labels(4L))
})

test_that("live echo, phylo: a univariate phylo() Julia fit reports base-R public names matching the TMB engine", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  jl_path <- Sys.getenv("DRM_JL_PATH", "")
  skip_if_not(nzchar(jl_path) && dir.exists(jl_path), "DRM_JL_PATH not available")

  set.seed(42)
  n <- 24
  tr <- ape::rcoal(n)
  d <- data.frame(x = rnorm(n), species = tr$tip.label)
  d$y <- 1 + 0.5 * d$x + rnorm(n, 0, 0.6)

  form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tr), sigma ~ 1)
  fj <- drmTMB(form, family = gaussian(), data = d, engine = "julia")
  ft <- drmTMB(form, family = gaussian(), data = d)

  expect_false(is.null(fj$bridge_public_coef_labels))
  expect_identical(names(coef(fj, "mu")), names(coef(ft, "mu")))
  expect_true("resd_species" %in% fj$bridge_public_coef_labels$public)
})
