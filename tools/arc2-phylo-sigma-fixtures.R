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
