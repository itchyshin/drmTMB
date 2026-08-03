# Arc 2 — signal-bearing phylogenetic SCALE-side fixtures.
#
# WHY THIS FILE EXISTS
# --------------------
# The Arc 0 candidate manifest prescribed `reml_phylo_location_fixture()`
# (tests/testthat/test-reml-phylo-location.R:9) for mc-0277
# (`sd:sigma:phylo(1 | species)`) and mc-0283 (its matched q2 sibling). That
# fixture puts the phylogenetic effect ONLY on the mean:
#
#     u <- as.vector(t(chol(A)) %*% rnorm(n_tip)) * 0.6   # :14  -- on mu
#     y <- 0.4 + 0.7 * x + u[tip] + rnorm(n, 0, 0.5)      # :18  -- resid SD fixed
#
# so the TRUE sigma-phylo SD is exactly ZERO. Profiling a variance component
# whose true value is zero drives the lower endpoint to the boundary of
# [0, Inf) by construction: the deviance never crosses the critical value on
# that side. That is correct profile behaviour under a null variance
# component, NOT a drmTMB limitation, and a boundary result obtained that way
# must never be recorded as a capability STOP. The test file says as much in
# its own words at test-reml-phylo-location.R:154-160 ("no true sigma-phylo
# signal ... expected boundary artifact").
#
# This file supplies the missing signal-bearing DGP. Validated by Fisher
# before promotion: at n_tip = 60, n_each = 12, true log-SD 0.7, the target
# profiled cleanly across three seeds --
#   seed 101: est 0.696, [0.413, 1.141]
#   seed 202: est 0.899, [0.631, 1.268]
#   seed 303: est 0.652, [0.461, 0.930]
# all with convergence 0, pdHess TRUE, and no boundary flag.
#
# DESIGN RATIONALE (do not shrink these without re-deriving)
# ----------------------------------------------------------
# Scale-side variance components need WITHIN-GROUP replication to be
# identified -- a standing drmTMB caveat. n_each = 12 gives twelve residuals
# per tip, enough to estimate each tip's own dispersion and so separate
# tip-level sigma variation from residual noise. The manifest's n_each = 3
# does not. It has NOT been established that this target is identifiable at
# the manifest's original n_tip = 30 / n_each = 3 even once real signal is
# added; do not assume it is.

#' Gaussian REML fixture with a genuine phylogenetic effect on log(sigma)
#'
#' @param n_tip Number of tips (species). Default 60.
#' @param n_each Observations per tip. Default 12 -- the replication that
#'   makes the scale-side component identifiable.
#' @param seed RNG seed.
#' @param true_log_sd_phylo True SD of the phylogenetic effect on log(sigma).
#' @param log_sigma0 Baseline log residual SD.
#' @return list(data, tree, true_log_sd_phylo)
arc2_phylo_sigma_fixture <- function(n_tip = 60L,
                                     n_each = 12L,
                                     seed = 101L,
                                     true_log_sd_phylo = 0.7,
                                     log_sigma0 = log(0.5)) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  # Phylogenetic effect placed on log(sigma), scaled to true_log_sd_phylo.
  v <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip)) * true_log_sd_phylo
  tip <- rep(seq_len(n_tip), each = n_each)
  n <- n_tip * n_each
  x <- stats::rnorm(n)
  sigma_tip <- exp(log_sigma0 + v[tip])
  y <- 0.4 + 0.7 * x + stats::rnorm(n, 0, sigma_tip)
  list(
    data = data.frame(
      y = y,
      x = x,
      species = factor(tree$tip.label[tip], levels = tree$tip.label)
    ),
    tree = tree,
    true_log_sd_phylo = true_log_sd_phylo
  )
}

