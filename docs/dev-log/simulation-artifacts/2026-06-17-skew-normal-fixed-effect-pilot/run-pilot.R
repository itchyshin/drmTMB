args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-17-skew-normal-fixed-effect-pilot/run-pilot.R",
    mustWork = TRUE
  )
}

artifact_dir <- dirname(script_path)
repo_root <- normalizePath(file.path(artifact_dir, "../../../.."), mustWork = TRUE)
tables_dir <- file.path(artifact_dir, "tables")
figures_dir <- file.path(artifact_dir, "figures")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(repo_root, quiet = TRUE)
} else {
  library(drmTMB)
}

source(file.path(repo_root, "inst/sim/R/sim_registry.R"))
source(file.path(repo_root, "inst/sim/R/sim_utils.R"))
source(file.path(repo_root, "inst/sim/R/sim_runner.R"))
source(file.path(repo_root, "inst/sim/R/sim_aggregate.R"))
source(file.path(repo_root, "inst/sim/R/sim_uncertainty.R"))
source(file.path(repo_root, "inst/sim/R/sim_bootstrap.R"))
source(file.path(repo_root, "inst/sim/dgp/sim_dgp_skew_normal_fixed_effect.R"))
source(file.path(repo_root, "inst/sim/fit/sim_summarise_skew_normal_fixed_effect.R"))
source(file.path(repo_root, "inst/sim/run/sim_run_skew_normal_fixed_effect_smoke.R"))
source(file.path(repo_root, "inst/sim/run/sim_summary_skew_normal_fixed_effect_smoke.R"))
source(file.path(repo_root, "inst/sim/run/sim_write_skew_normal_fixed_effect_grid.R"))

n_rep <- as.integer(Sys.getenv("DRMTMB_SKEW_NORMAL_PILOT_REPS", "25"))
cores <- as.integer(Sys.getenv("DRMTMB_SKEW_NORMAL_PILOT_CORES", "4"))
backend <- Sys.getenv("DRMTMB_SKEW_NORMAL_PILOT_BACKEND", "multicore")
if (.Platform$OS.type == "windows" && identical(backend, "multicore")) {
  backend <- "none"
  cores <- 1L
}

conditions <- phase18_skew_normal_fe_conditions(
  n = 720L,
  nu_intercept = c(-1.20, 0, 1.20),
  nu_slope = c(0, 0.35),
  sigma_slope = 0.15,
  rho_xw = 0.20
)

started <- Sys.time()
out <- phase18_write_skew_normal_fe_grid_outputs(
  output_dir = artifact_dir,
  conditions = conditions,
  n_rep = n_rep,
  master_seed = 20260617L,
  overwrite = TRUE,
  profile_parameters = character(),
  bootstrap_nsim = 0L,
  cores = cores,
  backend = backend
)
finished <- Sys.time()

cells <- out$summary$run$registry$cells
cells$cell_code <- paste0("C", seq_len(nrow(cells)))
utils::write.csv(
  cells,
  file.path(tables_dir, "skew-normal-fe-conditions.csv"),
  row.names = FALSE
)

aggregate <- out$summary$aggregate
replicates <- out$summary$replicates
manifest <- out$summary$manifest
wald_coverage <- out$summary$wald_coverage
cell_summary <- unique(aggregate[c(
  "cell_id",
  "n_replicate",
  "convergence_rate",
  "pdHess_rate",
  "warning_rate",
  "mean_elapsed"
)])
cell_summary <- merge(
  cells[c(
    "cell_id",
    "cell_code",
    "n",
    "nu_intercept",
    "nu_slope",
    "sigma_slope",
    "rho_xw"
  )],
  cell_summary,
  by = "cell_id",
  all.x = TRUE,
  sort = FALSE
)
utils::write.csv(
  cell_summary,
  file.path(tables_dir, "skew-normal-fe-condition-summary.csv"),
  row.names = FALSE
)

