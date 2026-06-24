#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
value_arg <- function(name, default) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (!length(hit)) {
    return(default)
  }
  sub(prefix, "", hit[[1L]], fixed = TRUE)
}

n_rep <- as.integer(value_arg("n-rep", "500"))
seed_start <- as.integer(value_arg("seed-start", "202607500"))
sd_scales <- as.numeric(strsplit(value_arg("sd-scales", "0.35,0.50"), ",")[[
  1L
]])
n_shards <- as.integer(value_arg("n-shards", "9"))
drac_array_tasks <- as.integer(value_arg("drac-array-tasks", "8"))
account <- value_arg("account", "def-pi-placeholder")
time_limit <- value_arg("time", "06:00:00")
mem <- value_arg("mem", "16G")
cpus_per_task <- as.integer(value_arg("cpus-per-task", "4"))
aggregate_label <- value_arg(
  "aggregate-label",
  "drac_hybrid_full_calibrated_grid"
)
nominal_coverage <- as.numeric(value_arg("nominal-coverage", "0.95"))
failure_rate_reference <- as.numeric(value_arg(
  "failure-rate-reference",
  "0.05"
))

if (is.na(n_rep) || n_rep < 475L) {
  stop(
    "The DRAC dispatch pack requires --n-rep >= 475 to meet the MCSE gate.",
    call. = FALSE
  )
}
if (is.na(seed_start) || seed_start <= 0L) {
  stop("--seed-start must be a positive integer.", call. = FALSE)
}
if (!length(sd_scales) || any(is.na(sd_scales)) || any(sd_scales <= 0)) {
  stop(
    "--sd-scales must be a comma-separated list of positive numbers.",
    call. = FALSE
  )
}
if (is.na(n_shards) || n_shards < 2L) {
  stop(
    "--n-shards must be at least 2 for the DRAC plus totoro dispatch pack.",
    call. = FALSE
  )
}
if (
  is.na(drac_array_tasks) ||
    drac_array_tasks < 1L ||
    drac_array_tasks >= n_shards
) {
  stop(
    "--drac-array-tasks must be positive and less than --n-shards.",
    call. = FALSE
  )
}
if (is.na(cpus_per_task) || cpus_per_task < 1L) {
  stop("--cpus-per-task must be a positive integer.", call. = FALSE)
}
if (
  is.na(nominal_coverage) ||
    nominal_coverage <= 0 ||
    nominal_coverage >= 1
) {
  stop("--nominal-coverage must be in (0, 1).", call. = FALSE)
}
if (
  is.na(failure_rate_reference) ||
    failure_rate_reference <= 0 ||
    failure_rate_reference >= 1
) {
  stop("--failure-rate-reference must be in (0, 1).", call. = FALSE)
}

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg)) {
  sub("^--file=", "", script_arg[[1L]])
} else {
  ""
}
artifact_dir <- if (nzchar(script_path) && file.exists(script_path)) {
  dirname(normalizePath(script_path, mustWork = TRUE))
} else {
  getwd()
}
artifact_dir <- normalizePath(artifact_dir, winslash = "/", mustWork = TRUE)
repo_root <- normalizePath(
  file.path(artifact_dir, "..", "..", "..", ".."),
  winslash = "/",
  mustWork = TRUE
)
dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
this_script <- if (nzchar(script_path) && file.exists(script_path)) {
  normalizePath(script_path, winslash = "/", mustWork = TRUE)
} else {
  file.path(artifact_dir, "write-calibrated-grid-delta-drac-dispatch-pack.R")
}
runner_script <- file.path(
  artifact_dir,
  "run-calibrated-grid-delta-resumable-smoke.R"
)
aggregate_script <- file.path(
  artifact_dir,
  "aggregate-calibrated-grid-delta-shards.R"
)

rel_path <- function(path) {
  vapply(
    path,
    function(one_path) {
      normalized <- normalizePath(one_path, winslash = "/", mustWork = FALSE)
      prefix <- paste0(repo_root, "/")
      if (startsWith(normalized, prefix)) {
        substring(normalized, nchar(prefix) + 1L)
      } else {
        normalized
      }
    },
    character(1L)
  )
}

write_table <- function(x, path) {
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = ""
  )
}

write_lines <- function(x, path, mode = "0644") {
  writeLines(x, con = path, useBytes = TRUE)
  Sys.chmod(path, mode = mode)
}

