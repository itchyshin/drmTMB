# S2 (Russell Dinnage's #1301 comment; docs/design/275, Fisher's 2026-09-14
# ruling): drm_constant_residual_sigma() must return the marginal residual
# variance E[sigma^2] = exp(2*b0 + 2*sum_k(omega_k^2)) -- not the squared
# median exp(2*b0) -- whenever `sigma` carries an ordinary random intercept
# or a unit-diagonal phylogenetic random intercept. Both callers
# (drm_derived_summary_rows() in R/methods.R and drm_variance_ratio()/
# drm_variance_ratio_delta() in R/heritability.R) must use it, and the
# delta-method SE must extend its gradient over the omega_k positions too.
# A random SLOPE on sigma, or a structured sigma effect without a verified
# unit-diagonal correlation, has no closed-form marginal residual variance
# and must be refused with a message naming why.

test_that("S2: drm_constant_residual_sigma() returns the marginal moment for an ordinary sigma random intercept", {
  set.seed(20260914)
  n_g <- 40L
  n_each <- 10L
  g <- factor(rep(seq_len(n_g), each = n_each))
  n <- length(g)
  b0_mu <- 1
  sd_mu_g <- 0.7
  b0_sigma <- -0.3
  omega_true <- 0.6
  u_mu <- stats::rnorm(n_g, sd = sd_mu_g)
  u_sigma <- stats::rnorm(n_g, sd = omega_true)
  y <- b0_mu + u_mu[g] +
    stats::rnorm(n, sd = exp(b0_sigma + u_sigma[g]))
  dat <- data.frame(y = y, g = g)

  fit <- drmTMB(bf(y ~ 1 + (1 | g), sigma ~ 1 + (1 | g)), data = dat)
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)

  b0_hat <- unname(coef(fit)$sigma[["(Intercept)"]])
  omega_hat <- unname(fit$sdpars$sigma[["(1 | g)"]])
  expected_sigma <- exp(b0_hat + omega_hat^2)

  # (a) drm_constant_residual_sigma() is the closed-form identity, not an
  # independent estimate -- tight tolerance.
  expect_equal(
    drmTMB:::drm_constant_residual_sigma(fit),
    expected_sigma,
    tolerance = 1e-8
  )

  # (b) summary()$derived's residual_variance / estimate use it.
  derived <- summary(fit)$derived
  row <- derived["derived:total_variance_share(g)", , drop = FALSE]
  expect_equal(nrow(row), 1L)
  expected_residual_variance <- exp(2 * b0_hat + 2 * omega_hat^2)
  expect_equal(
    row$residual_variance,
    expected_residual_variance,
    tolerance = 1e-8
  )
  v_g <- unname(fit$sdpars$mu[["(1 | g)"]])^2
  expect_equal(
    row$estimate,
    v_g / (v_g + expected_residual_variance),
    tolerance = 1e-8
  )

  # (c) repeatability()'s point estimate uses the same marginal residual
  # variance, and its delta-method SE is finite, positive, and DIFFERENT from
  # the pre-fix (median-based) SE computed by hand below.
  r <- repeatability(fit)
  expect_equal(
    r$estimate,
    v_g / (v_g + expected_residual_variance),
    tolerance = 1e-8
  )
  expect_true(is.finite(r$se))
  expect_gt(r$se, 0)

  opt_names <- names(fit$opt$par)
  mu_position <- which(opt_names == "log_sd_mu")
  resid_position <- which(opt_names == "beta_sigma")
  old_style <- drmTMB:::drm_variance_ratio_delta(
    theta_hat = fit$opt$par,
    cov_fixed = fit$sdr$cov.fixed,
    denom_groups = list(
      list(positions = mu_position, value = function(t) exp(2 * t[[1L]])),
      list(positions = resid_position, value = function(t) exp(2 * t[[1L]]))
    ),
    focal_index = 1L
  )
  expect_true(is.finite(old_style$se))
  # The corrected estimate must differ from the pre-fix (median-based) point
  # estimate -- this is the median-vs-marginal gap Russell's comment names.
  expect_false(isTRUE(all.equal(r$estimate, old_style$estimate)))
  expect_false(isTRUE(all.equal(r$se, old_style$se)))
})

