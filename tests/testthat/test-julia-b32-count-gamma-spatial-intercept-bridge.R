# Batch 32 R-bridge admission: coordinate spatial INTERCEPT SD regression for
# Poisson, NB2 and Gamma,
#   spatial(1 | id, coords = coords) + sd(id, level = "spatial") ~ z.
# As for the batch 25/26 slope routes, the bridge sends the native fixed kernel
# exp(-d / median positive distance) + 1e-6 I as a raw relmat K, so Julia fits
# its existing relmat intercept SD fitter for each family (no spatial-specific
# Julia code). The same file pins the relmat intercept routes those fitters
# already served from R. Poisson spatial SLOPE and NB2 spatial intercept through
# the direct Julia spatial marker stay out of scope.
# The first blocks are non-live (gate, payload, refusal pins). The last blocks
# are live native-vs-Julia parity checks, skipped unless Julia and DRM_JL_PATH
# are available. Tolerances fixed before the live runs: coefficients (every
# block) within 1e-3 absolute, logLik within 1e-2 absolute, native TMB
# (se = FALSE) as comparator. One fixture per route; no SE, coverage or broad
# parity claim.

b32c_small_data <- function() {
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
    y = c(0L, 3L, 1L, 2L, 4L, 0L, 2L, 5L)
  )
  list(K = K, coords = coords, data = data)
}

test_that("spatial intercept SD gate admits only its shape", {
  s <- b32c_small_data()
  coords <- s$coords
  K <- s$K
  spatial <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  expect_true(drm_julia_spatial_sd_intercept_route_admitted(spatial))
  slope <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  no_sd <- bf(y ~ x + spatial(1 | id, coords = coords))
  relmat <- bf(y ~ x + relmat(1 | id, K = K), sd(id, level = "relmat") ~ z)
  expect_false(drm_julia_spatial_sd_intercept_route_admitted(slope))
  expect_false(drm_julia_spatial_sd_intercept_route_admitted(no_sd))
  expect_false(drm_julia_spatial_sd_intercept_route_admitted(relmat))
  # The slope-only gates are unchanged by the new gate.
  expect_true(drm_julia_nbinom2_spatial_sd_slope_route_admitted(slope))
  expect_false(drm_julia_nbinom2_spatial_sd_slope_route_admitted(spatial))
})

test_that("spatial intercept payload sends the native kernel as a raw relmat K", {
  s <- b32c_small_data()
  coords <- s$coords
  spatial <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  distance <- as.matrix(stats::dist(coords))
  range <- stats::median(distance[upper.tri(distance)])
  expected <- exp(-distance / range) + 1e-6 * diag(4L)
  for (family_type in c("poisson", "nbinom2", "gamma")) {
    p <- drm_julia_structured_payload(spatial, family_type, s$data, environment())
    expect_identical(p$kwarg, "K", info = family_type)
    expect_null(p$matrix_labels)
    expect_identical(p$formula[[2L]], "sd(id, relmat) ~ z", info = family_type)
    expect_true(grepl("relmat(", p$formula[[1L]], fixed = TRUE), info = family_type)
    expect_true("sd" %in% names(p$coef_labels), info = family_type)
    expect_equal(unname(p$matrix), unname(expected), tolerance = 1e-6,
                 info = family_type)
  }
})

test_that("spatial intercept neighbours stay refused", {
  s <- b32c_small_data()
  coords <- s$coords
  spatial <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  # Without a matching SD formula the family-level spatial refusal remains.
  no_sd <- bf(y ~ x + spatial(1 | id, coords = coords))
  for (family_type in c("poisson", "nbinom2", "gamma")) {
    expect_error(
      drm_julia_structured_payload(no_sd, family_type, s$data, environment()),
      "spatial",
      info = family_type
    )
  }
  # Poisson spatial slope is not admitted (slope routes are Gamma/NB2/Gaussian).
  slope <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  expect_error(
    drm_julia_structured_payload(slope, "poisson", s$data, environment()),
    "spatial"
  )
  # A modelled sigma is still refused on the structured route.
  sigma_model <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sigma ~ x,
    sd(id, level = "spatial") ~ z
  )
  expect_error(
    drm_julia_structured_payload(sigma_model, "nbinom2", s$data, environment()),
    "sigma"
  )
  # Other families keep the spatial refusal.
  expect_error(
    drm_julia_structured_payload(spatial, "beta", s$data, environment()),
    "spatial"
  )
})

