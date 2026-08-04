#!/usr/bin/env Rscript
# Fixtures for the Prong B Tier 1 profile-fence-integrity guard.
#
# This file defines two independent proofs, as plain data + lazy closures.
# It never itself calls `library(drmTMB)` or a `drmTMB:::` internal at
# SOURCE time -- every reference to drmTMB lives inside a closure (a
# `dpar`/`object` builder, or a route's `build()` function) that only runs
# when a worker process (profile-fence-worker.R), which HAS drmTMB loaded,
# calls it. That lets the orchestrator (check-profile-fence-integrity.R)
# `source()` this file to read expectation metadata without loading any
# drmTMB build itself.
#
# (a) profile_fence_grid() -- the PREDICATE-DOMAIN ENUMERATION. Minimal
#     `object`-shaped stub lists covering the discrete cross-product the
#     deleted/retained fence predicates read (model_type x dpar x
#     structured_mu_type x structured_mu_q x phylo_mu_endpoint_dpars x
#     RE-topology flags on mu/sigma/zoi/coi/mu_sigma). Every stub's OLD-lib
#     (pre-edit) and NEW-lib (post-edit) predicate result is hand-derived and
#     recorded as `expect_old`/`expect_new`, then cross-checked against both
#     real installed libraries below (see the 2026-08-03 report for the
#     verification transcript).
#
# (b) profile_fence_routes() -- the FITTED BATTERY. Real drmTMB() fits, one
#     per route, each reusing the EXACT formula + DGP already proven to pass
#     in tests/testthat/test-zero-one-beta.R, test-count-structured-mu.R,
#     test-phylo-interaction.R, and tools/run-lane-c-c17c1-c14-model15-
#     compatibility.R (cited per route below). `old_ready`/`old_note` and
#     `new_ready`/`new_note` are the hand-derived pre-/post-edit
#     profile_targets() outcomes for each named `parm`.

# ---------------------------------------------------------------------------
# (a) Predicate-domain enumeration: stub-object constructors
# ---------------------------------------------------------------------------

# Field shapes below were verified against a REAL fitted `drmTMB` object
# (zero_one_beta, `sigma ~ 1 + (1 | id)`) on 2026-08-03: `$model$random$sigma`
# carries n_terms/n_re/n_cors/coef_names/covariance_labels; `$model$random$
# mu_sigma` is always a list (never NULL) carrying n_cors;
# `$model$structured$phylo_mu` carries has/type/q/coef_names/dpars/
# endpoint_covariance_labels. See R/drmTMB.R:11515-11725 for the pure
# accessors (`structured_mu_type`, `structured_mu_q`, `phylo_mu_dpars`,
# `phylo_mu_endpoint_dpars`, `phylo_mu_endpoint_covariance_labels`,
# `structured_mu_endpoint_coef_names`, `phylo_mu_covariance_mode`,
# `phylo_mu_has_labelled_mu_intercept_slope_q2`) these stubs must satisfy.
stub_phylo_mu <- function(
  has = FALSE,
  type = "phylo",
  q = 1L,
  dpars = "mu",
  coef_names = "(Intercept)",
  endpoint_covariance_labels = NA_character_,
  covariance_mode = NULL
) {
  list(
    has = isTRUE(has),
    type = type,
    q = as.integer(q),
    dpars = dpars,
    coef_names = coef_names,
    endpoint_covariance_labels = endpoint_covariance_labels,
    covariance_label = NULL,
    covariance_mode = covariance_mode
  )
}

stub_re <- function(
  n_terms = 0L,
  n_re = 0L,
  n_cors = 0L,
  coef_names = character(0),
  covariance_labels = character(0)
) {
  list(
    n_terms = as.integer(n_terms),
    n_re = as.integer(n_re),
    n_cors = as.integer(n_cors),
    coef_names = coef_names,
    covariance_labels = covariance_labels
  )
}

stub_object <- function(model_type, phylo_mu = stub_phylo_mu(), random = list()) {
  base_random <- list(
    mu = stub_re(), sigma = stub_re(), zoi = stub_re(), coi = stub_re(),
    mu_sigma = list(n_cors = 0L)
  )
  list(model = list(
    model_type = model_type,
    random = utils::modifyList(base_random, random),
    structured = list(phylo_mu = phylo_mu)
  ))
}

grid_row <- function(
  id, group, kind, dpar, object,
  expect_old, expect_new, internal = NA_character_
) {
  list(
    id = id, group = group, kind = kind, dpar = dpar, internal = internal,
    object = object, expect_old = expect_old, expect_new = expect_new
  )
}

# Convenience constructors for the recurring shapes.
zob_sigma_structured_q1 <- function(provider) stub_object(
  "zero_one_beta",
  stub_phylo_mu(has = TRUE, type = provider, q = 1L, dpars = "sigma", coef_names = "(Intercept)")
)
zob_dpar_structured_q1 <- function(provider, dpar) stub_object(
  "zero_one_beta",
  stub_phylo_mu(has = TRUE, type = provider, q = 1L, dpars = dpar, coef_names = "(Intercept)")
)
count_mu_q2_labelled <- function(model_type, provider) stub_object(
  model_type,
  stub_phylo_mu(
    has = TRUE, type = provider, q = 2L, dpars = c("mu", "mu"),
    coef_names = c("(Intercept)", "x"), endpoint_covariance_labels = c("p", "p")
  )
)
count_sigma_phylo_interaction_q1 <- function(model_type) stub_object(
  model_type,
  stub_phylo_mu(has = TRUE, type = "phylo_interaction", q = 1L, dpars = "sigma", coef_names = "(Intercept)")
)
zob_sigma_ordinary_re <- function(coef_name) stub_object(
  "zero_one_beta",
  stub_phylo_mu(has = FALSE),
  random = list(sigma = stub_re(n_terms = 1L, n_re = 8L, n_cors = 0L, coef_names = coef_name, covariance_labels = NA_character_))
)
zi_nbinom2_sigma_ordinary_re <- function(n_terms = 1L, n_re = 6L, coef_names = "(Intercept)", covariance_labels = NA_character_, structured_has = FALSE) stub_object(
  "zi_nbinom2",
  stub_phylo_mu(has = structured_has),
  random = list(sigma = stub_re(n_terms = n_terms, n_re = n_re, n_cors = 0L, coef_names = coef_names, covariance_labels = covariance_labels))
)

