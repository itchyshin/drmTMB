#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

parse_cli_args <- function(args) {
  out <- list(
    mode = "dry-run",
    provider = "all",
    endpoint_member = "all",
    shard_id = NULL
  )
  for (arg in args) {
    if (!startsWith(arg, "--")) {
      next
    }
    parts <- strsplit(sub("^--", "", arg), "=", fixed = TRUE)[[1L]]
    key <- parts[[1L]]
    value <- if (length(parts) > 1L) parts[[2L]] else "TRUE"
    out[[key]] <- value
  }
  out
}

args <- parse_cli_args(commandArgs(TRUE))
mode <- args$mode %||% "dry-run"
if (!identical(mode, "dry-run")) {
  stop(
    "Only `--mode=dry-run` is implemented. Totoro/DRAC execution needs ",
    "reviewed submission approval before this runner can execute refits.",
    call. = FALSE
  )
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-q4-location-slope-bootstrap-runner-contract"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

dispatch_path <- file.path(
  dashboard_dir,
  "structured-re-q4-location-slope-bootstrap-dispatch-plan.tsv"
)
runner_contract_path <- file.path(
  dashboard_dir,
  "structured-re-q4-location-slope-bootstrap-runner-contract.tsv"
)
selected_manifest_path <- file.path(
  artifact_dir,
  "structured-re-q4-location-slope-bootstrap-runner-target-manifest.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-location-slope-bootstrap-runner-run-log.tsv"
)

sanitize_shard_id <- function(x) {
  x <- clean_text(x)
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "-", x)
  x <- gsub("^-+|-+$", "", x)
  if (!nzchar(x)) {
    stop(
      "`--shard_id` must contain at least one letter or digit.",
      call. = FALSE
    )
  }
  x
}

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

read_dashboard_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

required_dispatch_fields <- c(
  "dispatch_id",
  "cell_id",
  "formula_cell",
  "structured_type",
  "target_kind",
  "endpoint_member",
  "estimand",
  "profile_target",
  "bootstrap_replicates",
  "bootstrap_seed",
  "retention_policy",
  "scheduler_status",
  "compute_status",
  "denominator_status",
  "coverage_evaluable",
  "coverage_status",
  "interval_claim_status",
  "status",
  "claim_boundary",
  "next_gate"
)

dispatch <- read_dashboard_tsv(dispatch_path)
missing_dispatch <- setdiff(required_dispatch_fields, names(dispatch))
if (length(missing_dispatch) > 0L) {
  stop(
    "Dispatch manifest is missing fields: ",
    paste(missing_dispatch, collapse = ", "),
    ".",
    call. = FALSE
  )
}
if (nrow(dispatch) != 16L) {
  stop(
    "Dispatch manifest must contain exactly 16 direct-SD targets.",
    call. = FALSE
  )
}
if (any(dispatch$scheduler_status != "dry_run_not_submitted")) {
  stop("Dispatch manifest must remain dry_run_not_submitted.", call. = FALSE)
}
if (any(dispatch$compute_status != "not_executed")) {
  stop("Dispatch manifest must remain not_executed.", call. = FALSE)
}
if (any(dispatch$denominator_status != "dispatch_plan_only")) {
  stop("Dispatch manifest must remain dispatch_plan_only.", call. = FALSE)
}
if (any(as.character(dispatch$coverage_evaluable) != "FALSE")) {
  stop("Dispatch manifest must not be coverage-evaluable.", call. = FALSE)
}
if (any(dispatch$coverage_status != "not_evaluated")) {
  stop(
    "Dispatch manifest must keep coverage_status = not_evaluated.",
    call. = FALSE
  )
}
if (any(dispatch$interval_claim_status != "diagnostic_only")) {
  stop(
    "Dispatch manifest must keep interval_claim_status = diagnostic_only.",
    call. = FALSE
  )
}

required_boundary_phrases <- c(
  "no submitted Totoro job",
  "no submitted DRAC job",
  "no all-target bootstrap denominator evidence",
  "no interval reliability",
  "interval coverage",
  "q4 REML",
  "AI-REML",
  "broad bridge support",
  "public support",
  "calibrated coverage wording"
)
for (phrase in required_boundary_phrases) {
  if (any(!grepl(phrase, dispatch$claim_boundary, fixed = TRUE))) {
    stop(
      "Dispatch claim boundaries must all retain phrase: ",
      phrase,
      call. = FALSE
    )
  }
}

