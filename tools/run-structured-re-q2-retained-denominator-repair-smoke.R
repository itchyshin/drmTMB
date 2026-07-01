#!/usr/bin/env Rscript
#
# q2 retained-denominator repair-smoke wrapper.
#
# This wrapper reads the Fisher/Rose/Grace repair contract and dispatches only
# the five small repair-smoke cells declared there. It is deliberately
# no-promotion machinery: it writes command manifests, preserves the exact seed
# ranges, and forwards to the existing q2 intercept / q2-plus-q2 smoke runners
# with --write-dashboard=false.

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q2-retained-denominator-repair-smoke.R [options]",
      "",
      "Options:",
      "  --cell-ids=a,b           Contract cell IDs to run (default: all five).",
      "  --host-class=CLASS       Host class stamped into artifacts.",
      "  --host-name=NAME         Host name stamped into artifacts.",
      "  --output-root=PATH       Root for per-cell artifact directories.",
      "  --profile-max-eval=N     Override endpoint profile budget.",
      "  --interval-repair-channel=CHANNEL",
      "                           Diagnostic repair sidecar forwarded to the smoke runners.",
      "  --overwrite=true         Replace existing output root.",
      "  --write-dashboard=false  Required; repair smokes never edit dashboard status.",
      "  --dry-run=true           Write command manifest only.",
      "  --allow-trillium=true    Permit Trillium only after source/root checks pass.",
      "  --cleanup-note=TEXT      Required for non-dry-run Totoro execution.",
      "",
      "This promotes exactly no Q-Series row; it is a small repair smoke after",
      "source/root checks only, not SR475/SR1000 top-up, inference_ready,",
      "supported, q4/q8, non-Gaussian interval, REML, AI-REML, bridge support,",
      "or public support evidence.",
      "",
      sep = "\n"
    )
  )
  quit(status = 0)
}

arg_value <- function(name, default = NULL) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (length(hit) == 0L) {
    return(default)
  }
  sub(prefix, "", hit[[length(hit)]], fixed = TRUE)
}

arg_flag <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (is.null(value)) {
    return(default)
  }
  tolower(value) %in% c("1", "true", "yes", "y")
}

split_csv <- function(x) {
  if (is.null(x) || !nzchar(x)) {
    return(character())
  }
  out <- trimws(strsplit(x, ",", fixed = TRUE)[[1L]])
  out[nzchar(out)]
}

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
}

