# Post-hoc check of small-sample Wald recipes on the stored t2 fits.
#
# Usage: Rscript t2_posthoc_t.R <outdir> <engine> <resultsdir> [<resultsdir> ...]
# For every random-effect cell with n >= 200, recompute 95% coverage of the
# mean intercept and of sd(g) from the stored link-scale estimates and SEs
# under three recipes:
#   z           estimate +/- qnorm(.975) * se             (what both engines report)
#   t(G-1)      estimate +/- qt(.975, G - 1) * se
#   t(G-1)+bc   for sd(g) only: log-scale centre shifted by log(G / (G - 1)),
#               the recipe drmTMB applies to structured SDs (R/profile.R)
# Writes <outdir>/t2_posthoc_t_<engine>.csv and .md.

args <- commandArgs(trailingOnly = TRUE)
outdir <- args[[1]]
engine <- args[[2]]
dirs <- args[-(1:2)]
files <- unlist(lapply(dirs, list.files,
  pattern = sprintf("^%s_n(0200|1000)_G", engine), full.names = TRUE))
d <- do.call(rbind, lapply(files, function(f) {
  x <- utils::read.csv(f, na.strings = c("NA", "", "NaN"), stringsAsFactors = FALSE)
  x$converged <- as.logical(x$converged)
  x[x$converged %in% TRUE & x$param %in% c("mu_intercept", "sd_g"),
    c("cell", "G", "rep", "param", "est_link", "se_link")]
}))
stopifnot(!anyDuplicated(d[, c("cell", "rep", "param")]))
out <- do.call(rbind, lapply(split(d, list(d$cell, d$param), drop = TRUE), function(x) {
  G <- x$G[1]
  sd_row <- x$param[1] == "sd_g"
  th <- if (sd_row) log(0.5) else 1
  e <- x$est_link
  s <- x$se_link
  zq <- stats::qnorm(0.975)
  tq <- stats::qt(0.975, G - 1)
  shift <- if (sd_row) log(G / (G - 1)) else 0
  cover <- function(lo, hi) mean(lo <= th & th <= hi)
  m <- nrow(x)
  data.frame(cell = x$cell[1], G = G, param = x$param[1], reps = m,
             z = cover(e - zq * s, e + zq * s),
             t_Gm1 = cover(e - tq * s, e + tq * s),
             t_Gm1_shift = if (sd_row) cover(e + shift - tq * s, e + shift + tq * s) else NA_real_,
             mcse_at_95 = sqrt(0.95 * 0.05 / m))
}))
out <- out[order(out$param, out$G, out$cell), ]
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(out, file.path(outdir, sprintf("t2_posthoc_t_%s.csv", engine)), row.names = FALSE)
pc <- function(v) ifelse(is.na(v), "-", sprintf("%.2f%%", 100 * v))
md <- c(sprintf("Engine: %s; reps per cell pooled over all supplied result directories.", engine), "",
        "| cell | target | reps | z (reported) | t(G-1) | t(G-1) + log(G/(G-1)) shift |",
        "|---|---|---:|---:|---:|---:|",
        sprintf("| %s | %s | %d | %s | %s | %s |", out$cell, out$param, out$reps,
                pc(out$z), pc(out$t_Gm1), pc(out$t_Gm1_shift)))
writeLines(md, file.path(outdir, sprintf("t2_posthoc_t_%s.md", engine)))
cat(md, sep = "\n")
