# Recovery upgrade for four cells that were previously smoke-only (convergence
# + SD-name checks) in test-nongaussian-structured-boundary.R. Each test here
# injects a known structured-effect signal into the correct linear predictor,
# simulates the response from the matching family, fits, and checks that the
# recovered per-group structured effect correlates with the injected truth.
# Fixture-construction patterns (coords data.frames for spatial(), pedigrees
# for animal(), Q matrices for relmat()) mirror
# test-nongaussian-structured-boundary.R lines 1-270.

test_that("zi_poisson: spatial(1 | id) on zi recovers the injected field", {
  skip_on_cran()
  skip_if_not_installed("ape")
  skip_if_not_installed("MASS")

  set.seed(2026070904)
  n_levels <- 60L
  levels_zi <- paste0("pz", seq_len(n_levels))
  obs_per <- 20L
  id <- factor(rep(levels_zi, each = obs_per), levels = levels_zi)
  x <- stats::rnorm(length(id))
  theta <- seq(0, 1.9 * pi, length.out = n_levels)
  coords <- data.frame(x = cos(theta), y = sin(theta), row.names = levels_zi)
  # Same precision -> covariance -> Cholesky route the marker itself uses, so
  # the injected field lives on the same spatial covariance the fit assumes.
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = levels_zi,
    group = "site"
  )
  cov <- solve(as.matrix(precision$precision))
  field <- as.vector(
    t(chol(cov)) %*% stats::rnorm(n_levels, sd = 1.2)
  )
  names(field) <- levels_zi
  mu <- exp(0.7 + 0.25 * x)
  prob <- stats::plogis(-0.6 + field[as.character(id)])
  y <- ifelse(
    stats::rbinom(length(id), size = 1L, prob = prob) == 1L,
    0L,
    stats::rpois(length(id), lambda = mu)
  )
  dat <- data.frame(y = y, x = x, id = id)

  fit <- drmTMB(
    bf(y ~ x, zi ~ spatial(1 | id, coords = coords)),
    family = stats::poisson(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(as.integer(fit$opt$convergence), 0L)
  fitted_sd <- fit$sdpars$zi[["spatial(1 | id)"]]
  expect_true(is.finite(fitted_sd) && fitted_sd > 0)

  re <- ranef(fit, "spatial_zi")$values
  recovered_cor <- stats::cor(re, field[names(re)])
  expect_gt(abs(recovered_cor), 0.5)
})

test_that("beta: animal(1 | id) on log_sigma recovers the injected field", {
  skip_on_cran()
  skip_if_not_installed("ape")
  skip_if_not_installed("MASS")

  set.seed(2026070912)
  n_levels <- 60L
  levels_id <- paste0("bs", seq_len(n_levels))
  obs_per <- 15L
  id <- factor(rep(levels_id, each = obs_per), levels = levels_id)
  x <- stats::rnorm(length(id))
  field <- stats::rnorm(n_levels, sd = 0.6)
  names(field) <- levels_id
  mu <- stats::plogis(-0.2 + 0.45 * x)
  log_sigma <- log(0.22) + field[as.character(id)]
  # Confirmed parameterization: phi = exp(-2 * log_sigma).
  phi <- exp(-2 * log_sigma)
  y <- stats::rbeta(
    length(id),
    shape1 = mu * phi,
    shape2 = (1 - mu) * phi
  )
  dat <- data.frame(y = y, x = x, id = id)
  # Star pedigree (no dam/sire) gives an identity additive-relationship
  # matrix, so the injected field is iid across ids, matching how
  # dat_beta_sigma_animal is built in test-nongaussian-structured-boundary.R.
  ped <- data.frame(id = levels_id, dam = NA_character_, sire = NA_character_)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ animal(1 | id, pedigree = ped)),
    family = beta(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(as.integer(fit$opt$convergence), 0L)
  fitted_sd <- fit$sdpars$sigma[["animal(1 | id)"]]
  expect_true(is.finite(fitted_sd) && fitted_sd > 0)

  re <- ranef(fit, "animal_sigma")$values
  recovered_cor <- stats::cor(re, field[names(re)])
  expect_gt(abs(recovered_cor), 0.5)
})

test_that("student: spatial(1 | id) on mu recovers the injected field", {
  skip_on_cran()
  skip_if_not_installed("ape")
  skip_if_not_installed("MASS")

  set.seed(2026070921)
  n_levels <- 60L
  levels_id <- paste0("s", seq_len(n_levels))
  obs_per <- 15L
  id <- factor(rep(levels_id, each = obs_per), levels = levels_id)
  x <- stats::rnorm(length(id))
  theta <- seq(0, 1.9 * pi, length.out = n_levels)
  coords <- data.frame(x = cos(theta), y = sin(theta), row.names = levels_id)
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = levels_id,
    group = "site"
  )
  cov <- solve(as.matrix(precision$precision))
  field <- as.vector(
    t(chol(cov)) %*% stats::rnorm(n_levels, sd = 0.8)
  )
  names(field) <- levels_id
  mu <- 0.2 + 0.5 * x + field[as.character(id)]
  y <- mu + 0.25 * stats::rt(length(id), df = 12)
  dat <- data.frame(y = y, x = x, id = id)

  fit <- drmTMB(
    bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1),
    family = student(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(as.integer(fit$opt$convergence), 0L)
  fitted_sd <- fit$sdpars$mu[["spatial(1 | id)"]]
  expect_true(is.finite(fitted_sd) && fitted_sd > 0)

  re <- ranef(fit, "spatial_mu")$values
  recovered_cor <- stats::cor(re, field[names(re)])
  expect_gt(abs(recovered_cor), 0.5)
})

test_that("truncated_nbinom2: relmat(1 | id) on hu recovers the injected field", {
  skip_on_cran()
  skip_if_not_installed("ape")
  skip_if_not_installed("MASS")

  set.seed(2026070931)
  n_levels <- 60L
  levels_id <- paste0("th", seq_len(n_levels))
  obs_per <- 20L
  id <- factor(rep(levels_id, each = obs_per), levels = levels_id)
  x <- stats::rnorm(length(id))
  field <- stats::rnorm(n_levels, sd = 1.0)
  names(field) <- levels_id
  prob <- stats::plogis(-0.8 + field[as.character(id)])
  mu <- exp(0.5 + 0.2 * x)
  positive <- stats::rnbinom(length(id), mu = mu, size = 12)
  positive[positive == 0L] <- 1L
  y <- ifelse(
    stats::rbinom(length(id), size = 1L, prob = prob) == 1L,
    0L,
    positive
  )
  dat <- data.frame(y = y, x = x, id = id)
  Q <- diag(n_levels)
  dimnames(Q) <- list(levels_id, levels_id)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, hu ~ relmat(1 | id, Q = Q)),
    family = truncated_nbinom2(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(as.integer(fit$opt$convergence), 0L)
  fitted_sd <- fit$sdpars$hu[["relmat(1 | id)"]]
  expect_true(is.finite(fitted_sd) && fitted_sd > 0)

  re <- ranef(fit, "relmat_hu")$values
  recovered_cor <- stats::cor(re, field[names(re)])
  expect_gt(abs(recovered_cor), 0.5)
})
