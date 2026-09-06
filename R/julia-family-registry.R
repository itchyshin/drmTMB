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
#   predictor_dpars  (character, REQUIRED -- no default) which dpars this family
#                 may carry a PREDICTOR on through `engine = "julia"`. The
#                 sentinel "*" means "every dpar the family has"; any other value
#                 enumerates the admitted dpars, and every dpar outside the list
#                 must be intercept-only or the bridge refuses BEFORE Julia
#                 starts (`drm_julia_refuse_unadmitted_predictor_dpars()`).
#                 See the block comment on `drm_julia_family_predictor_dpars()`
#                 for the measurements that made this column necessary (#1224).
#   fe_fence_exempt  exempt from the A4.G17 fixed-effect-only random-effect
#                 fence. Replaces the `startsWith(family, "biv_")` PREFIX test
#                 that used to grant this exemption, which every future `biv_*`
#                 admission inherited without earning it (#1224).
#
# INVARIANT: every list function below must return EXACTLY what its
# hand-maintained predecessor returned on 2026-09-05 (pinned by
# tests/testthat/test-julia-family-registry.R). Behaviour change is A4's job,
# one family per PR, never this file's.
drm_julia_family_registry <- function() {
  spec <- function(family, predictor_dpars, fe = FALSE, phylo_only = FALSE,
                   locscale_phylo = FALSE, slope_phylo = FALSE,
                   dispersionless = FALSE, structured = FALSE,
                   fe_fence_exempt = FALSE, drmjl_tag = family) {
    # `predictor_dpars` has NO DEFAULT on purpose (#1224). The defect this
    # column closes was a scope exemption inherited SILENTLY by a new row; a
    # default would reinstate exactly that. A row added without it aborts here,
    # at registry-build time, which every gate and every test trips on at once.
    if (missing(predictor_dpars)) {
      cli::cli_abort(c(
        "Julia family registry row {.val {family}} does not declare {.arg predictor_dpars}.",
        i = "State {.val *} if every dpar of this family may carry a predictor on the Julia route, or enumerate the dpars that may. A dpar outside the list must be intercept-only.",
        i = "The declaration is per-FAMILY on purpose: it used to be inferred from the {.val biv_} name prefix, so every new bivariate family inherited an exemption it had not earned."
      ))
    }
    list(family = family, fe = fe, phylo_only = phylo_only,
         locscale_phylo = locscale_phylo, slope_phylo = slope_phylo,
         dispersionless = dispersionless, structured = structured,
         predictor_dpars = predictor_dpars, fe_fence_exempt = fe_fence_exempt,
         drmjl_tag = drmjl_tag)
  }
  list(
    # ---- admitted today (byte-for-byte the 2026-09-05 lists) ----------------
    spec("gaussian",     predictor_dpars = "*",
                         fe = TRUE, locscale_phylo = TRUE, structured = TRUE),
    # biv_gaussian is the ONE family that has EARNED a predictor on every
    # bivariate dpar, and it earned it by measurement, not by its name.
    # Measured 2026-09-05 on this branch's base (drmTMB 2fcbb0fbf, DRM.jl
    # aee371cc9, n = 200, seed 20260905): `sigma1 = ~ z` fits on BOTH engines
    # at logLik -560.53957076 (identical to 8 dp), and `rho12 = ~ z` fits
    # through engine = "julia" at -561.91857503. Enumerated rather than "*"
    # so that a LATER bivariate family cannot acquire this by copying a row.
    spec("biv_gaussian", predictor_dpars = c("mu1", "mu2", "sigma1", "sigma2", "rho12"),
                         fe = TRUE, fe_fence_exempt = TRUE),
    # student: measured 2026-09-05, `nu ~ z` FITS on both engines
    # (tmb -276.48331601, julia -276.48331602), so nothing to fence.
    spec("student",      predictor_dpars = "*", fe = TRUE),
    spec("lognormal",    predictor_dpars = "*", fe = TRUE),
    spec("poisson",      predictor_dpars = "*",
                         fe = TRUE, phylo_only = TRUE, slope_phylo = TRUE,
                         dispersionless = TRUE, structured = TRUE),
    spec("nbinom2",      predictor_dpars = "*",
                         fe = TRUE, phylo_only = TRUE, locscale_phylo = TRUE,
                         slope_phylo = TRUE, structured = TRUE),
    spec("gamma",        predictor_dpars = "*",
                         fe = TRUE, phylo_only = TRUE, locscale_phylo = TRUE,
                         slope_phylo = TRUE, structured = TRUE),
    spec("beta",         predictor_dpars = "*",
                         fe = TRUE, phylo_only = TRUE, locscale_phylo = TRUE,
                         slope_phylo = TRUE),
    spec("binomial",     predictor_dpars = "*",
                         fe = TRUE, phylo_only = TRUE, dispersionless = TRUE),
    # ---- A4 admissions: one row per family, each its own PR -----------------
    # truncated_nbinom2 (A4, 2026-09-05): fixed effects only, dpars mu + sigma,
    # the SAME size = 1/sigma^2 parameterisation as nbinom2 on both sides
    # (DRM.jl src/negbinomial.jl `TruncatedNegBinomial2`, pin 430ef64cc, which
    # refuses random effects itself: "currently supports fixed effects only").
    # No phylo/RE/structured admission here -- that is a later row.
    spec("truncated_nbinom2", predictor_dpars = "*", fe = TRUE),
    # zero_one_beta (A4, 2026-09-05): fixed effects only, dpars mu (logit) +
    # sigma (log, phi = 1/sigma^2) + zoi (logit) + coi (logit) -- the SAME
    # three-part mixture on both sides (DRM.jl src/zeroonebeta.jl
    # `ZeroOneBeta`, pin 430ef64cc, which refuses random effects itself:
    # "currently supports fixed effects only"). No phylo/RE/structured
    # admission here -- that is a later row. No family-specific payload or
    # label code is needed: `julia_bridge_supported_dpars()` and
    # `drm_julia_bridge_blocks()` already carry zoi/coi.
    # zero_one_beta: measured 2026-09-05, `zoi ~ z` FITS on both engines at
    # logLik -80.36706785 (identical), so no dpar needs fencing.
    spec("zero_one_beta", predictor_dpars = "*", fe = TRUE),
    # tweedie (A4, 2026-09-05): fixed effects ONLY (mu, sigma, nu). DRM.jl
    # src/tweedie.jl at pin 430ef64cc uses the same parameterisation as
    # R/family.R (log mu; sigma = sqrt(phi); nu = 1 + plogis(eta), the
    # "logit12" link), so no payload/label code is needed. No phylo, no RE,
    # no structured route here -- that is a later row.
    # NARROWED 2026-09-05 (#1224), on a MEASUREMENT taken while building this
    # column: `nu` is intercept-only on the native route
    # ("`tweedie()` currently supports only intercept-only `nu ~ 1`",
    # drm_build_tweedie_spec(), R/drmTMB.R), but `bf(y ~ x, sigma ~ 1, nu ~ z)`
    # FIT through engine = "julia" at logLik -259.84074955 while engine = "tmb"
    # REFUSED it (drmTMB 2fcbb0fbf, DRM.jl aee371cc9, n = 200, seed 20260905).
    # `nu ~ 1` still fits (-260.40627451), so the fence does not over-fire.
    # This is the same defect the bivariate prefix exemption produced, on a
    # UNIVARIATE family -- which is why the fix is a registry column and not a
    # bivariate special case.
    spec("tweedie",      predictor_dpars = c("mu", "sigma"), fe = TRUE),
    # beta_binomial (A4, 2026-09-05): fixed-effect route ONLY. drmTMB dpars
    # mu/sigma, response cbind(successes, failures); DRM.jl's BetaBinomial uses
    # the SAME sigma mapping (phi = 1/sigma^2, src/betabinomial.jl at
    # 430ef64cc), and its bridge ships `trials` as per-row context, not a
    # dpar. phylo_only stays FALSE on purpose: DRM.jl's BetaBinomial phylo
    # route is constant-sigma only and has no bridge receipt yet -- a later row.
    spec("beta_binomial", predictor_dpars = "*", fe = TRUE),
    # A4 (2026-09-05): cumulative_logit on the fixed-effect route. Its only dpar
    # is `mu` (R/family.R), so it is `dispersionless` like poisson/binomial: the
    # label defaulter must NOT invent a `sigma` block and a user-written
    # `sigma ~` formula is refused. Cutpoints are NOT a dpar on the R side --
    # R/julia-family-cumulative_logit.R moves DRM.jl's `cutpoints` block into
    # `fit$ordinal` (design 258 section 8.9). Fixed effects only: no phylo, RE,
    # or structured route (a later row's job).
    spec("cumulative_logit", predictor_dpars = "*",
                         fe = TRUE, dispersionless = TRUE),
    # biv_student (A4, 2026-09-05): drmTMB's exact shared-nu bivariate
    # Student-t, fixed-effect route ONLY. dpars mu1, mu2, sigma1, sigma2, one
    # shared nu, rho12 -- the SAME parameterisation on both sides: identity
    # mu1/mu2, log sigma1/sigma2 (SCALES, not marginal SDs), nu on the "logm2"
    # link nu = 2 + exp(eta), and a guarded-atanh rho12 SCATTER correlation
    # (R/family.R `biv_student()`; DRM.jl src/bivariate_student.jl at pin
    # 430ef64cc). Bivariate-ness is a FORMULA property in DRM.jl, so its
    # `_bridge_family()` maps this tag to `Student()` and the keyed mu1/mu2
    # parts select the bivariate route (src/bridge.jl). No phylo, RE, or
    # structured column: DRM.jl refuses structured markers on this route by
    # design ("residual-only"), and native drmTMB defers them too.
    spec("biv_student", predictor_dpars = c("mu1", "mu2"), fe = TRUE),
    # ---- A4 admissions, one row per PR ---------------------------------------
    # skew_normal (dpars mu, sigma, nu): fixed effects only -- DRM.jl's
    # SkewNormal() refuses every random effect and structured marker, and the
    # public moment parameterisation (mu = E[y], sigma = SD[y], nu = slant)
    # is the same on both sides, so bridged coefficients are the native ones.
    # DRM.jl's _bridge_family() case for the "skew_normal" tag is DRM.jl
    # PR #641 (A4, 2026-09-05); pin 430ef64cc lacks it and refuses at the
    # Julia boundary ("drm_bridge: unsupported family `skew_normal`").
    spec("skew_normal",  predictor_dpars = "*", fe = TRUE),
    # biv_lognormal (2026-09-05): the bivariate residual route only, dpars
    # mu1 + mu2 + sigma1 + sigma2 + rho12, fixed-effect mu1/mu2 with
    # intercept-only sigma1/sigma2/rho12 -- exactly the cell
    # drm_build_biv_lognormal_spec() (R/drmTMB.R) admits natively; it refuses
    # random, structured, meta_V, offset, and sigma/rho predictor terms itself,
    # so no phylo/structured column is set here.
    #
    # SCALE CONTRACT, the thing this row rests on. Both engines take the two
    # responses on the RAW positive scale and log them internally, so mu1/mu2
    # are means of log y (identity link), sigma1/sigma2 are SDs of log y (log
    # link), and rho12 is the LOG-residual correlation. Both also add the
    # parameter-free change-of-variables Jacobian -sum(log y1) - sum(log y2)
    # to the log-likelihood: drmTMB's TMB kernel does it in src/drmTMB.cpp
    # (model_type 19 adds weights(i) * (y1(i) + y2(i)) to the nll AFTER
    # spec$y1/spec$y2 have been logged), and DRM.jl does it in
    # src/bivariate_lognormal.jl `_lognormal_jacobian_shift` after delegating
    # the whole fit to the bivariate Gaussian kernel on logged data. The tag
    # `biv_lognormal` reaches DRM.jl's `_bridge_family` unchanged
    # (src/bridge.jl:634 at pin 430ef64cc -> `LogNormal()`; bivariate-ness is
    # a property of the FORMULA there, as for biv_gaussian).
    spec("biv_lognormal", predictor_dpars = c("mu1", "mu2"), fe = TRUE)
    # ---- NOT admitted today: A4 adds one row per family, each its own PR ----
    # Julia bridge has NO case yet (needs DRM.jl src/bridge.jl too):
    #   zi_poisson, zi_nbinom2, hurdle_nbinom2
    #
    # hurdle_nbinom2 is NOT on that list and needs NO row of its own: it is a
    # post-fit `model_type`, not a family_type. There is no `hurdle_nbinom2()`
    # constructor -- the native spelling is `family = truncated_nbinom2()` plus
    # an `hu ~ ...` entry, so the `truncated_nbinom2` row above already admits
    # it and `hu` is already in `julia_bridge_supported_dpars()`. The bridge
    # fit's model_type is corrected to "hurdle_nbinom2" by
    # `drm_julia_bridge_model_type()` (R/julia-bridge.R). The same is true of
    # zi_poisson / zi_nbinom2, which are `poisson()` / `nbinom2()` plus a
    # `zi ~ ...` entry; the line above names the tags the bridge has no case
    # for, not models it cannot fit.
  )
}

