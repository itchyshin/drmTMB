.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); suppressPackageStartupMessages(library(drmTMB))
setwd("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/binom-probe")
tree <- ape::read.tree("tree.nwk"); cc <- read.csv("coords.csv"); coords <- as.matrix(cc[,2:3]); rownames(coords) <- cc$id
for (kind in c("phy","sp")) {
 d <- read.csv(if(kind=="phy") "data_phylo.csv" else "data_spatial.csv"); d$id <- factor(d$id); d$fail <- d$trials-d$k
 lev <- if(kind=="phy") "phylogenetic" else "spatial"
 XX {
  resp <- if(shape=="01") "y01" else "cbind(k, fail)"
  mu <- as.formula(sprintf("%s ~ x + %s", resp, if(kind=="phy") "phylo(1 + x | id, tree = tree)" else "spatial(1 + x | id, coords = coords)"))
  environment(mu) <- environment()
  f0 <- as.formula(sprintf('sd(id, level = "%s", coef = "(Intercept)") ~ z0', lev)); f1 <- as.formula(sprintf('sd(id, level = "%s", coef = "x") ~ z1', lev))
  fm <- bf(mu, f0, f1)
  t0 <- Sys.time()
  fit <- tryCatch(drmTMB(fm, family = binomial(link=lk), data = d), error=function(e) e)
  if (inherits(fit,"error")) cat(kind, shape, lk, "ERROR:", conditionMessage(fit), "\n")
  else { cat(kind, shape, lk, sprintf("OK ll %.6f conv %s time %.1fs\n", as.numeric(logLik(fit)), fit$opt$convergence, as.numeric(Sys.time()-t0, units="secs"))); print(summary(fit)$coefficients[,1:2]) }
 }
}
