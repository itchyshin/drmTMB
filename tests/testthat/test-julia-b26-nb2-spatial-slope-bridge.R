# Batch 26 R-bridge admission (DRM.jl 87a371a66): NB2 coordinate spatial
# slope-only SD regression, spatial(0 + x | id, coords) with
# sd(id, level = "spatial") ~ z. As for Gamma (batch 25), the bridge sends the
# native fixed kernel exp(-d / median positive distance) + 1e-6 I as a raw relmat
# K, so Julia fits the NB2 relmat slope route. The first four blocks are
# non-live (shape gates, payload, refusal pins). The last block is the live
# native-vs-Julia parity check; it is skipped unless Julia and DRM_JL_PATH are
# available. Tolerances fixed beforehand: coefficients (every block) within 1e-3
# absolute, logLik within 1e-2 absolute, native TMB (se = FALSE) as comparator.
# One fixture; no SE, coverage or broad parity claim.

b26_small_data <- function() {
  id_levels <- paste0("id", 1:4)
  K <- diag(4L)
  dimnames(K) <- list(id_levels, id_levels)
  coords <- cbind(east = 1:4, north = c(0, 1, 0, -1))
  rownames(coords) <- id_levels
  data <- data.frame(
    id = factor(rep(id_levels, each = 2L), levels = id_levels),
    x = rep(c(-1, 1), 4L),
    z = rep(c(-1, 1), each = 4L),
    y = c(0L, 3L, 1L, 2L, 4L, 0L, 2L, 5L)
  )
  list(K = K, coords = coords, data = data)
}

test_that("NB2 spatial slope-only SD gate admits only its shape", {
  s <- b26_small_data()
  coords <- s$coords
  K <- s$K
  spatial <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  expect_true(drm_julia_nbinom2_spatial_sd_slope_route_admitted(spatial))
  expect_true(drm_julia_nbinom2_structured_sd_slope_route_admitted(spatial))
  expect_no_error(drm_julia_refuse_marker_slope_unsupported(spatial, "nbinom2"))

  spatial_intercept <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  spatial_no_sd <- bf(y ~ x + spatial(0 + x | id, coords = coords))
  relmat <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  expect_false(drm_julia_nbinom2_spatial_sd_slope_route_admitted(spatial_intercept))
  expect_false(drm_julia_nbinom2_spatial_sd_slope_route_admitted(spatial_no_sd))
  expect_false(drm_julia_nbinom2_spatial_sd_slope_route_admitted(relmat))
  # The relmat route stays admitted through the combined gate.
  expect_true(drm_julia_nbinom2_structured_sd_slope_route_admitted(relmat))
})

test_that("NB2 spatial slope payload sends the native kernel as a raw relmat K", {
  s <- b26_small_data()
  coords <- s$coords
  spatial <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  p <- drm_julia_structured_payload(spatial, "nbinom2", s$data, environment())
  expect_identical(p$kwarg, "K")
  expect_null(p$matrix_labels)
  expect_identical(p$formula[[2L]], "sd(id, relmat) ~ z")
  expect_true(grepl("relmat(", p$formula[[1L]], fixed = TRUE))
  expect_true("sd" %in% names(p$coef_labels))
  distance <- as.matrix(stats::dist(coords))
  range <- stats::median(distance[upper.tri(distance)])
  expected <- exp(-distance / range) + 1e-6 * diag(4L)
  expect_equal(unname(p$matrix), unname(expected), tolerance = 1e-6)
  # The same shape for Gamma is unchanged.
  g <- drm_julia_structured_payload(spatial, "gamma", s$data, environment())
  expect_equal(unname(g$matrix), unname(p$matrix))
})

test_that("NB2 spatial slope neighbours stay refused", {
  s <- b26_small_data()
  coords <- s$coords
  K <- s$K
  spatial_intercept <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  # The NB2 spatial intercept is admitted by its own gate in batch 32 (see
  # test-julia-b32-count-gamma-spatial-intercept-bridge.R); the slope-only gate
  # stays false for it (pinned in the first block above).
  expect_true(drm_julia_spatial_sd_intercept_route_admitted(spatial_intercept))
  # Other non-admitted families keep the spatial refusal.
  spatial <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  expect_error(
    drm_julia_structured_payload(spatial, "poisson", s$data, environment()),
    "spatial"
  )
  # A spatial slope with a K slot never reaches the bridge: the parser refuses it.
  expect_error(
    bf(
      y ~ x + spatial(0 + x | id, K = K),
      sd(id, level = "spatial") ~ z
    ),
    "coords"
  )
  # Correlated intercept + slope with a spatial marker stays a slope refusal.
  intercept_slope <- bf(
    y ~ x + spatial(1 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  expect_error(
    drm_julia_refuse_marker_slope_unsupported(intercept_slope, "nbinom2"),
    "random slope"
  )
  # A modelled sigma is still refused on the structured route.
  sigma_model <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sigma ~ x,
    sd(id, level = "spatial") ~ z
  )
  expect_error(
    drm_julia_structured_payload(sigma_model, "nbinom2", s$data, environment()),
    "sigma"
  )
})

test_that("NB2 coordinate spatial slope SD agrees across engines", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261108L)
  n_group <- 40L
  n_each <- 20L
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
  size <- 1 / 0.42^2
  mu <- exp(0.3 + 0.25 * x + x * u[id_index])
  dat$y <- stats::rnbinom(nrow(dat), size = size, mu = mu)
  # Rows are not in group order, so the kernel must be aligned by name.
  expect_false(identical(unique(as.character(dat$id)), id_levels))
  form <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  native <- drmTMB(form, family = nbinom2(), data = dat, engine = "tmb",
                   control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = nbinom2(), data = dat, engine = "julia")
  expect_equal(native$opt$convergence, 0L)
  expect_equal(julia$opt$convergence, 0L)
  diffs <- list()
  for (dpar in c("mu", "sigma", "sd_spatial(id)")) {
    nc <- coef(native, dpar = dpar)
    jc <- coef(julia, dpar = dpar)
    expect_named(jc, names(nc))
    diffs[[dpar]] <- max(abs(unname(jc) - unname(nc)))
    expect_lt(diffs[[dpar]], 1e-3, label = paste("coef diff", dpar))
  }
  ll <- abs(as.numeric(logLik(julia)) - as.numeric(logLik(native)))
  expect_lt(ll, 1e-2, label = "logLik diff")
  message(
    "B26 diffs: ",
    paste(names(diffs), signif(unlist(diffs), 3), collapse = "; "),
    "; logLik diff ", signif(ll, 3)
  )
})
