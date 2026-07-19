#!/usr/bin/env Rscript
# Arc 4c worker.  The fit path is intentionally present in PR A, but this
# session must not invoke it before the explicit compute gate.

arc4c_runner_script <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(arc4c_runner_script) || !nzchar(arc4c_runner_script)) {
  arc4c_runner_script <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  arc4c_runner_script <- if (length(arc4c_runner_script)) sub("^--file=", "", arc4c_runner_script[[1L]]) else "tools/run-arc4c-mu-slope-coverage.R"
}
if (!exists("arc4c_task", mode = "function")) {
  source(file.path(dirname(normalizePath(arc4c_runner_script, mustWork = FALSE)), "arc4c-mu-slope-coverage-contract.R"))
}

arc4c_target_parameter <- "sd:mu:(0 + x | id)"

arc4c_fit_factory <- function(cell_id) {
  switch(cell_id,
    "mc-0464" = function(d) drmTMB::drmTMB(
      drmTMB::bf(y ~ x + (0 + x | id), sigma ~ z, nu ~ 1), family = drmTMB::skew_normal(), data = d, REML = FALSE),
    "mc-0539" = function(d) drmTMB::drmTMB(
      drmTMB::bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1), family = drmTMB::tweedie(), data = d, REML = FALSE),
    "mc-0575" = function(d) drmTMB::drmTMB(
      drmTMB::bf(y ~ x + (0 + x | id)), family = drmTMB::zero_one_beta(), data = d, REML = FALSE),
    arc4c_stop("Unknown Arc 4c cell: ", cell_id)
  )
}

arc4c_default_profile <- function(fit) {
  stats::confint(fit, parm = arc4c_target_parameter, method = "profile")
}

arc4c_extract_sd_estimate_se <- function(fit) {
  sm <- summary(fit$sdr)
  row <- which(rownames(sm) == "log_sd_mu")
  if (length(row) != 1L) return(c(estimate = NA_real_, se = NA_real_))
  c(estimate = as.numeric(sm[row[[1L]], "Estimate"]), se = as.numeric(sm[row[[1L]], "Std. Error"]))
}

arc4c_extract_named_estimate <- function(fit, name) {
  sm <- summary(fit$sdr); row <- which(rownames(sm) == name)
  if (!length(row)) return(NA_real_)
  as.numeric(sm[row[[1L]], "Estimate"])
}

arc4c_extract_nu_hat <- function(fit) {
  value <- stats::coef(fit, dpar = "nu")
  if (!length(value)) return(NA_real_)
  as.numeric(value[[1L]])
}

arc4c_family_diagnostics <- function(task, d) {
  out <- list(nu_hat = NA_real_, near_zero_slant = NA, zero_count = NA_integer_,
    all_zero_cluster_count = NA_integer_, interior_count = NA_integer_, one_count = NA_integer_,
    invalid_interior = NA, invalid_interior_count = NA_integer_)
  if (identical(task$cell_id[[1L]], "mc-0539")) {
    out$zero_count <- sum(d$y == 0, na.rm = TRUE)
    out$all_zero_cluster_count <- sum(vapply(split(d$y, d$id), function(y) all(y == 0), logical(1L)))
  }
  if (identical(task$cell_id[[1L]], "mc-0575")) {
    interior <- d$boundary == "beta"
    out$interior_count <- sum(interior)
    out$zero_count <- sum(d$y == 0)
    out$one_count <- sum(d$y == 1)
    out$invalid_interior_count <- sum(interior & (!is.finite(d$y) | d$y <= 0 | d$y >= 1))
    out$invalid_interior <- out$invalid_interior_count > 0L
  }
  out
}

