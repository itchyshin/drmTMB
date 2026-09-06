# Census of every skip condition in tests/testthat, classified by WHAT WOULD
# HAVE TO CHANGE for the skipped code to run.
#
# Two different diseases print as the same green line.
#
#   1. BUILD premise. The test needs a file that `.Rbuildignore` keeps out of
#      the tarball (`tools/`, `docs/`, `pkgdown/`, ...). Under `R CMD check`
#      that file is absent on every runner, so the skip is permanent and no
#      environment change can lift it. Measured separately in PR #1222.
#
#   2. ENVIRONMENT premise. The test needs something the RUNNER does not have:
#      a package, an external executable, an environment variable, an operating
#      system. Nothing about the build is wrong; the runner is simply not
#      configured for it. Some of these are satisfied on CI (and therefore
#      cost nothing), and some are never satisfied on any runner -- those are
#      as permanent as (1), for a completely different reason.
#
# This file is the SCANNER for both. It lives under tests/testthat/ rather than
# tools/ deliberately: `^tools$` is in `.Rbuildignore`, so a scanner living
# there could not run under `R CMD check` -- it would sit inside the very blind
# spot it exists to measure. From here it runs in the tarball as well as the
# source tree, and `tools/write-env-skip-census.R` sources it so the generator
# and the guard can never drift apart.
#
# Base R only. No package load, no fits: it parses R source and nothing else.

# testthat's own skip verbs plus the two project-local wrappers.
drm_skip_call_names <- function() {
  c(
    "skip",
    "skip_if",
    "skip_if_not",
    "skip_if_not_installed",
    "skip_if_offline",
    "skip_on_bioc",
    "skip_on_ci",
    "skip_on_covr",
    "skip_on_cran",
    "skip_on_os",
    "skip_on_travis",
    # project-local wrappers, defined in tests/testthat/helper-*.R
    "skip_fragile_recovery",
    "drm_skip_live_julia"
  )
}

# The condition of the nearest enclosing `if`, or "" when there is none.
#
# Needed because a bare `skip("...")` often sits one line below the test that
# decided it -- `if (!file.exists(path)) skip("fixture unavailable")`. Reading
# only the skip call would file that as run-decided when its real premise is a
# path the build removed. Classification uses call text AND this guard.
drm_enclosing_if_condition <- function(pd, call_id) {
  id <- call_id
  for (depth in seq_len(24L)) {
    parent <- pd$parent[match(id, pd$id)]
    if (is.na(parent) || parent <= 0L) break
    kids <- pd[pd$parent == parent, , drop = FALSE]
    if (any(kids$token == "IF")) {
      cond <- kids[kids$token == "expr", , drop = FALSE]
      if (nrow(cond)) {
        txt <- tryCatch(
          paste(utils::getParseText(pd, cond$id[1L]), collapse = " "),
          error = function(e) ""
        )
        return(gsub("[[:space:]]+", " ", txt))
      }
    }
    id <- parent
  }
  ""
}

# One row per skip CALL SITE, from the parse tree rather than a grep: a grep
# counts the word inside comments and prose, and this number is the deliverable.
drm_scan_skip_sites <- function(dir = ".") {
  files <- sort(
    list.files(dir, pattern = "^(test|helper)-.*\\.[Rr]$", full.names = TRUE),
    method = "radix"
  )
  wanted <- drm_skip_call_names()
  rows <- list()
  for (f in files) {
    exprs <- parse(f, keep.source = TRUE)
    pd <- utils::getParseData(exprs)
    if (is.null(pd) || !nrow(pd)) next
    hits <- pd[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text %in% wanted, , drop = FALSE]
    if (!nrow(hits)) next
    for (i in seq_len(nrow(hits))) {
      sym_expr <- pd$parent[match(hits$id[i], pd$id)]
      call_id <- pd$parent[match(sym_expr, pd$id)]
      txt <- tryCatch(
        paste(utils::getParseText(pd, call_id), collapse = " "),
        error = function(e) ""
      )
      txt <- gsub("[[:space:]]+", " ", txt)
      if (!nzchar(txt)) txt <- hits$text[i]
      rows[[length(rows) + 1L]] <- list(
        file = basename(f),
        line = as.integer(hits$line1[i]),
        fn = hits$text[i],
        call = txt,
        guard = drm_enclosing_if_condition(pd, call_id)
      )
    }
  }
  if (!length(rows)) {
    return(data.frame(
      file = character(0), line = integer(0), fn = character(0),
      call = character(0), guard = character(0), stringsAsFactors = FALSE
    ))
  }
  out <- data.frame(
    file = vapply(rows, `[[`, character(1), "file"),
    line = vapply(rows, `[[`, integer(1), "line"),
    fn = vapply(rows, `[[`, character(1), "fn"),
    call = vapply(rows, `[[`, character(1), "call"),
    guard = vapply(rows, `[[`, character(1), "guard"),
    stringsAsFactors = FALSE
  )
  out[order(out$file, out$line, method = "radix"), , drop = FALSE]
}