# mc-0283 -- matched q2 sibling of mc-0277
# ----------------------------------------
# mc-0283's direct target is `sd:sigma:sigma:phylo(1 | p | species)` (confirmed
# by inspecting `drm_profile_targets()` output on a fitted q2 model: the
# labelled RE `phylo(1 | p | species)` appears verbatim in the term name, and
# the sigma-dpar row gets an extra "sigma:" prefix inserted ahead of the term,
# giving the doubled "sd:sigma:sigma:..." string -- this is real naming
# behaviour, not a typo). The matched q2 formula itself is copied verbatim
# from tests/testthat/test-reml-phylo-location.R:163-164 ("REML admits matched
# mean-and-scale phylogenetic effects (q2 block)"):
#
#     y ~ x + phylo(1 | p | species, tree = tree),
#     sigma ~ 1 + phylo(1 | p | species, tree = tree)
#
# That test's own fixture (`reml_phylo_location_fixture()`) has NO true
# sigma-phylo signal (same defect as mc-0277's manifest fixture, see the file
# header above), so it cannot be reused for a profile-feasibility gate here.
# `arc2_phylo_sigma_q2_fixture()` instead places independent genuine
# phylogenetic signal on BOTH mu (identity link, additive) and log(sigma)
# (log link), each with its own known true SD, at n_tip = 60 / n_each = 12
# (n = 720) -- the same replication ladder already validated for mc-0277's
# scale-only sibling, comfortably above the Arc 0 manifest's N>=250 q2
# information floor. The two phylo draws are independent (true correlation 0)
# because the point-fit gate only targets the two marginal SDs, not the
# mu/sigma phylo correlation the q2 formula also estimates; that correlation
# is reported for information but is not gated.
#
# Point-fit gate (predeclared: mean relative error <= 0.35 over >= 3 seeds,
# on BOTH the mu-side and sigma-side phylo SD) -- PASSED:
#   seed 101: est_mu 0.549 (true 0.60, relerr 0.085); est_sigma 0.513 (true
#     0.70, relerr 0.267); conv 0, pdHess TRUE
#   seed 202: est_mu 0.702 (true 0.60, relerr 0.169); est_sigma 0.809 (true
#     0.70, relerr 0.156); conv 0, pdHess TRUE
#   seed 303: est_mu 0.593 (true 0.60, relerr 0.011); est_sigma 0.553 (true
#     0.70, relerr 0.211); conv 0, pdHess TRUE
#   mean relerr mu = 0.088, mean relerr sigma = 0.211 -- both under gate.
#
# Given the point-fit gate passed, mc-0283's direct target (`sd:sigma:sigma:
# phylo(1 | p | species)`) was profiled at the SAME three seeds via
# tools/run-arc2-profile-feasibility.R --cell=mc-0283 and PASSED the full Arc
# 2 contract at all three (single stats::profile() call each; convergence 0;
# pdHess TRUE; not boundary/clamp-limited; trace spans both sides):
#   seed 101: est 0.513, [0.311, 0.873]
#   seed 202: est 0.809, [0.586, 1.118]
#   seed 303: est 0.553, [0.316, 0.864]

#' Gaussian REML fixture with genuine phylogenetic signal on BOTH mu and
#' log(sigma) (matched q2 block), for the `phylo(1 | p | species)` label.
#'
#' @param n_tip Number of tips (species). Default 60.
#' @param n_each Observations per tip. Default 12 -- see file header.
#' @param seed RNG seed.
#' @param true_sd_mu True SD of the phylogenetic effect on mu (identity link,
#'   additive on the response scale).
#' @param true_log_sd_sigma True SD of the phylogenetic effect on log(sigma).
#' @param mu0 Intercept on mu.
#' @param beta_x Slope on mu.
#' @param log_sigma0 Baseline log residual SD.
#' @return list(data, tree, true_sd_mu, true_log_sd_sigma)
arc2_phylo_sigma_q2_fixture <- function(n_tip = 60L,
                                        n_each = 12L,
                                        seed = 101L,
                                        true_sd_mu = 0.6,
                                        true_log_sd_sigma = 0.7,
                                        mu0 = 0.4,
                                        beta_x = 0.7,
                                        log_sigma0 = log(0.5)) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  L <- t(chol(A))
  # Independent phylogenetic draws on mu (additive) and log(sigma) (log
  # link); see file header for why independence is acceptable here.
  u_mu <- as.vector(L %*% stats::rnorm(n_tip)) * true_sd_mu
  u_sigma <- as.vector(L %*% stats::rnorm(n_tip)) * true_log_sd_sigma
  tip <- rep(seq_len(n_tip), each = n_each)
  n <- n_tip * n_each
  x <- stats::rnorm(n)
  sigma_tip <- exp(log_sigma0 + u_sigma[tip])
  y <- mu0 + beta_x * x + u_mu[tip] + stats::rnorm(n, 0, sigma_tip)
  list(
    data = data.frame(
      y = y,
      x = x,
      species = factor(tree$tip.label[tip], levels = tree$tip.label)
    ),
    tree = tree,
    true_sd_mu = true_sd_mu,
    true_log_sd_sigma = true_log_sd_sigma
  )
}

