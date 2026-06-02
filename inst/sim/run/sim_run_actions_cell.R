phase18_actions_task_choices <- function() {
  c(
    "first_wave_summary",
    "interval_heavy_summary",
    "truncated_nbinom2_mu_random_intercept",
    "proportion_fixed_effect",
    "bounded_response_mu_random_intercept",
    "positive_continuous_fixed_effect",
    "tweedie_fixed_effect",
    "count_structured_q1",
    "positive_continuous_mu_random_intercept",
    "student_mu_random_intercept",
    "ordinal_fixed_effect",
    "zero_one_beta_fixed_effect",
    "correlation_block_status",
    "biv_gaussian_mu_slope",
    "spatial_mu_slope",
    "phylo_mu_slope",
    "animal_mu_slope",
    "relmat_mu_slope",
    "poisson_phylo_q1_formal",
    "nbinom2_phylo_q1_formal"
  )
}

phase18_actions_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  opts <- phase18_actions_parse_args(args)
  dry_run <- phase18_actions_bool(opts$dry_run, "dry-run")
  task <- phase18_actions_choice(
    opts$task,
    phase18_actions_task_choices(),
    "task"
  )
  output_dir <- opts$output_dir
  if (is.null(output_dir) || !nzchar(output_dir)) {
    output_dir <- file.path("inst", "sim", "results", "actions", task)
  }
  n_rep <- phase18_actions_positive_integer(opts$n_reps, "n-reps")
  cores <- phase18_actions_core_count(opts$cores, "cores")
  backend <- phase18_actions_choice(
    opts$backend,
    c("none", "multicore"),
    "backend"
  )
  master_seed <- phase18_actions_integer(opts$master_seed, "master-seed")
  overwrite <- phase18_actions_bool(opts$overwrite, "overwrite")
  render <- phase18_actions_bool(opts$render, "render")
  require_complete <- phase18_actions_bool(
    opts$require_complete,
    "require-complete"
  )
  notes <- opts$notes

  profile_parameters <- phase18_actions_character_vector(
    opts$profile_parameters
  )
  profile_level <- phase18_actions_probability(
    opts$profile_level,
    "profile-level"
  )
  condition_shard <- phase18_actions_positive_integer(
    opts$condition_shard,
    "condition-shard"
  )
  condition_shards <- phase18_actions_positive_integer(
    opts$condition_shards,
    "condition-shards"
  )
  condition_set <- phase18_actions_choice(
    opts$condition_set,
    c("all", "stable", "stable_watch", "boundary_stress"),
    "condition-set"
  )
  phase18_actions_validate_condition_shard(
    task = task,
    condition_shard = condition_shard,
    condition_shards = condition_shards
  )
  phase18_actions_validate_condition_set(
    task = task,
    condition_set = condition_set
  )
  bootstrap_nsim <- phase18_actions_nonnegative_integer(
    opts$bootstrap_nsim,
    "bootstrap-nsim"
  )
  bootstrap_cores <- phase18_actions_core_count(
    opts$bootstrap_cores,
    "bootstrap-cores"
  )
  bootstrap_backend <- phase18_actions_choice(
    opts$bootstrap_backend,
    c("none", "multicore"),
    "bootstrap-backend"
  )
  if (
    identical(backend, "multicore") &&
      identical(bootstrap_backend, "multicore") &&
      cores > 1L &&
      bootstrap_cores > 1L
  ) {
    stop(
      "Choose multicore for either the replicate layer or the bootstrap layer, ",
      "not both.",
      call. = FALSE
    )
  }

  if (dry_run) {
    phase18_actions_print_plan(
      task = task,
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      cores = cores,
      backend = backend,
      render = render,
      require_complete = require_complete,
      profile_parameters = profile_parameters,
      profile_level = profile_level,
      condition_shard = condition_shard,
      condition_shards = condition_shards,
      condition_set = condition_set,
      bootstrap_nsim = bootstrap_nsim,
      bootstrap_cores = bootstrap_cores,
      bootstrap_backend = bootstrap_backend
    )
    return(invisible(NULL))
  }

  phase18_actions_load_package()
  phase18_actions_source_dependencies(task)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (identical(task, "first_wave_summary")) {
    out <- phase18_run_first_wave_summary_smoke(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      cores = cores,
      backend = backend,
      overwrite = overwrite,
      render = render,
      require_complete = require_complete,
      notes = notes
    )
  } else if (identical(task, "interval_heavy_summary")) {
    out <- phase18_run_interval_heavy_summary_smoke(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      cores = cores,
      backend = backend,
      overwrite = overwrite,
      render = render,
      require_complete = require_complete,
      profile_parameters = profile_parameters,
      profile_level = profile_level,
      bootstrap_nsim = bootstrap_nsim,
      bootstrap_cores = bootstrap_cores,
      bootstrap_backend = bootstrap_backend,
      notes = notes
    )
  } else if (identical(task, "truncated_nbinom2_mu_random_intercept")) {
    out <- phase18_write_truncated_nbinom2_mu_ri_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "proportion_fixed_effect")) {
    out <- phase18_write_proportion_fe_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "bounded_response_mu_random_intercept")) {
    out <- phase18_write_bounded_response_mu_ri_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "positive_continuous_fixed_effect")) {
    out <- phase18_write_positive_continuous_fe_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "tweedie_fixed_effect")) {
    out <- phase18_write_tweedie_fe_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "count_structured_q1")) {
    conditions <- phase18_count_structured_q1_followup_conditions(
      condition_set = condition_set
    )
    out <- phase18_write_count_structured_q1_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      profile_parameters = profile_parameters,
      profile_level = profile_level,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "positive_continuous_mu_random_intercept")) {
    out <- phase18_write_positive_continuous_mu_ri_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "student_mu_random_intercept")) {
    out <- phase18_write_student_mu_ri_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "ordinal_fixed_effect")) {
    out <- phase18_write_ordinal_fe_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "zero_one_beta_fixed_effect")) {
    out <- phase18_write_zero_one_beta_fe_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "correlation_block_status")) {
    out <- phase18_write_correlation_block_status_outputs(
      output_dir = output_dir,
      overwrite = overwrite
    )
  } else if (identical(task, "biv_gaussian_mu_slope")) {
    out <- phase18_write_biv_gaussian_mu_slope_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "spatial_mu_slope")) {
    out <- phase18_write_spatial_mu_slope_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "phylo_mu_slope")) {
    out <- phase18_write_phylo_mu_slope_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "animal_mu_slope")) {
    out <- phase18_write_animal_mu_slope_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "relmat_mu_slope")) {
    out <- phase18_write_relmat_mu_slope_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else if (identical(task, "poisson_phylo_q1_formal")) {
    shard <- phase18_actions_formal_condition_shard(
      task = task,
      condition_shard = condition_shard,
      condition_shards = condition_shards
    )
    out <- phase18_write_poisson_phylo_q1_formal_grid_outputs(
      output_dir = output_dir,
      conditions = shard$conditions,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      profile_parameters = profile_parameters,
      profile_level = profile_level,
      condition_shard = condition_shard,
      condition_shards = condition_shards,
      full_condition_count = shard$full_condition_count,
      cores = cores,
      backend = backend
    )
  } else {
    shard <- phase18_actions_formal_condition_shard(
      task = task,
      condition_shard = condition_shard,
      condition_shards = condition_shards
    )
    out <- phase18_write_nbinom2_phylo_q1_formal_grid_outputs(
      output_dir = output_dir,
      conditions = shard$conditions,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      profile_parameters = profile_parameters,
      profile_level = profile_level,
      condition_shard = condition_shard,
      condition_shards = condition_shards,
      full_condition_count = shard$full_condition_count,
      cores = cores,
      backend = backend
    )
  }
  saveRDS(out, file.path(output_dir, "phase18-actions-result.rds"))
  phase18_actions_print_plan(
    task = task,
    output_dir = normalizePath(output_dir, mustWork = TRUE),
    n_rep = n_rep,
    master_seed = master_seed,
    cores = cores,
    backend = backend,
    render = render,
    require_complete = require_complete,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    condition_shard = condition_shard,
    condition_shards = condition_shards,
    condition_set = condition_set,
    bootstrap_nsim = bootstrap_nsim,
    bootstrap_cores = bootstrap_cores,
    bootstrap_backend = bootstrap_backend
  )
  invisible(out)
}

