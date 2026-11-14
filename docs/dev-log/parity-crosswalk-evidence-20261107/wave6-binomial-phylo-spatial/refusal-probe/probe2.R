.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); suppressPackageStartupMessages(library(drmTMB))
tree <- ape::read.tree("tree.nwk"); cc <- read.csv("coords.csv"); coords <- as.matrix(cc[,2:3]); rownames(coords) <- cc$id
for (kind in c("phy","sp")) {
 d <- read.csv(if(kind=="phy") "data_phylo.csv" else "data_spatial.csv"); d$id <- factor(d$id)
 lev <- if(kind=="phy") "phylogenetic" else "spatial"
 mu <- as.formula(sprintf("y01 ~ x + %s", if(kind=="phy") "phylo(1 + x | p | id, tree = tree)" else "spatial(1 + x | p | id, coords = coords)")); environment(mu) <- environment()
 f0 <- as.formula(sprintf('sd(id, level = "%s", coef = "(Intercept)") ~ z0', lev)); f1 <- as.formula(sprintf('sd(id, level = "%s", coef = "x") ~ z1', lev))
 fit <- tryCatch(drmTMB(bf(mu,f0,f1), family = binomial(), data = d), error=function(e) e)
 if (inherits(fit,"error")) cat(kind, "labelled ERROR:", conditionMessage(fit), "\n") else {cat(kind,"labelled OK ll", as.numeric(logLik(fit)), "\n"); print(summary(fit)$coefficients[,1:2])}
 # weights / trials=1 cbind
 d$f <- 1-d$y01
 mu2 <- as.formula(sprintf("cbind(y01, f) ~ x + %s", if(kind=="phy") "phylo(1 + x | id, tree = tree)" else "spatial(1 + x | id, coords = coords)")); environment(mu2) <- environment()
 fit <- tryCatch(drmTMB(bf(mu2,f0,f1), family = binomial(), data = d), error=function(e) e)
 if (inherits(fit,"error")) cat(kind, "cbind1 ERROR:", conditionMessage(fit), "\n") else cat(kind,"cbind1 OK ll", as.numeric(logLik(fit)), "\n")
 # intercept-only SD target (q1 slope-free) and one-target
 mu3 <- as.formula(sprintf("y01 ~ x + %s", if(kind=="phy") "phylo(1 | id, tree = tree)" else "spatial(1 | id, coords = coords)")); environment(mu3) <- environment()
 fit <- tryCatch(drmTMB(bf(mu3,f0), family = binomial(), data = d), error=function(e) e)
 if (inherits(fit,"error")) cat(kind, "q1 ERROR:", conditionMessage(fit), "\n") else cat(kind,"q1 OK ll", as.numeric(logLik(fit)), "\n")
}