drm_julia_registry_families <- function(column) {
  reg <- drm_julia_family_registry()
  vapply(reg[vapply(reg, function(s) isTRUE(s[[column]]), logical(1L))],
         `[[`, character(1L), "family")
}

# The `predictor_dpars` declaration for one family, or NULL when the family has
# no registry row at all (nothing is admitted, so nothing needs a scope fence).
#
# WHY THIS COLUMN EXISTS (#1224). The A4.G17 fixed-effect-only fence used to
# exempt bivariate families by TESTING THEIR NAME PREFIX -- `startsWith(family,
# "biv_")` -- because `biv_gaussian` legitimately fits predictor-driven
# `sigma1`/`sigma2`/`rho12` cells. A name prefix is not a capability, so every
# later `biv_*` admission inherited an exemption it had not earned, and the
# failure was SILENT: the bridge fit a shape `engine = "tmb"` refuses,
# converged, and returned plausible numbers. Two families hit this
# independently within an hour on 2026-09-05 (`biv_student` #1217:
# `sigma1 = ~ z` fit at logLik -466.43141436; `biv_lognormal` #1216:
# `sigma1 = ~ x` fit at -71.4056477; both refused by `engine = "tmb"`), and
# each wrote its own hand-written refusal function.
#
# Measuring the neighbours while building this column found a THIRD instance,
# on a family with no `biv_` prefix at all: `tweedie()` `nu ~ z` fit through
# `engine = "julia"` (logLik -259.84074955) while `engine = "tmb"` refused it.
# So the defect was never about bivariate-ness; it was about the bridge's
# reachable dpar surface being wider than the native engine's, with nothing
# declaring the difference. This column declares it, per family, once.
drm_julia_family_predictor_dpars <- function(family) {
  reg <- drm_julia_family_registry()
  row <- Find(function(s) identical(s$family, family), reg)
  if (is.null(row)) {
    return(NULL)
  }
  row$predictor_dpars
}

