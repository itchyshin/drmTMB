# Bivariate Gaussian q = 2 structured mean markers by REML through
# `engine = "julia"` (drmTMB #1142 / DRM.jl #470).
#
# Before this file the bridge refused `REML = TRUE` on EVERY q2 structured
# bivariate cell, for every provider, while both native engines fit them:
# DRM.jl's own q=2 route dispatches `fit_coevolution_q2_reml` (src/reml_q2.jl)
# and native `engine = "tmb"` admits the phylo, supplied-K relmat, and
# fixed-covariance spatial q2 location blocks. Two different R-side branches
# produced that refusal, and both are exercised here:
#
#   * `phylo(1 | p | g)` on mu1/mu2 reaches the MAIN bridge payload -- the
#     `drm_julia_has_structured_term()` detector deliberately excludes phylo --
#     and was refused by `drm_julia_reml_supported()`, which admitted only q4.
#   * `relmat` / `animal` / `spatial` reach
#     `drmTMB_julia_biv_known_structured_bridge()` and were refused
#     unconditionally one branch earlier.
#
# `animal` STAYS REFUSED here, and that is a measured decision rather than an
# oversight: DRM.jl fits it, but native `engine = "tmb"` still refuses
# bivariate animal q2 REML, so there is no same-target comparator to measure a
# receipt against (drmTMB PR #1200 adds the native route).
#
# The gate-logic tests need no Julia and always run. The live round-trips are
# guarded by `drm_skip_live_julia()` so they are SKIPPED -- never failed --
# without a DRM.jl checkout.

drm_biv_q2_reml_fixture <- function(kind, seed = 20260905L, n_id = 10L,
                                    nrep = 3L) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  idx <- seq_len(n_id)
  K <- outer(idx, idx, function(i, j) 0.45^abs(i - j))
  diag(K) <- diag(K) + 0.08
  dimnames(K) <- list(id_levels, id_levels)
  m <- matrix(stats::rnorm(n_id * n_id), n_id, n_id)
  A0 <- crossprod(m) / n_id + diag(n_id)
  d <- sqrt(diag(A0))
  A <- A0 / outer(d, d)
  dimnames(A) <- list(id_levels, id_levels)
  theta <- seq(0, 1.5 * pi, length.out = n_id)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_id) / (3 * n_id),
    y = sin(theta),
    row.names = id_levels
  )
  tree <- ape::rcoal(n_id, tip.label = id_levels)
  C <- switch(
    kind,
    relmat = K,
    animal = A,
    spatial = solve(as.matrix(drmTMB:::drm_spatial_coords_precision(
      coords,
      site = id_levels,
      group = "id"
    )$precision)),
    phylo = ape::vcv.phylo(tree)
  )
  C <- C[id_levels, id_levels, drop = FALSE]
  id <- rep(id_levels, each = nrep)
  n <- length(id)
  x <- stats::rnorm(n)
  Sigma_a <- matrix(c(0.20, 0.06, 0.06, 0.16), 2L, 2L)
  U <- t(chol(C + diag(1e-10, n_id))) %*%
    matrix(stats::rnorm(n_id * 2L), n_id, 2L) %*%
    chol(Sigma_a)
  row <- match(id, id_levels)
  e1 <- stats::rnorm(n, sd = 0.28)
  e2 <- 0.20 * e1 + sqrt(1 - 0.20^2) * stats::rnorm(n, sd = 0.30)
  data <- data.frame(
    id = id,
    x = x,
    y1 = 0.25 + 0.35 * x + U[row, 1L] + e1,
    y2 = -0.10 + 0.25 * x + U[row, 2L] + e2,
    stringsAsFactors = FALSE
  )
  list(data = data, K = K, A = A, coords = coords, tree = tree)
}

