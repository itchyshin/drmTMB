#!/usr/bin/env Rscript

# Arc 2 parameterized profile-feasibility runner.
#
# Generalizes the Arc 1 runners (tools/run-arc1-gaussian-fixed-profile-
# feasibility.R, tools/run-arc1-gaussian-reml-slope-profile-feasibility.R)
# into a single CLI-driven runner so new capability-ledger cells can be
# screened for promotion from `point_fit_recovery` to `interval_feasible`
# without duplicating the receipt/trace/interval logic. The contract is
# unchanged from Arc 1: a receipt PASSES only when the profile-derived lower
# bound, point estimate, and upper bound are all finite and strictly
# ordered (lower < estimate < upper), the optimizer converged
# (convergence == 0), the Hessian is positive definite (pdHess == TRUE), and
# the profile is neither boundary- nor clamp-limited. Endpoints come from
# exactly ONE retained `stats::profile()` execution -- never a separate
# profile()/confint() pair, which Arc 1's own after-task record identified
# as a defect -- and the emitted trace must span both sides of the point
# estimate. Every artifact (fixture, trace, interval, receipt) is content-
# hashed with the same field names Arc 1 uses, so a reconciler built on
# tools/arc1_profile_reconcile.py continues to apply unmodified.
#
# `fixture_call` returns whatever object the fixture builder itself returns
# (a bare data.frame for mc-0186/mc-0263; a list carrying `$data` plus a
# `$tree` for the phylo cells mc-0274/mc-0277), never coerced. Two contract
# fields then pull the data.frame and formula out of that fixture result:
# `data_from_fixture(fixture_result)` -> data.frame, and
# `formula(fixture_result)` -> a `drmTMB::bf()` object, so a formula that
# needs fixture-specific structure (e.g. `phylo(1 | species, tree = ...)`)
# can close over the same fixture result the data came from instead of being
# built niladically.
#
# Any contract violation -- an unready target, a profile() error, a
# non-finite or disordered interval, non-convergence, a non-PD Hessian, or a
# boundary/clamp condition -- is retained as a FAILING receipt (never a
# silent NA) and the runner exits with status 2.

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", name, "="), "", hit[[1L]])
}
allowed_args <- c("cell", "target", "fixture", "seed", "outdir", "estimator")
allowed_pattern <- paste0("^--(", paste(allowed_args, collapse = "|"), ")=")
if (length(args) && any(!grepl(allowed_pattern, args))) {
  stop("Only --", paste(allowed_args, collapse = "=, --"), "= are accepted.", call. = FALSE)
}

cell_id <- arg_value("cell")
target_arg <- arg_value("target")
fixture_arg <- arg_value("fixture")
seed_arg <- arg_value("seed")
estimator <- arg_value("estimator")

if (is.null(cell_id)) stop("--cell= is required.", call. = FALSE)
if (is.null(target_arg)) stop("--target= is required.", call. = FALSE)
if (is.null(fixture_arg)) stop("--fixture= is required.", call. = FALSE)
if (is.null(seed_arg)) stop("--seed= is required.", call. = FALSE)
if (is.null(estimator)) stop("--estimator= is required.", call. = FALSE)
if (!estimator %in% c("ML", "REML")) stop("--estimator= must be ML or REML.", call. = FALSE)
seed <- as.integer(seed_arg)
if (is.na(seed)) stop("--seed= must be an integer.", call. = FALSE)

