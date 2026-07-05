new_count_structured_mu_data <- function(
  seed = 2026052801,
  n_level = 10L,
  n_each = 12L,
  sd_spatial = 0.45,
  sd_known = 0.45,
  sigma_nb2 = 0.35
) {
  set.seed(seed)
  levels <- paste0("id", seq_len(n_level))
  theta <- seq(0, 1.75 * pi, length.out = n_level)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_level) / (4 * n_level),
    y = sin(theta)
  )
  rownames(coords) <- levels

  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = levels,
    group = "site"
  )
  spatial_covariance <- solve(as.matrix(precision$precision))
  spatial_effect <- as.vector(
    t(chol(spatial_covariance)) %*% stats::rnorm(n_level, sd = sd_spatial)
  )
  names(spatial_effect) <- levels

  K <- outer(seq_len(n_level), seq_len(n_level), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(levels, levels)
  Q <- solve(K)
  known_effect <- as.vector(t(chol(K)) %*% stats::rnorm(n_level, sd = sd_known))
  names(known_effect) <- levels

  site <- rep(levels, each = n_each)
  id <- site
  x <- stats::rnorm(length(site))
  beta_mu <- c(`(Intercept)` = 0.65, x = -0.20)
  eta_spatial <- beta_mu[[1L]] + beta_mu[[2L]] * x + spatial_effect[site]
  eta_known <- beta_mu[[1L]] + beta_mu[[2L]] * x + known_effect[id]
  data <- data.frame(
    poisson_spatial = stats::rpois(length(site), lambda = exp(eta_spatial)),
    poisson_known = stats::rpois(length(site), lambda = exp(eta_known)),
    nb2_spatial = stats::rnbinom(
      length(site),
      size = 1 / sigma_nb2^2,
      mu = exp(eta_spatial)
    ),
    nb2_known = stats::rnbinom(
      length(site),
      size = 1 / sigma_nb2^2,
      mu = exp(eta_known)
    ),
    x = x,
    site = site,
    id = id
  )

  list(
    data = data,
    coords = coords,
    Q = Q,
    beta_mu = beta_mu,
    sigma_nb2 = sigma_nb2
  )
}

new_count_structured_mu_plus_ordinary_data <- function(
  seed = 2026070412,
  n_site = 8L,
  n_id = 16L,
  n_each = 16L
) {
  set.seed(seed)
  sites <- paste0("site", seq_len(n_site))
  ids <- paste0("id", seq_len(n_id))
  theta <- seq(0, 1.75 * pi, length.out = n_site)
  coords <- data.frame(
    x = cos(theta),
    y = sin(theta)
  )
  rownames(coords) <- sites

  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = sites,
    group = "site"
  )
  spatial_covariance <- solve(as.matrix(precision$precision))
  spatial_effect <- as.vector(
    t(chol(spatial_covariance)) %*% stats::rnorm(n_site, sd = 0.45)
  )
  names(spatial_effect) <- sites

  id <- rep(ids, each = n_each)
  site_for_id <- rep(sites, length.out = n_id)
  names(site_for_id) <- ids
  site <- unname(site_for_id[id])
  x <- stats::rnorm(length(id))
  ordinary_effect <- stats::rnorm(n_id, sd = 0.25)
  names(ordinary_effect) <- ids
  eta <- 0.55 - 0.20 * x + spatial_effect[site] + ordinary_effect[id]

  list(
    data = data.frame(
      y = stats::rpois(length(id), lambda = exp(eta)),
      x = x,
      site = factor(site, levels = sites),
      id = factor(id, levels = ids)
    ),
    coords = coords
  )
}

