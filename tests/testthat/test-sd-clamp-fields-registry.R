# G1 conditions C4 and C7 (docs/dev-log/general-sd-regression/
# g1-joint-contract-review-20261101.md).
#
# C4: every direct-SD block REPORTs the raw log(SD) linear predictor
# (log_sd_{mu,sigma,phylo,phylo2}_group) and applies the clamp where the
# likelihood forms sd_*_group. The fit-time clamp-hit check, check_drm() and
# the start-value check must therefore look at all four fields.
# C7: drm_structured_mu_random_effect_draws() decides "modelled SD" from the SD
# registry, never from the presence of an `sdpars` entry.
#
# Tolerances are fixed before the first run: report equalities at 1e-10 (pure
# arithmetic on one double, tanh), draw equalities at 1e-12.

sdr_band <- c(-2, 2)
sdr_clamped_four <- 2 + 3 * tanh((4 - 2) / 3)

sdr_gamma_sigma_sd_fit <- function() {
  set.seed(20261201L)
  n_id <- 20L
  n_g <- 16L
  n <- 240L
  id_i <- c(seq_len(n_id), sample(n_id, n - n_id, TRUE))
  g_i <- c(seq_len(n_g), sample(n_g, n - n_g, TRUE))
  w <- as.numeric(scale(sin(seq_len(n_id) * 1.7)))
  z <- as.numeric(scale(cos(seq_len(n_g) * 0.9 + 1)))
  u <- stats::rnorm(n_id, sd = exp(log(0.45) + 0.7 * w))
  v <- stats::rnorm(n_g, sd = exp(log(0.35) - 0.8 * z))
  x <- stats::rnorm(n)
  mu <- exp(0.3 + 0.3 * x + u[id_i])
  sg <- exp(-0.7 + v[g_i])
  d <- data.frame(
    y = stats::rgamma(n, shape = 1 / sg^2, scale = mu * sg^2),
    x = x,
    id = factor(sprintf("g%02d", id_i)),
    g = factor(sprintf("s%02d", g_i)),
    w = w[id_i],
    z = z[g_i]
  )
  drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g),
       sd(id) ~ w, sd(g, dpar = "sigma") ~ z),
    family = Gamma(link = "log"), data = d,
    control = drm_control(se = FALSE, logsigma_clamp = sdr_band)
  )
}

sdr_expect_latent_clamp_diagnostics <- function(fit, report, field) {
  spec <- fit$model
  expect_true(field %in% drmTMB:::drm_active_logsigma_clamp_fields(spec))
  info <- drmTMB:::drm_logsigma_clamp_active(
    report, spec$tmb_data,
    fields = drmTMB:::drm_active_logsigma_clamp_fields(spec)
  )
  expect_equal(info$arm, "upper")
  expect_equal(info$field, field)
  expect_equal(info$kind, "latent random-effect SD")
  # The fit-time warning and check_drm() read the same report.
  obj <- list(report = function(...) report)
  expect_warning(
    drmTMB:::drm_warn_if_clamp_active(obj, spec),
    "latent random-effect",
    class = "drmTMB_clamp_active_warning"
  )
  row <- drmTMB:::check_logsigma_clamp_active(
    list(model = spec, obj = obj, tmb_state = list(last.par.best = 0))
  )
  expect_equal(row$status, "warning")
  expect_match(row$message, "latent random-effect SD", fixed = TRUE)
}

test_that("registry lists every direct-SD block's raw log(SD) field", {
  tmb_data <- list(use_logsigma_clamp = 1L, logsigma_clamp = c(-2, 2, 3))
  spec <- list(
    model_type = "binomial", tmb_data = tmb_data,
    random_scale = list(
      mu = list(n_models = 1L), phylo = list(n_models = 1L),
      phylo2 = list(n_models = 1L), sigma = list(n_models = 1L)
    )
  )
  expect_setequal(
    drmTMB:::drm_active_logsigma_clamp_fields(spec),
    c("log_sd_mu_group", "log_sd_phylo_group", "log_sd_phylo2_group",
      "log_sd_sigma_group")
  )
  # Blocks without a direct-SD model stay out of the list.
  spec$random_scale$sigma$n_models <- 0L
  spec$random_scale$phylo2$n_models <- 0L
  expect_setequal(
    drmTMB:::drm_active_logsigma_clamp_fields(spec),
    c("log_sd_mu_group", "log_sd_phylo_group")
  )
  # Each new field is classified as a latent SD, not residual sigma.
  for (field in c("log_sd_sigma_group", "log_sd_phylo2_group")) {
    report <- stats::setNames(list(2.6), field)
    info <- drmTMB:::drm_logsigma_clamp_active(
      report, tmb_data, fields = field
    )
    expect_equal(info$kind, "latent random-effect SD")
    expect_equal(info$arm, "upper")
  }
})

