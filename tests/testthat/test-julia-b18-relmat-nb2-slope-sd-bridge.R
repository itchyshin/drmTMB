# Batch 18 R-bridge admissions (DRM.jl f0566fb5b):
#   (1) Poisson relmat slope-only SD (K matrix);
#   (2) NB2 animal slope-only SD (raw, non-unit-diagonal A matrix).
# Tolerances were fixed before the live runs: coefficients (every block) within
# 1e-3 absolute, logLik within 1e-2 absolute, native TMB (se = FALSE) as the
# comparator on the same fixture. One fixture per route; no broad parity claim.

b18_fixture_data <- function(n_id, id_levels, x_n) {
  data.frame(
    id = factor(rep(id_levels, each = x_n), levels = id_levels),
    x = rep(seq(-1, 1, length.out = x_n), n_id)
  )
}

test_that("Poisson relmat slope-only SD gate admits only its shape", {
  id_levels <- paste0("id", 1:4)
  K <- diag(4L)
  dimnames(K) <- list(id_levels, id_levels)
  data <- data.frame(
    id = factor(rep(id_levels, each = 2L), levels = id_levels),
    x = rep(c(-1, 1), 4L),
    z = rep(c(-1, 1), each = 4L),
    y = c(0L, 1L, 2L, 0L, 1L, 3L, 0L, 1L)
  )
  slope <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  expect_true(drm_julia_poisson_relmat_sd_slope_route_admitted(slope))
  expect_identical(drm_julia_structured_family_tag("poisson", slope), "poisson")
  expect_no_error(drm_julia_refuse_marker_slope_unsupported(slope, "poisson"))
  payload <- drm_julia_structured_payload(slope, "poisson", data, environment())
  expect_identical(payload$formula[[2L]], "sd(id, relmat) ~ z")
  expect_equal(unname(payload$matrix), unname(K))
  expect_true("sd" %in% names(payload$coef_labels))

  # Family guard: the payload refuses the same shape for other count families.
  expect_error(
    drm_julia_structured_payload(slope, "student", data, environment()),
    "supports structured"
  )

  K_scaled <- K
  K_scaled[1L, 1L] <- 1.5
  scaled <- bf(
    y ~ x + relmat(0 + x | id, K = K_scaled),
    sd(id, level = "relmat") ~ z
  )
  # Batch 28: DRM.jl now uses relmat K as supplied (raw), as native does, so the
  # old unit-diagonal refusal is gone and a non-unit K is sent unchanged.
  expect_no_error(
    scaled_payload <- drm_julia_structured_payload(scaled, "poisson", data, environment())
  )
  expect_equal(unname(scaled_payload$matrix), unname(K_scaled))

  intercept <- bf(
    y ~ x + relmat(1 | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  intercept_slope <- bf(
    y ~ x + relmat(1 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  extra_iid <- bf(
    y ~ x + (1 | site) + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  expect_false(drm_julia_poisson_relmat_sd_slope_route_admitted(intercept))
  expect_false(drm_julia_poisson_relmat_sd_slope_route_admitted(intercept_slope))
  expect_false(drm_julia_poisson_relmat_sd_slope_route_admitted(extra_iid))
  expect_error(
    drm_julia_refuse_marker_slope_unsupported(intercept_slope, "poisson"),
    "random slope"
  )
})

test_that("NB2 animal slope-only SD gate admits only the A-matrix route", {
  A <- diag(4L)
  dimnames(A) <- list(paste0("id", 1:4), paste0("id", 1:4))
  data <- data.frame(
    y = c(0, 1, 2, 0, 1, 1, 0, 2),
    x = rep(c(-1, 1), 4),
    z = rep(c(-1, -1, 1, 1), each = 2),
    id = factor(rep(paste0("id", 1:4), each = 2))
  )
  with_sigma <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal") ~ z
  )
  without_sigma <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  expect_true(drm_julia_nbinom2_animal_sd_slope_route_admitted(with_sigma))
  expect_true(drm_julia_nbinom2_animal_sd_slope_route_admitted(without_sigma))
  expect_identical(
    drm_julia_structured_family_tag("nbinom2", with_sigma), "nbinom2"
  )
  expect_no_error(drm_julia_refuse_marker_slope_unsupported(with_sigma, "nbinom2"))
  payload <- drm_julia_structured_payload(
    with_sigma, "nbinom2", data, environment()
  )
  expect_identical(payload$kwarg, "A")
  expect_equal(unname(payload$matrix), unname(A))

  sigma_slope <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sigma ~ x,
    sd(id, level = "animal") ~ z
  )
  intercept_slope <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  expect_false(drm_julia_nbinom2_animal_sd_slope_route_admitted(sigma_slope))
  expect_false(drm_julia_nbinom2_animal_sd_slope_route_admitted(intercept_slope))

  # Ainv is not widened to NB2 from R.
  Ainv <- solve(A)
  dimnames(Ainv) <- dimnames(A)
  ainv_formula <- bf(
    y ~ x + animal(0 + x | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )
  expect_error(
    drm_julia_structured_payload(ainv_formula, "nbinom2", data, environment()),
    "admits animal"
  )
})

b18_compare <- function(julia, native, dpars, tol_coef = 1e-3, tol_ll = 1e-2) {
  expect_equal(native$opt$convergence, 0L)
  expect_equal(julia$opt$convergence, 0L)
  diffs <- list()
  for (dpar in dpars) {
    nc <- coef(native, dpar = dpar)
    jc <- coef(julia, dpar = dpar)
    expect_named(jc, names(nc))
    diffs[[dpar]] <- max(abs(unname(jc) - unname(nc)))
    expect_lt(diffs[[dpar]], tol_coef, label = paste("coef diff", dpar))
  }
  ll <- abs(as.numeric(logLik(julia)) - as.numeric(logLik(native)))
  expect_lt(ll, tol_ll, label = "logLik diff")
  message(
    "B18 diffs: ",
    paste(names(diffs), signif(unlist(diffs), 3), collapse = "; "),
    "; logLik diff ", signif(ll, 3),
    "; logLik native ", signif(as.numeric(logLik(native)), 8),
    " julia ", signif(as.numeric(logLik(julia)), 8)
  )
  invisible(list(coef = diffs, ll = ll))
}

test_that("Poisson relmat slope-only SD agrees across engines (one fixture)", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261101L)
  n_id <- 64L
  x_n <- 24L
  id_levels <- paste0("g", seq_len(n_id))
  corr <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.4^abs(i - j))
  K <- corr  # unit diagonal here; the non-unit case is covered in b28
  dimnames(K) <- list(id_levels, id_levels)
  dat <- b18_fixture_data(n_id, id_levels, x_n)
  z_group <- sample(rep(c(-1, 1), each = n_id / 2L))
  dat$z <- z_group[as.integer(dat$id)]
  alpha <- c(`(Intercept)` = log(0.55), z = 0.5)
  slope <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) *
    exp(alpha[[1L]] + alpha[[2L]] * z_group)
  dat$y <- stats::rpois(
    nrow(dat), exp(0.2 + 0.3 * dat$x + dat$x * slope[as.integer(dat$id)])
  )
  form <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  native <- drmTMB(form, family = stats::poisson(), data = dat,
                   engine = "tmb", control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = stats::poisson(), data = dat, engine = "julia")
  b18_compare(julia, native, c("mu", "sd_relmat(id)"))
})