new_count_structured_mu_slope_data <- function(
  seed = 2026062513,
  n_level = 8L,
  n_each = 20L,
  sd_intercept = 0.25,
  sd_slope = 0.45,
  sigma_nb2 = 0.20
) {
  set.seed(seed)
  levels <- paste0("id", seq_len(n_level))
  site <- rep(levels, each = n_each)
  id <- site
  x <- stats::rnorm(length(site))

  theta <- seq(0, 1.75 * pi, length.out = n_level)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_level) / (4 * n_level),
    y = sin(theta)
  )
  rownames(coords) <- levels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = levels,
    group = "site"
  )
  spatial_covariance <- solve(as.matrix(precision$precision))

  K <- outer(seq_len(n_level), seq_len(n_level), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(levels, levels)
  Q <- solve(K)

  tree <- ape::stree(n_level, type = "balanced")
  tree$tip.label <- levels
  tree$edge.length <- rep(1, nrow(tree$edge))
  phylo_covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
  phylo_covariance <- phylo_covariance[levels, levels]

  draw_fields <- function(covariance) {
    chol_covariance <- chol(covariance + diag(1e-8, nrow(covariance)))
    intercept <- as.vector(
      t(chol_covariance) %*% stats::rnorm(nrow(covariance), sd = sd_intercept)
    )
    slope <- as.vector(
      t(chol_covariance) %*% stats::rnorm(nrow(covariance), sd = sd_slope)
    )
    names(intercept) <- rownames(covariance)
    names(slope) <- rownames(covariance)
    list(intercept = intercept, slope = slope)
  }

  fields <- list(
    phylo = draw_fields(phylo_covariance),
    spatial = draw_fields(spatial_covariance),
    known = draw_fields(K)
  )
  beta_mu <- c(`(Intercept)` = 0.55, x = -0.15)
  eta <- list(
    phylo = beta_mu[[1L]] +
      beta_mu[[2L]] * x +
      fields$phylo$intercept[site] +
      x * fields$phylo$slope[site],
    spatial = beta_mu[[1L]] +
      beta_mu[[2L]] * x +
      fields$spatial$intercept[site] +
      x * fields$spatial$slope[site],
    known = beta_mu[[1L]] +
      beta_mu[[2L]] * x +
      fields$known$intercept[id] +
      x * fields$known$slope[id]
  )

  data <- data.frame(
    poisson_phylo = stats::rpois(length(site), lambda = exp(eta$phylo)),
    poisson_spatial = stats::rpois(length(site), lambda = exp(eta$spatial)),
    poisson_known = stats::rpois(length(site), lambda = exp(eta$known)),
    nb2_phylo = stats::rnbinom(
      length(site),
      size = 1 / sigma_nb2^2,
      mu = exp(eta$phylo)
    ),
    nb2_spatial = stats::rnbinom(
      length(site),
      size = 1 / sigma_nb2^2,
      mu = exp(eta$spatial)
    ),
    nb2_known = stats::rnbinom(
      length(site),
      size = 1 / sigma_nb2^2,
      mu = exp(eta$known)
    ),
    x = x,
    site = site,
    id = id
  )

  list(
    data = data,
    coords = coords,
    tree = tree,
    Q = Q,
    beta_mu = beta_mu,
    sigma_nb2 = sigma_nb2
  )
}

expect_count_structured_mu_fit <- function(fit, type, group) {
  label <- paste0(type, "(1 | ", group, ")")
  key <- paste0(type, "_mu")
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$structured$phylo_mu$type, type)
  expect_equal(fit$model$structured$phylo_mu$q, 1L)
  expect_named(fit$sdpars$mu, label)
  expect_gt(unname(fit$sdpars$mu[[label]]), 0)
  expect_equal(names(ranef(fit)), key)
  expect_equal(ranef(fit, key), fit$random_effects[[key]])

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == paste0("sd:mu:", label), , drop = FALSE]
  expect_equal(nrow(sd_target), 1L)
  expect_equal(sd_target$tmb_parameter, "log_sd_phylo")
  expect_equal(sd_target$target_type, "direct")
  expect_true(sd_target$profile_ready)

  fixed_link <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  expect_equal(
    unname(predict(fit, dpar = "mu", type = "link")),
    fixed_link + drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )
  expect_true(all(predict(fit, dpar = "mu") > 0))

  checks <- check_drm(fit)
  structured_check <- checks[checks$check == paste0(type, "_mu_diagnostics"), ]
  expect_equal(nrow(structured_check), 1L)
  expect_equal(structured_check$status, "ok")
  expect_true(attr(checks, "ok"))
}

