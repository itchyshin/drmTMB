# check_drm() guidance for a weakly identified scale-side phylogenetic field.
# See docs/design/171-scale-side-phylo-identifiability-model-a.md.

# A small, well-posed univariate location-scale phylo fit WITH multiple
# observations per tip (so the scale-side field is identifiable and an sdreport
# is produced). Branch behaviour is then exercised by setting sdr$pdHess.
make_scale_phylo_fit <- function(se = TRUE) {
  skip_if_not_installed("ape")
  set.seed(303)
  n_tip <- 18L
  reps <- 6L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("t", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  L <- t(chol(A))
  z_mu <- as.vector(L %*% stats::rnorm(n_tip))
  z_sig <- as.vector(L %*% stats::rnorm(n_tip))
  tip <- rep(tree$tip.label, each = reps)
  idx <- match(tip, tree$tip.label)
  x <- stats::rnorm(n_tip * reps)
  mu <- 0.3 + 0.5 * x + 0.4 * z_mu[idx]
  log_sigma <- -0.3 + 0.2 * x + 0.3 * z_sig[idx]
  y <- stats::rnorm(n_tip * reps, mu, exp(log_sigma))
  d <- data.frame(y = y, x = x, species = factor(tip, levels = tree$tip.label))
  # The scale-side phylo fixture is deliberately near-degenerate; without the
  # log-sigma clamp (a separate change) the fit can emit "NaNs produced" while
  # optimising. That is incidental here -- this fixture exists only to exercise
  # the guidance check's branches via sdr$pdHess, not to test fit quality.
  suppressWarnings(drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ x + phylo(1 | species, tree = tree)
    ),
    data = d,
    control = drm_control(se = se)
  ))
}

test_that("scale-phylo identifiability check is NULL when phylogeny is on the mean only", {
  skip_on_cran()
  skip_if_not_installed("ape")
  set.seed(404)
  n_tip <- 18L
  reps <- 5L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("t", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  L <- t(chol(A))
  z_mu <- as.vector(L %*% stats::rnorm(n_tip))
  tip <- rep(tree$tip.label, each = reps)
  idx <- match(tip, tree$tip.label)
  x <- stats::rnorm(n_tip * reps)
  y <- 0.3 +
    0.5 * x +
    0.4 * z_mu[idx] +
    stats::rnorm(n_tip * reps, 0, exp(-0.3 + 0.2 * x))
  d <- data.frame(y = y, x = x, species = factor(tip, levels = tree$tip.label))

  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ x),
    data = d,
    control = drm_control(se = FALSE)
  )

  # phylo on the mean only -> no scale-side field -> opt out of the check
  expect_null(drmTMB:::check_scale_phylo_identifiability(fit))
})

test_that("scale-phylo identifiability check reports ok when pdHess is TRUE", {
  skip_on_cran()
  fit <- make_scale_phylo_fit(se = TRUE)
  skip_if(is.null(fit$sdr))
  fit$sdr$pdHess <- TRUE

  row <- drmTMB:::check_scale_phylo_identifiability(fit)
  expect_equal(row$check, "scale_phylo_identifiability")
  expect_equal(row$status, "ok")
})

test_that("scale-phylo identifiability check steers to a fixed-effect scale when pdHess is not TRUE", {
  skip_on_cran()
  fit <- make_scale_phylo_fit(se = TRUE)
  skip_if(is.null(fit$sdr))
  fit$sdr$pdHess <- FALSE

  row <- drmTMB:::check_scale_phylo_identifiability(fit)
  expect_equal(row$status, "note")
  expect_match(row$message, "scale", ignore.case = TRUE)
  expect_match(row$message, "fixed effects")
})

test_that("scale-phylo identifiability check is NULL without an sdreport", {
  skip_on_cran()
  fit <- make_scale_phylo_fit(se = FALSE)
  expect_null(drmTMB:::check_scale_phylo_identifiability(fit))
})
