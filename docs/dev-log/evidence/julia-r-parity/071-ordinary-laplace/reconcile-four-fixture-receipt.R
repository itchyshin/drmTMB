#!/usr/bin/env Rscript
# Reconcile exact one-engine-target receipt rows produced by
# run-four-fixture-receipt.R.  This script deliberately refuses incomplete or
# inconsistent inputs rather than manufacturing an aggregate evidence table.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("usage: Rscript reconcile-four-fixture-receipt.R <fixture>", call. = FALSE)
id <- args[[1L]]
root <- normalizePath(".")
out <- file.path(root, "docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/receipt")
target_path <- file.path(out, paste0(id, "-target-checkpoint.tsv"))
if (!file.exists(target_path)) stop("missing generated target checkpoint: ", target_path, call. = FALSE)
targets <- read.delim(target_path, check.names = FALSE, stringsAsFactors = FALSE)
if (!nrow(targets) || anyDuplicated(targets$parm)) stop("target checkpoint must contain unique declared targets", call. = FALSE)
stamp <- function(repo) system2("git", c("-C", shQuote(repo), "rev-parse", "HEAD"), stdout = TRUE)
jl <- Sys.getenv("DRM_JL_PATH", "")
if (!nzchar(jl) || !dir.exists(jl)) stop("DRM_JL_PATH must name the committed DRM.jl lane", call. = FALSE)
suffix <- function(engine, target) paste0("-", sub("_+$", "", gsub("[^A-Za-z0-9]+", "_", paste(engine, target, sep = "-"))))
read_one <- function(path, what) {
  if (!file.exists(path)) stop("missing ", what, " receipt: ", path, call. = FALSE)
  x <- read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
  if (nrow(x) != 1L) stop(what, " receipt must contain exactly one row: ", path, call. = FALSE)
  x
}

profile_rows <- list(); point_rows <- list(); target_rows <- list(); fixture_rows <- list()
for (i in seq_len(nrow(targets))) {
  target <- targets$parm[[i]]
  target_rows[[i]] <- targets[i, , drop = FALSE]
  tmb_suffix <- suffix("tmb", target)
  julia_suffix <- suffix("julia", target)
  tmb_profile <- read_one(file.path(out, paste0(id, tmb_suffix, "-profile-receipt.tsv")), "TMB profile")
  julia_profile <- read_one(file.path(out, paste0(id, julia_suffix, "-profile-receipt.tsv")), "Julia profile")
  if (!identical(tmb_profile$parm[[1L]], target) || !identical(julia_profile$parm[[1L]], target)) stop("profile target label drift for ", target, call. = FALSE)
  if (!identical(tmb_profile$engine[[1L]], "tmb") || !identical(julia_profile$engine[[1L]], "julia")) stop("profile engine label drift for ", target, call. = FALSE)
  profile_rows[[length(profile_rows) + 1L]] <- tmb_profile
  profile_rows[[length(profile_rows) + 1L]] <- julia_profile
  tmb_point <- read.delim(file.path(out, paste0(id, tmb_suffix, "-point-receipt.tsv")), check.names = FALSE, stringsAsFactors = FALSE)
  julia_point <- read.delim(file.path(out, paste0(id, julia_suffix, "-point-receipt.tsv")), check.names = FALSE, stringsAsFactors = FALSE)
  if (nrow(tmb_point) != 2L || nrow(julia_point) != 2L || !identical(tmb_point, julia_point)) stop("point receipts disagree for ", target, call. = FALSE)
  point_rows[[i]] <- tmb_point
  fixture_rows[[i]] <- read_one(file.path(out, paste0(id, tmb_suffix, "-fixture-manifest.tsv")), "fixture manifest")
}
fixture_ref <- fixture_rows[[1L]]
if (!all(vapply(fixture_rows, identical, logical(1), fixture_ref))) stop("fixture bytes or dimensions drifted across engine-target tasks", call. = FALSE)
profile <- do.call(rbind, profile_rows)
point <- do.call(rbind, point_rows)
target <- do.call(rbind, target_rows)
if (nrow(profile) != 2L * nrow(target) || nrow(point) != 2L * nrow(target)) stop("aggregate denominator is incomplete", call. = FALSE)
write.table(fixture_ref, file.path(out, paste0(id, "-fixture-manifest.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
write.table(target, file.path(out, paste0(id, "-target-manifest.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
write.table(point, file.path(out, paste0(id, "-point-receipt.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
write.table(profile, file.path(out, paste0(id, "-profile-receipt.tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
writeLines(c("# 0.7.1 four-fixture receipt", "", paste0("- drmTMB: `", stamp(root), "`"), paste0("- DRM.jl: `", stamp(jl), "`"), "- This is one frozen fixture per family; it is not coverage evidence."), file.path(out, "README.md"))
cat("FOUR_FIXTURE_RECONCILED\n")
