E <- Sys.getenv("E"); ps <- read.csv(file.path(E, "per_seed.csv")); ps <- ps[ps$route == "nb2_phylo", c("seed","ll_julia","ll_R")]
b <- read.csv("nb2_base_mac.csv", header = FALSE, col.names = c("seed","ll_base","conv_base","t_base"))
f <- read.csv("nb2_fix_mac.csv", header = FALSE, col.names = c("seed","ll_fix","conv_fix","t_fix"))
w <- merge(merge(b, f, by = "seed"), ps, by = "seed")
cat("seeds:", nrow(w), "\n")
cat("bit-identical ll (base vs fix):", sum(w$ll_base == w$ll_fix), " differ:", sum(w$ll_base != w$ll_fix), "\n")
d <- w[w$ll_base != w$ll_fix, ]; d$delta <- d$ll_fix - d$ll_base; d$fix_minus_R <- d$ll_fix - d$ll_R; d$base_minus_R <- d$ll_base - d$ll_R
print(d[, c("seed","ll_base","ll_fix","delta","ll_R","base_minus_R","fix_minus_R","conv_base","conv_fix")], digits = 12)
cat("base Mac vs campaign Totoro Julia ll: max abs", max(abs(w$ll_base - w$ll_julia)), " (seeds >1e-6:", paste(w$seed[abs(w$ll_base - w$ll_julia) > 1e-6], collapse=","), ")\n")
cat("conv base:", sum(w$conv_base), " conv fix:", sum(w$conv_fix), "\n")
cat("max |fix - R| over all seeds:", max(abs(w$ll_fix - w$ll_R)), " seeds >1e-6:", paste(w$seed[abs(w$ll_fix - w$ll_R) > 1e-6], collapse=","), "\n")
cat("max |base - R| over all seeds:", max(abs(w$ll_base - w$ll_R)), " seeds >1e-6:", paste(w$seed[abs(w$ll_base - w$ll_R) > 1e-6], collapse=","), "\n")
cat("time base total", sum(w$t_base), " fix total", sum(w$t_fix), "\n")