# --- Per-cell contracts --------------------------------------------------
#
# Each entry pins the exact formula/family/estimator/fixture-builder for one
# capability-ledger cell. Adding a new cell means adding one entry here; the
# --target=/--fixture=/--estimator= CLI arguments are asserted against the
# entry so a typo in the invocation fails loudly instead of silently running
# a different contract than the one named on the command line.
cell_registry <- list(
  "mc-0186" = list(
    target = "rho12",
    family_name = "biv_gaussian",
    family = function() drmTMB::biv_gaussian(),
    formula = function(fx) {
      drmTMB::bf(
        mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      )
    },
    # The "robust" optimizer preset is copied from the same source (
    # tests/testthat/test-reml-bivariate.R) that defines the fixture; it is
    # the only configuration this exact DGP/formula/family/REML combination
    # is known to have been validated with.
    control = function() drmTMB::drm_control(optimizer_preset = "robust"),
    estimator = "REML",
    provider = "none",
    fixture_name = "biv_reml_fixture",
    fixture_file = "tests/testthat/test-reml-bivariate.R",
    # `fixture_call` isolates each cell's own fixture-builder signature (they
    # differ across cells -- see mc-0263 below) behind one common interface:
    # (fixture_fn, seed) -> data.frame.
    fixture_call = function(fixture_fn, seed) fixture_fn(n = 150L, seed = seed),
    data_from_fixture = function(fx) fx,
    information_rung = function(seed) "n150",
    dgp_id = "arc2_biv_gaussian_reml_residual_correlation",
    formula_label = paste0(
      "bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1); ",
      "biv_gaussian(); REML=TRUE; drm_control(optimizer_preset = \"robust\")"
    ),
    true_parameter_scale = "0.4 residual correlation (rho12), constant across observations",
    cohort_id = "arc2-biv-gaussian-reml-rho12-profile-feasibility"
  ),
  "mc-0263" = list(
    target = "fixef:sigma:x",
    family_name = "gaussian",
    family = function() stats::gaussian(),
    # `sigma ~ x` (no random effect on sigma) is required for `fixef:sigma:x`
    # to remain a DIRECT (non-marginalised) parameter: drmTMB REML always
    # marginalises the location (mu) fixed effects (R/profile.R -- see the
    # mc-0182/mc-0183/mc-0261 hold in the Arc 0 manifest), and additionally
    # marginalises any dpar's own fixed effects into the Laplace random block
    # if that dpar itself carries a random-effect term (demonstrated by
    # tests/testthat/test-reml-heteroscedastic.R:95-119, where `sigma ~ x +
    # (1 | id)` pulls `beta_sigma` into `tmb_random_names`). The mean random
    # intercept `(1 | id)` here matches the fixture's own DGP (which bakes in
    # a mean random intercept `u[id]`) without attaching any RE to sigma, so
    # this is the closest-in-shape config to the fixture's intent that keeps
    # sigma's fixed effect exposed -- an assumption this runner's
    # target_lookup stage checks explicitly rather than assumes.
    formula = function(fx) drmTMB::bf(y ~ x + (1 | id), sigma ~ x),
    control = function() drmTMB::drm_control(optimizer_preset = "robust"),
    estimator = "REML",
    provider = "none",
    fixture_name = "reml_hetero_fixture",
    fixture_file = "tests/testthat/test-reml-heteroscedastic.R",
    fixture_call = function(fixture_fn, seed) fixture_fn(n_id = 30L, n_each = 4L, seed = seed),
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "id30_each4",
    dgp_id = "arc2_gaussian_reml_heteroscedastic_sigma_fixed_effect",
    formula_label = paste0(
      "bf(y ~ x + (1 | id), sigma ~ x); gaussian(identity/log); REML=TRUE; ",
      "drm_control(optimizer_preset = \"robust\")"
    ),
    true_parameter_scale = "sigma ~ x fixed coefficient (DGP true sigma effect is on z, not x; this fit tests profile feasibility of the fixef:sigma:x target only, not point recovery)",
    cohort_id = "arc2-gaussian-reml-heteroscedastic-sigma-fixef-profile-feasibility"
  ),
  "mc-0274" = list(
    # Random-effect SD target (not fixed-effect): the target is on the
    # internal log-SD scale (`log_sd_phylo`), so `profile_targets()` exposes
    # it as `sd:mu:phylo(1 | species)`, mirroring mc-0266's `sd:sigma:(1 |
    # id)` convention (tools/run-arc1-gaussian-sigma-re-profile-feasibility.R).
    target = "sd:mu:phylo(1 | species)",
    family_name = "gaussian",
    family = function() stats::gaussian(),
    # Formula/control copied verbatim from
    # tests/testthat/test-reml-phylo-location.R's first test_that() (the
    # restricted-likelihood-matching test), the only validated config for
    # this exact fixture/target combination.
    # `phylo()` requires a bare symbol for `tree` (R/parse-formula.R's
    # "must be the name of a phylogeny object" check), resolved later by
    # `evaluate_phylo_tree()` via `get(name, envir = environment(formula),
    # inherits = TRUE)`. So `tree` must be bound as a local variable named
    # literally `tree` in this function's own execution environment (which
    # becomes `environment(formula)`) -- passing `fx$tree` directly as the
    # marker argument is a non-symbol and fails at parse time.
    formula = function(fx) {
      tree <- fx$tree
      drmTMB::bf(y ~ x + drmTMB::phylo(1 | species, tree = tree), sigma ~ 1)
    },
    control = function() drmTMB::drm_control(optimizer_preset = "robust"),
    estimator = "REML",
    provider = "phylo",
    fixture_name = "reml_phylo_location_fixture",
    fixture_file = "tests/testthat/test-reml-phylo-location.R",
    # Called at the fixture's own defaults (n_tip = 30, n_each = 3), which is
    # also what the source test itself uses (`fx <- reml_phylo_location_fixture()`).
    fixture_call = function(fixture_fn, seed) fixture_fn(n_tip = 30L, n_each = 3L, seed = seed),
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "tip30_each3",
    dgp_id = "arc2_gaussian_reml_phylo_location_mu_sd",
    formula_label = paste0(
      "bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1); gaussian(identity/log); ",
      "REML=TRUE; drm_control(optimizer_preset = \"robust\")"
    ),
    true_parameter_scale = "0.6 phylogenetic random-intercept SD on the mean (mu), log-SD internal scale",
    cohort_id = "arc2-gaussian-reml-phylo-location-mu-sd-profile-feasibility"
  ),
  "mc-0277" = list(
    target = "sd:sigma:phylo(1 | species)",
    family_name = "gaussian",
    family = function() stats::gaussian(),
    # Formula shape matches test-reml-phylo-location.R's "REML admits a pure
    # scale-side phylogenetic effect" test_that() (no optimizer preset
    # override; validated with default drm_control()). The FIXTURE, however,
    # is NOT that test's `reml_phylo_location_fixture()`: that fixture puts
    # the phylogenetic effect only on the mean (mu), so the true sigma-phylo
    # SD is exactly zero -- profiling a null variance component drives the
    # lower endpoint to the [0, Inf) boundary by construction, which is
    # correct profile behaviour under a null component, NOT a capability
    # limit (see tools/arc2-phylo-sigma-fixtures.R's header for the manifest
    # defect this replaces). `arc2_phylo_sigma_fixture()` instead places a
    # genuine phylogenetic effect on log(sigma) itself, so this cell tests
    # profile feasibility of a target with real signal.
    formula = function(fx) {
      tree <- fx$tree
      drmTMB::bf(y ~ x, sigma ~ drmTMB::phylo(1 | species, tree = tree))
    },
    control = NULL,
    estimator = "REML",
    provider = "phylo",
    fixture_name = "arc2_phylo_sigma_fixture",
    fixture_file = "tools/arc2-phylo-sigma-fixtures.R",
    # Defaults (n_tip = 60, n_each = 12, true_log_sd_phylo = 0.7) match the
    # fixture builder's own validated defaults -- n_each = 12 gives the
    # within-tip replication the scale-side component needs to be
    # identified (see the fixture file's design-rationale comment).
    fixture_call = function(fixture_fn, seed) fixture_fn(seed = seed),
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "tip60_each12",
    dgp_id = "arc2_gaussian_reml_phylo_sigma_sd",
    formula_label = paste0(
      "bf(y ~ x, sigma ~ phylo(1 | species, tree = tree)); gaussian(identity/log); REML=TRUE"
    ),
    true_parameter_scale = "0.7 phylogenetic random-intercept SD on log(sigma), log-SD internal scale",
    cohort_id = "arc2-gaussian-reml-phylo-sigma-sd-profile-feasibility"
  ),
  "mc-0283" = list(
    # Matched q2 sibling of mc-0277: the SAME labelled phylo() term
    # (`phylo(1 | p | species)`) appears in BOTH mu and sigma, so `sd:sigma:
    # ...` gets an extra "sigma:" prefix ahead of the term name (confirmed by
    # inspecting `drm_profile_targets()` on a fitted q2 model -- this is real
    # naming behaviour from the labelled-block term, not a typo), giving the
    # doubled target string below.
    target = "sd:sigma:sigma:phylo(1 | p | species)",
    family_name = "gaussian",
    family = function() stats::gaussian(),
    # Formula copied verbatim from test-reml-phylo-location.R:163-164 ("REML
    # admits matched mean-and-scale phylogenetic effects (q2 block)"), the
    # only validated syntax for this labelled q2 block. The FIXTURE is not
    # that test's `reml_phylo_location_fixture()`: that fixture has NO true
    # sigma-phylo signal (same defect mc-0277 replaces, see
    # tools/arc2-phylo-sigma-fixtures.R's header). `arc2_phylo_sigma_q2_fixture()`
    # instead places independent genuine phylogenetic signal on BOTH mu and
    # log(sigma), each with its own known true SD.
    formula = function(fx) {
      tree <- fx$tree
      drmTMB::bf(
        y ~ x + drmTMB::phylo(1 | p | species, tree = tree),
        sigma ~ 1 + drmTMB::phylo(1 | p | species, tree = tree)
      )
    },
    control = function() drmTMB::drm_control(optimizer_preset = "robust"),
    estimator = "REML",
    provider = "phylo",
    fixture_name = "arc2_phylo_sigma_q2_fixture",
    fixture_file = "tools/arc2-phylo-sigma-fixtures.R",
    # Defaults (n_tip = 60, n_each = 12) match mc-0277's validated replication
    # ladder, comfortably above the Arc 0 manifest's N>=250 q2 information
    # floor (n = 720).
    fixture_call = function(fixture_fn, seed) fixture_fn(seed = seed),
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "tip60_each12",
    dgp_id = "arc2_gaussian_reml_phylo_sigma_q2_sd",
    formula_label = paste0(
      "bf(y ~ x + phylo(1 | p | species, tree = tree), ",
      "sigma ~ 1 + phylo(1 | p | species, tree = tree)); gaussian(identity/log); ",
      "REML=TRUE; drm_control(optimizer_preset = \"robust\")"
    ),
    true_parameter_scale = "0.7 phylogenetic random-intercept SD on log(sigma) in the matched q2 block (independent 0.6 SD phylo effect also present on mu, identity link), log-SD internal scale",
    cohort_id = "arc2-gaussian-reml-phylo-sigma-q2-sd-profile-feasibility"
  ),
  "mc-0013" = list(
    # Random-effect SD target: the independent random-SLOPE SD component of
    # an intercept+slope animal() block on mu (beta() has no slope-only
    # animal() grammar -- see tools/arc2-beta-animal-fixtures.R).
    target = "sd:mu:animal(0 + x | id)",
    family_name = "beta",
    family = function() drmTMB::beta(),
    # `animal()` requires a bare symbol for pedigree/A/Ainv (R/parse-formula.R
    # ~line 760), resolved later from the formula's own environment -- same
    # bare-symbol requirement mc-0274/mc-0277 solve for phylo()'s `tree`.
    # `pedigree` must therefore be bound as a local variable named literally
    # `pedigree` in this function's own execution environment.
    formula = function(fx) {
      pedigree <- fx$pedigree
      drmTMB::bf(y ~ x + drmTMB::animal(1 + x | id, pedigree = pedigree), sigma ~ 1)
    },
    control = function() drmTMB::drm_control(optimizer_preset = "robust"),
    estimator = "ML",
    provider = "animal",
    fixture_name = "beta_animal_mu_slope_fixture",
    fixture_file = "tools/arc2-beta-animal-fixtures.R",
    fixture_call = function(fixture_fn, seed) fixture_fn(seed = seed),
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "id40_each20",
    dgp_id = "arc2_beta_animal_mu_slope_sd",
    formula_label = paste0(
      "bf(y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1); ",
      "beta() (logit/log); ML; drm_control(optimizer_preset = \"robust\")"
    ),
    true_parameter_scale = "0.55 animal random-slope SD on mu (logit link), independent of a 0.50 animal random-intercept SD; 40-individual (3-generation) pedigree, 20 observations per individual, log-SD internal scale",
    cohort_id = "arc2-beta-animal-mu-slope-sd-profile-feasibility"
  ),
  "mc-0015" = list(
    # Random-effect SD target: an intercept-only animal() block on sigma
    # (beta()'s scale side only admits intercept-only structured terms).
    target = "sd:sigma:animal(1 | id)",
    family_name = "beta",
    family = function() drmTMB::beta(),
    formula = function(fx) {
      pedigree <- fx$pedigree
      drmTMB::bf(y ~ x, sigma ~ drmTMB::animal(1 | id, pedigree = pedigree))
    },
    control = function() drmTMB::drm_control(optimizer_preset = "robust"),
    estimator = "ML",
    provider = "animal",
    fixture_name = "beta_animal_sigma_intercept_fixture",
    fixture_file = "tools/arc2-beta-animal-fixtures.R",
    fixture_call = function(fixture_fn, seed) fixture_fn(seed = seed),
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "id40_each40",
    dgp_id = "arc2_beta_animal_sigma_intercept_sd",
    formula_label = paste0(
      "bf(y ~ x, sigma ~ animal(1 | id, pedigree = pedigree)); ",
      "beta() (logit/log); ML; drm_control(optimizer_preset = \"robust\")"
    ),
    true_parameter_scale = "0.55 animal random-intercept SD on sigma (log link); 40-individual (3-generation) pedigree, 40 observations per individual for within-group replication, log-SD internal scale",
    cohort_id = "arc2-beta-animal-sigma-intercept-sd-profile-feasibility"
  ),
  "mc-0421" = list(
    # Random-effect SD target: the structured INTERCEPT component of an
    # intercept+slope phylo() block on sigma. NB2 (a count family) gates
    # structured sigma terms to unlabelled intercept-plus-one-slope only
    # (validate_*_sigma_random_terms(), R/drmTMB.R) -- the opposite of
    # beta()'s intercept-only scale gate mc-0015 relies on -- so the fitted
    # formula must include `1 + x` even though only the intercept SD is
    # profiled here (mirrors mc-0013's slope-only targeting of an
    # intercept+slope animal() block).
    target = "sd:sigma:phylo(1 | species)",
    family_name = "nbinom2",
    family = function() drmTMB::nbinom2(),
    # `phylo()` requires a bare symbol for `tree` -- same requirement as
    # mc-0274/mc-0277.
    formula = function(fx) {
      tree <- fx$tree
      drmTMB::bf(y ~ x, sigma ~ drmTMB::phylo(1 + x | species, tree = tree))
    },
    control = function() drmTMB::drm_control(optimizer_preset = "robust"),
    estimator = "ML",
    provider = "phylo",
    fixture_name = "arc3_nbinom2_sigma_phylo_fixture",
    fixture_file = "tools/arc3-nbinom2-sigma-provider-fixtures.R",
    fixture_call = function(fixture_fn, seed) fixture_fn(seed = seed),
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "tip80_each30",
    dgp_id = "arc3_nbinom2_ml_phylo_sigma_sd",
    formula_label = paste0(
      "bf(y ~ x, sigma ~ phylo(1 + x | species, tree = tree)); nbinom2() (log/log); ML; ",
      "drm_control(optimizer_preset = \"robust\")"
    ),
    true_parameter_scale = "0.55 phylogenetic random-intercept SD on log(sigma) (NB2 dispersion), independent of a 0.20 phylogenetic random-slope SD required by the intercept-plus-one-slope structured-sigma grammar for count families; 80-tip frozen random topology with Grafen branch lengths (power = 0.5, tree_seed = 909), 30 observations per tip, log-SD internal scale",
    cohort_id = "arc3-nbinom2-ml-phylo-sigma-sd-profile-feasibility"
  ),
  "mc-0422" = list(
    # Random-effect SD target: the structured INTERCEPT component of an
    # intercept+slope spatial() block on sigma (see mc-0421's NB2
    # structured-sigma gate note).
    target = "sd:sigma:spatial(1 | site)",
    family_name = "nbinom2",
    family = function() drmTMB::nbinom2(),
    # `spatial()` requires a bare symbol for `coords`.
    formula = function(fx) {
      coords <- fx$coords
      drmTMB::bf(y ~ x, sigma ~ drmTMB::spatial(1 + x | site, coords = coords))
    },
    control = function() drmTMB::drm_control(optimizer_preset = "robust"),
    estimator = "ML",
    provider = "spatial",
    fixture_name = "arc3_nbinom2_sigma_spatial_fixture",
    fixture_file = "tools/arc3-nbinom2-sigma-provider-fixtures.R",
    fixture_call = function(fixture_fn, seed) fixture_fn(seed = seed),
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "site81_each25",
    dgp_id = "arc3_nbinom2_ml_spatial_sigma_sd",
    formula_label = paste0(
      "bf(y ~ x, sigma ~ spatial(1 + x | site, coords = coords)); nbinom2() (log/log); ML; ",
      "drm_control(optimizer_preset = \"robust\")"
    ),
    true_parameter_scale = "0.55 spatial random-intercept SD on log(sigma) (NB2 dispersion), independent of a 0.20 spatial random-slope SD required by the intercept-plus-one-slope structured-sigma grammar for count families; 9x9 coordinate grid (81 sites), 25 observations per site, log-SD internal scale",
    cohort_id = "arc3-nbinom2-ml-spatial-sigma-sd-profile-feasibility"
  ),
  "mc-0423" = list(
    # Random-effect SD target: the structured INTERCEPT component of an
    # intercept+slope animal() block on sigma (see mc-0421's NB2
    # structured-sigma gate note).
    target = "sd:sigma:animal(1 | id)",
    family_name = "nbinom2",
    family = function() drmTMB::nbinom2(),
    # `animal()` requires a bare symbol for `pedigree`.
    formula = function(fx) {
      pedigree <- fx$pedigree
      drmTMB::bf(y ~ x, sigma ~ drmTMB::animal(1 + x | id, pedigree = pedigree))
    },
    control = function() drmTMB::drm_control(optimizer_preset = "robust"),
    estimator = "ML",
    provider = "animal",
    fixture_name = "arc3_nbinom2_sigma_animal_fixture",
    fixture_file = "tools/arc3-nbinom2-sigma-provider-fixtures.R",
    # 2026-08-02 CELL REMAINS A RETAINED STOP (Curie diagnostic session on
    # Fisher's withhold of seed 2026080302, estimate 0.283, 49% relative
    # error, interval [0.137, 0.479] excluding true 0.55):
    # - The mc-0424 (relmat) mechanism was TESTED, not assumed, and does NOT
    #   transfer: seed 2026080302's finite-sample cor(v0, v1) is -0.14, not
    #   an outlier (max|cor| over a 10-seed scan at n_founders = 4 is 0.51,
    #   at seed 423, a DIFFERENT and passing seed). The A-matrix condition
    #   number is 66.7 -- well short of mc-0421 (phylo)'s 98563-level
    #   ill-conditioning.
    # - n_founders raised 4 -> 8 (40 -> 80 individuals, n_each unchanged at
    #   25) as a direct information-count fix, mirroring mc-0424's n_id
    #   enlargement logic on the axis that WAS still open (more independent
    #   pedigree units, not less cor(v0, v1)). This reduces the *previously
    #   failing* seed 2026080302's relative error from 49% to 24% (now
    #   bracketing 0.55) -- but the shared 2026080301-05 family's re-gate at
    #   n_founders = 8 shows a DIFFERENT seed, 2026080304, now fails BOTH
    #   checks (relative error 40.2%, interval [0.207, 0.488] EXCLUDES 0.55).
    #   4/5 seeds pass; Fisher's tightened gate requires 5/5. See the Curie
    #   session notes for the full per-seed table (n_founders = 4 and
    #   n_founders = 8, both reported, no cell dropped from the record).
    # - CONCLUSION: this is not a forced pass. n_founders = 8 is kept as the
    #   contract default because it is a genuine, diagnosis-driven
    #   improvement over n_founders = 4 (worst-case relative error 49% -> 40%
    #   across the family), but mc-0423 stays at `point_fit_recovery`, NOT
    #   `interval_feasible` -- the animal-provider NB2 structured-sigma
    #   intercept SD shows real seed-to-seed sampling fragility at this scale
    #   that a single doubling of n_id does not eliminate. A Totoro campaign
    #   is NOT recommended for this cell without either a further diagnosed
    #   fix or an explicit decision to accept a retained STOP.
    fixture_call = function(fixture_fn, seed) fixture_fn(seed = seed, n_founders = 8L),
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "id80_each25",
    dgp_id = "arc3_nbinom2_ml_animal_sigma_sd",
    formula_label = paste0(
      "bf(y ~ x, sigma ~ animal(1 + x | id, pedigree = pedigree)); nbinom2() (log/log); ML; ",
      "drm_control(optimizer_preset = \"robust\")"
    ),
    true_parameter_scale = "0.55 animal random-intercept SD on log(sigma) (NB2 dispersion), independent of a 0.25 animal random-slope SD required by the intercept-plus-one-slope structured-sigma grammar for count families; 80-individual (3-generation, 8-founder-pair) pedigree, 25 observations per individual, log-SD internal scale",
    cohort_id = "arc3-nbinom2-ml-animal-sigma-sd-profile-feasibility"
  ),
  "mc-0424" = list(
    # Random-effect SD target: the structured INTERCEPT component of an
    # intercept+slope relmat() block on sigma (see mc-0421's NB2
    # structured-sigma gate note).
    target = "sd:sigma:relmat(1 | id)",
    family_name = "nbinom2",
    family = function() drmTMB::nbinom2(),
    # `relmat()` requires a bare symbol for `Q` (or `K`).
    formula = function(fx) {
      Q <- fx$Q
      drmTMB::bf(y ~ x, sigma ~ drmTMB::relmat(1 + x | id, Q = Q))
    },
    control = function() drmTMB::drm_control(optimizer_preset = "robust"),
    estimator = "ML",
    provider = "relmat",
    fixture_name = "arc3_nbinom2_sigma_relmat_fixture",
    fixture_file = "tools/arc3-nbinom2-sigma-provider-fixtures.R",
    fixture_call = function(fixture_fn, seed) fixture_fn(seed = seed),
    data_from_fixture = function(fx) fx$data,
    # 2026-08-02: raised from "id40_each25" -- see
    # tools/arc3-nbinom2-sigma-provider-fixtures.R's DESIGN ITERATION note
    # (n_id defaults 40 -> 80 to shrink finite-sample intercept/slope
    # confounding diagnosed on the Totoro seed 2026080303 failure).
    information_rung = function(seed) "id80_each25",
    dgp_id = "arc3_nbinom2_ml_relmat_sigma_sd",
    formula_label = paste0(
      "bf(y ~ x, sigma ~ relmat(1 + x | id, Q = Q)); nbinom2() (log/log); ML; ",
      "drm_control(optimizer_preset = \"robust\")"
    ),
    true_parameter_scale = "0.55 relmat (AR1-Toeplitz relatedness) random-intercept SD on log(sigma) (NB2 dispersion), independent of a 0.25 relmat random-slope SD required by the intercept-plus-one-slope structured-sigma grammar for count families; 80-individual relatedness structure, 25 observations per individual, log-SD internal scale",
    cohort_id = "arc3-nbinom2-ml-relmat-sigma-sd-profile-feasibility"
  ),
  "mc-0321" = list(
    # Random-effect SD target: the SAME target string, `sd:mu:phylo_
    # interaction(1 | plant:pollinator)`, that mc-0438 (Poisson) STOPPED on
    # (nonfinite profile endpoints at both npair64-each8 and npair64-each20;
    # see docs/dev-log/interval-feasibility/results/c8e04258.../arc1-mc0438-
    # profile-feasibility/mc-0438/*-receipt.tsv). tools/arc3-phylo-
    # interaction-fixtures.R's header explains why mc-0438's STAR-tree, 64-
    # pair geometry is deliberately reused here rather than the balanced-tree
    # shape test-phylo-interaction.R validates for point-fit: it is the
    # directly comparable geometry. A local point-fit + single-profile gate
    # (tools/arc3-phylo-interaction-point-fit-gate.R) found this EXACT
    # geometry profiles cleanly for gaussian across 3 seeds (rel_err 0.089,
    # 0.024, 0.064; conf_status "profile", finite/ordered every time) -- the
    # Poisson STOP does not generalise to gaussian mu.
    target = "sd:mu:phylo_interaction(1 | plant:pollinator)",
    family_name = "gaussian",
    family = function() stats::gaussian(),
    formula = function(fx) {
      plant_tree <- fx$plant_tree
      pollinator_tree <- fx$pollinator_tree
      drmTMB::bf(
        y ~ x + drmTMB::phylo_interaction(
          1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree
        ),
        sigma ~ 1
      )
    },
    control = NULL,
    estimator = "ML",
    provider = "phylo_interaction",
    fixture_name = "arc3_phylo_interaction_gaussian_fixture",
    fixture_file = "tools/arc3-phylo-interaction-fixtures.R",
    fixture_call = function(fixture_fn, seed) {
      fixture_fn(
        n_plant = 8L, n_pollinator = 8L, n_each = 8L, sd_pair = 0.6,
        tree_type = "star", seed = seed
      )
    },
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "star_np8_npo8_each8",
    dgp_id = "arc3_gaussian_ml_phylo_interaction_mu_sd",
    formula_label = paste0(
      "bf(y ~ x + phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, ",
      "tree2 = pollinator_tree), sigma ~ 1); gaussian(identity/log); ML"
    ),
    true_parameter_scale = "0.6 bipartite phylogenetic-interaction random-intercept SD on mu (identity link); 8-tip star plant tree x 8-tip star pollinator tree (64 pairs, tip covariance = identity on each side -- the same iid-pair geometry mc-0438 used), 8 observations per pair, log-SD internal scale",
    cohort_id = "arc3-gaussian-ml-phylo-interaction-mu-sd-profile-feasibility"
  ),
  "mc-0409" = list(
    # NB2 sibling of mc-0321: same target string, same STAR-tree geometry,
    # same point-fit + single-profile gate result (rel_err 0.160, 0.006,
    # 0.159 across 3 seeds; conf_status "profile", finite/ordered every
    # time) -- the Poisson STOP does not generalise to NB2 mu either. See
    # tools/arc3-phylo-interaction-fixtures.R's header and mc-0321's comment
    # above for the full rationale.
    target = "sd:mu:phylo_interaction(1 | plant:pollinator)",
    family_name = "nbinom2",
    family = function() drmTMB::nbinom2(),
    formula = function(fx) {
      plant_tree <- fx$plant_tree
      pollinator_tree <- fx$pollinator_tree
      drmTMB::bf(
        nb2 ~ x + drmTMB::phylo_interaction(
          1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree
        ),
        sigma ~ 1
      )
    },
    control = NULL,
    estimator = "ML",
    provider = "phylo_interaction",
    fixture_name = "arc3_phylo_interaction_nbinom2_fixture",
    fixture_file = "tools/arc3-phylo-interaction-fixtures.R",
    # 2026-08-02: n_each raised from 8 to 24 -- see the Curie diagnostic
    # session for seed 2026080405 (Fisher's withhold: a truth-excluding
    # interval [0.610, 0.902] against true 0.6 despite every relative error
    # passing the mechanical gate). Diagnosis found TWO compounding, tested
    # (not assumed) causes, neither of which is per-pair count sparsity
    # (zero-pair rate 0.000 at every seed): (1) the realized latent
    # pair-effect draw itself (identical RNG stream to the Gaussian sibling
    # mc-0321, since it is drawn before the family-specific x/y draws) has
    # empirical SD 0.706 at seed 2026080405 vs true 0.6 -- an ordinary ~2 SD
    # finite-sample outcome for only 64 iid pair levels (star tree = identity
    # tip covariance on each side) that also nudges mc-0321's own interval to
    # barely bracket truth (lower 0.575); (2) a genuine NB2-specific
    # dispersion/interaction-SD confound -- cor(sigma_hat, sd_hat) = -0.74
    # across the shared 2026080401-05 family at n_each = 8, and seed
    # 2026080405 combines a below-median sigma_hat with the family's highest
    # sd_hat, amplifying cause (1). Tripling n_each to 24 (1536 obs instead
    # of 512) gives the dispersion parameter more direct per-pair
    # information, shrinking seed 2026080405's relative error from 0.227 to
    # 0.134 and its profile interval to [0.572, 0.824] (brackets 0.6) -- see
    # the RE-GATE RESULTS in the fixture-file-adjacent Curie session notes
    # for the full 5-seed table this contract now reflects.
    fixture_call = function(fixture_fn, seed) {
      fixture_fn(
        n_plant = 8L, n_pollinator = 8L, n_each = 24L, sd_pair = 0.6,
        tree_type = "star", seed = seed
      )
    },
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "star_np8_npo8_each24",
    dgp_id = "arc3_nbinom2_ml_phylo_interaction_mu_sd",
    formula_label = paste0(
      "bf(nb2 ~ x + phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, ",
      "tree2 = pollinator_tree), sigma ~ 1); nbinom2() (log/log); ML"
    ),
    true_parameter_scale = "0.6 bipartite phylogenetic-interaction random-intercept SD on mu (log link); 8-tip star plant tree x 8-tip star pollinator tree (64 pairs, tip covariance = identity on each side -- the same iid-pair geometry mc-0438 used), 24 observations per pair, log-SD internal scale",
    cohort_id = "arc3-nbinom2-ml-phylo-interaction-mu-sd-profile-feasibility"
  ),
  "mc-0417" = list(
    # AGGREGATE cell (docs/dev-log/dashboard/capability-ledger/cells.tsv):
    # "exactly two intercept-only providers drawn from {phylo, spatial,
    # animal, relmat} ... may co-occur as primary+secondary q1 fields" has
    # C(4,2) = 6 possible pairs. Boole's BIND decision pins mc-0417 to the
    # ONE pair with recovery evidence on record -- spatial+relmat, per
    # docs/dev-log/after-task/2026-07-05-count-multiprovider-structured-mu.md
    # -- rather than splitting into five more zero-evidence cells. PRIMARY
    # target: sd:mu:spatial(1 | site). Companion (surfaced, not gated):
    # sd:mu:relmat(1 | id). Formula shape copied from
    # tests/testthat/test-count-multiprovider-structured-mu.R:65-69, the only
    # place in the tree that builds a simultaneous two-provider structured
    # NB2 mean. Both `coords` and `Q` must be bare local symbols (spatial()/
    # relmat()'s formula-parser requirement). See tools/arc4-multiprovider-
    # mu-fixtures.R's header for the full point-fit gate record (5/5 seeds
    # PASS at n_site=20/n_id=24/n_rep=5, after a smaller n_site=12/n_id=15
    # design failed 1/5 on the primary target).
    target = "sd:mu:spatial(1 | site)",
    family_name = "nbinom2",
    family = function() drmTMB::nbinom2(),
    formula = function(fx) {
      coords <- fx$coords
      Q <- fx$Q
      drmTMB::bf(
        y ~ x + drmTMB::spatial(1 | site, coords = coords) +
          drmTMB::relmat(1 | id, Q = Q),
        sigma ~ 1
      )
    },
    control = NULL,
    estimator = "ML",
    provider = "spatial+relmat",
    fixture_name = "arc4_nbinom2_mu_spatial_relmat_fixture",
    fixture_file = "tools/arc4-multiprovider-mu-fixtures.R",
    fixture_call = function(fixture_fn, seed) fixture_fn(seed = seed),
    data_from_fixture = function(fx) fx$data,
    information_rung = function(seed) "site20_id24_each5",
    dgp_id = "arc4_nbinom2_ml_spatial_relmat_mu_sd",
    formula_label = paste0(
      "bf(y ~ x + spatial(1 | site, coords = coords) + relmat(1 | id, Q = Q), ",
      "sigma ~ 1); nbinom2() (log/log); ML"
    ),
    true_parameter_scale = "0.6 spatial random-intercept SD on mu (log link; PRIMARY target), simultaneous with an independent 0.5 relmat random-intercept SD on mu (COMPANION, not gated); 20-site coordinate-arc GMRF (kappa = 66.2) crossed with 24-individual AR(1)-relatedness GMRF (kappa = 3.5), 5 observations per (site, id) cell, log-SD internal scale",
    cohort_id = "arc4-nbinom2-ml-spatial-relmat-mu-sd-profile-feasibility"
  )
)

