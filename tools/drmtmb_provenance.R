#!/usr/bin/env Rscript
# tools/drmtmb_provenance.R -- build-time provenance capture for drmTMB.
#
# Answers DRM.jl#473: a version string alone cannot tell a fixture what BUILD
# produced it. This script captures the git SHA and working-tree dirty flag
# of the drmTMB source tree at BUILD time (never at call time, since an
# installed package has no `.git` to consult), and can either:
#
#  * be sourced (base R only, no drmTMB dependency) to get the functions
#    `drmtmb_capture_git_state()` and `drmtmb_provenance()` for reuse from
#    Julia-side fixture generation, to stamp a build anchor into receipts; or
#  * be run directly via `Rscript tools/drmtmb_provenance.R [options]` to
#    print or write the record, e.g. for developer/CI use.
#
# NOTE ON DUPLICATION: `configure`/`configure.win` do NOT source this file.
# `tools/` is excluded from the built source tarball via `.Rbuildignore`
# (correctly -- it holds ~300 developer/campaign scripts, and this one is a
# developer tool per DRM.jl#473, not a shipped component). A shipped
# `configure` that depended on an unshipped file would silently no-op on a
# real `R CMD build`/`R CMD INSTALL` from a tarball. So `configure` and
# `configure.win` re-implement the same few `git rev-parse`/`git status
# --porcelain` lines directly in shell/batch instead. If you change the git
# capture logic here, change it there too.
#
# When git information genuinely is not available (no git executable, no
# .git directory -- e.g. installing from a released tarball with .git
# excluded via .Rbuildignore) the record reports NA fields with a stated
# `reason`. It never guesses.

#' Capture live git state for a source directory
#'
#' @param root Path to a directory that may or may not be inside a git
#'   working tree.
#' @return A list with `git_sha` (character or NA), `git_dirty` (logical or
#'   NA), and `reason` (character or NA, set whenever `git_sha` is NA).
drmtmb_capture_git_state <- function(root = ".") {
  na_result <- function(reason) {
    list(git_sha = NA_character_, git_dirty = NA, reason = reason)
  }

  if (!nzchar(Sys.which("git"))) {
    return(na_result("git executable not found on PATH"))
  }
  if (!dir.exists(root)) {
    return(na_result(sprintf("root directory %s does not exist", root)))
  }

  run_git <- function(args) {
    out <- suppressWarnings(system2(
      "git", args = c("-C", root, args),
      stdout = TRUE, stderr = TRUE
    ))
    status <- attr(out, "status")
    list(out = out, status = if (is.null(status)) 0L else status)
  }

  inside <- run_git(c("rev-parse", "--is-inside-work-tree"))
  if (inside$status != 0L || !identical(inside$out, "true")) {
    return(na_result(sprintf(
      "no .git directory found under %s (not a git checkout, e.g. installed from a released tarball)",
      root
    )))
  }

  sha_res <- run_git(c("rev-parse", "HEAD"))
  if (sha_res$status != 0L || length(sha_res$out) != 1L) {
    return(na_result(paste("git rev-parse HEAD failed:", paste(sha_res$out, collapse = "; "))))
  }
  git_sha <- sha_res$out[[1L]]

  status_res <- run_git(c("status", "--porcelain"))
  if (status_res$status != 0L) {
    return(na_result(paste("git status --porcelain failed:", paste(status_res$out, collapse = "; "))))
  }
  git_dirty <- length(status_res$out) > 0L

  list(git_sha = git_sha, git_dirty = git_dirty, reason = NA_character_)
}

#' Build a provenance record for a source tree
#'
#' @param root Path to the drmTMB source tree (defaults to the current
#'   working directory).
#' @return A list: `package_version`, `git_sha`, `git_dirty`, `build_time`
#'   (UTC ISO-8601 timestamp of this capture), `source`
#'   (`"baked-without-git"` when git information is unavailable, `"baked"`
#'   when it is), and `reason` (set whenever `source != "baked"`).
drmtmb_provenance <- function(root = ".") {
  build_time <- format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")

  desc_path <- file.path(root, "DESCRIPTION")
  package_version <- if (file.exists(desc_path)) {
    fields <- tryCatch(read.dcf(desc_path, fields = "Version"), error = function(e) NULL)
    if (is.null(fields) || is.na(fields[1L, "Version"])) NA_character_ else fields[1L, "Version"]
  } else {
    NA_character_
  }

  git_state <- drmtmb_capture_git_state(root)

  list(
    package_version = package_version,
    git_sha = git_state$git_sha,
    git_dirty = git_state$git_dirty,
    build_time = build_time,
    source = if (is.na(git_state$git_sha)) "unavailable" else "baked",
    reason = git_state$reason
  )
}

#' Write a provenance record as a DCF file consumable by `drm_provenance()`
#'
#' @param rec A record as returned by `drmtmb_provenance()`.
#' @param path Output file path.
.drmtmb_write_provenance_dcf <- function(rec, path) {
  chr_or_na <- function(x) if (is.na(x)) "NA" else as.character(x)
  df <- data.frame(
    GitSHA = chr_or_na(rec$git_sha),
    GitDirty = chr_or_na(rec$git_dirty),
    GitReason = chr_or_na(rec$reason),
    BuildTimeUTC = chr_or_na(rec$build_time),
    stringsAsFactors = FALSE
  )
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write.dcf(df, file = path)
}

# --- CLI driver -------------------------------------------------------------
# Only runs when this file is executed directly (`Rscript tools/drmtmb_provenance.R`),
# never when it is `source()`d for its functions (e.g. from tests, or from
# ad hoc developer/fixture-stamping use -- NOT from `configure`, see the
# duplication note above).
if (identical(environment(), globalenv()) && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  root <- "."
  bake_path <- NULL
  i <- 1L
  while (i <= length(args)) {
    if (identical(args[[i]], "--root")) {
      root <- args[[i + 1L]]
      i <- i + 2L
    } else if (identical(args[[i]], "--bake")) {
      bake_path <- args[[i + 1L]]
      i <- i + 2L
    } else {
      i <- i + 1L
    }
  }
  rec <- drmtmb_provenance(root)
  if (!is.null(bake_path)) {
    .drmtmb_write_provenance_dcf(rec, bake_path)
    cat(sprintf("wrote build provenance to %s\n", bake_path))
  } else {
    for (nm in names(rec)) {
      cat(sprintf("%s: %s\n", nm, if (is.na(rec[[nm]])) "NA" else as.character(rec[[nm]])))
    }
  }
}
