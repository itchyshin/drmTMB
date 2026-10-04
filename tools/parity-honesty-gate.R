#!/usr/bin/env Rscript
# tools/parity-honesty-gate.R -- Arc 1's headline (S1a, 2026-09-24).
#
# Turns "the ledger is honest" from a reading exercise into a check: every
# non-GREEN row of docs/design/parity-matrix.md must be DEFECT, FENCED,
# OWNER-DECISION, CITED-PARTIAL, or CITED-LIMITED (`pm_honest_state()` in
# tools/write-parity-matrix.R); a row reading UNCITED or DEFECT fails this
# gate.
#
# USAGE (same DRM_JL_PATH contract as tools/write-parity-matrix.R -- no Julia
# is started; the DRM.jl clone is read at its committed pin with `git show`):
#   DRM_JL_PATH=/path/to/DRM.jl-clone Rscript tools/parity-honesty-gate.R
#   DRM_JL_PATH=... Rscript tools/parity-honesty-gate.R --list owner-decision
#
# Prints one "<STATE> :: <capability>" line per row (all 45), then EXACTLY one
# summary line:
#   HONESTY: green=N fenced=N owner_decision=N cited_partial=N cited_limited=N uncited=N defect=N
# and exits 1 when uncited + defect > 0, 0 otherwise -- GOAL.md's finish line
# is `uncited=0 defect=0` at exit 0.
#
# `--list <state>` (dash/underscore/case-insensitive, e.g. `owner-decision`,
# `FENCED`, `cited_partial`) prints only that state's rows instead of the
# summary. For `--list owner-decision`, each line additionally names the
# ticket and owner from inst/extdata/julia-fences.tsv (`... T1 owner=Shinichi`),
# and a trailing `OWNER_DECISION_UNNAMED=N` line counts rows whose fences.tsv
# entry is missing a ticket or an owner (D1b).

pg_states <- function() {
  c("DEFECT", "GREEN", "FENCED", "OWNER-DECISION", "CITED-PARTIAL", "CITED-LIMITED", "UNCITED")
}

pg_normalize_state <- function(x) toupper(gsub("_", "-", x, fixed = TRUE))

pg_parse_args <- function(args) {
  list_state <- NULL
  li <- which(args == "--list")
  if (length(li)) {
    if (length(args) < li[[1L]] + 1L) {
      stop("--list requires a state argument, one of: ", paste(pg_states(), collapse = ", "), call. = FALSE)
    }
    list_state <- pg_normalize_state(args[[li[[1L]] + 1L]])
    if (!list_state %in% pg_states()) {
      stop("unknown --list state '", args[[li[[1L]] + 1L]], "'; one of: ", paste(pg_states(), collapse = ", "), call. = FALSE)
    }
    args <- args[-c(li[[1L]], li[[1L]] + 1L)]
  }
  list(list_state = list_state, rest = args)
}

pg_main <- function() {
  parsed <- pg_parse_args(commandArgs(trailingOnly = TRUE))
  args <- parsed$rest
  drmjl_path <- if (length(args) >= 1L) args[[1L]] else Sys.getenv("DRM_JL_PATH", unset = "")
  if (!nzchar(drmjl_path) || !dir.exists(drmjl_path)) {
    stop("Set DRM_JL_PATH (or pass it as the first argument) to a DRM.jl clone at the pin.", call. = FALSE)
  }

  tool <- file.path(".", "tools", "write-parity-matrix.R")
  env <- new.env(parent = globalenv())
  sys.source(tool, envir = env)

  ctx <- env$pm_load_context(".", drmjl_path)
  mat <- env$pm_build_matrix(ctx)

  if (is.null(parsed$list_state)) {
    for (i in seq_len(nrow(mat))) {
      cat(sprintf("%s :: %s\n", mat$honest_state[[i]], mat$capability[[i]]))
    }
    counts <- table(factor(mat$honest_state, levels = pg_states()))
    cat(sprintf(
      "HONESTY: green=%d fenced=%d owner_decision=%d cited_partial=%d cited_limited=%d uncited=%d defect=%d\n",
      counts[["GREEN"]], counts[["FENCED"]], counts[["OWNER-DECISION"]],
      counts[["CITED-PARTIAL"]], counts[["CITED-LIMITED"]], counts[["UNCITED"]], counts[["DEFECT"]]
    ))
    quit(status = if (counts[["UNCITED"]] + counts[["DEFECT"]] > 0L) 1L else 0L, save = "no")
  }

  keep <- mat$honest_state == parsed$list_state
  rows <- mat[keep, , drop = FALSE]
  if (identical(parsed$list_state, "OWNER-DECISION")) {
    unnamed <- 0L
    for (i in seq_len(nrow(rows))) {
      fi <- match(rows$capability[[i]], ctx$fences$capability)
      ticket <- if (is.na(fi)) "" else ctx$fences$ticket[[fi]]
      owner <- if (is.na(fi)) "" else ctx$fences$owner[[fi]]
      if (!nzchar(ticket) || !nzchar(owner)) unnamed <- unnamed + 1L
      cat(sprintf(
        "%s :: %s owner=%s\n", rows$capability[[i]],
        if (nzchar(ticket)) ticket else "NONE",
        if (nzchar(owner)) owner else "NONE"
      ))
    }
    cat(sprintf("OWNER_DECISION_UNNAMED=%d\n", unnamed))
  } else {
    for (i in seq_len(nrow(rows))) cat(sprintf("%s\n", rows$capability[[i]]))
  }
  quit(status = 0L, save = "no")
}

if (sys.nframe() == 0L) {
  pg_main()
}
