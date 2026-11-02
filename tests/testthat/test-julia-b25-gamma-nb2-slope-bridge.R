# Batch 25 R-bridge admissions (DRM.jl 53b992349, 2ffbbcb5a):
#   (1) Gamma relmat slope-only SD (raw K, non-unit diagonal);
#   (2) Gamma coordinate spatial slope-only SD (native fixed kernel, sent as K);
#   (3) NB2 relmat slope-only SD (raw K, non-unit diagonal).
# Gamma phylogenetic slope-only SD is NOT admitted: DRM.jl uses the raw tree
# covariance, native uses the correlation matrix, and Gamma phylogenetic SD is
# not marshalled by the bridge.
# Tolerances were fixed before the live runs: coefficients (every block)
# within 1e-3 absolute, logLik within 1e-2 absolute, native TMB (se = FALSE)
# as the comparator on the same fixture. One fixture per route; no SE,
# coverage or broad parity claim.

b25_compare <- function(julia, native, dpars, tol_coef = 1e-3, tol_ll = 1e-2) {
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
    "B25 diffs: ",
    paste(names(diffs), signif(unlist(diffs), 3), collapse = "; "),
    "; logLik diff ", signif(ll, 3)
  )
  invisible(list(coef = diffs, ll = ll))
}

b25_live_setup <- function(.local_envir = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path, .local_envir = .local_envir)
  drm_test_local_julia_home(.local_envir = .local_envir)
}

b25_small_data <- function() {
  id_levels <- paste0("id", 1:4)
  K <- diag(4L)
  dimnames(K) <- list(id_levels, id_levels)
  coords <- cbind(east = 1:4, north = c(0, 1, 0, -1))
  rownames(coords) <- id_levels
  data <- data.frame(
    id = factor(rep(id_levels, each = 2L), levels = id_levels),
    x = rep(c(-1, 1), 4L),
    z = rep(c(-1, 1), each = 4L),
    y = c(0.4, 1.2, 0.8, 0.5, 1.1, 0.7, 0.9, 1.3)
  )
  list(K = K, coords = coords, data = data)
}

