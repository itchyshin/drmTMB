# REML for the mean-only phylogenetic Gaussian cell through engine = "julia".
#
#   bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1), gaussian(), REML = TRUE
#
# This is DRM.jl #624 item (c) / drmTMB #1142: the cell native TMB has always
# fitted by REML and the bridge refused, because DRM.jl refused it. DRM.jl now
# restricts it on its sparse location-only spine, so the bridge gate admits it.
#
# WHAT EACH ENGINE INTEGRATES OUT, AND ON WHICH CONVENTION. Native drmTMB does
# REML by moving `beta_mu` into TMB's `random=` vector alongside the phylo field
# `u_phylo` (R/drmTMB.R drm_apply_estimator_spec()); TMB's Laplace approximation
# over a jointly quadratic negative log-density is EXACT, so the result is the
# Patterson-Thompson restricted likelihood, including the +0.5*p_mu*log(2*pi)
# the Laplace constant contributes. DRM.jl profiles `beta_mu` out by GLS at
# every variance point and adds
#     0.5*logdet(Xmu' V^-1 Xmu) - 0.5*p_mu*log(2*pi)
# to the ML objective. Same integrated-out set {u_phylo, beta_mu}, same additive
# constant: the two logLik values are on ONE convention with NO offset to
# remove, which is why the assertion below is a plain 1e-4 comparison rather
# than a comparison after subtracting a constant.
#
# The gate-logic tests need no Julia and always run; the live parity test is
# guarded by drm_skip_live_julia().
#
# The fixture below is the SAME construction and seed as
# `reml_phylo_location_fixture()` in tests/testthat/test-reml-phylo-location.R
# (n_tip = 30, n_each = 3, seed = 7, true phylo SD 0.6, true residual SD 0.5),
# repeated here so this file runs standalone under `testthat::test_file()`.

reml_phylo_mean_parity_fixture <- function(n_tip = 30L, n_each = 3L, seed = 7L,
                                           true_sd_phylo = 0.6) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  u <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip)) * true_sd_phylo
  tip <- rep(seq_len(n_tip), each = n_each)
  n <- n_tip * n_each
  x <- stats::rnorm(n)
  y <- 0.4 + 0.7 * x + u[tip] + stats::rnorm(n, 0, 0.5)
  list(
    data = data.frame(
      y = y,
      x = x,
      species = factor(tree$tip.label[tip], levels = tree$tip.label)
    ),
    tree = tree,
    A = A,
    tip = tip,
    true_sd_phylo = true_sd_phylo
  )
}

test_that("the REML gate admits mean-only phylo Gaussian and nothing adjacent", {
  skip_if_not_installed("ape")
  tree <- ape::rcoal(6)

  mean_only <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1
  )
  # sigma carries a predictor: DRM.jl's dense structured fitter, no REML there.
  mean_phylo_lss <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ z
  )
  # an ordinary (1 | g) bar alongside the phylo term: a different DRM.jl route.
  mean_phylo_plus_bar <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree) + (1 | g),
    sigma ~ 1
  )
  # relmat / spatial share the phylo cell's shape but not its engine route.
  K <- diag(4)
  mean_relmat <- drmTMB::bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1)

  expect_true(drmTMB:::drm_julia_reml_phylo_mean_only(mean_only))
  expect_false(drmTMB:::drm_julia_reml_phylo_mean_only(mean_phylo_lss))
  expect_false(drmTMB:::drm_julia_reml_phylo_mean_only(mean_phylo_plus_bar))
  expect_false(drmTMB:::drm_julia_reml_phylo_mean_only(mean_relmat))

  expect_true(drmTMB:::drm_julia_reml_supported(mean_only, "gaussian"))
  expect_false(drmTMB:::drm_julia_reml_supported(mean_phylo_lss, "gaussian"))
  expect_false(drmTMB:::drm_julia_reml_supported(mean_phylo_plus_bar, "gaussian"))
  # relmat() carries no phylo() term, so it has ALWAYS satisfied this gate's
  # first disjunct (`!has_phylo`) -- a pre-existing width, unrelated to the
  # phylo-mean widening and deliberately left alone here. Pinned so a future
  # change to that disjunct is visible; the new predicate correctly excludes it.
  expect_true(drmTMB:::drm_julia_reml_supported(mean_relmat, "gaussian"))
})

