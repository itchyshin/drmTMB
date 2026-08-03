# Arc 4b -- q6 spatial mu1 fixture, the missing sibling of B3's q6 mu2 target.
#
# WHY THIS FILE EXISTS
# ---------------------
# mc-0123 (dpar mu1) and mc-0124 (dpar mu2) are the two mu-side endpoints of
# the SAME labelled bivariate `spatial(1 + x + z | p | site, coords = coords)`
# q6 block admitted in both mu1 and mu2
# (tests/testthat/test-structured-re-q6-location.R). B3 promoted mc-0124 to
# `interval_feasible` (ev-mc-0124-b3-q6-mu2-interval, target
# `sd:mu:mu2:spatial(1 | p | site)`, dgp_id
# `b2_q6_spatial_all_component_highinfo_v1`, information_rung
# `high_n72_each20`), but the runner that produced that receipt
# (tools/run-b2-q6-proof-profile-cohort.R, source SHA
# a8d068e641105473b3f30723a92c909467a46fac) was never merged to `main`: it
# lives only on the unmerged local branch `codex/lane-b-q1-preflight-
# admission` and is unreachable from any checkout of this tree, so its exact
# DGP cannot be replayed. The Arc 0 manifest's own citation
# (`tools/b2-q6-q12-admission-contracts.R:b2_q6q12_fixture`) is likewise a
# file that does not exist in this tree -- a second, independent manifest
# defect (see docs/dev-log/after-task/2026-08-02-arc3-fixture-construction.md
# section 10, "mc-0123").
#
# This file is therefore an INDEPENDENT, self-contained mu1 fixture for the
# same target family (the mu1 intercept-level spatial SD inside the q6
# block), built the same way the Arc 2/3 provider fixtures are: a validated
# regular coordinate grid -- not a spiral, which collapsed a structured
# intercept SD elsewhere; see tools/arc3-nbinom2-sigma-provider-fixtures.R's
# design-iteration note -- via `drmTMB:::drm_spatial_coords_precision()`,
# with the SAME independent-latent-field construction the merged structural
# test uses (`q6_biv_location_data()` in
# tests/testthat/test-structured-re-q6-location.R), scaled up for point-fit
# power. "n72_each20" mirrors mc-0124's own information-rung label: an
# 8 x 9 = 72-site grid, 20 observations per site (2 x 30-48/~12 group-count
# rule of thumb from the Arc 1 continuous-scale ladder, generously above it
# because this is a labelled two-slope q6 block, not a q1 intercept).
#
# The mu2-side true SDs below exist only to fill out the labelled q6 block
# (fitting mu1 alone is rejected -- the block is labelled on both
# endpoints); they are NOT a promotion claim for mu2, which already has its
# own independent B3 evidence.

#' Arc 4b fixture: labelled q6 spatial block, gate target is the mu1
#' intercept-level spatial SD.
#'
#' @param n_side_x,n_side_y Grid dimensions (`n_side_x * n_side_y` sites).
#'   Default 8 x 9 = 72 sites, matching mc-0124's `high_n72_each20` rung.
#' @param n_each Observations per site. Default 20.
#' @param seed RNG seed.
#' @param true_sd_mu1_intercept,true_sd_mu1_x,true_sd_mu1_z True spatial SDs
#'   for the mu1 endpoint's intercept/x-slope/z-slope random effects. The
#'   gated target is `true_sd_mu1_intercept` only.
#' @param true_sd_mu2_intercept,true_sd_mu2_x,true_sd_mu2_z Same for mu2;
#'   present only because the labelled q6 block requires both endpoints, not
#'   gated here (see file header).
#' @return list(data, coords, true_sd_mu1_intercept, true_sd_mu1_x,
#'   true_sd_mu1_z, true_sd_mu2_intercept, true_sd_mu2_x, true_sd_mu2_z)
arc4_q6_spatial_mu1_fixture <- function(n_side_x = 8L,
                                         n_side_y = 9L,
                                         n_each = 20L,
                                         seed = 2026080301L,
                                         true_sd_mu1_intercept = 0.45,
                                         true_sd_mu1_x = 0.30,
                                         true_sd_mu1_z = 0.25,
                                         true_sd_mu2_intercept = 0.40,
                                         true_sd_mu2_x = 0.28,
                                         true_sd_mu2_z = 0.22) {
  set.seed(seed)
  n_site <- n_side_x * n_side_y
  site_levels <- paste0("site_", seq_len(n_site))
  coords <- data.frame(
    x = rep(seq_len(n_side_x), each = n_side_y),
    y = rep(seq_len(n_side_y), times = n_side_x),
    row.names = site_levels
  )
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = site_levels, group = "site"
  )
  cov <- solve(as.matrix(precision$precision))
  chol_cov <- chol(cov)
  field <- function(sd) {
    v <- as.vector(t(chol_cov) %*% stats::rnorm(n_site, sd = sd))
    names(v) <- site_levels
    v
  }
  site <- rep(site_levels, each = n_each)
  n <- n_site * n_each
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  eta1 <- 0.30 + 0.25 * x - 0.15 * z +
    field(true_sd_mu1_intercept)[site] +
    x * field(true_sd_mu1_x)[site] +
    z * field(true_sd_mu1_z)[site]
  eta2 <- -0.20 - 0.20 * x + 0.10 * z +
    field(true_sd_mu2_intercept)[site] +
    x * field(true_sd_mu2_x)[site] +
    z * field(true_sd_mu2_z)[site]
  e1 <- stats::rnorm(n)
  e2 <- -0.15 * e1 + sqrt(1 - 0.15^2) * stats::rnorm(n)
  dat <- data.frame(
    y1 = eta1 + 0.25 * e1, y2 = eta2 + 0.28 * e2,
    x = x, z = z,
    site = factor(site, levels = site_levels)
  )
  list(
    data = dat, coords = coords,
    true_sd_mu1_intercept = true_sd_mu1_intercept,
    true_sd_mu1_x = true_sd_mu1_x, true_sd_mu1_z = true_sd_mu1_z,
    true_sd_mu2_intercept = true_sd_mu2_intercept,
    true_sd_mu2_x = true_sd_mu2_x, true_sd_mu2_z = true_sd_mu2_z
  )
}
