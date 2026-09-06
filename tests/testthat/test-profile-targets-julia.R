# #1156: profile_targets() on an `engine = "julia"` fit listed only the
# phylogenetic SD row, while the same TMB fit listed every fixed effect too --
# even though confint() on the Julia fit accepted the fixed-effect names in
# full. Discovery now returns the union the engine accepts.

# Synthetic Julia fit (no Julia needed): the same shape as
# tests/testthat/test-julia-inference.R's payload fixture.
drm_profile_targets_julia_fixture <- function(with_payload = TRUE) {
  tree <- structure(
    list(
      edge = matrix(c(7, 5, 7, 6, 5, 1, 5, 2, 6, 3, 6, 4), ncol = 2, byrow = TRUE),
      edge.length = rep(1, 6),
      tip.label = paste0("sp_", 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
  coef_names <- c("mu_(Intercept)", "mu_x", "sigma_(Intercept)", "resd_species")
  V <- diag(c(0.04, 0.01, 0.02, NA_real_))
  dimnames(V) <- list(coef_names, coef_names)
  result <- list(
    coef_names = coef_names,
    coefficients = c(0.1, 0.4, -0.2, log(1.7)),
    vcov = V,
    loglik = -12.5, aic = 33, bic = 35, df = 4L, nobs = 6L, converged = TRUE,
    fitted = seq_len(6), residuals = rep(0.1, 6), sigma = rep(0.8, 6),
    corpairs = list()
  )
  dat <- data.frame(
    y = seq_len(6), x = seq_len(6),
    species = paste0("sp_", c(1, 1, 2, 3, 3, 4))
  )
  form <- bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
  payload <- if (with_payload) {
    list(
      formula = list(mu = "y ~ x + phylo(1 | species)", sigma = "sigma ~ 1"),
      data = dat,
      tree = "((sp_1:1,sp_2:1):1,(sp_3:1,sp_4:1):1);",
      options = list(g_tol = 1e-4),
      structured_sd_scales = c("phylo(1 | species)" = sqrt(2))
    )
  } else {
    NULL
  }
  drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = gaussian(),
    data = dat,
    family_type = "gaussian",
    structured_sd_scales = c("phylo(1 | species)" = sqrt(2)),
    bridge_payload = payload
  )
}

test_that("profile_targets() on a Julia fit lists the union the engine accepts", {
  fit <- drm_profile_targets_julia_fixture()
  targets <- profile_targets(fit)

  # Native row order: fixed effects (mu, then sigma), the response-scale
  # sigma alias, then the random-effect SD. Five names, not one.
  expect_equal(
    targets$parm,
    c(
      "fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)",
      "sigma", "sd:mu:phylo(1 | species)"
    )
  )
  expect_equal(
    targets$target_class,
    c(
      "fixed-effect", "fixed-effect", "fixed-effect",
      "distributional-scale", "random-effect-sd"
    )
  )
  expect_false(anyDuplicated(targets$parm) > 0L)

  # The union must be exactly what confint() builds internally: the SD
  # inventory plus the fixed-effect inventory, plus the Wald-only sigma alias.
  expect_setequal(
    targets$parm,
    c(
      drmTMB:::drm_julia_profile_targets(fit)$parm,
      drmTMB:::drm_julia_wald_targets(fit)$parm,
      drmTMB:::drm_julia_wald_scale_targets(fit)$parm
    )
  )

  # Readiness is inherited row by row: fixed effects and the SD are ready
  # with a bridge payload; the sigma alias stays Wald-only, as
  # drm_julia_wald_confint() reports it.
  expect_equal(targets$profile_ready, c(TRUE, TRUE, TRUE, FALSE, TRUE))
  expect_equal(targets$profile_note[targets$parm == "sigma"], "missing_tmb_parameter")
  ready <- profile_targets(fit, ready_only = TRUE)
  expect_equal(
    ready$parm,
    c("fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)", "sd:mu:phylo(1 | species)")
  )

  # The SD row itself is unchanged by the union.
  sd_row <- targets[targets$parm == "sd:mu:phylo(1 | species)", , drop = FALSE]
  expect_equal(sd_row$tmb_parameter, "resd")
  expect_equal(sd_row$estimate, 1.7 * sqrt(2), tolerance = 1e-12)
  expect_equal(sd_row$link_estimate, log(1.7), tolerance = 1e-12)
})

test_that("the Julia target union does not widen drm_julia_profile_targets() itself", {
  # drm_julia_confint() rbind()s drm_julia_profile_targets() with the
  # fixed-effect rows; widening the SD inventory would duplicate those rows and
  # make the one-target validator reject a valid parm.
  fit <- drm_profile_targets_julia_fixture()
  sd_only <- drmTMB:::drm_julia_profile_targets(fit)
  expect_equal(sd_only$parm, "sd:mu:phylo(1 | species)")
  expect_equal(nrow(sd_only), 1L)
})

test_that("a payload-less Julia fit lists the same names, all not ready", {
  fit <- drm_profile_targets_julia_fixture(with_payload = FALSE)
  targets <- profile_targets(fit)
  expect_equal(
    targets$parm,
    c(
      "fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)",
      "sigma", "sd:mu:phylo(1 | species)"
    )
  )
  expect_false(any(targets$profile_ready))
  expect_equal(nrow(profile_targets(fit, ready_only = TRUE)), 0L)
})

test_that("a Julia fit with no coefficient blocks and no SD lists no targets", {
  fit <- drm_profile_targets_julia_fixture()
  fit$coefficients <- list()
  fit$coef_vector <- numeric(0)
  fit$sdpars <- list()
  targets <- profile_targets(fit)
  expect_equal(nrow(targets), 0L)
  expect_s3_class(targets, "data.frame")
})

test_that("live: a Julia fit lists the TMB fit's targets and every ready one profiles", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("ape")

  set.seed(202606L)
  n_tip <- 32L
  tree <- ape::rcoal(n_tip)
  sp <- tree$tip.label
  x <- stats::rnorm(n_tip)
  bm_mu <- ape::rTraitCont(tree, model = "BM", sigma = 0.5)
  y <- stats::rnorm(n_tip, mean = 0.3 + 0.4 * x + bm_mu[sp], sd = exp(-0.2))
  dat <- data.frame(species = sp, x = x, y = y, stringsAsFactors = FALSE)
  form <- bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)

  fit_tmb <- drmTMB(form, family = gaussian(), data = dat, engine = "tmb")
  fit_julia <- drmTMB(form, family = gaussian(), data = dat, engine = "julia")

  tmb_targets <- profile_targets(fit_tmb)
  julia_targets <- profile_targets(fit_julia)

  # Name-matched on every non-derived target. The native fit additionally
  # lists a derived-summary phylo_total_variance_share row the bridge has no
  # counterpart for; nothing on the Julia side is absent from TMB.
  expect_equal(
    tmb_targets$parm[tmb_targets$target_class == "derived-summary"],
    "derived:phylo_total_variance_share(species)"
  )
  tmb_direct <- tmb_targets$parm[tmb_targets$target_class != "derived-summary"]
  expect_equal(julia_targets$parm, tmb_direct)
  expect_length(julia_targets$parm, 5L)
  expect_equal(setdiff(julia_targets$parm, tmb_targets$parm), character(0))

  # Every ready target is accepted by the engine and returns a finite
  # likelihood-ratio interval.
  ready <- julia_targets$parm[julia_targets$profile_ready]
  expect_true("fixef:mu:x" %in% ready)
  for (p in ready) {
    ci <- stats::confint(fit_julia, parm = p, method = "profile", threads = FALSE)
    expect_equal(ci$parm, p)
    expect_equal(ci$conf.status, "profile", info = p)
    expect_true(is.finite(ci$lower) && is.finite(ci$upper), info = p)
    expect_lt(ci$lower, ci$upper, label = p)
  }
})