test_that("a sigma SD predictor outside the band triggers the clamp-hit warning", {
  skip_on_cran()
  fit <- sdr_gamma_sigma_sd_fit()
  expect_equal(fit$opt$convergence, 0L)
  perturbed <- fit$tmb_state$last.par.best
  idx <- which(names(perturbed) == "beta_sd_sigma")
  expect_length(idx, 2L)
  perturbed[idx] <- c(4, 0)
  report <- fit$obj$report(perturbed)

  # One reporting contract: raw log SD in REPORT, clamped inside sd_sigma_group.
  expect_equal(
    unname(report$log_sd_sigma_group),
    rep(4, length(report$log_sd_sigma_group)),
    tolerance = 1e-10
  )
  expect_equal(
    unname(log(report$sd_sigma_group)),
    rep(sdr_clamped_four, length(report$sd_sigma_group)),
    tolerance = 1e-10
  )
  # Inflating the sigma-effect SD also scales the sigma random effect, so the
  # residual log_sigma moves out of the band as well and would be the reported
  # maximum. Drop it to isolate the latent SD field under test.
  sd_only <- report[!names(report) %in% c("log_sigma", "log_sigma1", "log_sigma2")]
  sdr_expect_latent_clamp_diagnostics(fit, sd_only, "log_sd_sigma_group")

  # The start-value check covers the sigma SD coefficients too.
  expect_warning(
    drmTMB:::drm_warn_if_start_saturates_logsigma_clamp(
      fit$model, list(beta_sd_sigma = c(4, 0))
    ),
    "latent random-effect",
    class = "drmTMB_start_clamp_saturated_warning"
  )
  expect_no_warning(
    drmTMB:::drm_warn_if_start_saturates_logsigma_clamp(
      fit$model, list(beta_sd_sigma = c(0.5, 0))
    )
  )
})

test_that("a second structured field's SD predictor outside the band is reported raw and detected", {
  skip_on_cran()
  skip_if_not_installed("ape")
  set.seed(20261202L)
  n_tip <- 16L
  n_site <- 20L
  n_rep <- 3L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  site_levels <- paste0("site_", seq_len(n_site))
  coords <- cbind(
    east = seq(0, 1, length.out = n_site),
    north = sin(seq(0, 2 * pi, length.out = n_site))
  )
  rownames(coords) <- site_levels
  z_tree <- sample(rep(c(-1, 1), length.out = n_tip))
  z_site <- sample(rep(c(-1, 1), length.out = n_site))
  design <- expand.grid(
    replicate = seq_len(n_rep), site_index = seq_len(n_site),
    tip_index = seq_len(n_tip)
  )
  dat <- data.frame(
    y = stats::rbinom(nrow(design), 1L, 0.5),
    x = stats::rnorm(nrow(design)),
    species = factor(tree$tip.label[design$tip_index], levels = tree$tip.label),
    site = factor(site_levels[design$site_index], levels = site_levels),
    z_tree = z_tree[design$tip_index],
    z_site = z_site[design$site_index]
  )
  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree) +
        spatial(1 | site, coords = coords),
      sd(species, level = "phylogenetic") ~ z_tree,
      sd(site, level = "spatial") ~ z_site
    ),
    family = stats::binomial(link = "logit"), data = dat,
    control = drm_control(se = FALSE, logsigma_clamp = sdr_band)
  )
  expect_s3_class(fit, "drmTMB")
  perturbed <- fit$tmb_state$last.par.best
  idx <- which(names(perturbed) == "beta_sd_mu")
  expect_length(idx, 4L)
  perturbed[idx] <- c(0, 0, 4, 0)
  report <- fit$obj$report(perturbed)

  expect_equal(
    unname(report$log_sd_phylo2_group),
    rep(4, length(report$log_sd_phylo2_group)),
    tolerance = 1e-10
  )
  expect_equal(
    unname(log(report$sd_phylo2_group)),
    rep(sdr_clamped_four, length(report$sd_phylo2_group)),
    tolerance = 1e-10
  )
  # The first field was left at log SD 0, inside the band and raw as well.
  expect_equal(
    unname(report$log_sd_phylo_group),
    rep(0, length(report$log_sd_phylo_group)),
    tolerance = 1e-10
  )
  sdr_expect_latent_clamp_diagnostics(fit, report, "log_sd_phylo2_group")
  expect_warning(
    drmTMB:::drm_warn_if_start_saturates_logsigma_clamp(
      fit$model, list(beta_sd_mu = c(0, 0, 4, 0))
    ),
    "latent random-effect",
    class = "drmTMB_start_clamp_saturated_warning"
  )
})