providers <- c("phylo", "spatial", "animal", "relmat")
endpoint_members <- c(
  "mu1:(Intercept)",
  "mu1:x",
  "mu2:(Intercept)",
  "mu2:x"
)
provider_filter <- args$provider %||% "all"
endpoint_filter <- args$endpoint_member %||% "all"
full_contract <- identical(provider_filter, "all") &&
  identical(endpoint_filter, "all")
shard_id <- args$shard_id %||%
  if (full_contract) {
    "all-targets"
  } else {
    paste(
      c(
        if (!identical(provider_filter, "all")) {
          paste0("provider-", provider_filter)
        },
        if (!identical(endpoint_filter, "all")) {
          paste0("endpoint-", endpoint_filter)
        }
      ),
      collapse = "-"
    )
  }
shard_id <- sanitize_shard_id(shard_id)
if (!full_contract && identical(shard_id, "all-targets")) {
  stop(
    "`--shard_id=all-targets` is reserved for the unfiltered full dry-run contract.",
    call. = FALSE
  )
}
if (full_contract && !identical(shard_id, "all-targets")) {
  stop(
    "The unfiltered full dry-run contract must use `--shard_id=all-targets`.",
    call. = FALSE
  )
}
if (!identical(provider_filter, "all") && !provider_filter %in% providers) {
  stop(
    "`--provider` must be all, phylo, spatial, animal, or relmat.",
    call. = FALSE
  )
}
if (
  !identical(endpoint_filter, "all") && !endpoint_filter %in% endpoint_members
) {
  stop(
    "`--endpoint_member` must be all, mu1:(Intercept), mu1:x, ",
    "mu2:(Intercept), or mu2:x.",
    call. = FALSE
  )
}

selected <- dispatch
if (!identical(provider_filter, "all")) {
  selected <- selected[
    selected$structured_type == provider_filter,
    ,
    drop = FALSE
  ]
}
if (!identical(endpoint_filter, "all")) {
  selected <- selected[
    selected$endpoint_member == endpoint_filter,
    ,
    drop = FALSE
  ]
}
if (nrow(selected) == 0L) {
  stop("No dispatch targets match the requested filters.", call. = FALSE)
}

selected_manifest_file <- if (full_contract) {
  "structured-re-q4-location-slope-bootstrap-runner-target-manifest.tsv"
} else {
  paste0(
    "structured-re-q4-location-slope-bootstrap-runner-target-manifest-",
    shard_id,
    ".tsv"
  )
}
run_log_file <- if (full_contract) {
  "structured-re-q4-location-slope-bootstrap-runner-run-log.tsv"
} else {
  paste0(
    "structured-re-q4-location-slope-bootstrap-runner-run-log-",
    shard_id,
    ".tsv"
  )
}
selected_manifest_path <- file.path(artifact_dir, selected_manifest_file)
run_log_path <- file.path(artifact_dir, run_log_file)

source_dispatch_manifest <- paste(
  "docs/dev-log/dashboard",
  "structured-re-q4-location-slope-bootstrap-dispatch-plan.tsv",
  sep = "/"
)
selected_manifest <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-24-q4-location-slope-bootstrap-runner-contract",
  selected_manifest_file,
  sep = "/"
)
run_log <- paste(
  "docs/dev-log/simulation-artifacts",
  "2026-06-24-q4-location-slope-bootstrap-runner-contract",
  run_log_file,
  sep = "/"
)