test_that("NB2 animal slope-only SD agrees across engines (raw non-unit A)", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261101L)
  n_fam <- 16L
  n_off <- 4L
  sires <- sprintf("sire%02d", seq_len(n_fam))
  dams <- sprintf("dam%02d", seq_len(n_fam))
  offspring <- sprintf("off%03d", seq_len(n_fam * n_off))
  pedigree <- data.frame(
    id = c(sires, dams, offspring),
    dam = c(rep(NA_character_, 2L * n_fam), rep(dams, each = n_off)),
    sire = c(rep(NA_character_, 2L * n_fam), rep(sires, each = n_off)),
    stringsAsFactors = FALSE
  )
  A_full <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  n_id <- length(offspring)
  d <- seq(0.8, 1.5, length.out = n_id)
  A <- outer(d, d) * A_full[offspring, offspring, drop = FALSE]
  dimnames(A) <- list(offspring, offspring)
  expect_true(any(abs(diag(A) - 1) > 1e-6))  # non-unit diagonal: raw A
  x_n <- 20L
  dat <- b18_fixture_data(n_id, offspring, x_n)
  z_id <- rep(c(-0.5, 0.5), length.out = n_id)
  dat$z <- z_id[as.integer(dat$id)]
  alpha <- c(`(Intercept)` = log(0.35), z = 0.45)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_id)
  slope <- as.vector(t(chol(outer(tau, tau) * A + diag(1e-8, n_id))) %*%
    stats::rnorm(n_id))
  eta <- 1.1 + 0.2 * dat$x + dat$x * slope[as.integer(dat$id)]
  dat$y <- stats::rnbinom(nrow(dat), mu = exp(eta), size = 1 / 0.45^2)
  form <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal") ~ z
  )
  native <- drmTMB(form, family = nbinom2(), data = dat, engine = "tmb",
                   control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = nbinom2(), data = dat, engine = "julia")
  b18_compare(julia, native, c("mu", "sigma", "sd_animal(id)"))
})