# Registry invariants that a `spec()` default could not enforce, checked by
# tests/testthat/test-julia-family-registry.R rather than on every registry
# read. Returns a character vector of problems (empty when the registry is
# well formed) so a failure names every offending row at once.
#
# The bivariate rule is keyed on the FAMILY OBJECT's `n_response`, not on the
# family's name: `"*"` ("every dpar may carry a predictor") is a claim no
# two-response family may make implicitly, because the native bivariate spec
# builders are narrower than the bridge's reach for every bivariate family
# except `biv_gaussian`. A row must therefore enumerate.
drm_julia_family_registry_problems <- function() {
  reg <- drm_julia_family_registry()
  problems <- character(0L)
  for (row in reg) {
    declared <- row$predictor_dpars
    if (!is.character(declared) || length(declared) == 0L ||
        anyNA(declared) || any(!nzchar(declared))) {
      problems <- c(problems, sprintf(
        "%s: predictor_dpars must be a non-empty character vector", row$family
      ))
      next
    }
    if ("*" %in% declared && length(declared) != 1L) {
      problems <- c(problems, sprintf(
        "%s: the \"*\" sentinel cannot be mixed with named dpars", row$family
      ))
      next
    }
    fam <- drm_julia_registry_family_object(row$family)
    if (is.null(fam)) {
      # No drmTMB `drm_family` constructor of this name -- the stats-family
      # rows (gaussian, poisson, binomial, gamma via Gamma(link = "log")).
      # All univariate; nothing further to check.
      next
    }
    n_response <- fam$n_response %||% 1L
    if (n_response >= 2L && identical(declared, "*")) {
      problems <- c(problems, sprintf(
        "%s: a %d-response family may not declare predictor_dpars = \"*\"; enumerate the dpars it has earned",
        row$family, as.integer(n_response)
      ))
      next
    }
    if (!identical(declared, "*") && !is.null(fam$dpars)) {
      unknown <- setdiff(declared, fam$dpars)
      if (length(unknown) > 0L) {
        problems <- c(problems, sprintf(
          "%s: predictor_dpars names dpar(s) the family does not have: %s",
          row$family, paste(unknown, collapse = ", ")
        ))
      }
    }
  }
  problems
}

# The `drm_family` object behind a registry row, or NULL when the row names a
# stats family (gaussian / poisson / binomial / gamma) rather than a drmTMB
# constructor. Looked up with `inherits = FALSE` so `gamma` resolves to nothing
# instead of to `base::gamma`.
drm_julia_registry_family_object <- function(family) {
  ctor <- tryCatch(
    get0(family, envir = asNamespace("drmTMB"), mode = "function",
         inherits = FALSE),
    error = function(e) NULL
  )
  if (is.null(ctor)) {
    return(NULL)
  }
  obj <- tryCatch(ctor(), error = function(e) NULL)
  if (!inherits(obj, "drm_family")) {
    return(NULL)
  }
  obj
}
