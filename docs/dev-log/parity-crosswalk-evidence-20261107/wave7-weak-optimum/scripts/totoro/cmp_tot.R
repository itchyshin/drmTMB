E <- Sys.getenv("E"); ps <- read.csv(file.path(E, "per_seed.csv")); ps <- ps[ps$route %in% c("nb2_phylo","nb2_animal","nb2_relmat"), c("route","seed","ll_julia","ll_R","julia_converged")]
rd <- function(v, r, s) { f <- sprintf("%s/%s_s%03d_ll.csv", v, r, s); x <- readLines(f)[2]; p <- strsplit(x, ",")[[1]]; list(ll = p[1], conv = p[2]) }
rows <- lapply(seq_len(nrow(ps)), function(i) { r <- ps$route[i]; s <- ps$seed[i]; b <- rd("base", r, s); f <- rd("fix", r, s)
  data.frame(route = r, seed = s, ll_base = b$ll, ll_fix = f$ll, conv_base = b$conv, conv_fix = f$conv) })
d <- do.call(rbind, rows); d <- merge(d, ps, by = c("route","seed"))
d$identical <- d$ll_base == d$ll_fix
d$ll_base_n <- as.numeric(d$ll_base); d$ll_fix_n <- as.numeric(d$ll_fix)
cat("Totoro Julia 1.10.12, base (origin tip 759e58e4f) vs fix (this branch):\n")
for (r in unique(d$route)) { x <- d[d$route == r, ]; cat(sprintf("%-11s seeds %3d  bit-identical ll (string equal) %3d  differ %d  conv_base false %d conv_fix false %d\n", r, nrow(x), sum(x$identical), sum(!x$identical), sum(x$conv_base != "true"), sum(x$conv_fix != "true"))) }
cat("base vs campaign Julia ll (e5ae24539 tip) max abs diff:", max(abs(d$ll_base_n - d$ll_julia)), "\n")
x <- d[!d$identical, ]; x$delta <- x$ll_fix_n - x$ll_base_n; x$base_minus_R <- x$ll_base_n - x$ll_R; x$fix_minus_R <- x$ll_fix_n - x$ll_R
print(x[, c("route","seed","ll_base_n","ll_fix_n","delta","ll_R","base_minus_R","fix_minus_R","conv_base","conv_fix")], digits = 12)
d$bR <- d$ll_base_n - d$ll_R; d$fR <- d$ll_fix_n - d$ll_R
cat("seeds with |base - R| > 1e-6:", paste(d$route[abs(d$bR) > 1e-6], d$seed[abs(d$bR) > 1e-6], collapse = "; "), "\n")
cat("seeds with |fix  - R| > 1e-6:", paste(d$route[abs(d$fR) > 1e-6], d$seed[abs(d$fR) > 1e-6], collapse = "; "), "\n")
write.csv(d[, c("route","seed","ll_base","ll_fix","identical","conv_base","conv_fix","ll_R","bR","fR")], "totoro_base_vs_fix.csv", row.names = FALSE)