scale_levels <- paste(sd_scales, collapse = ";")
planned_seed_scale_cells <- n_rep * length(sd_scales)
planned_target_rows <- planned_seed_scale_cells * 6L
coverage_mcse_at_nominal <- sqrt(
  nominal_coverage * (1 - nominal_coverage) / n_rep
)
failure_rate_mcse_at_reference <- sqrt(
  failure_rate_reference * (1 - failure_rate_reference) / n_rep
)
cells_per_shard <- vapply(
  seq_len(n_shards),
  function(i) {
    sum(((seq_len(planned_seed_scale_cells) - 1L) %% n_shards) + 1L == i)
  },
  integer(1L)
)

pack_dir <- file.path(
  artifact_dir,
  "q4-derived-correlation-delta-grid-drac-dispatch-pack"
)
slurm_dir <- file.path(pack_dir, "slurm")
dir.create(slurm_dir, recursive = TRUE, showWarnings = FALSE)

shard_root <- file.path(
  artifact_dir,
  "q4-derived-correlation-delta-grid-drac-shards"
)
pack_manifest <- file.path(
  pack_dir,
  "q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv"
)
dashboard_sidecar <- file.path(
  dashboard_dir,
  "structured-re-q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv"
)
array_script <- file.path(
  slurm_dir,
  "q4-derived-correlation-delta-grid-array.sbatch"
)
array_worker <- file.path(
  slurm_dir,
  "q4-derived-correlation-delta-grid-array-worker.sh"
)
totoro_worker <- file.path(
  slurm_dir,
  "q4-derived-correlation-delta-grid-totoro-worker.sh"
)
aggregate_runner <- file.path(
  slurm_dir,
  "q4-derived-correlation-delta-grid-aggregate.sh"
)
readme_path <- file.path(pack_dir, "README.md")

claim_boundary <- paste(
  "Q4 derived-correlation DRAC/totoro dispatch pack only; no q4 interval",
  "reliability, interval coverage, q4 REML, AI-REML, HSquared transfer,",
  "broad bridge support, DRAC readiness, or SR150 acceptance is promoted."
)
aggregate_gate <- paste0(
  "after_all_",
  n_shards,
  "_shard_manifests_expect_",
  planned_seed_scale_cells,
  "_cells_",
  planned_target_rows,
  "_rows_compute_rate_mcse_true"
)
mcse_policy <- paste0(
  "coverage_mcse_at_0.95_equals_",
  sprintf("%.6f", coverage_mcse_at_nominal),
  ";failure_rate_mcse_at_0.05_equals_",
  sprintf("%.6f", failure_rate_mcse_at_reference),
  ";diagnostic_rate_mcse_requires_compute_rate_mcse_true"
)
storage_policy <- "project_backed_private_shards_no_login_node_compute"

manifest_rows <- data.frame(
  pack_id = rep("q4_derived_delta_grid_drac_dispatch_pack", 6L),
  slice_id = rep("SR150", 6L),
  target = rep("gaussian_q4_phylo", 6L),
  pack_component = c(
    "manifest",
    "drac_slurm_array",
    "drac_array_worker",
    "totoro_worker",
    "aggregate_afterok",
    "readme"
  ),
  artifact_path = rel_path(c(
    pack_manifest,
    array_script,
    array_worker,
    totoro_worker,
    aggregate_runner,
    readme_path
  )),
  planned_n_rep = rep(n_rep, 6L),
  scale_levels = rep(scale_levels, 6L),
  planned_shards = rep(n_shards, 6L),
  planned_drac_array_tasks = rep(drac_array_tasks, 6L),
  planned_totoro_shards = rep(n_shards - drac_array_tasks, 6L),
  planned_seed_scale_cells = rep(planned_seed_scale_cells, 6L),
  planned_target_rows = rep(planned_target_rows, 6L),
  scheduler = rep("slurm_template_for_drac_plus_separate_totoro_worker", 6L),
  scheduler_status = rep("dry_run_not_submitted", 6L),
  compute_status = rep("not_submitted", 6L),
  account_placeholder = rep(account, 6L),
  time_limit = rep(time_limit, 6L),
  mem = rep(mem, 6L),
  cpus_per_task = rep(cpus_per_task, 6L),
  output_root = rep(rel_path(shard_root), 6L),
  aggregate_label = rep(aggregate_label, 6L),
  aggregate_gate = rep(aggregate_gate, 6L),
  mcse_policy = rep(mcse_policy, 6L),
  storage_policy = rep(storage_policy, 6L),
  status = rep("covered", 6L),
  claim_boundary = rep(claim_boundary, 6L),
  next_gate = rep(
    paste(
      "Select the actual DRAC account/cluster, submit only the eight-task",
      "DRAC array after login, run the separate totoro shard if used, then",
      "aggregate with compute-rate MCSE enabled only after all nine shard",
      "manifests exist."
    ),
    6L
  ),
  stringsAsFactors = FALSE
)
write_table(manifest_rows, pack_manifest)

