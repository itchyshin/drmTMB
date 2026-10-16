# Generate every t2 dataset once, so drmTMB and DRModels.jl fit identical data.
#
# Usage: Rscript t2_gen_data.R <outdir>
# Writes <outdir>/<cell>.csv (all 500 reps stacked, 17 significant digits),
# <outdir>/truth.csv, <outdir>/seeds.csv, and <outdir>/SHA256SUMS.

args <- commandArgs(trailingOnly = TRUE)
here <- dirname(normalizePath(sub("--file=", "",
  grep("--file=", commandArgs(FALSE), value = TRUE)[1])))
source(file.path(here, "t2_config.R"))
outdir <- if (length(args) >= 1L) args[[1]] else file.path(here, "data")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

cells <- t2_cells()
for (k in seq_len(nrow(cells))) {
  cl <- cells[k, ]
  d <- do.call(rbind, lapply(seq_len(T2_REPS), function(r) {
    t2_simulate(cl$n, cl$G, r)
  }))
  path <- file.path(outdir, paste0(cl$cell, ".csv"))
  utils::write.csv(
    format(d, digits = 17, scientific = FALSE, trim = TRUE),
    path, row.names = FALSE, quote = FALSE
  )
  # Round-trip check: the text file must reproduce the doubles exactly.
  back <- utils::read.csv(path)
  stopifnot(identical(back$y, d$y), identical(back$x, d$x), identical(back$z, d$z))
  message(sprintf("%s: %d rows", cl$cell, nrow(d)))
}

utils::write.csv(data.frame(param = names(T2_TRUTH), true = unname(T2_TRUTH)),
                 file.path(outdir, "truth.csv"), row.names = FALSE)
utils::write.csv(
  data.frame(rep = seq_len(T2_REPS),
             seed_nominal = sprintf("%.0f", T2_SEED_BASE + seq_len(T2_REPS)),
             seed_r = t2_seed_r(seq_len(T2_REPS))),
  file.path(outdir, "seeds.csv"), row.names = FALSE
)
utils::write.csv(cells, file.path(outdir, "cells.csv"), row.names = FALSE)
files <- list.files(outdir, pattern = "\\.csv$", full.names = TRUE)
sums <- vapply(files, function(f) {
  sub(" .*", "", system2("sha256sum", f, stdout = TRUE))
}, character(1))
writeLines(paste(sums, basename(files)), file.path(outdir, "SHA256SUMS"))
