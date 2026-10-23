# Wave B1 (Dinnage audit arc 3): check.R rows and conf.status
# (#1319 Md-B, #1356 UX-1, #1337 A-7, #1342 Mi-4, #1333 A-3, #1327 Md-J).

wave4b1_rank_deficient_gaussian <- function(seed = 1319L) {
  set.seed(seed)
  n <- 50L
  x1 <- stats::rnorm(n)
  data.frame(
    y = stats::rnorm(n),
    x1 = x1,
    x2 = x1 + stats::rnorm(n, 0, 1e-6),
    x3 = 2 * x1 + stats::rnorm(n, 0, 1e-6)
  )
}

wave4b1_collinear_design <- function(r = 0.99995, n = 120L, seed = 1342L) {
  set.seed(seed)
  x1 <- stats::rnorm(n)
  x2 <- r * x1 + sqrt(1 - r^2) * stats::rnorm(n)
  data.frame(y = stats::rnorm(n) + 0.1 * x1, x1 = x1, x2 = x2)
}

wave4b1_pure_noise_scale_submodel <- function(n, seed = 1337L) {
  set.seed(seed)
  x1 <- stats::rnorm(n)
  x2 <- stats::rnorm(n)
  x3 <- stats::rnorm(n)
  z1 <- stats::rnorm(n)
  z2 <- stats::rnorm(n)
  data.frame(
    y = stats::rnorm(n),
    x1 = x1,
    x2 = x2,
    x3 = x3,
    z1 = z1,
    z2 = z2
  )
}

wave4b1_spatial_mu_fit <- function() {
  set.seed(20260916)
  levels <- paste0("site", seq_len(8L))
  theta <- seq(0, 1.6 * pi, length.out = 8L)
  coords <- data.frame(
    x = cos(theta) + seq_len(8L) / 32,
    y = sin(theta)
  )
  rownames(coords) <- levels
  site <- rep(levels, each = 6L)
  x <- stats::rnorm(length(site))
  site_effect <- stats::rnorm(8L, 0, 0.5)
  names(site_effect) <- levels
  y <- 0.5 + 0.3 * x + site_effect[site] + stats::rnorm(length(site), 0, 0.6)
  fit <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ 1),
    family = gaussian(),
    data = data.frame(y = y, x = x, site = site),
    control = drm_control(keep_tmb_object = TRUE)
  )
  list(
    fit = fit,
    parm = "sd:mu:spatial(1 | site)"
  )
}

test_that("Md-B: SE-inflation ratio uses a non-flagged median reference (Dinnage audit)", {
  # When every finite SE is pathological, the old median-over-all rule left
  # n_inflated=0 despite max SE orders of magnitude above a well-scaled slope.
  dat <- wave4b1_rank_deficient_gaussian()
  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ x1 + x2 + x3, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(keep_tmb_object = TRUE)
  ))
  chk <- check_drm(fit)
  row <- chk[chk$check == "standard_errors_inflated", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "note")
  expect_match(row$value, "n_inflated=[1-9]")
  expect_match(row$value, "reference_median=")
})

test_that("UX-1: subset drm_check print reports X of N checks shown (Dinnage audit)", {
  dat <- data.frame(y = stats::rnorm(40), x = stats::rnorm(40))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  chk <- check_drm(fit)
  n_total <- nrow(chk)
  sub <- chk[chk$status != "ok", , drop = FALSE]
  expect_s3_class(sub, "drm_check")
  banner <- utils::capture.output(print(sub))[1L]
  expect_match(banner, paste0("0 of ", n_total, " checks shown"))
})

test_that("A-7: low observations-per-parameter ratio adds a check_drm note (Dinnage audit)", {
  fit_small <- drmTMB(
    bf(y ~ x1 + x2 + x3, sigma ~ z1 + z2),
    family = gaussian(),
    data = wave4b1_pure_noise_scale_submodel(60L),
    control = drm_control(keep_tmb_object = TRUE)
  )
  fit_large <- drmTMB(
    bf(y ~ x1 + x2 + x3, sigma ~ z1 + z2),
    family = gaussian(),
    data = wave4b1_pure_noise_scale_submodel(200L, seed = 1338L),
    control = drm_control(keep_tmb_object = TRUE)
  )
  chk_small <- check_drm(fit_small)
  chk_large <- check_drm(fit_large)
  row_small <- chk_small[chk_small$check == "observations_per_parameter", ]
  row_large <- chk_large[chk_large$check == "observations_per_parameter", ]
  expect_equal(nrow(row_small), 1L)
  expect_equal(row_small$status, "note")
  expect_equal(row_large$status, "ok")
})

test_that("Mi-4: near-collinear fixed-effect design columns add a note (Dinnage audit)", {
  dat <- wave4b1_collinear_design()
  expect_gt(abs(stats::cor(dat$x1, dat$x2)), 0.9999)
  fit <- drmTMB(
    bf(y ~ x1 + x2, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(keep_tmb_object = TRUE)
  )
  chk <- check_drm(fit)
  row <- chk[chk$check == "fixed_effect_collinearity", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "note")
  expect_match(row$value, "max_abs_r=")
})

test_that("A-3: convergence_status and multi_start cannot clear a degenerate fit (Dinnage audit)", {
  dat <- wave4b1_rank_deficient_gaussian(seed = 1333L)
  fit_one <- allow_nonconvergence(drmTMB(
    bf(y ~ x1 + x2 + x3, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(keep_tmb_object = TRUE, multi_start = 1L)
  ))
  fit_many <- allow_nonconvergence(drmTMB(
    bf(y ~ x1 + x2 + x3, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(keep_tmb_object = TRUE, multi_start = 3L)
  ))

  expect_false(attr(check_drm(fit_one), "ok"))
  expect_false(attr(check_drm(fit_many), "ok"))
  expect_equal(convergence_status(fit_one), "degenerate")
  expect_equal(convergence_status(fit_many), "degenerate")
  expect_false(is_converged(fit_one))
  expect_false(is_converged(fit_many))

  chk_many <- check_drm(fit_many)
  status_row <- chk_many[chk_many$check == "convergence_status", ]
  expect_equal(nrow(status_row), 1L)
  expect_equal(status_row$status, "note")
  expect_match(status_row$value, "degenerate")
})

test_that("Md-J: bias-corrected Wald intervals record wald_bias_corrected (Dinnage audit)", {
  obj <- wave4b1_spatial_mu_fit()
  ci <- stats::confint(
    obj$fit,
    parm = obj$parm,
    method = "wald"
  )
  expect_equal(unique(ci$conf.status), "wald_bias_corrected")
})