test_that("Poisson, NB2 and Gamma spatial intercept payload orders the kernel by first appearance, not by coords row order", {
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
    y = c(1L, 3L, 0L, 2L, 4L, 1L, 2L, 5L, 0L, 3L)
  )
  spatial <- bf(
    y ~ x + spatial(1 | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  distance <- as.matrix(stats::dist(coords))
  range <- stats::median(distance[upper.tri(distance)])
  kernel <- exp(-distance / range) + 1e-6 * diag(5L)
  expected <- kernel[first_seen, first_seen]
  for (family_type in c("poisson", "nbinom2", "gamma")) {
    p <- drm_julia_structured_payload(spatial, family_type, data, environment())
    expect_equal(unname(p$matrix), unname(expected), tolerance = 1e-6,
                 info = family_type)
    # The order is not the coords row order (the test would be vacuous if so).
    expect_false(isTRUE(all.equal(unname(p$matrix), unname(kernel))))
  }
})

b32c_live_setup <- function(.local_envir = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path, .local_envir = .local_envir)
  drm_test_local_julia_home(.local_envir = .local_envir)
}

b32c_compare <- function(julia, native, dpars, tol_coef = 1e-3, tol_ll = 1e-2) {
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
    "B32C diffs: ",
    paste(names(diffs), signif(unlist(diffs), 3), collapse = "; "),
    "; logLik diff ", signif(ll, 3)
  )
  invisible(list(coef = diffs, ll = ll))
}

# Draw the response for one family given the linear predictor on the mean.
b32c_draw <- function(family_type, eta) {
  mu <- exp(eta)
  switch(
    family_type,
    poisson = stats::rpois(length(mu), mu),
    nbinom2 = stats::rnbinom(length(mu), size = 1 / 0.42^2, mu = mu),
    gamma = stats::rgamma(length(mu), shape = 1 / 0.35^2,
                          rate = (1 / 0.35^2) / mu)
  )
}

b32c_family <- function(family_type) {
  switch(
    family_type,
    poisson = poisson(),
    nbinom2 = nbinom2(),
    gamma = Gamma(link = "log")
  )
}

b32c_spatial_fixture <- function(family_type, seed, n_group = 40L, n_each = 16L) {
  set.seed(seed)
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
  dat$y <- b32c_draw(family_type, 0.3 + 0.2 * x + u[id_index])
  expect_false(identical(unique(as.character(dat$id)), id_levels))
  list(coords = coords, dat = dat)
}

b32c_relmat_fixture <- function(family_type, seed, n_group = 40L, n_each = 16L) {
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
  x <- stats::rnorm(length(id_index))
  dat <- data.frame(
    id = factor(id_levels[id_index], levels = id_levels),
    x = x, z = z_group[id_index]
  )
  dat$y <- b32c_draw(family_type, 0.3 + 0.2 * x + u[id_index])
  list(K = K, dat = dat)
}

for (b32c_family_type in c("poisson", "nbinom2", "gamma")) {
  local({
    family_type <- b32c_family_type
    test_that(paste(family_type, "coordinate spatial intercept SD agrees across engines"), {
      b32c_live_setup()
      fx <- b32c_spatial_fixture(family_type, 20261210L + nchar(family_type))
      coords <- fx$coords
      form <- bf(
        y ~ x + spatial(1 | id, coords = coords),
        sd(id, level = "spatial") ~ z
      )
      fam <- b32c_family(family_type)
      native <- drmTMB(form, family = fam, data = fx$dat, engine = "tmb",
                       control = drm_control(se = FALSE))
      julia <- drmTMB(form, family = fam, data = fx$dat, engine = "julia")
      dpars <- c("mu", "sd_spatial(id)", if (family_type != "poisson") "sigma")
      b32c_compare(julia, native, dpars)
      # fitted() contract (batch 32 audit): the bridge slot is the
      # population-level value exp(X beta) in data row order, with the random
      # effect modes at zero. Native fitted() is the conditional mean, so the
      # engines differ here by definition; this pins the row order and the
      # definition and claims no parity. The fixture's coordinate rows are named
      # in a different order from first appearance.
      b <- coef(julia, dpar = "mu")
      xb <- as.vector(cbind(1, fx$dat$x) %*% b[c("(Intercept)", "x")])
      expect_equal(as.numeric(fitted(julia)), exp(xb), tolerance = 1e-6)
    })
    test_that(paste(family_type, "relmat intercept SD agrees across engines (non-unit K)"), {
      b32c_live_setup()
      fx <- b32c_relmat_fixture(family_type, 20261220L + nchar(family_type))
      K <- fx$K
      form <- bf(y ~ x + relmat(1 | id, K = K), sd(id, level = "relmat") ~ z)
      fam <- b32c_family(family_type)
      native <- drmTMB(form, family = fam, data = fx$dat, engine = "tmb",
                       control = drm_control(se = FALSE))
      julia <- drmTMB(form, family = fam, data = fx$dat, engine = "julia")
      dpars <- c("mu", "sd_relmat(id)", if (family_type != "poisson") "sigma")
      b32c_compare(julia, native, dpars)
    })
  })
}