# ---------------------------------------------------------------------------
# #1156, the two halves the issue's own fix did not close. MEASURED live
# 2026-09-05 at DRM.jl pin 430ef64cc, one Gaussian 32-tip fit of
#   bf(y ~ x + phylo(1 | species, tree), sigma ~ 1,
#      sd(species, level = "phylogenetic") ~ z)
# on BOTH engines (log: inst/parity/p1156-live-measure.log):
#
#   TMB   profile_targets(): fixef:mu:(Intercept), fixef:mu:x,
#         fixef:sigma:(Intercept), fixef:sd_phylo(species):(Intercept),
#         fixef:sd_phylo(species):z, sigma, + 32 per-tip sd: rows
#   Julia profile_targets(): fixef:mu:(Intercept), fixef:mu:x,
#         fixef:sd_phylo:(Intercept), fixef:sd_phylo:z,
#         fixef:sigma:(Intercept), sigma
#
#   (a) CLOSURE was already TRUE at that pin: setdiff(accepted, listed) and
#       setdiff(listed, accepted) were both character(0) under Wald. It is
#       untested, though, so it is one merge away from regressing -- hence
#       the closure tests below, which fail if any accepted name is unlisted.
#   (b) NAMING divergence STOOD: each engine refused the other's spelling of
#       the same estimand, whose Wald interval agrees to six significant
#       figures ([0.1548585, 0.5961239] Julia vs [0.1548584, 0.5961240] TMB).
#   (c) A LISTED row was reported as UNKNOWN: confint(julia, "sigma",
#       method = "profile") answered `Unknown confidence-interval target:
#       "sigma"` while profile_targets() was printing that very name.
# ---------------------------------------------------------------------------

