# A6 (design 258; DRM.jl #467 + the #609 factors case): formula constructs
# through the `engine = "julia"` bridge with R-contrast fidelity.
#
# Base-R `model.matrix()` column names are canonical (D-202); DRM.jl echoes
# them. Measured at DRM.jl 430ef64cc on 2026-09-05: `factor()`, `I(x^2)`,
# `poly(x, 2)`, `(x + z)^2` and `- term` already agree with `engine = "tmb"`
# name-for-name to <= 3e-11 -- the gap was CONTRAST fidelity: a design the two
# engines build differently with the same column count (an ordered factor,
# a contr.sum factor, a character column whose locale-collated level order
# is not Julia's codepoint order, a factor whose levels were reversed on the
# Julia side only) passed every check and reported DRM.jl's coefficients
# under R's names with no error (max|coef diff| 1.180 / 1.757 / 0.462).
#
# Part 1 (no Julia): the label producer refuses non-treatment contrasts
#   before Julia starts, and still labels every construct base-R.
# Part 2 (live, gated by drm_skip_live_julia()): tmb-vs-julia parity per
#   construct by NAME and <= 1e-4 (ledger G3/G4), and the RED control (G5):
#   level order reversed on the Julia side only fails by name, not silently
#   by number. Needs a DRM.jl carrying `_bridge_check_coef_labels_fidelity`.

fc_data <- function(n = 150L, seed = 20260905L) {
  set.seed(seed)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  g_chr <- sample(c("low", "mid", "high"), n, TRUE)
  eff <- c(low = 0, mid = 0.6, high = -0.9)
  d <- data.frame(
    x = x, z = z, g_chr = g_chr,
    # 3 levels, NON-alphabetical declared order: baseline "low", columns mid/high.
    g_fac = factor(g_chr, levels = c("low", "mid", "high")),
    stringsAsFactors = FALSE
  )
  d$y <- 0.3 + 0.8 * x + 0.4 * x^2 + eff[g_chr] + stats::rnorm(n, 0, 0.5)
  d
}

fc_labels <- function(formula, data) {
  drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = formula, data = data, env = environment(), family_type = "gaussian"
  )
}

# The five constructs of the A6 ledger plus the factor shapes around them.
fc_constructs <- function() {
  list(
    factor_call        = list(form = bf(y ~ x + factor(g_chr), sigma ~ 1), mu = ~ x + factor(g_chr), sigma = ~1),
    factor_col_nonalpha = list(form = bf(y ~ x + g_fac, sigma ~ 1), mu = ~ x + g_fac, sigma = ~1),
    factor_interaction = list(form = bf(y ~ x * g_fac, sigma ~ 1), mu = ~ x * g_fac, sigma = ~1),
    I_x2               = list(form = bf(y ~ x + I(x^2), sigma ~ 1), mu = ~ x + I(x^2), sigma = ~1),
    poly_x_2           = list(form = bf(y ~ poly(x, 2), sigma ~ 1), mu = ~ poly(x, 2), sigma = ~1),
    power_xz_2         = list(form = bf(y ~ (x + z)^2, sigma ~ 1), mu = ~ (x + z)^2, sigma = ~1),
    minus_term         = list(form = bf(y ~ x + z - z, sigma ~ 1), mu = ~ x + z - z, sigma = ~1),
    sigma_factor       = list(form = bf(y ~ x, sigma ~ g_fac), mu = ~x, sigma = ~g_fac)
  )
}

# ---------------------------------------------------------------------------
# Part 1: no Julia.
# ---------------------------------------------------------------------------

test_that("producer: every construct is labelled with base-R model.matrix() names, level order as declared", {
  d <- fc_data()
  for (nm in names(fc_constructs())) {
    cs <- fc_constructs()[[nm]]
    labels <- fc_labels(cs$form, d)
    expect_identical(labels$mu, colnames(stats::model.matrix(cs$mu, d)), info = nm)
    expect_identical(labels$sigma, colnames(stats::model.matrix(cs$sigma, d)), info = nm)
  }
  expect_identical(
    fc_labels(bf(y ~ x + g_fac, sigma ~ 1), d)$mu,
    c("(Intercept)", "x", "g_facmid", "g_fachigh")
  )
})

test_that("producer refuses an ordered factor (contr.poly) before Julia starts, naming the column", {
  d <- fc_data()
  d$g_ord <- factor(as.character(d$g_fac), levels = levels(d$g_fac), ordered = TRUE)
  expect_error(
    fc_labels(bf(y ~ x + g_ord, sigma ~ 1), d),
    "g_ord: an ordered factor"
  )
  expect_error(fc_labels(bf(y ~ x + g_ord, sigma ~ 1), d), "treatment contrasts")
  # On the sigma side too, naming that dpar.
  expect_error(fc_labels(bf(y ~ x, sigma ~ g_ord), d), "sigma")
})

test_that("producer refuses a factor carrying an explicit contrasts attribute (contr.sum)", {
  d <- fc_data()
  d$g_sum <- d$g_fac
  stats::contrasts(d$g_sum) <- stats::contr.sum(3)
  expect_error(
    fc_labels(bf(y ~ x + g_sum, sigma ~ 1), d),
    "g_sum: a factor with an explicit `contrasts` attribute"
  )
  # A contrasts attribute that IS treatment coding is not a disagreement.
  d$g_trt <- d$g_fac
  stats::contrasts(d$g_trt) <- stats::contr.treatment(3)
  expect_identical(
    fc_labels(bf(y ~ x + g_trt, sigma ~ 1), d)$mu,
    colnames(stats::model.matrix(~ x + g_trt, d))
  )
})