sidecar_rows <- data.frame(
  pack_id = c(
    "q4_derived_delta_grid_drac_dispatch_pack_entrypoint",
    "q4_derived_delta_grid_drac_dispatch_pack_slurm_array",
    "q4_derived_delta_grid_drac_dispatch_pack_worker",
    "q4_derived_delta_grid_drac_dispatch_pack_totoro",
    "q4_derived_delta_grid_drac_dispatch_pack_aggregate",
    "q4_derived_delta_grid_drac_dispatch_pack_storage",
    "q4_derived_delta_grid_drac_dispatch_pack_mcse",
    "q4_derived_delta_grid_drac_dispatch_pack_sr150_gate"
  ),
  slice_id = rep("SR150", 8L),
  target = rep("gaussian_q4_phylo", 8L),
  pack_component = c(
    "entrypoint",
    "slurm_array",
    "drac_array_worker",
    "totoro_worker",
    "aggregate_gate",
    "storage_policy",
    "mcse_gate",
    "sr150_gate"
  ),
  source_script = rep(rel_path(this_script), 8L),
  pack_manifest = rep(rel_path(pack_manifest), 8L),
  slurm_array_script = rep(rel_path(array_script), 8L),
  worker_script = rep(rel_path(array_worker), 8L),
  totoro_worker_script = rep(rel_path(totoro_worker), 8L),
  aggregate_script = rep(rel_path(aggregate_runner), 8L),
  planned_n_rep = rep(n_rep, 8L),
  scale_levels = rep(scale_levels, 8L),
  planned_shards = rep(n_shards, 8L),
  planned_drac_array_tasks = rep(drac_array_tasks, 8L),
  planned_totoro_shards = rep(n_shards - drac_array_tasks, 8L),
  planned_seed_scale_cells = rep(planned_seed_scale_cells, 8L),
  planned_target_rows = rep(planned_target_rows, 8L),
  cells_per_shard = rep(paste(cells_per_shard, collapse = ";"), 8L),
  scheduler_status = rep("slurm_array_dry_run_not_submitted", 8L),
  compute_status = rep("not_submitted", 8L),
  storage_policy = rep(storage_policy, 8L),
  aggregate_gate = rep(aggregate_gate, 8L),
  mcse_policy = rep(mcse_policy, 8L),
  status = rep("covered", 8L),
  evidence_url = rel_path(c(
    pack_manifest,
    array_script,
    array_worker,
    totoro_worker,
    aggregate_runner,
    readme_path,
    pack_manifest,
    dashboard_sidecar
  )),
  claim_boundary = rep(claim_boundary, 8L),
  next_gate = rep(
    paste(
      "Replace the account placeholder, choose the actual DRAC host/account",
      "after login, run no compute on login nodes, then aggregate only after",
      "all nine private shard manifests exist and validator checks pass."
    ),
    8L
  ),
  stringsAsFactors = FALSE
)
write_table(sidecar_rows, dashboard_sidecar)

common_compute_flags <- c(
  "--n-rep=500",
  "--seed-start=202607500",
  "--sd-scales=0.35,0.50",
  "--cell-limit=1000",
  "--n-shards=9",
  "--allow-large=true"
)
common_compute_flag_lines <- paste0("  ", common_compute_flags, " \\")

write_lines(
  c(
    "#!/usr/bin/env bash",
    "# DRY-RUN TEMPLATE: submit only after a DRAC account/cluster is selected.",
    sprintf("#SBATCH --job-name=%s", "drmtmb-q4-delta"),
    sprintf("#SBATCH --array=1-%d", drac_array_tasks),
    sprintf("#SBATCH --cpus-per-task=%d", cpus_per_task),
    sprintf("#SBATCH --mem=%s", mem),
    sprintf("#SBATCH --time=%s", time_limit),
    sprintf("#SBATCH --account=%s", account),
    "#SBATCH --output=logs/%x-%A-%a.out",
    "#SBATCH --error=logs/%x-%A-%a.err",
    "",
    "set -euo pipefail",
    "SCRIPT_DIR=$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)",
    "bash \"${SCRIPT_DIR}/q4-derived-correlation-delta-grid-array-worker.sh\"",
    ""
  ),
  array_script,
  mode = "0755"
)

