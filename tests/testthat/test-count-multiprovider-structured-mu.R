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
    )
  )
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
