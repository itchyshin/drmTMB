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
