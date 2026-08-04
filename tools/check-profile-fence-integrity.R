#!/usr/bin/env Rscript
# Fence-integrity guard for Prong B Tier 1 (see docs/dev-log/handover/
# 2026-08-03-prong-b-next-lane-brief.md for the source task, and
# scratchpad/2026-08-03-prong-b-s2-guard-report.md for the design report).
#
# R/profile.R deleted four boolean "fence" predicates (and narrowed one dpar
# set) that used to force `profile_ready = FALSE` for 14 specific
# structured/labelled random-effect profile targets. This guard asserts, by
# construction rather than by re-reading the diff, that the resulting
# profile-fence surface is EXACTLY the intended one: the 14 named routes
# open, everything else (in particular zi_nbinom2 ordinary sigma q1 and
# zero_one_beta structured mu/zoi/coi) stays fenced.
#
# Two independent proofs, both defined in tools/profile-fence-fixtures.R and
# executed by tools/profile-fence-worker.R:
#   (a) predicate-domain enumeration -- pure-R stub objects, no TMB fitting,
#       runs in well under a second.
#   (b) fitted battery -- real drmTMB() fits for the 14 promoted routes plus
#       a representative must-stay-fenced set, checking convergence, TMB
#       object retention, the exact profile_note string, and se=TRUE
#       success.
#
# USAGE
#   Rscript tools/check-profile-fence-integrity.R
#     Guard/CI mode (default; this is what .github/workflows/R-CMD-check.yaml
#     runs). Loads the package IN PLACE with pkgload::load_all(compile = NA)
#     -- the same mechanism tools/check-capability-runtime.R and
#     tools/emit-profile-truth-manifest.R already use at this point in the
#     workflow, before `R CMD INSTALL` has run -- inside its OWN Rscript
#     subprocess, and checks the result against the intended POST-edit
#     (`new_*`) outcome table. Exits non-zero on any mismatch, fit error, or
#     profile_targets() error.
#
#   Rscript tools/check-profile-fence-integrity.R --diff \
#     --lib-old=/path/to/pre-edit/lib --lib-new=/path/to/post-edit/lib \
#     [--out-dir=/path/to/write/tsvs]
#     One-time two-library diff mode. Runs the SAME battery against two
#     already-installed libraries, each in its OWN Rscript subprocess (never
#     switches .libPaths() inside one live R session -- see
#     tools/profile-fence-worker.R's header), and asserts: the two
#     provenance stamps differ (primary stamp: exists() of the four deleted
#     predicates; secondary corroboration: installed .so md5 + Built
#     string); the set of enumeration rows whose predicate result flips is
#     EXACTLY the 14 intended routes; every other row (fenced /
#     negative-control / retained-predicate-control) is unchanged; every
#     fitted-battery row fits and classifies as expected in BOTH libraries.

suppressPackageStartupMessages({
  # Only needed for guard mode's default load_all path; loaded lazily below
  # so --diff mode (which never calls load_all itself -- the WORKER
  # subprocess does, or uses library()) does not require it either.
})

`%||%` <- function(a, b) if (is.null(a) || !nzchar(a)) b else a

find_script_dir <- function() {
  file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(file_arg) == 0L) {
    stop("Could not determine this script's own path (expected --file=).", call. = FALSE)
  }
  dirname(normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE))
}
script_dir <- find_script_dir()
pkg_root <- normalizePath(file.path(script_dir, ".."), mustWork = TRUE)
worker_path <- file.path(script_dir, "profile-fence-worker.R")
fixtures_path <- file.path(script_dir, "profile-fence-fixtures.R")
source(fixtures_path, chdir = FALSE)

# --- Argument parsing -------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
parse_kv <- function(args, flag) {
  hit <- grep(paste0("^--", flag, "="), args, value = TRUE)
  if (length(hit) == 0L) return(NULL)
  sub(paste0("^--", flag, "="), "", hit[[length(hit)]])
}
diff_mode <- "--diff" %in% args
lib_old <- parse_kv(args, "lib-old")
lib_new <- parse_kv(args, "lib-new")
out_dir_arg <- parse_kv(args, "out-dir")

if (diff_mode && (is.null(lib_old) || is.null(lib_new))) {
  stop("--diff requires both --lib-old=PATH and --lib-new=PATH.", call. = FALSE)
}