contract <- cell_registry[[cell_id]]
if (is.null(contract)) {
  stop(
    "Unknown --cell=", cell_id,
    "; add an entry to cell_registry in this runner first.",
    call. = FALSE
  )
}
if (!identical(target_arg, contract$target)) {
  stop(
    "--target=", target_arg, " does not match the registered contract target ",
    contract$target, " for --cell=", cell_id, call. = FALSE
  )
}
if (!identical(fixture_arg, contract$fixture_name)) {
  stop(
    "--fixture=", fixture_arg, " does not match the registered fixture builder ",
    contract$fixture_name, " for --cell=", cell_id, call. = FALSE
  )
}
if (!identical(estimator, contract$estimator)) {
  stop(
    "--estimator=", estimator, " does not match the registered estimator ",
    contract$estimator, " for --cell=", cell_id, call. = FALSE
  )
}

script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]]))
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
source_sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
runner_sha256 <- sub(" .*", "", system2("shasum", c("-a", "256", script), stdout = TRUE))
file_sha256 <- function(path) sub(" .*", "", system2("shasum", c("-a", "256", path), stdout = TRUE))

out <- arg_value(
  "outdir",
  file.path(
    root, "docs/dev-log/interval-feasibility/results", source_sha,
    "arc2-profile-feasibility", cell_id
  )
)
dir.create(out, recursive = TRUE, showWarnings = FALSE)