write_lines(
  c(
    "#!/usr/bin/env bash",
    "# DRY-RUN TEMPLATE: run from the repository root inside a submitted DRAC array task.",
    "set -euo pipefail",
    "",
    "SHARD_INDEX=\"${SLURM_ARRAY_TASK_ID:?SLURM_ARRAY_TASK_ID is required}\"",
    sprintf(
      "if [ \"${SHARD_INDEX}\" -lt 1 ] || [ \"${SHARD_INDEX}\" -gt %d ]; then",
      drac_array_tasks
    ),
    "  echo \"DRAC array worker only handles shard indices 1-8\" >&2",
    "  exit 2",
    "fi",
    "SHARD_TAG=$(printf \"shard_%02d\" \"${SHARD_INDEX}\")",
    "REPO_ROOT=\"${REPO_ROOT:-$PWD}\"",
    "ARTIFACT_DIR=\"${REPO_ROOT}/docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight\"",
    "RUNNER=\"${ARTIFACT_DIR}/run-calibrated-grid-delta-resumable-smoke.R\"",
    "SHARD_ROOT=\"${ARTIFACT_DIR}/q4-derived-correlation-delta-grid-drac-shards/${SHARD_TAG}\"",
    "mkdir -p \"${SHARD_ROOT}\"",
    "",
    "Rscript --vanilla \"${RUNNER}\" \\",
    common_compute_flag_lines,
    "  --shard-index=\"${SHARD_INDEX}\" \\",
    "  --run-label=\"r63_drac_compute_${SHARD_TAG}\" \\",
    "  --output-root=\"${SHARD_ROOT}/cells\" \\",
    "  --manifest-dir=\"${SHARD_ROOT}\" \\",
    "  --manifest-file=\"q4-derived-correlation-delta-grid-${SHARD_TAG}-manifest.tsv\" \\",
    "  --run-log-dir=\"${SHARD_ROOT}\" \\",
    "  --run-log-file=\"q4-derived-correlation-delta-grid-${SHARD_TAG}-run-log.tsv\" \\",
    "  --force=true \\",
    "  --reset-output=true \\",
    "  --reset-log=true",
    "",
    "Rscript --vanilla \"${RUNNER}\" \\",
    common_compute_flag_lines,
    "  --shard-index=\"${SHARD_INDEX}\" \\",
    "  --run-label=\"r63_drac_resume_${SHARD_TAG}\" \\",
    "  --output-root=\"${SHARD_ROOT}/cells\" \\",
    "  --manifest-dir=\"${SHARD_ROOT}\" \\",
    "  --manifest-file=\"q4-derived-correlation-delta-grid-${SHARD_TAG}-manifest.tsv\" \\",
    "  --run-log-dir=\"${SHARD_ROOT}\" \\",
    "  --run-log-file=\"q4-derived-correlation-delta-grid-${SHARD_TAG}-run-log.tsv\" \\",
    "  --force=false",
    ""
  ),
  array_worker,
  mode = "0755"
)