expect_count_structured_mu_plus_ordinary_fit <- function(fit) {
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$model_type, "poisson")
  expect_equal(fit$model$structured$phylo_mu$type, "spatial")
  expect_equal(fit$model$structured$phylo_mu$q, 1L)
  expect_setequal(names(fit$random_effects), c("mu", "spatial_mu"))
  expect_equal(ranef(fit, "mu"), fit$random_effects$mu)
  expect_equal(ranef(fit, "spatial_mu"), fit$random_effects$spatial_mu)
  expect_setequal(names(fit$sdpars$mu), c("(1 | id)", "spatial(1 | site)"))
  expect_true(all(unname(fit$sdpars$mu) > 0))

  targets <- profile_targets(fit)
  sd_target <- targets[
    targets$parm == "sd:mu:spatial(1 | site)",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(sd_target), 1L)
  expect_equal(sd_target$tmb_parameter, "log_sd_phylo")
  expect_equal(sd_target$target_type, "direct")
  expect_true(sd_target$profile_ready)

  fixed_link <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  expect_equal(
    unname(predict(fit, dpar = "mu", type = "link")),
    fixed_link +
      drmTMB:::mu_random_effect_contribution(fit) +
      drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )
  expect_true(all(predict(fit, dpar = "mu") > 0))

  checks <- check_drm(fit)
  structured_check <- checks[checks$check == "spatial_mu_diagnostics", ]
  expect_equal(nrow(structured_check), 1L)
  expect_equal(structured_check$status, "ok")
  expect_true(attr(checks, "ok"))
}

expect_count_structured_mu_slope_fit <- function(fit, type, group) {
  labels <- c(
    paste0(type, "(1 | ", group, ")"),
    paste0(type, "(0 + x | ", group, ")")
  )
  key <- paste0(type, "_mu")
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$structured$phylo_mu$type, type)
  expect_equal(fit$model$structured$phylo_mu$q, 2L)
  expect_equal(
    fit$model$structured$phylo_mu$coef_names,
    c("(Intercept)", "x")
  )
  expect_setequal(names(fit$sdpars$mu), labels)
  expect_true(all(unname(fit$sdpars$mu[labels]) > 0))
  expect_equal(names(ranef(fit)), key)
  expect_setequal(names(fit$random_effects[[key]]$terms), labels)

  targets <- profile_targets(fit)
  sd_targets <- targets[
    targets$parm %in% paste0("sd:mu:", labels),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(sd_targets), 2L)
  expect_equal(sd_targets$tmb_parameter, rep("log_sd_phylo", 2L))
  expect_equal(sd_targets$target_type, rep("direct", 2L))
  expect_true(all(sd_targets$profile_ready))

  fixed_link <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  expect_equal(
    unname(predict(fit, dpar = "mu", type = "link")),
    fixed_link + drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )
  expect_true(all(predict(fit, dpar = "mu") > 0))

  checks <- check_drm(fit)
  structured_check <- checks[checks$check == paste0(type, "_mu_diagnostics"), ]
  expect_equal(nrow(structured_check), 1L)
  expect_equal(structured_check$status, "ok")
  expect_true(attr(checks, "ok"))
}

