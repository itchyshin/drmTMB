# Per-attempt S7 worker interface.  Source prepare-s7-campaign-manifest.R and
# s7-attempt-contract.R first.  This initial layer only resolves an immutable
# task/engine/target identity; it does not fit or submit work.

r071_s7_worker_spec <- function(manifest, profile_plan, task, engine, parm) {
  if (!exists("r071_s7_task", mode = "function", inherits = TRUE) ||
      !exists("r071_s7_validate_attempt", mode = "function", inherits = TRUE)) {
    stop("source the S7 manifest and attempt-contract helpers before the worker", call. = FALSE)
  }
  task_row <- r071_s7_task(manifest, task)
  target <- profile_plan[
    profile_plan$fixture == task_row$fixture[[1L]] &
      profile_plan$engine == engine & profile_plan$parm == parm,
    , drop = FALSE
  ]
  if (nrow(target) != 1L) {
    stop("worker target is absent from the frozen profile plan", call. = FALSE)
  }
  list(
    logical_task_id = as.integer(task_row$logical_task_id[[1L]]),
    fixture = as.character(task_row$fixture[[1L]]),
    dgp_seed = as.integer(task_row$dgp_seed[[1L]]),
    engine = as.character(target$engine[[1L]]),
    parm = as.character(target$parm[[1L]]),
    target_class = as.character(target$target_class[[1L]]),
    truth = as.numeric(target$truth[[1L]])
  )
}

r071_s7_worker_args <- function(args) {
  if (any(!grepl("^--[A-Za-z][A-Za-z-]*=.+$", args))) {
    stop("S7 worker arguments must use --name=value syntax", call. = FALSE)
  }
  key <- sub("^--([^=]+)=.*$", "\\1", args)
  if (anyDuplicated(key)) stop("duplicate S7 worker argument", call. = FALSE)
  out <- stats::setNames(sub("^--[^=]+=", "", args), key)
  required <- c("root", "task", "engine", "parm", "out", "dry-run")
  if (!identical(sort(names(out)), sort(required))) {
    stop("S7 worker needs exactly --root, --task, --engine, --parm, --out, and --dry-run", call. = FALSE)
  }
  if (!out[["dry-run"]] %in% c("true", "false")) stop("--dry-run must be true or false", call. = FALSE)
  out
}

r071_s7_worker_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  a <- r071_s7_worker_args(args)
  root <- normalizePath(a[["root"]], mustWork = TRUE)
  out <- normalizePath(a[["out"]], mustWork = FALSE)
  if (!dir.exists(out)) dir.create(out, recursive = TRUE, showWarnings = FALSE)
  helper_dir <- file.path(root, "docs", "dev-log", "evidence", "julia-r-parity", "071-ordinary-laplace")
  for (file in c("prepare-s7-campaign-manifest.R", "s7-attempt-contract.R")) {
    path <- file.path(helper_dir, file)
    if (!file.exists(path)) stop("missing S7 helper: ", path, call. = FALSE)
    sys.source(path, envir = .GlobalEnv)
  }
  spec <- r071_s7_worker_spec(
    manifest = r071_s7_manifest(), profile_plan = r071_s7_profile_plan(),
    task = as.integer(a[["task"]]), engine = a[["engine"]], parm = a[["parm"]]
  )
  planned <- as.data.frame(spec, stringsAsFactors = FALSE)
  utils::write.table(planned, file.path(out, "planned-attempt.tsv"),
                     sep = "\t", quote = FALSE, row.names = FALSE)
  if (identical(a[["dry-run"]], "true")) return(invisible(spec))
  stop("S7 fitting worker is not enabled until the post-cost approval gate is recorded", call. = FALSE)
}

if (sys.nframe() == 0L) r071_s7_worker_main()
