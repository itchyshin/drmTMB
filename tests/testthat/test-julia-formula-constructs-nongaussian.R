# A6 follow-through (design 258; DRM.jl #467/#609/#730): the formula-construct
# battery ran on ONE fixture -- Gaussian location-scale, fixed effects, mu and
# sigma. This file asks whether its classification holds off that fixture.
#
# The contract under test is not "the engines agree". It is: a construct is
# either FAITHFUL (identical base-R names AND coefficients within tolerance)
# or REFUSED. What must never happen is the third thing -- a fit that
# converges, returns identical names, and reports a coefficient that means
# something other than its label says. A user reading a summary table has no
# way to tell those apart, so this file fails on that case specifically.
#
# Measured 2026-09-05 at drmTMB origin/main 2fcbb0fbf against DRM.jl
# aee371cc9. The two shapes PR #1227 recorded as MISLABELLED_SILENT at the
# now-dead pin 430ef64cc are REFUSED at a live engine on the mu and sigma
# blocks of every family tried (poisson, nbinom2, binomial, gamma,
# cumulative_logit) -- DRM.jl's own `_bridge_check_coef_labels_fidelity`
# catches them there. It does NOT catch them on the location-scale-scale
# `sd(<group>)` block, which `_bridge_rendered_regression_blocks` skips by
# construction, and that route WAS silently mislabelled:
#
#   bf(y ~ x + (1 | study), sigma ~ z, sd(study) ~ s_chr)
#   logLik  tmb -69.917488  julia -69.917488  (diff 2.98e-13)
#   mu      max|coef diff| 2.12299e-11
#   sigma   max|coef diff| 5.19876e-12
#   sd      max|coef diff| 1.3853   s_chrBeta tmb 0.692648 julia -0.692648
#
# Two independent fixes close it: drmTMB's own
# `drm_julia_check_factor_level_fidelity()` (PR #1227), which refuses before
# Julia starts, and DRM.jl's `_bridge_check_lss_coef_labels_fidelity`
# (DRM.jl #730), the second line of defence for a disagreement the R data
# cannot show. The live case below states which of the two it needs.

fcn_data <- function(n = 200L, seed = 20260905L) {
  set.seed(seed)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  g_chr <- sample(c("low", "mid", "high"), n, TRUE)
  d <- data.frame(
    x = x, z = z, g_chr = g_chr,
    g_fac = factor(g_chr, levels = c("low", "mid", "high")),
    stringsAsFactors = FALSE
  )
  # A character column whose R level order under a Latin collation
  # ("alpha", "Beta", "gamma") is NOT the code-point order Julia sorts a
  # bare `Vector{String}` into ("Beta", "alpha", "gamma").
  d$m_chr <- sample(c("Beta", "alpha", "gamma"), n, TRUE)
  meff <- c(Beta = 0.5, alpha = -0.4, gamma = 0.2)
  # A declared factor level that no row uses: `model.matrix()` gives it an
  # all-zero column, DRM.jl codes only the levels it observes.
  d$g_empty <- factor(g_chr, levels = c("low", "mid", "high", "zz"))
  lin <- 0.3 + 0.5 * x + meff[d$m_chr]
  d$y <- lin + stats::rnorm(n, 0, 0.5)
  d$cnt <- stats::rpois(n, exp(0.4 + 0.3 * x + 0.5 * meff[d$m_chr]))
  d$nb <- stats::rnbinom(n, mu = exp(0.4 + 0.3 * x + 0.5 * meff[d$m_chr]), size = 3)
  d$bin <- stats::rbinom(n, 1L, stats::plogis(0.2 + 0.5 * x + meff[d$m_chr]))
  d$pos <- exp(lin + stats::rnorm(n, 0, 0.3))
  d$ord <- factor(
    cut(lin + stats::rnorm(n, 0, 0.5), 3L, labels = c("a", "b", "c")),
    ordered = TRUE
  )
  d
}

fcn_labels <- function(formula, data, family_type) {
  drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = formula, data = data, env = environment(), family_type = family_type
  )
}

