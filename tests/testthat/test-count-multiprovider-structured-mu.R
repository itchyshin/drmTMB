# Row 105 (M5): simultaneous multi-provider structured mu in a count family.
#
# `spatial(1 | site, coords) + relmat(1 | id, Q)` in an NB2 mean, on a CROSSED
# site x id design so the two structured fields are jointly identifiable (the
# standard spatial-autocorrelation + relatedness setup). The engine currently
# rejects >1 structured mu type pre-optimization
# (`select_count_mu_structured_term`, R/drmTMB.R:7013). This test fixes the
# admission target: the crossed two-provider model BUILDS and surfaces BOTH
# structured SD/ranef fields, each a direct profile target.

r105_crossed_count_data <- function(n_site = 8L, n_id = 10L, n_rep = 4L,
                                    sd_spatial = 0.45, sd_relmat = 0.40,
                                    sigma_nb2 = 0.35, seed = 20260705L) {
  set.seed(seed)
  sites <- paste0("s", seq_len(n_site))
  ids <- paste0("g", seq_len(n_id))

  # Spatial covariance from a coordinate GMRF precision over sites.
  theta <- seq(0, 1.75 * pi, length.out = n_site)
  coords <- data.frame(x = cos(theta), y = sin(theta))
  rownames(coords) <- sites
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = sites, group = "site"
  )
  spatial_cov <- solve(as.matrix(precision$precision))
  spatial_effect <- as.vector(
    t(chol(spatial_cov)) %*% stats::rnorm(n_site, sd = sd_spatial)
  )
  names(spatial_effect) <- sites

  # Relatedness covariance K over ids (AR(1)-style); relmat() takes Q = K^{-1}.
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(ids, ids)
  Q <- solve(K)
  relmat_effect <- as.vector(
    t(chol(K)) %*% stats::rnorm(n_id, sd = sd_relmat)
  )
  names(relmat_effect) <- ids

  # Crossed design: every (site, id) pair, n_rep times -> fields separable.
  grid <- expand.grid(
    site = sites, id = ids, rep = seq_len(n_rep),
    stringsAsFactors = FALSE
  )
  x <- stats::rnorm(nrow(grid))
  eta <- 0.65 - 0.20 * x + spatial_effect[grid$site] + relmat_effect[grid$id]
  data <- data.frame(
    y = stats::rnbinom(nrow(grid), size = 1 / sigma_nb2^2, mu = exp(eta)),
    x = x, site = grid$site, id = grid$id
  )
  list(
    data = data, coords = coords, Q = Q,
    truth = c(
      sd_spatial = sd_spatial, sd_relmat = sd_relmat, sigma_nb2 = sigma_nb2
    ),
    beta_mu = c(`(Intercept)` = 0.65, x = -0.20),
    spatial_effect = spatial_effect,
    relmat_effect = relmat_effect
  )
}

nb2_spatial_relmat_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  eta_mu <- eta_mu + data$phylo_mu_value[, 1L] *
    par$u_phylo[data$phylo_mu_node_index + 1L]
  eta_mu <- eta_mu + data$phylo_mu2_value[, 1L] *
    par$u_phylo2[data$phylo_mu2_node_index + 1L]
  spatial_quadratic <- sum(par$u_phylo * as.vector(data$Q_phylo %*% par$u_phylo))
  relmat_quadratic <- sum(par$u_phylo2 * as.vector(data$Q_phylo2 %*% par$u_phylo2))
  structured_prior <- 0.5 * (
    nrow(data$Q_phylo) * log(2 * pi) +
      2 * nrow(data$Q_phylo) * par$log_sd_phylo -
      data$log_det_Q_phylo + exp(-2 * par$log_sd_phylo) * spatial_quadratic
  ) + 0.5 * (
    nrow(data$Q_phylo2) * log(2 * pi) +
      2 * nrow(data$Q_phylo2) * par$log_sd_phylo2 -
      data$log_det_Q_phylo2 + exp(-2 * par$log_sd_phylo2) * relmat_quadratic
  )
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma)
  observed <- as.logical(data$observed_y)
  structured_prior - sum(data$weights[observed] * stats::dnbinom(
    data$y[observed], size = exp(-2 * log_sigma[observed]),
    mu = exp(eta_mu[observed]), log = TRUE
  ))
}

test_that("nbinom2 mu builds simultaneous crossed spatial + relmat fields", {
  sim <- r105_crossed_count_data()
  coords <- sim$coords
  Q <- sim$Q
  fit <- suppressWarnings(drmTMB(
    bf(
      y ~ x +
        spatial(1 | site, coords = coords) +
        relmat(1 | id, Q = Q),
      sigma ~ 1
    ),
    family = nbinom2(),
    data = sim$data,
    control = drm_control(
      se = FALSE, optimizer = list(eval.max = 500, iter.max = 500)
    )
  ))

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  # Both structured SDs surface, both positive.
  expect_setequal(
    names(fit$sdpars$mu), c("spatial(1 | site)", "relmat(1 | id)")
  )
  expect_true(all(unname(fit$sdpars$mu) > 0))
  # Both structured random-effect blocks surface.
  expect_true(all(c("spatial_mu", "relmat_mu") %in% names(ranef(fit))))
  # Both SDs are direct profile targets (the pdHess=FALSE routing doctrine).
  targets <- profile_targets(fit)
  sd_rows <- targets[startsWith(targets$parm, "sd:mu:"), ]
  expect_true(
    all(
      c("sd:mu:spatial(1 | site)", "sd:mu:relmat(1 | id)") %in% sd_rows$parm
    )
  )
})

test_that("NB2 spatial plus relmat response mask has oracle and recovery evidence", {
  sim <- r105_crossed_count_data(n_rep = 20L, seed = 2026081772L)
  dat <- sim$data
  dat$y[seq(1L, nrow(dat), by = 20L)] <- NA_integer_
  observed <- !is.na(dat$y)
  coords <- sim$coords
  Q <- sim$Q
  formula <- bf(
    y ~ x + spatial(1 | site, coords = coords) + relmat(1 | id, Q = Q),
    sigma ~ 1
  )
  fit_masked <- drmTMB(
    formula, family = nbinom2(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = nbinom2(), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), nb2_spatial_relmat_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)),
    numDeriv::grad(obj$fn, probe), tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  conditional_intercept <- sim$beta_mu[["(Intercept)"]] +
    mean(sim$spatial_effect) + mean(sim$relmat_effect)
  expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - conditional_intercept), 0.30)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.15)
  expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - log(sim$truth[["sigma_nb2"]])), 0.16)
  expect_lt(abs(fit_masked$sdpars$mu[["spatial(1 | site)"]] - sim$truth[["sd_spatial"]]), 0.22)
  expect_lt(abs(fit_masked$sdpars$mu[["relmat(1 | id)"]] - sim$truth[["sd_relmat"]]), 0.28)
})
