#!/usr/bin/env Rscript
# Repair of the q4 spatial fixture — symbolic alignment first, then the DGP.
#
# THE DEFECT (measured 2026-08-15). The original adapter
# `lane_b_q4_provider_fixture` (recovered from commit 3672ce757) generates latent
# effects from
#     K   = 0.25^|i-j|,  diag(K) <- diag(K) + 0.35
#     eff = t(chol(K)) %*% Z %*% diag(sds)
# and then hands
#     * animal / relmat :  Ainv = solve(K)   -- the SAME matrix, so the model's
#                          estimand IS sds. These cells PASS the truth check.
#     * spatial         :  only `coords`. The model then builds its OWN
#                          correlation, ignoring K entirely.
#
# THE MODEL'S ACTUAL STRUCTURE (R/drmTMB.R:13388-13435, drm_spatial_coords_precision):
#     D     = as.matrix(dist(coords))
#     range = median(D[D > 0])
#     C     = exp(-D / range);  diag(C) <- diag(C) + 1e-6
#     precision = C^-1                      (scaled by 1/sd^2 in the likelihood)
# so the model assumes  effects ~ N(0, sd^2 * C)  and its estimand is that `sd`.
#
# With coords = (x = 1:60, y = sqrt(1:60)) the two structures are ~30x apart:
#     lag 1  ->  K = 0.250   vs   C = 0.942
#     lag 10 ->  K = 0.000   vs   C = 0.567
# A near-constant field cannot reproduce site-to-site variation without inflating
# its SD, which is the observed 3-4x. The declared truth was never the estimand.
#
# THE REPAIR. Generate the spatial arm from C, the structure the model actually
# assumes, so that  sd_true  is the parameter being estimated:
#     eff = t(chol(C)) %*% Z %*% diag(sds)      ==>  eff[,k] ~ N(0, sds[k]^2 * C)
#
# INDEPENDENCE. C is re-implemented here from the documented formula rather than
# obtained by calling drmTMB's internal. Deriving fixture truth from the very
# routine under test would make the oracle non-independent (the failure Fisher
# flagged for new_zero_one_beta_phylo_data()). Instead the two are built
# separately and ASSERTED equal -- that buys independence AND proves alignment.

suppressMessages(pkgload::load_all(".", compile = FALSE, quiet = TRUE))

q4_spatial_coords <- function(nlev = 60L) {
  labels <- paste0("site", seq_len(nlev))
  coords <- data.frame(x = seq_len(nlev), y = sqrt(seq_len(nlev)))
  rownames(coords) <- labels
  coords
}

# Independent re-implementation of the model's spatial covariance.
q4_spatial_covariance <- function(coords, jitter = 1e-6) {
  d <- as.matrix(stats::dist(coords))
  positive <- d[d > 0]
  range <- stats::median(positive)
  cov <- exp(-d / range)
  diag(cov) <- diag(cov) + jitter
  dimnames(cov) <- list(rownames(coords), rownames(coords))
  list(cov = cov, range = range)
}

# ALIGNMENT GATE: our independent C must invert to the model's precision.
q4_spatial_assert_alignment <- function(coords, tol = 1e-8) {
  ours <- q4_spatial_covariance(coords)
  theirs <- drmTMB:::drm_spatial_coords_precision(
    coords, site = rownames(coords), group = "site"
  )
  model_precision <- as.matrix(theirs$precision)
  our_precision <- solve(ours$cov)
  worst <- max(abs(model_precision - our_precision))
  rel <- worst / max(abs(model_precision))
  cat(sprintf(
    "  alignment: range ours=%.6f model=%.6f | worst precision abs diff=%.3e (rel %.3e)\n",
    ours$range, theirs$range, worst, rel
  ))
  if (!isTRUE(all.equal(ours$range, theirs$range))) {
    stop("range disagrees: the fixture is not aligned with the model", call. = FALSE)
  }
  if (rel > tol) {
    stop(sprintf("precision disagrees by rel %.3e > %.1e", rel, tol), call. = FALSE)
  }
  invisible(list(cov = ours$cov, range = ours$range))
}

# The repaired DGP. `sds` are, by construction, the model's estimands.
q4_spatial_repaired_fixture <- function(seed = 20260730L, nlev = 60L, neach = 10L,
                                        sds = c(.55, .50, .40, .35)) {
  coords <- q4_spatial_coords(nlev)
  aligned <- q4_spatial_assert_alignment(coords)
  set.seed(seed)
  L <- t(chol(aligned$cov))
  effects <- L %*% matrix(stats::rnorm(nlev * 4L), nlev, 4L) %*% diag(sds)
  ix <- rep(seq_len(nlev), each = neach)
  labels <- rownames(coords)
  data <- data.frame(
    y1 = .20 + effects[ix, 1L] + stats::rnorm(nlev * neach, 0, exp(-.8 + effects[ix, 3L])),
    y2 = -.10 + effects[ix, 2L] + stats::rnorm(nlev * neach, 0, exp(-.7 + effects[ix, 4L])),
    site = labels[ix]
  )
  fml <- drmTMB::bf(
    mu1    = y1 ~ 1 + drmTMB::spatial(1 | p | site, coords = coords),
    mu2    = y2 ~ 1 + drmTMB::spatial(1 | p | site, coords = coords),
    sigma1 =    ~ 1 + drmTMB::spatial(1 | p | site, coords = coords),
    sigma2 =    ~ 1 + drmTMB::spatial(1 | p | site, coords = coords),
    rho12  =    ~ 1
  )
  list(
    data = data, coords = coords, sds = sds,
    truth = data.frame(
      cell   = c("mc-0115", "mc-0116", "mc-0117", "mc-0118"),
      target = c("sd:mu:mu1:spatial(1 | p | site)", "sd:mu:mu2:spatial(1 | p | site)",
                 "sd:mu:sigma1:spatial(1 | p | site)", "sd:mu:sigma2:spatial(1 | p | site)"),
      true_value = sds, stringsAsFactors = FALSE
    ),
    fit = function() drmTMB::drmTMB(
      fml, family = drmTMB::biv_gaussian(), data = data,
      control = drmTMB::drm_control(optimizer = list(eval.max = 3000, iter.max = 3000))
    )
  )
}