run_summary <- data.frame(
  surface = "skew_normal_fixed_effect",
  label = "pilot",
  n_cells = nrow(cells),
  n_rep = n_rep,
  n_fits = nrow(manifest),
  n_ok = sum(manifest$status == "ok"),
  n_error = sum(manifest$status == "error"),
  n_skipped = sum(manifest$skipped),
  min_convergence_rate = min(cell_summary$convergence_rate, na.rm = TRUE),
  min_pdHess_rate = min(cell_summary$pdHess_rate, na.rm = TRUE),
  max_warning_rate = max(cell_summary$warning_rate, na.rm = TRUE),
  mean_elapsed_seconds = mean(cell_summary$mean_elapsed, na.rm = TRUE),
  started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
  finished = format(finished, "%Y-%m-%d %H:%M:%S %Z"),
  elapsed_seconds = as.numeric(difftime(finished, started, units = "secs")),
  cores = cores,
  backend = backend,
  stringsAsFactors = FALSE
)
utils::write.csv(
  run_summary,
  file.path(artifact_dir, "skew-normal-fixed-effect-pilot-summary.csv"),
  row.names = FALSE
)

capture.output(
  sessionInfo(),
  file = file.path(artifact_dir, "session-info.txt")
)

plot_path <- file.path(figures_dir, "skew-normal-fixed-effect-pilot.png")
png(plot_path, width = 1600, height = 1100, res = 150)
op <- par(mfrow = c(2, 2), mar = c(5, 5, 3, 1), oma = c(0, 0, 2, 0))
on.exit(par(op), add = TRUE)

barplot(
  cell_summary$pdHess_rate,
  names.arg = cell_summary$cell_code,
  las = 1,
  ylim = c(0, 1),
  ylab = "Rate",
  xlab = "Cell",
  main = "Positive Hessian by cell",
  col = "#4C78A8"
)
abline(h = 0.95, col = "#D62728", lty = 2)

nu_intercept <- merge(
  replicates[replicates$parameter == "nu:(Intercept)", ],
  cells[c("cell_id", "cell_code", "nu_intercept", "nu_slope")],
  by = "cell_id",
  all.x = TRUE,
  sort = FALSE
)
boxplot(
  error ~ cell_code,
  data = nu_intercept,
  las = 1,
  ylab = "Estimate - truth",
  xlab = "Cell",
  main = "nu intercept error",
  col = "#F58518"
)
abline(h = 0, col = "#333333", lty = 2)

nu_slope <- merge(
  replicates[replicates$parameter == "nu:w", ],
  cells[c("cell_id", "cell_code", "nu_intercept", "nu_slope")],
  by = "cell_id",
  all.x = TRUE,
  sort = FALSE
)
boxplot(
  error ~ cell_code,
  data = nu_slope,
  las = 1,
  ylab = "Estimate - truth",
  xlab = "Cell",
  main = "nu slope error",
  col = "#54A24B"
)
abline(h = 0, col = "#333333", lty = 2)

coverage_key <- merge(
  wald_coverage[wald_coverage$parameter %in% c("nu:(Intercept)", "nu:w"), ],
  cells[c("cell_id", "cell_code", "nu_intercept", "nu_slope")],
  by = "cell_id",
  all.x = TRUE,
  sort = FALSE
)
coverage_key$plot_label <- paste0(
  coverage_key$cell_code,
  "-",
  ifelse(coverage_key$parameter == "nu:(Intercept)", "nu0", "nu_w")
)
barplot(
  coverage_key$coverage,
  names.arg = coverage_key$plot_label,
  las = 2,
  cex.names = 0.75,
  ylim = c(0, 1),
  ylab = "Wald coverage",
  main = "70% Wald coverage for slant terms",
  col = "#B279A2"
)
abline(h = 0.70, col = "#333333", lty = 2)
mtext("Fixed-effect skew-normal pilot, diagnostic evidence only", outer = TRUE)
dev.off()

if (!identical(Sys.getenv("DRMTMB_KEEP_RAW_RESULTS"), "true")) {
  unlink(out$result_dir, recursive = TRUE)
}

message("Wrote skew-normal fixed-effect pilot artifact to: ", artifact_dir)