# testthat sets `LC_COLLATE = "C"` for reproducible output, which is exactly
# the code-point order Julia uses -- so under the default test locale there
# is no disagreement left to measure and every case below would skip while
# reading green. Ask for a Latin collation explicitly, then verify the
# session actually took it; a session that cannot is a skip, not a pass.
fcn_local_latin_collation <- function(.local_envir = parent.frame()) {
  ok <- tryCatch({
    withr::local_collate("en_US.UTF-8", .local_envir = .local_envir)
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  isTRUE(ok)
}

fcn_collation_disagrees <- function(d) {
  !identical(levels(factor(d$m_chr)), sort(unique(d$m_chr), method = "radix"))
}

# ---------------------------------------------------------------------------
# Part 1: no Julia. The label producer is family-agnostic; pin that.
# ---------------------------------------------------------------------------

test_that("producer: non-Gaussian dpar shapes are labelled with base-R model.matrix() names", {
  d <- fcn_data()
  # poisson: dispersionless, `mu` only -- no sigma block may be invented.
  lab <- fcn_labels(bf(cnt ~ x + g_fac), d, "poisson")
  expect_identical(lab$mu, colnames(stats::model.matrix(~ x + g_fac, d)))
  expect_false("sigma" %in% names(lab))
  # nbinom2: mu + sigma, each labelled from its own formula.
  lab <- fcn_labels(bf(nb ~ x + g_fac, sigma ~ z), d, "nbinom2")
  expect_identical(lab$mu, colnames(stats::model.matrix(~ x + g_fac, d)))
  expect_identical(lab$sigma, colnames(stats::model.matrix(~z, d)))
  # cumulative_logit: `mu` only, with NO intercept -- the proportional-odds
  # cutpoints absorb it, and drmTMB moves them into `fit$ordinal` rather than
  # naming them as a dpar (design 258 section 8.9). The declared factor level
  # order survives that projection.
  lab <- fcn_labels(bf(ord ~ x + g_fac), d, "cumulative_logit")
  expect_identical(lab$mu, c("x", "g_facmid", "g_fachigh"))
  expect_false("(Intercept)" %in% lab$mu)
})

test_that("producer: a location-scale-scale sd(group) formula is labelled under the `sd` block key", {
  d <- fcn_data()
  d$study <- factor(rep(seq_len(20L), length.out = nrow(d)))
  d$study_z <- as.numeric(d$study) / 20
  lab <- fcn_labels(
    bf(y ~ x + (1 | study), sigma ~ z, sd(study) ~ g_fac), d, "gaussian"
  )
  # design 258: the per-call group name is stripped, so DRM.jl's block key is
  # `sd`. These are the names the echo pastes onto DRM.jl's own sd columns.
  expect_identical(lab$sd, colnames(stats::model.matrix(~g_fac, d)))
  expect_identical(lab$sd, c("(Intercept)", "g_facmid", "g_fachigh"))
})

# ---------------------------------------------------------------------------
# Part 2: live Julia. The contract, per fixture.
# ---------------------------------------------------------------------------

# Returns "REFUSED", "FAITHFUL", or "MISLABELLED_SILENT" -- plus the numbers,
# so a failure message says what was measured rather than only that it failed.
fcn_classify <- function(form, family, data, tol = 1e-4) {
  fj <- tryCatch(
    drmTMB(form, family = family, data = data, engine = "julia"),
    error = function(e) e
  )
  if (inherits(fj, "condition")) {
    return(list(verdict = "REFUSED", message = conditionMessage(fj)))
  }
  ft <- drmTMB(form, family = family, data = data, engine = "tmb")
  # `sd(<group>)` is drmTMB's dpar spelling for DRM.jl's `sd` block; compare
  # the blocks column-for-column rather than a flattened vector, so a dpar
  # renaming cannot mask a column-level disagreement.
  key <- function(x) sub("^sd\\(.*\\)$", "sd", x)
  bt <- stats::setNames(fixef(ft), key(names(fixef(ft))))
  bj <- stats::setNames(fixef(fj), key(names(fixef(fj))))
  shared <- intersect(names(bt), names(bj))
  worst <- 0
  for (k in shared) {
    if (!identical(names(bt[[k]]), names(bj[[k]]))) {
      return(list(verdict = "REFUSED", message = paste0("names differ in block ", k)))
    }
    worst <- max(worst, max(abs(bt[[k]] - bj[[k]])))
  }
  list(
    verdict = if (worst <= tol) "FAITHFUL" else "MISLABELLED_SILENT",
    worst = worst, blocks = shared,
    loglik_diff = abs(as.numeric(logLik(ft)) - as.numeric(logLik(fj)))
  )
}

fcn_expect_not_silent <- function(res, info) {
  expect_true(
    res$verdict %in% c("REFUSED", "FAITHFUL"),
    label = paste0(
      info, ": verdict ", res$verdict,
      if (identical(res$verdict, "MISLABELLED_SILENT")) {
        sprintf(" (max|coef diff| = %.6g over blocks %s; |logLik diff| = %.3g)",
                res$worst, paste(res$blocks, collapse = "/"), res$loglik_diff)
      } else ""
    )
  )
}

test_that("live: the two shapes recorded MISLABELLED_SILENT at the pin are never silent on a non-Gaussian mu/sigma block", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not(fcn_local_latin_collation(), "en_US.UTF-8 collation not available")
  d <- fcn_data()
  skip_if_not(fcn_collation_disagrees(d),
              "this session's collation is code-point order; nothing to disagree about")
  expect_identical(levels(factor(d$m_chr)), c("alpha", "Beta", "gamma"))
  cases <- list(
    list(tag = "poisson mu", form = bf(cnt ~ x + m_chr), fam = poisson()),
    list(tag = "nbinom2 mu", form = bf(nb ~ x + m_chr, sigma ~ 1), fam = nbinom2()),
    list(tag = "binomial mu", form = bf(bin ~ x + m_chr), fam = binomial()),
    list(tag = "gamma mu", form = bf(pos ~ x + m_chr, sigma ~ 1), fam = Gamma(link = "log")),
    list(tag = "cumulative_logit mu", form = bf(ord ~ x + m_chr), fam = cumulative_logit()),
    list(tag = "gaussian sigma side", form = bf(y ~ x, sigma ~ m_chr), fam = gaussian()),
    list(tag = "nbinom2 sigma side", form = bf(nb ~ x, sigma ~ m_chr), fam = nbinom2()),
    list(tag = "poisson unused level", form = bf(cnt ~ x + g_empty), fam = poisson()),
    list(tag = "nbinom2 unused level", form = bf(nb ~ x + g_empty, sigma ~ 1), fam = nbinom2()),
    list(tag = "gaussian sigma unused level", form = bf(y ~ x, sigma ~ g_empty), fam = gaussian())
  )
  for (cs in cases) {
    fcn_expect_not_silent(fcn_classify(cs$form, cs$fam, d), cs$tag)
  }
})

test_that("live: a declared factor stays FAITHFUL on every non-Gaussian route (the refusals above are not a blanket fence)", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  d <- fcn_data()
  controls <- list(
    list(tag = "poisson", form = bf(cnt ~ x + g_fac), fam = poisson()),
    list(tag = "nbinom2", form = bf(nb ~ x + g_fac, sigma ~ 1), fam = nbinom2()),
    list(tag = "cumulative_logit", form = bf(ord ~ x + g_fac), fam = cumulative_logit())
  )
  for (cs in controls) {
    res <- fcn_classify(cs$form, cs$fam, d)
    expect_identical(res$verdict, "FAITHFUL", label = paste0(cs$tag, " verdict"))
    expect_lt(res$worst, 1e-4, label = paste0(cs$tag, " max|coef diff|"))
  }
})

