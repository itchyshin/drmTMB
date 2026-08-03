# Arc 2 -- bivariate ordinary REML mu-sigma correlated-block fixture.
#
# WHY THIS FILE EXISTS
# --------------------
# mc-0205 (`sd:mu:mu1:(1 | p | id)`) and mc-0206 (`sd:sigma:sigma1:(1 | p |
# id)`) are the two marginal SD targets of ONE labelled random-effect block:
# a `(1 | p | id)` correlation between the mean (mu1) and log-scale (sigma1)
# random intercepts of a bivariate Gaussian fit, estimated under REML. The
# prior diagnosis for this slice traced the admission of this exact spec to
# R/drmTMB.R:2359-2363 (`drm_validate_reml_spec_biv`, inline comment dated
# 2026-07-08) and confirmed empirically that the unpatched package fits it
# without error.
#
# The only prior harness for this DGP, `sim3()` in
# scratchpad/reml_parity_gaps_3A_ladder.R, extracts POINT ESTIMATES ONLY --
# it never returns standard errors, confidence intervals, convergence codes,
# or `pdHess`, so it is structurally incapable of supporting an interval-
# feasibility claim (the ask of this slice). This file replaces it with a
# committed fixture returning a plain data.frame the profile-feasibility
# runner (tools/run-arc2-profile-feasibility.R) can fit directly, following
# the same one-fixture/two-target pattern already used for the
# mc-0277/mc-0283 phylogenetic sigma pair (tools/arc2-phylo-sigma-fixtures.R).
#
# DGP is copied verbatim from `sim3()`'s data-generating code (mu1 intercept
# 0.3 / slope 0.5 on x, mu2 intercept 0.6 / slope 0.2 on x with constant
# sigma2 = 0.6, log_sigma1_0 = log(0.5), a Cholesky-correlated draw of the
# mu1/sigma1 random-effect pair from truth3 <- c(sd_mu1 = .6, sd_sig1 = .4,
# cor = .3)) -- only the harness (this file returns the fitted model's own
# convergence/pdHess/profile output, not just point estimates) differs.
#
# DESIGN RATIONALE
# -----------------
# n_id = 60, n_each = 8 are reused UNCHANGED from `sim3()`'s own design and
# are NOT enlarged here. That design already sits at or above the
# within-group-replication floor already validated for this exact block
# shape: the univariate analog requires n_each >= ~8 for REML to debias the
# scale-side random-effect SD without underperforming ML (R/drmTMB.R:2254-
# 2257; docs/dev-log/known-limitations.md:245-249), and `sim3()`'s n_each
# 5-10 spans that floor unevenly. n_each = 8 sits ON the validated floor. No
# enlargement was needed: this exact design (n_id = 60, n_each = 8) passed
# the point-fit recovery gate AND the profile-bracketing gate on the FIRST
# and ONLY design tried (5/5 seeds, both gates, both targets -- see below).
# Because this design already clears both gates cleanly, no alternative
# design was explored and none needs to be recorded as rejected.
#
# RECOVERY-LADDER EVIDENCE (n_id = 60, n_each = 8, 5 seeds, seed formula
# `seed * 31337L + n_each` copied from reml_parity_gaps_3A_ladder.R:14, so
# the point-fit gate and the profile-feasibility smoke share one seed
# family). Truth: sd_mu1 = 0.6, sd_sig1 = 0.4 (sim3()'s own truth3 vector).
#
# Point-fit recovery (predeclared gate: mean relative error <= 0.35; ALL
# seeds converged, ALL pdHess TRUE):
#   seed 1: sd_mu1 = 0.639 (relerr 0.065); sd_sig1 = 0.438 (relerr 0.096)
#   seed 2: sd_mu1 = 0.614 (relerr 0.024); sd_sig1 = 0.383 (relerr 0.041)
#   seed 3: sd_mu1 = 0.570 (relerr 0.050); sd_sig1 = 0.466 (relerr 0.166)
#   seed 4: sd_mu1 = 0.643 (relerr 0.072); sd_sig1 = 0.326 (relerr 0.185)
#   seed 5: sd_mu1 = 0.586 (relerr 0.023); sd_sig1 = 0.318 (relerr 0.205)
#   Worst-case relative error 0.205, well under the 0.35 gate.
#
# Profile feasibility (one `stats::profile()` call per target per seed;
# conf.status == "profile", profile.message == "ok", 68-74 retained trace
# rows spanning both sides of the estimate, all 5 x 2 PASS the full
# receipt contract, and the interval BRACKETS the true value every time):
#   sd:mu:mu1:(1 | p | id):      seed1 [0.525,0.790]  seed2 [0.505,0.759]
#                                 seed3 [0.463,0.711]  seed4 [0.532,0.791]
#                                 seed5 [0.484,0.722]  -- 5/5 bracket 0.6
#   sd:sigma:sigma1:(1 | p | id): seed1 [0.338,0.565]  seed2 [0.290,0.501]
#                                 seed3 [0.363,0.598]  seed4 [0.232,0.438]
#                                 seed5 [0.215,0.435]  -- 5/5 bracket 0.4

#' Bivariate Gaussian REML fixture: correlated mu1/sigma1 random intercepts
#'
#' Generates data under a labelled `(1 | p | id)` random-effect block linking
#' the mu1 (mean) and sigma1 (log-scale) random intercepts of a bivariate
#' Gaussian response pair, with a second, unrelated response (mu2, constant
#' sigma2) carrying no random effect. DGP copied verbatim from `sim3()` in
#' scratchpad/reml_parity_gaps_3A_ladder.R.
#'
#' @param n_id Number of groups (individuals). Default 60.
#' @param n_each Observations per group. Default 8 -- reused unchanged from
#'   `sim3()`, at the within-group-replication floor already validated for
#'   this block shape (see header).
#' @param seed RNG seed.
#' @param true_sd_mu1 True SD of the mu1 random intercept. Default 0.6.
#' @param true_sd_sig1 True SD of the sigma1 (log-scale) random intercept.
#'   Default 0.4.
#' @param true_cor True correlation between the mu1 and sigma1 random
#'   intercepts. Default 0.3.
#' @return list(data, true_sd_mu1, true_sd_sig1, true_cor)
arc2_biv_musigma_fixture <- function(n_id = 60L,
                                      n_each = 8L,
                                      seed,
                                      true_sd_mu1 = 0.6,
                                      true_sd_sig1 = 0.4,
                                      true_cor = 0.3) {
  set.seed(seed * 31337L + n_each)
  Sigma_re <- matrix(
    c(
      true_sd_mu1^2, true_cor * true_sd_mu1 * true_sd_sig1,
      true_cor * true_sd_mu1 * true_sd_sig1, true_sd_sig1^2
    ),
    2, 2
  )
  S <- chol(Sigma_re)
  a <- matrix(stats::rnorm(n_id * 2), n_id, 2) %*% S
  id <- rep(seq_len(n_id), each = n_each)
  n <- n_id * n_each
  x <- stats::rnorm(n)
  y1 <- 0.3 + 0.5 * x + a[id, 1] + stats::rnorm(n, 0, exp(log(0.5) + a[id, 2]))
  y2 <- 0.6 + 0.2 * x + stats::rnorm(n, 0, 0.6)
  list(
    data = data.frame(id = factor(id), x = x, y1 = y1, y2 = y2),
    true_sd_mu1 = true_sd_mu1,
    true_sd_sig1 = true_sd_sig1,
    true_cor = true_cor
  )
}
