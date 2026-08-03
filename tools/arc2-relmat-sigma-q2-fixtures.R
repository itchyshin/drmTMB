# Arc 2 -- signal-bearing relmat SCALE-side q2 fixture (mc-0316).
#
# WHY THIS FILE EXISTS
# --------------------
# mc-0316's capability-ledger row (dpar=sigma, provider=relmat, q_gate=q2,
# estimator=ML) has NO genuine measured profile failure on record -- same
# disqualified-evidence pattern as mc-0292/mc-0304 (see
# tools/arc2-spatial-sigma-q2-fixtures.R's header for the full account of the
# n=1/N=100/Wald/zero-truth-correlation defect this file's evidence source
# shares). This file supplies the missing signal-bearing DGP, mirroring
# tools/arc2-phylo-sigma-fixtures.R::arc2_phylo_sigma_q2_nolabel_fixture()'s
# pattern exactly.
#
# The fitted formula (verified against
# tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R:399-406) is
# the SAME unlabelled term in both mu and sigma:
#
#     y ~ relmat(1 | id, K = K), sigma ~ relmat(1 | id, K = K)
#
# A live toy fit (Curie, 2026-08-03) confirms drmTMB auto-links this matching
# unlabelled pair into a joint q2 block exactly as it does for
# phylo/spatial/animal: `profile_targets()` exposes `sd:mu:mu:relmat(1 | id)`,
# `sd:sigma:sigma:relmat(1 | id)`, and a
# `cor:relmat:cor(mu:(Intercept),sigma:(Intercept) | relmat | id)` target.
# Only the two marginal SDs are gated; the correlation is reported for
# information but never gated, matching mc-0283's scoping precisely.
#
# DESIGN RATIONALE
# -----------------
# `n_id = 80` (NOT the smaller n_id = 40 that failed for mc-0424, relmat's
# NB2 q1 sigma-only sibling) with the SAME AR1-Toeplitz K construction
# (0.35^|i-j| off-diagonal decay, +0.15 ridge on the diagonal) already
# validated in tools/arc3-nbinom2-sigma-provider-fixtures.R and
# tests/testthat/test-animal-relmat-gaussian.R. mc-0424 needed n_id raised
# from 40 to 80 specifically because independently-drawn structured vectors
# can correlate by chance at small n (|cor| 0.457 at n_id=40 -> 0.135 at
# n_id=80 over a 10-seed scan there); a q2 block draws two independent
# provider-level vectors (mu-side, sigma-side) the same way, so n_id=80 is
# used here from the start rather than discovered by a failing gate.
# `n_each = 12` follows the Gaussian-scale replication ladder already
# validated for mc-0277/mc-0283/mc-0279/mc-0292/mc-0304.

#' Gaussian ML fixture with genuine relmat (AR1-Toeplitz relatedness) signal
#' on BOTH mu and log(sigma) via two UNLABELLED matching `relmat(1 | id)`
#' terms (mc-0316 shape).
#'
#' @param n_id Number of individuals. Default 80 (not the smaller n_id=40
#'   that failed for mc-0424 -- see file header).
#' @param n_each Observations per individual. Default 12.
#' @param seed RNG seed.
#' @param true_sd_mu True SD of the relmat effect on mu (identity link,
#'   additive on the response scale).
#' @param true_log_sd_sigma True SD of the relmat effect on log(sigma).
#' @param mu0 Intercept on mu.
#' @param log_sigma0 Baseline log residual SD.
#' @return list(data, K, Q, true_sd_mu, true_log_sd_sigma)
arc2_relmat_sigma_q2_fixture <- function(n_id = 80L,
                                         n_each = 12L,
                                         seed = 101L,
                                         true_sd_mu = 0.6,
                                         true_log_sd_sigma = 0.7,
                                         mu0 = 0.4,
                                         log_sigma0 = log(0.5)) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  L <- t(chol(K))
  u_mu <- as.vector(L %*% stats::rnorm(n_id)) * true_sd_mu
  u_sigma <- as.vector(L %*% stats::rnorm(n_id)) * true_log_sd_sigma
  names(u_mu) <- id_levels
  names(u_sigma) <- id_levels
  id <- rep(id_levels, each = n_each)
  n <- length(id)
  sigma_tip <- exp(log_sigma0 + u_sigma[id])
  y <- mu0 + u_mu[id] + stats::rnorm(n, 0, sigma_tip)
  list(
    data = data.frame(
      y = y,
      id = factor(id, levels = id_levels)
    ),
    K = K,
    Q = Q,
    true_sd_mu = true_sd_mu,
    true_log_sd_sigma = true_log_sd_sigma
  )
}
