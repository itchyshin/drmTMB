#!/usr/bin/env Rscript

# Rebuild a current-source TMB objective from one retained Ayumi OU cell and
# write a deliberately short profile diagnostic for its location-side alpha.
# This is a boundary diagnostic, not an interval calculation.
#
# Usage:
#   Rscript tools/phylo-ou-ayumi-alpha-profile.R <ou-cell.rds> <output-csv>

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Usage: Rscript tools/phylo-ou-ayumi-alpha-profile.R <ou-cell.rds> <output-csv>", call. = FALSE)
}
cell_file <- normalizePath(args[[1L]], mustWork = TRUE)
output_file <- args[[2L]]
if (!requireNamespace("pkgload", quietly = TRUE) || !requireNamespace("TMB", quietly = TRUE)) {
  stop("This diagnostic needs pkgload and TMB.", call. = FALSE)
}
pkgload::load_all(".", compile = TRUE, quiet = TRUE)

cell <- readRDS(cell_file)
fit <- cell$fit
if (is.null(fit) || !identical(fit$model$structured$phylo_mu$model, "ou")) {
  stop("The retained cell is not a fitted phylogenetic OU model.", call. = FALSE)
}
if (!identical(fit$provenance$git_sha, trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE)))) {
  stop("The retained fit was not built from the current source; refit before profiling.", call. = FALSE)
}
obj <- TMB::MakeADFun(
  data = fit$model$tmb_data,
  parameters = fit$model$start,
  map = fit$model$map,
  random = fit$model$tmb_random_names,
  DLL = "drmTMB",
  silent = TRUE
)
drmTMB:::drm_pin_tmb_object_to_optimum(obj, fit$opt, fit$tmb_state)
started <- proc.time()[["elapsed"]]
profile <- TMB::tmbprofile(
  obj,
  name = "log_decay_phylo",
  ytol = 0.1,
  ystep = 0.1,
  maxit = 1L,
  trace = FALSE
)
elapsed <- proc.time()[["elapsed"]] - started
profile$alpha_mu <- exp(profile$log_decay_phylo)
profile$profile_seconds <- elapsed
profile$fit_source_commit <- fit$provenance$git_sha
profile$claim_boundary <- "Short local profile diagnostic only; not a confidence interval or a general inference result."
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(profile, output_file, row.names = FALSE)
cat(sprintf("AYUMI_OU_ALPHA_PROFILE_PASS rows=%d seconds=%.3f output=%s\n",
  nrow(profile), elapsed, normalizePath(output_file)
))