# `bf()` captures its arguments unevaluated, so the marker text is assembled
# into real formulas first and passed through `do.call()`. mu1 and mu2 share
# ONE fixed-effect design (`~ x`): DRM.jl's q=2 route requires X1 == X2.
drm_biv_q2_reml_formula <- function(kind, fx) {
  K <- fx$K
  A <- fx$A
  coords <- fx$coords
  tree <- fx$tree
  env <- environment()
  marker <- switch(
    kind,
    relmat = "relmat(1 | p | id, K = K)",
    animal = "animal(1 | p | id, A = A)",
    spatial = "spatial(1 | p | id, coords = coords)",
    phylo = "phylo(1 | p | id, tree = tree)"
  )
  do.call(drmTMB::bf, list(
    mu1 = stats::as.formula(paste("y1 ~ x +", marker), env = env),
    mu2 = stats::as.formula(paste("y2 ~ x +", marker), env = env),
    sigma1 = stats::as.formula("~1", env = env),
    sigma2 = stats::as.formula("~1", env = env),
    rho12 = stats::as.formula("~1", env = env)
  ))
}

test_that("the q2 REML provider list is exactly the measured set", {
  # The list is the whole capability claim, so it is pinned literally: adding a
  # provider here without a same-target receipt is the failure this pins shut.
  expect_identical(
    drmTMB:::drm_julia_biv_q2_reml_providers(),
    c("phylo", "relmat", "spatial")
  )
})

test_that("the q2 REML predicate admits phylo/relmat/spatial and refuses animal", {
  fx <- drm_biv_q2_reml_fixture("relmat")
  for (kind in c("phylo", "relmat", "spatial")) {
    form <- drm_biv_q2_reml_formula(kind, fx)
    expect_true(
      drmTMB:::drm_julia_biv_q2_reml_supported(form),
      info = kind
    )
    expect_true(
      drmTMB:::drm_julia_reml_supported(form, "biv_gaussian"),
      info = kind
    )
  }
  animal_form <- drm_biv_q2_reml_formula("animal", fx)
  expect_false(drmTMB:::drm_julia_biv_q2_reml_supported(animal_form))
  expect_false(drmTMB:::drm_julia_reml_supported(animal_form, "biv_gaussian"))

  # Shapes that are not a matching mu1/mu2 q2 marker pair stay outside the
  # predicate, so the widening cannot leak into a neighbouring cell.
  expect_false(
    drmTMB:::drm_julia_biv_q2_reml_supported(drmTMB::bf(y ~ x, sigma ~ 1))
  )
})

test_that("both q2 payload builders forward method = REML, and only then", {
  fx <- drm_biv_q2_reml_fixture("relmat")

  phylo_form <- drm_biv_q2_reml_formula("phylo", fx)
  phylo_env <- environment(phylo_form$entries[[1L]]$formula)
  ml <- drmTMB:::drm_julia_bridge_payload(
    formula = phylo_form,
    family_type = "biv_gaussian",
    data = fx$data,
    env = phylo_env,
    method = "ML"
  )
  reml <- drmTMB:::drm_julia_bridge_payload(
    formula = phylo_form,
    family_type = "biv_gaussian",
    data = fx$data,
    env = phylo_env,
    method = "REML"
  )
  expect_identical(ml$bivariate_dimension, "q2")
  # ML stays byte-identical to the parity-tested baseline shape.
  expect_equal(drm_test_options_sans_labels(ml$options), list(g_tol = 1e-4))
  expect_equal(
    drm_test_options_sans_labels(reml$options),
    list(g_tol = 1e-4, method = "REML")
  )

  relmat_form <- drm_biv_q2_reml_formula("relmat", fx)
  relmat_env <- environment(relmat_form$entries[[1L]]$formula)
  ml_k <- drmTMB:::drm_julia_biv_known_structured_payload(
    formula = relmat_form,
    family_type = "biv_gaussian",
    data = fx$data,
    env = relmat_env,
    method = "ML"
  )
  reml_k <- drmTMB:::drm_julia_biv_known_structured_payload(
    formula = relmat_form,
    family_type = "biv_gaussian",
    data = fx$data,
    env = relmat_env,
    method = "REML"
  )
  expect_equal(drm_test_options_sans_labels(ml_k$options), list(g_tol = 1e-4))
  expect_equal(
    drm_test_options_sans_labels(reml_k$options),
    list(g_tol = 1e-4, method = "REML")
  )
})

