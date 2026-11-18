# Compare the primary sweep (reps 1-500) with the confirmatory replicate
# (reps 501-2500, same seed scheme) for every gate cell (n >= 200), per engine.
#
# Usage: Rscript t2_compare.R <primary_summary_dir> <confirm_summary_dir> <outdir>
# Reads t2_summary.csv from both summary directories (written by t2_analyse.R)
# and writes <outdir>/t2_confirm_compare.csv plus <outdir>/t2_confirm_tables.md.

args <- commandArgs(trailingOnly = TRUE)
p <- utils::read.csv(file.path(args[[1]], "t2_summary.csv"), stringsAsFactors = FALSE)
q <- utils::read.csv(file.path(args[[2]], "t2_summary.csv"), stringsAsFactors = FALSE)
outdir <- args[[3]]
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
p <- p[p$n >= 200, ]
key <- c("engine", "cell", "param")
m <- merge(p, q, by = key, suffixes = c(".p", ".c"))
# Pooled estimates: weight each run by its number of converged fits.
w1 <- m$n_conv.p
w2 <- m$n_conv.c
m$rel_bias.pool <- (w1 * m$rel_bias.p + w2 * m$rel_bias.c) / (w1 + w2)
m$coverage.pool <- (m$n_ci.p * m$coverage.p + m$n_ci.c * m$coverage.c) / (m$n_ci.p + m$n_ci.c)
m$coverage_mcse.pool <- sqrt(m$coverage.pool * (1 - m$coverage.pool) / (m$n_ci.p + m$n_ci.c))
m$rel_bias_mcse.pool <- sqrt((w1^2 * m$rel_bias_mcse.p^2 + w2^2 * m$rel_bias_mcse.c^2)) / (w1 + w2)
m$primary_bias <- ifelse(abs(m$rel_bias.p) < 0.05, "PASS", "FAIL")
m$primary_cov <- ifelse(m$coverage.p >= 0.93 & m$coverage.p <= 0.97, "PASS", "FAIL")
m$pooled_bias <- ifelse(abs(m$rel_bias.pool) < 0.05, "PASS", "FAIL")
m$pooled_cov <- ifelse(m$coverage.pool >= 0.93 & m$coverage.pool <= 0.97, "PASS", "FAIL")
m <- m[order(m$engine, m$cell_order.p, match(m$param, c("mu_intercept", "mu_x",
                                                         "sigma_intercept", "sigma_z", "sd_g"))), ]
utils::write.csv(m[, c(key, "n_conv.p", "n_conv.c", "rel_bias.p", "rel_bias.c", "rel_bias.pool",
                       "rel_bias_mcse.pool", "coverage.p", "coverage.c", "coverage.pool",
                       "coverage_mcse.pool", "se_ratio.p", "se_ratio.c", "primary_bias",
                       "primary_cov", "pooled_bias", "pooled_cov")],
                 file.path(outdir, "t2_confirm_compare.csv"), row.names = FALSE)
f <- function(x) sprintf("%+.2f%%", 100 * x)
g <- function(x) sprintf("%.1f%%", 100 * x)
md <- c("| engine | cell | parameter | rel. bias 1-500 | rel. bias 501-2500 | pooled (MCSE) | coverage 1-500 | coverage 501-2500 | pooled (MCSE) | verdict 500 reps -> pooled 2500 |",
        "|---|---|---|---:|---:|---:|---:|---:|---:|---|")
for (i in seq_len(nrow(m))) {
  r <- m[i, ]
  flag <- function(a, b) if (identical(a, b)) a else paste0("**", a, " -> ", b, "**")
  md <- c(md, sprintf("| %s | %s | %s | %s | %s | %s (%.2f) | %s | %s | %s (%.2f) | bias %s; coverage %s |",
                      r$engine, r$cell, r$param, f(r$rel_bias.p), f(r$rel_bias.c),
                      f(r$rel_bias.pool), 100 * r$rel_bias_mcse.pool, g(r$coverage.p),
                      g(r$coverage.c), sprintf("%.2f%%", 100 * r$coverage.pool),
                      100 * r$coverage_mcse.pool, flag(r$primary_bias, r$pooled_bias),
                      flag(r$primary_cov, r$pooled_cov)))
}
writeLines(md, file.path(outdir, "t2_confirm_tables.md"))
message("wrote ", outdir)
