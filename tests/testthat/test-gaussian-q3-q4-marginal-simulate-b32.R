# Marginal simulation (`simulate(fit, re.form = NA)`, fresh random effects) for
# Gaussian ordinary unlabelled correlated blocks of three and four
# coefficients with one `sd(id, coef = ...)` formula per coefficient (fitting
# admitted 2026-11-02). Group g has random-effect covariance S_g = D_g R D_g,
# with R the fitted unstructured correlation matrix (applied to the standard
# normal latent first) and D_g the diagonal of the group-specific fitted SDs
# (applied second). A coefficient without an sd() formula keeps one constant SD.
#
# What is checked. For each simulated replicate, y - X beta = Z_g b_g + e is
# reduced per group to the OLS coefficients b_hat_g = (Z'Z)^-1 Z' (y - X beta).
# Since e is N(0, sigma^2 I), b_hat_g is exactly N(0, S_g + sigma^2 (Z'Z)^-1),
# where S_g, X beta and sigma are rebuilt by hand from the fitted coefficients
# and corpars (not from the package's SD extraction or simulation code).
#
# Monte Carlo tolerance, fixed before the first run. With nsim = 4000 iid
# replicates the sample covariance entry S_ij of N(0, Sigma) draws has
# Var(S_ij) = (Sigma_ij^2 + Sigma_ii Sigma_jj) / (nsim - 1). Each group and
# each unique entry (i <= j) gives a standardised error
#   z_ij = (S_ij - Sigma_ij) / sqrt((Sigma_ij^2 + Sigma_ii Sigma_jj)/(nsim-1)).
# The rule is |z_ij| <= 4.5 for every entry of every group (60 groups x 6 or
# 10 entries = 360 or 600 checks; a two-sided N(0,1) tail at 4.5 is 6.8e-06,
# so the family-wise false-alarm rate is below 0.5%, and the sample
# covariance at nsim = 4000 is close to normal: skew about sqrt(8/nsim)=0.045).
# Second, E[z^2] = 1, so the mean of z^2 over all entries must lie in
# [0.65, 1.35] (about 4 SE of the mean for 360 independent entries, with extra
# room for the within-group dependence). Third, the mean of each b_hat
# coefficient over replicates is within 4.5 standard errors of 0.
# The emulated bugs (R replaced by I; SD vector reversed in coefficient
# order) are scored against the SAME simulated draws with the same statistics;
# each must breach the |z| <= 4.5 rule and push the mean of z^2 above 1.35.
# In the pilot run the breach was wide (R = I: max |z| 24 to 33, mean z^2 70
# to 180; reversed SD: max |z| above 200), because the coefficient
# correlations and SD ratios are far larger than the Monte Carlo error.
# These are Monte Carlo moment checks of the sampler against the stated
# covariance. They make no recovery, calibration or parity claim.

g34ms_fixture <- function(q = 3L, groups = 60L, repeats = 8L,
                          seed = 20261102L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  n <- length(id)
  covariates <- c("x", "z", "u")[seq_len(q - 1L)]
  design <- as.data.frame(vapply(covariates, function(v) stats::rnorm(n),
                                 numeric(n)))
  w_group <- seq(-1, 1, length.out = groups)
  correlation <- diag(q)
  correlation[upper.tri(correlation)] <- c(0.4, -0.3, 0.2, 0.15, -0.25, 0.1)[
    seq_len(q * (q - 1L) / 2L)
  ]
  correlation[lower.tri(correlation)] <- t(correlation)[lower.tri(correlation)]
  chol_lower <- t(chol(correlation))
  sd_by_group <- cbind(
    exp(-0.5 + 0.4 * w_group),
    exp(-0.8 - 0.3 * w_group),
    matrix(0.3, groups, q - 2L)
  )
  latent <- t(vapply(seq_len(groups), function(g) {
    diag(sd_by_group[g, ]) %*% chol_lower %*% stats::rnorm(q)
  }, numeric(q)))
  zmat <- cbind(1, as.matrix(design))
  eta <- 0.2 + 0.5 * design$x - 0.3 * design$z +
    rowSums(zmat * latent[as.integer(id), , drop = FALSE])
  data <- data.frame(y = eta + stats::rnorm(n, sd = 0.5), design,
                     w = rep(w_group, each = repeats), id)
  list(data = data, w_group = w_group, q = q,
       coef_names = c("(Intercept)", covariates), covariates = covariates)
}