runner_contract <- data.frame(
  runner_id = paste0(
    "q4_location_slope_bootstrap_runner_",
    selected$dispatch_id
  ),
  dispatch_id = selected$dispatch_id,
  cell_id = selected$cell_id,
  formula_cell = selected$formula_cell,
  structured_type = selected$structured_type,
  target_kind = selected$target_kind,
  endpoint_member = selected$endpoint_member,
  estimand = selected$estimand,
  profile_target = selected$profile_target,
  mode = mode,
  selected = "TRUE",
  source_dispatch_manifest = source_dispatch_manifest,
  selected_manifest = selected_manifest,
  run_log = run_log,
  bootstrap_replicates = selected$bootstrap_replicates,
  bootstrap_seed = selected$bootstrap_seed,
  retention_policy = selected$retention_policy,
  scheduler_status = "dry_run_not_submitted",
  compute_status = "not_executed",
  denominator_status = "runner_contract_only",
  coverage_evaluable = "FALSE",
  coverage_status = "not_evaluated",
  interval_claim_status = "diagnostic_only",
  execution_status = "validated_not_executed",
  status = "covered",
  evidence_url = paste(
    "docs/dev-log/after-task",
    "2026-06-24-q4-location-slope-bootstrap-runner-contract.md",
    sep = "/"
  ),
  claim_boundary = clean_text(paste(
    "q4 location one-slope bootstrap denominator runner contract only;",
    "no bootstrap refits executed, no Totoro job submitted, no DRAC job",
    "submitted, no all-target bootstrap denominator evidence, no",
    "derived-correlation intervals, no interval reliability, interval",
    "coverage, q4 REML, AI-REML, broad bridge support, public support,",
    "partial location-scale support, broader q8 support, or calibrated",
    "coverage wording promoted."
  )),
  next_gate = clean_text(paste(
    "After human review, execute one provider shard at a time with this",
    "selected manifest; use shard-specific manifests and run logs so",
    "provider/target dry-runs cannot overwrite the full contract; retain fit",
    "errors, nonconvergence, pdHess false, nonfinite intervals, bootstrap",
    "refit attempts, and scheduler exit status before denominator accounting."
  )),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
character_cols <- vapply(runner_contract, is.character, logical(1L))
runner_contract[character_cols] <- lapply(
  runner_contract[character_cols],
  clean_text
)

run_log_row <- data.frame(
  run_id = if (full_contract) {
    "q4_location_slope_bootstrap_runner_contract"
  } else {
    paste0("q4_location_slope_bootstrap_runner_contract_", shard_id)
  },
  mode = mode,
  shard_id = shard_id,
  provider_filter = provider_filter,
  endpoint_member_filter = endpoint_filter,
  selected_targets = nrow(runner_contract),
  selected_providers = paste(
    sort(unique(runner_contract$structured_type)),
    collapse = ";"
  ),
  selected_endpoint_members = paste(
    unique(runner_contract$endpoint_member),
    collapse = ";"
  ),
  source_dispatch_manifest = source_dispatch_manifest,
  selected_manifest = selected_manifest,
  runner_contract = paste(
    "docs/dev-log/dashboard",
    "structured-re-q4-location-slope-bootstrap-runner-contract.tsv",
    sep = "/"
  ),
  execution_status = "validated_not_executed",
  scheduler_status = "dry_run_not_submitted",
  compute_status = "not_executed",
  denominator_status = "runner_contract_only",
  coverage_evaluable = "FALSE",
  coverage_status = "not_evaluated",
  interval_claim_status = "diagnostic_only",
  status = "covered",
  claim_boundary = unique(runner_contract$claim_boundary)[[1L]],
  next_gate = unique(runner_contract$next_gate)[[1L]],
  stringsAsFactors = FALSE,
  check.names = FALSE
)
run_log_row[] <- lapply(run_log_row, clean_text)

if (full_contract) {
  utils::write.table(
    runner_contract,
    runner_contract_path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}
utils::write.table(
  runner_contract,
  selected_manifest_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  run_log_row,
  run_log_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

if (full_contract) {
  cat(
    "wrote ",
    runner_contract_path,
    " with ",
    nrow(runner_contract),
    " rows\n",
    sep = ""
  )
} else {
  cat(
    "kept dashboard runner contract unchanged for shard ",
    shard_id,
    "\n",
    sep = ""
  )
}
cat(
  "wrote ",
  selected_manifest_path,
  " with ",
  nrow(runner_contract),
  " rows\n",
  sep = ""
)
cat("wrote ", run_log_path, " with ", nrow(run_log_row), " rows\n", sep = "")