arc4c_one_attempt <- function(task, fit_fun, profile_fun = arc4c_default_profile,
                              dgp_fun = arc4c_dgp) {
  out <- arc4c_empty_row(task)
  started <- proc.time()[["elapsed"]]
  # arc4c_dgp() resets the frozen seed immediately before every simulation.
  d <- tryCatch(dgp_fun(task$cell_id[[1L]], task$M[[1L]], task$replicate[[1L]]),
    error = function(e) e)
  if (inherits(d, "error")) {
    out$fit_status <- "simulation_error"; out$fit_error <- conditionMessage(d)
    out$elapsed_seconds <- proc.time()[["elapsed"]] - started; return(out)
  }
  diagnostics <- arc4c_family_diagnostics(task, d)
  for (name in names(diagnostics)) out[[name]] <- diagnostics[[name]]
  fit <- tryCatch(fit_fun(d), error = function(e) e)
  if (inherits(fit, "error")) {
    out$fit_status <- "fit_error"; out$fit_error <- conditionMessage(fit)
    out$elapsed_seconds <- proc.time()[["elapsed"]] - started; return(out)
  }
  out$convergence <- suppressWarnings(as.integer(fit$opt$convergence[[1L]]))
  out$pdHess <- isTRUE(fit$sdr$pdHess)
  if (!isTRUE(out$convergence == 0L)) {
    out$fit_status <- "nonconverged"; out$elapsed_seconds <- proc.time()[["elapsed"]] - started; return(out)
  }
  if (!isTRUE(out$pdHess)) {
    out$fit_status <- "pdHess_bad"; out$elapsed_seconds <- proc.time()[["elapsed"]] - started; return(out)
  }
  out$fit_status <- "eligible"
  sd_log <- tryCatch(arc4c_extract_sd_estimate_se(fit), error = function(e) c(estimate = NA_real_, se = NA_real_))
  if (all(is.finite(sd_log))) {
    out$sd_hat <- exp(sd_log[["estimate"]])
    out$wald_lower <- exp(sd_log[["estimate"]] - stats::qnorm(0.975) * sd_log[["se"]])
    out$wald_upper <- exp(sd_log[["estimate"]] + stats::qnorm(0.975) * sd_log[["se"]])
    out$wald_covered <- arc4c_true_sd >= out$wald_lower && arc4c_true_sd <= out$wald_upper
  }
  if (identical(task$cell_id[[1L]], "mc-0464")) {
    out$nu_hat <- tryCatch(arc4c_extract_nu_hat(fit), error = function(e) NA_real_)
    out$near_zero_slant <- is.finite(out$nu_hat) && abs(out$nu_hat) < 0.1
  }
  ci <- tryCatch(profile_fun(fit), error = function(e) e)
  if (inherits(ci, "error")) {
    out$profile_error <- conditionMessage(ci)
  } else if (is.null(ci) || nrow(ci) < 1L) {
    out$profile_error <- "profile returned no rows"
  } else {
    out$profile_lower <- suppressWarnings(as.numeric(ci$lower[[1L]]))
    out$profile_upper <- suppressWarnings(as.numeric(ci$upper[[1L]]))
    out$profile_conf_status <- if ("conf.status" %in% names(ci)) as.character(ci$conf.status[[1L]]) else NA_character_
  }
  out <- arc4c_profile_flags(out)
  out$elapsed_seconds <- proc.time()[["elapsed"]] - started
  out
}

arc4c_resume_rows <- function(path, task) {
  if (!file.exists(path) && !file.exists(paste0(path, ".md5"))) return(task[FALSE, , drop = FALSE])
  result <- tryCatch({
    if (!file.exists(path) || !file.exists(paste0(path, ".md5"))) arc4c_stop("incomplete")
    if (!identical(readLines(paste0(path, ".md5"), warn = FALSE), arc4c_checksum(path))) arc4c_stop("checksum")
    raw <- arc4c_read_tsv(path); arc4c_validate_raw(raw, allow_partial = TRUE)
    n <- nrow(raw); if (n > nrow(task)) arc4c_stop("too_many_rows")
    wanted <- task[seq_len(n), c("cell_id", "family", "M", "shard", "replicate", "seed", "mode"), drop = FALSE]
    got <- raw[, names(wanted), drop = FALSE]
    if (!identical(lapply(got, as.character), lapply(wanted, as.character))) arc4c_stop("task_mapping")
    raw
  }, error = function(e) e)
  if (!inherits(result, "error")) return(result)
  stamp <- format(Sys.time(), "%Y%m%dT%H%M%S", tz = "UTC")
  quarantine <- paste0(path, ".quarantine-", stamp, "-", gsub("[^A-Za-z0-9]+", "_", conditionMessage(result)))
  if (file.exists(path)) file.rename(path, quarantine)
  if (file.exists(paste0(path, ".md5"))) file.rename(paste0(path, ".md5"), paste0(quarantine, ".md5"))
  message("Quarantined invalid Arc 4c shard: ", quarantine)
  task[FALSE, , drop = FALSE]
}

