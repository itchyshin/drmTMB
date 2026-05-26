phase18_actions_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  opts <- phase18_actions_parse_args(args)
  dry_run <- phase18_actions_bool(opts$dry_run, "dry-run")
  task <- phase18_actions_choice(
    opts$task,
    c(
      "first_wave_summary",
      "interval_heavy_summary",
      "positive_continuous_fixed_effect",
      "proportion_fixed_effect",
      "ordinal_fixed_effect",
      "poisson_phylo_q1_formal"
    ),
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
      profile_parameters = profile_parameters,
      profile_level = profile_level,
      bootstrap_nsim = bootstrap_nsim,
      bootstrap_cores = bootstrap_cores,
      bootstrap_backend = bootstrap_backend
    )
    return(invisible(NULL))
  }

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
  } else if (identical(task, "positive_continuous_fixed_effect")) {
    out <- phase18_write_positive_continuous_fe_grid_outputs(
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
  } else if (identical(task, "ordinal_fixed_effect")) {
    out <- phase18_write_ordinal_fe_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      cores = cores,
      backend = backend
    )
  } else {
    out <- phase18_write_poisson_phylo_q1_formal_grid_outputs(
      output_dir = output_dir,
      n_rep = n_rep,
      master_seed = master_seed,
      overwrite = overwrite,
      profile_parameters = profile_parameters,
      profile_level = profile_level,
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
    profile_parameters = profile_parameters,
    profile_level = profile_level,
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

phase18_actions_task_paths <- function(task) {
  if (identical(task, "first_wave_summary")) {
    return(c(
      "sim/dgp/sim_dgp_gaussian_ls.R",
      "sim/dgp/sim_dgp_meta_v.R",
      "sim/dgp/sim_dgp_poisson_mu_random_effect.R",
      "sim/dgp/sim_dgp_nbinom2_mu_random_effect.R",
      "sim/dgp/sim_dgp_proportion_fixed_effect.R",
      "sim/dgp/sim_dgp_positive_continuous_fixed_effect.R",
      "sim/dgp/sim_dgp_ordinal_fixed_effect.R",
      "sim/dgp/sim_dgp_gaussian_mu_random_slope.R",
      "sim/dgp/sim_dgp_gaussian_sigma_random_slope.R",
      "sim/dgp/sim_dgp_spatial_mu_slope.R",
      "sim/fit/sim_summarise_gaussian_ls.R",
      "sim/fit/sim_summarise_meta_v.R",
      "sim/fit/sim_summarise_poisson_mu_random_effect.R",
      "sim/fit/sim_summarise_nbinom2_mu_random_effect.R",
      "sim/fit/sim_summarise_proportion_fixed_effect.R",
      "sim/fit/sim_summarise_positive_continuous_fixed_effect.R",
      "sim/fit/sim_summarise_ordinal_fixed_effect.R",
      "sim/fit/sim_summarise_gaussian_mu_random_slope.R",
      "sim/fit/sim_summarise_gaussian_sigma_random_slope.R",
      "sim/fit/sim_summarise_spatial_mu_slope.R",
      "sim/run/sim_run_gaussian_ls_smoke.R",
      "sim/run/sim_run_meta_v_smoke.R",
      "sim/run/sim_run_poisson_mu_random_effect_smoke.R",
      "sim/run/sim_run_nbinom2_mu_random_effect_smoke.R",
      "sim/run/sim_run_proportion_fixed_effect_smoke.R",
      "sim/run/sim_run_positive_continuous_fixed_effect_smoke.R",
      "sim/run/sim_run_ordinal_fixed_effect_smoke.R",
      "sim/run/sim_run_gaussian_mu_random_slope_smoke.R",
      "sim/run/sim_run_gaussian_sigma_random_slope_smoke.R",
      "sim/run/sim_run_spatial_mu_slope_smoke.R",
      "sim/run/sim_summary_gaussian_ls_smoke.R",
      "sim/run/sim_summary_meta_v_smoke.R",
      "sim/run/sim_summary_poisson_mu_random_effect_smoke.R",
      "sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R",
      "sim/run/sim_summary_count_mu_random_effect_pilot.R",
      "sim/run/sim_summary_proportion_fixed_effect_smoke.R",
      "sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R",
      "sim/run/sim_summary_ordinal_fixed_effect_smoke.R",
      "sim/run/sim_summary_gaussian_mu_random_slope_smoke.R",
      "sim/run/sim_summary_gaussian_sigma_random_slope_smoke.R",
      "sim/run/sim_summary_spatial_mu_slope_smoke.R",
      "sim/run/sim_write_gaussian_ls_grid.R",
      "sim/run/sim_write_meta_v_grid.R",
      "sim/run/sim_write_count_mu_random_effect_grid.R",
      "sim/run/sim_write_proportion_fixed_effect_grid.R",
      "sim/run/sim_write_positive_continuous_fixed_effect_grid.R",
      "sim/run/sim_write_ordinal_fixed_effect_grid.R",
      "sim/run/sim_write_gaussian_mu_random_slope_grid.R",
      "sim/run/sim_write_gaussian_sigma_random_slope_grid.R",
      "sim/run/sim_write_spatial_mu_slope_grid.R",
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
  if (identical(task, "proportion_fixed_effect")) {
    return(c(
      "sim/dgp/sim_dgp_proportion_fixed_effect.R",
      "sim/fit/sim_summarise_proportion_fixed_effect.R",
      "sim/run/sim_run_proportion_fixed_effect_smoke.R",
      "sim/run/sim_summary_proportion_fixed_effect_smoke.R",
      "sim/run/sim_write_proportion_fixed_effect_grid.R"
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
  if (identical(task, "ordinal_fixed_effect")) {
    return(c(
      "sim/dgp/sim_dgp_ordinal_fixed_effect.R",
      "sim/fit/sim_summarise_ordinal_fixed_effect.R",
      "sim/run/sim_run_ordinal_fixed_effect_smoke.R",
      "sim/run/sim_summary_ordinal_fixed_effect_smoke.R",
      "sim/run/sim_write_ordinal_fixed_effect_grid.R"
    ))
  }
  c(
    "sim/dgp/sim_dgp_poisson_phylo_q1.R",
    "sim/fit/sim_summarise_poisson_phylo_q1.R",
    "sim/run/sim_run_poisson_phylo_q1_smoke.R",
    "sim/run/sim_summary_poisson_phylo_q1_smoke.R",
    "sim/run/sim_write_poisson_phylo_q1_grid.R"
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

phase18_actions_print_plan <- function(
  task,
  output_dir,
  n_rep,
  master_seed,
  cores,
  backend,
  render,
  profile_parameters,
  profile_level,
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
      "profile_parameters=",
      paste(profile_parameters, collapse = ","),
      "\n",
      "profile_level=",
      profile_level,
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
