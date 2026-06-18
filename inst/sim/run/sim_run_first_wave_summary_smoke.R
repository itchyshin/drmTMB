phase18_run_first_wave_summary_smoke <- function(
  output_dir,
  n_rep = 1L,
  master_seed = 20260530L,
  cores = 1L,
  backend = "none",
  overwrite = FALSE,
  render = TRUE,
  require_complete = TRUE,
  notes = NULL
) {
  phase18_assert_first_wave_summary_smoke_inputs(
    output_dir = output_dir,
    n_rep = n_rep,
    master_seed = master_seed,
    notes = notes
  )
  if (is.null(notes)) {
    notes <- paste0(
      "Phase 18 first-wave summary smoke with n_rep = ",
      as.integer(n_rep),
      "."
    )
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)

  gaussian <- phase18_write_gaussian_ls_grid_outputs(
    output_dir = file.path(output_dir, "gaussian-ls"),
    conditions = phase18_gaussian_ls_conditions(
      n = 100L,
      sigma_slope = 0.20,
      collinearity = 0.10
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 1L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  meta <- phase18_write_meta_v_grid_outputs(
    output_dir = file.path(output_dir, "meta-v"),
    conditions = phase18_meta_v_conditions(
      n_study = 32L,
      known_v_type = c("vector", "dense"),
      sigma = 0.25,
      sampling_sd = 0.14,
      sampling_rho = c(0, 0.20)
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 2L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  count <- phase18_write_count_mu_re_grid_outputs(
    output_dir = file.path(output_dir, "count-mu-re"),
    poisson_conditions = phase18_poisson_mu_re_conditions(
      n_group = 36L,
      n_per_group = 9L
    ),
    nbinom2_conditions = phase18_nbinom2_mu_re_conditions(
      n_group = 44L,
      n_per_group = 10L
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 3L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  truncated_nbinom2_mu_random_intercept <-
    phase18_write_truncated_nbinom2_mu_ri_grid_outputs(
      output_dir = file.path(output_dir, "truncated-nb2-mu-ri"),
      conditions = phase18_truncated_nbinom2_mu_ri_conditions(
        n_group = 28L,
        n_per_group = 8L,
        beta_sigma_intercept = -0.65,
        beta_sigma_z = 0.15,
        sd_intercept = 0.35
      ),
      n_rep = as.integer(n_rep),
      master_seed = as.integer(master_seed) + 14L,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  proportion <- phase18_write_proportion_fe_grid_outputs(
    output_dir = file.path(output_dir, "proportion-fe"),
    conditions = phase18_proportion_fe_conditions(
      family = c("beta", "beta_binomial"),
      n = 260L,
      trial_min = 10L,
      trial_max = 18L,
      beta_sigma_intercept = -0.90,
      beta_sigma_z = 0.20,
      rho_xz = 0.20
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 7L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  bounded_response_mu_random_intercept <-
    phase18_write_bounded_response_mu_ri_grid_outputs(
      output_dir = file.path(output_dir, "bounded-response-mu-ri"),
      conditions = phase18_bounded_response_mu_ri_conditions(
        family = c("beta", "beta_binomial"),
        n_group = 28L,
        n_per_group = 8L,
        trial_min = 14L,
        trial_max = 24L,
        beta_sigma_intercept = -0.95,
        beta_sigma_z = 0.15,
        sd_intercept = 0.45,
        rho_xz = 0.20
      ),
      n_rep = as.integer(n_rep),
      master_seed = as.integer(master_seed) + 11L,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  positive_continuous <- phase18_write_positive_continuous_fe_grid_outputs(
    output_dir = file.path(output_dir, "positive-continuous-fe"),
    conditions = phase18_positive_continuous_fe_conditions(
      family = c("lognormal", "gamma"),
      n = 260L,
      beta_sigma_intercept = -0.75,
      beta_sigma_z = 0.20,
      rho_xz = 0.20
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 8L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  tweedie_fixed_effect <- phase18_write_tweedie_fe_grid_outputs(
    output_dir = file.path(output_dir, "tweedie-fe"),
    conditions = phase18_tweedie_fe_conditions(
      n = 260L,
      zero_regime = c("low", "high"),
      rho_xz = 0.20
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 15L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  positive_continuous_mu_random_intercept <-
    phase18_write_positive_continuous_mu_ri_grid_outputs(
      output_dir = file.path(output_dir, "positive-continuous-mu-ri"),
      conditions = phase18_positive_continuous_mu_ri_conditions(
        family = c("lognormal", "gamma"),
        n_group = 28L,
        n_per_group = 8L,
        beta_sigma_intercept = -0.75,
        beta_sigma_z = 0.18,
        sd_intercept = 0.45,
        rho_xz = 0.20
      ),
      n_rep = as.integer(n_rep),
      master_seed = as.integer(master_seed) + 12L,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  student_mu_random_intercept <- phase18_write_student_mu_ri_grid_outputs(
    output_dir = file.path(output_dir, "student-mu-ri"),
    conditions = phase18_student_mu_ri_conditions(
      n_group = 28L,
      n_per_group = 8L,
      beta_sigma_intercept = -0.42,
      beta_sigma_z = 0.18,
      beta_nu_intercept = log(7),
      sd_intercept = 0.45,
      rho_xz = 0.20
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 13L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  student_shape <- phase18_write_student_shape_grid_outputs(
    output_dir = file.path(output_dir, "student-shape"),
    conditions = phase18_student_shape_conditions(
      n = 240L,
      nu_intercept = log(6),
      nu_slope = 0.20,
      sigma_slope = 0.20,
      rho_xw = 0.1
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 16L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  ordinal <- phase18_write_ordinal_fe_grid_outputs(
    output_dir = file.path(output_dir, "ordinal-fe"),
    conditions = phase18_ordinal_fe_conditions(
      n = 320L,
      n_category = c(3L, 5L),
      beta_mu_x = 0.65,
      cutpoint_pattern = "balanced"
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 9L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  zero_one_beta <- phase18_write_zero_one_beta_fe_grid_outputs(
    output_dir = file.path(output_dir, "zero-one-beta-fe"),
    conditions = phase18_zero_one_beta_fe_conditions(
      n = 360L,
      beta_sigma_intercept = -0.80,
      beta_sigma_z = 0.15,
      beta_zoi_intercept = -1.20,
      beta_zoi_w = 0.30,
      beta_coi_intercept = 0.10,
      beta_coi_v = -0.30,
      rho_xz = 0.20
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 10L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  gaussian_mu_random_slope <- phase18_write_gaussian_mu_rs_grid_outputs(
    output_dir = file.path(output_dir, "gaussian-mu-random-slope"),
    conditions = phase18_gaussian_mu_rs_conditions(
      n_group = 24L,
      n_per_group = 7L
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 4L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  gaussian_sigma_random_slope <- phase18_write_gaussian_sigma_rs_grid_outputs(
    output_dir = file.path(output_dir, "gaussian-sigma-random-slope"),
    conditions = phase18_gaussian_sigma_rs_conditions(
      n_group = 32L,
      n_per_group = 8L
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 5L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  spatial_mu_slope <- phase18_write_spatial_mu_slope_grid_outputs(
    output_dir = file.path(output_dir, "spatial-mu-slope"),
    conditions = phase18_spatial_mu_slope_conditions(
      n_site = 12L,
      n_each = 8L
    ),
    n_rep = as.integer(n_rep),
    master_seed = as.integer(master_seed) + 6L,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  report <- phase18_render_first_wave_summary_report(
    output_dir = file.path(output_dir, "first-wave-summary"),
    grid_outputs = list(
      gaussian,
      meta,
      count,
      truncated_nbinom2_mu_random_intercept,
      proportion,
      bounded_response_mu_random_intercept,
      positive_continuous,
      tweedie_fixed_effect,
      positive_continuous_mu_random_intercept,
      student_mu_random_intercept,
      student_shape,
      ordinal,
      zero_one_beta,
      gaussian_mu_random_slope,
      gaussian_sigma_random_slope,
      spatial_mu_slope
    ),
    overwrite = overwrite,
    render = render,
    require_complete = require_complete,
    notes = notes
  )
  parallel_summary <- phase18_first_wave_parallel_summary(
    gaussian = gaussian,
    meta = meta,
    count = count,
    truncated_nbinom2_mu_random_intercept = truncated_nbinom2_mu_random_intercept,
    proportion = proportion,
    bounded_response_mu_random_intercept = bounded_response_mu_random_intercept,
    positive_continuous = positive_continuous,
    tweedie_fixed_effect = tweedie_fixed_effect,
    positive_continuous_mu_random_intercept = positive_continuous_mu_random_intercept,
    student_mu_random_intercept = student_mu_random_intercept,
    student_shape = student_shape,
    ordinal = ordinal,
    zero_one_beta = zero_one_beta,
    gaussian_mu_random_slope = gaussian_mu_random_slope,
    gaussian_sigma_random_slope = gaussian_sigma_random_slope,
    spatial_mu_slope = spatial_mu_slope
  )
  paths <- list(
    parallel_summary_csv = file.path(
      output_dir,
      "first-wave-parallel-summary.csv"
    )
  )
  utils::write.csv(
    parallel_summary,
    paths$parallel_summary_csv,
    row.names = FALSE
  )

  list(
    surface = "phase18_first_wave_summary_smoke",
    output_dir = output_dir,
    paths = paths,
    gaussian = gaussian,
    meta = meta,
    count = count,
    truncated_nbinom2_mu_random_intercept = truncated_nbinom2_mu_random_intercept,
    proportion = proportion,
    bounded_response_mu_random_intercept = bounded_response_mu_random_intercept,
    positive_continuous = positive_continuous,
    tweedie_fixed_effect = tweedie_fixed_effect,
    positive_continuous_mu_random_intercept = positive_continuous_mu_random_intercept,
    student_mu_random_intercept = student_mu_random_intercept,
    student_shape = student_shape,
    ordinal = ordinal,
    zero_one_beta = zero_one_beta,
    gaussian_mu_random_slope = gaussian_mu_random_slope,
    gaussian_sigma_random_slope = gaussian_sigma_random_slope,
    spatial_mu_slope = spatial_mu_slope,
    report = report,
    parallel_summary = parallel_summary
  )
}

phase18_assert_first_wave_summary_smoke_inputs <- function(
  output_dir,
  n_rep,
  master_seed,
  notes
) {
  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  if (
    !is.numeric(n_rep) ||
      length(n_rep) != 1L ||
      !is.finite(n_rep) ||
      n_rep < 1L ||
      n_rep != as.integer(n_rep)
  ) {
    stop("`n_rep` must be one positive integer.", call. = FALSE)
  }
  if (
    !is.numeric(master_seed) ||
      length(master_seed) != 1L ||
      !is.finite(master_seed) ||
      master_seed != as.integer(master_seed)
  ) {
    stop("`master_seed` must be one integer.", call. = FALSE)
  }
  if (
    !is.null(notes) &&
      (!is.character(notes) || length(notes) != 1L || is.na(notes))
  ) {
    stop("`notes` must be NULL or one character string.", call. = FALSE)
  }
  invisible(TRUE)
}

phase18_first_wave_parallel_summary <- function(
  gaussian,
  meta,
  count,
  truncated_nbinom2_mu_random_intercept,
  proportion,
  bounded_response_mu_random_intercept,
  positive_continuous,
  tweedie_fixed_effect,
  positive_continuous_mu_random_intercept,
  student_mu_random_intercept,
  student_shape,
  ordinal,
  zero_one_beta,
  gaussian_mu_random_slope,
  gaussian_sigma_random_slope,
  spatial_mu_slope
) {
  out <- do.call(
    rbind,
    list(
      phase18_parallel_summary_row(
        "gaussian_ls_grid",
        gaussian$summary$run$parallel
      ),
      phase18_parallel_summary_row("meta_v_grid", meta$summary$run$parallel),
      phase18_parallel_summary_row(
        "poisson_mu_random_effect",
        count$summary$poisson$run$parallel
      ),
      phase18_parallel_summary_row(
        "nbinom2_mu_random_effect",
        count$summary$nbinom2$run$parallel
      ),
      phase18_parallel_summary_row(
        "truncated_nbinom2_mu_random_intercept_grid",
        truncated_nbinom2_mu_random_intercept$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "proportion_fixed_effect_grid",
        proportion$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "bounded_response_mu_random_intercept_grid",
        bounded_response_mu_random_intercept$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "positive_continuous_fixed_effect_grid",
        positive_continuous$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "tweedie_fixed_effect_grid",
        tweedie_fixed_effect$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "positive_continuous_mu_random_intercept_grid",
        positive_continuous_mu_random_intercept$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "student_mu_random_intercept_grid",
        student_mu_random_intercept$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "student_shape_grid",
        student_shape$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "ordinal_fixed_effect_grid",
        ordinal$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "zero_one_beta_fixed_effect_grid",
        zero_one_beta$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "gaussian_mu_random_slope_grid",
        gaussian_mu_random_slope$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "gaussian_sigma_random_slope_grid",
        gaussian_sigma_random_slope$summary$run$parallel
      ),
      phase18_parallel_summary_row(
        "spatial_mu_slope_grid",
        spatial_mu_slope$summary$run$parallel
      )
    )
  )
  row.names(out) <- NULL
  out
}

phase18_parallel_summary_row <- function(surface, parallel) {
  data.frame(
    surface = surface,
    backend = parallel$backend,
    requested_cores = parallel$requested_cores,
    cores = parallel$cores,
    stringsAsFactors = FALSE
  )
}
