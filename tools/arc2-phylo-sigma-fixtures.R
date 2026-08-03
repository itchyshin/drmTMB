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
