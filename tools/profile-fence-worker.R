#!/usr/bin/env Rscript
# Subprocess worker for the Prong B Tier 1 profile-fence-integrity guard.
#
# Runs BOTH the predicate-domain enumeration and the fitted battery against
# whichever drmTMB build is resolvable from THIS process's .libPaths() (set
# by the caller via the R_LIBS_USER environment variable before launching
# Rscript). Writes three files to <out_dir>: enumeration.tsv, battery.tsv,
# provenance.tsv. Every result row is written and flushed immediately after
# it is computed (never batched to the end), so a crash or timeout leaves
# partial evidence on disk instead of nothing.
#
# This script is deliberately the ONLY place that calls `library(drmTMB)`.
# check-profile-fence-integrity.R launches this ONCE per library, each time
# in its own `Rscript` process (see requirement #1 in the 2026-08-03 task
# brief): a namespace, once attached in a live R session, is reused even if
# .libPaths() changes afterwards, so comparing two libraries within one
# session would silently make "post" a second read of "pre". Never source
# this file directly into an already-running R session that has drmTMB
# attached from a different library.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop("Usage: Rscript profile-fence-worker.R <out_dir>", call. = FALSE)
}
out_dir <- args[[1L]]
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

script_path <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]])
script_dir <- dirname(normalizePath(script_path, mustWork = TRUE))
source(file.path(script_dir, "profile-fence-fixtures.R"), chdir = FALSE)

# Normal path: library(drmTMB) resolves against .libPaths(), which the
# caller sets via R_LIBS_USER before launching this Rscript process.
#
# load_all path (PROFILE_FENCE_LOAD_ALL_PATH set): load a source tree in
# place with pkgload::load_all(compile = NA) -- the same default
# tools/check-capability-runtime.R and tools/emit-profile-truth-manifest.R
# already rely on at this point in the CI workflow, before `R CMD INSTALL`
# has run. `compile = NA` recompiles only if src/*.so is missing or older
# than src/*.cpp: on a genuinely fresh checkout it compiles (same one-time
# cost those two existing tools already pay); after that, or for the
# guard's manual red test (a deliberately mutated R/profile.R, no src/
# changes), it detects the compiled object is already current and skips
# straight to loading -- seconds, not a multi-minute TMB recompile.
load_all_path <- Sys.getenv("PROFILE_FENCE_LOAD_ALL_PATH", unset = "")
if (nzchar(load_all_path)) {
  suppressPackageStartupMessages(pkgload::load_all(load_all_path, compile = NA, quiet = TRUE, export_all = TRUE))
} else {
  suppressPackageStartupMessages(library(drmTMB))
}

write_line <- function(con, fields) {
  fields <- vapply(fields, function(v) {
    if (length(v) != 1L || is.na(v)) "" else as.character(v)
  }, character(1L))
  writeLines(paste(fields, collapse = "\t"), con)
  flush(con)
}

# --- Provenance stamp -------------------------------------------------
# Each stage runs inside local() rather than a bare `{ }` block: on.exit()
# only fires when a FUNCTION call returns, and local() is a function call,
# so the connection is reliably closed instead of leaking to the GC finalizer.
provenance_path <- file.path(out_dir, "provenance.tsv")
local({
  con <- file(provenance_path, open = "w")
  on.exit(close(con), add = TRUE)
  ns <- asNamespace("drmTMB")
  write_line(con, c("key", "value"))
  lib_dir <- dirname(dirname(system.file(package = "drmTMB")))
  write_line(con, c("lib_path", lib_dir))
  # Installed layout: <lib>/drmTMB/libs/drmTMB.so. load_all(compile=FALSE)
  # source-tree layout: <pkg>/src/drmTMB.so. Try both so the provenance
  # stamp works identically for a normal library(drmTMB) run and a red-test
  # pkgload::load_all() run.
  so_path <- system.file("libs", paste0("drmTMB", .Platform$dynlib.ext), package = "drmTMB")
  if (!nzchar(so_path)) {
    candidate <- file.path(system.file(package = "drmTMB"), "src", paste0("drmTMB", .Platform$dynlib.ext))
    if (file.exists(candidate)) so_path <- candidate
  }
  so_md5 <- if (nzchar(so_path) && file.exists(so_path)) unname(tools::md5sum(so_path)) else NA_character_
  write_line(con, c("so_md5", so_md5))
  built <- tryCatch(utils::packageDescription("drmTMB")$Built, error = function(e) NA_character_)
  write_line(con, c("built", built))
  for (fn in profile_fence_all_probed_fn_names()) {
    write_line(con, c(paste0("exists:", fn), exists(fn, envir = ns, inherits = FALSE)))
  }
})
message("Wrote provenance: ", provenance_path)

