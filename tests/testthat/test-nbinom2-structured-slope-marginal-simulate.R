# Marginal simulation (`simulate(fit, re.form = NA)`) for native NB2
# structured slope-only SD fits (relmat and phylo providers).
#
# The marginal path redraws the structured effect as u ~ N(0, K), scales node i
# by the fitted per-level SD predicted from `sd(id, level = ...) ~ z`, and maps
# it onto rows through the slope design x
# (`drm_structured_mu_random_effect_draws()`). That helper is family-agnostic;
# the NB2 outcome draw is `rnbinom(size = 1 / sigma^2, mu = exp(eta))`. The only
# family-specific piece is the whitelist `supported_q1_structured_sd` in
# `drm_simulate_marginal_unsupported()`. These tests therefore pin
#   (1) the public contract: shape, finite non-negative integer counts,
#       reproducibility under a seed, and re.form = NULL still working;
#   (2) the moments of the fresh linear-predictor random effect: for row r on
#       node i the effect is x_r * sd_i * u_i, so its variance across draws is
#       x_r^2 * sd_i^2 * K_ii and its covariance between rows r, s is
#       x_r x_s sd_i sd_j K_ij.
#
# Tolerances are fixed before the first run. With R = 4000 draws the relative
# standard error of a variance estimate is sqrt(2 / (R - 1)) = 2.2% and that of
# a correlation is about 1.6%, so:
#   per-level variance ratio (empirical / expected) within 15% (about 6.7 SE,
#     covers the maximum over 30 levels);
#   pooled mean variance ratio within 4% of one;
#   ratio of mean variance between high-z and low-z levels within 10% of the
#     expected ratio (this fails if a constant SD replaced the modelled one:
#     the fitted z slope is about 0.4, i.e. a variance ratio of about 2.2);
#   empirical minus expected correlation between levels within 0.10 (about 6 SE
#     at the largest of 435 pairs).

nsm_fixture <- function(K, seed, n_each = 20L, dispersion = 0.3) {
  set.seed(seed)
  levels_id <- rownames(K)
  n_id <- length(levels_id)
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_id), levels_id)
  alpha <- c(`(Intercept)` = log(0.7), z = 0.4)
  sd_id <- exp(alpha[[1L]] + alpha[[2L]] * z_id[levels_id])
  slope <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) * sd_id
  names(slope) <- levels_id
  id <- factor(rep(levels_id, each = n_each), levels = levels_id)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
  eta <- 1.1 + 0.2 * x + slope[as.character(id)] * x
  data <- data.frame(
    y = stats::rnbinom(length(eta), mu = exp(eta), size = 1 / dispersion^2),
    id = id,
    x = x,
    z = unname(z_id[as.character(id)])
  )
  list(data = data, z_id = z_id)
}

# Checks the public simulate() contract and returns the link-scale marginal
# random-effect draws used by the same code path (one row per draw).
nsm_expect_marginal_contract <- function(fit, data, sd_name, seed) {
  expect_equal(fit$opt$convergence, 0L)
  expect_true(sd_name %in% names(fit$coefficients))

  sims <- simulate(fit, nsim = 25L, re.form = NA, seed = seed)
  expect_s3_class(sims, "data.frame")
  expect_equal(dim(sims), c(nrow(data), 25L))
  expect_equal(names(sims), paste0("sim_", seq_len(25L)))
  all_values <- unlist(sims, use.names = FALSE)
  expect_true(all(is.finite(all_values)))
  expect_true(all(all_values >= 0))
  expect_equal(all_values, round(all_values))
  # Fresh effects must make draws differ from one another.
  expect_gt(length(unique(sims$sim_1 - sims$sim_2)), 1L)

  again <- simulate(fit, nsim = 25L, re.form = NA, seed = seed)
  expect_identical(sims, again)

  conditional <- simulate(fit, nsim = 3L, re.form = NULL, seed = seed)
  expect_equal(dim(conditional), c(nrow(data), 3L))
  expect_true(all(unlist(conditional) >= 0))
  invisible(sims)
}