# C7 fixture: NB2 relmat slope SD fit, small.
sdr_relmat_fixture <- function(n_id = 12L, n_each = 10L) {
  set.seed(20261203L)
  id_levels <- paste0("id", seq_len(n_id))
  K <- 1.7 * 0.45^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(K) <- list(id_levels, id_levels)
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_id), id_levels)
  sd_id <- exp(log(0.7) + 0.4 * z_id)
  slope <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) * sd_id
  names(slope) <- id_levels
  id <- factor(rep(id_levels, each = n_each), levels = id_levels)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
  eta <- 1.1 + 0.2 * x + slope[as.character(id)] * x
  data <- data.frame(
    y = stats::rnbinom(length(eta), mu = exp(eta), size = 1 / 0.3^2),
    id = id, x = x, z = unname(z_id[as.character(id)])
  )
  list(data = data, K = K)
}

sdr_captured_sd <- function(fit) {
  captured <- NULL
  testthat::local_mocked_bindings(
    drm_fresh_structured_mu_values = function(phylo_mu, sd) {
      captured <<- sd
      rep(0, phylo_mu$n_re)
    },
    .package = "drmTMB"
  )
  drmTMB:::drm_structured_mu_random_effect_draws(fit)
  captured
}

test_that("marginal structured draws take the modelled SD from the registry, not sdpars", {
  skip_on_cran()
  fx <- sdr_relmat_fixture()
  K <- fx$K
  fit <- drmTMB(
    bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1,
       sd(id, level = "relmat") ~ z),
    family = nbinom2(), data = fx$data, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  phylo_mu <- fit$model$structured$phylo_mu
  expected <- unname(
    predict(fit, dpar = "sd_relmat(id)")[phylo_mu$node_labels]
  )
  expect_true(all(is.finite(expected)) && length(unique(expected)) > 1L)
  expect_equal(sdr_captured_sd(fit), expected, tolerance = 1e-12)

  # An unmodelled constant SD for another endpoint, filed under the same key
  # and label, coexists with the modelled one and must not be used.
  sd_key <- unique(drmTMB:::phylo_mu_endpoint_dpars(phylo_mu))
  label <- drmTMB:::phylo_mu_sd_labels(phylo_mu, fit$model$model_type)
  decoy <- fit
  decoy$sdpars[[sd_key]] <- c(
    decoy$sdpars[[sd_key]], stats::setNames(rep(99, length(label)), label)
  )
  expect_equal(unname(decoy$sdpars[[sd_key]][label]), rep(99, length(label)))
  expect_equal(sdr_captured_sd(decoy), expected, tolerance = 1e-12)

  # Through the public path as well: draws under re.form = NA stay finite and
  # reproducible with the decoy present.
  sim_a <- simulate(decoy, nsim = 2L, re.form = NA, seed = 20261204L)
  sim_b <- simulate(fit, nsim = 2L, re.form = NA, seed = 20261204L)
  expect_identical(sim_a, sim_b)
})

test_that("an unmodelled constant structured SD is still read from sdpars", {
  skip_on_cran()
  fx <- sdr_relmat_fixture()
  K <- fx$K
  fit <- drmTMB(
    bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1),
    family = nbinom2(), data = fx$data, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  phylo_mu <- fit$model$structured$phylo_mu
  sd_key <- unique(drmTMB:::phylo_mu_endpoint_dpars(phylo_mu))
  label <- drmTMB:::phylo_mu_sd_labels(phylo_mu, fit$model$model_type)
  constant <- unname(fit$sdpars[[sd_key]][label])
  expect_true(length(constant) == 1L && is.finite(constant) && constant > 0)
  expect_equal(sdr_captured_sd(fit), constant, tolerance = 1e-12)

  # Neither a registry entry nor a constant entry: explicit refusal.
  broken <- fit
  broken$sdpars[[sd_key]] <- NULL
  expect_error(
    drmTMB:::drm_structured_mu_random_effect_draws(broken),
    "could not find a unique fitted structured-effect SD"
  )
})
