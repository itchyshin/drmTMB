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
    # ---- A4 admissions (one row per PR, each with its own receipts) ---------
    # beta_binomial (A4, 2026-09-05): fixed-effect route ONLY. drmTMB dpars
    # mu/sigma, response cbind(successes, failures); DRM.jl's BetaBinomial uses
    # the SAME sigma mapping (phi = 1/sigma^2, src/betabinomial.jl at
    # 430ef64cc), and its bridge ships `trials` as per-row context, not a
    # dpar. phylo_only stays FALSE on purpose: DRM.jl's BetaBinomial phylo
    # route is constant-sigma only and has no bridge receipt yet -- a later row.
    spec("beta_binomial", fe = TRUE)
    # ---- NOT admitted today: A4 adds one row per family, each its own PR ----
    # Julia bridge ALREADY accepts (drmTMB refuses alone):
    #   truncated_nbinom2, zero_one_beta, tweedie, cumulative_logit
    # Julia bridge has NO case yet (needs DRM.jl src/bridge.jl too):
    #   zi_poisson, zi_nbinom2, hurdle_nbinom2, skew_normal
  )
}

drm_julia_registry_families <- function(column) {
  reg <- drm_julia_family_registry()
  vapply(reg[vapply(reg, function(s) isTRUE(s[[column]]), logical(1L))],
         `[[`, character(1L), "family")
}