test_that("S2: a constant sigma ~ 1 fit is unaffected by the fix (bit-identical closed form)", {
  set.seed(20260917)
  n_g <- 25L
  n_each <- 8L
  g <- factor(rep(seq_len(n_g), each = n_each))
  n <- length(g)
  u_mu <- stats::rnorm(n_g, sd = 0.6)
  y <- 1 + u_mu[g] + stats::rnorm(n, sd = exp(-0.4))
  dat <- data.frame(y = y, g = g)

  fit <- drmTMB(bf(y ~ 1 + (1 | g), sigma ~ 1), data = dat)
  expect_equal(fit$opt$convergence, 0)

  b0_hat <- unname(coef(fit)$sigma[["(Intercept)"]])
  # (d) no sigma random effect -- drm_constant_residual_sigma() must still be
  # the plain exp(b0) it always was, bit-identical.
  expect_identical(drmTMB:::drm_constant_residual_sigma(fit), exp(b0_hat))

  r <- repeatability(fit)
  v_g <- unname(fit$sdpars$mu[["(1 | g)"]])^2
  expect_equal(r$estimate, v_g / (v_g + exp(2 * b0_hat)), tolerance = 1e-10)

  derived <- summary(fit)$derived
  row <- derived["derived:total_variance_share(g)", , drop = FALSE]
  expect_equal(row$residual_variance, exp(2 * b0_hat), tolerance = 1e-10)
})

test_that("S2: a random SLOPE on sigma is refused by name, not silently returned as exp(b0)", {
  set.seed(20260915)
  n_g <- 30L
  n_each <- 10L
  g <- factor(rep(seq_len(n_g), each = n_each))
  n <- length(g)
  x <- stats::rnorm(n)
  u_mu <- stats::rnorm(n_g, sd = 0.5)
  u_slope <- stats::rnorm(n_g, sd = 0.3)
  # sigma ~ (0 + x | g): an uncorrelated residual-scale random SLOPE, the
  # supported form asserted in test-gaussian-random-intercepts.R
  # ("expect_no_error(drmTMB(bf(y ~ x, sigma ~ (0 + x | id)), ...))").
  y <- 1 + u_mu[g] +
    stats::rnorm(n, sd = exp(-0.5 + u_slope[g] * x))
  dat <- data.frame(y = y, x = x, g = g)

  fit <- drmTMB(bf(y ~ 1 + (1 | g), sigma ~ (0 + x | g)), data = dat)

  expect_true(is.na(drmTMB:::drm_constant_residual_sigma(fit)))
  expect_error(repeatability(fit), "random slope on sigma")
  expect_error(icc(fit), "random slope on sigma")
  expect_error(heritability(fit), "random slope on sigma")

  derived <- summary(fit)$derived
  expect_equal(nrow(derived), 0L)
  expect_match(
    attr(derived, "residual_variance.message"),
    "random slope on sigma"
  )
  # residual_variance.message must not just be attached, it must be SHOWN
  # (2026-09-14 ruling, S2b item 5): print.summary.drmTMB() emits it via
  # cli_text(), which surfaces through message(), not through
  # capture.output()/stdout.
  expect_message(print(summary(fit)), "random slope on sigma")
})

test_that("S2: a unit-diagonal phylogenetic random intercept on sigma gets the same closed form", {
  skip_if_not_installed("ape")

  set.seed(20260916)
  n_tip <- 20L
  n_each <- 8L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  u_mu <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip)) * 0.9
  omega_phylo_true <- 0.4
  u_sigma <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip)) * omega_phylo_true
  species <- factor(
    rep(tree$tip.label, each = n_each),
    levels = tree$tip.label
  )
  tip_index <- rep(seq_len(n_tip), each = n_each)
  b0_sigma <- -0.4
  y <- 2 + u_mu[tip_index] +
    stats::rnorm(length(species), sd = exp(b0_sigma + u_sigma[tip_index]))
  dat <- data.frame(y = y, species = species)

  fit <- drmTMB(
    bf(
      y ~ 1 + phylo(1 | species, tree = tree),
      sigma ~ 1 + phylo(1 | species, tree = tree)
    ),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)

  b0_hat <- unname(coef(fit)$sigma[["(Intercept)"]])
  omega_hat <- unname(fit$sdpars$sigma[["sigma:phylo(1 | species)"]])
  expected_sigma <- exp(b0_hat + omega_hat^2)

  expect_equal(
    drmTMB:::drm_constant_residual_sigma(fit),
    expected_sigma,
    tolerance = 1e-8
  )

  # Negative control for the phylo arm, at the USER-FACING loci (2026-09-14
  # ruling, S2b items 2-3): this fit has phylo() on BOTH mu and sigma, so
  # split_tmb_sdpars() prefixes the mu-side label "mu:phylo(1 | species)"
  # (R/drmTMB.R phylo_mu_sd_labels()); before the fix that prefix defeated
  # derived_summary_random_effect_kind() (R/methods.R) and
  # drm_variance_ratio_positions()'s structured-marker regex
  # (R/heritability.R:453), so summary()$derived returned 0 rows and
  # repeatability()/icc()/heritability() aborted even though
  # drm_constant_residual_sigma() above was already correct. Both loci must
  # now report the SAME closed-form share.
  expected_residual_variance <- exp(2 * b0_hat + 2 * omega_hat^2)
  v_mu <- unname(fit$sdpars$mu[["mu:phylo(1 | species)"]])^2
  expected_share <- v_mu / (v_mu + expected_residual_variance)

  derived <- summary(fit)$derived
  expect_equal(nrow(derived), 1L)
  row <- derived["derived:phylo_total_variance_share(species)", , drop = FALSE]
  expect_equal(nrow(row), 1L)
  expect_equal(
    row$residual_variance,
    expected_residual_variance,
    tolerance = 1e-8
  )
  expect_equal(row$estimate, expected_share, tolerance = 1e-8)

  r <- repeatability(fit)
  expect_true(is.finite(r$estimate))
  expect_equal(r$estimate, expected_share, tolerance = 1e-8)
  expect_true(is.finite(r$se))

  ic <- icc(fit)
  expect_true(is.finite(ic$estimate))
  expect_equal(ic$estimate, expected_share, tolerance = 1e-8)
})