test_that("Poisson mu supports q1 spatial, animal, and relmat intercepts", {
  sim <- new_count_structured_mu_data()
  dat <- sim$data
  coords <- sim$coords
  Q <- sim$Q

  fit_spatial <- drmTMB(
    bf(poisson_spatial ~ x + spatial(1 | site, coords = coords)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  fit_animal <- drmTMB(
    bf(poisson_known ~ x + animal(1 | id, Ainv = Q)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  fit_relmat <- drmTMB(
    bf(poisson_known ~ x + relmat(1 | id, Q = Q)),
    family = stats::poisson(link = "log"),
    data = dat
  )

  expect_count_structured_mu_fit(fit_spatial, "spatial", "site")
  expect_count_structured_mu_fit(fit_animal, "animal", "id")
  expect_count_structured_mu_fit(fit_relmat, "relmat", "id")
  expect_lt(max(abs(coef(fit_spatial, "mu") - sim$beta_mu)), 0.45)
  expect_lt(max(abs(coef(fit_animal, "mu") - sim$beta_mu)), 0.45)
  expect_lt(max(abs(coef(fit_relmat, "mu") - sim$beta_mu)), 0.45)
})

test_that("nbinom2 mu supports q1 spatial, animal, and relmat intercepts", {
  sim <- new_count_structured_mu_data(seed = 2026052802)
  dat <- sim$data
  coords <- sim$coords
  Q <- sim$Q

  fit_spatial <- drmTMB(
    bf(nb2_spatial ~ x + spatial(1 | site, coords = coords), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )
  fit_animal <- drmTMB(
    bf(nb2_known ~ x + animal(1 | id, Ainv = Q), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )
  fit_relmat <- drmTMB(
    bf(nb2_known ~ x + relmat(1 | id, Q = Q), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )

  expect_count_structured_mu_fit(fit_spatial, "spatial", "site")
  expect_count_structured_mu_fit(fit_animal, "animal", "id")
  expect_count_structured_mu_fit(fit_relmat, "relmat", "id")
  expect_lt(max(abs(coef(fit_spatial, "mu") - sim$beta_mu)), 0.50)
  expect_lt(max(abs(coef(fit_animal, "mu") - sim$beta_mu)), 0.50)
  expect_lt(max(abs(coef(fit_relmat, "mu") - sim$beta_mu)), 0.50)
  expect_true(all(sigma(fit_spatial) > 0))
  expect_true(all(sigma(fit_animal) > 0))
  expect_true(all(sigma(fit_relmat) > 0))
})

test_that("Poisson and nbinom2 mu support one structured count slope", {
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data()
  dat <- sim$data
  coords <- sim$coords
  tree <- sim$tree
  Q <- sim$Q

  poisson_phylo <- drmTMB(
    bf(poisson_phylo ~ x + phylo(1 + x | site, tree = tree)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  poisson_spatial <- drmTMB(
    bf(poisson_spatial ~ x + spatial(1 + x | site, coords = coords)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  poisson_animal <- drmTMB(
    bf(poisson_known ~ x + animal(1 + x | id, Ainv = Q)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  poisson_relmat <- drmTMB(
    bf(poisson_known ~ x + relmat(1 + x | id, Q = Q)),
    family = stats::poisson(link = "log"),
    data = dat
  )

  expect_count_structured_mu_slope_fit(poisson_phylo, "phylo", "site")
  expect_count_structured_mu_slope_fit(poisson_spatial, "spatial", "site")
  expect_count_structured_mu_slope_fit(poisson_animal, "animal", "id")
  expect_count_structured_mu_slope_fit(poisson_relmat, "relmat", "id")

  nb2_phylo <- drmTMB(
    bf(nb2_phylo ~ x + phylo(1 + x | site, tree = tree), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 700, iter.max = 700)
  )
  nb2_spatial <- drmTMB(
    bf(nb2_spatial ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 700, iter.max = 700)
  )
  nb2_animal <- drmTMB(
    bf(nb2_known ~ x + animal(1 + x | id, Ainv = Q), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 700, iter.max = 700)
  )
  nb2_relmat <- drmTMB(
    bf(nb2_known ~ x + relmat(1 + x | id, Q = Q), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 700, iter.max = 700)
  )

  expect_count_structured_mu_slope_fit(nb2_phylo, "phylo", "site")
  expect_count_structured_mu_slope_fit(nb2_spatial, "spatial", "site")
  expect_count_structured_mu_slope_fit(nb2_animal, "animal", "id")
  expect_count_structured_mu_slope_fit(nb2_relmat, "relmat", "id")
  expect_true(all(sigma(nb2_phylo) > 0))
  expect_true(all(sigma(nb2_spatial) > 0))
  expect_true(all(sigma(nb2_animal) > 0))
  expect_true(all(sigma(nb2_relmat) > 0))
})

test_that("count structured mu keeps planned neighboring routes closed", {
  sim <- new_count_structured_mu_data(n_level = 6L, n_each = 4L)
  dat <- sim$data
  coords <- sim$coords
  Q <- sim$Q

  expect_error(
    drmTMB(
      bf(poisson_spatial ~ x + spatial(0 + x | site, coords = coords)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "intercept-only or one-slope"
  )
  expect_error(
    drmTMB(
      bf(poisson_spatial ~ x + spatial(1 | p | site, coords = coords)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "unlabelled q=1"
  )
  sim_plus_ordinary <- new_count_structured_mu_plus_ordinary_data()
  coords_plus_ordinary <- sim_plus_ordinary$coords
  fit_plus_ordinary <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords_plus_ordinary) + (1 | id)),
    family = stats::poisson(link = "log"),
    data = sim_plus_ordinary$data
  )
  expect_count_structured_mu_plus_ordinary_fit(fit_plus_ordinary)

  sim_zi <- new_count_structured_mu_data(
    seed = 2026070408,
    n_level = 8L,
    n_each = 20L
  )
  dat_zi <- sim_zi$data
  coords_zi <- sim_zi$coords
  set.seed(2026070409)
  dat_zi$poisson_zi_spatial <- ifelse(
    stats::rbinom(nrow(dat_zi), size = 1L, prob = 0.25) == 1L,
    0L,
    dat_zi$poisson_spatial
  )
  fit_zi_mu <- drmTMB(
    bf(poisson_zi_spatial ~ x + spatial(1 | site, coords = coords_zi), zi ~ 1),
    family = stats::poisson(link = "log"),
    data = dat_zi,
    control = list(eval.max = 600, iter.max = 600)
  )
  expect_s3_class(fit_zi_mu, "drmTMB")
  expect_equal(fit_zi_mu$opt$convergence, 0)
  expect_true(fit_zi_mu$sdr$pdHess)
  expect_equal(fit_zi_mu$model$model_type, "zi_poisson")
  expect_equal(fit_zi_mu$model$dpars, c("mu", "zi"))
  expect_equal(fit_zi_mu$model$structured$phylo_mu$type, "spatial")
  expect_equal(fit_zi_mu$model$structured$phylo_mu$q, 1L)
  expect_named(fit_zi_mu$sdpars$mu, "spatial(1 | site)")
  expect_gt(unname(fit_zi_mu$sdpars$mu[["spatial(1 | site)"]]), 0)
  expect_equal(names(ranef(fit_zi_mu)), "spatial_mu")
  expect_equal(ranef(fit_zi_mu, "spatial_mu"), fit_zi_mu$random_effects$spatial_mu)
  sd_target <- profile_targets(fit_zi_mu)
  sd_target <- sd_target[
    sd_target$parm == "sd:mu:spatial(1 | site)",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(sd_target), 1L)
  expect_equal(sd_target$tmb_parameter, "log_sd_phylo")
  expect_equal(sd_target$target_type, "direct")
  expect_true(sd_target$profile_ready)
  expect_true(all(is.finite(predict(fit_zi_mu, dpar = "mu", type = "link"))))
  expect_true(all(predict(fit_zi_mu, dpar = "mu") > 0))
  expect_true(all(is.finite(predict(fit_zi_mu, dpar = "zi", type = "link"))))
  expect_error(
    drmTMB(
      bf(
        poisson_zi_spatial ~ x + spatial(1 | site, coords = coords_zi),
        zi ~ spatial(1 | site, coords = coords_zi)
      ),
      family = stats::poisson(link = "log"),
      data = dat_zi
    ),
    "cannot be combined"
  )
  expect_error(
    drmTMB(
      bf(
        nb2_spatial ~ x +
          spatial(1 | site, coords = coords) +
          relmat(1 | id, Q = Q),
        sigma ~ 1
      ),
      family = nbinom2(),
      data = dat
    ),
    "Only one structured"
  )
  expect_error(
    drmTMB(
      bf(
        nb2_spatial ~ x + spatial(1 | site, coords = coords),
        sigma ~ 1,
        zi ~ 1
      ),
      family = nbinom2(),
      data = dat
    ),
    "Zero-inflated NB2 structured random effects"
  )
  expect_error(
    drmTMB(
      bf(
        nb2_known ~ x + relmat(1 | id, Q = Q),
        sigma ~ animal(1 | id, Ainv = Q)
      ),
      family = nbinom2(),
      data = dat
    ),
    "cannot be combined"
  )
})