# ---------------------------------------------------------------------------
# (a) The grid itself
# ---------------------------------------------------------------------------
profile_fence_grid <- function() {
  rows <- list()
  add <- function(...) rows[[length(rows) + 1L]] <<- grid_row(...)

  providers <- c("phylo", "animal", "relmat", "spatial", "phylo_interaction")

  # --- Group 1: the 14 routes that MUST flip TRUE(old,restricted) ->
  # FALSE(new,open)/ABSENT(new). Mirrors the task brief's 14-route list
  # exactly (mc-IDs are the capability-ledger cell IDs; see
  # docs/dev-log/dashboard/capability-ledger/cells.tsv, read-only citation).
  #
  # 1a. zero_one_beta sigma STRUCTURED, 5 providers (mc-0593..0597):
  #     R/profile.R count_point_fit_only_profile_restricted narrowed its
  #     zero_one_beta dpar set from c("mu","sigma","zoi","coi") to
  #     c("mu","zoi","coi") -- "sigma" dropped out.
  for (p in providers) {
    add(
      id = paste0("open-zob-sigma-structured-", p), group = "open-14",
      kind = "count_point_fit_only", dpar = "sigma",
      object = zob_sigma_structured_q1(p), expect_old = TRUE, expect_new = FALSE
    )
  }

  # 1b. poisson/nbinom2 mu labelled q2 (mc-0418, mc-0436/0446/0450/0454):
  # the whole `(identical(dpar,"mu") && count_labelled_q2_profile_restricted(object))`
  # disjunct was deleted.
  add(
    id = "open-nbinom2-mu-q2-phylo", group = "open-14",
    kind = "count_point_fit_only", dpar = "mu",
    object = count_mu_q2_labelled("nbinom2", "phylo"), expect_old = TRUE, expect_new = FALSE
  )
  for (p in c("phylo", "spatial", "animal", "relmat")) {
    add(
      id = paste0("open-poisson-mu-q2-", p), group = "open-14",
      kind = "count_point_fit_only", dpar = "mu",
      object = count_mu_q2_labelled("poisson", p), expect_old = TRUE, expect_new = FALSE
    )
  }

  # 1c. nbinom2/zi_nbinom2 sigma phylo_interaction q1 (mc-0425, mc-0653): the
  # `count_sigma_interaction_profile_restricted` disjunct was deleted.
  add(
    id = "open-nbinom2-sigma-phylo-interaction", group = "open-14",
    kind = "count_point_fit_only", dpar = "sigma",
    object = count_sigma_phylo_interaction_q1("nbinom2"), expect_old = TRUE, expect_new = FALSE
  )
  add(
    id = "open-zi-nbinom2-sigma-phylo-interaction", group = "open-14",
    kind = "count_point_fit_only", dpar = "sigma",
    object = count_sigma_phylo_interaction_q1("zi_nbinom2"), expect_old = TRUE, expect_new = FALSE
  )

  # 1d. zero_one_beta sigma ORDINARY, intercept + slope (mc-0568, mc-0576):
  # a separate, wholly deleted predicate `zero_one_beta_sigma_q1_profile_
  # restricted()` (not a disjunct of count_point_fit_only). expect_new =
  # NA here means "function must not exist in the new lib" (see worker).
  add(
    id = "open-zob-sigma-ordinary-intercept", group = "open-14",
    kind = "zero_one_beta_sigma_q1_deleted", dpar = "sigma", internal = "log_sd_sigma",
    object = zob_sigma_ordinary_re("(Intercept)"), expect_old = TRUE, expect_new = NA
  )
  add(
    id = "open-zob-sigma-ordinary-slope", group = "open-14",
    kind = "zero_one_beta_sigma_q1_deleted", dpar = "sigma", internal = "log_sd_sigma",
    object = zob_sigma_ordinary_re("x"), expect_old = TRUE, expect_new = NA
  )

  # --- Group 2: MUST-STAY-FENCED, via count_point_fit_only_profile_restricted
  # (expect_old == expect_new == TRUE everywhere: unchanged).
  add(
    id = "fenced-zi-nbinom2-sigma-q1", group = "fenced",
    kind = "count_point_fit_only", dpar = "sigma",
    object = zi_nbinom2_sigma_ordinary_re(), expect_old = TRUE, expect_new = TRUE
  )
  for (p in providers) {
    add(
      id = paste0("fenced-zob-mu-structured-", p), group = "fenced",
      kind = "count_point_fit_only", dpar = "mu",
      object = zob_dpar_structured_q1(p, "mu"), expect_old = TRUE, expect_new = TRUE
    )
    add(
      id = paste0("fenced-zob-zoi-structured-", p), group = "fenced",
      kind = "count_point_fit_only", dpar = "zoi",
      object = zob_dpar_structured_q1(p, "zoi"), expect_old = TRUE, expect_new = TRUE
    )
    add(
      id = paste0("fenced-zob-coi-structured-", p), group = "fenced",
      kind = "count_point_fit_only", dpar = "coi",
      object = zob_dpar_structured_q1(p, "coi"), expect_old = TRUE, expect_new = TRUE
    )
  }

  # --- Group 3: negative controls / decision-boundary probes. All
  # expect_old == expect_new == FALSE: these shapes were never gated and
  # must still never be gated. Each isolates ONE conjunct.
  add(
    id = "neg-gaussian-mu-q2-phylo", group = "negative",
    kind = "count_point_fit_only", dpar = "mu",
    object = count_mu_q2_labelled("gaussian", "phylo"), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-biv-gaussian-mu-q2-phylo", group = "negative",
    kind = "count_point_fit_only", dpar = "mu",
    object = count_mu_q2_labelled("biv_gaussian", "phylo"), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-zob-mu-no-structure", group = "negative",
    kind = "count_point_fit_only", dpar = "mu",
    object = stub_object("zero_one_beta", stub_phylo_mu(has = FALSE)), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-zob-sigma-structured-q2", group = "negative",
    kind = "count_point_fit_only", dpar = "sigma",
    object = stub_object("zero_one_beta", stub_phylo_mu(has = TRUE, type = "phylo", q = 2L, dpars = c("sigma", "sigma"), coef_names = c("(Intercept)", "x"), endpoint_covariance_labels = c("p", "p"))),
    expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-zob-sigma-structured-unknown-provider", group = "negative",
    kind = "count_point_fit_only", dpar = "sigma",
    object = zob_sigma_structured_q1("not_a_real_provider"), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-nbinom2-mu-q2-spatial-not-permitted", group = "negative",
    kind = "count_point_fit_only", dpar = "mu",
    object = count_mu_q2_labelled("nbinom2", "spatial"), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-poisson-mu-q2-phylo-unlabelled", group = "negative",
    kind = "count_point_fit_only", dpar = "mu",
    object = stub_object("poisson", stub_phylo_mu(has = TRUE, type = "phylo", q = 2L, dpars = c("mu", "mu"), coef_names = c("(Intercept)", "x"), endpoint_covariance_labels = c(NA, NA))),
    expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-poisson-mu-q2-phylo-cross-dpar", group = "negative",
    kind = "count_point_fit_only", dpar = "mu",
    object = stub_object("poisson", stub_phylo_mu(has = TRUE, type = "phylo", q = 2L, dpars = c("mu", "sigma"), coef_names = c("(Intercept)", "x"), endpoint_covariance_labels = c("p", "p"))),
    expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-nbinom2-sigma-phylo-not-interaction", group = "negative",
    kind = "count_point_fit_only", dpar = "sigma",
    object = stub_object("nbinom2", stub_phylo_mu(has = TRUE, type = "phylo", q = 1L, dpars = "sigma", coef_names = "(Intercept)")),
    expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-nbinom2-mu-phylo-interaction-wrong-dpar", group = "negative",
    kind = "count_point_fit_only", dpar = "mu",
    object = count_sigma_phylo_interaction_q1("nbinom2"), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-hurdle-nbinom2-sigma-phylo-interaction", group = "negative",
    kind = "count_point_fit_only", dpar = "sigma",
    object = count_sigma_phylo_interaction_q1("hurdle_nbinom2"), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-zi-poisson-mu-q2-phylo", group = "negative",
    kind = "count_point_fit_only", dpar = "mu",
    object = count_mu_q2_labelled("zi_poisson", "phylo"), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "neg-zob-rho12-structured", group = "negative",
    kind = "count_point_fit_only", dpar = "rho12",
    object = zob_dpar_structured_q1("phylo", "rho12"), expect_old = FALSE, expect_new = FALSE
  )

  # zi_nbinom2_sigma_q1_profile_restricted direct probes (retained/
  # unchanged; expect_old == expect_new for every row -- a control on the
  # control).
  add(
    id = "zi-ctrl-sigma-q1-true", group = "retained-control",
    kind = "zi_nbinom2_sigma_q1", dpar = "sigma",
    object = zi_nbinom2_sigma_ordinary_re(), expect_old = TRUE, expect_new = TRUE
  )
  add(
    id = "zi-ctrl-wrong-dpar", group = "retained-control",
    kind = "zi_nbinom2_sigma_q1", dpar = "mu",
    object = zi_nbinom2_sigma_ordinary_re(), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "zi-ctrl-two-terms", group = "retained-control",
    kind = "zi_nbinom2_sigma_q1", dpar = "sigma",
    object = zi_nbinom2_sigma_ordinary_re(n_terms = 2L), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "zi-ctrl-slope-not-intercept", group = "retained-control",
    kind = "zi_nbinom2_sigma_q1", dpar = "sigma",
    object = zi_nbinom2_sigma_ordinary_re(coef_names = "x"), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "zi-ctrl-labelled-not-iid", group = "retained-control",
    kind = "zi_nbinom2_sigma_q1", dpar = "sigma",
    object = zi_nbinom2_sigma_ordinary_re(covariance_labels = "p"), expect_old = FALSE, expect_new = FALSE
  )
  add(
    id = "zi-ctrl-structured-excludes-ordinary", group = "retained-control",
    kind = "zi_nbinom2_sigma_q1", dpar = "sigma",
    object = zi_nbinom2_sigma_ordinary_re(structured_has = TRUE), expect_old = FALSE, expect_new = FALSE
  )

  # zero_one_beta_zoi_q1_profile_restricted / _coi_q1_ direct probes
  # (retained/unchanged; R/profile.R:4043-4062, untouched by the diff).
  zob_zoi_topology <- function(zoi_re = TRUE, mu_re = 0L, sigma_re = 0L) stub_object(
    "zero_one_beta", stub_phylo_mu(has = FALSE),
    random = list(
      zoi = if (zoi_re) stub_re(n_terms = 1L, n_re = 8L, n_cors = 0L) else stub_re(n_terms = 0L),
      mu = stub_re(n_re = mu_re), sigma = stub_re(n_re = sigma_re)
    )
  )
  add(id = "zoi-ctrl-clean", group = "retained-control", kind = "zero_one_beta_zoi_q1", dpar = "zoi", internal = "log_sd_zoi", object = zob_zoi_topology(), expect_old = TRUE, expect_new = TRUE)
  add(id = "zoi-ctrl-mu-re-present", group = "retained-control", kind = "zero_one_beta_zoi_q1", dpar = "zoi", internal = "log_sd_zoi", object = zob_zoi_topology(mu_re = 4L), expect_old = FALSE, expect_new = FALSE)
  add(id = "zoi-ctrl-sigma-re-present", group = "retained-control", kind = "zero_one_beta_zoi_q1", dpar = "zoi", internal = "log_sd_zoi", object = zob_zoi_topology(sigma_re = 4L), expect_old = FALSE, expect_new = FALSE)
  add(id = "zoi-ctrl-wrong-dpar", group = "retained-control", kind = "zero_one_beta_zoi_q1", dpar = "coi", internal = "log_sd_zoi", object = zob_zoi_topology(), expect_old = FALSE, expect_new = FALSE)
  add(id = "zoi-ctrl-wrong-internal", group = "retained-control", kind = "zero_one_beta_zoi_q1", dpar = "zoi", internal = "log_sd_sigma", object = zob_zoi_topology(), expect_old = FALSE, expect_new = FALSE)

  zob_coi_topology <- function(coi_re = TRUE, mu_re = 0L, sigma_re = 0L, zoi_re = 0L) stub_object(
    "zero_one_beta", stub_phylo_mu(has = FALSE),
    random = list(
      coi = if (coi_re) stub_re(n_terms = 1L, n_re = 8L, n_cors = 0L) else stub_re(n_terms = 0L),
      mu = stub_re(n_re = mu_re), sigma = stub_re(n_re = sigma_re), zoi = stub_re(n_re = zoi_re)
    )
  )
  add(id = "coi-ctrl-clean", group = "retained-control", kind = "zero_one_beta_coi_q1", dpar = "coi", internal = "log_sd_coi", object = zob_coi_topology(), expect_old = TRUE, expect_new = TRUE)
  add(id = "coi-ctrl-mu-re-present", group = "retained-control", kind = "zero_one_beta_coi_q1", dpar = "coi", internal = "log_sd_coi", object = zob_coi_topology(mu_re = 4L), expect_old = FALSE, expect_new = FALSE)
  add(id = "coi-ctrl-zoi-re-present", group = "retained-control", kind = "zero_one_beta_coi_q1", dpar = "coi", internal = "log_sd_coi", object = zob_coi_topology(zoi_re = 4L), expect_old = FALSE, expect_new = FALSE)
  add(id = "coi-ctrl-wrong-dpar", group = "retained-control", kind = "zero_one_beta_coi_q1", dpar = "zoi", internal = "log_sd_coi", object = zob_coi_topology(), expect_old = FALSE, expect_new = FALSE)

  rows
}

