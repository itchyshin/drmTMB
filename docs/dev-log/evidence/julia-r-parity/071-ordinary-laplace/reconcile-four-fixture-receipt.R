#!/usr/bin/env Rscript
# Reconcile exact one-engine-target receipt rows produced by
# run-four-fixture-receipt.R.  This script deliberately refuses incomplete or
# inconsistent inputs rather than manufacturing an aggregate evidence table.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("usage: Rscript reconcile-four-fixture-receipt.R <fixture>", call. = FALSE)
id <- args[[1L]]
root <- normalizePath(".")
out <- file.path(root, "docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/receipt")
declared_targets <- function(id) {
  common <- data.frame(
    parm = c("fixef:mu:(Intercept)", "fixef:mu:x"),
    target_class = "fixed-effect", profile_ready = TRUE,
    stringsAsFactors = FALSE
  )
  if (id %in% c("binomial_ri", "poisson_ri")) {
    return(rbind(common, data.frame(parm = "sd:mu:(1 | group)", target_class = "random-effect-sd", profile_ready = TRUE)))
  }
  if (identical(id, "nb2_ri")) {
    return(rbind(
      common,
      data.frame(parm = c("fixef:sigma:(Intercept)", "sigma", "sd:mu:(1 | group)"),
                 target_class = c("fixed-effect", "distributional-scale", "random-effect-sd"),
                 profile_ready = c(TRUE, FALSE, TRUE))
    ))
  }
  if (!identical(id, "nb2_coupled")) stop("unknown frozen fixture: ", id, call. = FALSE)
  rbind(
    common,
    data.frame(parm = c("fixef:sigma:(Intercept)", "fixef:sigma:z", "cholesky:recov:L11", "cholesky:recov:L22", "cholesky:recov:L21"),
               target_class = c("fixed-effect", "fixed-effect", "covariance-coordinate", "covariance-coordinate", "covariance-coordinate"),
               profile_ready = TRUE)
  )
}
targets <- declared_targets(id)
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
same_row <- function(x, y) {
  row.names(x) <- NULL
  row.names(y) <- NULL
  identical(x, y)
}
same_target_declaration <- function(x, y) {
  keep <- c("fixture", "parm", "target_class")
  identical(unname(unlist(x[keep], use.names = FALSE)), unname(unlist(y[keep], use.names = FALSE))) &&
    is.logical(x$profile_ready) && length(x$profile_ready) == 1L
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
  tmb_point <- read_one(file.path(out, paste0(id, tmb_suffix, "-point-receipt.tsv")), "TMB point")
  julia_point <- read_one(file.path(out, paste0(id, julia_suffix, "-point-receipt.tsv")), "Julia point")
  if (!identical(tmb_point$parm[[1L]], target) || !identical(julia_point$parm[[1L]], target)) stop("point target label drift for ", target, call. = FALSE)
  if (!identical(tmb_point$engine[[1L]], "tmb") || !identical(julia_point$engine[[1L]], "julia")) stop("point engine label drift for ", target, call. = FALSE)
  point_rows[[length(point_rows) + 1L]] <- tmb_point
  point_rows[[length(point_rows) + 1L]] <- julia_point
  tmb_target <- read_one(file.path(out, paste0(id, tmb_suffix, "-target-manifest.tsv")), "TMB target manifest")
  julia_target <- read_one(file.path(out, paste0(id, julia_suffix, "-target-manifest.tsv")), "Julia target manifest")
  expected_target <- data.frame(fixture = id, targets[i, , drop = FALSE], stringsAsFactors = FALSE)
  if (!same_target_declaration(tmb_target, expected_target) || !same_target_declaration(julia_target, expected_target)) stop("engine target manifests disagree with the frozen declaration for ", target, call. = FALSE)
  fixture_rows[[length(fixture_rows) + 1L]] <- read_one(file.path(out, paste0(id, tmb_suffix, "-fixture-manifest.tsv")), "TMB fixture manifest")
  fixture_rows[[length(fixture_rows) + 1L]] <- read_one(file.path(out, paste0(id, julia_suffix, "-fixture-manifest.tsv")), "Julia fixture manifest")
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
