# R's TMB objective evaluated at Julia's estimate (same likelihood function), then re-optimised from there.
.libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths())); suppressPackageStartupMessages({library(drmTMB); library(ape)})
args <- commandArgs(TRUE); tag <- args[1]; kind <- args[2]; s <- as.integer(args[3])   # tag of the Julia file, e.g. fix2
tree <- read.tree("tree.nwk"); cc <- read.csv("coords.csv"); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
d <- read.csv(file.path("data", sprintf("%s_%d.csv", kind, s))); d$id <- factor(d$id, levels = unique(d$id))
lev <- if (kind == "phylo") "phylogenetic" else "spatial"
mu <- if (kind == "phylo") y ~ x + phylo(1 + x | id, tree = tree) else y ~ x + spatial(1 + x | id, coords = coords)
f0 <- as.formula(sprintf('sd(id, level = "%s", coef = "(Intercept)") ~ z0', lev)); f1 <- as.formula(sprintf('sd(id, level = "%s", coef = "x") ~ z1', lev))
fit <- drmTMB(bf(mu, f0, f1), family = binomial(), data = d); obj <- fit$obj; pr <- fit$opt$par
jv <- read.csv(sprintf("out/j_%s_%s_%d.csv", tag, kind, s)); jp <- jv$est
cat(sprintf("%s %d: R default ll %.8f | R objective at Julia estimate (%s) ll %.8f | R grad max at Julia est %.3e\n", kind, s, -obj$fn(pr), tag, -obj$fn(jp), max(abs(obj$gr(jp)))))
o <- nlminb(jp, obj$fn, obj$gr, control = list(iter.max = 1000, eval.max = 2000))
cat(sprintf("   R polish from Julia estimate: ll %.8f, max par move %.3e, conv %d\n", -o$objective, max(abs(o$par - jp)), o$convergence))
