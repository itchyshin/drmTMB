args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-18-skew-normal-tail-floor-diagnostic/run-pilot.R",
    mustWork = TRUE
  )
}

artifact_dir <- dirname(script_path)
tables_dir <- file.path(artifact_dir, "tables")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

floor_value <- 1e-300
log_floor <- log(floor_value)
threshold <- uniroot(
  function(x) stats::pnorm(x, log.p = TRUE) - log_floor,
  interval = c(-40, -30)
)$root

grid <- data.frame(
  cell = c(
    rep("ordinary_tail", 7),
    rep("near_floor", 5),
    rep("floor_dominated_tail", 5)
  ),
  alpha_z = c(
    -8, -5, -2, 0, 2, 5, 8,
    -20, -30, -36, threshold, -38,
    -40, -45, -50, -60, -80
  ),
  stringsAsFactors = FALSE
)

grid$exact_log_cdf <- stats::pnorm(grid$alpha_z, log.p = TRUE)
grid$tmb_pnorm_value <- stats::pnorm(grid$alpha_z)
grid$floored_log_cdf <- log(grid$tmb_pnorm_value + floor_value)
grid$floor_log_lift <- grid$floored_log_cdf - grid$exact_log_cdf
grid$floor_dominates <- grid$tmb_pnorm_value <= floor_value
grid$finite_tmb_value <- is.finite(grid$floored_log_cdf)

cell_order <- c("ordinary_tail", "near_floor", "floor_dominated_tail")
summary <- do.call(rbind, lapply(cell_order, function(cell) {
  rows <- grid[grid$cell == cell, , drop = FALSE]
  data.frame(
    cell = cell,
    n_points = nrow(rows),
    n_floor_dominated = sum(rows$floor_dominates),
    floor_threshold_alpha_z = threshold,
    log_floor = log_floor,
    max_abs_log_lift = max(abs(rows$floor_log_lift)),
    max_log_lift = max(rows$floor_log_lift),
    min_log_lift = min(rows$floor_log_lift),
    min_exact_log_cdf = min(rows$exact_log_cdf),
    stringsAsFactors = FALSE
  )
}))

run_summary <- data.frame(
  surface = "skew_normal_tail_floor_diagnostic",
  label = "source_level_tail_floor",
  n_cells = length(unique(grid$cell)),
  n_points = nrow(grid),
  floor_value = floor_value,
  floor_threshold_alpha_z = threshold,
  max_ordinary_abs_log_lift = max(abs(
    grid$floor_log_lift[grid$cell == "ordinary_tail"]
  )),
  max_near_floor_abs_log_lift = max(abs(
    grid$floor_log_lift[grid$cell == "near_floor"]
  )),
  max_floor_dominated_log_lift = max(
    grid$floor_log_lift[grid$cell == "floor_dominated_tail"]
  ),
  all_floored_values_finite = all(grid$finite_tmb_value),
  stringsAsFactors = FALSE
)

utils::write.csv(
  grid,
  file.path(tables_dir, "skew-normal-tail-floor-grid.csv"),
  row.names = FALSE
)
utils::write.csv(
  summary,
  file.path(tables_dir, "skew-normal-tail-floor-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  run_summary,
  file.path(artifact_dir, "skew-normal-tail-floor-run-summary.csv"),
  row.names = FALSE
)

session_info <- capture.output(sessionInfo())
session_info <- sub("[ \t]+$", "", session_info)
writeLines(session_info, file.path(artifact_dir, "session-info.txt"))

message("Wrote skew-normal tail-floor diagnostic artifact to: ", artifact_dir)
