# The Julia-bridge FAMILY REGISTRY -- one row per family, the single place that
# says what the bridge knows about a family.
#
# WHY THIS FILE EXISTS (A0.5, 2026-09-05). The bridge's family knowledge was
# spread over six hand-maintained character vectors in R/julia-bridge.R
# (the fixed-effect admission list inside drm_julia_family_tag(), and
# drm_julia_{phylo_only,locscale_phylo,slope_phylo,dispersionless,
# structured}_families()). Adding one family meant editing up to six lists in
# one 6,000-line file, so nine families being added in parallel would have
# collided on every edit. Now each family is ONE ROW here, the six lists are
# DERIVED from the rows, and a new family is a one-row addition.
#
# Column meanings (all logical unless stated):
#   family        drmTMB family_type string, i.e. drm_family_type(family)$family
#   fe            admitted on the fixed-effect (Workflow G) route with no
#                 structured term -- the old `wfg_fe` list
#   phylo_only    admitted ONLY with a phylo(1 | g) random intercept (DRM.jl's
#                 sparse all-node Laplace is the large-p edge; a plain GLM stays
#                 on TMB)
#   locscale_phylo  supports the coupled mu + sigma phylo route (cluster 4)
#   slope_phylo   supports the structured-slope phylo route (cluster 3)
#   dispersionless  no free dispersion/shape dpar for the label defaulter to
#                 add (poisson, binomial)
#   structured    admitted with relmat()/animal()/spatial() markers
#   drmjl_tag     the string DRM.jl's _bridge_family() accepts (NA = the Julia
#                 bridge has no case for it yet; the family CANNOT be admitted
#                 on the R side until it does)
#
# INVARIANT: every list function below must return EXACTLY what its
# hand-maintained predecessor returned on 2026-09-05 (pinned by
# tests/testthat/test-julia-family-registry.R). Behaviour change is A4's job,
# one family per PR, never this file's.
drm_julia_family_registry <- function() {
  spec <- function(family, fe = FALSE, phylo_only = FALSE, locscale_phylo = FALSE,
                   slope_phylo = FALSE, dispersionless = FALSE, structured = FALSE,
                   drmjl_tag = family) {
    list(family = family, fe = fe, phylo_only = phylo_only,
         locscale_phylo = locscale_phylo, slope_phylo = slope_phylo,
         dispersionless = dispersionless, structured = structured,
         drmjl_tag = drmjl_tag)
  }
  list(
    # ---- admitted today (byte-for-byte the 2026-09-05 lists) ----------------
    spec("gaussian",     fe = TRUE, locscale_phylo = TRUE, structured = TRUE),
    spec("biv_gaussian", fe = TRUE),
    spec("student",      fe = TRUE),
    spec("lognormal",    fe = TRUE),
    spec("poisson",      fe = TRUE, phylo_only = TRUE, slope_phylo = TRUE,
                         dispersionless = TRUE, structured = TRUE),
    spec("nbinom2",      fe = TRUE, phylo_only = TRUE, locscale_phylo = TRUE,
                         slope_phylo = TRUE, structured = TRUE),
    spec("gamma",        fe = TRUE, phylo_only = TRUE, locscale_phylo = TRUE,
                         slope_phylo = TRUE, structured = TRUE),
    spec("beta",         fe = TRUE, phylo_only = TRUE, locscale_phylo = TRUE,
                         slope_phylo = TRUE),
    spec("binomial",     fe = TRUE, phylo_only = TRUE, dispersionless = TRUE),
    # ---- A4 admissions: one row per family, each its own PR -----------------
    # truncated_nbinom2 (A4, 2026-09-05): fixed effects only, dpars mu + sigma,
    # the SAME size = 1/sigma^2 parameterisation as nbinom2 on both sides
    # (DRM.jl src/negbinomial.jl `TruncatedNegBinomial2`, pin 430ef64cc, which
    # refuses random effects itself: "currently supports fixed effects only").
    # No phylo/RE/structured admission here -- that is a later row.
    spec("truncated_nbinom2", fe = TRUE),
    # zero_one_beta (A4, 2026-09-05): fixed effects only, dpars mu (logit) +
    # sigma (log, phi = 1/sigma^2) + zoi (logit) + coi (logit) -- the SAME
    # three-part mixture on both sides (DRM.jl src/zeroonebeta.jl
    # `ZeroOneBeta`, pin 430ef64cc, which refuses random effects itself:
    # "currently supports fixed effects only"). No phylo/RE/structured
    # admission here -- that is a later row. No family-specific payload or
    # label code is needed: `julia_bridge_supported_dpars()` and
    # `drm_julia_bridge_blocks()` already carry zoi/coi.
    spec("zero_one_beta", fe = TRUE),
    # tweedie (A4, 2026-09-05): fixed effects ONLY (mu, sigma, nu). DRM.jl
    # src/tweedie.jl at pin 430ef64cc uses the same parameterisation as
    # R/family.R (log mu; sigma = sqrt(phi); nu = 1 + plogis(eta), the
    # "logit12" link), so no payload/label code is needed. No phylo, no RE,
    # no structured route here -- that is a later row.
    spec("tweedie",      fe = TRUE),
    # ---- A4 admissions, one row per PR ---------------------------------------
    # skew_normal (dpars mu, sigma, nu): fixed effects only -- DRM.jl's
    # SkewNormal() refuses every random effect and structured marker, and the
    # public moment parameterisation (mu = E[y], sigma = SD[y], nu = slant)
    # is the same on both sides, so bridged coefficients are the native ones.
    # DRM.jl's _bridge_family() case for the "skew_normal" tag is DRM.jl
    # PR #641 (A4, 2026-09-05); pin 430ef64cc lacks it and refuses at the
    # Julia boundary ("drm_bridge: unsupported family `skew_normal`").
    spec("skew_normal",  fe = TRUE)
    # ---- NOT admitted today: A4 adds one row per family, each its own PR ----
    # Julia bridge ALREADY accepts (drmTMB refuses alone):
    #   beta_binomial, cumulative_logit
    # Julia bridge has NO case yet (needs DRM.jl src/bridge.jl too):
    #   zi_poisson, zi_nbinom2, hurdle_nbinom2
  )
}

drm_julia_registry_families <- function(column) {
  reg <- drm_julia_family_registry()
  vapply(reg[vapply(reg, function(s) isTRUE(s[[column]]), logical(1L))],
         `[[`, character(1L), "family")
}