# --- Single-source the fixture builder from its test file ----------------
#
# We source only the fixture function's own top-level assignment expression
# out of the frozen test file (never the whole test file, which would also
# execute its test_that() blocks), so the fixture stays single-sourced from
# tests/testthat/ instead of being duplicated in tools/.
source_fixture_builder <- function(fixture_file, fn_name) {
  path <- file.path(root, fixture_file)
  if (!file.exists(path)) stop("Fixture source file not found: ", path, call. = FALSE)
  exprs <- parse(path, keep.source = FALSE)
  env <- new.env(parent = globalenv())
  found <- FALSE
  for (e in exprs) {
    if (
      is.call(e) && identical(e[[1L]], as.name("<-")) &&
        is.name(e[[2L]]) && identical(as.character(e[[2L]]), fn_name)
    ) {
      eval(e, envir = env)
      found <- TRUE
    }
  }
  if (!found) {
    stop("Fixture builder ", fn_name, " not found in ", fixture_file, call. = FALSE)
  }
  get(fn_name, envir = env)
}

fixture_fn <- source_fixture_builder(contract$fixture_file, contract$fixture_name)
fixture_result <- contract$fixture_call(fixture_fn, seed)
dat <- contract$data_from_fixture(fixture_result)
if (!is.data.frame(dat)) {
  stop("data_from_fixture for --cell=", cell_id, " did not return a data.frame.", call. = FALSE)
}
rung <- contract$information_rung(seed)

