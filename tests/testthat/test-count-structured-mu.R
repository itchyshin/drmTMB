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

test_that("count structured mu keeps planned neighboring routes closed", {
  sim <- new_count_structured_mu_data(n_level = 6L, n_each = 4L)
  dat <- sim$data
  coords <- sim$coords
  Q <- sim$Q

  expect_error(
    drmTMB(
      bf(poisson_spatial ~ x + spatial(1 + x | site, coords = coords)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "q=1 random intercepts"
  )
  expect_error(
    drmTMB(
      bf(poisson_spatial ~ x + spatial(1 | p | site, coords = coords)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "unlabelled q=1"
  )
  expect_error(
    drmTMB(
      bf(poisson_spatial ~ x + spatial(1 | site, coords = coords) + (1 | id)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "cannot be combined"
  )
  expect_error(
    drmTMB(
      bf(poisson_spatial ~ x + spatial(1 | site, coords = coords), zi ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Zero-inflated Poisson structured random effects"
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
    "Structured non-Gaussian paths"
  )
})
