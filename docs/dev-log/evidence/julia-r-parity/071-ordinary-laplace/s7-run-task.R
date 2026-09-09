#!/usr/bin/env Rscript
# One S7 array index expands to every engine-target profile attempt required
# for that frozen fixture/seed.  Until the post-cost approval is recorded this
# runner is intentionally dry-run only; it never loads drmTMB or Julia.

r071_s7_task_attempt_plan <- function(bundle, task) {
  if (!is.list(bundle) || is.null(bundle$manifest) || is.null(bundle$profile_plan)) {
    stop("S7 task runner needs a validated immutable campaign bundle", call. = FALSE)
  }
  task_row <- r071_s7_task(bundle$manifest, task)
  targets <- bundle$profile_plan[
    bundle$profile_plan$fixture == task_row$fixture[[1L]], , drop = FALSE
  ]
  if (nrow(targets) != task_row$profile_attempt_count[[1L]]) {
    stop("S7 task target count disagrees with frozen manifest", call. = FALSE)
  }
  out <- data.frame(
    logical_task_id = rep.int(task_row$logical_task_id[[1L]], nrow(targets)),
    fixture = rep.int(task_row$fixture[[1L]], nrow(targets)),
    dgp_seed = rep.int(task_row$dgp_seed[[1L]], nrow(targets)),
    engine = targets$engine, parm = targets$parm, target_class = targets$target_class,
    truth = targets$truth, stringsAsFactors = FALSE
  )
  if (nrow(out) != task_row$profile_attempt_count[[1L]] ||
      anyDuplicated(out[c("engine", "parm")])) {
    stop("S7 task attempt expansion is not a fixture-target bijection", call. = FALSE)
  }
  out
}

r071_s7_task_args <- function(args) {
  if (any(!grepl("^--[A-Za-z][A-Za-z-]*=.+$", args))) {
    stop("S7 task arguments must use --name=value syntax", call. = FALSE)
  }
  key <- sub("^--([^=]+)=.*$", "\\1", args)
  if (anyDuplicated(key)) stop("duplicate S7 task argument", call. = FALSE)
  out <- stats::setNames(sub("^--[^=]+=", "", args), key)
  required <- c("root", "bundle", "task", "out", "dry-run")
  if (!identical(sort(names(out)), sort(required))) {
    stop("S7 task runner needs exactly --root, --bundle, --task, --out, and --dry-run", call. = FALSE)
  }
  if (!out[["dry-run"]] %in% c("true", "false")) stop("--dry-run must be true or false", call. = FALSE)
  out
}

r071_s7_task_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  a <- r071_s7_task_args(args)
  root <- normalizePath(a[["root"]], mustWork = TRUE)
  bundle_path <- normalizePath(a[["bundle"]], mustWork = TRUE)
  out <- normalizePath(a[["out"]], mustWork = FALSE)
  if (!dir.exists(out)) dir.create(out, recursive = TRUE, showWarnings = FALSE)
  helper_dir <- file.path(root, "docs", "dev-log", "evidence", "julia-r-parity", "071-ordinary-laplace")
  for (file in c("prepare-s7-campaign-manifest.R", "prepare-s7-campaign-bundle.R")) {
    path <- file.path(helper_dir, file)
    if (!file.exists(path)) stop("missing S7 helper: ", path, call. = FALSE)
    sys.source(path, envir = .GlobalEnv)
  }
  plan <- r071_s7_task_attempt_plan(
    r071_s7_read_campaign_bundle(bundle_path), as.integer(a[["task"]])
  )
  r071_s7_atomic_write(file.path(out, "planned-task.tsv"), function(file) {
    utils::write.table(plan, file, sep = "\t", quote = FALSE, row.names = FALSE)
  })
  if (identical(a[["dry-run"]], "true")) return(invisible(plan))
  stop("S7 fitting task runner is not enabled until the post-cost approval gate is recorded", call. = FALSE)
}

if (sys.nframe() == 0L) r071_s7_task_main()
