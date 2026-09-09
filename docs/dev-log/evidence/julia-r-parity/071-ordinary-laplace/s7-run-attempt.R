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