test_that("producer refuses a non-default options(\"contrasts\") for plain factors and character columns", {
  d <- fc_data()
  withr::local_options(contrasts = c("contr.sum", "contr.poly"))
  expect_error(
    fc_labels(bf(y ~ x + g_fac, sigma ~ 1), d),
    "g_fac: coded with options\\(\"contrasts\"\\) = \"contr.sum\""
  )
  expect_error(fc_labels(bf(y ~ x + g_chr, sigma ~ 1), d), "g_chr: coded with")
  expect_error(fc_labels(bf(y ~ x + factor(g_chr), sigma ~ 1), d), "factor\\(g_chr\\): coded with")
})

test_that("producer: a logical covariate under default contrasts is treatment-coded and accepted", {
  d <- fc_data()
  d$flag <- d$x > 0
  expect_identical(
    fc_labels(bf(y ~ x + flag, sigma ~ 1), d)$mu,
    c("(Intercept)", "x", "flagTRUE")
  )
})

test_that("RED control of the refusal: the same ordered factor is accepted by drmTMB's own native engine (the disagreement is engine-specific, not a formula error)", {
  d <- fc_data()
  d$g_ord <- factor(as.character(d$g_fac), levels = levels(d$g_fac), ordered = TRUE)
  ft <- drmTMB(bf(y ~ x + g_ord, sigma ~ 1), family = gaussian(), data = d)
  expect_identical(names(coef(ft, "mu")), c("(Intercept)", "x", "g_ord.L", "g_ord.Q"))
})

# ---------------------------------------------------------------------------
# Part 2: live Julia.
# ---------------------------------------------------------------------------

fc_compare <- function(form, d, tol = 1e-4) {
  ft <- drmTMB(form, family = gaussian(), data = d, engine = "tmb")
  fj <- drmTMB(form, family = gaussian(), data = d, engine = "julia")
  ct <- unlist(fixef(ft))
  cj <- unlist(fixef(fj))
  list(
    names_tmb = names(ct), names_julia = names(cj),
    max_abs_coef_diff = if (identical(names(ct), names(cj))) max(abs(ct - cj)) else NA_real_,
    loglik_diff = abs(as.numeric(logLik(ft)) - as.numeric(logLik(fj))),
    raw = fj$bridge$raw_coef_names
  )
}

test_that("live G3/G4: engine = 'julia' name-matches engine = 'tmb' and agrees <= 1e-4 for factor()/I()/poly()/^/- (3-level non-alphabetical factor included)", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  d <- fc_data()
  for (nm in names(fc_constructs())) {
    res <- fc_compare(fc_constructs()[[nm]]$form, d)
    expect_identical(res$names_julia, res$names_tmb, info = nm)
    expect_lt(res$max_abs_coef_diff, 1e-4, label = paste0(nm, " max|coef diff|"))
    expect_lt(res$loglik_diff, 1e-4, label = paste0(nm, " |logLik diff|"))
  }
})

test_that("live G5 RED control: level order reversed on the Julia side only FAILS by name, not silently by number", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  d <- fc_data()
  form <- bf(y ~ x + g_fac, sigma ~ 1)
  payload <- drmTMB:::drm_julia_bridge_payload(
    form, family_type = "gaussian", data = d,
    env = environment(form$entries[[1L]]$formula), method = "ML"
  )
  expect_identical(payload$coef_labels$mu, c("(Intercept)", "x", "g_facmid", "g_fachigh"))
  # Same column count, same names on the R side; only Julia's design changes.
  payload$data$g_fac <- factor(as.character(payload$data$g_fac), levels = rev(levels(d$g_fac)))
  expect_error(
    drmTMB:::drm_julia_call_bridge(
      payload$formula, "gaussian", payload$data, payload$tree, payload$options
    ),
    "does not match the design DRM.jl built"
  )
  err <- tryCatch(
    drmTMB:::drm_julia_call_bridge(
      payload$formula, "gaussian", payload$data, payload$tree, payload$options
    ),
    error = function(e) conditionMessage(e)
  )
  # Both spellings are named: R's, and the one DRM.jl rendered from its own design.
  expect_match(err, "g_fachigh", fixed = TRUE)
  expect_match(err, "g_faclow", fixed = TRUE)
})

test_that("live: a character column whose R (locale) level order differs from Julia's codepoint order is refused, and declaring the factor in R restores parity", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  ok <- tryCatch({ withr::local_collate("en_US.UTF-8"); TRUE }, error = function(e) FALSE,
                 warning = function(w) FALSE)
  skip_if_not(ok, "en_US.UTF-8 collation not available")
  d <- fc_data()
  d$m_chr <- sample(c("Beta", "alpha", "gamma"), nrow(d), TRUE)
  r_levels <- levels(factor(d$m_chr))
  skip_if_not(
    !identical(r_levels, sort(unique(d$m_chr), method = "radix")),
    "collation here is codepoint order; nothing to disagree about"
  )
  expect_identical(r_levels, c("alpha", "Beta", "gamma"))
  expect_error(
    drmTMB(bf(y ~ x + m_chr, sigma ~ 1), family = gaussian(), data = d, engine = "julia"),
    "does not match the design DRM.jl built"
  )
  expect_error(
    drmTMB(bf(y ~ x + factor(m_chr), sigma ~ 1), family = gaussian(), data = d, engine = "julia"),
    "does not match the design DRM.jl built"
  )
  d$m_fac <- factor(d$m_chr)
  res <- fc_compare(bf(y ~ x + m_fac, sigma ~ 1), d)
  expect_identical(res$names_julia, res$names_tmb)
  expect_lt(res$max_abs_coef_diff, 1e-4)
})