phase18_actions_parse_args <- function(args) {
  opts <- list(
    task = "first_wave_summary",
    output_dir = NULL,
    n_reps = "1",
    cores = "1",
    backend = "none",
    master_seed = "20260530",
    overwrite = "false",
    render = "false",
    require_complete = "false",
    profile_parameters = "",
    profile_level = "0.70",
    condition_shard = "1",
    condition_shards = "1",
    condition_set = "all",
    bootstrap_nsim = "0",
    bootstrap_cores = "1",
    bootstrap_backend = "none",
    notes = NULL,
    dry_run = "false"
  )
  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]
    if (!startsWith(arg, "--")) {
      stop("Unexpected argument: ", arg, call. = FALSE)
    }
    key_value <- substring(arg, 3L)
    if (grepl("=", key_value, fixed = TRUE)) {
      piece <- strsplit(key_value, "=", fixed = TRUE)[[1L]]
      key <- piece[[1L]]
      value <- paste(piece[-1L], collapse = "=")
    } else {
      key <- key_value
      i <- i + 1L
      if (i > length(args)) {
        stop("Missing value for --", key, ".", call. = FALSE)
      }
      value <- args[[i]]
    }
    key <- gsub("-", "_", key, fixed = TRUE)
    if (!key %in% names(opts)) {
      stop(
        "Unknown option --",
        gsub("_", "-", key, fixed = TRUE),
        ".",
        call. = FALSE
      )
    }
    opts[[key]] <- value
    i <- i + 1L
  }
  opts
}