nsm_draw_effects <- function(fit, rows, n_draw, seed) {
  set.seed(seed)
  draws <- vapply(
    seq_len(n_draw),
    function(i) drmTMB:::drm_ordinary_random_effect_draws(fit)$mu[rows],
    numeric(length(rows))
  )
  draws
}

nsm_expect_moments <- function(fit, data, K, sd_name, seed, n_draw = 4000L) {
  levels_id <- rownames(K)
  # One row per level at x = 1 so the design multiplier is the same for all.
  rows <- vapply(
    levels_id,
    function(l) max(which(as.character(data$id) == l & data$x == max(data$x))),
    integer(1L)
  )
  expect_equal(unname(data$x[rows]), rep(1, length(levels_id)))
  sd_fit <- predict(fit, dpar = sd_name)[levels_id]
  expect_true(all(is.finite(sd_fit)) && all(sd_fit > 0))
  # The fitted SD must genuinely vary with z, otherwise the check is vacuous.
  expect_gt(max(sd_fit) / min(sd_fit), 1.2)

  expected_cov <- outer(sd_fit, sd_fit) * K
  expected_var <- diag(expected_cov)
  draws <- nsm_draw_effects(fit, rows, n_draw, seed)
  expect_equal(dim(draws), c(length(levels_id), n_draw))

  emp_var <- apply(draws, 1L, stats::var)
  ratio <- emp_var / expected_var
  expect_true(all(abs(ratio - 1) < 0.15), info = paste(round(range(ratio), 3), collapse = " to "))
  expect_lt(abs(mean(ratio) - 1), 0.04)
  # Zero mean: pooled across levels, standardised by the expected SD.
  expect_lt(abs(mean(rowMeans(draws) / sqrt(expected_var))), 4 / sqrt(n_draw))

  high <- data$z[rows] > 0
  expect_equal(
    mean(emp_var[high]) / mean(emp_var[!high]),
    mean(expected_var[high]) / mean(expected_var[!high]),
    tolerance = 0.10
  )

  emp_cor <- stats::cov2cor(stats::cov(t(draws)))
  expected_cor <- stats::cov2cor(expected_cov)
  expect_lt(max(abs(emp_cor - expected_cor)), 0.10)
  invisible(list(ratio = ratio, draws = draws))
}

test_that("NB2 relmat slope-SD fits simulate marginally with per-level SDs", {
  skip_on_cran()
  n_id <- 30L
  id_levels <- paste0("id", seq_len(n_id))
  order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  # Non-unit covariance scale detects accidental conversion to a correlation.
  K_base <- 1.7 * 0.45^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(K_base) <- list(id_levels, id_levels)
  K <- K_base[order, order]
  fx <- nsm_fixture(K, seed = 20261201L)

  fit <- drmTMB(
    bf(
      y ~ x + relmat(0 + x | id, K = K),
      sigma ~ 1,
      sd(id, level = "relmat") ~ z
    ),
    family = nbinom2(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  nsm_expect_marginal_contract(fit, fx$data, "sd_relmat(id)", seed = 20261202L)
  nsm_expect_moments(fit, fx$data, K, "sd_relmat(id)", seed = 20261203L)
})

test_that("NB2 phylo slope-SD fits simulate marginally with per-level SDs", {
  skip_on_cran()
  skip_if_not_installed("ape")
  set.seed(20261204L)
  n_species <- 30L
  tree <- ape::rcoal(n_species)
  tree$tip.label <- paste0("species_", seq_len(n_species))
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  K <- K[tree$tip.label, tree$tip.label]
  fx <- nsm_fixture(K, seed = 20261205L)
  fx$data$species <- fx$data$id

  fit <- drmTMB(
    bf(
      y ~ x + phylo(0 + x | species, tree = tree),
      sigma ~ 1,
      sd(species, level = "phylogenetic") ~ z
    ),
    family = nbinom2(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  nsm_expect_marginal_contract(
    fit, fx$data, "sd_phylo(species)", seed = 20261206L
  )
  nsm_expect_moments(
    fit, fx$data, K, "sd_phylo(species)", seed = 20261207L
  )
})