# ---------------------------------------------------------------------------
# Live same-target receipt. Measured 2026-09-05 at DRM.jl pin 430ef64cc;
# every tolerance below is the number this fixture actually produced, rounded
# UP to the next round figure, not an aspiration:
#
#   provider | REML max|d coef| | REML |d logLik| | ML |d logLik| (same fixture)
#   phylo    | 5.152e-05        | 1.803e-04      | 5.423e-04
#   relmat   | 5.294e-05        | 3.704e-07      | 7.334e-09
#   spatial  | 4.202e-05        | 4.493e-08      | 2.306e-05
#
# The phylo logLik residual is the ONLY number outside a flat 1e-4 bar, and it
# is a pre-existing property of the q2 PHYLO route rather than anything REML
# introduced: on this same fixture the already-admitted, parity-tested ML fit
# disagrees by 5.423e-04 (and 4.607e-03 on coefficients), i.e. the REML
# agreement is TIGHTER than the ML agreement this route already ships with.
# Two controls were measured and both are in the receipt: tightening the
# route's outer-gradient tolerance does NOT close it (g_tol 1e-4 -> 1e-6 ->
# 1e-8 leaves |d logLik| at 1.803e-04 -> 1.799e-04 -> 1.799e-04), so it is not
# optimiser slack; and relmat/spatial, which share the REML code path but not
# the phylo covariance construction, agree to 3.7e-07 and 4.5e-08.
#
# SEs ARE NOT COMPARED. DRM.jl's q=2 structured route stores an all-NaN
# covariance (`V = fill(NaN, ...)` in `_fit_bivariate_q2_structured`), so this
# receipt is POINT-ONLY on every provider. That is asserted below rather than
# passed over in silence.
# ---------------------------------------------------------------------------

test_that("engine='julia' fits bivariate q2 phylo/relmat/spatial by REML, same target as engine='tmb'", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("ape")
  drm_skip_live_julia()

  tol_coef <- 1e-4
  tol_loglik <- c(phylo = 2e-4, relmat = 1e-5, spatial = 1e-5)

  for (kind in c("phylo", "relmat", "spatial")) {
    fx <- drm_biv_q2_reml_fixture(kind)
    form <- drm_biv_q2_reml_formula(kind, fx)

    fj <- drmTMB::drmTMB(
      form,
      family = drmTMB::biv_gaussian(),
      data = fx$data,
      engine = "julia",
      REML = TRUE
    )
    ft <- drmTMB::drmTMB(
      form,
      family = drmTMB::biv_gaussian(),
      data = fx$data,
      engine = "tmb",
      REML = TRUE
    )

    expect_true(drmTMB::is_converged(fj), info = kind)
    expect_true(drmTMB::is_converged(ft), info = kind)

    # G4: the estimator label, and the engine's own report of it, both say REML.
    expect_identical(fj$estimator, "REML", info = kind)
    expect_identical(
      toupper(as.character(fj$bridge$estim_method)[1L]),
      "REML",
      info = kind
    )
    # A relabelled ML fit would put these on top of each other.
    expect_gt(
      abs(as.numeric(fj$bridge$ml_loglik) - as.numeric(fj$bridge$reml_loglik)),
      1
    )

    ll_j <- as.numeric(stats::logLik(fj))
    ll_t <- as.numeric(stats::logLik(ft))
    expect_lt(abs(ll_j - ll_t), tol_loglik[[kind]])

    coef_j <- unlist(stats::coef(fj))
    coef_t <- unlist(stats::coef(ft))
    # Same coefficient NAMES as a set. The two engines order the block
    # differently (Julia reports rho12 before sigma1/sigma2), so the assertion
    # is setequal plus a name-matched comparison, not vector identity.
    expect_setequal(names(coef_j), names(coef_t))
    expect_lt(
      max(abs(coef_j[names(coef_t)] - coef_t)),
      tol_coef
    )

    # POINT-ONLY: DRM.jl reports no usable covariance on this route, so no SE
    # claim is made or could be made here.
    expect_true(all(!is.finite(sqrt(diag(stats::vcov(fj))))), info = kind)
  }
})

test_that("engine='julia' still refuses bivariate q2 animal by REML", {
  skip_if_not_installed("ape")
  fx <- drm_biv_q2_reml_fixture("animal")
  form <- drm_biv_q2_reml_formula("animal", fx)
  expect_error(
    drmTMB::drmTMB(
      form,
      family = drmTMB::biv_gaussian(),
      data = fx$data,
      engine = "julia",
      REML = TRUE
    ),
    "bivariate q2 known-covariance structured-effect"
  )
})