# S2b follow-up (Fisher's 2026-09-14 fresh-context review,
# docs/dev-log/audits/2026-09-14-dinnage-wave3-review.md "### S2b follow-up
# (4ae2f5d99, d61f65183)", REQUIRED items 1-3):
# drm_structured_sigma_unit_diagonal() must measure the diagonal on the
# MODELLED-UNIT rows (the tip/species rows indexed by the object's own
# `precision$tip_node_index` / `precision$species_node_index`), not the
# whole augmented tips-plus-internal-nodes basis, or `phylo()` on `sigma`
# ALONE (no `phylo()` on `mu`) is falsely refused as "not unit diagonal"
# even though its tip-level correlation diagonal is exactly one. And
# drm_constant_residual_sigma() must refuse the marginal on a clamp-active
# fit rather than report the unclamped moment of a distribution the
# likelihood never evaluates.

test_that("S2b: sigma ~ spatial(1 | site, coords = ) with a q == 1 unit-diagonal correlation gets the closed form", {
  set.seed(20260918)
  n_site <- 20L
  n_each <- 8L
  coords <- data.frame(
    x = stats::runif(n_site, 0, 10),
    y = stats::runif(n_site, 0, 10),
    row.names = paste0("site_", seq_len(n_site))
  )
  site <- factor(
    rep(rownames(coords), each = n_each),
    levels = rownames(coords)
  )
  # Same exponential covariance drm_spatial_coords_precision() builds
  # (R/drmTMB.R:14688-14735), so the fitted omega recovers something close
  # to what generated the data.
  dist_mat <- as.matrix(stats::dist(coords))
  positive <- as.numeric(dist_mat)[as.numeric(dist_mat) > 0]
  range <- stats::median(positive)
  cov <- exp(-dist_mat / range)
  omega_spatial_true <- 0.4
  u_sigma <- as.vector(t(chol(cov)) %*% stats::rnorm(n_site)) *
    omega_spatial_true
  site_index <- rep(seq_len(n_site), each = n_each)
  b0_sigma <- -0.3
  n <- length(site)
  y <- 2 + stats::rnorm(n, sd = exp(b0_sigma + u_sigma[site_index]))
  dat <- data.frame(y = y, site = site)

  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1 + spatial(1 | site, coords = coords)),
    family = gaussian(),
    data = dat
  )
  expect_equal(fit$opt$convergence, 0)

  b0_hat <- unname(coef(fit)$sigma[["(Intercept)"]])
  omega_hat <- unname(fit$sdpars$sigma[[1L]])
  expected_sigma <- exp(b0_hat + omega_hat^2)

  expect_equal(
    drmTMB:::drm_constant_residual_sigma(fit),
    expected_sigma,
    tolerance = 1e-8
  )
})