parse_seed_range <- function(x, n_rep) {
  pieces <- strsplit(x, "-", fixed = TRUE)[[1L]]
  if (length(pieces) != 2L) {
    stop("Seed range must be START-END: ", x, call. = FALSE)
  }
  start <- suppressWarnings(as.integer(pieces[[1L]]))
  end <- suppressWarnings(as.integer(pieces[[2L]]))
  if (!is.finite(start) || !is.finite(end) || end < start) {
    stop("Invalid seed range: ", x, call. = FALSE)
  }
  if ((end - start + 1L) != n_rep) {
    stop(
      "Seed range length does not match smoke_n_rep for ",
      x,
      call. = FALSE
    )
  }
  list(seed_start = 1L, seed_base = start - 1L, seed_end = end)
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root_candidates <- c(
  Sys.getenv("DRMTMB_REPO_ROOT", ""),
  file.path(dirname(script_file), ".."),
  getwd(),
  file.path(getwd(), ".."),
  file.path(getwd(), "..", "..")
)
repo_root_candidates <- repo_root_candidates[nzchar(repo_root_candidates)]
repo_root <- NA_character_
for (candidate in repo_root_candidates) {
  candidate <- normalizePath(candidate, winslash = "/", mustWork = FALSE)
  if (file.exists(file.path(candidate, "DESCRIPTION"))) {
    repo_root <- candidate
    break
  }
}
if (is.na(repo_root)) {
  stop("Cannot locate drmTMB repo root.", call. = FALSE)
}

rel_path <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"), "", path)
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
repair_contract_path <- file.path(
  dashboard_dir,
  "structured-re-q2-retained-denominator-repair-contract.tsv"
)
q2_plus_contract_path <- file.path(
  dashboard_dir,
  "structured-re-q2-plus-q2-intercept-contract.tsv"
)
repair <- read_tsv(repair_contract_path)
required_repair <- c(
  "repair_id",
  "cell_id",
  "provider",
  "repair_status",
  "repair_targets",
  "smoke_n_rep",
  "smoke_seed_range",
  "status_edit_policy",
  "claim_boundary"
)
missing_repair <- setdiff(required_repair, names(repair))
if (length(missing_repair) > 0L) {
  stop(
    "q2 repair contract is missing fields: ",
    paste(missing_repair, collapse = ", "),
    call. = FALSE
  )
}
if (nrow(repair) != 5L) {
  stop("q2 repair contract must contain exactly five cells.", call. = FALSE)
}
if (
  !all(
    repair$repair_status ==
      "fisher_rose_grace_repair_contract_ready_no_promotion"
  )
) {
  stop("q2 repair contract rows are not all repair-smoke ready.", call. = FALSE)
}
if (
  !all(
    repair$status_edit_policy == "do_not_promote_keep_point_fit_planned_planned"
  )
) {
  stop(
    "q2 repair smoke cannot run when status edit policy is not no-promotion.",
    call. = FALSE
  )
}

selected_cell_ids <- split_csv(arg_value(
  "cell-ids",
  paste(repair$cell_id, collapse = ",")
))
unknown_cells <- setdiff(selected_cell_ids, repair$cell_id)
if (length(selected_cell_ids) == 0L || length(unknown_cells) > 0L) {
  stop(
    "`--cell-ids` must be a comma-separated subset of repair-contract cells. Unknown: ",
    paste(unknown_cells, collapse = ", "),
    call. = FALSE
  )
}
repair <- repair[match(selected_cell_ids, repair$cell_id), , drop = FALSE]

write_dashboard <- tolower(arg_value("write-dashboard", "false"))
if (!write_dashboard %in% c("0", "false", "no", "n")) {
  stop("q2 repair smoke must use --write-dashboard=false.", call. = FALSE)
}

dry_run <- arg_flag("dry-run", FALSE)
overwrite <- arg_flag("overwrite", FALSE)
allow_trillium <- arg_flag("allow-trillium", FALSE)
host_class <- arg_value("host-class", "local_repair_smoke")
host_name <- arg_value("host-name", unname(Sys.info()[["nodename"]]))
cleanup_note <- arg_value("cleanup-note", "")
host_gate_text <- tolower(paste(host_class, host_name, collapse = " "))
slurm_cluster <- tolower(trimws(Sys.getenv("SLURM_CLUSTER_NAME", "")))
slurm_job_id <- Sys.getenv("SLURM_JOB_ID", "")
is_slurm_runtime <- nzchar(slurm_cluster) || nzchar(slurm_job_id)
if (grepl("trillium|tri-login", host_gate_text) && !allow_trillium) {
  stop(
    "Trillium requires --allow-trillium=true plus synced source/run-root, ",
    "row-specific command, seed manifest, module list, and host-separated ",
    "provenance before q2 repair-smoke evidence can be imported.",
    call. = FALSE
  )
}
if (identical(slurm_cluster, "trillium") && !allow_trillium) {
  stop(
    "Trillium SLURM repair smoke requires --allow-trillium=true plus ",
    "source/run-root/provenance checks.",
    call. = FALSE
  )
}
if (grepl("fiia", host_gate_text)) {
  stop("FIIA remains blocked until alias/access is configured.", call. = FALSE)
}
if (
  is_slurm_runtime &&
    !slurm_cluster %in% c("nibi", "rorqual", "trillium")
) {
  stop(
    "q2 repair smoke allows only one eligible DRAC host: Nibi, Rorqual, ",
    "or explicitly enabled Trillium.",
    call. = FALSE
  )
}
if (!dry_run && grepl("totoro", host_gate_text) && !nzchar(cleanup_note)) {
  stop(
    "Totoro execution requires --cleanup-note=TEXT so worker cleanup is recorded.",
    call. = FALSE
  )
}

default_output_root <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-30-q2-retained-denominator-repair-smoke-local"
)
output_root <- normalizePath(
  arg_value("output-root", default_output_root),
  winslash = "/",
  mustWork = FALSE
)
if (dir.exists(output_root) && !overwrite) {
  stop(
    "`output-root` already exists. Use --overwrite=true to replace it: ",
    output_root,
    call. = FALSE
  )
}
if (dir.exists(output_root) && overwrite) {
  unlink(output_root, recursive = TRUE)
}
dir.create(output_root, recursive = TRUE, showWarnings = FALSE)

q2_intercept_runner <- file.path(
  repo_root,
  "tools",
  "run-structured-re-q2-intercept-smoke.R"
)
q2_plus_runner <- file.path(
  repo_root,
  "tools",
  "run-structured-re-q2-plus-q2-intercept-smoke.R"
)
q2_plus_contract <- read_tsv(q2_plus_contract_path)
q2_plus_direct <- q2_plus_contract[
  q2_plus_contract$cell_id == "qseries_phylo_q2_plus_q2_intercept" &
    q2_plus_contract$target_kind %in% c("direct_sd", "direct_correlation") &
    q2_plus_contract$estimand != "cor_sigma1_sigma2_intercept",
  ,
  drop = FALSE
]
expected_q2_plus_direct_ids <- c(
  "q2_plus_q2_intercept_phylo_mu1_intercept",
  "q2_plus_q2_intercept_phylo_mu2_intercept",
  "q2_plus_q2_intercept_phylo_cor_mu1_mu2",
  "q2_plus_q2_intercept_phylo_sigma1_intercept",
  "q2_plus_q2_intercept_phylo_sigma2_intercept"
)
if (
  !identical(
    sort(q2_plus_direct$contract_id),
    sort(expected_q2_plus_direct_ids)
  )
) {
  stop(
    "q2-plus repair smoke must resolve exactly five direct repair targets ",
    "and exclude cor_sigma1_sigma2_intercept.",
    call. = FALSE
  )
}

