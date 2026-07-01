#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q2-retained-denominator-pregrid.R [options]",
      "",
      "Runs only the reviewed q2 SR150 retained-denominator pregrid.",
      "",
      "Required/guarded options:",
      "  --pregrid-family=q2_intercept|q2_plus_q2_intercept",
      "  --n-rep=150",
      "  --write-dashboard=false",
      "  --host-class=<nibi-or-rorqual label>",
      "",
      "Options:",
      "  --providers=a,b,c         q2_intercept providers (default: phylo,spatial,animal,relmat).",
      "  --seed-start=N            First replicate index (default: 1).",
      "  --seed-base=N             Seed base forwarded to the runner (default: runner default).",
      "  --profile-max-eval=N      Endpoint-profile evaluation budget.",
      "  --output-dir=PATH         Artifact directory.",
      "  --overwrite=true          Replace an existing artifact directory.",
      "  --dry-run=true            Validate and write command manifest only.",
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
  stop(
    "Cannot locate drmTMB repo root from script path or working directory.",
    call. = FALSE
  )
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
design_path <- file.path(
  dashboard_dir,
  "structured-re-q2-retained-denominator-design.tsv"
)
design <- read_tsv(design_path)
required_design <- c(
  "design_id",
  "cell_id",
  "provider",
  "design_family",
  "source_interval_contract_id",
  "target_decision",
  "pregrid_n_rep",
  "design_status",
  "linked_support_status",
  "promotion_decision"
)
missing_design <- setdiff(required_design, names(design))
if (length(missing_design) > 0L) {
  stop(
    "q2 retained-denominator design is missing fields: ",
    paste(missing_design, collapse = ", "),
    call. = FALSE
  )
}
if (nrow(design) != 18L) {
  stop(
    "q2 retained-denominator design must keep exactly 18 target rows.",
    call. = FALSE
  )
}
if (sum(design$target_decision == "sr150_pregrid_ready_no_promotion") != 17L) {
  stop(
    "q2 retained-denominator design must keep exactly 17 SR150-ready rows.",
    call. = FALSE
  )
}
if (sum(design$target_decision == "profile_repair_required_no_pregrid") != 1L) {
  stop(
    "q2 retained-denominator design must keep exactly one repair-held row.",
    call. = FALSE
  )
}
if (!all(design$promotion_decision == "do_not_promote")) {
  stop(
    "q2 retained-denominator pregrid cannot promote support cells.",
    call. = FALSE
  )
}
if (!all(design$linked_support_status == "point_fit/planned/planned")) {
  stop(
    "q2 retained-denominator pregrid requires linked support cells to remain planned.",
    call. = FALSE
  )
}
if (!all(design$pregrid_n_rep %in% c(0L, 150L))) {
  stop(
    "q2 retained-denominator design must keep pregrid_n_rep in {0, 150}.",
    call. = FALSE
  )
}

pregrid_family <- arg_value("pregrid-family", "q2_intercept")
allowed_families <- c("q2_intercept", "q2_plus_q2_intercept")
if (!pregrid_family %in% allowed_families) {
  stop(
    "`--pregrid-family` must be one of: ",
    paste(allowed_families, collapse = ", "),
    call. = FALSE
  )
}

n_rep <- as.integer(arg_value("n-rep", "150"))
if (!is.finite(n_rep) || n_rep != 150L) {
  stop(
    "q2 retained-denominator pregrid requires exactly --n-rep=150.",
    call. = FALSE
  )
}

write_dashboard <- tolower(arg_value("write-dashboard", "false"))
if (!write_dashboard %in% c("0", "false", "no", "n")) {
  stop(
    "q2 retained-denominator pregrid must use --write-dashboard=false.",
    call. = FALSE
  )
}

dry_run <- arg_flag("dry-run", FALSE)
host_class <- arg_value("host-class", NULL)
outer_host_name <- arg_value("host-name", unname(Sys.info()[["nodename"]]))
inner_host_name <- "retained_denominator_pregrid_runtime"
if (
  !dry_run &&
    (is.null(host_class) || !grepl("nibi|rorqual", tolower(host_class)))
) {
  stop(
    "q2 retained-denominator pregrid requires a Nibi/Rorqual host class; ",
    "use --dry-run=true for local command-manifest rehearsal.",
    call. = FALSE
  )
}
slurm_cluster <- tolower(Sys.getenv("SLURM_CLUSTER_NAME", ""))
slurm_job_id <- Sys.getenv("SLURM_JOB_ID", "")
if (
  !dry_run &&
    (!slurm_cluster %in% c("nibi", "rorqual") || !nzchar(slurm_job_id))
) {
  stop(
    "q2 retained-denominator pregrid requires SLURM runtime on Nibi/Rorqual. ",
    "Saw SLURM_CLUSTER_NAME='",
    Sys.getenv("SLURM_CLUSTER_NAME", ""),
    "' and SLURM_JOB_ID='",
    slurm_job_id,
    "'.",
    call. = FALSE
  )
}

