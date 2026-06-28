# The small-sample correction (t(g-1) width + log(g/(g-1)) centre shift) is the
# DEFAULT for LOCATION-axis (mu) structured-RE SD targets in confint(method =
# "wald"). It must stay OFF by default for dispersion (sigma) structured SD
# targets (they over-cover under the normal quantile) and for every
# non-structured target. `small_sample_df = "none"` / `bias_correct = "none"`
# is the opt-out that recovers the raw z-interval for all targets;
# `*_correct = "group"` widens/shifts both axes.
#
# A Gaussian spatial(...) fit is used because it resolves a structured group
# count `g` (= number of sites) without requiring an `ape` phylogeny at fit time.

wald_small_sample_spatial_data <- function(
  seed = 20260627,
  n_level = 8L,
  n_each = 6L
) {
  set.seed(seed)
  levels <- paste0("site", seq_len(n_level))
  theta <- seq(0, 1.6 * pi, length.out = n_level)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_level) / (4 * n_level),
    y = sin(theta)
  )
  rownames(coords) <- levels
  site <- rep(levels, each = n_each)
  x <- stats::rnorm(length(site))
  site_effect <- stats::rnorm(n_level, 0, 0.5)
  names(site_effect) <- levels
  y <- 0.5 +
    0.3 * x +
    site_effect[site] +
    stats::rnorm(length(site), 0, 0.6)
  list(
    data = data.frame(y = y, x = x, site = site),
    coords = coords,
    g = n_level
  )
}

wald_small_sample_mu_fit <- function() {
  sim <- wald_small_sample_spatial_data()
  coords <- sim$coords
  fit <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ 1),
    family = gaussian(),
    data = sim$data,
    control = drm_control(keep_tmb_object = TRUE)
  )
  list(fit = fit, g = sim$g, parm = "sd:mu:spatial(1 | site)")
}

# Recover (log-scale estimate, log-scale se) from a raw z-interval so the test
# can reconstruct the expected corrected and uncorrected endpoints
# independently of the implementation under test.
wald_small_sample_eta_se <- function(row, level = 0.95) {
  z <- stats::qnorm((1 + level) / 2)
  lo <- log(row$lower)
  hi <- log(row$upper)
  c(eta = (lo + hi) / 2, se = (hi - lo) / (2 * z))
}

test_that("location-axis structured SD is corrected by the wald DEFAULT", {
  obj <- wald_small_sample_mu_fit()
  g <- obj$g
  level <- 0.95
  p <- (1 + level) / 2
  shift <- log(g / (g - 1))
  tq <- stats::qt(p, g - 1)

  raw <- drmTMB:::drm_wald_confint(
    obj$fit,
    parm = obj$parm,
    level = level,
    small_sample_df = "none",
    bias_correct = "none"
  )
  es <- wald_small_sample_eta_se(raw, level)

  default <- drmTMB:::drm_wald_confint(obj$fit, parm = obj$parm, level = level)
  expected_lower <- exp((es[["eta"]] + shift) - tq * es[["se"]])
  expected_upper <- exp((es[["eta"]] + shift) + tq * es[["se"]])

  expect_equal(default$lower, expected_lower, tolerance = 1e-9)
  expect_equal(default$upper, expected_upper, tolerance = 1e-9)
  # The default genuinely moves the interval away from the raw z-interval.
  expect_false(isTRUE(all.equal(default$lower, raw$lower)))
})

test_that("dispersion-axis structured SD keeps the raw z-interval by default", {
  sim <- wald_small_sample_spatial_data()
  coords <- sim$coords
  fit <- drmTMB(
    bf(y ~ x, sigma ~ spatial(1 | site, coords = coords)),
    family = gaussian(),
    data = sim$data,
    control = drm_control(keep_tmb_object = TRUE)
  )
  parm <- "sd:sigma:spatial(1 | site)"

  # The sigma SD can land near the lower boundary; the boundary warning is
  # orthogonal to this test (it fires identically in both modes).
  default <- suppressWarnings(
    drmTMB:::drm_wald_confint(fit, parm = parm, level = 0.95)
  )
  raw <- suppressWarnings(drmTMB:::drm_wald_confint(
    fit,
    parm = parm,
    level = 0.95,
    small_sample_df = "none",
    bias_correct = "none"
  ))

  # sigma structured SD: default == none, byte-identical.
  expect_identical(default$lower, raw$lower)
  expect_identical(default$upper, raw$upper)
})