g34ms_fit <- function(fx, modelled = c("(Intercept)", "x")) {
  rhs <- paste(fx$covariates, collapse = " + ")
  main <- stats::as.formula(paste0("y ~ x + z + (1 + ", rhs, " | id)"))
  sd_formulas <- lapply(modelled, function(coef) {
    stats::as.formula(paste0('sd(id, coef = "', coef, '") ~ w'),
                      env = globalenv())
  })
  fit <- drmTMB(do.call(bf, c(list(main, sigma ~ 1), sd_formulas)),
                family = stats::gaussian(), data = fx$data,
                control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L)
  fit
}

# Hand-built pieces from fitted coefficients and corpars.
g34ms_hand_sd <- function(fit, fx, modelled = c("(Intercept)", "x")) {
  label <- paste0("(", paste(sub("(Intercept)", "1", fx$coef_names,
                                 fixed = TRUE), collapse = " + "), " | id)")
  out <- matrix(NA_real_, length(fx$w_group), fx$q)
  for (k in seq_len(fx$q)) {
    cf <- fx$coef_names[[k]]
    out[, k] <- if (cf %in% modelled) {
      a <- coef(fit, paste0('sd(id, coef = "', cf, '")'))
      exp(a[[1L]] + a[[2L]] * fx$w_group)
    } else {
      rep(unname(fit$sdpars$mu[[paste0(label, ":", cf)]]), length(fx$w_group))
    }
  }
  out
}

g34ms_hand_cor <- function(fit, fx) {
  out <- diag(fx$q)
  values <- fit$corpars$re_cov
  for (nm in names(values)) {
    inner <- sub("^cor\\((.*) \\| id\\)$", "\\1", nm)
    parts <- strsplit(inner, ",", fixed = TRUE)[[1L]]
    i <- match(parts[[1L]], fx$coef_names)
    j <- match(parts[[2L]], fx$coef_names)
    out[i, j] <- out[j, i] <- unname(values[[nm]])
  }
  out
}

# OLS group coefficients of y - X beta for every replicate: q x nsim per group.
g34ms_group_ols <- function(sims, fit, fx) {
  data <- fx$data
  xb <- drop(stats::model.matrix(~ x + z, data) %*% coef(fit, "mu"))
  resid <- as.matrix(sims) - xb
  lapply(levels(data$id), function(g) {
    rows <- which(data$id == g)
    zg <- cbind(1, as.matrix(data[rows, fx$covariates, drop = FALSE]))
    list(
      zz_inv = solve(crossprod(zg)),
      b_hat = solve(crossprod(zg), crossprod(zg, resid[rows, , drop = FALSE]))
    )
  })
}

# Standardised errors z_ij (all groups, entries i <= j) of the empirical
# covariance of b_hat against S_g + sigma^2 (Z'Z)^-1 built from `sd_matrix` and
# `correlation`; also the standardised means of b_hat.
g34ms_scores <- function(ols, sd_matrix, correlation, sigma, nsim) {
  q <- nrow(correlation)
  upper <- which(upper.tri(correlation, diag = TRUE), arr.ind = TRUE)
  z_cov <- numeric(0)
  z_mean <- numeric(0)
  for (g in seq_along(ols)) {
    d <- diag(sd_matrix[g, ], q)
    target <- d %*% correlation %*% d + sigma^2 * ols[[g]]$zz_inv
    emp <- stats::cov(t(ols[[g]]$b_hat))
    se <- sqrt((target^2 + outer(diag(target), diag(target))) / (nsim - 1L))
    z_cov <- c(z_cov, ((emp - target) / se)[upper])
    z_mean <- c(z_mean, rowMeans(ols[[g]]$b_hat) / sqrt(diag(target) / nsim))
  }
  list(z_cov = z_cov, z_mean = z_mean)
}

g34ms_nsim <- 4000L
g34ms_z_max <- 4.5
g34ms_z2_range <- c(0.65, 1.35)

