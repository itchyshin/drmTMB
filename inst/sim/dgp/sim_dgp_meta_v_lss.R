# Small, deterministic DGPs for the Arc 7B known-V heterogeneity ladder.
#
# The labels deliberately describe the fitted formula, rather than a claim that
# every latent component is separately identifiable in every small fixture:
# L    yi ~ x + meta_V(V = V)
# LS   L, sigma ~ z
# LSS  LS + (1 | study), sd(study) ~ z_study
# LSSS LSS + (1 | effect), sd(effect) ~ z_effect
# DH   L + (1 | study), sigma ~ z + (1 | study)

phase18_meta_v_lss_conditions <- function(
  layer = c("L", "LS", "LSS", "LSSS", "DH"),
  n_study = 12L,
  n_effect_per_study = 2L,
  n_rep_per_effect = 2L,
  known_v_type = c("vector", "dense")
) {
  out <- expand.grid(
    layer = layer, known_v_type = known_v_type,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  out$n_study <- as.integer(n_study)
  out$n_effect_per_study <- as.integer(n_effect_per_study)
  out$n_rep_per_effect <- as.integer(n_rep_per_effect)
  out
}

phase18_dgp_meta_v_lss_from_condition <- function(condition, seed = NULL, ...) {
  if (!is.data.frame(condition) || nrow(condition) != 1L) {
    stop("`condition` must be a one-row meta_V LSS condition.", call. = FALSE)
  }
  required <- c("layer", "n_study", "n_effect_per_study", "n_rep_per_effect", "known_v_type")
  if (!all(required %in% names(condition))) {
    stop("`condition` is missing required meta_V LSS design columns.", call. = FALSE)
  }
  do.call(phase18_dgp_meta_v_lss, c(
    as.list(condition[required]), list(seed = seed), list(...)
  ))
}

phase18_dgp_meta_v_lss <- function(
  n_study,
  n_effect_per_study = 2L,
  n_rep_per_effect = 2L,
  layer = c("L", "LS", "LSS", "LSSS", "DH"),
  known_v_type = c("vector", "dense"),
  beta_mu = c("(Intercept)" = 0.20, x = 0.45),
  beta_sigma = c("(Intercept)" = -1.10, z = 0.30),
  beta_sd_study = c("(Intercept)" = -1.00, z_study = 0.20),
  beta_sd_effect = c("(Intercept)" = -1.25, z_effect = 0.20),
  sd_sigma_study = 0.20,
  sampling_sd = 0.12,
  sampling_rho = 0,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_study, "n_study")
  layer <- match.arg(layer)
  known_v_type <- match.arg(known_v_type)
  n_effect_per_study <- phase18_meta_v_lss_effect_counts(
    n_effect_per_study, n_study
  )
  assert_positive_whole_number(n_rep_per_effect, "n_rep_per_effect")
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  beta_sigma <- phase18_named_pair(
    beta_sigma, c("(Intercept)", "z"), "beta_sigma"
  )
  beta_sd_study <- phase18_named_pair(
    beta_sd_study, c("(Intercept)", "z_study"), "beta_sd_study"
  )
  beta_sd_effect <- phase18_named_pair(
    beta_sd_effect, c("(Intercept)", "z_effect"), "beta_sd_effect"
  )
  assert_phase18_positive_number(sd_sigma_study, "sd_sigma_study")
  assert_phase18_positive_number(sampling_sd, "sampling_sd")
  assert_phase18_correlation(sampling_rho, "sampling_rho")
  if (known_v_type == "vector" && !identical(unname(sampling_rho), 0)) {
    stop("`sampling_rho` must be 0 for vector known-V simulations.", call. = FALSE)
  }

  draw <- function() {
    study_id <- rep(seq_len(n_study), times = n_effect_per_study * n_rep_per_effect)
    n <- length(study_id)
    effect_study <- rep(seq_len(n_study), times = n_effect_per_study)
    effect_within_study <- unlist(lapply(n_effect_per_study, seq_len), use.names = FALSE)
    effect_id <- rep(seq_along(effect_study), each = n_rep_per_effect)
    x <- stats::rnorm(n)
    z <- stats::rnorm(n)
    z_study <- stats::rnorm(n_study)
    z_effect_level <- stats::rnorm(length(effect_id) / n_rep_per_effect)
    z_effect <- rep(z_effect_level, each = n_rep_per_effect)
    log_sigma <- unname(beta_sigma[["(Intercept)"]] + beta_sigma[["z"]] * z)
    if (layer == "L") {
      log_sigma <- rep(unname(beta_sigma[["(Intercept)"]]), n)
    }
    sd_study <- exp(unname(
      beta_sd_study[["(Intercept)"]] + beta_sd_study[["z_study"]] * z_study
    ))
    study_effect <- if (layer %in% c("LSS", "LSSS")) {
      stats::rnorm(n_study, sd = sd_study)
    } else if (identical(layer, "DH")) {
      stats::rnorm(n_study, sd = exp(unname(beta_sd_study[["(Intercept)"]])))
    } else {
      rep(0, n_study)
    }
    sd_effect <- exp(unname(
      beta_sd_effect[["(Intercept)"]] + beta_sd_effect[["z_effect"]] * z_effect_level
    ))
    effect_effect <- if (identical(layer, "LSSS")) {
      rep(stats::rnorm(length(effect_id) / n_rep_per_effect, sd = sd_effect),
        each = n_rep_per_effect)
    } else {
      rep(0, n)
    }
    sigma_study_effect <- if (identical(layer, "DH")) {
      stats::rnorm(n_study, sd = sd_sigma_study)
    } else {
      rep(0, n_study)
    }
    log_sigma <- log_sigma + sigma_study_effect[study_id]
    sigma <- exp(log_sigma)
    mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x) +
      study_effect[study_id] + effect_effect
    V <- phase18_make_meta_v(n, known_v_type, sampling_sd, sampling_rho)
    yi <- mu + phase18_draw_known_v_error(V) + stats::rnorm(n, sd = sigma)

    dat <- data.frame(
      yi = yi, x = x, z = z, z_study = z_study[study_id], z_effect = z_effect,
      study = factor(study_id),
      effect = factor(paste(effect_study, effect_within_study, sep = ":")[effect_id]),
      mu = mu, sigma = sigma,
      sampling_var = if (is.matrix(V)) diag(V) else V,
      cell_id = cell_id, replicate = replicate, stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "meta_v_lss", layer = layer, beta_mu = beta_mu,
      beta_sigma = beta_sigma, beta_sd_study = beta_sd_study,
      beta_sd_effect = beta_sd_effect, sd_sigma_study = sd_sigma_study,
      n_study = n_study, n_effect_per_study = n_effect_per_study,
      n_rep_per_effect = n_rep_per_effect,
      n_effect = n, known_v_type = known_v_type, sampling_sd = sampling_sd,
      sampling_rho = sampling_rho
    )
    attr(dat, "V") <- V
    dat
  }
  if (is.null(seed)) draw() else phase18_with_seed(seed, draw)
}

phase18_meta_v_lss_effect_counts <- function(n_effect_per_study, n_study) {
  if (length(n_effect_per_study) == 1L) {
    assert_positive_whole_number(n_effect_per_study, "n_effect_per_study")
    return(rep(as.integer(n_effect_per_study), n_study))
  }
  if (length(n_effect_per_study) != n_study || any(!is.finite(n_effect_per_study)) ||
      any(n_effect_per_study < 1) || any(n_effect_per_study != as.integer(n_effect_per_study))) {
    stop("`n_effect_per_study` must be one positive integer or one per study.", call. = FALSE)
  }
  as.integer(n_effect_per_study)
}
