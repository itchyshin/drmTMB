# Native R refuses SD formulas on labelled Poisson phylo and labelled NB2 spatial.
# Does it fit them with constant SDs (no sd() formulas)? Poisson phylo does; NB2 spatial does not.
.libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths())); suppressMessages(library(drmTMB))
tree <- ape::read.tree("tree.nwk")
cc <- read.csv("coords.csv"); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
dp <- read.csv("data_phylo.csv"); dp$id <- factor(dp$id)
ds <- read.csv("data_spatial.csv"); ds$id <- factor(ds$id)
r1 <- tryCatch(drmTMB(bf(yp ~ x + phylo(1 + x | p | id, tree = tree)), family = poisson(), data = dp), error = function(e) e)
if (!inherits(r1, "error")) {
  par <- r1$opt$par; se <- sqrt(diag(r1$sdr$cov.fixed))
  write.csv(data.frame(name = names(par), est = unname(par), se = unname(se)), "r_poisson_phylo_const.csv", row.names = FALSE)
  writeLines(sprintf("%.12f", as.numeric(logLik(r1))), "r_poisson_phylo_const_ll.txt")
}
cat("poisson phylo const:", if (inherits(r1, "error")) gsub("\\s+", " ", conditionMessage(r1)) else sprintf("ll=%.8f conv=%d", as.numeric(logLik(r1)), r1$opt$convergence), "\n")
r2 <- tryCatch(drmTMB(bf(yn ~ x + spatial(1 + x | p | id, coords = coords), sigma ~ 1), family = nbinom2(), data = ds), error = function(e) e)
cat("nb2 spatial const:", if (inherits(r2, "error")) gsub("\\s+", " ", conditionMessage(r2)) else sprintf("ll=%.8f conv=%d", as.numeric(logLik(r2)), r2$opt$convergence), "\n")
