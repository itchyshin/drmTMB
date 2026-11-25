# drmTMB 0.8.1 ML fits for the weak-probe family. usage: DRMTMB_LIB=<lib> Rscript r_fit.R <seed_from> <seed_to>
.libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths())); suppressPackageStartupMessages({library(drmTMB); library(ape)})
args <- as.integer(commandArgs(TRUE)); tree <- read.tree("tree.nwk"); cc <- read.csv("coords.csv"); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
for (s in args[1]:args[2]) for (kind in c("phylo", "spatial")) {
  d <- read.csv(file.path("data", sprintf("%s_%d.csv", kind, s))); d$id <- factor(d$id, levels = unique(d$id))
  lev <- if (kind == "phylo") "phylogenetic" else "spatial"
  mu <- if (kind == "phylo") y ~ x + phylo(1 + x | id, tree = tree) else y ~ x + spatial(1 + x | id, coords = coords)
  f0 <- as.formula(sprintf('sd(id, level = "%s", coef = "(Intercept)") ~ z0', lev)); f1 <- as.formula(sprintf('sd(id, level = "%s", coef = "x") ~ z1', lev))
  fm <- bf(mu, f0, f1)
  t0 <- Sys.time()
  fit <- tryCatch(drmTMB(fm, family = binomial(), data = d), error = function(e) e)
  tag <- sprintf("%s_%d", kind, s)
  if (inherits(fit, "error")) { writeLines(paste0("NA,error,", gsub(",", ";", conditionMessage(fit))), file.path("out", paste0("r_", tag, "_ll.txt"))); next }
  est <- summary(fit)$coefficients
  write.csv(data.frame(term = rownames(est), est = est[, 1], se = est[, 2]), file.path("out", paste0("r_", tag, ".csv")), row.names = FALSE)
  writeLines(sprintf("%.10f,%s,%s", as.numeric(logLik(fit)), fit$opt$convergence, isTRUE(fit$sdr$pdHess)), file.path("out", paste0("r_", tag, "_ll.txt")))
}