write_lines(
  c(
    "#!/usr/bin/env bash",
    "# DRY-RUN TEMPLATE: run on totoro only after the maintainer connects/authenticates it.",
    "set -euo pipefail",
    "",
    "SHARD_INDEX=9",
    "SHARD_TAG=$(printf \"shard_%02d\" \"${SHARD_INDEX}\")",
    "REPO_ROOT=\"${REPO_ROOT:-$PWD}\"",
    "ARTIFACT_DIR=\"${REPO_ROOT}/docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight\"",
    "RUNNER=\"${ARTIFACT_DIR}/run-calibrated-grid-delta-resumable-smoke.R\"",
    "SHARD_ROOT=\"${ARTIFACT_DIR}/q4-derived-correlation-delta-grid-drac-shards/${SHARD_TAG}\"",
    "mkdir -p \"${SHARD_ROOT}\"",
    "",
    "Rscript --vanilla \"${RUNNER}\" \\",
    common_compute_flag_lines,
    "  --shard-index=\"${SHARD_INDEX}\" \\",
    "  --run-label=\"r63_totoro_compute_${SHARD_TAG}\" \\",
    "  --output-root=\"${SHARD_ROOT}/cells\" \\",
    "  --manifest-dir=\"${SHARD_ROOT}\" \\",
    "  --manifest-file=\"q4-derived-correlation-delta-grid-${SHARD_TAG}-manifest.tsv\" \\",
    "  --run-log-dir=\"${SHARD_ROOT}\" \\",
    "  --run-log-file=\"q4-derived-correlation-delta-grid-${SHARD_TAG}-run-log.tsv\" \\",
    "  --force=true \\",
    "  --reset-output=true \\",
    "  --reset-log=true",
    "",
    "Rscript --vanilla \"${RUNNER}\" \\",
    common_compute_flag_lines,
    "  --shard-index=\"${SHARD_INDEX}\" \\",
    "  --run-label=\"r63_totoro_resume_${SHARD_TAG}\" \\",
    "  --output-root=\"${SHARD_ROOT}/cells\" \\",
    "  --manifest-dir=\"${SHARD_ROOT}\" \\",
    "  --manifest-file=\"q4-derived-correlation-delta-grid-${SHARD_TAG}-manifest.tsv\" \\",
    "  --run-log-dir=\"${SHARD_ROOT}\" \\",
    "  --run-log-file=\"q4-derived-correlation-delta-grid-${SHARD_TAG}-run-log.tsv\" \\",
    "  --force=false",
    ""
  ),
  totoro_worker,
  mode = "0755"
)

write_lines(
  c(
    "#!/usr/bin/env bash",
    "# DRY-RUN TEMPLATE: run only after the DRAC array and totoro shard finish successfully.",
    "# For SLURM, submit manually with a dependency such as:",
    "# sbatch --dependency=afterok:<array_job_id> q4-derived-correlation-delta-grid-aggregate.sh",
    "set -euo pipefail",
    "",
    "REPO_ROOT=\"${REPO_ROOT:-$PWD}\"",
    "ARTIFACT_DIR=\"${REPO_ROOT}/docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight\"",
    "AGGREGATE=\"${ARTIFACT_DIR}/aggregate-calibrated-grid-delta-shards.R\"",
    "SHARD_ROOT=\"${ARTIFACT_DIR}/q4-derived-correlation-delta-grid-drac-shards\"",
    "",
    "Rscript --vanilla \"${AGGREGATE}\" \\",
    "  --shard-root=\"${SHARD_ROOT}\" \\",
    "  --n-shards=9 \\",
    "  --expected-cells=1000 \\",
    "  --expected-target-rows=6000 \\",
    sprintf("  --aggregate-label=%s \\", aggregate_label),
    "  --compute-rate-mcse=true",
    ""
  ),
  aggregate_runner,
  mode = "0755"
)

write_lines(
  c(
    "# q4 derived-correlation DRAC/totoro dispatch pack",
    "",
    "This is a dry-run dispatch pack. It should not be submitted until a DRAC",
    "account, cluster, module stack, and login session have been selected.",
    "",
    "- `slurm/q4-derived-correlation-delta-grid-array.sbatch` is an eight-task",
    "  DRAC SLURM array template for shards 1-8.",
    "- `slurm/q4-derived-correlation-delta-grid-array-worker.sh` runs a forced",
    "  compute pass and a no-force resume pass inside each DRAC shard root.",
    "- `slurm/q4-derived-correlation-delta-grid-totoro-worker.sh` runs shard 9",
    "  separately on `totoro` if the hybrid plan is used.",
    "- `slurm/q4-derived-correlation-delta-grid-aggregate.sh` aggregates only",
    "  after all nine private shard manifests exist and enables diagnostic rate",
    "  MCSE fields.",
    "",
    "The pack is CPU-only, uses private shard roots, and does not promote q4",
    "interval reliability, interval coverage, q4 REML, AI-REML, HSquared",
    "transfer, broad bridge support, DRAC readiness, or SR150 acceptance.",
    ""
  ),
  readme_path
)

message("Wrote ", pack_manifest)
message("Wrote ", dashboard_sidecar)
message("Wrote ", array_script)
message("Wrote ", array_worker)
message("Wrote ", totoro_worker)
message("Wrote ", aggregate_runner)
message("Wrote ", readme_path)