selected_design <- design[
  design$design_family == pregrid_family &
    design$target_decision == "sr150_pregrid_ready_no_promotion",
  ,
  drop = FALSE
]
if (pregrid_family == "q2_intercept") {
  providers <- split_csv(arg_value("providers", "phylo,spatial,animal,relmat"))
  allowed_providers <- c("phylo", "spatial", "animal", "relmat")
  unknown_providers <- setdiff(providers, allowed_providers)
  if (length(providers) == 0L || length(unknown_providers) > 0L) {
    stop(
      "`--providers` must be a comma-separated subset of: phylo,spatial,animal,relmat.",
      call. = FALSE
    )
  }
  selected_design <- selected_design[
    selected_design$provider %in% providers,
    ,
    drop = FALSE
  ]
  expected_rows <- 3L * length(providers)
  if (nrow(selected_design) != expected_rows) {
    stop(
      "q2 intercept pregrid expected ",
      expected_rows,
      " ready target rows for selected providers.",
      call. = FALSE
    )
  }
  runner <- file.path(
    repo_root,
    "tools",
    "run-structured-re-q2-intercept-smoke.R"
  )
  inner_args <- c(
    paste0("--n-rep=", n_rep),
    paste0("--providers=", paste(providers, collapse = ",")),
    "--bootstrap=0",
    paste0("--host-name=", inner_host_name),
    "--host-class=retained_denominator_pregrid",
    "--write-dashboard=false"
  )
  profile_default <- "60"
} else {
  providers <- unique(selected_design$provider)
  if (!identical(providers, "phylo") || nrow(selected_design) != 5L) {
    stop(
      "q2-plus-q2 pregrid must contain exactly five ready phylo targets.",
      call. = FALSE
    )
  }
  runner <- file.path(
    repo_root,
    "tools",
    "run-structured-re-q2-plus-q2-intercept-smoke.R"
  )
  inner_args <- c(
    paste0("--n-rep=", n_rep),
    "--bootstrap=0",
    paste0(
      "--contract-ids=",
      paste(selected_design$source_interval_contract_id, collapse = ",")
    ),
    paste0("--host-name=", inner_host_name),
    "--host-class=retained_denominator_pregrid",
    "--write-dashboard=false"
  )
  profile_default <- "80"
}

seed_start <- arg_value("seed-start", NULL)
if (!is.null(seed_start)) {
  inner_args <- c(inner_args, paste0("--seed-start=", seed_start))
}
seed_base <- arg_value("seed-base", NULL)
if (!is.null(seed_base)) {
  inner_args <- c(inner_args, paste0("--seed-base=", seed_base))
}
profile_max_eval <- arg_value("profile-max-eval", profile_default)
inner_args <- c(inner_args, paste0("--profile-max-eval=", profile_max_eval))

default_output_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  paste0(
    "2026-06-30-q2-retained-denominator-",
    pregrid_family,
    "-pregrid-local"
  )
)
output_dir <- normalizePath(
  arg_value("output-dir", default_output_dir),
  winslash = "/",
  mustWork = FALSE
)
inner_args <- c(inner_args, paste0("--output-dir=", output_dir))
if (arg_flag("overwrite", FALSE)) {
  inner_args <- c(inner_args, "--overwrite=true")
}

command <- paste(
  shQuote(file.path(R.home("bin"), "Rscript")),
  paste(shQuote(c("--no-init-file", runner, inner_args)), collapse = " ")
)
manifest <- data.frame(
  pregrid_family = pregrid_family,
  selected_providers = paste(providers, collapse = ","),
  selected_target_count = nrow(selected_design),
  selected_contract_ids = paste(
    selected_design$source_interval_contract_id,
    collapse = ";"
  ),
  n_rep = n_rep,
  profile_max_eval = profile_max_eval,
  source_design = "docs/dev-log/dashboard/structured-re-q2-retained-denominator-design.tsv",
  output_dir = output_dir,
  requested_host_class = host_class %||% "NA",
  requested_host_name = outer_host_name,
  inner_host_class = "retained_denominator_pregrid",
  inner_host_name = inner_host_name,
  dry_run = dry_run,
  promotion_decision = "do_not_promote",
  claim_boundary = paste(
    "q2 retained-denominator pregrid artifact only; this promotes exactly no",
    "Q-Series row and does not change interval_status, coverage_status,",
    "inference_ready, supported, q1, q2 slope, q4/q8, non-Gaussian, REML,",
    "AI-REML, bridge support, or public support."
  ),
  command = command,
  stringsAsFactors = FALSE
)
manifest_path <- file.path(
  output_dir,
  "structured-re-q2-retained-denominator-pregrid-command.tsv"
)
write_tsv(manifest, manifest_path)

if (dry_run) {
  message("dry_run_ok: wrote ", manifest_path)
  quit(status = 0L)
}

status <- system2(
  file.path(R.home("bin"), "Rscript"),
  shQuote(c("--no-init-file", runner, inner_args))
)
quit(status = status)