# The 3 wholesale-deleted functions never called directly above (their
# effect on `count_point_fit_only_profile_restricted` is already exercised
# via Group 1a/1b/1c/2/3; this is a direct, independent existence check that
# machine-verifies the background section's "Deleted: ..." claim).
profile_fence_deleted_fn_names <- function() {
  c(
    "count_labelled_q2_profile_restricted",
    "count_labelled_q2_profile_restricted_status",
    "count_sigma_interaction_profile_restricted"
  )
}

# All function names ever probed (existence and/or call), for the worker's
# provenance stamp (includes the 4th deleted fn, called directly in Group 1d,
# plus the always-retained controls).
profile_fence_all_probed_fn_names <- function() {
  c(
    profile_fence_deleted_fn_names(),
    "zero_one_beta_sigma_q1_profile_restricted",
    "count_point_fit_only_profile_restricted",
    "zi_nbinom2_sigma_q1_profile_restricted",
    "zero_one_beta_zoi_q1_profile_restricted",
    "zero_one_beta_coi_q1_profile_restricted"
  )
}

# ---------------------------------------------------------------------------
# (b) Fitted battery: route table
# ---------------------------------------------------------------------------
# Every `build()` below reuses an EXACT formula + DGP already proven to pass
# in the repo (cited per route). Only two deliberate departures from the
# cited source: (i) `control` always forces `se = TRUE` (several cited tests
# use `se = FALSE` purely for unrelated gradient-oracle speed; this battery's
# job is partly to prove "se=TRUE succeeds" for the newly-opened routes, so
# se=TRUE is used everywhere for a uniform proof); (ii) each route's `checks`
# list is new (added here), the fits/formulas themselves are not.

route <- function(id, status, description, build, checks) {
  list(id = id, status = status, description = description, build = build, checks = checks)
}
chk <- function(parm, dpar, old_ready, old_note, new_ready, new_note, tmb_parameter) {
  list(
    parm = parm, dpar = dpar,
    old_ready = old_ready, old_note = old_note,
    new_ready = new_ready, new_note = new_note,
    tmb_parameter = tmb_parameter
  )
}

