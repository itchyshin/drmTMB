#!/usr/bin/env Rscript
# Print the R/ files that the lss-tip-identity receipt's runner can exercise.
#
# Used by tools/ci-receipt-staleness.sh so that guard fails only when a file the
# runner can reach has changed. Base R only (no package is loaded), so it runs on
# the same bare runner as the guard.
#
# THE RULE. The runner (tools/run-julia-phylo-labels-public.R) attaches the
# package with pkgload::load_all(), then calls bf(), drmTMB(), is_converged(),
# drm_julia_phylo_newick(), coef(), logLik() and fitted(). A file is EXERCISED
# when it is reachable from the runner through a static call graph of R/*.R:
#
#   * A node is one top-level assignment (a function or a constant) of one file.
#   * A node reaches every R/ node whose name its code mentions, as a symbol
#     (so a function passed to lapply() counts) or as a string constant (so
#     do.call("f", ...) and dispatch tables count).
#   * S3 dispatch: when reached code CALLS a name g (g in function position),
#     every R/ method `g.<cls>` is reachable, unless <cls> is a class that R/
#     itself constructs and that no reached code mentions (an object of that
#     class cannot exist in this run). A class R/ never mentions outside method
#     names (an external class such as "phylo") is always allowed.
#   * Roots: the runner's own mentions, .onLoad/.onAttach, and every top-level
#     statement that is not an assignment, a bare NULL, a bare string (roxygen
#     anchor) or utils::globalVariables(). A file holding such a statement is
#     exercised (it runs at load).
#
# The rule OVER-approximates: a mention in an untaken branch still counts. That
# can call a file exercised when this run never executes it (the guard then
# fails, the safe direction). It cannot call a file unexercised unless code is
# reached through a name assembled at run time from pieces that are not
# literals; R/ has one assembly site, get(paste0(generic, ".drmTMB")) in
# R/zzz.R, whose generics are the literals "fixef" and "ranef" and whose class
# suffix is a literal, so the method-prefix rule above follows it.
# Known blind spot: if a changed, unexercised file REMOVED a definition that an
# unchanged exercised file still calls, this rule reports a note, not a failure;
# the call then errors loudly in any test or check, it does not drift silently.
#
# Usage: Rscript tools/receipt-exercised-files.R [--explain] [RUNNER] [R_DIR]
# Output: one path per line, sorted (e.g. R/drmTMB.R). --explain adds, on stderr,
# the verdict per R/ file and the first few reached names it defines.

args <- commandArgs(trailingOnly = TRUE)
explain <- "--explain" %in% args
args <- setdiff(args, "--explain")
runner <- if (length(args) >= 1L) args[[1L]] else "tools/run-julia-phylo-labels-public.R"
r_dir <- if (length(args) >= 2L) args[[2L]] else "R"

# Symbols, string constants, and the subset of symbols used as a function.
scan_expr <- function(expr) {
  all <- character(0L)
  called <- character(0L)
  walk <- function(e) {
    if (is.symbol(e)) {
      s <- as.character(e)
      if (nzchar(s)) all <<- c(all, s)
    } else if (is.character(e)) {
      all <<- c(all, e)
    } else if (is.call(e) || is.pairlist(e) || is.expression(e) || is.list(e)) {
      if (is.call(e)) {
        head <- e[[1L]]
        if (is.symbol(head)) {
          called <<- c(called, as.character(head))
        } else if (is.call(head) && length(head) == 3L &&
                   (identical(head[[1L]], as.name("::")) || identical(head[[1L]], as.name(":::"))) &&
                   is.symbol(head[[3L]])) {
          called <<- c(called, as.character(head[[3L]]))
        }
      }
      for (i in seq_along(e)) {
        el <- e[[i]]
        if (!missing(el)) walk(el)
      }
    }
  }
  walk(expr)
  list(all = unique(all), called = unique(called))
}

is_assignment <- function(e) {
  is.call(e) && (identical(e[[1L]], as.name("<-")) || identical(e[[1L]], as.name("="))) &&
    (is.name(e[[2L]]) || is.character(e[[2L]]))
}
is_inert <- function(e) {
  is.null(e) || is.character(e) ||
    (is.call(e) && identical(deparse(e[[1L]]), "utils::globalVariables"))
}

files <- sort(list.files(r_dir, full.names = TRUE, pattern = "[.]R$"))
node_file <- character(0L)
node_name <- character(0L)
node_all <- list()
node_called <- list()
load_time <- list(file = character(0L), all = list(), called = list())
for (f in files) {
  for (e in parse(f, keep.source = FALSE)) {
    if (is_assignment(e)) {
      s <- scan_expr(e[[3L]])
      id <- length(node_file) + 1L
      node_file[id] <- f
      node_name[id] <- as.character(e[[2L]])
      node_all[[id]] <- s$all
      node_called[[id]] <- s$called
    } else if (!is_inert(e)) {
      s <- scan_expr(e)
      k <- length(load_time$file) + 1L
      load_time$file[k] <- f
      load_time$all[[k]] <- s$all
      load_time$called[[k]] <- s$called
    }
  }
}

# Split a method name `g.cls` at every dot: list of (generic, class) candidates.
split_name <- function(nm) {
  d <- gregexpr(".", nm, fixed = TRUE)[[1L]]
  d <- d[d > 1L & d < nchar(nm)]
  lapply(d, function(k) c(substr(nm, 1L, k - 1L), substr(nm, k + 1L, nchar(nm))))
}
method_split <- lapply(node_name, split_name)
# Classes R/ constructs: any mention of the class outside a method's own name.
mentioned_anywhere <- unique(c(unlist(node_all), unlist(load_time$all)))

seen <- logical(length(node_file))
mentioned <- character(0L)   # every name mentioned by the runner or a reached node
called <- character(0L)      # every name called by the runner or a reached node
exercised <- character(0L)

take <- function(all, called_now) {
  mentioned <<- union(mentioned, all)
  called <<- union(called, called_now)
}
runner_scan <- scan_expr(parse(runner, keep.source = FALSE))
take(runner_scan$all, runner_scan$called)
for (k in seq_along(load_time$file)) {
  exercised <- union(exercised, load_time$file[k])
  take(load_time$all[[k]], load_time$called[[k]])
}
roots <- node_name %in% c(".onLoad", ".onAttach")

repeat {
  fresh <- integer(0L)
  for (i in which(!seen)) {
    hit <- roots[i] || node_name[i] %in% mentioned
    if (!hit) {
      for (p in method_split[[i]]) {
        if (p[[1L]] %in% called &&
            (p[[2L]] %in% mentioned || !(p[[2L]] %in% mentioned_anywhere))) {
          hit <- TRUE
          break
        }
      }
    }
    if (hit) fresh <- c(fresh, i)
  }
  if (!length(fresh)) break
  for (i in fresh) {
    seen[i] <- TRUE
    take(node_all[[i]], node_called[[i]])
  }
}
exercised <- sort(unique(c(exercised, node_file[seen])))

if (explain) {
  cat("exercised ", length(exercised), " of ", length(files), " R/ files\n", sep = "", file = stderr())
  for (f in files) {
    k <- which(seen & node_file == f)
    tag <- if (f %in% exercised) "EXERCISED" else "not on path"
    what <- if (length(k)) paste(utils::head(node_name[k], 3L), collapse = ", ") else
      if (f %in% exercised) "(load-time statement)" else ""
    cat(sprintf("%-11s %-40s %s\n", tag, f, what), file = stderr())
  }
}
if (length(exercised)) cat(exercised, sep = "\n")