arc4c_execute_task <- function(task, path, fit_fun, profile_fun = arc4c_default_profile,
                               dgp_fun = arc4c_dgp, heartbeat = function(...) message(...)) {
  raw <- arc4c_resume_rows(path, task)
  remaining <- seq_len(nrow(task))
  remaining <- remaining[remaining > nrow(raw)]
  for (i in remaining) {
    row <- arc4c_one_attempt(task[i, , drop = FALSE], fit_fun, profile_fun, dgp_fun)
    raw <- rbind(raw, row)
    arc4c_atomic_write_tsv(raw, path)
    heartbeat(sprintf("arc4c cell=%s M=%d replicate=%d/%d status=%s", task$cell_id[[1L]],
      task$M[[1L]], task$replicate[[i]], task$replicate[[nrow(task)]], row$fit_status[[1L]]))
  }
  arc4c_validate_shard_file(path, task)
  invisible(raw)
}

arc4c_runner_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (any(args %in% c("--help", "-h"))) {
    cat("Usage: Rscript tools/run-arc4c-mu-slope-coverage.R --mode=dry-run|smoke|full --cell-id=mc-0464 --family=skew_normal --M=16 --replicate-start=1 --replicate-end=10 --out-dir=PATH\n")
    return(invisible(NULL))
  }
  allowed <- c("mode", "cell-id", "family", "M", "replicate-start", "replicate-end", "out-dir")
  if (any(!grepl("^--[A-Za-z][A-Za-z-]*=.+$", args))) arc4c_stop("Runner arguments must be named --key=value arguments.")
  keys <- sub("^--([^=]+)=.*$", "\\1", args[grepl("^--", args)])
  if (any(!keys %in% allowed) || anyDuplicated(keys)) arc4c_stop("Unknown or duplicate runner argument.")
  value <- function(name, default = NULL) { x <- grep(paste0("^--", name, "="), args, value = TRUE); if (!length(x)) default else sub(paste0("^--", name, "="), "", x[[length(x)]]) }
  mode <- value("mode", "dry-run")
  if (!mode %in% c("dry-run", "smoke", "full")) arc4c_stop("--mode must be dry-run, smoke, or full.")
  cell <- value("cell-id", NULL); family <- value("family", NULL); out_dir <- value("out-dir", NULL)
  if (is.null(cell) || is.null(family) || is.null(out_dir) || !nzchar(out_dir)) arc4c_stop("--cell-id, --family, and nonempty --out-dir are required.")
  M <- arc4c_validate_M(value("M", NA_integer_)); start <- suppressWarnings(as.integer(value("replicate-start", "1"))); end <- suppressWarnings(as.integer(value("replicate-end", "1")))
  task_mode <- if (identical(mode, "smoke") || (identical(mode, "dry-run") && identical(start, 1L) && identical(end, 1L))) "smoke" else "full"
  task <- arc4c_task_from_range(cell, family, M, start, end, task_mode)
  shard_token <- if (identical(task_mode, "smoke")) 0L else task$shard[[1L]]
  path <- file.path(out_dir, sprintf("arc4c-%s-M%02d-shard%03d.tsv", cell, M, shard_token))
  if (identical(mode, "dry-run")) { arc4c_atomic_write_tsv(task, paste0(path, ".plan")); print(task); return(invisible(task)) }
  repo_root <- normalizePath(file.path(dirname(normalizePath(arc4c_runner_script, mustWork = FALSE)), ".."), mustWork = TRUE)
  if (!requireNamespace("pkgload", quietly = TRUE)) arc4c_stop("pkgload is required for Arc 4c execution.")
  suppressWarnings(suppressMessages(pkgload::load_all(repo_root, quiet = TRUE, recompile = FALSE)))
  arc4c_execute_task(task, path, arc4c_fit_factory(cell))
}

if (sys.nframe() == 0L) arc4c_runner_main()