# --- (a) Predicate-domain enumeration ----------------------------------
enum_path <- file.path(out_dir, "enumeration.tsv")
local({
  con <- file(enum_path, open = "w")
  on.exit(close(con), add = TRUE)
  ns <- asNamespace("drmTMB")
  write_line(con, c("id", "group", "kind", "dpar", "internal", "result", "error"))

  fn_name_for_kind <- function(kind) {
    switch(
      kind,
      count_point_fit_only = "count_point_fit_only_profile_restricted",
      zi_nbinom2_sigma_q1 = "zi_nbinom2_sigma_q1_profile_restricted",
      zero_one_beta_zoi_q1 = "zero_one_beta_zoi_q1_profile_restricted",
      zero_one_beta_coi_q1 = "zero_one_beta_coi_q1_profile_restricted",
      zero_one_beta_sigma_q1_deleted = "zero_one_beta_sigma_q1_profile_restricted",
      stop("Unknown grid row kind: ", kind, call. = FALSE)
    )
  }
  takes_internal <- c("zero_one_beta_zoi_q1", "zero_one_beta_coi_q1", "zero_one_beta_sigma_q1_deleted")

  for (row in profile_fence_grid()) {
    fn_name <- fn_name_for_kind(row$kind)
    if (!exists(fn_name, envir = ns, inherits = FALSE)) {
      write_line(con, c(row$id, row$group, row$kind, row$dpar, row$internal, "ABSENT", ""))
      next
    }
    fn <- get(fn_name, envir = ns, inherits = FALSE)
    val <- tryCatch(
      if (row$kind %in% takes_internal) {
        fn(row$object, row$dpar, row$internal)
      } else {
        fn(row$object, row$dpar)
      },
      error = function(e) e
    )
    if (inherits(val, "error")) {
      write_line(con, c(row$id, row$group, row$kind, row$dpar, row$internal, "ERROR", conditionMessage(val)))
    } else {
      write_line(con, c(row$id, row$group, row$kind, row$dpar, row$internal, isTRUE(val), ""))
    }
  }
  for (fn_name in profile_fence_deleted_fn_names()) {
    write_line(con, c(
      paste0("exists:", fn_name), "deleted_fn_probe", "exists_only", NA, NA,
      exists(fn_name, envir = ns, inherits = FALSE), ""
    ))
  }
})
message("Wrote enumeration: ", enum_path)

# --- (b) Fitted battery --------------------------------------------------
battery_path <- file.path(out_dir, "battery.tsv")
local({
  con <- file(battery_path, open = "w")
  on.exit(close(con), add = TRUE)
  write_line(con, c(
    "route_id", "status", "parm", "dpar", "old_ready", "old_note", "new_ready", "new_note",
    "expect_tmb_parameter", "fit_status", "fit_error", "convergence", "pdhess", "has_obj",
    "se_success", "profile_targets_status", "profile_targets_error",
    "observed_ready", "observed_note", "observed_tmb_parameter", "observed_target_type"
  ))
  emit_for_checks <- function(route, common) {
    for (chk in route$checks) {
      write_line(con, c(
        route$id, route$status, chk$parm, chk$dpar, chk$old_ready, chk$old_note,
        chk$new_ready, chk$new_note, chk$tmb_parameter,
        common
      ))
    }
  }

  for (route in profile_fence_routes()) {
    t_start <- Sys.time()
    built <- tryCatch(route$build(), error = function(e) e)
    if (inherits(built, "error")) {
      emit_for_checks(route, c("build_error", conditionMessage(built), NA, NA, NA, NA, "not_run", "", NA, NA, NA, NA))
      message(sprintf("[%s] BUILD ERROR: %s", route$id, conditionMessage(built)))
      next
    }
    fit <- tryCatch(
      drmTMB::drmTMB(built$formula, family = built$family, data = built$data, control = built$control),
      error = function(e) e
    )
    elapsed <- as.numeric(difftime(Sys.time(), t_start, units = "secs"))
    if (inherits(fit, "error")) {
      emit_for_checks(route, c("fit_error", conditionMessage(fit), NA, NA, NA, NA, "not_run", "", NA, NA, NA, NA))
      message(sprintf("[%s] FIT ERROR (%.1fs): %s", route$id, elapsed, conditionMessage(fit)))
      next
    }
    convergence <- fit$opt$convergence
    pdhess <- if (!is.null(fit$sdr)) isTRUE(fit$sdr$pdHess) else NA
    has_obj <- !is.null(fit$obj)
    se_success <- !is.null(fit$sdr) && !inherits(fit$sdr, "try-error") &&
      !is.null(fit$sdr$sd) && length(fit$sdr$sd) > 0L && all(is.finite(fit$sdr$sd))
    targets <- tryCatch(drmTMB::profile_targets(fit), error = function(e) e)
    if (inherits(targets, "error")) {
      emit_for_checks(route, c(
        "fit_ok", "", convergence, pdhess, has_obj, se_success,
        "profile_targets_error", conditionMessage(targets), NA, NA, NA, NA
      ))
      message(sprintf("[%s] FIT OK (%.1fs) but profile_targets() ERROR: %s", route$id, elapsed, conditionMessage(targets)))
      next
    }
    for (chk_i in route$checks) {
      match_row <- targets[targets$parm == chk_i$parm, , drop = FALSE]
      if (nrow(match_row) != 1L) {
        write_line(con, c(
          route$id, route$status, chk_i$parm, chk_i$dpar, chk_i$old_ready, chk_i$old_note,
          chk_i$new_ready, chk_i$new_note, chk_i$tmb_parameter,
          "fit_ok", "", convergence, pdhess, has_obj, se_success,
          "ok", "", NA, paste0("MISSING_ROW(n=", nrow(match_row), ")"), NA, NA
        ))
      } else {
        write_line(con, c(
          route$id, route$status, chk_i$parm, chk_i$dpar, chk_i$old_ready, chk_i$old_note,
          chk_i$new_ready, chk_i$new_note, chk_i$tmb_parameter,
          "fit_ok", "", convergence, pdhess, has_obj, se_success,
          "ok", "", match_row$profile_ready, match_row$profile_note,
          match_row$tmb_parameter, match_row$target_type
        ))
      }
    }
    message(sprintf(
      "[%s] FIT OK (%.1fs) convergence=%s pdHess=%s se_success=%s",
      route$id, elapsed, convergence, pdhess, se_success
    ))
  }
})
message("Wrote battery: ", battery_path)
