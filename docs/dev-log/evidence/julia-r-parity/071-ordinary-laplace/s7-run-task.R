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

r071_s7_validate_task_attempts <- function(plan, attempts) {
  required_plan <- c("logical_task_id", "fixture", "dgp_seed", "engine", "parm", "truth")
  if (!is.data.frame(plan) || !all(required_plan %in% names(plan)) ||
      !is.data.frame(attempts)) {
    stop("S7 task receipt needs planned and observed attempt tables", call. = FALSE)
  }
  if (nrow(attempts) != nrow(plan)) {
    stop("S7 task receipt count does not match the frozen task plan", call. = FALSE)
  }
  lapply(seq_len(nrow(attempts)), function(i) r071_s7_validate_attempt(attempts[i, , drop = FALSE]))
  expected_key <- vapply(seq_len(nrow(plan)), function(i) {
    r071_s7_attempt_key(plan[i, , drop = FALSE])
  }, character(1L))
  observed_key <- vapply(seq_len(nrow(attempts)), function(i) {
    r071_s7_attempt_key(attempts[i, , drop = FALSE])
  }, character(1L))
  if (anyDuplicated(observed_key) || !setequal(observed_key, expected_key)) {
    stop("S7 task receipt keys do not match the frozen task plan", call. = FALSE)
  }
  ordered <- attempts[match(expected_key, observed_key), , drop = FALSE]
  if (!isTRUE(all.equal(as.numeric(ordered$truth), as.numeric(plan$truth), tolerance = 1e-12))) {
    stop("S7 task receipt truth does not match the frozen task plan", call. = FALSE)
  }
  invisible(ordered)
}

r071_s7_task_args <- function(args) {
  if (any(!grepl("^--[A-Za-z][A-Za-z-]*=.+$", args))) {
    stop("S7 task arguments must use --name=value syntax", call. = FALSE)
  }
  key <- sub("^--([^=]+)=.*$", "\\1", args)
  if (anyDuplicated(key)) stop("duplicate S7 task argument", call. = FALSE)
  out <- stats::setNames(sub("^--[^=]+=", "", args), key)
  required <- c("root", "bundle", "task", "out", "dry-run")
  allowed <- c(required, "approved")
  if (!all(required %in% names(out)) || any(!names(out) %in% allowed)) {
    stop("S7 task runner needs --root, --bundle, --task, --out, --dry-run, and optional --approved", call. = FALSE)
  }
  if (!out[["dry-run"]] %in% c("true", "false")) stop("--dry-run must be true or false", call. = FALSE)
  if (!"approved" %in% names(out)) out[["approved"]] <- "false"
  if (!out[["approved"]] %in% c("true", "false")) stop("--approved must be true or false", call. = FALSE)
  out
}

r071_s7_task_execution_allowed <- function(args) {
  if (identical(args[["dry-run"]], "true")) return(FALSE)
  if (!identical(args[["approved"]], "true")) {
    stop("S7 live fitting requires --approved=true after the G7 approval gate", call. = FALSE)
  }
  TRUE
}

r071_s7_task_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  a <- r071_s7_task_args(args)
  root <- normalizePath(a[["root"]], mustWork = TRUE)
  bundle_path <- normalizePath(a[["bundle"]], mustWork = TRUE)
  out <- normalizePath(a[["out"]], mustWork = FALSE)
  if (!dir.exists(out)) dir.create(out, recursive = TRUE, showWarnings = FALSE)
  helper_dir <- file.path(root, "docs", "dev-log", "evidence", "julia-r-parity", "071-ordinary-laplace")
  for (file in c(
    "prepare-s7-campaign-manifest.R", "prepare-s7-campaign-bundle.R",
    "s7-attempt-contract.R", "s7-fit-diagnostics.R", "s7-fit-attempt.R",
    "s7-task-dispatch.R", "s7-campaign-fixture.R", "s7-live-fit-factory.R"
  )) {
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
  if (!r071_s7_task_execution_allowed(a)) return(invisible(plan))
  if (!requireNamespace("drmTMB", quietly = TRUE)) {
    stop("S7 live worker requires the preflight-installed drmTMB package", call. = FALSE)
  }
  suppressPackageStartupMessages(library(drmTMB))
  attempts <- r071_s7_dispatch_task(
    plan, r071_s7_make_fixture, r071_s7_engine_fit
  )
  r071_s7_atomic_write(file.path(out, "attempts.tsv"), function(file) {
    utils::write.table(attempts, file, sep = "\t", quote = FALSE, row.names = FALSE)
  })
  invisible(attempts)
}

if (sys.nframe() == 0L) r071_s7_task_main()
