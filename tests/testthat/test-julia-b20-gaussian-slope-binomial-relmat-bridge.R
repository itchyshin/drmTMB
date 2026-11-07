# Batch 20 R-bridge checks (DRM.jl 40da69c72 Gaussian structured slope SD,
# fbcf4d0e3 NB2 animal slope simulator; Binomial relmat scaling audit).
# Tolerances were fixed before the live runs: coefficients (every block)
# within 1e-3 absolute, logLik within 1e-2 absolute, native TMB
# (se = FALSE) as the comparator on the same fixture. One fixture per route;
# no SE, coverage or broad parity claim.

b20_compare <- function(julia, native, dpars, tol_coef = 1e-3, tol_ll = 1e-2) {
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
    "B20 diffs: ",
    paste(names(diffs), signif(unlist(diffs), 3), collapse = "; "),
    "; logLik diff ", signif(ll, 3)
  )
  invisible(list(coef = diffs, ll = ll))
}

b20_live_setup <- function(.local_envir = parent.frame()) {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path, .local_envir = .local_envir)
  drm_test_local_julia_home(.local_envir = .local_envir)
}

b20_pedigree_A <- function(n_fam, n_off, scale_range) {
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
  d <- seq(scale_range[[1L]], scale_range[[2L]], length.out = length(offspring))
  A <- outer(d, d) * A_full[offspring, offspring, drop = FALSE]
  dimnames(A) <- list(offspring, offspring)
  A
}

test_that("Gaussian animal slope-only SD gate admits its shape", {
  A <- diag(4L)
  dimnames(A) <- list(paste0("id", 1:4), paste0("id", 1:4))
  data <- data.frame(
    y = c(0.1, 1.2, -0.3, 0.4, 1.1, 0.7, -0.2, 0.9),
    x = rep(c(-1, 1), 4),
    z = rep(c(-1, -1, 1, 1), each = 2),
    id = factor(rep(paste0("id", 1:4), each = 2))
  )
  slope <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  expect_true(drm_julia_gaussian_animal_sd_slope_route_admitted(slope))
  expect_no_error(drm_julia_refuse_marker_slope_unsupported(slope, "gaussian"))
  payload <- drm_julia_structured_payload(slope, "gaussian", data, environment())
  expect_identical(payload$kwarg, "A")
  expect_identical(payload$formula[[2L]], "sd(id, animal) ~ z")
  expect_equal(unname(payload$matrix), unname(A))
  expect_true("sd" %in% names(payload$coef_labels))

  # Structured sigma and the intercept-plus-slope form stay refused.
  sigma_slope <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sigma ~ x,
    sd(id, level = "animal") ~ z
  )
  intercept_slope <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  expect_false(drm_julia_gaussian_animal_sd_slope_route_admitted(sigma_slope))
  expect_false(drm_julia_gaussian_animal_sd_slope_route_admitted(intercept_slope))
  expect_error(
    drm_julia_refuse_marker_slope_unsupported(intercept_slope, "gaussian"),
    "random slope"
  )
})

test_that("Gaussian relmat and spatial slope SD payloads are admitted", {
  id_levels <- paste0("id", 1:4)
  K <- diag(4L)
  dimnames(K) <- list(id_levels, id_levels)
  coords <- cbind(east = 1:4, north = c(0, 1, 0, -1))
  rownames(coords) <- id_levels
  data <- data.frame(
    id = factor(rep(id_levels, each = 2L), levels = id_levels),
    x = rep(c(-1, 1), 4L),
    z = rep(c(-1, 1), each = 4L),
    y = c(0.1, 1.2, -0.3, 0.4, 1.1, 0.7, -0.2, 0.9)
  )
  relmat <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  spatial <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  expect_true(drm_julia_gaussian_relmat_sd_slope_route_admitted(relmat))
  expect_true(drm_julia_gaussian_spatial_sd_slope_route_admitted(spatial))
  rp <- drm_julia_structured_payload(relmat, "gaussian", data, environment())
  expect_identical(rp$kwarg, "K")
  expect_identical(rp$formula[[2L]], "sd(id, relmat) ~ z")
  sp <- drm_julia_structured_payload(spatial, "gaussian", data, environment())
  expect_identical(sp$kwarg, "K")  # coordinate kernel sent as a covariance K
  expect_equal(dim(sp$matrix), c(4L, 4L))

  # Named coords listed in a different order than the first-seen group order
  # are reordered by name (the kernel rows follow the data's first-seen groups).
  shuffled <- data[c(5:8, 1:4), ]
  coords_rev <- coords[4:1, ]
  spatial_rev <- bf(
    y ~ x + spatial(0 + x | id, coords = coords_rev),
    sd(id, level = "spatial") ~ z
  )
  sp_rev <- drm_julia_structured_payload(spatial_rev, "gaussian", shuffled, environment())
  d <- as.matrix(stats::dist(coords[c("id3", "id4", "id1", "id2"), ]))
  expected <- exp(-d / stats::median(d[upper.tri(d)])) + 1e-6 * diag(4L)
  expect_equal(unname(sp_rev$matrix), unname(expected), tolerance = 1e-8)
})

