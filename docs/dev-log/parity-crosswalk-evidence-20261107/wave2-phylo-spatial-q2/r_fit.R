# Native R drmTMB fits for the wave-2 phylo/spatial q2 shapes.
# Usage: Rscript r_fit.R <case>  with case in gphy, pphy, nphy, gsp, psp, nsp
args <- commandArgs(TRUE); case <- args[1]
O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/w2ps"
.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths()))
suppressPackageStartupMessages(library(drmTMB))
kind <- substr(case, 2, 4); fam <- substr(case, 1, 1)
d <- read.csv(file.path(O, if (kind == "phy") "data_phylo.csv" else "data_spatial.csv"))
tree <- ape::read.tree(file.path(O, "tree.nwk"))
cc <- read.csv(file.path(O, "coords.csv")); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
d$id <- factor(d$id)
d$y <- switch(fam, g = d$yg, p = d$yp, n = d$yn)
lev <- if (kind == "phy") "phylogenetic" else "spatial"
mu <- if (kind == "phy") y ~ x + phylo(1 + x | id, tree = tree) else y ~ x + spatial(1 + x | id, coords = coords)
environment(mu) <- environment()
f0 <- as.formula(sprintf('sd(id, level = "%s", coef = "(Intercept)") ~ z0', lev))
f1 <- as.formula(sprintf('sd(id, level = "%s", coef = "x") ~ z1', lev))
family <- switch(fam, g = gaussian(), p = poisson(), n = nbinom2())
fm <- if (fam == "p") bf(mu, f0, f1) else bf(mu, sigma ~ 1, f0, f1)
t0 <- Sys.time()
fit <- tryCatch(drmTMB(fm, family = family, data = d), error = function(e) e)
if (inherits(fit, "error")) { cat("R ERROR:", conditionMessage(fit), "\n"); quit(status = 0) }
cat("time", format(Sys.time() - t0), "\n")
cat(sprintf("logLik %.10f conv %s\n", as.numeric(logLik(fit)), fit$opt$convergence))
ct <- summary(fit)$coefficients
print(ct)
write.csv(ct, file.path(O, paste0("r_", case, ".csv")), row.names = TRUE)
writeLines(sprintf("%.12f", as.numeric(logLik(fit))), file.path(O, paste0("r_", case, "_ll.txt")))