# --- Run one worker subprocess -----------------------------------------
# Requirement: NEVER switch .libPaths() inside one live R session. Each
# call here is its own `Rscript` process; the parent (this script) never
# itself calls library(drmTMB)/pkgload::load_all(), so it carries no
# drmTMB namespace of its own to accidentally reuse.
run_worker <- function(out_dir, r_libs_user = NULL, load_all_path = NULL) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  # Inherit the caller's R_LIBS_USER when none is pinned. Passing an empty
  # value would make the child fall back to R's DEFAULT user library, so a
  # caller running against an explicit library would be silently measured
  # against a different one -- the wrong-library failure this guard exists to
  # catch. `--diff` always pins both sides explicitly and is unaffected.
  env <- c(
    paste0("R_LIBS_USER=", r_libs_user %||% Sys.getenv("R_LIBS_USER")),
    paste0("PROFILE_FENCE_LOAD_ALL_PATH=", load_all_path %||% "")
  )
  out <- system2(
    "Rscript", c("--vanilla", shQuote(worker_path), shQuote(out_dir)),
    env = env, stdout = TRUE, stderr = TRUE
  )
  status <- attr(out, "status") %||% 0L
  list(out_dir = out_dir, transcript = out, status = status)
}

read_tsv <- function(path) {
  if (!file.exists(path)) stop("Missing worker output: ", path, call. = FALSE)
  utils::read.delim(path, sep = "\t", colClasses = "character", na.strings = character(0))
}
as_lgl <- function(x) {
  out <- rep(NA, length(x))
  out[x == "TRUE"] <- TRUE
  out[x == "FALSE"] <- FALSE
  out
}

# ==========================================================================
# GUARD / CI mode
# ==========================================================================
run_guard_mode <- function() {
  out_dir <- out_dir_arg %||% tempfile("profile-fence-guard-")
  cat(sprintf("[guard] loading package in place from %s (pkgload::load_all)\n", pkg_root))
  cat(sprintf("[guard] worker output dir: %s\n", out_dir))
  worker <- run_worker(out_dir, load_all_path = pkg_root)
  cat(paste(worker$transcript, collapse = "\n"), "\n")
  if (!identical(worker$status, 0L) && !is.null(worker$status)) {
    cat(sprintf("VIOLATIONS: worker subprocess exited with status %s (see transcript above)\n", worker$status))
    return(FALSE)
  }

  grid <- profile_fence_grid()
  enum_tsv <- read_tsv(file.path(out_dir, "enumeration.tsv"))
  battery_tsv <- read_tsv(file.path(out_dir, "battery.tsv"))

  violations <- character(0)

  # (a) enumeration: observed result must equal expect_new for every row,
  # and the specific "kind"/"internal" call must not itself have ERRORed.
  by_id <- setNames(grid, vapply(grid, `[[`, character(1L), "id"))
  for (i in seq_len(nrow(enum_tsv))) {
    row <- enum_tsv[i, ]
    if (identical(row$kind, "exists_only")) {
      expect_exists <- FALSE # every wholesale-deleted fn must be absent post-edit
      if (!identical(as_lgl(row$result), expect_exists)) {
        violations <- c(violations, sprintf(
          "enumeration[%s]: expected exists()=%s post-edit, observed %s", row$id, expect_exists, row$result
        ))
      }
      next
    }
    spec <- by_id[[row$id]]
    if (is.null(spec)) {
      violations <- c(violations, sprintf("enumeration[%s]: no matching grid spec (stale worker output?)", row$id))
      next
    }
    if (identical(row$result, "ERROR")) {
      violations <- c(violations, sprintf("enumeration[%s]: predicate call ERRORed: %s", row$id, row$error))
      next
    }
    observed <- if (identical(row$result, "ABSENT")) NA else as_lgl(row$result)
    expect_new <- spec$expect_new
    ok <- if (is.na(expect_new)) {
      identical(row$result, "ABSENT")
    } else {
      isTRUE(identical(observed, expect_new))
    }
    if (!ok) {
      violations <- c(violations, sprintf(
        "enumeration[%s] group=%s: expected new-lib result %s, observed %s",
        row$id, spec$group, if (is.na(expect_new)) "ABSENT" else expect_new, row$result
      ))
    }
  }

  # (b) fitted battery: every route must fit + classify successfully, and
  # match the intended post-edit ready/note pair exactly.
  for (i in seq_len(nrow(battery_tsv))) {
    row <- battery_tsv[i, ]
    label <- sprintf("battery[%s parm=%s]", row$route_id, row$parm)
    if (!identical(row$fit_status, "fit_ok")) {
      violations <- c(violations, sprintf("%s: FIT ERROR: %s", label, row$fit_error))
      next
    }
    if (!identical(row$profile_targets_status, "ok")) {
      violations <- c(violations, sprintf("%s: profile_targets() ERROR: %s", label, row$profile_targets_error))
      next
    }
    expect_ready <- as_lgl(row$new_ready)
    expect_note <- row$new_note
    observed_ready <- as_lgl(row$observed_ready)
    if (!identical(observed_ready, expect_ready) || !identical(row$observed_note, expect_note)) {
      violations <- c(violations, sprintf(
        "%s: expected ready=%s note=%s, observed ready=%s note=%s",
        label, expect_ready, expect_note, row$observed_ready, row$observed_note
      ))
    }
    if (!identical(row$observed_tmb_parameter, row$expect_tmb_parameter)) {
      violations <- c(violations, sprintf(
        "%s: tmb_parameter drifted: expected %s, observed %s",
        label, row$expect_tmb_parameter, row$observed_tmb_parameter
      ))
    }
  }

  cat(sprintf(
    "\n[guard] enumeration rows=%d battery rows=%d violations=%d\n",
    nrow(enum_tsv), nrow(battery_tsv), length(violations)
  ))
  if (length(violations) > 0L) {
    cat("VIOLATIONS:\n")
    for (v in violations) cat(" - ", v, "\n", sep = "")
    return(FALSE)
  }
  cat("VIOLATIONS: none\n")
  TRUE
}

