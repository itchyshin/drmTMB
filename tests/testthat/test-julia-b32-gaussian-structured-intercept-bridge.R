# Batch 32 R-bridge admission: Gaussian structured intercept SD regression,
#   relmat(1 | id, K = K)         + sd(id, level = "relmat")   ~ z
#   animal(1 | id, A = A)         + sd(id, level = "animal")   ~ z
#   spatial(1 | id, coords = ...) + sd(id, level = "spatial")  ~ z
# DRModels.jl routes these through its Gaussian structured SD fitter (exact
# dense ML, loading 1; K and A enter raw as in native drmTMB). Coordinate
# spatial reaches Julia as the native fixed kernel re-expressed as a relmat K.
# The first blocks are non-live (payload and refusal pins). The last blocks are
# live native-vs-Julia parity checks, skipped unless Julia and DRM_JL_PATH are
# available. Tolerances fixed before the live runs: coefficients (every block)
# within 1e-3 absolute, logLik within 1e-2 absolute, native TMB (se = FALSE) as
# comparator on the same fixture. One fixture per route; no SE, coverage or
# broad parity claim.

b32g_small_data <- function() {
  id_levels <- paste0("id", 1:4)
  K <- matrix(
    c(1.5, 0.3, 0.1, 0.0,
      0.3, 1.0, 0.2, 0.1,
      0.1, 0.2, 0.8, 0.2,
      0.0, 0.1, 0.2, 1.2),
    4L, 4L
  )
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

test_that("Gaussian structured intercept payloads send raw K / A and the native spatial kernel", {
  s <- b32g_small_data()
  K <- s$K
  A <- s$K
  coords <- s$coords
  relmat <- bf(y ~ x + relmat(1 | id, K = K), sd(id, level = "relmat") ~ z)
  animal <- bf(y ~ x + animal(1 | id, A = A), sd(id, level = "animal") ~ z)
  spatial <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  expect_true(max(abs(diag(K) - 1)) > 0.2)  # non-unit diagonal: raw K is testable

  rp <- drm_julia_structured_payload(relmat, "gaussian", s$data, environment())
  expect_identical(rp$kwarg, "K")
  expect_identical(rp$formula[[2L]], "sd(id, relmat) ~ z")
  expect_equal(unname(rp$matrix), unname(K))
  expect_true("sd" %in% names(rp$coef_labels))

  ap <- drm_julia_structured_payload(animal, "gaussian", s$data, environment())
  expect_identical(ap$kwarg, "A")
  expect_identical(ap$formula[[2L]], "sd(id, animal) ~ z")
  expect_equal(unname(ap$matrix), unname(A))

  sp <- drm_julia_structured_payload(spatial, "gaussian", s$data, environment())
  expect_identical(sp$kwarg, "K")
  expect_null(sp$matrix_labels)
  expect_identical(sp$formula[[2L]], "sd(id, relmat) ~ z")
  expect_true(grepl("relmat(", sp$formula[[1L]], fixed = TRUE))
  distance <- as.matrix(stats::dist(coords))
  range <- stats::median(distance[upper.tri(distance)])
  expected <- exp(-distance / range) + 1e-6 * diag(4L)
  expect_equal(unname(sp$matrix), unname(expected), tolerance = 1e-6)
})

test_that("Gaussian structured intercept SD neighbours stay refused", {
  s <- b32g_small_data()
  K <- s$K
  A <- s$K
  Ainv <- solve(s$K)
  dimnames(Ainv) <- dimnames(s$K)
  coords <- s$coords
  # A modelled sigma is still refused on the structured route.
  sigma_model <- bf(
    y ~ x + relmat(1 | id, K = K),
    sigma ~ x,
    sd(id, level = "relmat") ~ z
  )
  expect_error(
    drm_julia_structured_payload(sigma_model, "gaussian", s$data, environment()),
    "sigma"
  )
  # Precision-matrix animal input is still limited to the Poisson/Binomial routes.
  animal_ainv <- bf(
    y ~ x + animal(1 | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )
  expect_error(
    drm_julia_structured_payload(animal_ainv, "gaussian", s$data, environment()),
    "Ainv"
  )
  # A correlated intercept + slope marker stays a slope refusal.
  intercept_slope <- bf(
    y ~ x + relmat(1 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  expect_error(
    drm_julia_refuse_marker_slope_unsupported(intercept_slope, "gaussian"),
    "random slope"
  )
  # The spatial intercept gate needs the matching SD formula and the coords slot.
  spatial_no_sd <- bf(y ~ x + spatial(1 | id, coords = coords))
  expect_false(drm_julia_spatial_sd_intercept_route_admitted(spatial_no_sd))
  spatial_slope <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  expect_false(drm_julia_spatial_sd_intercept_route_admitted(spatial_slope))
  spatial_intercept <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  expect_true(drm_julia_spatial_sd_intercept_route_admitted(spatial_intercept))
  # The new spatial gate is family-scoped in the payload: Beta stays refused.
  expect_error(
    drm_julia_structured_payload(spatial_intercept, "beta", s$data, environment()),
    "spatial"
  )
})

test_that("Gaussian spatial intercept payload orders the kernel by first appearance, not by coords row order", {
  # Audit pin (batch 32, fitted() investigation): named coords listed in a
  # different order from the groups' first appearance in the data must give the
  # kernel rows in first-appearance order, because DRModels.jl pairs row i with
  # the i-th group and never sees names. Passes before and after the batch.
  id_levels <- paste0("id", 1:5)
  coords <- cbind(east = c(0, 2, 5, 6, 9), north = c(1, 0, 3, 1, 2))
  rownames(coords) <- id_levels
  first_seen <- c("id4", "id2", "id5", "id1", "id3")
  data <- data.frame(
    id = factor(rep(first_seen, each = 2L), levels = id_levels),
    x = rep(c(-1, 1), 5L),
    z = rep(c(-1, 1), length.out = 10L),
    y = c(0.4, 1.2, 0.8, 0.5, 1.1, 0.7, 0.9, 1.3, 0.2, 0.6)
  )
  spatial <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  distance <- as.matrix(stats::dist(coords))
  range <- stats::median(distance[upper.tri(distance)])
  kernel <- exp(-distance / range) + 1e-6 * diag(5L)
  expected <- kernel[first_seen, first_seen]
  for (family_type in "gaussian") {
    p <- drm_julia_structured_payload(spatial, family_type, data, environment())
    expect_equal(unname(p$matrix), unname(expected), tolerance = 1e-6,
                 info = family_type)
    # The order is not the coords row order (the test would be vacuous if so).
    expect_false(isTRUE(all.equal(unname(p$matrix), unname(kernel))))
  }
})

b32g_live_setup <- function(.local_envir = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path, .local_envir = .local_envir)
  drm_test_local_julia_home(.local_envir = .local_envir)
}

b32g_compare <- function(julia, native, dpars, tol_coef = 1e-3, tol_ll = 1e-2) {
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
    "B32G diffs: ",
    paste(names(diffs), signif(unlist(diffs), 3), collapse = "; "),
    "; logLik diff ", signif(ll, 3)
  )
  invisible(list(coef = diffs, ll = ll))
}

# Non-unit-diagonal K with the group SD driven by a group-level covariate z.
b32g_kernel_fixture <- function(seed, n_group = 40L, n_each = 16L) {
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
  # Rows are not in group order, so the kernel must be aligned by name.
  id_index <- sample(rep(seq_len(n_group), each = n_each))
  x <- stats::rnorm(length(id_index))
  dat <- data.frame(
    id = factor(id_levels[id_index], levels = id_levels),
    x = x, z = z_group[id_index]
  )
  dat$y <- 0.3 + 0.2 * x + u[id_index] + stats::rnorm(nrow(dat), sd = 0.5)
  expect_false(identical(unique(as.character(dat$id)), id_levels))
  list(K = K, dat = dat)
}

test_that("Gaussian relmat intercept SD agrees across engines (non-unit K)", {
  b32g_live_setup()
  fx <- b32g_kernel_fixture(20261201L)
  K <- fx$K
  form <- bf(y ~ x + relmat(1 | id, K = K), sd(id, level = "relmat") ~ z)
  native <- drmTMB(form, family = gaussian(), data = fx$dat, engine = "tmb",
                   control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = gaussian(), data = fx$dat, engine = "julia")
  b32g_compare(julia, native, c("mu", "sigma", "sd_relmat(id)"))
})

test_that("Gaussian animal intercept SD agrees across engines (supplied A)", {
  b32g_live_setup()
  fx <- b32g_kernel_fixture(20261202L)
  A <- fx$K
  form <- bf(y ~ x + animal(1 | id, A = A), sd(id, level = "animal") ~ z)
  native <- drmTMB(form, family = gaussian(), data = fx$dat, engine = "tmb",
                   control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = gaussian(), data = fx$dat, engine = "julia")
  b32g_compare(julia, native, c("mu", "sigma", "sd_animal(id)"))
})

test_that("Gaussian coordinate spatial intercept SD agrees across engines", {
  b32g_live_setup()
  set.seed(20261203L)
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
  dat$y <- 0.3 + 0.2 * x + u[id_index] + stats::rnorm(nrow(dat), sd = 0.5)
  expect_false(identical(unique(as.character(dat$id)), id_levels))
  form <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  native <- drmTMB(form, family = gaussian(), data = dat, engine = "tmb",
                   control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = gaussian(), data = dat, engine = "julia")
  b32g_compare(julia, native, c("mu", "sigma", "sd_spatial(id)"))
  # fitted() contract on the structured bridge routes (batch 34): the conditional
  # mean, as native fitted() returns, in data row order even though the
  # coordinate rows are named in a different order from first appearance. The
  # population-level value X beta (what the slot held before batch 34) is far
  # from it, so this also pins that the old definition is gone. Tolerance fixed
  # beforehand: relative 1e-4 on fitted() and residuals().
  b <- coef(julia, dpar = "mu")
  xb <- as.vector(cbind(1, dat$x) %*% b[c("(Intercept)", "x")])
  fn <- as.numeric(fitted(native))
  expect_lt(max(abs(as.numeric(fitted(julia)) - fn)) / max(abs(fn)), 1e-4)
  rn <- as.numeric(residuals(native))
  expect_lt(max(abs(as.numeric(residuals(julia)) - rn)) / max(abs(rn)), 1e-4)
  expect_gt(max(abs(xb - fn)) / max(abs(fn)), 1e-2)
})
