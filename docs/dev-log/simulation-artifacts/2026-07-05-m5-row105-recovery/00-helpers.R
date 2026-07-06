# M5 row-105 crossed recovery ladder: helpers.
#
# Generalizes the RED-test DGP (`r105_crossed_count_data()` in
# tests/testthat/test-count-multiprovider-structured-mu.R) to a variable
# #levels rung n_site = n_id = n_lvl, holding total rows near a target by
# adjusting n_rep. The design is `expand.grid(site, id, rep)`: EVERY (site,
# id) pair appears, so the two structured fields (spatial over site, relmat
# over id) are jointly identifiable by construction (crossed, not nested).
#
# One control rung (`crossed = FALSE`) breaks the crossing (one id per site,
# i.e. id is a deterministic function of site) to demonstrate confounding:
# with no genuine crossing the two fields cannot be separated and (per the
# task brief) both SDs are expected to collapse/misbehave.

r105_crossed_data <- function(n_lvl = 10L, n_rep = 4L, sd_spatial = 0.45,
                              sd_relmat = 0.40, sigma_nb2 = 0.35,
                              seed = 20260705L, crossed = TRUE) {
  set.seed(seed)
  sites <- paste0("s", seq_len(n_lvl))
  ids <- paste0("g", seq_len(n_lvl))

  # Spatial covariance from a coordinate GMRF precision over sites (unit
  # circle placement, same shape as the RED-test DGP, any n_lvl).
  theta <- seq(0, 1.75 * pi, length.out = n_lvl)
  coords <- data.frame(x = cos(theta), y = sin(theta))
  rownames(coords) <- sites
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = sites, group = "site"
  )
  spatial_cov <- solve(as.matrix(precision$precision))
  spatial_effect <- as.vector(
    t(chol(spatial_cov)) %*% stats::rnorm(n_lvl, sd = sd_spatial)
  )
  names(spatial_effect) <- sites

  # Relatedness covariance K over ids (AR(1)-style); relmat() takes Q = K^-1.
  K <- outer(seq_len(n_lvl), seq_len(n_lvl), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(ids, ids)
  Q <- solve(K)
  relmat_effect <- as.vector(
    t(chol(K)) %*% stats::rnorm(n_lvl, sd = sd_relmat)
  )
  names(relmat_effect) <- ids

  if (crossed) {
    # Crossed design: every (site, id) pair, n_rep times -> fields separable.
    grid <- expand.grid(
      site = sites, id = ids, rep = seq_len(n_rep),
      stringsAsFactors = FALSE
    )
  } else {
    # Non-crossed CONTROL: id is a deterministic function of site (id_i always
    # co-occurs with site_i), replicated n_rep * n_lvl times so nrow matches
    # the crossed rung. Site and id vary together -> NOT identifiable; this
    # rung is a labelled confounding demonstration, not a recovery target.
    grid <- data.frame(
      site = rep(sites, times = n_rep * n_lvl),
      id = rep(ids, times = n_rep * n_lvl),
      stringsAsFactors = FALSE
    )
  }

  x <- stats::rnorm(nrow(grid))
  eta <- 0.65 - 0.20 * x + spatial_effect[grid$site] + relmat_effect[grid$id]
  data <- data.frame(
    y = stats::rnbinom(nrow(grid), size = 1 / sigma_nb2^2, mu = exp(eta)),
    x = x, site = grid$site, id = grid$id
  )
  n_pairs <- nrow(unique(data[, c("site", "id")]))
  list(
    data = data, coords = coords, Q = Q, n_lvl = n_lvl, crossed = crossed,
    n_pairs = n_pairs, n_possible_pairs = n_lvl * n_lvl,
    truth = c(sd_spatial = sd_spatial, sd_relmat = sd_relmat,
              sigma_nb2 = sigma_nb2)
  )
}

# Fit the row-105 two-provider NB2 model. `coords`/`Q` are assigned into the
# calling frame under fixed names because `spatial()`/`relmat()` markers
# require bare-name arguments (not `$`-expressions) -- see
# parse_structured_marker_call().
r105_fit <- function(sim, control = drm_control(
                       se = TRUE, optimizer = list(eval.max = 800, iter.max = 800)
                     )) {
  coords <- sim$coords
  Q <- sim$Q
  drmTMB(
    bf(
      y ~ x +
        spatial(1 | site, coords = coords) +
        relmat(1 | id, Q = Q),
      sigma ~ 1
    ),
    family = nbinom2(),
    data = sim$data,
    control = control
  )
}

recovery_summary <- function(df, param_col, truth_col) {
  est <- df[[param_col]]
  truth <- df[[truth_col]]
  ok <- is.finite(est) & is.finite(truth)
  data.frame(
    n_seeds = sum(ok),
    mean_est = mean(est[ok]),
    truth = if (any(ok)) mean(truth[ok]) else NA_real_,
    bias = mean(est[ok] - truth[ok]),
    rmse = sqrt(mean((est[ok] - truth[ok])^2))
  )
}
