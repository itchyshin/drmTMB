#!/usr/bin/env Rscript
# THE PROGRAMME PIN as one shared read path (S1b, Arc 1 honest ledger,
# 2026-09-24; LOOP/lanes/arc1-honest-ledger/ultra-plan.md, amendment A8).
#
# Before this file, each of the three parity generators
# (write-parity-matrix.R, write-parity-scoreboard.R,
# write-capability-status-join.R) decided for itself which DRModels commit to
# read: the matrix and scoreboard called `git rev-parse HEAD` on whatever
# clone DRM_JL_PATH named, with no check that it was the commit the ledger
# claims to be honest against, and the join defaulted to `origin/main` or a
# caller-supplied `DRM_JL_REF`. Three chances to read three different
# commits, silently. This file is the one place that decides "the programme
# pin" and the one place that refuses a mismatched checkout, so the other
# three can never disagree about it again.
#
# THE PIN. `docs/dev-log/loop/parity-joint-20260905/source-pins.json` records
# every re-pin in its `repins` array, in order (its own `repins_note` says
# the newest entry is the current programme pin). `pp_pin()` returns that
# entry's `drmjl_base`: a full 40-character DRModels commit sha.
#
# THE CHECK. `pp_verify_pin(repo)` reads `repo`'s HEAD with `git rev-parse`
# and stops -- naming both shas -- unless it equals the programme pin. A
# generator that read a mismatched checkout would silently cite the wrong
# commit as if it were the pin; refusing is the fix, not an exception to it.
# `expected` is a plain argument (not always `pp_pin()`) so a test can inject
# a sha and never needs a real DRModels clone.
#
# LOADED, NEVER RUN STANDALONE. `sys.source()`d by the three generators, the
# same pattern `write-parity-scoreboard.R`'s `sb_matrix_env()` and
# `write-capability-status-join.R`'s `csj_matrix_env()` already use for
# `write-parity-matrix.R` itself. This file defines no `main()` and has no
# CLI of its own.

pp_source_pins_path <- function(root = ".") {
  file.path(root, "docs", "dev-log", "loop", "parity-joint-20260905", "source-pins.json")
}

# The current programme pin: `repins[[length(repins)]]$drmjl_base`, read from
# `root`'s copy of source-pins.json. Aborts -- rather than guessing -- when
# the file, the array, or the field is missing, or the value is not a full
# 40-character hex sha.
pp_pin <- function(root = ".") {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required to read the programme pin (docs/dev-log/loop/parity-joint-20260905/source-pins.json).", call. = FALSE)
  }
  path <- pp_source_pins_path(root)
  if (!file.exists(path)) {
    stop("programme pin file not found: ", path, call. = FALSE)
  }
  pins <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  repins <- pins$repins
  if (!length(repins)) {
    stop("source-pins.json carries no repins[] entries: ", path, call. = FALSE)
  }
  pin <- repins[[length(repins)]]$drmjl_base
  if (is.null(pin) || !grepl("^[0-9a-f]{40}$", pin)) {
    stop("repins[-1].drmjl_base is not a 40-character sha in ", path, call. = FALSE)
  }
  pin
}

# `git rev-parse <ref>` in `repo`, generic: used both to read the DRModels
# checkout's HEAD (pp_verify_pin()) and, by the scoreboard and join
# generators, to read drmTMB's OWN HEAD for their "generated against" report
# -- a different question from the DRModels pin, answered by the same small
# wrapper so the literal git plumbing call lives in exactly one file.
pp_git_rev_parse <- function(repo, ref = "HEAD") {
  out <- suppressWarnings(system2(
    "git", c("-C", shQuote(repo), "rev-parse", ref), stdout = TRUE, stderr = FALSE
  ))
  status <- attr(out, "status")
  if (!is.null(status) && status != 0L) {
    stop("git rev-parse ", ref, " failed in ", repo, call. = FALSE)
  }
  as.character(out)[[1L]]
}

# Refuse a DRModels checkout whose HEAD is not the programme pin. Returns
# `expected` (invisibly) on a match, so a caller can write
# `pin <- pp_verify_pin(drmjl_path)`. `expected` defaults to `pp_pin(root)`
# but is a plain argument so tests can inject a sha without a source-pins.json
# or a real DRModels clone.
pp_verify_pin <- function(repo, expected = NULL, root = ".") {
  if (is.null(expected)) expected <- pp_pin(root)
  head <- pp_git_rev_parse(repo)
  if (!identical(head, expected)) {
    stop(sprintf(
      paste0(
        "DRModels checkout at %s is on %s, not the programme pin %s ",
        "(docs/dev-log/loop/parity-joint-20260905/source-pins.json repins[-1].drmjl_base). ",
        "Check out the pin, or add a new repins[] entry if this checkout IS the new pin."
      ),
      repo, head, expected
    ), call. = FALSE)
  }
  invisible(expected)
}

# A loader mirroring `write-parity-scoreboard.R`'s `sb_matrix_env()` and
# `write-capability-status-join.R`'s `csj_matrix_env()`: returns an
# environment carrying `pp_pin()` / `pp_git_rev_parse()` / `pp_verify_pin()`,
# so every generator reaches this file the same way regardless of which of
# the three sys.source()s it first.
pm_pin_env <- function(root = ".") {
  path <- file.path(root, "tools", "parity-pin.R")
  if (!file.exists(path)) {
    stop("tools/parity-pin.R not found under ", root, call. = FALSE)
  }
  env <- new.env(parent = globalenv())
  sys.source(path, envir = env)
  env
}