test_that("opt-out (none) recovers the raw z-interval for a location-axis SD", {
  obj <- wald_small_sample_mu_fit()
  level <- 0.95
  z <- stats::qnorm((1 + level) / 2)

  raw <- drmTMB:::drm_wald_confint(
    obj$fit,
    parm = obj$parm,
    level = level,
    small_sample_df = "none",
    bias_correct = "none"
  )
  es <- wald_small_sample_eta_se(raw, level)

  expect_equal(raw$lower, exp(es[["eta"]] - z * es[["se"]]), tolerance = 1e-9)
  expect_equal(raw$upper, exp(es[["eta"]] + z * es[["se"]]), tolerance = 1e-9)
})

test_that("group widens and shifts both location and dispersion structured SDs", {
  sim <- wald_small_sample_spatial_data()
  coords <- sim$coords
  fit <- drmTMB(
    bf(
      y ~ x + spatial(1 | site, coords = coords),
      sigma ~ spatial(1 | site, coords = coords)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(keep_tmb_object = TRUE)
  )
  g <- sim$g
  level <- 0.95
  p <- (1 + level) / 2
  shift <- log(g / (g - 1))
  tq <- stats::qt(p, g - 1)

  mu_parm <- "sd:mu:mu:spatial(1 | site)"
  sigma_parm <- "sd:sigma:sigma:spatial(1 | site)"

  raw <- drmTMB:::drm_wald_confint(
    fit,
    parm = c(mu_parm, sigma_parm),
    level = level,
    small_sample_df = "none",
    bias_correct = "none"
  )
  grp <- drmTMB:::drm_wald_confint(
    fit,
    parm = c(mu_parm, sigma_parm),
    level = level,
    small_sample_df = "group",
    bias_correct = "group"
  )

  for (parm in c(mu_parm, sigma_parm)) {
    es <- wald_small_sample_eta_se(raw[raw$parm == parm, ], level)
    g_row <- grp[grp$parm == parm, ]
    expect_equal(
      g_row$lower,
      exp((es[["eta"]] + shift) - tq * es[["se"]]),
      tolerance = 1e-9
    )
    expect_equal(
      g_row$upper,
      exp((es[["eta"]] + shift) + tq * es[["se"]]),
      tolerance = 1e-9
    )
  }
})

test_that("non-structured targets are byte-identical across all three modes", {
  set.seed(20260628)
  n_id <- 12L
  n <- n_id * 6L
  u <- stats::rnorm(n_id, 0, 0.8)
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = 6L)),
    x = stats::rnorm(n)
  )
  dat$y <- 0.5 + 0.4 * dat$x + u[dat$id] + stats::rnorm(n, 0, 0.5)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(keep_tmb_object = TRUE)
  )

  default <- drmTMB:::drm_wald_confint(fit, parm = NULL, level = 0.95)
  none <- drmTMB:::drm_wald_confint(
    fit,
    parm = NULL,
    level = 0.95,
    small_sample_df = "none",
    bias_correct = "none"
  )
  group <- drmTMB:::drm_wald_confint(
    fit,
    parm = NULL,
    level = 0.95,
    small_sample_df = "group",
    bias_correct = "group"
  )

  # No structured block: nothing resolves g, so every mode is byte-identical for
  # the plain (1|id) SD, the fixed effects, and the residual sigma scale.
  expect_identical(default$lower, none$lower)
  expect_identical(default$upper, none$upper)
  expect_identical(group$lower, none$lower)
  expect_identical(group$upper, none$upper)
})
