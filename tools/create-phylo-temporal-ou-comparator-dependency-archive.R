#!/usr/bin/env Rscript
# Seal the exact CRAN source closure needed to add glmmTMB to the verified
# G12 Linux R library.  No package is downloaded during a DRAC job.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop('Usage: create-phylo-temporal-ou-comparator-dependency-archive.R <source-dir> <output.tar.gz>', call. = FALSE)
}
source_dir <- normalizePath(args[[1L]], mustWork = TRUE)
out <- normalizePath(args[[2L]], mustWork = FALSE)
if (file.exists(out)) stop('Output archive already exists: ', out, call. = FALSE)
required <- c(
  'ape', 'backports', 'boot', 'broom', 'cli', 'colorspace', 'cpp11', 'Deriv',
  'digest', 'doBy', 'dplyr', 'farver', 'forecast', 'fracdiff', 'generics',
  'ggplot2', 'glmmTMB', 'glue', 'gtable', 'isoband', 'labeling', 'lattice',
  'lifecycle', 'lme4', 'lmtest', 'magrittr', 'MASS', 'Matrix', 'mgcv', 'minqa',
  'modelr', 'nlme', 'nloptr', 'nnet', 'numDeriv', 'pbkrtest', 'pillar',
  'pkgconfig', 'purrr', 'R6', 'rbibutils', 'RColorBrewer', 'Rcpp',
  'RcppArmadillo', 'RcppEigen', 'Rdpack', 'reformulas', 'rlang', 'S7',
  'sandwich', 'scales', 'stringi', 'stringr', 'tibble', 'tidyr', 'tidyselect',
  'timeDate', 'TMB', 'urca', 'utf8', 'vctrs', 'viridisLite', 'withr', 'zoo'
)
lock_path <- file.path(dirname(source_dir), 'LOCKED-PACKAGES.csv')
if (file.exists(lock_path)) {
  locked <- read.csv(lock_path, stringsAsFactors = FALSE)
  if (!identical(names(locked), c('package', 'version')) || anyDuplicated(locked$package)) stop('Malformed LOCKED-PACKAGES.csv.', call. = FALSE)
  required <- locked$package
}
source_files <- list.files(source_dir, pattern = '\\.tar\\.gz$', full.names = TRUE)
pick_source <- function(pkg) {
  candidates <- source_files[startsWith(basename(source_files), paste0(pkg, '_'))]
  if (length(candidates) != 1L) stop('Need exactly one source archive for ', pkg, '; found ', length(candidates), call. = FALSE)
  candidates
}
selected <- vapply(required, pick_source, character(1L))
stage <- tempfile('phylo-temporal-ou-comparator-deps-')
dir.create(stage)
on.exit(unlink(stage, recursive = TRUE, force = TRUE), add = TRUE)
dir.create(file.path(stage, 'packages'))
for (src in selected) file.copy(src, file.path(stage, 'packages', basename(src)), copy.date = FALSE)
manifest <- data.frame(
  package = required,
  archive = basename(selected),
  sha256 = unname(tools::sha256sum(selected)),
  stringsAsFactors = FALSE
)
write.csv(manifest, file.path(stage, 'dependency-manifest.csv'), row.names = FALSE, quote = TRUE)
old <- getwd(); on.exit(setwd(old), add = TRUE); setwd(stage)
status <- system2('tar', c('-czf', out, 'packages', 'dependency-manifest.csv'))
if (!identical(status, 0L) || !file.exists(out)) stop('Failed to create dependency archive.', call. = FALSE)
cat(unname(tools::sha256sum(out)), ' ', out, '\n', sep = '')