profile_fence_routes <- function() {
  routes <- list()
  add <- function(x) routes[[length(routes) + 1L]] <<- x

  # --- mc-0568 / mc-0576: zero_one_beta sigma ORDINARY q1 (intercept /
  # slope). Canonical DGP + formula:
  # tools/run-lane-c-c17c1-c14-model15-compatibility.R:19-23 (standard_x),
  # :25-39 (simulate_sigma_intercept), :68-86 (simulate_sigma_slope),
  # :88-113 (route_spec formulas + first seed of each seed range).
  standard_x <- function(id) {
    x <- stats::rnorm(length(id))
    x <- x - ave(x, id, FUN = mean)
    x / stats::sd(x)
  }
  simulate_sigma_intercept <- function(seed, tau = 0.45) {
    set.seed(seed)
    id <- factor(rep(paste0("g", seq_len(32L)), each = 30L))
    x <- standard_x(id)
    b <- stats::rnorm(32L, sd = tau); names(b) <- levels(id)
    mu <- stats::plogis(-0.15 + 0.35 * x)
    sigma <- exp(log(0.45) + b[as.character(id)])
    boundary <- stats::rbinom(length(id), 1L, 0.14)
    y <- ifelse(
      boundary == 1L,
      stats::rbinom(length(id), 1L, 0.40),
      stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
    )
    data.frame(y, x, id)
  }
  simulate_sigma_slope <- function(seed, tau = 0.45) {
    set.seed(seed)
    id <- factor(rep(paste0("g", seq_len(32L)), each = 50L))
    x <- standard_x(id)
    b <- stats::rnorm(32L, sd = tau); names(b) <- levels(id)
    mu <- stats::plogis(-.15 + .35 * x)
    sigma <- exp(-1 + b[as.character(id)] * x)
    zoi <- stats::plogis(-0.7)
    boundary <- stats::rbinom(length(id), 1L, zoi)
    y <- stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
    y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, stats::plogis(0.1))
    data.frame(y, x, id)
  }

  add(route(
    "mc-0568", "open",
    "zero_one_beta sigma ordinary random intercept q1 (tools/run-lane-c-c17c1-c14-model15-compatibility.R:89-96)",
    function() list(
      data = simulate_sigma_intercept(2026073401L),
      formula = drmTMB::bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1),
      family = drmTMB::zero_one_beta(),
      control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 3000L, iter.max = 3000L))
    ),
    list(chk(
      "sd:sigma:(1 | id)", "sigma",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_sigma_q1",
      new_ready = TRUE, new_note = "ready", tmb_parameter = "log_sd_sigma"
    ))
  ))

  add(route(
    "mc-0576", "open",
    "zero_one_beta sigma ordinary random slope q1 (tools/run-lane-c-c17c1-c14-model15-compatibility.R:105-112)",
    function() list(
      data = simulate_sigma_slope(2026073701L),
      formula = drmTMB::bf(y ~ x, sigma ~ x + (0 + x | id), zoi ~ 1, coi ~ 1),
      family = drmTMB::zero_one_beta(),
      control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 3000L, iter.max = 3000L))
    ),
    list(chk(
      "sd:sigma:(0 + x | id)", "sigma",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_sigma_q1",
      new_ready = TRUE, new_note = "ready", tmb_parameter = "log_sd_sigma"
    ))
  ))

  # --- mc-0593..0597: zero_one_beta sigma STRUCTURED q1, 5 providers.
  # DGP + formula + old-note citations:
  #  phylo:             tests/testthat/test-zero-one-beta.R
  #  animal:            tests/testthat/test-zero-one-beta.R
  #  relmat:            tests/testthat/test-zero-one-beta.R
  #  spatial:           tests/testthat/test-zero-one-beta.R
  #  phylo_interaction: tests/testthat/test-zero-one-beta.R, DGP
  #    helper new_zero_one_beta_phylo_interaction_data() at :120-131.
  dense_zoib_phylo_precision <- function(tree) {
    n_tip <- length(tree$tip.label)
    n_total <- n_tip + tree$Nnode
    root <- setdiff(tree$edge[, 1L], tree$edge[, 2L])
    stopifnot(length(root) == 1L)
    included <- setdiff(seq_len(n_total), root)
    index <- integer(n_total); index[included] <- seq_along(included)
    Q <- matrix(0, length(included), length(included))
    for (edge_id in seq_len(nrow(tree$edge))) {
      parent <- tree$edge[edge_id, 1L]; child <- tree$edge[edge_id, 2L]
      weight <- 1 / tree$edge.length[edge_id]
      child_index <- index[[child]]
      Q[child_index, child_index] <- Q[child_index, child_index] + weight
      if (parent != root) {
        parent_index <- index[[parent]]
        Q[parent_index, parent_index] <- Q[parent_index, parent_index] + weight
        Q[parent_index, child_index] <- Q[parent_index, child_index] - weight
        Q[child_index, parent_index] <- Q[child_index, parent_index] - weight
      }
    }
    height <- max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
    list(Q = height * Q, log_det = length(included) * log(height) - sum(log(tree$edge.length)), tip_index = index[seq_len(n_tip)])
  }
  dense_zoib_spatial_precision <- function(coords, site_levels, jitter = 1e-6) {
    coords <- as.matrix(coords)[site_levels, seq_len(2L), drop = FALSE]
    distances <- as.matrix(stats::dist(coords))
    positive <- distances[distances > 0]
    range <- stats::median(positive)
    if (!is.finite(range) || range <= 0) range <- max(positive)
    K <- exp(-distances / range); diag(K) <- diag(K) + jitter
    chol_K <- chol(K)
    list(Q = chol2inv(chol_K), log_det_Q = -2 * sum(log(diag(chol_K))), levels = site_levels)
  }
  zob_sigma_control <- function() drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))

  add(route(
    "mc-0593", "open", "zero_one_beta sigma structured phylo q1 (tests/testthat/test-zero-one-beta.R)",
    function() {
      set.seed(2026074001L)
      tree <- ape::stree(16L, type = "balanced"); tree$edge.length <- rep(1, nrow(tree$edge)); tree$tip.label <- paste0("sp", seq_len(16L))
      precision <- dense_zoib_phylo_precision(tree)
      u <- as.numeric(t(chol(solve(precision$Q))) %*% stats::rnorm(nrow(precision$Q), sd = .45)); names(u) <- tree$tip.label
      species <- rep(tree$tip.label, each = 40L); x <- stats::rnorm(length(species))
      mu <- stats::plogis(-.15 + .35 * x); sigma <- exp(-1 + u[species]); zoi <- stats::plogis(-1.1); coi <- stats::plogis(.1)
      boundary <- stats::rbinom(length(x), 1L, zoi); y <- stats::rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2); y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
      list(
        data = data.frame(y, x, species), formula = drmTMB::bf(y ~ x, sigma ~ phylo(1 | species, tree = tree), zoi ~ 1, coi ~ 1),
        family = drmTMB::zero_one_beta(), control = zob_sigma_control()
      )
    },
    list(chk(
      "sd:sigma:phylo(1 | species)", "sigma",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_phylo_q1",
      new_ready = TRUE, new_note = "ready", tmb_parameter = "log_sd_phylo"
    ))
  ))

  add(route(
    "mc-0594", "open", "zero_one_beta sigma structured animal q1 (tests/testthat/test-zero-one-beta.R)",
    function() {
      set.seed(2026074101L); n <- 16L; labels <- paste0("sp", seq_len(n))
      Ainv <- diag(2, n); Ainv[cbind(seq_len(n - 1L), seq.int(2L, n))] <- -.5; Ainv[cbind(seq.int(2L, n), seq_len(n - 1L))] <- -.5
      rownames(Ainv) <- colnames(Ainv) <- rev(labels)
      u <- as.numeric(t(chol(solve(Ainv))) %*% stats::rnorm(n, sd = .45)); names(u) <- rownames(Ainv)
      species <- rep(labels, each = 40L); x <- stats::rnorm(length(species))
      mu <- stats::plogis(-.15 + .35 * x); sigma <- exp(-1 + u[species]); zoi <- stats::plogis(-1.1); coi <- stats::plogis(.1)
      boundary <- stats::rbinom(length(x), 1L, zoi); y <- stats::rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2); y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
      list(
        data = data.frame(y, x, species), formula = drmTMB::bf(y ~ x, sigma ~ animal(1 | species, Ainv = Ainv), zoi ~ 1, coi ~ 1),
        family = drmTMB::zero_one_beta(), control = zob_sigma_control()
      )
    },
    list(chk(
      "sd:sigma:animal(1 | species)", "sigma",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_animal_q1",
      new_ready = TRUE, new_note = "ready", tmb_parameter = "log_sd_phylo"
    ))
  ))

  add(route(
    "mc-0595", "open", "zero_one_beta sigma structured relmat q1 (tests/testthat/test-zero-one-beta.R)",
    function() {
      set.seed(2026074201L); n <- 16L; labels <- paste0("sp", seq_len(n))
      Q <- diag(2, n); Q[cbind(seq_len(n - 1L), seq.int(2L, n))] <- -.5; Q[cbind(seq.int(2L, n), seq_len(n - 1L))] <- -.5
      rownames(Q) <- colnames(Q) <- rev(labels); K <- solve(Q)
      u <- as.numeric(t(chol(K)) %*% stats::rnorm(n, sd = .45)); names(u) <- rownames(K)
      species <- rep(labels, each = 40L); x <- stats::rnorm(length(species))
      mu <- stats::plogis(-.15 + .35 * x); sigma <- exp(-1 + u[species]); zoi <- stats::plogis(-1.1); coi <- stats::plogis(.1)
      boundary <- stats::rbinom(length(x), 1L, zoi); y <- stats::rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2); y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
      list(
        data = data.frame(y, x, species), formula = drmTMB::bf(y ~ x, sigma ~ relmat(1 | species, K = K), zoi ~ 1, coi ~ 1),
        family = drmTMB::zero_one_beta(), control = zob_sigma_control()
      )
    },
    list(chk(
      "sd:sigma:relmat(1 | species)", "sigma",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_relmat_q1",
      new_ready = TRUE, new_note = "ready", tmb_parameter = "log_sd_phylo"
    ))
  ))

  add(route(
    "mc-0596", "open", "zero_one_beta sigma structured spatial q1 (tests/testthat/test-zero-one-beta.R)",
    function() {
      set.seed(2026074301L); n <- 16L; labels <- paste0("site", seq_len(n))
      coords <- cbind(seq_len(n), (seq_len(n) %% 5L) / 3); rownames(coords) <- rev(labels)
      precision <- dense_zoib_spatial_precision(coords, labels)
      u <- as.numeric(t(chol(solve(precision$Q))) %*% stats::rnorm(n, sd = .45)); names(u) <- labels
      site <- rep(labels, each = 40L); x <- stats::rnorm(length(site))
      mu <- stats::plogis(-.15 + .35 * x); sigma <- exp(-1 + u[site]); zoi <- stats::plogis(-1.1); coi <- stats::plogis(.1)
      boundary <- stats::rbinom(length(x), 1L, zoi); y <- stats::rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2); y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
      list(
        data = data.frame(y, x, site), formula = drmTMB::bf(y ~ x, sigma ~ spatial(1 | site, coords = coords), zoi ~ 1, coi ~ 1),
        family = drmTMB::zero_one_beta(), control = zob_sigma_control()
      )
    },
    list(chk(
      "sd:sigma:spatial(1 | site)", "sigma",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_spatial_q1",
      new_ready = TRUE, new_note = "ready", tmb_parameter = "log_sd_phylo"
    ))
  ))

  add(route(
    "mc-0597", "open", "zero_one_beta sigma structured phylo_interaction q1 (tests/testthat/test-zero-one-beta.R)",
    function() {
      set.seed(2026073301L); n_each <- 30L
      plant_tree <- ape::stree(4L, type = "balanced"); plant_tree$edge.length <- rep(1, nrow(plant_tree$edge)); plant_tree$tip.label <- paste0("plant", 1:4)
      pollinator_tree <- ape::stree(4L, type = "balanced"); pollinator_tree$edge.length <- rep(1, nrow(pollinator_tree$edge)); pollinator_tree$tip.label <- paste0("poll", 1:4)
      V <- kronecker(drmTMB:::drm_phylo_tip_covariance(pollinator_tree), drmTMB:::drm_phylo_tip_covariance(plant_tree))
      grid <- expand.grid(plant = plant_tree$tip.label, pollinator = pollinator_tree$tip.label, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
      u <- as.numeric(t(chol(V)) %*% stats::rnorm(nrow(grid), sd = .55)); names(u) <- paste0(grid$plant, ":", grid$pollinator)
      data <- grid[rep(seq_len(nrow(grid)), each = n_each), , drop = FALSE]
      data$x <- stats::rnorm(nrow(data)); data$x <- data$x - ave(data$x, interaction(data$plant, data$pollinator), FUN = mean); data$x <- data$x / stats::sd(data$x)
      mu <- stats::plogis(-.10 + .35 * data$x + u[paste0(data$plant, ":", data$pollinator)]); boundary <- stats::rbinom(nrow(data), 1, .12)
      data$y <- ifelse(boundary == 1, stats::rbinom(nrow(data), 1, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
      list(
        data = data,
        formula = drmTMB::bf(y ~ x, sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree), zoi ~ 1, coi ~ 1),
        family = drmTMB::zero_one_beta(), control = zob_sigma_control()
      )
    },
    list(chk(
      "sd:sigma:phylo_interaction(1 | plant:pollinator)", "sigma",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_phylo_interaction_q1",
      new_ready = TRUE, new_note = "ready", tmb_parameter = "log_sd_phylo"
    ))
  ))

  # --- mc-0418/0436/0446/0450/0454: poisson/nbinom2 mu labelled q2. DGP
  # helper new_count_structured_mu_slope_data(), from
  # tests/testthat/test-count-structured-mu.R. Anchors are seeds and function
  # names, not line numbers: line pins in this file went stale in the same
  # commit that introduced them, so grep the seed or the helper name instead.
  # Formulae and seeds: nbinom2 phylo seed 2026072801; poisson phylo seed
  # 2026072811; poisson spatial/animal/relmat seed 2026072908. Target names
  # and tmb_parameter come from expect_count_labelled_q2_profile_restriction()
  # and expect_poisson_labelled_q2_provider_fit() in the same file.
  new_count_structured_mu_slope_data <- function(seed, n_level = 8L, n_each = 20L, sd_intercept = 0.25, sd_slope = 0.45, rho_phylo = 0, rho_provider = 0, sigma_nb2 = 0.20) {
    set.seed(seed)
    levels <- paste0("id", seq_len(n_level))
    site <- rep(levels, each = n_each); id <- site; x <- stats::rnorm(length(site))
    theta <- seq(0, 1.75 * pi, length.out = n_level)
    coords <- data.frame(x = cos(theta) + seq_len(n_level) / (4 * n_level), y = sin(theta)); rownames(coords) <- levels
    precision <- drmTMB:::drm_spatial_coords_precision(coords, site = levels, group = "site")
    spatial_covariance <- solve(as.matrix(precision$precision))
    K <- outer(seq_len(n_level), seq_len(n_level), function(i, j) 0.35^abs(i - j)); diag(K) <- diag(K) + 0.15
    dimnames(K) <- list(levels, levels); Q <- solve(K)
    tree <- ape::stree(n_level, type = "balanced"); tree$tip.label <- levels; tree$edge.length <- rep(1, nrow(tree$edge))
    phylo_covariance <- drmTMB:::drm_phylo_tip_covariance(tree); phylo_covariance <- phylo_covariance[levels, levels]
    draw_fields <- function(covariance, rho = 0) {
      chol_covariance <- chol(covariance + diag(1e-8, nrow(covariance)))
      z_intercept <- stats::rnorm(nrow(covariance))
      z_slope <- rho * z_intercept + sqrt(1 - rho^2) * stats::rnorm(nrow(covariance))
      intercept <- as.vector(t(chol_covariance) %*% z_intercept * sd_intercept)
      slope <- as.vector(t(chol_covariance) %*% z_slope * sd_slope)
      names(intercept) <- rownames(covariance); names(slope) <- rownames(covariance)
      list(intercept = intercept, slope = slope)
    }
    fields <- list(phylo = draw_fields(phylo_covariance, rho = rho_phylo), spatial = draw_fields(spatial_covariance, rho = rho_provider), known = draw_fields(K, rho = rho_provider))
    beta_mu <- c(`(Intercept)` = 0.55, x = -0.15)
    eta <- list(
      phylo = beta_mu[[1L]] + beta_mu[[2L]] * x + fields$phylo$intercept[site] + x * fields$phylo$slope[site],
      spatial = beta_mu[[1L]] + beta_mu[[2L]] * x + fields$spatial$intercept[site] + x * fields$spatial$slope[site],
      known = beta_mu[[1L]] + beta_mu[[2L]] * x + fields$known$intercept[id] + x * fields$known$slope[id]
    )
    data <- data.frame(
      poisson_phylo = stats::rpois(length(site), lambda = exp(eta$phylo)),
      poisson_spatial = stats::rpois(length(site), lambda = exp(eta$spatial)),
      poisson_known = stats::rpois(length(site), lambda = exp(eta$known)),
      nb2_phylo = stats::rnbinom(length(site), size = 1 / sigma_nb2^2, mu = exp(eta$phylo)),
      nb2_spatial = stats::rnbinom(length(site), size = 1 / sigma_nb2^2, mu = exp(eta$spatial)),
      nb2_known = stats::rnbinom(length(site), size = 1 / sigma_nb2^2, mu = exp(eta$known)),
      x = x, site = site, id = id
    )
    list(data = data, coords = coords, tree = tree, Q = Q)
  }
  q2_targets <- function(provider, group) c(
    paste0("sd:mu:", provider, "(1 | p | ", group, ")"),
    paste0("sd:mu:", provider, "(0 + x | p | ", group, ")"),
    paste0("cor:", provider, ":cor(mu:(Intercept),mu:x | p | ", group, ")")
  )
  q2_checks <- function(provider, group) {
    parms <- q2_targets(provider, group)
    list(
      chk(parms[[1L]], "mu", FALSE, "point_fit_only_count_q2", TRUE, "ready", "log_sd_phylo"),
      chk(parms[[2L]], "mu", FALSE, "point_fit_only_count_q2", TRUE, "ready", "log_sd_phylo"),
      chk(parms[[3L]], "mu", FALSE, "point_fit_only_count_q2", TRUE, "ready", "eta_cor_phylo")
    )
  }

  add(route(
    "mc-0418", "open", "nbinom2 mu labelled phylo q2 (tests/testthat/test-count-structured-mu.R)",
    function() {
      sim <- new_count_structured_mu_slope_data(seed = 2026072801, n_level = 16L, n_each = 24L, rho_phylo = 0.35)
      tree <- sim$tree
      list(
        data = sim$data, formula = drmTMB::bf(nb2_phylo ~ x + phylo(1 + x | p | site, tree = tree), sigma ~ 1),
        family = drmTMB::nbinom2(), control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))
      )
    },
    q2_checks("phylo", "site")
  ))
  add(route(
    "mc-0436", "open", "poisson mu labelled phylo q2 (tests/testthat/test-count-structured-mu.R)",
    function() {
      sim <- new_count_structured_mu_slope_data(seed = 2026072811, n_level = 16L, n_each = 24L, rho_phylo = 0.35)
      tree <- sim$tree
      list(
        data = sim$data, formula = drmTMB::bf(poisson_phylo ~ x + phylo(1 + x | p | site, tree = tree)),
        family = stats::poisson(link = "log"), control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))
      )
    },
    q2_checks("phylo", "site")
  ))
  add(route(
    "mc-0446", "open", "poisson mu labelled spatial q2 (tests/testthat/test-count-structured-mu.R)",
    function() {
      sim <- new_count_structured_mu_slope_data(seed = 2026072908, n_level = 16L, n_each = 24L, rho_provider = 0.35)
      coords <- sim$coords
      list(
        data = sim$data, formula = drmTMB::bf(poisson_spatial ~ x + spatial(1 + x | p | site, coords = coords)),
        family = stats::poisson(link = "log"), control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))
      )
    },
    q2_checks("spatial", "site")
  ))
  add(route(
    "mc-0450", "open", "poisson mu labelled animal q2 (tests/testthat/test-count-structured-mu.R)",
    function() {
      sim <- new_count_structured_mu_slope_data(seed = 2026072908, n_level = 16L, n_each = 24L, rho_provider = 0.35)
      Q <- sim$Q
      data <- sim$data; data$id <- factor(data$id, levels = rownames(Q))
      list(
        data = data, formula = drmTMB::bf(poisson_known ~ x + animal(1 + x | p | id, Ainv = Q)),
        family = stats::poisson(link = "log"), control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))
      )
    },
    q2_checks("animal", "id")
  ))
  add(route(
    "mc-0454", "open", "poisson mu labelled relmat q2 (tests/testthat/test-count-structured-mu.R)",
    function() {
      sim <- new_count_structured_mu_slope_data(seed = 2026072908, n_level = 16L, n_each = 24L, rho_provider = 0.35)
      Q <- sim$Q
      data <- sim$data; data$id <- factor(data$id, levels = rownames(Q))
      list(
        data = data, formula = drmTMB::bf(poisson_known ~ x + relmat(1 + x | p | id, Q = Q)),
        family = stats::poisson(link = "log"), control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))
      )
    },
    q2_checks("relmat", "id")
  ))

  # --- mc-0425 / mc-0653: nbinom2 / zi_nbinom2 sigma phylo_interaction q1.
  # DGP helpers + formulas: tests/testthat/test-phylo-interaction.R
  # (new_phylo_interaction_sigma_nb2_data), :129-177
  # (new_zi_nbinom2_sigma_phylo_interaction_data), :404-421 (mc-0425 fit),
  # :509-525 (mc-0653 fit). Both use phylo_interaction_balanced_tree() at
  # :1-31.
  phylo_interaction_balanced_tree <- function(n_tip, prefix) {
    edges <- matrix(integer(), ncol = 2L); edge_lengths <- numeric(); next_node <- n_tip + 1L
    build <- function(tips) {
      if (length(tips) == 1L) return(tips)
      node <- next_node; next_node <<- next_node + 1L
      mid <- length(tips) / 2L
      left <- build(tips[seq_len(mid)]); right <- build(tips[seq.int(mid + 1L, length(tips))])
      edges <<- rbind(edges, c(node, left), c(node, right)); edge_lengths <<- c(edge_lengths, 1, 1)
      node
    }
    build(seq_len(n_tip))
    structure(list(edge = edges, edge.length = edge_lengths, tip.label = paste0(prefix, "_", seq_len(n_tip)), Nnode = n_tip - 1L), class = "phylo")
  }
  new_phylo_interaction_sigma_nb2_data <- function(seed, n_plant = 4L, n_pollinator = 4L, n_each = 18L, sd_pair = 0.60, sigma_intercept = -0.20) {
    set.seed(seed)
    plant_tree <- phylo_interaction_balanced_tree(n_plant, "plant"); pollinator_tree <- phylo_interaction_balanced_tree(n_pollinator, "poll")
    plant_cov <- drmTMB:::drm_phylo_tip_covariance(plant_tree); pollinator_cov <- drmTMB:::drm_phylo_tip_covariance(pollinator_tree)
    pair_cov <- kronecker(pollinator_cov, plant_cov)
    pair_grid <- expand.grid(plant = plant_tree$tip.label, pollinator = pollinator_tree$tip.label, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
    pair_effect <- as.vector(t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid), sd = sd_pair))
    names(pair_effect) <- paste0(pair_grid$plant, ":", pair_grid$pollinator)
    row_id <- rep(seq_len(nrow(pair_grid)), each = n_each); dat <- pair_grid[row_id, , drop = FALSE]
    dat$x <- stats::rnorm(nrow(dat))
    log_sigma <- sigma_intercept + pair_effect[paste0(dat$plant, ":", dat$pollinator)]
    dat$nb2 <- stats::rnbinom(nrow(dat), mu = exp(1.4 + 0.3 * dat$x), size = exp(-2 * log_sigma))
    list(data = dat, plant_tree = plant_tree, pollinator_tree = pollinator_tree)
  }
  new_zi_nbinom2_sigma_phylo_interaction_data <- function(seed, n_plant = 4L, n_pollinator = 4L, n_each = 18L, sd_pair = 0.60, sigma_intercept = -0.20, zi_probability = 0.20) {
    set.seed(seed)
    plant_tree <- phylo_interaction_balanced_tree(n_plant, "plant"); pollinator_tree <- phylo_interaction_balanced_tree(n_pollinator, "poll")
    plant_cov <- drmTMB:::drm_phylo_tip_covariance(plant_tree); pollinator_cov <- drmTMB:::drm_phylo_tip_covariance(pollinator_tree)
    pair_cov <- kronecker(pollinator_cov, plant_cov)
    pair_grid <- expand.grid(plant = plant_tree$tip.label, pollinator = pollinator_tree$tip.label, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
    pair_effect <- as.vector(t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid), sd = sd_pair))
    names(pair_effect) <- paste0(pair_grid$plant, ":", pair_grid$pollinator)
    row_id <- rep(seq_len(nrow(pair_grid)), each = n_each); dat <- pair_grid[row_id, , drop = FALSE]
    dat$x <- as.vector(scale(stats::rnorm(nrow(dat)), scale = FALSE))
    log_sigma <- sigma_intercept + pair_effect[paste0(dat$plant, ":", dat$pollinator)]
    structural_zero <- stats::runif(nrow(dat)) < zi_probability
    nb_count <- stats::rnbinom(nrow(dat), mu = exp(1.4 + 0.3 * dat$x), size = exp(-2 * log_sigma))
    dat$count <- ifelse(structural_zero, 0L, nb_count)
    list(data = dat, plant_tree = plant_tree, pollinator_tree = pollinator_tree)
  }

  add(route(
    "mc-0425", "open", "nbinom2 sigma phylo_interaction q1 (tests/testthat/test-phylo-interaction.R)",
    function() {
      sim <- new_phylo_interaction_sigma_nb2_data(seed = 2026072901)
      plant_tree <- sim$plant_tree; pollinator_tree <- sim$pollinator_tree
      list(
        data = sim$data,
        formula = drmTMB::bf(nb2 ~ x, sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)),
        family = drmTMB::nbinom2(), control = drmTMB::drm_control(se = TRUE)
      )
    },
    list(chk(
      "sd:sigma:phylo_interaction(1 | plant:pollinator)", "sigma",
      old_ready = FALSE, old_note = "point_fit_only_count_sigma_interaction",
      new_ready = TRUE, new_note = "ready", tmb_parameter = "log_sd_phylo"
    ))
  ))
  add(route(
    "mc-0653", "open", "zi_nbinom2 sigma phylo_interaction q1 (tests/testthat/test-phylo-interaction.R)",
    function() {
      sim <- new_zi_nbinom2_sigma_phylo_interaction_data(seed = 2026073001)
      plant_tree <- sim$plant_tree; pollinator_tree <- sim$pollinator_tree
      list(
        data = sim$data,
        formula = drmTMB::bf(count ~ x, sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree), zi ~ 1),
        family = drmTMB::nbinom2(), control = drmTMB::drm_control(se = TRUE)
      )
    },
    list(chk(
      "sd:sigma:phylo_interaction(1 | plant:pollinator)", "sigma",
      old_ready = FALSE, old_note = "point_fit_only_zi_nbinom2_sigma_interaction",
      new_ready = TRUE, new_note = "ready", tmb_parameter = "log_sd_phylo"
    ))
  ))

  # --- MUST-STAY-FENCED representative fits (completeness across all 5
  # providers is part (a)'s job; these are behavioural spot-checks that a
  # real fit really does still land on the fenced note).
  add(route(
    "fenced-zi-nbinom2-sigma-q1", "fenced",
    "zi_nbinom2 sigma ordinary q1 -- MUST stay fenced (tests/testthat/test-phylo-interaction.R)",
    function() {
      sim <- new_zi_nbinom2_sigma_phylo_interaction_data(seed = 2026073001, n_each = 8L)
      dat <- sim$data; dat$pair <- factor(paste(dat$plant, dat$pollinator, sep = ":"))
      list(
        data = dat, formula = drmTMB::bf(count ~ x, sigma ~ 1 + (1 | pair), zi ~ 1),
        family = drmTMB::nbinom2(), control = drmTMB::drm_control(se = TRUE)
      )
    },
    list(chk(
      "sd:sigma:(1 | pair)", "sigma",
      old_ready = FALSE, old_note = "point_fit_only_zi_nbinom2_sigma_q1",
      new_ready = FALSE, new_note = "point_fit_only_zi_nbinom2_sigma_q1", tmb_parameter = "log_sd_sigma"
    ))
  ))

  new_zero_one_beta_phylo_data <- function(seed = 2026072901L, n_tip = 32L, n_each = 30L) {
    set.seed(seed)
    tree <- ape::stree(n_tip, type = "balanced")
    tree$edge.length <- rep(1, nrow(tree$edge)); tree$tip.label <- paste0("sp", seq_len(n_tip))
    V <- drmTMB:::drm_phylo_tip_covariance(tree)
    u <- as.numeric(t(chol(V)) %*% stats::rnorm(n_tip, sd = .55)); names(u) <- tree$tip.label
    data <- data.frame(species = rep(tree$tip.label, each = n_each), x = stats::rnorm(n_tip * n_each))
    mu <- stats::plogis(-.10 + .35 * data$x + u[data$species])
    boundary <- stats::rbinom(nrow(data), 1, .12)
    data$y <- ifelse(boundary == 1, stats::rbinom(nrow(data), 1, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
    list(data = data, tree = tree)
  }
  add(route(
    "fenced-zob-mu-phylo", "fenced",
    "zero_one_beta mu structured phylo q1 -- MUST stay fenced (tests/testthat/test-zero-one-beta.R)",
    function() {
      sim <- new_zero_one_beta_phylo_data()
      tree <- sim$tree
      list(
        data = sim$data, formula = drmTMB::bf(y ~ x + phylo(1 | species, tree = tree)),
        family = drmTMB::zero_one_beta(), control = drmTMB::drm_control(se = TRUE)
      )
    },
    list(chk(
      "sd:mu:phylo(1 | species)", "mu",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_phylo_q1",
      new_ready = FALSE, new_note = "point_fit_only_zero_one_beta_phylo_q1", tmb_parameter = "log_sd_phylo"
    ))
  ))

  new_zero_one_beta_animal_data <- function(seed = 2026073001L, n_group = 32L, n_each = 30L) {
    set.seed(seed)
    labels <- paste0("sp", seq_len(n_group))
    Q <- diag(2, n_group); Q[cbind(seq_len(n_group - 1L), seq.int(2L, n_group))] <- -.5; Q[cbind(seq.int(2L, n_group), seq_len(n_group - 1L))] <- -.5
    rownames(Q) <- colnames(Q) <- rev(labels)
    u <- as.numeric(t(chol(solve(Q))) %*% stats::rnorm(n_group, sd = .55)); names(u) <- labels
    data <- data.frame(species = rep(labels, each = n_each), x = stats::rnorm(n_group * n_each))
    data$x <- data$x - ave(data$x, data$species, FUN = mean); data$x <- data$x / stats::sd(data$x)
    mu <- stats::plogis(-.10 + .35 * data$x + u[data$species])
    boundary <- stats::rbinom(nrow(data), 1, .12)
    data$y <- ifelse(boundary == 1, stats::rbinom(nrow(data), 1, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
    list(data = data, Ainv = Q)
  }
  add(route(
    "fenced-zob-mu-animal", "fenced",
    "zero_one_beta mu structured animal q1 -- MUST stay fenced (tests/testthat/test-zero-one-beta.R)",
    function() {
      sim <- new_zero_one_beta_animal_data()
      Ainv <- sim$Ainv
      list(
        data = sim$data, formula = drmTMB::bf(y ~ x + animal(1 | species, Ainv = Ainv)),
        family = drmTMB::zero_one_beta(), control = drmTMB::drm_control(se = TRUE)
      )
    },
    list(chk(
      "sd:mu:animal(1 | species)", "mu",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_animal_q1",
      new_ready = FALSE, new_note = "point_fit_only_zero_one_beta_animal_q1", tmb_parameter = "log_sd_phylo"
    ))
  ))

  new_zero_one_beta_relmat_data <- function(seed = 2026073101L, n_group = 32L, n_each = 30L) {
    set.seed(seed)
    labels <- paste0("sp", seq_len(n_group))
    Q <- diag(2, n_group); Q[cbind(seq_len(n_group - 1L), seq.int(2L, n_group))] <- -.5; Q[cbind(seq.int(2L, n_group), seq_len(n_group - 1L))] <- -.5
    rownames(Q) <- colnames(Q) <- rev(labels); K <- solve(Q)
    u <- as.numeric(t(chol(K)) %*% stats::rnorm(n_group, sd = .55)); names(u) <- rownames(K)
    data <- data.frame(species = rep(labels, each = n_each), x = stats::rnorm(n_group * n_each))
    data$x <- data$x - ave(data$x, data$species, FUN = mean); data$x <- data$x / stats::sd(data$x)
    mu <- stats::plogis(-.10 + .35 * data$x + u[data$species])
    boundary <- stats::rbinom(nrow(data), 1, .12)
    data$y <- ifelse(boundary == 1, stats::rbinom(nrow(data), 1, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
    list(data = data, K = K)
  }
  add(route(
    "fenced-zob-mu-relmat", "fenced",
    "zero_one_beta mu structured relmat q1 -- MUST stay fenced (tests/testthat/test-zero-one-beta.R)",
    function() {
      sim <- new_zero_one_beta_relmat_data()
      K <- sim$K
      list(
        data = sim$data, formula = drmTMB::bf(y ~ x + relmat(1 | species, K = K)),
        family = drmTMB::zero_one_beta(), control = drmTMB::drm_control(se = TRUE)
      )
    },
    list(chk(
      "sd:mu:relmat(1 | species)", "mu",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_relmat_q1",
      new_ready = FALSE, new_note = "point_fit_only_zero_one_beta_relmat_q1", tmb_parameter = "log_sd_phylo"
    ))
  ))

  new_zero_one_beta_spatial_data <- function(seed = 2026073201L, n_group = 24L, n_each = 35L) {
    set.seed(seed)
    labels <- paste0("site", seq_len(n_group))
    coords <- cbind(seq_len(n_group), (seq_len(n_group) %% 5L) / 3); rownames(coords) <- rev(labels)
    precision <- dense_zoib_spatial_precision(coords, labels)
    u <- as.numeric(t(chol(solve(precision$Q))) %*% stats::rnorm(n_group, sd = .55)); names(u) <- labels
    data <- data.frame(site = rep(labels, each = n_each), x = stats::rnorm(n_group * n_each))
    data$x <- data$x - ave(data$x, data$site, FUN = mean); data$x <- data$x / stats::sd(data$x)
    mu <- stats::plogis(-.10 + .35 * data$x + u[data$site])
    boundary <- stats::rbinom(nrow(data), 1, .12)
    data$y <- ifelse(boundary == 1, stats::rbinom(nrow(data), 1, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
    list(data = data, coords = coords)
  }
  add(route(
    "fenced-zob-mu-spatial", "fenced",
    "zero_one_beta mu structured spatial q1 -- MUST stay fenced (tests/testthat/test-zero-one-beta.R)",
    function() {
      sim <- new_zero_one_beta_spatial_data()
      coords <- sim$coords
      list(
        data = sim$data, formula = drmTMB::bf(y ~ x + spatial(1 | site, coords = coords)),
        family = drmTMB::zero_one_beta(), control = drmTMB::drm_control(se = TRUE)
      )
    },
    list(chk(
      "sd:mu:spatial(1 | site)", "mu",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_spatial_q1",
      new_ready = FALSE, new_note = "point_fit_only_zero_one_beta_spatial_q1", tmb_parameter = "log_sd_phylo"
    ))
  ))

  new_zero_one_beta_phylo_interaction_data <- function(seed = 2026073301L, n_each = 30L) {
    set.seed(seed)
    plant_tree <- ape::stree(4L, type = "balanced"); plant_tree$edge.length <- rep(1, nrow(plant_tree$edge)); plant_tree$tip.label <- paste0("plant", 1:4)
    pollinator_tree <- ape::stree(4L, type = "balanced"); pollinator_tree$edge.length <- rep(1, nrow(pollinator_tree$edge)); pollinator_tree$tip.label <- paste0("poll", 1:4)
    V <- kronecker(drmTMB:::drm_phylo_tip_covariance(pollinator_tree), drmTMB:::drm_phylo_tip_covariance(plant_tree))
    grid <- expand.grid(plant = plant_tree$tip.label, pollinator = pollinator_tree$tip.label, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
    u <- as.numeric(t(chol(V)) %*% stats::rnorm(nrow(grid), sd = .55)); names(u) <- paste0(grid$plant, ":", grid$pollinator)
    data <- grid[rep(seq_len(nrow(grid)), each = n_each), , drop = FALSE]; data$x <- stats::rnorm(nrow(data))
    data$x <- data$x - ave(data$x, interaction(data$plant, data$pollinator), FUN = mean); data$x <- data$x / stats::sd(data$x)
    mu <- stats::plogis(-.10 + .35 * data$x + u[paste0(data$plant, ":", data$pollinator)]); boundary <- stats::rbinom(nrow(data), 1, .12)
    data$y <- ifelse(boundary == 1, stats::rbinom(nrow(data), 1, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
    list(data = data, plant_tree = plant_tree, pollinator_tree = pollinator_tree)
  }
  add(route(
    "fenced-zob-mu-phylo-interaction", "fenced",
    "zero_one_beta mu structured phylo_interaction q1 -- MUST stay fenced (tests/testthat/test-zero-one-beta.R)",
    function() {
      sim <- new_zero_one_beta_phylo_interaction_data()
      plant_tree <- sim$plant_tree; pollinator_tree <- sim$pollinator_tree
      list(
        data = sim$data,
        formula = drmTMB::bf(y ~ x + phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)),
        family = drmTMB::zero_one_beta(), control = drmTMB::drm_control(se = TRUE)
      )
    },
    list(chk(
      "sd:mu:phylo_interaction(1 | plant:pollinator)", "mu",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_phylo_interaction_q1",
      new_ready = FALSE, new_note = "point_fit_only_zero_one_beta_phylo_interaction_q1", tmb_parameter = "log_sd_phylo"
    ))
  ))

  new_zero_one_beta_zoi_random_intercept_data <- function(seed = 2026073501L, n_id = 32L, n_each = 50L, sd_zoi = 0.45) {
    set.seed(seed)
    id <- factor(rep(paste0("id", seq_len(n_id)), each = n_each))
    x <- stats::rnorm(length(id))
    u_zoi <- stats::rnorm(n_id); names(u_zoi) <- levels(id)
    mu <- stats::plogis(-0.15 + 0.35 * x); sigma <- exp(-1.0)
    zoi <- stats::plogis(-1.15 + sd_zoi * u_zoi[as.character(id)]); coi <- stats::plogis(0.1)
    boundary <- stats::rbinom(length(id), 1L, zoi)
    y <- stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
    y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
    data.frame(y = y, x = x, id = id)
  }
  add(route(
    "fenced-zob-zoi-ordinary", "fenced",
    "zero_one_beta zoi ordinary q1 -- MUST stay fenced (retained predicate, unaffected by the diff; tests/testthat/test-zero-one-beta.R)",
    function() list(
      data = new_zero_one_beta_zoi_random_intercept_data(),
      formula = drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ 1),
      family = drmTMB::zero_one_beta(), control = drmTMB::drm_control(se = TRUE)
    ),
    list(chk(
      "sd:zoi:(1 | id)", "zoi",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_zoi_q1",
      new_ready = FALSE, new_note = "point_fit_only_zero_one_beta_zoi_q1", tmb_parameter = "log_sd_zoi"
    ))
  ))
  add(route(
    "fenced-zob-zoi-phylo", "fenced",
    "zero_one_beta zoi structured phylo q1 -- MUST stay fenced (tests/testthat/test-zero-one-beta.R)",
    function() {
      sim <- new_zero_one_beta_phylo_data()
      tree <- sim$tree
      list(
        data = sim$data, formula = drmTMB::bf(y ~ x, zoi ~ phylo(1 | species, tree = tree)),
        family = drmTMB::zero_one_beta(), control = drmTMB::drm_control(se = TRUE)
      )
    },
    list(chk(
      "sd:zoi:phylo(1 | species)", "zoi",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_phylo_zoi_q1",
      new_ready = FALSE, new_note = "point_fit_only_zero_one_beta_phylo_zoi_q1", tmb_parameter = "log_sd_phylo"
    ))
  ))

  new_zero_one_beta_coi_random_intercept_data <- function(seed = 2026081701L, n_id = 32L, n_each = 50L, sd_coi = 0.45) {
    set.seed(seed)
    id_levels <- paste0("id", seq_len(n_id)); id <- factor(rep(id_levels, each = n_each), levels = id_levels)
    x <- stats::rnorm(length(id)); x <- x - ave(x, id, FUN = mean); x <- x / stats::sd(x)
    u_coi <- stats::rnorm(n_id); names(u_coi) <- levels(id)
    mu <- stats::plogis(-0.15 + 0.35 * x); sigma <- exp(-1.0); zoi <- stats::plogis(-0.40)
    coi <- stats::plogis(0.10 + sd_coi * u_coi[as.character(id)])
    boundary <- stats::rbinom(length(id), 1L, zoi)
    y <- stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
    y[boundary == 1L] <- stats::rbinom(sum(boundary == 1L), 1L, coi[boundary == 1L])
    data.frame(y = y, x = x, id = id)
  }
  add(route(
    "fenced-zob-coi-ordinary", "fenced",
    "zero_one_beta coi ordinary q1 -- MUST stay fenced (retained predicate, unaffected by the diff; tests/testthat/test-zero-one-beta.R)",
    function() list(
      data = new_zero_one_beta_coi_random_intercept_data(),
      formula = drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | id)),
      family = drmTMB::zero_one_beta(), control = drmTMB::drm_control(se = TRUE)
    ),
    list(chk(
      "sd:coi:(1 | id)", "coi",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_coi_q1",
      new_ready = FALSE, new_note = "point_fit_only_zero_one_beta_coi_q1", tmb_parameter = "log_sd_coi"
    ))
  ))
  add(route(
    "fenced-zob-coi-phylo", "fenced",
    "zero_one_beta coi structured phylo q1 -- MUST stay fenced (tests/testthat/test-zero-one-beta.R)",
    function() {
      sim <- new_zero_one_beta_phylo_data()
      tree <- sim$tree
      list(
        data = sim$data, formula = drmTMB::bf(y ~ x, coi ~ phylo(1 | species, tree = tree)),
        family = drmTMB::zero_one_beta(), control = drmTMB::drm_control(se = TRUE)
      )
    },
    list(chk(
      "sd:coi:phylo(1 | species)", "coi",
      old_ready = FALSE, old_note = "point_fit_only_zero_one_beta_phylo_coi_q1",
      new_ready = FALSE, new_note = "point_fit_only_zero_one_beta_phylo_coi_q1", tmb_parameter = "log_sd_phylo"
    ))
  ))

  routes
}
