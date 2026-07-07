#!/usr/bin/env Rscript
# q-ladder convergence experiment: for each phylo location-scale rung (q1, q2, q4)
# under ML, which rescue strategy (baseline / robust optimizer / multi-start /
# penalty-MAP) makes it converge with pdHess=TRUE and no boundary collapse?
# Fast AVONET subtree so we can iterate. (q3 added once q2 is understood.)
suppressPackageStartupMessages({library(drmTMB); library(ape)})
e <- new.env()
load("/Users/z3437171/Dropbox/Github Local/BACE/dev/testing_data/data/avonet_traits.rda", envir=e)
load("/Users/z3437171/Dropbox/Github Local/BACE/dev/testing_data/data/avonet_tree.rda", envir=e)
tr <- e$avonet_traits; ph <- e$avonet_tree
sp <- intersect(rownames(tr), ph$tip.label)
set.seed(1); sp <- sample(sp, 250)
st <- ape::keep.tip(ph, sp)
dep <- ape::node.depth.edgelength(st); ntip <- length(st$tip.label)
td <- dep[seq_len(ntip)]; tgt <- max(td); ends <- st$edge[,2]
for (i in seq_len(ntip)) { k <- which(ends==i); st$edge.length[k] <- st$edge.length[k] + (tgt-td[i]) }
if (any(st$edge.length<=0)) st$edge.length[st$edge.length<=0] <- 1e-9
sp <- st$tip.label
dat <- data.frame(
  beak   = as.numeric(scale(log(tr[sp,"beak_length_culmen_mm"]))),
  tarsus = as.numeric(scale(log(tr[sp,"tarsus_length_mm"]))),
  species = sp, stringsAsFactors=FALSE)

mk <- list(
  q1 = function() bf(beak ~ 1, sigma ~ 1 + phylo(1 | species, tree = st)),
  q2 = function() bf(beak ~ 1 + phylo(1 | p | species, tree = st),
                     sigma ~ 1 + phylo(1 | p | species, tree = st)),
  q4 = function() bf(mu1 = beak   ~ 1 + phylo(1 | p | species, tree = st),
                     mu2 = tarsus ~ 1 + phylo(1 | p | species, tree = st),
                     sigma1 = ~ 1 + phylo(1 | p | species, tree = st),
                     sigma2 = ~ 1 + phylo(1 | p | species, tree = st),
                     rho12 = ~ 1))
fam <- list(q1=gaussian(), q2=gaussian(), q4=biv_gaussian())

summ <- function(fit) {
  if (inherits(fit, "error"))
    return(sprintf("ERROR: %s", substr(conditionMessage(fit), 1, 45)))
  sds <- tryCatch(unlist(fit$sdpars), error=function(e) NA_real_)
  pd  <- tryCatch(isTRUE(fit$sdr$pdHess), error=function(e) NA)
  nzero <- sum(sds < 1e-4, na.rm=TRUE)
  sprintf("conv=%s pd=%-5s minSD=%.4f nZero=%d obj=%.2f",
          fit$opt$convergence, pd, min(sds, na.rm=TRUE), nzero,
          tryCatch(fit$opt$objective, error=function(e) NA_real_))
}
run <- function(form, family, strat) {
  ctrl <- switch(strat,
    baseline   = drm_control(se=TRUE),
    robust     = drm_control(se=TRUE, optimizer_preset="robust"),
    multistart = drm_control(se=TRUE, multi_start=5L),
    penalty    = drm_control(se=TRUE))
  pen <- if (strat=="penalty") drm_phylo_penalty() else NULL
  tryCatch(drmTMB(form, family, dat, engine="tmb", REML=FALSE, penalty=pen, control=ctrl),
           error=function(e) e)
}
cat(sprintf("q-ladder convergence, ML, AVONET N=%d (beak/tarsus)\n\n", length(sp)))
for (q in c("q1","q2","q4")) {
  form <- mk[[q]]()
  for (strat in c("baseline","robust","multistart","penalty")) {
    t0 <- proc.time()[["elapsed"]]
    fit <- suppressWarnings(run(form, fam[[q]], strat))
    dt <- round(proc.time()[["elapsed"]]-t0,1)
    cat(sprintf("%s %-11s %s  t=%ss\n", q, strat, summ(fit), dt)); flush(stdout())
  }
  cat("\n")
}
cat("Q-LADDER DONE\n")