test_that("Gaussian relmat slope SD agrees across engines (non-unit K)", {
  b20_live_setup()

  set.seed(20261102L)
  n_group <- 40L
  n_each <- 16L
  id_levels <- paste0("g", seq_len(n_group))
  marginal_scale <- seq(0.7, 1.6, length.out = n_group)
  correlation <- outer(seq_len(n_group), seq_len(n_group), function(i, j) {
    0.4^abs(i - j)
  })
  K <- outer(marginal_scale, marginal_scale) * correlation
  dimnames(K) <- list(id_levels, id_levels)
  expect_gt(max(abs(diag(K) - 1)), 0.5)
  z_group <- rep(c(-1, 1), length.out = n_group)
  slope_sd <- exp(-0.5 + 0.5 * z_group)
  u <- slope_sd * as.vector(t(chol(K)) %*% stats::rnorm(n_group))
  id_index <- rep(seq_len(n_group), each = n_each)
  x <- stats::rnorm(n_group * n_each)
  dat <- data.frame(
    id = factor(id_levels[id_index], levels = id_levels),
    x = x, z = z_group[id_index]
  )
  dat$y <- 0.3 + 0.2 * x + x * u[id_index] +
    stats::rnorm(nrow(dat), 0, 0.5)
  form <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  native <- drmTMB(form, family = gaussian(), data = dat, engine = "tmb",
                   control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = gaussian(), data = dat, engine = "julia")
  b20_compare(julia, native, c("mu", "sigma", "sd_relmat(id)"))
})

test_that("Gaussian coordinate spatial slope SD agrees across engines", {
  b20_live_setup()

  set.seed(20261103L)
  n_group <- 40L
  n_each <- 16L
  id_levels <- paste0("s", seq_len(n_group))
  coords <- cbind(east = stats::rnorm(n_group), north = stats::rnorm(n_group))
  rownames(coords) <- id_levels
  distance <- as.matrix(stats::dist(coords))
  range <- stats::median(distance[upper.tri(distance)])
  C <- exp(-distance / range) + 1e-6 * diag(n_group)
  z_group <- rep(c(-1, 1), length.out = n_group)
  u <- exp(-0.5 + 0.5 * z_group) * as.vector(t(chol(C)) %*% stats::rnorm(n_group))
  # Rows are shuffled so the first-seen group order differs from the row
  # order of `coords`; the bridge must reorder coordinates by name.
  id_index <- sample(rep(seq_len(n_group), each = n_each))
  x <- stats::rnorm(length(id_index))
  dat <- data.frame(
    id = factor(id_levels[id_index], levels = id_levels),
    x = x, z = z_group[id_index]
  )
  dat$y <- 0.3 + 0.2 * x + x * u[id_index] + stats::rnorm(nrow(dat), 0, 0.5)
  expect_false(identical(unique(as.character(dat$id)), id_levels))
  form <- bf(
    y ~ x + spatial(0 + x | id, coords = coords),
    sd(id, level = "spatial") ~ z
  )
  native <- drmTMB(form, family = gaussian(), data = dat, engine = "tmb",
                   control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = gaussian(), data = dat, engine = "julia")
  b20_compare(julia, native, c("mu", "sigma", "sd_spatial(id)"))
})