# Synthetic Julia location-scale-scale fit (no Julia needed). Shape pinned to
# the live fit measured above: coefficient blocks mu / sd_phylo / sigma, vcov
# rows named <dpar>_<term>, and a formula whose third entry's dpar is the
# canonical native string "sd_phylo(species)".
drm_profile_targets_julia_lss_fixture <- function() {
  tree <- structure(
    list(
      edge = matrix(c(7, 5, 7, 6, 5, 1, 5, 2, 6, 3, 6, 4), ncol = 2, byrow = TRUE),
      edge.length = rep(1, 6),
      tip.label = paste0("sp_", 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
  coef_names <- c(
    "mu_(Intercept)", "mu_x", "sd_phylo_(Intercept)", "sd_phylo_z",
    "sigma_(Intercept)"
  )
  V <- diag(c(0.04, 0.01, 0.09, 0.0225, 0.02))
  dimnames(V) <- list(coef_names, coef_names)
  result <- list(
    coef_names = coef_names,
    coefficients = c(0.2, 0.5, -0.055, 0.3455, -0.4),
    vcov = V,
    loglik = -14.5, aic = 39, bic = 41, df = 5L, nobs = 6L, converged = TRUE,
    fitted = seq_len(6), residuals = rep(0.1, 6), sigma = rep(0.8, 6),
    corpairs = list()
  )
  dat <- data.frame(
    y = seq_len(6), x = seq_len(6), z = c(0.1, -0.2, 0.3, -0.4, 0.5, -0.6),
    species = paste0("sp_", c(1, 1, 2, 3, 3, 4))
  )
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1,
    sd(species, level = "phylogenetic") ~ z
  )
  drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = gaussian(),
    data = dat,
    family_type = "gaussian",
    structured_sd_scales = c("phylo(1 | species)" = sqrt(2)),
    bridge_payload = list(
      formula = list(
        mu = "y ~ x + phylo(1 | species)",
        sigma = "sigma ~ 1",
        sd_phylo = "sd_phylo ~ z"
      ),
      data = dat,
      tree = "((sp_1:1,sp_2:1):1,(sp_3:1,sp_4:1):1);",
      options = list(g_tol = 1e-4),
      structured_sd_scales = c("phylo(1 | species)" = sqrt(2))
    )
  )
}

# Candidate target names built WITHOUT consulting the union implementation:
# from the fit's own coefficient blocks, from the formula's dpars in their
# canonical native spelling, from the bare dpar names, plus names that are
# targets under no spelling at all.
drm_profile_targets_julia_candidates <- function(fit) {
  blocks <- fit$coefficients
  terms_seen <- unique(unlist(lapply(blocks, names), use.names = FALSE))
  from_coef <- unlist(
    lapply(names(blocks), function(dpar) paste0("fixef:", dpar, ":", names(blocks[[dpar]]))),
    use.names = FALSE
  )
  formula_dpars <- vapply(
    fit$formula$entries,
    function(entry) as.character(entry$dpar)[[1L]],
    character(1L)
  )
  from_formula <- unlist(
    lapply(formula_dpars, function(dpar) paste0("fixef:", dpar, ":", terms_seen)),
    use.names = FALSE
  )
  junk <- c(
    "x", "mu_x", "fixef:mu:not_a_term", "fixef:not_a_dpar:x",
    "sd:mu:phylo(1 | species)", "derived:phylo_total_variance_share(species)"
  )
  unique(c(from_coef, from_formula, names(blocks), formula_dpars, junk))
}

# Every canonical native spelling this fit documents as an accepted alias.
drm_profile_targets_julia_alias_inputs <- function(fit, listed) {
  aliases <- drmTMB:::drm_julia_lss_dpar_aliases(fit)
  if (length(aliases) == 0L) {
    return(character(0))
  }
  out <- unlist(lapply(seq_along(aliases), function(i) {
    prefix <- paste0("fixef:", aliases[[i]], ":")
    hit <- listed[startsWith(listed, prefix)]
    if (length(hit) == 0L) {
      return(character(0))
    }
    paste0("fixef:", names(aliases)[[i]], ":", substring(hit, nchar(prefix) + 1L))
  }), use.names = FALSE)
  unique(out)
}

# Probe every candidate under Wald and report BOTH what the engine accepted as
# input and what row it reported back.
drm_profile_targets_julia_probe <- function(fit, candidates) {
  inputs <- character(0)
  reported <- character(0)
  for (p in candidates) {
    ci <- tryCatch(
      stats::confint(fit, parm = p, method = "wald"),
      error = function(cnd) NULL
    )
    if (!is.null(ci) && nrow(ci) > 0L) {
      inputs <- c(inputs, p)
      reported <- c(reported, as.character(ci$parm))
    }
  }
  list(inputs = unique(inputs), reported = unique(reported))
}

test_that("profile_targets() closes over what confint() accepts (phylo fit)", {
  fit <- drm_profile_targets_julia_fixture()
  listed <- profile_targets(fit)$parm
  candidates <- drm_profile_targets_julia_candidates(fit)
  expect_gt(length(candidates), length(listed))

  seen <- drm_profile_targets_julia_probe(fit, candidates)

  # The assertion this leaf exists for: nothing the engine hands back may be
  # absent from the documented discovery route.
  expect_equal(setdiff(seen$reported, listed), character(0))
  # And no undocumented input name is quietly accepted either. This fit has
  # no sd()/sd_phylo() submodel, so it documents no aliases at all.
  expect_equal(drmTMB:::drm_julia_lss_dpar_aliases(fit), character(0))
  expect_equal(setdiff(seen$inputs, listed), character(0))
  # Non-vacuous.
  expect_true(all(c("fixef:mu:x", "sigma") %in% seen$reported))
})

test_that("profile_targets() closes over what confint() accepts (location-scale-scale fit)", {
  fit <- drm_profile_targets_julia_lss_fixture()
  listed <- profile_targets(fit)$parm

  # Pinned to the live fit measured at DRM.jl 430ef64cc: six rows, the
  # bridge's own short sd_phylo spelling, and no sd: row (the bridge reports
  # no scalar phylogenetic SD once that SD carries its own submodel).
  expect_equal(
    listed,
    c(
      "fixef:mu:(Intercept)", "fixef:mu:x",
      "fixef:sd_phylo:(Intercept)", "fixef:sd_phylo:z",
      "fixef:sigma:(Intercept)", "sigma"
    )
  )

  seen <- drm_profile_targets_julia_probe(
    fit,
    drm_profile_targets_julia_candidates(fit)
  )
  expect_equal(setdiff(seen$reported, listed), character(0))
  expect_true("fixef:sd_phylo:z" %in% seen$reported)

  # Every accepted INPUT is either a listed name or a documented canonical
  # alias of one -- no third spelling sneaks in.
  documented <- c(
    listed,
    drm_profile_targets_julia_alias_inputs(fit, listed)
  )
  expect_equal(setdiff(seen$inputs, documented), character(0))
  expect_true("fixef:sd_phylo(species):z" %in% seen$inputs)
})

test_that("the canonical native location-scale-scale name is accepted on a Julia fit", {
  fit <- drm_profile_targets_julia_lss_fixture()

  # The canonical native name and the bridge's own name select the SAME row
  # and return the SAME interval; the reported parm is the bridge's name,
  # which is what profile_targets() lists.
  native <- stats::confint(fit, parm = "fixef:sd_phylo(species):z", method = "wald")
  bridge <- stats::confint(fit, parm = "fixef:sd_phylo:z", method = "wald")
  expect_equal(native$parm, "fixef:sd_phylo:z")
  expect_equal(native$parm, bridge$parm)
  expect_equal(native$lower, bridge$lower)
  expect_equal(native$upper, bridge$upper)

  # The intercept of the same submodel too.
  expect_equal(
    stats::confint(fit, parm = "fixef:sd_phylo(species):(Intercept)", method = "wald")$parm,
    "fixef:sd_phylo:(Intercept)"
  )

  # The alias is a rewrite onto a real target, not a wildcard: a
  # canonical-shaped name whose term is not a coefficient stays refused, and
  # the message quotes what the user typed rather than a rewritten variant.
  err <- tryCatch(
    stats::confint(fit, parm = "fixef:sd_phylo(species):nope", method = "wald"),
    error = conditionMessage
  )
  expect_match(err, "fixef:sd_phylo(species):nope", fixed = TRUE)
  expect_false(grepl("fixef:sd_phylo:nope", err, fixed = TRUE))

  # The alias map is derived from the formula, and is empty for a fit with no
  # sd()/sd_phylo() submodel.
  expect_equal(
    drmTMB:::drm_julia_lss_dpar_aliases(fit),
    c("sd_phylo(species)" = "sd_phylo")
  )
  expect_equal(
    drmTMB:::drm_julia_lss_dpar_aliases(drm_profile_targets_julia_fixture()),
    character(0)
  )
})

test_that("an ambiguous location-scale-scale block key yields no alias", {
  # bf() accepts two sd() submodels on different grouping factors, and BOTH
  # reduce to the bridge block key `sd` -- so a canonical name could not be
  # resolved to one coefficient. The alias map must fail closed rather than
  # answer for whichever group came first. Unit test of the pure helper: it
  # reads only $formula$entries and $coefficients.
  ambiguous <- bf(y ~ x + (1 | g1) + (1 | g2), sigma ~ 1, sd(g1) ~ z, sd(g2) ~ w)
  expect_equal(
    vapply(ambiguous$entries, function(e) as.character(e$dpar)[[1L]], character(1L)),
    c("mu", "sigma", "sd(g1)", "sd(g2)")
  )
  probe <- list(
    formula = ambiguous,
    coefficients = list(
      mu = c("(Intercept)" = 0.1, x = 0.2),
      sigma = c("(Intercept)" = -0.3),
      sd = c("(Intercept)" = -0.4, z = 0.5)
    )
  )
  expect_equal(drmTMB:::drm_julia_lss_dpar_aliases(probe), character(0))

  # One unambiguous submodel on the same shape still maps.
  single <- bf(y ~ x + (1 | g1), sigma ~ 1, sd(g1) ~ z)
  probe$formula <- single
  expect_equal(
    drmTMB:::drm_julia_lss_dpar_aliases(probe),
    c("sd(g1)" = "sd")
  )
})

test_that("a listed-but-not-dispatchable target is not reported as unknown", {
  fit <- drm_profile_targets_julia_fixture()

  # `sigma` IS in the inventory (profile_ready = FALSE, note
  # missing_tmb_parameter) but DRM.jl has no profile/bootstrap entry point for
  # it. Measured at the pin, confint(..., method = "profile") called it
  # `Unknown confidence-interval target`, contradicting profile_targets().
  expect_true("sigma" %in% profile_targets(fit)$parm)
  msg <- tryCatch(
    stats::confint(fit, parm = "sigma", method = "profile"),
    error = conditionMessage
  )
  expect_type(msg, "character")
  # cli wraps the hint at console width, so a target name can be split across
  # lines; match against a whitespace-normalised copy rather than pinning the
  # width this suite happens to run at.
  flat <- gsub("[[:space:]]+", " ", paste(msg, collapse = " "))
  expect_false(grepl("Unknown confidence-interval target", flat, fixed = TRUE))
  expect_match(flat, "profile_targets", fixed = TRUE)
  expect_match(flat, "missing_tmb_parameter", fixed = TRUE)
  # It names the profile-ready alias to use instead, and lists the valid names.
  expect_match(flat, "fixef:sigma:(Intercept)", fixed = TRUE)
  expect_match(flat, "fixef:mu:x", fixed = TRUE)

  # A name that really is in no inventory keeps the unknown-target message,
  # which already lists the valid names.
  msg2 <- tryCatch(
    stats::confint(fit, parm = "fixef:mu:not_a_term", method = "profile"),
    error = conditionMessage
  )
  expect_match(msg2, "Unknown confidence-interval target", fixed = TRUE)

  # Wald still serves the alias row, unchanged.
  expect_equal(stats::confint(fit, parm = "sigma", method = "wald")$parm, "sigma")
})

test_that("live: a Julia location-scale-scale fit takes the canonical name and its inventory closes", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("ape")

  set.seed(202606L)
  n_tip <- 32L
  tree <- ape::rcoal(n_tip)
  sp <- tree$tip.label
  x <- stats::rnorm(n_tip)
  z <- stats::rnorm(n_tip)
  sd_sp <- exp(-0.3 + 0.4 * z)
  u <- sd_sp * drop(t(chol(ape::vcv(tree)[sp, sp])) %*% stats::rnorm(n_tip))
  y <- 0.2 + 0.5 * x + u + stats::rnorm(n_tip, sd = exp(-0.4))
  dat <- data.frame(species = sp, x = x, z = z, y = y, stringsAsFactors = FALSE)
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1,
    sd(species, level = "phylogenetic") ~ z
  )

  fit_tmb <- drmTMB(form, family = gaussian(), data = dat, engine = "tmb")
  fit_jl <- drmTMB(form, family = gaussian(), data = dat, engine = "julia")

  # The divergence this test pins: the two engines REPORT the same estimand
  # under different names. That is a documented contract (design 258 sec. 9),
  # not a bug to paper over.
  expect_true("fixef:sd_phylo(species):z" %in% profile_targets(fit_tmb)$parm)
  expect_true("fixef:sd_phylo:z" %in% profile_targets(fit_jl)$parm)
  expect_false("fixef:sd_phylo(species):z" %in% profile_targets(fit_jl)$parm)
  expect_false("fixef:sd_phylo:z" %in% profile_targets(fit_tmb)$parm)

  # ... and the bridge nonetheless ACCEPTS the canonical native name, so one
  # script runs on both engines. Same estimand, same interval.
  native <- stats::confint(fit_jl, parm = "fixef:sd_phylo(species):z", method = "wald")
  bridge <- stats::confint(fit_jl, parm = "fixef:sd_phylo:z", method = "wald")
  tmb_ci <- stats::confint(fit_tmb, parm = "fixef:sd_phylo(species):z", method = "wald")
  expect_equal(native$parm, "fixef:sd_phylo:z")
  expect_equal(native$lower, bridge$lower)
  expect_equal(native$upper, bridge$upper)
  expect_equal(bridge$lower, tmb_ci$lower, tolerance = 1e-5)
  expect_equal(bridge$upper, tmb_ci$upper, tolerance = 1e-5)

  # Closure on a real fit: every reported row is listed, and every accepted
  # input is a listed name or a documented alias.
  listed <- profile_targets(fit_jl)$parm
  seen <- drm_profile_targets_julia_probe(
    fit_jl,
    drm_profile_targets_julia_candidates(fit_jl)
  )
  expect_equal(setdiff(seen$reported, listed), character(0))
  expect_equal(
    setdiff(
      seen$inputs,
      c(listed, drm_profile_targets_julia_alias_inputs(fit_jl, listed))
    ),
    character(0)
  )

  # Every profile-ready row profiles end to end on the engine; the one listed
  # row that is NOT ready explains itself instead of being called unknown.
  targets <- profile_targets(fit_jl)
  ready <- targets$parm[targets$profile_ready]
  expect_true(length(ready) > 0L)
  for (p in ready) {
    ci <- stats::confint(fit_jl, parm = p, method = "profile", threads = FALSE)
    expect_equal(ci$parm, p)
    expect_true(is.finite(ci$lower) && is.finite(ci$upper), info = p)
  }
  for (p in setdiff(listed, ready)) {
    msg <- tryCatch(
      stats::confint(fit_jl, parm = p, method = "profile", threads = FALSE),
      error = conditionMessage
    )
    expect_false(grepl("Unknown confidence-interval target", msg, fixed = TRUE), info = p)
  }
})