test_that("engine = julia REML matches engine = tmb REML on the phylo-mean cell", {
  skip_if_not_installed("ape")
  drm_skip_live_julia()
  drm_test_local_julia_home()

  fx <- reml_phylo_mean_parity_fixture()
  tree <- fx$tree
  form <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1
  )

  fit_tmb <- drmTMB(form, family = gaussian(), data = fx$data, REML = TRUE)
  fit_jl <- drmTMB(
    form,
    family = gaussian(),
    data = fx$data,
    REML = TRUE,
    engine = "julia"
  )

  # G4 ESTIMATOR HONESTY, read off the objects rather than inferred from the
  # absence of an abort. `bridge$estim_method` is DRM.jl's own report (#625);
  # the bridge aborts if it disagrees with the label drmTMB would apply.
  expect_identical(fit_tmb$estimator, "REML")
  expect_identical(fit_jl$estimator, "REML")
  expect_identical(toupper(as.character(fit_jl$bridge$estim_method)[1L]), "REML")
  expect_true(isTRUE(fit_jl$effective_REML))

  # Coefficient NAMES, normalised the way tools/parity_se.R does (native
  # "mu:(Intercept)" vs bridge "mu_(Intercept)" is a separator difference, not
  # a different coefficient set).
  norm_names <- function(x) gsub("[.:]", "_", x, perl = TRUE)
  se_tmb <- sqrt(diag(as.matrix(vcov(fit_tmb))))
  names(se_tmb) <- norm_names(rownames(as.matrix(vcov(fit_tmb))))
  se_jl <- sqrt(diag(as.matrix(fit_jl$vcov)))
  names(se_jl) <- norm_names(names(se_jl))
  coef_tmb <- unlist(coef(fit_tmb))
  names(coef_tmb) <- norm_names(names(coef_tmb))
  coef_jl <- fit_jl$coef_vector
  names(coef_jl) <- norm_names(names(coef_jl))
  expect_identical(names(coef_jl), names(coef_tmb))
  expect_identical(names(se_jl), names(se_tmb))

  # Coefficients within 1e-4 (absolute, or relative where |value| > 1).
  scale <- pmax(1, abs(coef_tmb))
  expect_lt(max(abs(coef_tmb - coef_jl[names(coef_tmb)]) / scale), 1e-4)

  # logLik within 1e-4 on the shared REML convention (see the header note).
  expect_lt(abs(as.numeric(logLik(fit_tmb)) - as.numeric(fit_jl$logLik)), 1e-4)

  # REML is a genuine restriction on both engines, not a relabelled ML fit:
  # the REML logLik sits several units from the ML one.
  fit_tmb_ml <- drmTMB(form, family = gaussian(), data = fx$data)
  expect_gt(abs(as.numeric(logLik(fit_tmb)) - as.numeric(logLik(fit_tmb_ml))), 1)
  expect_gt(abs(as.numeric(fit_jl$logLik) - as.numeric(fit_jl$bridge$ml_loglik)), 1)

  # nobs and df follow the same reporting on both engines.
  expect_identical(as.integer(fit_jl$nobs), as.integer(stats::nobs(fit_tmb)))
  expect_identical(as.integer(fit_jl$df), as.integer(attr(logLik(fit_tmb), "df")))

  # OBJECTIVE HONESTY through the bridge. DRM.jl attaches the RESTRICTED objective
  # (and no analytic score) to a REML fit, so the bridge reports no `gradient` for
  # it. Before that fix the bridge surfaced the ML score at the REML optimum --
  # (1.01, 0.99) on the two variance parameters -- which reads as "not converged"
  # for a fit that is converged. The ML fit on the same route still carries its
  # analytic score, so the absence here is estimator-specific, not a lost feature.
  fit_jl_ml <- drmTMB(form, family = gaussian(), data = fx$data, engine = "julia")
  expect_null(fit_jl$bridge$gradient)
  expect_false(is.null(fit_jl_ml$bridge$gradient))
  expect_lt(max(abs(unlist(fit_jl_ml$bridge$gradient))), 1e-4)

  # STANDARD ERRORS. DRM.jl reports the canonical REML fixed-effect covariance
  # (Xmu' Vhat^-1 Xmu)^-1 -- verified below against a hand-built GLS oracle at
  # the TMB fit's own variance estimates, agreeing to ~1e-7. Native drmTMB's
  # REML SEs come from TMB's sdreport over a random set that CONTAINS beta_mu,
  # which additionally propagates variance-parameter uncertainty into that
  # block, so TMB's are slightly larger. On this fixture that convention
  # difference is 4.84e-05 relative on mu_(Intercept) and 1.50e-03 on mu_x --
  # the latter just past the 1e-3 relative bar tools/parity_se.R uses. It is
  # measured and explained, NOT hidden behind a widened tolerance: the oracle
  # assertion is the strict one, and the cross-engine bound is deliberately
  # 2.5e-3 so this file fails if the gap ever grows.
  X <- stats::model.matrix(~x, fx$data)
  n <- nrow(fx$data)
  n_tip <- length(tree$tip.label)
  Z <- matrix(0, n, n_tip)
  Z[cbind(seq_len(n), fx$tip)] <- 1
  s2p <- as.numeric(fit_tmb$sdpars$mu[[1L]])^2
  s2r <- exp(2 * as.numeric(fit_tmb$par$sigma[1L]))
  V <- s2p * (Z %*% fx$A %*% t(Z)) + s2r * diag(n)
  gls_se <- sqrt(diag(solve(t(X) %*% solve(V, X))))
  expect_lt(max(abs(se_jl[c("mu_(Intercept)", "mu_x")] - gls_se) / gls_se), 1e-5)
  expect_lt(max(abs(se_tmb - se_jl[names(se_tmb)]) / se_tmb), 2.5e-3)
})

test_that("the phylo-mean REML admission is withdrawn under a non-default response engine", {
  skip_if_not_installed("ape")
  drm_skip_live_julia()
  drm_test_local_julia_home()

  # docs/design/261 row `gaussian_response_mask`. DRM.jl's sparse phylo-mean REML
  # gate excludes a model carrying missing responses, so with an explicit
  # `response = "include"` engine the widened bridge gate must step back and
  # refuse with drmTMB's own message rather than let the user see DRM.jl's raw
  # ArgumentError plus a JuliaCall trace. Native engine = "tmb" refuses the same
  # combination, for its own (different) reason.
  fx <- reml_phylo_mean_parity_fixture()
  tree <- fx$tree
  form <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1
  )
  masked <- fx$data
  masked$y[3L] <- NA

  expect_error(
    drmTMB(
      form,
      family = gaussian(),
      data = masked,
      REML = TRUE,
      engine = "julia",
      missing = miss_control(response = "include")
    ),
    "cannot fit mean-only phylogenetic Gaussian models"
  )
})
