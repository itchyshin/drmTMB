# Arc 2 -- signal-bearing spatial SCALE-side q2 fixture (mc-0292).
#
# WHY THIS FILE EXISTS
# --------------------
# mc-0292's capability-ledger row (dpar=sigma, provider=spatial, q_gate=q2,
# estimator=ML) has NO genuine measured profile failure on record. Its
# `legacy_evidence_source` is "qseries_spatial_q1_mu_sigma_intercept" --
# tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R's local
# n=1 smoke at n_group=10/n_each=10 (N=100), a Wald (not `stats::profile()`)
# interval, and a bundled mu-sigma correlation target with TRUE value exactly
# 0 (`rho_mu_sigma = 0.00` in that tool's `provider_defaults`). That smoke's
# own dashboard row records `local_smoke_passed_fixture_only` /
# `do_not_promote` for spatial -- n=1 against a true-zero correlation is not
# evidence either way, and the row was never advanced. This file supplies the
# missing signal-bearing DGP, mirroring
# tools/arc2-phylo-sigma-fixtures.R::arc2_phylo_sigma_q2_nolabel_fixture()'s
# pattern exactly.
#
# The fitted formula (verified against the smoke tool's own
# `fit_mu_sigma()`, tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-
# smoke.R:384-390) is the SAME unlabelled term in both mu and sigma:
#
#     y ~ spatial(1 | site, coords = coords), sigma ~ spatial(1 | site, coords = coords)
#
# A live toy fit (Curie, 2026-08-03) confirms drmTMB auto-links this matching
# unlabelled pair into a joint q2 block exactly as it does for phylo:
# `profile_targets()` exposes `sd:mu:mu:spatial(1 | site)`,
# `sd:sigma:sigma:spatial(1 | site)`, and a
# `cor:spatial:cor(mu:(Intercept),sigma:(Intercept) | spatial | site)` target.
# Only the two marginal SDs are gated; the correlation is reported for
# information but never gated, matching mc-0283's scoping precisely.
#
# DESIGN RATIONALE
# -----------------
# The regular 9x9 coordinate grid (81 sites) is the SAME well-conditioned
# spatial design tools/arc3-nbinom2-sigma-provider-fixtures.R validates for
# mc-0422 (spatial sigma, NB2) -- a tighter spiral-coordinate layout used
# elsewhere in the suite collapsed the structured SD estimate there (see that
# file's DESIGN ITERATION NOTES). `n_each = 12` (not NB2's 25-30) follows the
# Gaussian-scale replication ladder mc-0277/mc-0283/mc-0279 already validate.

#' Gaussian ML fixture with genuine spatial signal on BOTH mu and log(sigma)
#' via two UNLABELLED matching `spatial(1 | site)` terms (mc-0292 shape).
#'
#' @param n_side Grid side length (`n_side^2` sites). Default 9 (81 sites).
#' @param n_each Observations per site. Default 12.
#' @param seed RNG seed.
#' @param true_sd_mu True SD of the spatial effect on mu (identity link,
#'   additive on the response scale).
#' @param true_log_sd_sigma True SD of the spatial effect on log(sigma).
#' @param mu0 Intercept on mu.
#' @param log_sigma0 Baseline log residual SD.
#' @return list(data, coords, true_sd_mu, true_log_sd_sigma)
arc2_spatial_sigma_q2_fixture <- function(n_side = 9L,
                                          n_each = 12L,
                                          seed = 101L,
                                          true_sd_mu = 0.6,
                                          true_log_sd_sigma = 0.7,
                                          mu0 = 0.4,
                                          log_sigma0 = log(0.5)) {
  set.seed(seed)
  n_site <- n_side^2
  site_levels <- paste0("site_", seq_len(n_site))
  coords <- data.frame(
    x = rep(seq_len(n_side), each = n_side),
    y = rep(seq_len(n_side), times = n_side),
    row.names = site_levels
  )
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = site_levels, group = "site"
  )
  cov <- solve(as.matrix(precision$precision))
  L <- t(chol(cov))
  u_mu <- as.vector(L %*% stats::rnorm(n_site)) * true_sd_mu
  u_sigma <- as.vector(L %*% stats::rnorm(n_site)) * true_log_sd_sigma
  names(u_mu) <- site_levels
  names(u_sigma) <- site_levels
  site <- rep(site_levels, each = n_each)
  n <- n_site * n_each
  sigma_tip <- exp(log_sigma0 + u_sigma[site])
  y <- mu0 + u_mu[site] + stats::rnorm(n, 0, sigma_tip)
  list(
    data = data.frame(
      y = y,
      site = factor(site, levels = site_levels)
    ),
    coords = coords,
    true_sd_mu = true_sd_mu,
    true_log_sd_sigma = true_log_sd_sigma
  )
}
