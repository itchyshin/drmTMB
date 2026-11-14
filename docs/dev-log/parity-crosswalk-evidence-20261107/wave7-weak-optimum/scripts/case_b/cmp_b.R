rd <- function(f) { x <- readLines(f); strsplit(x, ",")[[1]] }
rows <- list()
for (s in 1:40) for (k in c("phylo","spatial")) {
  r <- rd(sprintf("out/r_%s_%d_ll.txt", k, s)); llR <- suppressWarnings(as.numeric(r[1]))
  jb <- rd(sprintf("out/j_base_%s_%d_ll.txt", k, s)); jf <- rd(sprintf("out/j_fix_%s_%d_ll.txt", k, s))
  rows[[length(rows)+1]] <- data.frame(kind = k, seed = s, ll_R = llR, R_pd = r[3], base = as.numeric(jb[1]), base_conv = jb[2], fix = as.numeric(jf[1]), fix_conv = jf[2],
     t_base = as.numeric(jb[3]), t_fix = as.numeric(jf[3]))
}
d <- do.call(rbind, rows); d$base_minus_R <- d$base - d$ll_R; d$fix_minus_R <- d$fix - d$ll_R; d$fix_minus_base <- d$fix - d$base
write.csv(d, "summary_b.csv", row.names = FALSE)
cat("datasets:", nrow(d), " R failed:", sum(is.na(d$ll_R)), "\n")
cat("bit-identical base vs fix:", sum(d$base == d$fix, na.rm=TRUE), " differ:", sum(d$base != d$fix, na.rm=TRUE), "\n")
cat("base worse than R by >1e-3:", sum(d$base_minus_R < -1e-3, na.rm=TRUE), "; >1e-6:", sum(d$base_minus_R < -1e-6, na.rm=TRUE), "\n")
cat("fix  worse than R by >1e-3:", sum(d$fix_minus_R < -1e-3, na.rm=TRUE), "; >1e-6:", sum(d$fix_minus_R < -1e-6, na.rm=TRUE), "\n")
cat("base conv false:", sum(d$base_conv != "true"), " fix conv false:", sum(d$fix_conv != "true"), "\n")
cat("Julia better than R by >1e-6 (base/fix):", sum(d$base_minus_R > 1e-6, na.rm=TRUE), sum(d$fix_minus_R > 1e-6, na.rm=TRUE), "\n")
print(d[(abs(d$base_minus_R) > 1e-6 | abs(d$fix_minus_R) > 1e-6 | d$base != d$fix | d$base_conv != "true" | d$fix_conv != "true") %in% TRUE, c("kind","seed","ll_R","base","fix","base_minus_R","fix_minus_R","base_conv","fix_conv")], digits = 10)
cat("time base", sum(d$t_base), " fix", sum(d$t_fix), "\n")