fixture_path <- file.path(out, sprintf("fixture-%s-%s-seed%d.tsv", contract$fixture_name, rung, seed))
utils::write.table(dat, fixture_path, sep = "\t", quote = FALSE, row.names = FALSE)
fixture_sha256 <- file_sha256(fixture_path)

target_name <- contract$target
stem <- sprintf("%s-%s-%s-seed%d", cell_id, contract$fixture_name, rung, seed)
trace_path <- file.path(out, paste0(stem, "-trace.tsv"))
interval_path <- file.path(out, paste0(stem, "-interval.tsv"))

# --- Single retained pipeline: fit -> target lookup -> ONE profile() -----
#
# Every stage runs inside one tryCatch so ANY contract violation --
# including a fit error or an unready target, not just a profile() error --
# is retained as a FAILING receipt rather than crashing without a record.
# `stage` records which phase failed for `failure_reason`.
stage <- "fit"
pipeline_error <- NULL
fit <- NULL
target_row <- NULL
prof <- NULL
interval <- NULL

tryCatch({
  fit_args <- list(
    contract$formula(fixture_result), family = contract$family(), data = dat,
    REML = identical(estimator, "REML")
  )
  if (!is.null(contract$control)) fit_args$control <- contract$control()
  fit <- do.call(drmTMB::drmTMB, fit_args)

  stage <- "target_lookup"
  targets <- drmTMB::profile_targets(fit)
  target_row <- subset(targets, parm == target_name)
  if (
    nrow(target_row) != 1L || !isTRUE(target_row$profile_ready) ||
      !identical(target_row$target_type, "direct")
  ) {
    stop("Exact direct profile target is not ready: ", target_name, call. = FALSE)
  }

  stage <- "profile"
  prof <- stats::profile(fit, parm = target_name, trace = FALSE)

  stage <- "artifact_write"
  trace <- as.data.frame(prof)
  trace$cell_id <- cell_id
  trace$target_id <- paste0(cell_id, "::", target_name)
  trace$seed <- seed
  trace$information_rung <- rung
  utils::write.table(trace, trace_path, sep = "\t", quote = FALSE, row.names = FALSE)

  profile_field <- function(name) {
    value <- unique(prof[[name]])
    if (length(value) != 1L) stop("Profile field is not constant: ", name, call. = FALSE)
    value[[1L]]
  }
  interval <- data.frame(
    parm = target_name, level = profile_field("level"),
    lower = profile_field("conf.low"), upper = profile_field("conf.high"),
    scale = profile_field("scale"), transformation = profile_field("transformation"),
    tmb_parameter = profile_field("tmb_parameter"), index = profile_field("index"),
    method = "profile", profile.engine = "tmbprofile",
    conf.status = profile_field("conf.status"),
    profile.boundary = !all(is.finite(c(
      profile_field("conf.low"), target_row$estimate[[1L]], profile_field("conf.high")
    ))) ||
      profile_field("conf.low") >= target_row$estimate[[1L]] ||
      profile_field("conf.high") <= target_row$estimate[[1L]] ||
      !identical(profile_field("profile.message"), "ok"),
    profile.message = profile_field("profile.message"),
    cell_id = cell_id, target_id = paste0(cell_id, "::", target_name),
    seed = seed, information_rung = rung,
    stringsAsFactors = FALSE
  )
  utils::write.table(interval, interval_path, sep = "\t", quote = FALSE, row.names = FALSE)
}, error = function(e) {
  pipeline_error <<- e
})