test_that("Binomial relmat SD agrees across engines for a non-unit-diagonal K", {
  b20_live_setup()

  set.seed(20261102L)
  n_group <- 64L
  n_each <- 32L
  id_levels <- paste0("g", seq_len(n_group))
  marginal_scale <- seq(0.8, 1.6, length.out = n_group)
  correlation <- outer(seq_len(n_group), seq_len(n_group), function(i, j) {
    0.4^abs(i - j)
  })
  K <- outer(marginal_scale, marginal_scale) * correlation
  dimnames(K) <- list(id_levels, id_levels)
  expect_gt(max(abs(diag(K) - 1)), 0.5)  # the raw-K case that Poisson refuses
  z_group <- sample(rep(c(-1, 1), each = n_group / 2L))
  slope_sd <- exp(-0.75 + 0.5 * z_group)
  unit <- as.vector(t(chol(K)) %*% stats::rnorm(n_group))
  id_index <- rep(seq_len(n_group), each = n_each)
  x <- rep(seq(-1.5, 1.5, length.out = n_each), times = n_group)
  dat <- data.frame(
    id = factor(id_levels[id_index], levels = id_levels),
    x = x, z = z_group[id_index]
  )
  random <- (slope_sd * unit)[id_index]

  slope_form <- bf(
    y ~ x + relmat(0 + x | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  dat$y <- stats::rbinom(
    nrow(dat), 1L, stats::plogis(-0.1 + 0.35 * x + x * random)
  )
  native <- drmTMB(slope_form, family = stats::binomial(), data = dat,
                   engine = "tmb", control = drm_control(se = FALSE))
  julia <- drmTMB(slope_form, family = stats::binomial(), data = dat,
                  engine = "julia")
  b20_compare(julia, native, c("mu", "sd_relmat(id)"))

  intercept_form <- bf(
    y ~ x + relmat(1 | id, K = K),
    sd(id, level = "relmat") ~ z
  )
  dat$y <- stats::rbinom(
    nrow(dat), 1L, stats::plogis(-0.1 + 0.35 * x + random)
  )
  native <- drmTMB(intercept_form, family = stats::binomial(), data = dat,
                   engine = "tmb", control = drm_control(se = FALSE))
  julia <- drmTMB(intercept_form, family = stats::binomial(), data = dat,
                  engine = "julia")
  b20_compare(julia, native, c("mu", "sd_relmat(id)"))
})

test_that("Gaussian animal slope-only SD agrees across engines (raw non-unit A)", {
  b20_live_setup()

  set.seed(20261102L)
  A <- b20_pedigree_A(n_fam = 12L, n_off = 4L, scale_range = c(0.8, 1.5))
  expect_true(any(abs(diag(A) - 1) > 1e-6))  # raw A, as native uses it
  offspring <- rownames(A)
  n_id <- length(offspring)
  x_n <- 14L
  dat <- data.frame(
    id = factor(rep(offspring, each = x_n), levels = offspring),
    x = rep(seq(-1, 1, length.out = x_n), n_id)
  )
  z_id <- rep(c(-0.5, 0.5), length.out = n_id)
  dat$z <- z_id[as.integer(dat$id)]
  tau <- exp(log(0.5) + 0.5 * z_id)
  u <- tau * as.vector(t(chol(A + diag(1e-8, n_id))) %*% stats::rnorm(n_id))
  dat$y <- 0.3 + 0.4 * dat$x + dat$x * u[as.integer(dat$id)] +
    stats::rnorm(nrow(dat), 0, 0.6)
  form <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sd(id, level = "animal") ~ z
  )
  native <- drmTMB(form, family = gaussian(), data = dat, engine = "tmb",
                   control = drm_control(se = FALSE))
  julia <- drmTMB(form, family = gaussian(), data = dat, engine = "julia")
  b20_compare(julia, native, c("mu", "sigma", "sd_animal(id)"))
})

test_that("Julia NB2 animal slope-only fit supports marginal simulate()", {
  b20_live_setup()

  set.seed(20261102L)
  A <- b20_pedigree_A(n_fam = 16L, n_off = 4L, scale_range = c(0.8, 1.5))
  offspring <- rownames(A)
  n_id <- length(offspring)
  x_n <- 20L
  dat <- data.frame(
    id = factor(rep(offspring, each = x_n), levels = offspring),
    x = rep(seq(-1, 1, length.out = x_n), n_id)
  )
  z_id <- rep(c(-0.5, 0.5), length.out = n_id)
  dat$z <- z_id[as.integer(dat$id)]
  tau <- exp(log(0.35) + 0.45 * z_id)
  u <- tau * as.vector(t(chol(A + diag(1e-8, n_id))) %*% stats::rnorm(n_id))
  eta <- 1.1 + 0.2 * dat$x + dat$x * u[as.integer(dat$id)]
  dat$y <- stats::rnbinom(nrow(dat), mu = exp(eta), size = 1 / 0.45^2)
  form <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal") ~ z
  )
  julia <- drmTMB(form, family = nbinom2(), data = dat, engine = "julia")

  draws <- simulate(julia, nsim = 200L, seed = 20261103L)
  repeat_draws <- simulate(julia, nsim = 200L, seed = 20261103L)
  expect_identical(draws, repeat_draws)
  expect_equal(dim(draws), c(nrow(dat), 200L))
  expect_true(all(vapply(draws, function(col) all(col >= 0 & col == round(col)),
                         logical(1L))))
  # Marginal means: the simulated mean count stays close to the observed one
  # (a loose sanity band, not a calibration claim).
  ratio <- mean(as.matrix(draws)) / mean(dat$y)
  message("B20 NB2 simulate mean ratio ", signif(ratio, 4))
  expect_gt(ratio, 0.8)
  expect_lt(ratio, 1.25)
  expect_error(
    simulate(julia, nsim = 1L, seed = 1L, re.form = NULL),
    "Conditional simulation is unavailable"
  )
})