test_that("S2b: a unit-diagonal phylogenetic random intercept on sigma ALONE (no phylo on mu) gets the closed form -- the regressed arm", {
  skip_if_not_installed("ape")

  set.seed(20260919)
  n_tip <- 20L
  n_each <- 8L
  n_g <- 10L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  omega_phylo_true <- 0.4
  u_sigma <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip)) * omega_phylo_true
  species <- factor(
    rep(tree$tip.label, each = n_each),
    levels = tree$tip.label
  )
  tip_index <- rep(seq_len(n_tip), each = n_each)
  n <- length(species)
  g <- factor(rep(seq_len(n_g), length.out = n))
  u_mu_g <- stats::rnorm(n_g, sd = 0.5)
  b0_sigma <- -0.4
  y <- 2 + u_mu_g[as.integer(g)] +
    stats::rnorm(n, sd = exp(b0_sigma + u_sigma[tip_index]))
  dat <- data.frame(y = y, species = species, g = g)

  fit <- drmTMB(
    bf(
      y ~ 1 + (1 | g),
      sigma ~ 1 + phylo(1 | species, tree = tree)
    ),
    family = gaussian(),
    data = dat
  )
  expect_equal(fit$opt$convergence, 0)

  b0_hat <- unname(coef(fit)$sigma[["(Intercept)"]])
  omega_hat <- unname(fit$sdpars$sigma[[1L]])
  expected_sigma <- exp(b0_hat + omega_hat^2)

  # (b) this is the arm 4ae2f5d99 regressed: phylo()'s q == 1 precision on
  # `sigma` alone is the 38x38 tips-plus-internal-nodes augmented matrix,
  # and its tip rows (species_node_index) have a unit diagonal even though
  # the whole augmented diagonal does not.
  expect_equal(
    drmTMB:::drm_constant_residual_sigma(fit),
    expected_sigma,
    tolerance = 1e-8
  )

  expected_residual_variance <- exp(2 * b0_hat + 2 * omega_hat^2)
  v_g <- unname(fit$sdpars$mu[["(1 | g)"]])^2
  expected_share <- v_g / (v_g + expected_residual_variance)

  derived <- summary(fit)$derived
  expect_equal(nrow(derived), 1L)
  row <- derived["derived:total_variance_share(g)", , drop = FALSE]
  expect_equal(nrow(row), 1L)
  expect_equal(
    row$residual_variance,
    expected_residual_variance,
    tolerance = 1e-8
  )
  expect_equal(row$estimate, expected_share, tolerance = 1e-8)

  r <- repeatability(fit)
  expect_true(is.finite(r$estimate))
  expect_equal(r$estimate, expected_share, tolerance = 1e-8)
  expect_true(is.finite(r$se))

  ic <- icc(fit)
  expect_true(is.finite(ic$estimate))
  expect_equal(ic$estimate, expected_share, tolerance = 1e-8)
})

test_that("S2b: a genuinely non-unit-diagonal structured precision still refuses, by name", {
  # Hand-built precision with no tip/species index attached (mirroring
  # phylo_interaction()'s Kronecker block, which carries none either) --
  # the helper must measure it (there is no index to fall back to) and
  # refuse, never claim "not checked" as a way to dodge a real answer, and
  # never claim "unit" for a diagonal that is not.
  bad_precision <- matrix(c(2, 0.5, 0.2, 0.5, 2, 0.3, 0.2, 0.3, 2), nrow = 3)
  bad_structured <- list(q = 1L, precision = list(precision = bad_precision))

  expect_identical(
    drmTMB:::drm_structured_sigma_unit_diagonal(bad_structured),
    FALSE
  )
})

test_that("S2b: a clamp-active fit refuses the marginal residual variance by name, and the default band still gets the closed form", {
  set.seed(20260920)
  n_g <- 12L
  n_each <- 10L
  g <- factor(rep(seq_len(n_g), each = n_each))
  n <- length(g)
  u_mu <- stats::rnorm(n_g, sd = 0.6)
  u_sigma <- stats::rnorm(n_g, sd = 1.4)
  b0_sigma <- 0
  band <- c(-0.6, 0.6)
  margin <- 0.2
  raw_eta <- b0_sigma + u_sigma[g]
  sigma_clamped <- exp(drmTMB:::drm_softclamp_log_sd(
    raw_eta,
    list(use_logsigma_clamp = 1L, logsigma_clamp = c(band, margin))
  ))
  y <- 1 + u_mu[g] + stats::rnorm(n, sd = sigma_clamped)
  dat <- data.frame(y = y, g = g)

  fit_clamped <- suppressWarnings(drmTMB(
    bf(y ~ 1 + (1 | g), sigma ~ 1 + (1 | g)),
    family = gaussian(),
    data = dat,
    control = drm_control(
      logsigma_clamp = band,
      logsigma_clamp_margin = margin
    )
  ))

  report <- fit_clamped$obj$report(fit_clamped$tmb_state$last.par.best)
  info <- drmTMB:::drm_logsigma_clamp_active(report, fit_clamped$model$tmb_data)
  # Sanity: the fixture really is clamp-active at the optimum.
  expect_false(is.null(info))

  sigma_na <- drmTMB:::drm_constant_residual_sigma(fit_clamped)
  expect_true(is.na(sigma_na))
  expect_identical(attr(sigma_na, "reason"), "clamp_limited")

  expect_error(repeatability(fit_clamped), "clamp")

  fit_default <- suppressWarnings(drmTMB(
    bf(y ~ 1 + (1 | g), sigma ~ 1 + (1 | g)),
    family = gaussian(),
    data = dat
  ))
  b0_hat <- unname(coef(fit_default)$sigma[["(Intercept)"]])
  omega_hat <- unname(fit_default$sdpars$sigma[["(1 | g)"]])
  expected_sigma <- exp(b0_hat + omega_hat^2)
  expect_equal(
    drmTMB:::drm_constant_residual_sigma(fit_default),
    expected_sigma,
    tolerance = 1e-8
  )
})
