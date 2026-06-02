# Persist a power-grid runner result to CSV artifacts plus a manifest.
#
# `phase18_write_power_grid_tables()` is pure persistence: it takes an in-memory
# result from `phase18_run_power_grid()` (or a surface wrapper) and writes the
# power table, power curve, target-sample-size table, condition registry, and
# per-replicate summary, then a manifest of what was written. The
# `phase18_run_and_write_power_grid()` helper and the per-surface
# `phase18_write_*_power_grid_outputs()` wrappers run a grid and persist it in one
# call, for the Actions dispatch. Contract:
# docs/design/154-phase-18-power-simulation-plan.md.

phase18_power_grid_paths <- function(table_dir, prefix) {
  list(
    power_csv = file.path(table_dir, paste0(prefix, "-power.csv")),
    curve_csv = file.path(table_dir, paste0(prefix, "-curve.csv")),
    sample_size_csv = file.path(table_dir, paste0(prefix, "-sample-size.csv")),
    conditions_csv = file.path(table_dir, paste0(prefix, "-conditions.csv")),
    replicate_csv = file.path(table_dir, paste0(prefix, "-replicates.csv"))
  )
}

phase18_power_grid_manifest <- function(surface, paths) {
  files <- unlist(paths, use.names = TRUE)
  n_rows <- vapply(
    files,
    function(p) {
      if (!file.exists(p)) {
        return(NA_integer_)
      }
      nrow(utils::read.csv(p, stringsAsFactors = FALSE))
    },
    integer(1L)
  )
  data.frame(
    surface = surface,
    artifact = names(files),
    path = unname(files),
    exists = file.exists(files),
    n_rows = unname(n_rows),
    stringsAsFactors = FALSE
  )
}

phase18_write_power_grid_tables <- function(
  result,
  output_dir,
  prefix = "power",
  overwrite = FALSE
) {
  required <- c("surface", "power", "curve", "sample_size", "registry", "summary")
  if (!is.list(result) || !all(required %in% names(result))) {
    stop(
      "`result` must be a power-grid runner result list with ",
      paste(required, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  if (
    !is.character(prefix) || length(prefix) != 1L || !nzchar(prefix)
  ) {
    stop("`prefix` must be one non-empty string.", call. = FALSE)
  }
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  table_dir <- file.path(output_dir, "tables")
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  paths <- phase18_power_grid_paths(table_dir, prefix)
  manifest_csv <- file.path(table_dir, paste0(prefix, "-manifest.csv"))

  path_values <- c(unlist(paths, use.names = FALSE), manifest_csv)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Power grid output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }

  utils::write.csv(result$power, paths$power_csv, row.names = FALSE)
  utils::write.csv(result$curve, paths$curve_csv, row.names = FALSE)
  utils::write.csv(result$sample_size, paths$sample_size_csv, row.names = FALSE)
  utils::write.csv(result$registry$cells, paths$conditions_csv, row.names = FALSE)
  utils::write.csv(result$summary, paths$replicate_csv, row.names = FALSE)

  manifest <- phase18_power_grid_manifest(result$surface, paths)
  utils::write.csv(manifest, manifest_csv, row.names = FALSE)

  list(
    surface = result$surface,
    output_dir = output_dir,
    table_dir = table_dir,
    paths = paths,
    manifest_csv = manifest_csv,
    manifest = manifest,
    result = result
  )
}

phase18_run_and_write_power_grid <- function(
  run_fun,
  output_dir,
  prefix,
  n_rep = 5L,
  master_seed = 20260602L,
  overwrite = FALSE,
  cores = 1L,
  backend = "none",
  ...
) {
  phase18_assert_function(run_fun, "run_fun")
  result <- run_fun(
    n_rep = n_rep,
    master_seed = master_seed,
    cores = cores,
    backend = backend,
    ...
  )
  phase18_write_power_grid_tables(
    result,
    output_dir = output_dir,
    prefix = prefix,
    overwrite = overwrite
  )
}

phase18_write_gaussian_ls_power_grid_outputs <- function(
  output_dir,
  n_rep = 5L,
  master_seed = 20260602L,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  phase18_run_and_write_power_grid(
    run_fun = phase18_run_gaussian_ls_power,
    output_dir = output_dir,
    prefix = "gaussian-ls-power",
    n_rep = n_rep,
    master_seed = master_seed,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
}

phase18_write_meta_v_power_grid_outputs <- function(
  output_dir,
  n_rep = 5L,
  master_seed = 20260602L,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  phase18_run_and_write_power_grid(
    run_fun = phase18_run_meta_v_power,
    output_dir = output_dir,
    prefix = "meta-v-power",
    n_rep = n_rep,
    master_seed = master_seed,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
}

phase18_write_poisson_mu_re_power_grid_outputs <- function(
  output_dir,
  n_rep = 5L,
  master_seed = 20260602L,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  phase18_run_and_write_power_grid(
    run_fun = phase18_run_poisson_mu_re_power,
    output_dir = output_dir,
    prefix = "poisson-mu-re-power",
    n_rep = n_rep,
    master_seed = master_seed,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
}