# ==========================================================================
# DIFF mode (two prebuilt libraries, one-time verification)
# ==========================================================================
run_diff_mode <- function() {
  base_out <- out_dir_arg %||% tempfile("profile-fence-diff-")
  old_dir <- file.path(base_out, "old"); new_dir <- file.path(base_out, "new")
  # The library that actually carries TMB/pkgload/etc. is this orchestrator
  # process's OWN .libPaths() (typically the per-user arm64 library plus the
  # base R library) -- not just .Library (the base library alone), which
  # omits the user library and makes the worker subprocess fail to find TMB.
  sys_lib_path <- paste(.libPaths(), collapse = ":")

  cat(sprintf("[diff] OLD lib: %s\n[diff] NEW lib: %s\n[diff] out dir: %s\n", lib_old, lib_new, base_out))

  worker_old <- run_worker(old_dir, r_libs_user = paste0(lib_old, ":", sys_lib_path))
  cat("--- OLD worker transcript ---\n", paste(worker_old$transcript, collapse = "\n"), "\n")
  worker_new <- run_worker(new_dir, r_libs_user = paste0(lib_new, ":", sys_lib_path))
  cat("--- NEW worker transcript ---\n", paste(worker_new$transcript, collapse = "\n"), "\n")

  violations <- character(0)
  if (!identical(worker_old$status, 0L) && !is.null(worker_old$status)) {
    violations <- c(violations, sprintf("OLD worker subprocess exited with status %s", worker_old$status))
  }
  if (!identical(worker_new$status, 0L) && !is.null(worker_new$status)) {
    violations <- c(violations, sprintf("NEW worker subprocess exited with status %s", worker_new$status))
  }
  if (length(violations) > 0L) {
    cat("VIOLATIONS (worker subprocess failure -- cannot proceed to diff):\n")
    for (v in violations) cat(" - ", v, "\n", sep = "")
    return(list(pass = FALSE, violations = violations))
  }

  prov_old <- read_tsv(file.path(old_dir, "provenance.tsv"))
  prov_new <- read_tsv(file.path(new_dir, "provenance.tsv"))
  prov_get <- function(prov, key) prov$value[prov$key == key]

  # PRIMARY provenance stamp: exists() of the four deleted predicates.
  deleted_fns <- profile_fence_deleted_fn_names()
  deleted_fns <- c(deleted_fns, "zero_one_beta_sigma_q1_profile_restricted")
  stamp_ok <- TRUE
  for (fn in deleted_fns) {
    key <- paste0("exists:", fn)
    old_val <- prov_get(prov_old, key); new_val <- prov_get(prov_new, key)
    if (!identical(old_val, "TRUE") || !identical(new_val, "FALSE")) {
      stamp_ok <- FALSE
      violations <- c(violations, sprintf(
        "PROVENANCE STAMP: %s expected exists()=TRUE(old)/FALSE(new), observed old=%s new=%s",
        fn, old_val, new_val
      ))
    }
  }
  so_old <- prov_get(prov_old, "so_md5"); so_new <- prov_get(prov_new, "so_md5")
  built_old <- prov_get(prov_old, "built"); built_new <- prov_get(prov_new, "built")
  cat(sprintf(
    "[diff] provenance: so_md5 old=%s new=%s (%s) | built old=%s new=%s\n",
    so_old, so_new, if (identical(so_old, so_new)) "SAME (secondary stamp uninformative here)" else "differ",
    built_old, built_new
  ))
  if (!stamp_ok) {
    cat("VIOLATIONS: provenance stamps do not prove two distinct code bases were exercised -- ABORTING before trusting any diff below.\n")
    for (v in violations) cat(" - ", v, "\n", sep = "")
    return(list(pass = FALSE, violations = violations))
  }
  cat("[diff] PRIMARY provenance stamp confirms two distinct namespaces (deleted predicates present in OLD, absent in NEW).\n")

  # --- Enumeration diff ---------------------------------------------------
  grid <- profile_fence_grid()
  by_id <- setNames(grid, vapply(grid, `[[`, character(1L), "id"))
  enum_old <- read_tsv(file.path(old_dir, "enumeration.tsv"))
  enum_new <- read_tsv(file.path(new_dir, "enumeration.tsv"))
  stopifnot(identical(enum_old$id, enum_new$id))

  flipped <- character(0)
  for (i in seq_len(nrow(enum_old))) {
    id <- enum_old$id[[i]]
    old_row <- enum_old[i, ]; new_row <- enum_new[i, ]
    if (identical(old_row$kind, "exists_only")) {
      if (!identical(old_row$result, "TRUE") || !identical(new_row$result, "FALSE")) {
        violations <- c(violations, sprintf(
          "enumeration[%s]: expected deleted-fn exists() TRUE(old)/FALSE(new), observed old=%s new=%s",
          id, old_row$result, new_row$result
        ))
      }
      next
    }
    spec <- by_id[[id]]
    if (old_row$result == "ERROR" || new_row$result == "ERROR") {
      violations <- c(violations, sprintf(
        "enumeration[%s]: unexpected ERROR (old=%s new=%s old_err=%s new_err=%s)",
        id, old_row$result, new_row$result, old_row$error, new_row$error
      ))
      next
    }
    old_val <- if (identical(old_row$result, "ABSENT")) NA else as_lgl(old_row$result)
    new_val <- if (identical(new_row$result, "ABSENT")) NA else as_lgl(new_row$result)
    expect_old_val <- spec$expect_old
    expect_new_val <- spec$expect_new
    old_ok <- if (is.na(expect_old_val)) is.na(old_val) else identical(old_val, expect_old_val)
    new_ok <- if (is.na(expect_new_val)) is.na(new_val) else identical(new_val, expect_new_val)
    if (!old_ok || !new_ok) {
      violations <- c(violations, sprintf(
        "enumeration[%s] group=%s: expected old=%s new=%s, observed old=%s(%s) new=%s(%s)",
        id, spec$group,
        if (is.na(expect_old_val)) "ABSENT" else expect_old_val,
        if (is.na(expect_new_val)) "ABSENT" else expect_new_val,
        old_row$result, old_row$error, new_row$result, new_row$error
      ))
    }
    same <- if (is.na(old_val) || is.na(new_val)) is.na(old_val) == is.na(new_val) else identical(old_val, new_val)
    if (!same) flipped <- c(flipped, id)
  }
  intended_flip <- vapply(grid, function(r) identical(r$group, "open-14"), logical(1L))
  intended_ids <- vapply(grid[intended_flip], `[[`, character(1L), "id")
  set_diff_missing <- setdiff(intended_ids, flipped)
  set_diff_extra <- setdiff(flipped, intended_ids)
  if (length(set_diff_missing) > 0L) {
    violations <- c(violations, sprintf(
      "FLIP SET: %d intended route(s) did NOT flip: %s", length(set_diff_missing), paste(set_diff_missing, collapse = ", ")
    ))
  }
  if (length(set_diff_extra) > 0L) {
    violations <- c(violations, sprintf(
      "FLIP SET: %d UNINTENDED route(s) flipped: %s", length(set_diff_extra), paste(set_diff_extra, collapse = ", ")
    ))
  }
  cat(sprintf(
    "[diff] enumeration: %d grid points, %d flipped (intended 14: %s)\n",
    nrow(enum_old), length(flipped),
    if (length(set_diff_missing) == 0L && length(set_diff_extra) == 0L) "EXACT MATCH" else "MISMATCH"
  ))

  # --- Fitted battery diff -------------------------------------------------
  bat_old <- read_tsv(file.path(old_dir, "battery.tsv"))
  bat_new <- read_tsv(file.path(new_dir, "battery.tsv"))
  stopifnot(identical(bat_old$route_id, bat_new$route_id), identical(bat_old$parm, bat_new$parm))
  for (i in seq_len(nrow(bat_old))) {
    old_row <- bat_old[i, ]; new_row <- bat_new[i, ]
    label <- sprintf("battery[%s parm=%s]", old_row$route_id, old_row$parm)
    if (!identical(old_row$fit_status, "fit_ok")) violations <- c(violations, sprintf("%s OLD: FIT ERROR: %s", label, old_row$fit_error))
    if (!identical(new_row$fit_status, "fit_ok")) violations <- c(violations, sprintf("%s NEW: FIT ERROR: %s", label, new_row$fit_error))
    if (!identical(old_row$profile_targets_status, "ok")) violations <- c(violations, sprintf("%s OLD: profile_targets() ERROR: %s", label, old_row$profile_targets_error))
    if (!identical(new_row$profile_targets_status, "ok")) violations <- c(violations, sprintf("%s NEW: profile_targets() ERROR: %s", label, new_row$profile_targets_error))
    if (!identical(old_row$fit_status, "fit_ok") || !identical(new_row$fit_status, "fit_ok")) next
    if (!identical(old_row$profile_targets_status, "ok") || !identical(new_row$profile_targets_status, "ok")) next
    if (!identical(as_lgl(old_row$observed_ready), as_lgl(old_row$old_ready)) || !identical(old_row$observed_note, old_row$old_note)) {
      violations <- c(violations, sprintf(
        "%s OLD-lib: expected ready=%s note=%s, observed ready=%s note=%s",
        label, old_row$old_ready, old_row$old_note, old_row$observed_ready, old_row$observed_note
      ))
    }
    if (!identical(as_lgl(new_row$observed_ready), as_lgl(new_row$new_ready)) || !identical(new_row$observed_note, new_row$new_note)) {
      violations <- c(violations, sprintf(
        "%s NEW-lib: expected ready=%s note=%s, observed ready=%s note=%s",
        label, new_row$new_ready, new_row$new_note, new_row$observed_ready, new_row$observed_note
      ))
    }
  }
  cat(sprintf("[diff] fitted battery: %d routes checked in both libraries\n", nrow(bat_old)))

  cat(sprintf("\n[diff] TOTAL violations=%d\n", length(violations)))
  if (length(violations) > 0L) {
    cat("VIOLATIONS:\n")
    for (v in violations) cat(" - ", v, "\n", sep = "")
    return(list(pass = FALSE, violations = violations, flipped = flipped, base_out = base_out))
  }
  cat("VIOLATIONS: none\n")
  list(pass = TRUE, violations = character(0), flipped = flipped, base_out = base_out)
}

# --- Entry point ---------------------------------------------------------
if (diff_mode) {
  result <- run_diff_mode()
  quit(status = if (isTRUE(result$pass)) 0L else 1L, save = "no")
} else {
  pass <- run_guard_mode()
  quit(status = if (isTRUE(pass)) 0L else 1L, save = "no")
}