# What would have to change for this call NOT to skip.
#
# Order is deliberate: the most specific mechanism wins. A DRM.jl gate is
# written as dir.exists() of an env-var-supplied path, so it would otherwise be
# misread as a filesystem premise; it is classified by the env var it reads,
# which is what an owner would actually have to set.
drm_classify_skip <- function(fn, call, guard = "") {
  call <- paste(call, guard)
  if (identical(fn, "skip_if_not_installed")) return("suggests-package")
  if (identical(fn, "skip_on_cran")) return("cran-lane")
  if (identical(fn, "skip_on_os")) return("os")
  if (identical(fn, "skip_on_ci")) return("ci-permanent")
  if (identical(fn, "skip_fragile_recovery")) return("env-var-optin")
  if (identical(fn, "drm_skip_live_julia")) return("engine-drm-jl")
  if (grepl("DRM_JL|DRM\\.jl|drmjl|jl_path", call)) return("engine-drm-jl")
  if (grepl("DRMTMB_RUN_FRAGILE_RECOVERY", call)) return("env-var-optin")
  if (grepl("NOT_CRAN", call)) return("cran-lane")
  if (grepl("Sys\\.which|pandoc_available|\\b(git|bash|python3|Rscript|pandoc) (is |not )", call)) {
    return("external-tool")
  }
  if (grepl("DRMTMB_[A-Z_]+|Sys\\.getenv", call)) return("env-var-optin")
  if (grepl("collat|locale|Sys\\.setlocale", call, ignore.case = TRUE)) return("locale")
  if (grepl("LAPACK|BLAS|pdHess|eigen", call)) return("platform-numeric")
  # Blind spot #1's sibling: the premise is a git OBJECT the published history
  # does not contain, so no clone can supply it and no runner setting can fix
  # it. Kept off the "environment" axis deliberately -- a runner cannot install
  # its way out of this one.
  if (grepl("never pushed|absent from this clone|unpushed commit", call)) {
    return("history-premise")
  }
  if (grepl(paste0(
    "file\\.exists|dir\\.exists|system\\.file|test_path|\\.Rbuildignore|tarball|",
    "source checkout|source tree|source package|source-only|installed[- ]package|",
    "not (installed|shipped|reachable) |source file not available"
  ), call)) {
    return("build-premise")
  }
  "runtime-conditional"
}

# Is the mechanism something a RUNNER can supply (environment), something only
# the BUILD can supply, or something the run itself decides?
drm_skip_axis <- function(gate_class) {
  ifelse(
    gate_class %in% c(
      "suggests-package", "cran-lane", "os", "ci-permanent",
      "env-var-optin", "engine-drm-jl", "external-tool", "locale"
    ),
    "environment",
    ifelse(gate_class %in% c("build-premise", "history-premise"), "build", "runtime")
  )
}

