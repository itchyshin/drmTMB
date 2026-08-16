# Design 256 S2 — experimental boundary soft-penalty on the Gaussian A1 cell.
# Surface: penalty = drm_boundary_penalty(), estimator labeled MAP, confint withheld.

test_that("drm_boundary_penalty validates inputs and reports the rate formula", {
  p <- drm_boundary_penalty()
  expect_s3_class(p, "drm_boundary_penalty")
  expect_equal(p$kappa_minus, 1)
  expect_equal(p$kappa_plus, 1)
  expect_equal(p$q_v, 1L)
  expect_identical(p$c_g_formula, "2 * sqrt(q_v / g)")
  expect_true(isTRUE(p$experimental))

  p2 <- drm_boundary_penalty(kappa_minus = 2, kappa_plus = 0.25)
  expect_equal(p2$kappa_minus, 2)
  expect_equal(p2$kappa_plus, 0.25)

  expect_error(drm_boundary_penalty(kappa_minus = 0), "kappa_minus")
  expect_error(drm_boundary_penalty(kappa_plus = -1), "kappa_plus")
})

test_that("drm_boundary_c_g and I_g closed form match design 256", {
  expect_equal(drm_boundary_c_g(1L, 10L), 2 / sqrt(10), tolerance = 1e-12)

  # D-117 A1 cell table in design 256 §5.3 (g=10, m=4, sigma=0.7).
  ig <- drm_boundary_I_g_log_sd(g = 10, m = 4, sigma = 0.7, sigma_u = 1.0)
  expect_equal(ig, 15.81, tolerance = 5e-3)
  expect_lt(ig, 2 * 10)

  # Proposition 2: I_g < 2g uniformly.
  grid <- expand.grid(
    g = c(5, 10, 25),
    m = c(2, 4, 10),
    sigma = c(0.7, 2.1),
    sigma_u = c(0.25, 1, 4)
  )
  for (i in seq_len(nrow(grid))) {
    ig_i <- drm_boundary_I_g_log_sd(
      grid$g[[i]], grid$m[[i]], grid$sigma[[i]], grid$sigma_u[[i]]
    )
    expect_lt(ig_i, 2 * grid$g[[i]])
    expect_gte(ig_i, 0)
  }
})

test_that("equivariance-weight classifier fails loudly off the A1 cell", {
  expect_equal(
    drm_boundary_equivariance_weight("gaussian")$anchor,
    "mean_eta_sigma"
  )
  expect_error(
    drm_boundary_equivariance_weight("binomial"),
    class = "drm_boundary_equivariance_unclassified"
  )
  expect_error(
    drm_boundary_equivariance_weight(
      "gaussian",
      family = list(link = "log")
    ),
    class = "drm_boundary_equivariance_unclassified"
  )
})

a1_fixture <- function(seed = 20260816L, scale = 1) {
  set.seed(seed)
  g <- factor(rep(1:10, each = 4))
  x <- rnorm(length(g))
  u <- rnorm(10, 0, 0.5)
  y <- scale * (1 + 0.5 * x + u[as.integer(g)] + rnorm(length(g), 0, 0.7))
  data.frame(y = y, x = x, g = g)
}

test_that("boundary penalty admits A1, labels MAP, and withholds confint", {
  skip_on_cran()
  dat <- a1_fixture()
  form <- bf(y ~ x + (1 | g), sigma ~ 1)

  fit_ml <- drmTMB(form, data = dat, family = gaussian())
  fit_map <- drmTMB(
    form,
    data = dat,
    family = gaussian(),
    penalty = drm_boundary_penalty()
  )

  expect_equal(fit_ml$estimator, "ML")
  expect_equal(fit_map$estimator, "MAP")
  expect_s3_class(fit_map$penalty, "drm_boundary_penalty")
  expect_gt(fit_map$boundary_penalty, 0)
  expect_equal(
    fit_map$boundary_penalty_meta$c_g,
    drm_boundary_c_g(1L, 10L),
    tolerance = 1e-12
  )

  # Unpenalized logLik recovers as -objective + boundary nll contribution.
  expect_equal(
    as.numeric(fit_map$logLik),
    -fit_map$opt$objective + fit_map$boundary_penalty,
    tolerance = 1e-6
  )

  expect_error(
    confint(fit_map, parm = "sd:mu:(1 | g)"),
    class = "drmTMB_boundary_penalty_inference_unsupported"
  )
  expect_error(
    profile(fit_map, parm = "sd:mu:(1 | g)"),
    class = "drmTMB_boundary_penalty_inference_unsupported"
  )
})

test_that("boundary penalty rejects off-cell requests", {
  skip_on_cran()
  dat <- a1_fixture()

  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      family = gaussian(),
      penalty = drm_boundary_penalty()
    ),
    "exactly one ordinary"
  )

  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | g), sigma ~ 1),
      data = dat,
      family = gaussian(),
      penalty = drm_boundary_penalty()
    ),
    "exactly one ordinary|intercept-only"
  )

  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g), sigma ~ 1),
      data = dat,
      family = gaussian(),
      REML = TRUE,
      penalty = drm_boundary_penalty()
    ),
    "cannot be combined"
  )

  # Singleton-group designs are refused (design 256 §4.3c).
  dat_m1 <- data.frame(
    y = rnorm(12),
    x = rnorm(12),
    g = factor(c(rep(1:4, each = 2), 5:8))
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g), sigma ~ 1),
      data = dat_m1,
      family = gaussian(),
      penalty = drm_boundary_penalty()
    ),
    class = "drm_boundary_singleton_group"
  )
})

test_that("S0-A regression: moving-anchor form is scale-equivariant", {
  skip_on_cran()
  # Tiny paired check of design 256 K1 / S0 Experiment A on the new form.
  # Full 200-rep campaign stays on Totoro; this asserts the repair direction.
  disc <- vapply(1:5, function(r) {
    d1 <- a1_fixture(seed = 20260816L + r, scale = 1)
    d2 <- a1_fixture(seed = 20260816L + r, scale = 100)
    form <- bf(y ~ x + (1 | g), sigma ~ 1)
    pen <- drm_boundary_penalty()
    s1 <- as.numeric(
      drmTMB(form, data = d1, family = gaussian(), penalty = pen)$sdpars$mu[[1L]]
    )
    s2 <- as.numeric(
      drmTMB(form, data = d2, family = gaussian(), penalty = pen)$sdpars$mu[[1L]]
    )
    abs(s1 - s2 / 100)
  }, numeric(1))

  # ML control on this fixture is ~1e-6; the shipped unit-anchor form failed at
  # O(0.01). Accept a generous optimiser-tolerance ceiling here.
  expect_lt(max(disc), 1e-4)
})