failed <- !is.null(pipeline_error)
trace_complete <- !is.null(prof) && file.exists(trace_path)

conf_status <- if (!is.null(interval)) {
  interval$conf.status[[1L]]
} else if (identical(stage, "profile") || identical(stage, "artifact_write")) {
  "profile_error"
} else {
  "not_attempted"
}
estimate <- if (!is.null(target_row) && nrow(target_row) == 1L) target_row$estimate[[1L]] else NA_real_
lower <- if (!is.null(interval)) interval$lower[[1L]] else NA_real_
upper <- if (!is.null(interval)) interval$upper[[1L]] else NA_real_
boundary <- if (!is.null(interval)) interval$profile.boundary[[1L]] else NA
convergence <- if (!is.null(fit)) fit$opt$convergence else NA_integer_
pdHess <- if (!is.null(fit)) isTRUE(fit$sdr$pdHess) else NA

clean <- !failed && !is.null(interval) &&
  identical(conf_status, "profile") && all(is.finite(c(lower, estimate, upper))) &&
  lower < estimate && estimate < upper && !isTRUE(boundary) &&
  identical(convergence, 0L) && isTRUE(pdHess)

failure_reason <- if (failed) {
  paste0(stage, ": ", conditionMessage(pipeline_error))
} else if (!clean) {
  interval$profile.message[[1L]]
} else {
  ""
}