phase18_actions_source_dependencies <- function(task) {
  root <- phase18_actions_root()
  paths <- unique(c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    if (identical(task, "interval_heavy_summary")) "sim/R/sim_bootstrap.R",
    phase18_actions_task_paths(task)
  ))
  for (path in paths) {
    source(phase18_actions_path(root, path), local = globalenv())
  }
}

phase18_actions_load_package <- function() {
  ok <- require("drmTMB", quietly = TRUE, character.only = TRUE)
  if (!ok) {
    stop(
      "The Phase 18 Actions runner requires the drmTMB package to be ",
      "installed before running non-dry-run tasks.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

phase18_actions_task_paths <- function(task) {
  if (identical(task, "first_wave_summary")) {
    return(c(
      "sim/dgp/sim_dgp_gaussian_ls.R",
      "sim/dgp/sim_dgp_meta_v.R",
      "sim/dgp/sim_dgp_poisson_mu_random_effect.R",
      "sim/dgp/sim_dgp_nbinom2_mu_random_effect.R",
      "sim/dgp/sim_dgp_truncated_nbinom2_mu_random_intercept.R",
      "sim/dgp/sim_dgp_gaussian_mu_random_slope.R",
      "sim/dgp/sim_dgp_gaussian_sigma_random_slope.R",
      "sim/dgp/sim_dgp_spatial_mu_slope.R",
      "sim/dgp/sim_dgp_proportion_fixed_effect.R",
      "sim/dgp/sim_dgp_bounded_response_mu_random_intercept.R",
      "sim/dgp/sim_dgp_positive_continuous_fixed_effect.R",
      "sim/dgp/sim_dgp_tweedie_fixed_effect.R",
      "sim/dgp/sim_dgp_positive_continuous_mu_random_intercept.R",
      "sim/dgp/sim_dgp_student_mu_random_intercept.R",
      "sim/dgp/sim_dgp_ordinal_fixed_effect.R",
      "sim/dgp/sim_dgp_zero_one_beta_fixed_effect.R",
      "sim/fit/sim_summarise_gaussian_ls.R",
      "sim/fit/sim_summarise_meta_v.R",
      "sim/fit/sim_summarise_poisson_mu_random_effect.R",
      "sim/fit/sim_summarise_nbinom2_mu_random_effect.R",
      "sim/fit/sim_summarise_truncated_nbinom2_mu_random_intercept.R",
      "sim/fit/sim_summarise_gaussian_mu_random_slope.R",
      "sim/fit/sim_summarise_gaussian_sigma_random_slope.R",
      "sim/fit/sim_summarise_spatial_mu_slope.R",
      "sim/fit/sim_summarise_proportion_fixed_effect.R",
      "sim/fit/sim_summarise_bounded_response_mu_random_intercept.R",
      "sim/fit/sim_summarise_positive_continuous_fixed_effect.R",
      "sim/fit/sim_summarise_tweedie_fixed_effect.R",
      "sim/fit/sim_summarise_positive_continuous_mu_random_intercept.R",
      "sim/fit/sim_summarise_student_mu_random_intercept.R",
      "sim/fit/sim_summarise_ordinal_fixed_effect.R",
      "sim/fit/sim_summarise_zero_one_beta_fixed_effect.R",
      "sim/run/sim_run_gaussian_ls_smoke.R",
      "sim/run/sim_run_meta_v_smoke.R",
      "sim/run/sim_run_poisson_mu_random_effect_smoke.R",
      "sim/run/sim_run_nbinom2_mu_random_effect_smoke.R",
      "sim/run/sim_run_truncated_nbinom2_mu_random_intercept_smoke.R",
      "sim/run/sim_run_gaussian_mu_random_slope_smoke.R",
      "sim/run/sim_run_gaussian_sigma_random_slope_smoke.R",
      "sim/run/sim_run_spatial_mu_slope_smoke.R",
      "sim/run/sim_run_proportion_fixed_effect_smoke.R",
      "sim/run/sim_run_bounded_response_mu_random_intercept_smoke.R",
      "sim/run/sim_run_positive_continuous_fixed_effect_smoke.R",
      "sim/run/sim_run_tweedie_fixed_effect_smoke.R",
      "sim/run/sim_run_positive_continuous_mu_random_intercept_smoke.R",
      "sim/run/sim_run_student_mu_random_intercept_smoke.R",
      "sim/run/sim_run_ordinal_fixed_effect_smoke.R",
      "sim/run/sim_run_zero_one_beta_fixed_effect_smoke.R",
      "sim/run/sim_summary_gaussian_ls_smoke.R",
      "sim/run/sim_summary_meta_v_smoke.R",
      "sim/run/sim_summary_poisson_mu_random_effect_smoke.R",
      "sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R",
      "sim/run/sim_summary_truncated_nbinom2_mu_random_intercept_smoke.R",
      "sim/run/sim_summary_count_mu_random_effect_pilot.R",
      "sim/run/sim_summary_gaussian_mu_random_slope_smoke.R",
      "sim/run/sim_summary_gaussian_sigma_random_slope_smoke.R",
      "sim/run/sim_summary_spatial_mu_slope_smoke.R",
      "sim/run/sim_summary_proportion_fixed_effect_smoke.R",
      "sim/run/sim_summary_bounded_response_mu_random_intercept_smoke.R",
      "sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R",
      "sim/run/sim_summary_tweedie_fixed_effect_smoke.R",
      "sim/run/sim_summary_positive_continuous_mu_random_intercept_smoke.R",
      "sim/run/sim_summary_student_mu_random_intercept_smoke.R",
      "sim/run/sim_summary_ordinal_fixed_effect_smoke.R",
      "sim/run/sim_summary_zero_one_beta_fixed_effect_smoke.R",
      "sim/run/sim_write_gaussian_ls_grid.R",
      "sim/run/sim_write_meta_v_grid.R",
      "sim/run/sim_write_count_mu_random_effect_grid.R",
      "sim/run/sim_write_truncated_nbinom2_mu_random_intercept_grid.R",
      "sim/run/sim_write_gaussian_mu_random_slope_grid.R",
      "sim/run/sim_write_gaussian_sigma_random_slope_grid.R",
      "sim/run/sim_write_spatial_mu_slope_grid.R",
      "sim/run/sim_write_proportion_fixed_effect_grid.R",
      "sim/run/sim_write_bounded_response_mu_random_intercept_grid.R",
      "sim/run/sim_write_positive_continuous_fixed_effect_grid.R",
      "sim/run/sim_write_tweedie_fixed_effect_grid.R",
      "sim/run/sim_write_positive_continuous_mu_random_intercept_grid.R",
      "sim/run/sim_write_student_mu_random_intercept_grid.R",
      "sim/run/sim_write_ordinal_fixed_effect_grid.R",
      "sim/run/sim_write_zero_one_beta_fixed_effect_grid.R",
      "sim/run/sim_write_first_wave_artifact_status.R",
      "sim/run/sim_write_first_wave_table_bundle.R",
      "sim/run/sim_render_first_wave_summary_report.R",
      "sim/run/sim_run_first_wave_summary_smoke.R"
    ))
  }
  if (identical(task, "interval_heavy_summary")) {
    return(c(
      "sim/dgp/sim_dgp_student_shape.R",
      "sim/dgp/sim_dgp_biv_rho12.R",
      "sim/fit/sim_summarise_student_shape.R",
      "sim/fit/sim_summarise_biv_rho12.R",
      "sim/run/sim_run_student_shape_smoke.R",
      "sim/run/sim_run_biv_rho12_smoke.R",
      "sim/run/sim_summary_student_shape_smoke.R",
      "sim/run/sim_summary_biv_rho12_smoke.R",
      "sim/run/sim_write_student_shape_grid.R",
      "sim/run/sim_write_biv_rho12_grid.R",
      "sim/run/sim_write_first_wave_artifact_status.R",
      "sim/run/sim_write_first_wave_table_bundle.R",
      "sim/run/sim_render_first_wave_summary_report.R",
      "sim/run/sim_run_interval_heavy_summary_smoke.R"
    ))
  }
  if (identical(task, "truncated_nbinom2_mu_random_intercept")) {
    return(c(
      "sim/dgp/sim_dgp_truncated_nbinom2_mu_random_intercept.R",
      "sim/fit/sim_summarise_truncated_nbinom2_mu_random_intercept.R",
      "sim/run/sim_run_truncated_nbinom2_mu_random_intercept_smoke.R",
      "sim/run/sim_summary_truncated_nbinom2_mu_random_intercept_smoke.R",
      "sim/run/sim_write_truncated_nbinom2_mu_random_intercept_grid.R"
    ))
  }
  if (identical(task, "proportion_fixed_effect")) {
    return(c(
      "sim/dgp/sim_dgp_proportion_fixed_effect.R",
      "sim/fit/sim_summarise_proportion_fixed_effect.R",
      "sim/run/sim_run_proportion_fixed_effect_smoke.R",
      "sim/run/sim_summary_proportion_fixed_effect_smoke.R",
      "sim/run/sim_write_proportion_fixed_effect_grid.R"
    ))
  }
  if (identical(task, "bounded_response_mu_random_intercept")) {
    return(c(
      "sim/dgp/sim_dgp_proportion_fixed_effect.R",
      "sim/dgp/sim_dgp_bounded_response_mu_random_intercept.R",
      "sim/fit/sim_summarise_bounded_response_mu_random_intercept.R",
      "sim/run/sim_run_bounded_response_mu_random_intercept_smoke.R",
      "sim/run/sim_summary_bounded_response_mu_random_intercept_smoke.R",
      "sim/run/sim_write_bounded_response_mu_random_intercept_grid.R"
    ))
  }
  if (identical(task, "positive_continuous_fixed_effect")) {
    return(c(
      "sim/dgp/sim_dgp_positive_continuous_fixed_effect.R",
      "sim/fit/sim_summarise_positive_continuous_fixed_effect.R",
      "sim/run/sim_run_positive_continuous_fixed_effect_smoke.R",
      "sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R",
      "sim/run/sim_write_positive_continuous_fixed_effect_grid.R"
    ))
  }
  if (identical(task, "tweedie_fixed_effect")) {
    return(c(
      "sim/dgp/sim_dgp_tweedie_fixed_effect.R",
      "sim/fit/sim_summarise_tweedie_fixed_effect.R",
      "sim/run/sim_run_tweedie_fixed_effect_smoke.R",
      "sim/run/sim_summary_tweedie_fixed_effect_smoke.R",
      "sim/run/sim_write_tweedie_fixed_effect_grid.R"
    ))
  }
  if (identical(task, "count_structured_q1")) {
    return(c(
      "sim/dgp/sim_dgp_count_structured_q1.R",
      "sim/fit/sim_summarise_count_structured_q1.R",
      "sim/run/sim_run_count_structured_q1_smoke.R",
      "sim/run/sim_summary_count_structured_q1_smoke.R",
      "sim/run/sim_write_count_structured_q1_grid.R"
    ))
  }
  if (identical(task, "positive_continuous_mu_random_intercept")) {
    return(c(
      "sim/dgp/sim_dgp_positive_continuous_fixed_effect.R",
      "sim/dgp/sim_dgp_positive_continuous_mu_random_intercept.R",
      "sim/fit/sim_summarise_positive_continuous_mu_random_intercept.R",
      "sim/run/sim_run_positive_continuous_mu_random_intercept_smoke.R",
      "sim/run/sim_summary_positive_continuous_mu_random_intercept_smoke.R",
      "sim/run/sim_write_positive_continuous_mu_random_intercept_grid.R"
    ))
  }
  if (identical(task, "student_mu_random_intercept")) {
    return(c(
      "sim/dgp/sim_dgp_student_mu_random_intercept.R",
      "sim/fit/sim_summarise_student_mu_random_intercept.R",
      "sim/run/sim_run_student_mu_random_intercept_smoke.R",
      "sim/run/sim_summary_student_mu_random_intercept_smoke.R",
      "sim/run/sim_write_student_mu_random_intercept_grid.R"
    ))
  }
  if (identical(task, "ordinal_fixed_effect")) {
    return(c(
      "sim/dgp/sim_dgp_ordinal_fixed_effect.R",
      "sim/fit/sim_summarise_ordinal_fixed_effect.R",
      "sim/run/sim_run_ordinal_fixed_effect_smoke.R",
      "sim/run/sim_summary_ordinal_fixed_effect_smoke.R",
      "sim/run/sim_write_ordinal_fixed_effect_grid.R"
    ))
  }
  if (identical(task, "zero_one_beta_fixed_effect")) {
    return(c(
      "sim/dgp/sim_dgp_zero_one_beta_fixed_effect.R",
      "sim/fit/sim_summarise_zero_one_beta_fixed_effect.R",
      "sim/run/sim_run_zero_one_beta_fixed_effect_smoke.R",
      "sim/run/sim_summary_zero_one_beta_fixed_effect_smoke.R",
      "sim/run/sim_write_zero_one_beta_fixed_effect_grid.R"
    ))
  }
  if (identical(task, "correlation_block_status")) {
    return(c(
      "sim/run/sim_phase18_structured_workflow_registry.R",
      "sim/run/sim_write_correlation_block_status.R"
    ))
  }
  if (identical(task, "biv_gaussian_mu_slope")) {
    return(c(
      "sim/dgp/sim_dgp_biv_gaussian_mu_slope.R",
      "sim/fit/sim_summarise_biv_gaussian_mu_slope.R",
      "sim/run/sim_run_biv_gaussian_mu_slope_smoke.R",
      "sim/run/sim_summary_biv_gaussian_mu_slope_smoke.R",
      "sim/run/sim_write_biv_gaussian_mu_slope_grid.R"
    ))
  }
  if (identical(task, "spatial_mu_slope")) {
    return(c(
      "sim/dgp/sim_dgp_spatial_mu_slope.R",
      "sim/fit/sim_summarise_spatial_mu_slope.R",
      "sim/run/sim_run_spatial_mu_slope_smoke.R",
      "sim/run/sim_summary_spatial_mu_slope_smoke.R",
      "sim/run/sim_write_spatial_mu_slope_grid.R"
    ))
  }
  if (identical(task, "phylo_mu_slope")) {
    return(c(
      "sim/dgp/sim_dgp_phylo_mu_slope.R",
      "sim/fit/sim_summarise_phylo_mu_slope.R",
      "sim/run/sim_run_phylo_mu_slope_smoke.R",
      "sim/run/sim_summary_phylo_mu_slope_smoke.R",
      "sim/run/sim_write_phylo_mu_slope_grid.R"
    ))
  }
  if (identical(task, "animal_mu_slope")) {
    return(c(
      "sim/dgp/sim_dgp_animal_mu_slope.R",
      "sim/fit/sim_summarise_animal_mu_slope.R",
      "sim/run/sim_run_animal_mu_slope_smoke.R",
      "sim/run/sim_summary_animal_mu_slope_smoke.R",
      "sim/run/sim_write_animal_mu_slope_grid.R"
    ))
  }
  if (identical(task, "relmat_mu_slope")) {
    return(c(
      "sim/dgp/sim_dgp_relmat_mu_slope.R",
      "sim/fit/sim_summarise_relmat_mu_slope.R",
      "sim/run/sim_run_relmat_mu_slope_smoke.R",
      "sim/run/sim_summary_relmat_mu_slope_smoke.R",
      "sim/run/sim_write_relmat_mu_slope_grid.R"
    ))
  }
  if (identical(task, "poisson_phylo_q1_formal")) {
    return(c(
      "sim/dgp/sim_dgp_poisson_phylo_q1.R",
      "sim/fit/sim_summarise_poisson_phylo_q1.R",
      "sim/run/sim_run_poisson_phylo_q1_smoke.R",
      "sim/run/sim_summary_poisson_phylo_q1_smoke.R",
      "sim/run/sim_write_poisson_phylo_q1_grid.R"
    ))
  }
  c(
    "sim/dgp/sim_dgp_nbinom2_phylo_q1.R",
    "sim/fit/sim_summarise_nbinom2_phylo_q1.R",
    "sim/run/sim_run_nbinom2_phylo_q1_smoke.R",
    "sim/run/sim_summary_nbinom2_phylo_q1_smoke.R",
    "sim/run/sim_write_nbinom2_phylo_q1_grid.R"
  )
}

phase18_actions_root <- function() {
  cwd <- normalizePath(getwd(), mustWork = TRUE)
  desc <- file.path(cwd, "DESCRIPTION")
  if (file.exists(desc)) {
    fields <- tryCatch(
      read.dcf(desc, fields = "Package"),
      error = function(e) matrix(NA_character_, nrow = 1L)
    )
    if (identical(fields[[1L]], "drmTMB")) {
      return(cwd)
    }
  }
  pkg <- system.file(package = "drmTMB")
  if (nzchar(pkg)) {
    return(pkg)
  }
  stop("Could not find the drmTMB package root.", call. = FALSE)
}

phase18_actions_path <- function(root, path) {
  candidates <- c(file.path(root, "inst", path), file.path(root, path))
  hit <- candidates[file.exists(candidates)][1L]
  if (is.na(hit)) {
    stop("Could not find Phase 18 dependency `", path, "`.", call. = FALSE)
  }
  hit
}

phase18_actions_choice <- function(x, choices, name) {
  if (!is.character(x) || length(x) != 1L || !nzchar(x) || !x %in% choices) {
    stop(
      "`",
      name,
      "` must be one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  x
}

phase18_actions_bool <- function(x, name) {
  if (is.null(x)) {
    return(FALSE)
  }
  value <- tolower(x)
  if (!value %in% c("true", "false", "1", "0", "yes", "no")) {
    stop("`", name, "` must be true or false.", call. = FALSE)
  }
  value %in% c("true", "1", "yes")
}

phase18_actions_positive_integer <- function(x, name) {
  value <- phase18_actions_integer(x, name)
  if (value < 1L) {
    stop("`", name, "` must be a positive integer.", call. = FALSE)
  }
  value
}

phase18_actions_nonnegative_integer <- function(x, name) {
  value <- phase18_actions_integer(x, name)
  if (value < 0L) {
    stop("`", name, "` must be a non-negative integer.", call. = FALSE)
  }
  value
}

phase18_actions_integer <- function(x, name) {
  value <- suppressWarnings(as.integer(x))
  if (
    length(value) != 1L ||
      is.na(value) ||
      !identical(as.character(value), as.character(x))
  ) {
    stop("`", name, "` must be one integer.", call. = FALSE)
  }
  value
}

phase18_actions_core_count <- function(x, name) {
  value <- phase18_actions_positive_integer(x, name)
  if (value > 10L) {
    warning("`", name, "` was capped at 10.", call. = FALSE)
    value <- 10L
  }
  value
}

phase18_actions_probability <- function(x, name) {
  value <- suppressWarnings(as.numeric(x))
  if (!is.finite(value) || value <= 0 || value >= 1) {
    stop("`", name, "` must be between 0 and 1.", call. = FALSE)
  }
  value
}

phase18_actions_character_vector <- function(x) {
  if (is.null(x) || !nzchar(x)) {
    return(character())
  }
  trimws(strsplit(x, ",", fixed = TRUE)[[1L]])
}

phase18_actions_validate_condition_shard <- function(
  task,
  condition_shard,
  condition_shards
) {
  if (condition_shard > condition_shards) {
    stop(
      "`condition-shard` must be less than or equal to `condition-shards`.",
      call. = FALSE
    )
  }
  if (
    !phase18_actions_formal_task(task) &&
      (!identical(condition_shard, 1L) || !identical(condition_shards, 1L))
  ) {
    stop(
      "Condition sharding is only available for phylo q1 formal tasks.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

phase18_actions_validate_condition_set <- function(task, condition_set) {
  if (
    !identical(task, "count_structured_q1") &&
      !identical(condition_set, "all")
  ) {
    stop(
      "`condition-set` is only available for count_structured_q1.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

phase18_actions_formal_task <- function(task) {
  task %in% c("poisson_phylo_q1_formal", "nbinom2_phylo_q1_formal")
}

phase18_actions_formal_condition_shard <- function(
  task,
  condition_shard = 1L,
  condition_shards = 1L
) {
  phase18_actions_validate_condition_shard(
    task = task,
    condition_shard = condition_shard,
    condition_shards = condition_shards
  )
  conditions <- if (identical(task, "poisson_phylo_q1_formal")) {
    phase18_poisson_phylo_q1_formal_conditions()
  } else {
    phase18_nbinom2_phylo_q1_formal_conditions()
  }
  full_condition_count <- nrow(conditions)
  shard_index <- ((seq_len(full_condition_count) - 1L) %% condition_shards) + 1L
  conditions <- conditions[shard_index == condition_shard, , drop = FALSE]
  row.names(conditions) <- NULL
  if (nrow(conditions) == 0L) {
    stop("Condition shard is empty.", call. = FALSE)
  }
  list(
    conditions = conditions,
    full_condition_count = full_condition_count
  )
}

phase18_actions_print_plan <- function(
  task,
  output_dir,
  n_rep,
  master_seed,
  cores,
  backend,
  render,
  require_complete,
  profile_parameters,
  profile_level,
  condition_shard,
  condition_shards,
  condition_set,
  bootstrap_nsim,
  bootstrap_cores,
  bootstrap_backend
) {
  cat(
    paste0(
      "Phase 18 Actions task=",
      task,
      "\n",
      "output_dir=",
      output_dir,
      "\n",
      "n_rep=",
      n_rep,
      "\n",
      "master_seed=",
      master_seed,
      "\n",
      "backend=",
      backend,
      "\n",
      "cores=",
      cores,
      "\n",
      "render=",
      render,
      "\n",
      "require_complete=",
      require_complete,
      "\n",
      "profile_parameters=",
      paste(profile_parameters, collapse = ","),
      "\n",
      "profile_level=",
      profile_level,
      "\n",
      "condition_shard=",
      condition_shard,
      "\n",
      "condition_shards=",
      condition_shards,
      "\n",
      "condition_set=",
      condition_set,
      "\n",
      "bootstrap_nsim=",
      bootstrap_nsim,
      "\n",
      "bootstrap_backend=",
      bootstrap_backend,
      "\n",
      "bootstrap_cores=",
      bootstrap_cores,
      "\n"
    )
  )
}

if (sys.nframe() == 0L) {
  phase18_actions_main()
}