g34ms_check_q <- function(q) {
  fx <- g34ms_fixture(q = q)
  fit <- g34ms_fit(fx)
  sims <- simulate(fit, nsim = g34ms_nsim, seed = 20261102L, re.form = NA)
  expect_equal(dim(sims), c(nrow(fx$data), g34ms_nsim))

  sd_hand <- g34ms_hand_sd(fit, fx)
  cor_hand <- g34ms_hand_cor(fit, fx)
  sigma_hat <- exp(unname(coef(fit, "sigma")[[1L]]))
  # The hand-built SDs agree with the package's per-group SDs (a check on the
  # test's own reconstruction, not on the sampler).
  expect_equal(unname(sd_hand[, 1L]),
               unname(fit$sdpars[['sd(id, coef = "(Intercept)")']]),
               tolerance = 1e-8)
  expect_equal(unname(sd_hand[, 2L]),
               unname(fit$sdpars[['sd(id, coef = "x")']]),
               tolerance = 1e-8)

  ols <- g34ms_group_ols(sims, fit, fx)
  good <- g34ms_scores(ols, sd_hand, cor_hand, sigma_hat, g34ms_nsim)
  n_entries <- length(ols) * q * (q + 1L) / 2L
  expect_length(good$z_cov, n_entries)
  expect_lte(max(abs(good$z_cov)), g34ms_z_max)
  expect_gte(mean(good$z_cov^2), g34ms_z2_range[[1L]])
  expect_lte(mean(good$z_cov^2), g34ms_z2_range[[2L]])
  expect_lte(max(abs(good$z_mean)), g34ms_z_max)

  # Emulated bug 1: R = I (correlation dropped from the draw).
  no_cor <- g34ms_scores(ols, sd_hand, diag(q), sigma_hat, g34ms_nsim)
  expect_gt(max(abs(no_cor$z_cov)), g34ms_z_max)
  expect_gt(mean(no_cor$z_cov^2), g34ms_z2_range[[2L]])
  # Emulated bug 2: SD vector reversed in coefficient order.
  rev_sd <- g34ms_scores(ols, sd_hand[, rev(seq_len(q))], cor_hand,
                         sigma_hat, g34ms_nsim)
  expect_gt(max(abs(rev_sd$z_cov)), g34ms_z_max)
  expect_gt(mean(rev_sd$z_cov^2), g34ms_z2_range[[2L]])
  invisible(list(fit = fit, good = good, no_cor = no_cor, rev_sd = rev_sd))
}

test_that("Gaussian q3 marginal simulation draws covariance D_g R D_g", {
  skip_on_cran()
  g34ms_check_q(3L)
})

test_that("Gaussian q4 marginal simulation draws covariance D_g R D_g", {
  skip_on_cran()
  g34ms_check_q(4L)
})

test_that("Gaussian q3 marginal simulation is seed-reproducible", {
  fx <- g34ms_fixture(q = 3L)
  fit <- g34ms_fit(fx)
  a <- simulate(fit, nsim = 3L, seed = 11L, re.form = NA)
  b <- simulate(fit, nsim = 3L, seed = 11L, re.form = NA)
  d <- simulate(fit, nsim = 3L, seed = 12L, re.form = NA)
  expect_identical(a, b)
  expect_false(isTRUE(all.equal(a, d)))
  # The default is the marginal draw, and the replicates differ.
  expect_identical(a, simulate(fit, nsim = 3L, seed = 11L))
  expect_gt(max(abs(a[[1L]] - a[[2L]])), 0)
  # Conditional simulation is unchanged and still available.
  cond <- simulate(fit, nsim = 2L, seed = 11L, re.form = NULL)
  expect_equal(dim(cond), c(nrow(fx$data), 2L))
})

test_that("Plain q3 blocks without sd() formulas keep the marginal refusal", {
  fx <- g34ms_fixture(q = 3L)
  plain <- drmTMB(
    bf(y ~ x + z + (1 + x + z | id), sigma ~ 1),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_error(
    simulate(plain, nsim = 1L, seed = 1L, re.form = NA),
    "does not yet support"
  )
  expect_equal(
    dim(simulate(plain, nsim = 1L, seed = 1L, re.form = NULL)),
    c(nrow(fx$data), 1L)
  )
})