receipt <- data.frame(
  cell_id = cell_id,
  target_id = paste0(cell_id, "::", target_name),
  cohort_id = contract$cohort_id,
  family = contract$family_name, provider = contract$provider,
  dgp_id = contract$dgp_id,
  dgp_version = sprintf("%s_seed%d_current_source_v1", rung, seed),
  formula = contract$formula_label,
  true_parameter_scale = contract$true_parameter_scale,
  profile_parameter = target_name, seed = seed,
  execution_information_rung = rung,
  binding_source = "tools/run-arc2-profile-feasibility.R",
  source_sha = source_sha, runner_sha256 = runner_sha256,
  estimator = estimator, target_type = "direct",
  fixture_path = fixture_path, fixture_sha256 = fixture_sha256,
  profile_engine = "tmbprofile", promotion_eligible = clean,
  receipt_scope = "targetwise_interval_feasibility_only_no_coverage",
  conf_status = conf_status, estimate = estimate, lower = lower, upper = upper,
  convergence = convergence, pdHess = pdHess,
  profile_boundary = boundary, clamp_limited = FALSE,
  trace_complete = trace_complete,
  failure_reason = failure_reason,
  trace_path = if (file.exists(trace_path)) trace_path else "",
  trace_sha256 = if (file.exists(trace_path)) file_sha256(trace_path) else "",
  interval_path = if (file.exists(interval_path)) interval_path else "",
  interval_sha256 = if (file.exists(interval_path)) file_sha256(interval_path) else "",
  stringsAsFactors = FALSE
)
receipt_path <- file.path(out, paste0(stem, "-receipt.tsv"))
utils::write.table(receipt, receipt_path, sep = "\t", quote = FALSE, row.names = FALSE)

print(receipt[c(
  "cell_id", "target_id", "estimator", "conf_status", "estimate", "lower", "upper",
  "convergence", "pdHess", "profile_boundary", "trace_complete", "promotion_eligible",
  "failure_reason"
)])

if (!clean) {
  message("Arc 2 contract FAILED for ", cell_id, " (stage=", stage, "): ", failure_reason)
  quit(status = 2L, save = "no")
}
