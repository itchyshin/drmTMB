# One-sided Wald miss rates for the gate cells, pooled over reps 1-2500.
#
# The lane's coverage bar is two-sided, so it cannot see an interval that
# misses mostly on one side. This tabulates, per cell and parameter, the share
# of converged fits whose interval lies wholly below the truth ("truth above")
# or wholly above it ("truth below"), with an exact binomial test of symmetry
# among the misses.
#
# Usage: Rscript t2_onesided.R <engine> <outdir> <resultsdir> [<resultsdir> ...]
# Writes <outdir>/t2_onesided_<engine>.csv and .md.

args <- commandArgs(trailingOnly = TRUE)
engine <- args[[1]]
outdir <- args[[2]]
dirs <- args[-(1:2)]
files <- unlist(lapply(dirs, list.files,
  pattern = sprintf("^%s_n(0200|1000)_", engine), full.names = TRUE))
d <- do.call(rbind, lapply(files, function(f) {
  x <- utils::read.csv(f, na.strings = c("NA", "", "NaN"), stringsAsFactors = FALSE)
  x$converged <- as.logical(x$converged)
  x[x$converged %in% TRUE & !is.na(x$param),
    c("cell", "rep", "param", "true", "lower", "upper")]
}))
stopifnot(!anyDuplicated(d[, c("cell", "rep", "param")]))
pord <- c("mu_intercept", "mu_x", "sigma_intercept", "sigma_z", "sd_g")
corder <- c("n0200_none", "n1000_none", "n0200_G20", "n1000_G20", "n0200_G50", "n1000_G50")
o <- do.call(rbind, lapply(split(d, list(d$cell, d$param), drop = TRUE), function(x) {
  below <- sum(x$true < x$lower) # truth below the interval
  above <- sum(x$true > x$upper) # truth above the interval
  p <- if (below + above > 0) stats::binom.test(below, below + above)$p.value else NA_real_
  data.frame(cell = x$cell[1], param = x$param[1], reps = nrow(x),
             truth_below = below / nrow(x), truth_above = above / nrow(x),
             p_symmetric = p)
}))
o <- o[order(match(o$cell, corder), match(o$param, pord)), ]
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(o, file.path(outdir, sprintf("t2_onesided_%s.csv", engine)), row.names = FALSE)
md <- c(sprintf("Engine: %s; reps 1-2500 pooled.", engine), "",
        "| cell | parameter | reps | truth below interval | truth above interval | exact p (symmetric misses) |",
        "|---|---|---:|---:|---:|---:|",
        sprintf("| %s | %s | %d | %.2f%% | %.2f%% | %s |", o$cell, o$param, o$reps,
                100 * o$truth_below, 100 * o$truth_above, signif(o$p_symmetric, 2)))
writeLines(md, file.path(outdir, sprintf("t2_onesided_%s.md", engine)))
cat(md, sep = "\n")