profile_override <- arg_value("profile-max-eval", NULL)
interval_repair_channel <- arg_value("interval-repair-channel", "none")
allowed_repair_channels <- c("none", "bounded_tmbprofile_direct_correlation_sidecar")
if (!interval_repair_channel %in% allowed_repair_channels) {
  stop(
    "`--interval-repair-channel` must be one of: ",
    paste(allowed_repair_channels, collapse = ", "),
    call. = FALSE
  )
}
command_rows <- lapply(seq_len(nrow(repair)), function(i) {
  row <- repair[i, , drop = FALSE]
  n_rep <- as.integer(row$smoke_n_rep)
  seed <- parse_seed_range(row$smoke_seed_range, n_rep)
  cell_dir <- file.path(
    output_root,
    paste0(sprintf("%02d", i), "-", row$cell_id)
  )
  artifact_dir <- file.path(cell_dir, "artifacts")
  is_q2_plus <- identical(row$cell_id, "qseries_phylo_q2_plus_q2_intercept")
  profile_max_eval <- profile_override %||% if (is_q2_plus) "80" else "60"
  runner <- if (is_q2_plus) q2_plus_runner else q2_intercept_runner
  inner_args <- if (is_q2_plus) {
    c(
      paste0("--n-rep=", n_rep),
      "--bootstrap=0",
      paste0("--seed-start=", seed$seed_start),
      paste0("--seed-base=", seed$seed_base),
      paste0(
        "--contract-ids=",
        paste(q2_plus_direct$contract_id, collapse = ",")
      ),
      paste0("--profile-max-eval=", profile_max_eval),
      paste0("--interval-repair-channel=", interval_repair_channel),
      paste0("--host-class=", host_class),
      paste0("--host-name=", host_name),
      paste0("--output-dir=", artifact_dir),
      "--overwrite=true",
      "--write-dashboard=false"
    )
  } else {
    c(
      paste0("--n-rep=", n_rep),
      paste0("--providers=", row$provider),
      "--bootstrap=0",
      paste0("--seed-start=", seed$seed_start),
      paste0("--seed-base=", seed$seed_base),
      paste0("--profile-max-eval=", profile_max_eval),
      paste0("--interval-repair-channel=", interval_repair_channel),
      paste0("--host-class=", host_class),
      paste0("--host-name=", host_name),
      paste0("--output-dir=", artifact_dir),
      "--overwrite=true",
      "--write-dashboard=false"
    )
  }
  command <- paste(
    shQuote(file.path(R.home("bin"), "Rscript")),
    paste(shQuote(c("--no-init-file", runner, inner_args)), collapse = " ")
  )
  data.frame(
    command_id = paste0("q2_retained_denominator_repair_smoke_", row$cell_id),
    repair_id = row$repair_id,
    cell_id = row$cell_id,
    provider = row$provider,
    repair_status = row$repair_status,
    repair_targets = row$repair_targets,
    n_rep = n_rep,
    smoke_seed_range = row$smoke_seed_range,
    seed_start = seed$seed_start,
    seed_base = seed$seed_base,
    seed_end = seed$seed_end,
    profile_max_eval = profile_max_eval,
    interval_repair_channel = interval_repair_channel,
    host_class = host_class,
    host_name = host_name,
    slurm_cluster_name = slurm_cluster %||% "NA",
    slurm_job_id = slurm_job_id %||% "NA",
    output_dir = rel_path(artifact_dir),
    source_repair_contract = rel_path(repair_contract_path),
    selected_contract_ids = if (is_q2_plus) {
      paste(q2_plus_direct$contract_id, collapse = ";")
    } else {
      paste0("provider_targets=", row$provider)
    },
    dry_run = dry_run,
    cleanup_note = cleanup_note %||% "NA",
    promotion_decision = "do_not_promote",
    claim_boundary = paste(
      "This promotes exactly no Q-Series row; q2 retained-denominator",
      "repair smoke is diagnostic-only after source/root checks; it does",
      "not let a diagnostic repair sidecar replace the primary interval",
      "route without Fisher/Rose/Grace review; it does not claim",
      "interval_status, coverage_status, inference_ready,",
      "supported, q2 slope inheritance, q2-plus inheritance, q4/q8,",
      "non-Gaussian intervals, REML, AI-REML, bridge support, or public",
      "support."
    ),
    command = command,
    stringsAsFactors = FALSE
  )
})
manifest <- do.call(rbind, command_rows)
manifest_path <- file.path(
  output_root,
  "structured-re-q2-retained-denominator-repair-smoke-command.tsv"
)
write_tsv(manifest, manifest_path)

if (dry_run) {
  message("dry_run_ok: wrote ", rel_path(manifest_path))
  quit(status = 0L)
}

for (i in seq_len(nrow(manifest))) {
  message(
    "running ",
    manifest$cell_id[[i]],
    " with seed range ",
    manifest$smoke_seed_range[[i]]
  )
  status <- system(manifest$command[[i]])
  if (!identical(status, 0L)) {
    quit(status = status)
  }
}
quit(status = 0L)