# mc-0279 -- the OTHER q2 phylo sigma cell, NOT a duplicate of mc-0283
# ----------------------------------------------------------------------
# mc-0279's own capability-ledger row (docs/dev-log/dashboard/capability-
# ledger/cells.tsv) is estimator=ML, route_variant="legacy_01", and its
# `legacy_evidence_source` points at "qseries_phylo_q1_mu_sigma_intercept" --
# tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R's UNLABELLED
# matched-intercept smoke, NOT test-reml-phylo-location.R's LABELLED
# `phylo(1 | p | species)` REML block that mc-0283 (route_variant="base",
# estimator=REML) is built on. The two cells differ on BOTH route_variant and
# estimator; they are genuinely different targets, not the same target under
# two ledger IDs.
#
# The smoke tool's actual fitted formula (verified by reading
# tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R:377-383) is
#
#     y ~ phylo(1 | species, tree = tree), sigma ~ phylo(1 | species, tree = tree)
#
# i.e. the SAME unlabelled term `phylo(1 | species)` in both mu and sigma,
# with NO explicit "p"/correlation label and no fixed-effect `x` in either
# dpar. A live toy fit (Curie, 2026-08-03) confirms drmTMB auto-links two
# matching unlabelled structured terms across mu and sigma into a joint q2
# covariance block WITHOUT an explicit label -- `profile_targets()` exposes
# `sd:mu:mu:phylo(1 | species)`, `sd:sigma:sigma:phylo(1 | species)` (the same
# doubled-prefix convention mc-0283's labelled block uses), AND a
# `cor:phylo:cor(mu:(Intercept),sigma:(Intercept) | phylo | species)` target
# -- so this IS a genuine q2 correlation block, just reached by matching group
# name rather than an explicit `p` label. This confirms the ledger's own
# claim_boundary text for mc-0278/mc-0279 ("matched intercept-only 2x2
# location-scale phylo block") rather than the `q1_plus_q1` /
# "separate_structured_scalars" language in
# docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv, which
# describes the DGP's independent draws, not the fitted model's parameter
# structure.
#
# The existing evidence for mc-0279 (the local n=1 smoke,
# docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-sigma-intercept-local-
# smoke.tsv) is disqualifying on its own terms: n_group=10/n_each=10 (N=100,
# far below the validated N=720 replication ladder), n_rep=1 (not evidence for
# a point-fit gate let alone a profile campaign), a Wald (not
# `stats::profile()`) confidence interval, and a bundled mu-sigma correlation
# target with TRUE value exactly 0 (`rho_mu_sigma = 0.00` in the smoke tool's
# `provider_defaults`) that drove the phylo row to
# `local_smoke_diagnostic_blocked` when that zero-truth correlation landed at
# its [-1, 1] boundary in the one replicate drawn -- the same defect class
# already diagnosed for mc-0277/mc-0283's SD targets, here on the correlation
# dimension of the SAME shape. None of this is genuine profile-failure
# evidence; `run` was never even attempted at an adequate N.
#
# `arc2_phylo_sigma_q2_nolabel_fixture()` supplies a signal-bearing DGP at the
# SAME validated n_tip=60/n_each=12 replication ladder as
# `arc2_phylo_sigma_q2_fixture()`, with independent structured draws on mu
# (identity link) and log(sigma) (log link) -- but WITHOUT the "p" label, so
# the fitted formula matches mc-0279's real (ML, unlabelled) shape rather than
# mc-0283's (REML, labelled) one. The point-fit gate targets ONLY the two
# marginal SDs; the auto-linked `cor:phylo:...` target is reported for
# information but never gated, mirroring mc-0283's scoping of its own
# correlation target exactly.
#
# Point-fit gate (predeclared: mean relative error <= 0.35 over 5 seeds, on
# BOTH the mu-side and sigma-side phylo SD) -- see the runner-independent gate
# script's output for the full per-seed table this header summarizes.

#' Gaussian ML fixture with genuine phylogenetic signal on BOTH mu and
#' log(sigma) via two UNLABELLED matching `phylo(1 | species)` terms (mc-0279
#' shape: drmTMB auto-links matching unlabelled structured terms across mu and
#' sigma into a joint q2 block).
#'
#' @param n_tip Number of tips (species). Default 60.
#' @param n_each Observations per tip. Default 12 -- see file header.
#' @param seed RNG seed.
#' @param true_sd_mu True SD of the phylogenetic effect on mu (identity link,
#'   additive on the response scale).
#' @param true_log_sd_sigma True SD of the phylogenetic effect on log(sigma).
#' @param mu0 Intercept on mu.
#' @param log_sigma0 Baseline log residual SD.
#' @return list(data, tree, true_sd_mu, true_log_sd_sigma)
arc2_phylo_sigma_q2_nolabel_fixture <- function(n_tip = 60L,
                                                n_each = 12L,
                                                seed = 101L,
                                                true_sd_mu = 0.6,
                                                true_log_sd_sigma = 0.7,
                                                mu0 = 0.4,
                                                log_sigma0 = log(0.5)) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  L <- t(chol(A))
  u_mu <- as.vector(L %*% stats::rnorm(n_tip)) * true_sd_mu
  u_sigma <- as.vector(L %*% stats::rnorm(n_tip)) * true_log_sd_sigma
  tip <- rep(seq_len(n_tip), each = n_each)
  n <- n_tip * n_each
  sigma_tip <- exp(log_sigma0 + u_sigma[tip])
  y <- mu0 + u_mu[tip] + stats::rnorm(n, 0, sigma_tip)
  list(
    data = data.frame(
      y = y,
      species = factor(tree$tip.label[tip], levels = tree$tip.label)
    ),
    tree = tree,
    true_sd_mu = true_sd_mu,
    true_log_sd_sigma = true_log_sd_sigma
  )
}
