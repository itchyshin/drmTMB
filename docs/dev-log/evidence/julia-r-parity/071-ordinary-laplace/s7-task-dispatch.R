#!/usr/bin/env Rscript
# Execute the complete engine-target plan for one already-resolved fixture/seed.
# The caller owns runtime setup and durable publication; this layer guarantees
# that an individual fit failure remains an observed terminal attempt.

r071_s7_dispatch_task <- function(
  plan, make_fixture, fit_factory,
  target_inventory = function(object) profile_targets(object),
  profile_fun = stats::confint
) {
  required <- c("logical_task_id", "fixture", "dgp_seed", "engine", "parm", "truth")
  if (!is.data.frame(plan) || nrow(plan) < 1L || !all(required %in% names(plan))) {
    stop("S7 task dispatcher needs a non-empty resolved task plan", call. = FALSE)
  }
  singleton <- c("logical_task_id", "fixture", "dgp_seed")
  if (any(vapply(singleton, function(column) length(unique(plan[[column]])) != 1L, logical(1L))) ||
      anyDuplicated(plan[c("engine", "parm")])) {
    stop("S7 task dispatcher plan is not one fixture-seed target bijection", call. = FALSE)
  }
  fixture <- make_fixture(plan$fixture[[1L]], plan$dgp_seed[[1L]])
  attempts <- lapply(seq_len(nrow(plan)), function(i) {
    spec <- plan[i, required, drop = FALSE]
    fit <- tryCatch(fit_factory(spec, fixture), error = identity)
    if (inherits(fit, "error")) return(r071_s7_fit_failed_attempt(spec))
    r071_s7_attempt_from_fit(
      fit, spec, target_inventory = target_inventory, profile_fun = profile_fun
    )
  })
  out <- do.call(rbind, attempts)
  row.names(out) <- NULL
  r071_s7_validate_task_attempts(plan, out)
  out
}