# What the drmTMB CI runner actually does with each mechanism.
#
# "runs"    -- the runner satisfies the premise; the guarded code executes.
# "skips"   -- the runner never satisfies it; the skip is PERMANENT there.
# "depends" -- decided by the run's own data or numerics, not by configuration.
#
# Every "runs" and "skips" below is MEASURED, not assumed. Evidence, all from
# the last completed green routine run on main before this census
# (GitHub Actions run 34004644639, head eccb10299, 4 ubuntu-latest shards,
# R 4.6.1, Ubuntu 24.04.4, 2026-09-06):
#
#   suggests-package  All 24 distinct packages named by skip_if_not_installed()
#                     appear in that run's `Session info` package table
#                     (setup-r-dependencies@v2 installs Suggests). No
#                     skip_if_not_installed reason appears anywhere in the
#                     run's four "Skipped tests" blocks.
#   cran-lane         .github/workflows/R-CMD-check.yaml sets `NOT_CRAN: true`
#                     in the job env, so skip_on_cran() is a no-op; no
#                     skip_on_cran reason appears in the run.
#   external-tool     git, bash, python3 and Rscript are present on
#                     ubuntu-latest and the workflow runs setup-pandoc@v2; no
#                     external-tool reason appears in the run.
#   os                All skip_on_os() sites name "windows"; routine runs are
#                     ubuntu-latest only, so they execute. They skip only on
#                     the tag / workflow_dispatch full-OS matrix.
#   engine-drm-jl     The workflow never sets DRM_JL_PATH or DRM_JL_PHYLO_PATH
#                     and never installs Julia. The run reports 54 skips whose
#                     reason is "DRM.jl engine not available (set DRM_JL_PATH)".
#   env-var-optin     The workflow never sets DRMTMB_RUN_FRAGILE_RECOVERY, and
#                     CI is set, so skip_fragile_recovery() always fires: 8
#                     skips reported with that reason.
#   build-premise     Blind spot #1, measured in PR #1222: `.Rbuildignore`
#                     removes the premise from the tarball CI checks.
#   history-premise   The premise is a git object the published history does not
#                     contain, so every clone lacks it and no runner setting
#                     helps. Measured in PR #1222: the q6 audit's frozen
#                     runner_source_sha a8d068e64 returns 422 from the GitHub
#                     API and is on no remote ref.
#   locale            The runner collates as C.UTF-8, not en_US.UTF-8, so the
#                     two sites disagree in opposite senses; on this runner
#                     both are masked by an upstream engine-drm-jl gate.
drm_skip_ci_status <- function(gate_class) {
  status <- c(
    "suggests-package" = "runs",
    "cran-lane" = "runs",
    "external-tool" = "runs",
    "os" = "runs",
    "engine-drm-jl" = "skips",
    "env-var-optin" = "skips",
    "ci-permanent" = "skips",
    "build-premise" = "skips",
    "history-premise" = "skips",
    "locale" = "depends",
    "platform-numeric" = "depends",
    "runtime-conditional" = "depends"
  )
  unname(status[gate_class])
}

# Parsing the whole suite costs about 3 s, and three tests want the same
# answer, so it is computed once per session.
.drm_skip_census_cache <- new.env(parent = emptyenv())

drm_skip_census <- function(dir = ".") {
  key <- normalizePath(dir, mustWork = FALSE)
  hit <- .drm_skip_census_cache[[key]]
  if (!is.null(hit)) return(hit)
  d <- drm_scan_skip_sites(dir)
  if (!nrow(d)) return(cbind(d, gate_class = character(0), axis = character(0),
                 ci_status = character(0)))
  d$gate_class <- vapply(
    seq_len(nrow(d)),
    function(i) drm_classify_skip(d$fn[i], d$call[i], d$guard[i]),
    character(1)
  )
  d$axis <- drm_skip_axis(d$gate_class)
  d$ci_status <- drm_skip_ci_status(d$gate_class)
  assign(key, d, envir = .drm_skip_census_cache)
  d
}

# The packages named by skip_if_not_installed(), from the call text.
drm_skip_installed_targets <- function(census) {
  calls <- census$call[census$gate_class == "suggests-package"]
  m <- regmatches(calls, regexpr('"[^"]+"', calls))
  sort(unique(gsub('"', "", m)), method = "radix")
}

# The committed artefact, as lines: one row per (file, gate_class), with a
# count of the call sites.
#
# DELIBERATELY NOT ONE ROW PER LINE. A per-line artefact would be re-derived
# every time anything shifted a line number anywhere above a skip -- which is
# most test edits -- so it would churn constantly and conflict in every parallel
# branch, and a guard people routinely regenerate to make red go away is a guard
# that has stopped guarding. Aggregated, the artefact moves only when a file
# gains or loses a gate, or a gate changes class: exactly the events worth
# noticing. Per-line detail is a `Rscript tools/write-env-skip-census.R` away.
#
# One function so the generator (tools/write-env-skip-census.R) and the guard
# (test-env-skip-census.R) can never disagree about the bytes.
drm_env_skip_census_tsv <- function(census) {
  cols <- c("file", "gate_class", "axis", "ci_status")
  stopifnot(all(c(cols, "line") %in% names(census)))
  key <- do.call(paste, c(lapply(cols, function(k) census[[k]]), list(sep = "\t")))
  n <- table(key)
  keys <- sort(names(n), method = "radix")
  c(
    paste(c(cols, "sites"), collapse = "\t"),
    paste(keys, as.integer(n[keys]), sep = "\t")
  )
}
