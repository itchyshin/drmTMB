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