test_that("Gamma and NB2 slope-only SD gates admit only their shapes", {
  s <- b25_small_data()
  K <- s$K
  coords <- s$coords
  relmat <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  spatial <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  expect_true(drm_julia_gamma_relmat_sd_slope_route_admitted(relmat))
  expect_true(drm_julia_nbinom2_relmat_sd_slope_route_admitted(relmat))
  expect_true(drm_julia_gamma_spatial_sd_slope_route_admitted(spatial))
  expect_no_error(drm_julia_refuse_marker_slope_unsupported(relmat, "gamma"))
  expect_no_error(drm_julia_refuse_marker_slope_unsupported(relmat, "nbinom2"))
  expect_no_error(drm_julia_refuse_marker_slope_unsupported(spatial, "gamma"))

  # Raw K goes to Julia untouched, including a non-unit diagonal (no refusal).
  K_scaled <- K
  K_scaled[1L, 1L] <- 1.5
  scaled <- bf(
    y ~ x + relmat(0 + x | id, K = K_scaled),
    sd(id, level = "relmat") ~ z
  )
  gp <- drm_julia_structured_payload(scaled, "gamma", s$data, environment())
  expect_identical(gp$kwarg, "K")
  expect_identical(gp$formula[[2L]], "sd(id, relmat) ~ z")
  expect_equal(unname(gp$matrix), unname(K_scaled))
  expect_true("sd" %in% names(gp$coef_labels))
  np <- drm_julia_structured_payload(scaled, "nbinom2", s$data, environment())
  expect_equal(unname(np$matrix), unname(K_scaled))
  sp <- drm_julia_structured_payload(spatial, "gamma", s$data, environment())
  expect_identical(sp$kwarg, "K")  # native coordinate kernel sent as a covariance
  expect_identical(sp$formula[[2L]], "sd(id, relmat) ~ z")

  # Shapes and families that stay refused.
  intercept <- bf(
    y ~ x + relmat(1 | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  intercept_slope <- bf(
    y ~ x + relmat(1 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  spatial_intercept <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  expect_error(
    drm_julia_refuse_marker_slope_unsupported(intercept_slope, "gamma"),
    "random slope"
  )
  expect_false(drm_julia_gamma_spatial_sd_slope_route_admitted(spatial_intercept))
  expect_error(
    drm_julia_structured_payload(
      spatial_intercept, "gamma", s$data, environment()
    ),
    "spatial"
  )
  # NB2 spatial slope has no Julia route.
  expect_error(
    drm_julia_structured_payload(spatial, "nbinom2", s$data, environment()),
    "spatial"
  )
  tr <- ape::rtree(4L, tip.label = levels(s$data$id))
  phylo <- bf(
    y ~ x + phylo(0 + x | id, tree = tr),
    sd(id, level = "phylogenetic") ~ z
  )
  expect_error(
    drm_julia_refuse_marker_slope_unsupported(phylo, "gamma"),
    "random slope"
  )
})

b25_relmat_fixture <- function(seed, n_group, n_each) {
  set.seed(seed)
  id_levels <- paste0("g", seq_len(n_group))
  marginal_scale <- seq(0.7, 1.6, length.out = n_group)
  correlation <- outer(seq_len(n_group), seq_len(n_group), function(i, j) {
    0.4^abs(i - j)
  })
  K <- outer(marginal_scale, marginal_scale) * correlation
  dimnames(K) <- list(id_levels, id_levels)
  stopifnot(max(abs(diag(K) - 1)) > 0.5)
  z_group <- rep(c(-1, 1), length.out = n_group)
  u <- exp(-0.6 + 0.5 * z_group) * as.vector(t(chol(K)) %*% stats::rnorm(n_group))
  id_index <- rep(seq_len(n_group), each = n_each)
  x <- stats::rnorm(n_group * n_each)
  dat <- data.frame(
    id = factor(id_levels[id_index], levels = id_levels),
    x = x, z = z_group[id_index]
  )
  list(K = K, dat = dat, random = x * u[id_index], x = x)
}

test_that("Gamma relmat slope SD agrees across engines (non-unit K)", {
  b25_live_setup()
  fx <- b25_relmat_fixture(20261105L, 40L, 16L)
  K <- fx$K
  dat <- fx$dat
  shape <- 1 / 0.35^2
  mu <- exp(0.3 + 0.2 * fx$x + fx$random)
  dat$y <- stats::rgamma(nrow(dat), shape = shape, rate = shape / mu)
  form <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  native <- drmTMB(form, family = Gamma(link = "log"), data = dat,
                   engine = "tmb", control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = Gamma(link = "log"), data = dat,
                  engine = "julia")
  b25_compare(julia, native, c("mu", "sigma", "sd_relmat(id)"))
})

test_that("Gamma coordinate spatial slope SD agrees across engines", {
  b25_live_setup()
  set.seed(20261106L)
  n_group <- 40L
  n_each <- 16L
  id_levels <- paste0("s", seq_len(n_group))
  coords <- cbind(east = stats::rnorm(n_group), north = stats::rnorm(n_group))
  rownames(coords) <- id_levels
  distance <- as.matrix(stats::dist(coords))
  range <- stats::median(distance[upper.tri(distance)])
  C <- exp(-distance / range) + 1e-6 * diag(n_group)
  z_group <- rep(c(-1, 1), length.out = n_group)
  u <- exp(-0.6 + 0.5 * z_group) * as.vector(t(chol(C)) %*% stats::rnorm(n_group))
  id_index <- sample(rep(seq_len(n_group), each = n_each))
  x <- stats::rnorm(length(id_index))
  dat <- data.frame(
    id = factor(id_levels[id_index], levels = id_levels),
    x = x, z = z_group[id_index]
  )
  shape <- 1 / 0.35^2
  mu <- exp(0.3 + 0.2 * x + x * u[id_index])
  dat$y <- stats::rgamma(nrow(dat), shape = shape, rate = shape / mu)
  expect_false(identical(unique(as.character(dat$id)), id_levels))
  form <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  native <- drmTMB(form, family = Gamma(link = "log"), data = dat,
                   engine = "tmb", control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = Gamma(link = "log"), data = dat,
                  engine = "julia")
  b25_compare(julia, native, c("mu", "sigma", "sd_spatial(id)"))
})

test_that("NB2 relmat slope SD agrees across engines (non-unit K)", {
  b25_live_setup()
  fx <- b25_relmat_fixture(20261107L, 40L, 20L)
  K <- fx$K
  dat <- fx$dat
  size <- 1 / 0.42^2
  mu <- exp(0.3 + 0.25 * fx$x + fx$random)
  dat$y <- stats::rnbinom(nrow(dat), size = size, mu = mu)
  form <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  native <- drmTMB(form, family = nbinom2(), data = dat, engine = "tmb",
                   control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = nbinom2(), data = dat, engine = "julia")
  b25_compare(julia, native, c("mu", "sigma", "sd_relmat(id)"))
})
