#!/usr/bin/env Rscript
# Execute exactly one immutable B1 task-map row.  The worker is intentionally
# single-threaded; DRAC parallelism is supplied by the Slurm array.

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x
b1_script <- normalizePath(
  sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools/run-b1-breadth-validation.R"),
  mustWork = FALSE
)
b1_root <- dirname(b1_script)
source(file.path(b1_root, "b1-breadth-contract.R"))
source(file.path(b1_root, "b1-breadth-adapters.R"))

b1_raw_columns <- c(
  "logical_task_id", "cell_id", "family", "dpar", "effect", "adapter", "adapter_status", "target",
  "information_rung", "shard", "replicate", "seed", "attempt_status", "attempt_error",
  "convergence", "pdHess", "target_estimate", "field_correlation", "profile_ready", "elapsed_seconds"
)

b1_parse_args <- function(args) {
  out <- list()
  for (arg in args) {
    if (!grepl("^--[A-Za-z][A-Za-z-]*=.+$", arg)) b1_stop("Arguments must use nonempty --name=value syntax.")
    key_value <- strsplit(substring(arg, 3L), "=", fixed = TRUE)[[1L]]
    key <- key_value[[1L]]
    if (!is.null(out[[key]])) b1_stop("Duplicate argument: --", key, ".")
    out[[key]] <- paste(key_value[-1L], collapse = "=")
  }
  required <- c("manifest", "array-index", "out-dir")
  missing <- required[vapply(required, function(x) is.null(out[[x]]) || !nzchar(out[[x]]), logical(1L))]
  if (length(missing)) b1_stop("Missing required argument(s): --", paste(missing, collapse = ", --"), "=.")
  extra <- setdiff(names(out), required)
  if (length(extra)) b1_stop("Unsupported argument(s): --", paste(extra, collapse = ", --"), ".")
  out[["array-index"]] <- suppressWarnings(as.integer(out[["array-index"]]))
  if (length(out[["array-index"]]) != 1L || is.na(out[["array-index"]]) || out[["array-index"]] < 1L) {
    b1_stop("--array-index must be a positive integer.")
  }
  out
}

b1_read_task <- function(manifest_path, array_index) {
  if (!file.exists(manifest_path)) b1_stop("B1 manifest does not exist: ", manifest_path)
  manifest <- utils::read.delim(manifest_path, check.names = FALSE, stringsAsFactors = FALSE)
  missing <- setdiff(b1_required_task_columns, names(manifest))
  if (length(missing)) b1_stop("B1 manifest is missing column(s): ", paste(missing, collapse = ", "), ".")
  hit <- manifest[manifest$array_index == array_index, , drop = FALSE]
  if (nrow(hit) != 1L) b1_stop("B1 manifest has no unique row for array index ", array_index, ".")
  if (hit$replicate_start[[1L]] < 1L || hit$replicate_end[[1L]] < hit$replicate_start[[1L]]) {
    b1_stop("B1 task has an invalid replicate range.")
  }
  hit
}

b1_atomic_write <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile("b1-", tmpdir = dirname(path), fileext = ".tsv")
  on.exit(unlink(temporary), add = TRUE)
  utils::write.table(x, temporary, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
  if (!file.rename(temporary, path)) b1_stop("Could not atomically publish B1 task output: ", path)
  invisible(path)
}

b1_target_estimate <- function(fit, task) {
  block <- task$dpar[[1L]]
  if (identical(block, "sigma1")) block <- "sigma"
  label <- sub("^sd:[^:]+:", "", task$target[[1L]])
  values <- fit$sdpars[[block]]
  if (is.null(values) || !label %in% names(values)) return(NA_real_)
  unname(values[[label]])
}

b1_field_correlation <- function(fit, task, truth) {
  type <- switch(task$cell_id[[1L]],
    "mc-0005" = list(block = "mu", name = "(1 | id)", values = "terms"),
    "mc-0031" = list(block = "mu", name = "(0 + x | id)", values = "terms"),
    "mc-0059" = list(block = "mu", name = "(1 | id)", values = "terms"),
    "mc-0364" = list(block = "relmat_hu", name = "", values = "values"),
    "mc-0511" = list(block = "mu", name = "(0 + x | id)", values = "terms"),
    "mc-0229" = list(block = "phylo_mu", name = "", values = "values"),
    "mc-0495" = list(block = "phylo_nu", name = "", values = "values"),
    "mc-0641" = list(block = "spatial_mu", name = "", values = "values"),
    "mc-0667" = list(block = "spatial_zi", name = "", values = "values"),
    return(NA_real_)
  )
  random <- tryCatch(stats::ranef(fit, type$block), error = function(e) NULL)
  if (is.null(random)) return(NA_real_)
  values <- if (identical(type$values, "terms")) random$terms[[type$name]] else random$values
  if (is.null(values) || is.null(names(values))) return(NA_real_)
  shared <- intersect(names(values), names(truth$field))
  if (length(shared) < 3L) return(NA_real_)
  unname(stats::cor(values[shared], truth$field[shared]))
}

b1_one_attempt <- function(task, replicate, seed) {
  started <- proc.time()[["elapsed"]]
  row <- as.list(rep(NA, length(b1_raw_columns))); names(row) <- b1_raw_columns
  for (name in intersect(names(task), names(row))) row[[name]] <- task[[name]][[1L]]
  row$replicate <- as.integer(replicate); row$seed <- as.integer(seed); row$attempt_status <- "not_attempted"
  result <- tryCatch({
    adapter <- b1_adapter_fixture(task$cell_id[[1L]], seed, task$information_rung[[1L]])
    fit <- adapter$fit(adapter$data)
    row$attempt_status <- "fit_completed"
    row$convergence <- fit$opt$convergence
    row$pdHess <- if (is.null(fit$sdr$pdHess)) NA else isTRUE(fit$sdr$pdHess)
    row$target_estimate <- b1_target_estimate(fit, task)
    row$field_correlation <- b1_field_correlation(fit, task, adapter$truth)
    targets <- tryCatch(drmTMB::profile_targets(fit), error = function(e) NULL)
    row$profile_ready <- !is.null(targets) && any(targets$parm == task$target[[1L]] & targets$profile_ready %in% TRUE)
    row
  }, error = function(e) {
    row$attempt_status <- "fit_error"
    row$attempt_error <- conditionMessage(e)
    row
  })
  result$elapsed_seconds <- proc.time()[["elapsed"]] - started
  as.data.frame(result, stringsAsFactors = FALSE)
}

b1_execute_task <- function(task, output_path) {
  repetitions <- seq.int(task$replicate_start[[1L]], task$replicate_end[[1L]])
  seeds <- seq.int(task$seed_start[[1L]], task$seed_end[[1L]])
  if (length(repetitions) != length(seeds)) b1_stop("B1 task replicate/seed mapping is not bijective.")
  raw <- do.call(rbind, Map(function(rep, seed) b1_one_attempt(task, rep, seed), repetitions, seeds))
  if (nrow(raw) != length(repetitions) || anyDuplicated(raw$replicate) || anyDuplicated(raw$seed)) {
    b1_stop("B1 worker did not retain exactly one row per attempted replicate.")
  }
  b1_atomic_write(raw, output_path)
  raw
}

b1_runner_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  parsed <- b1_parse_args(args)
  task <- b1_read_task(parsed$manifest, parsed[["array-index"]])
  output <- file.path(parsed[["out-dir"]], sprintf("b1-task-%06d.tsv", task$logical_task_id[[1L]]))
  b1_execute_task(task, output)
  invisible(output)
}

if (sys.nframe() == 0L) b1_runner_main()