# The LSS fixture. Its `sd(<group>)` block is the one DRM.jl's own fidelity
# check skips by construction, so this is where the silent mislabel actually
# lived on 2026-09-05 -- see the header for the measured numbers.
fcn_lss_data <- function(n_study = 14L, n_each = 8L, seed = 2026090501L) {
  set.seed(seed)
  n <- n_study * n_each
  study <- factor(rep(seq_len(n_study), each = n_each))
  lab <- c("Beta", "alpha", "gamma")[rep_len(c(1L, 2L, 3L), n_study)]
  d <- data.frame(
    x = stats::rnorm(n), z = stats::rnorm(n), study = study,
    m_chr = rep(lab, each = n_each), stringsAsFactors = FALSE
  )
  d$m_fac <- factor(d$m_chr)
  study_sd <- exp(-1 + c(Beta = 0.5, alpha = -0.3, gamma = 0.1)[lab])
  d$y <- 0.10 + 0.40 * d$x + (study_sd * stats::rnorm(n_study))[study] +
    stats::rnorm(n, 0, exp(-1 + 0.15 * d$z))
  d
}

test_that("live: an LSS sd(group) formula over a collation-ambiguous character column is never silently mislabelled", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not(fcn_local_latin_collation(), "en_US.UTF-8 collation not available")
  d <- fcn_lss_data()
  skip_if_not(fcn_collation_disagrees(d),
              "this session's collation is code-point order; nothing to disagree about")
  expect_identical(levels(factor(d$m_chr)), c("alpha", "Beta", "gamma"))
  guarded_here <- is.function(
    tryCatch(drmTMB:::drm_julia_check_factor_level_fidelity, error = function(e) NULL)
  )
  guarded_engine <- isTRUE(tryCatch({
    drmTMB:::drm_julia_setup()
    JuliaCall::julia_eval("isdefined(DRM, :_bridge_check_lss_coef_labels_fidelity)")
  }, error = function(e) NA))
  skip_if_not(
    guarded_here || guarded_engine,
    paste(
      "needs drmTMB's drm_julia_check_factor_level_fidelity() (PR #1227) or",
      "DRM.jl's _bridge_check_lss_coef_labels_fidelity (DRM.jl #730);",
      "measured MISLABELLED_SILENT with neither, sd block max|coef diff| 1.3853"
    )
  )
  fcn_expect_not_silent(
    fcn_classify(bf(y ~ x + (1 | study), sigma ~ z, sd(study) ~ m_chr), gaussian(), d),
    "LSS sd(study) ~ <character column>"
  )
})

test_that("live: declaring the same LSS column as a factor in R restores parity (RED control of the refusal)", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  d <- fcn_lss_data()
  res <- fcn_classify(bf(y ~ x + (1 | study), sigma ~ z, sd(study) ~ m_fac), gaussian(), d)
  # The refusal above is specific to the level order, not to sd() formulas or
  # to this column: the same model with the level order declared must fit.
  expect_identical(res$verdict, "FAITHFUL")
  expect_true("sd" %in% res$blocks)
  expect_lt(res$worst, 1e-4)
  res_int <- fcn_classify(bf(y ~ x + (1 | study), sigma ~ z, sd(study) ~ 1), gaussian(), d)
  expect_identical(res_int$verdict, "FAITHFUL")
})
