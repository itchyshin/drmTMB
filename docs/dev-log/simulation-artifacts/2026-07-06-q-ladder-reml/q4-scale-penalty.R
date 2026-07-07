#!/usr/bin/env Rscript
# Does the full q4 biv phylo location-scale model identify (pdHess=TRUE) as N grows
# toward Ayumi's real scale? baseline vs penalty, across a scale ladder. beak+tarsus
# (the pair that collapsed at N=250). se=TRUE to read pdHess (the identifiability
# verdict). This tells us whether "some pairs didn't run" is a small-N artifact.
suppressPackageStartupMessages({library(drmTMB); library(ape)})
AV <- "/home/snakagaw/drmtmb_work/avonet"
load(file.path(AV,"avonet_traits.rda")); load(file.path(AV,"avonet_tree.rda"))
sp_all <- intersect(rownames(avonet_traits), avonet_tree$tip.label)
Ns <- c(250L, 500L, 1000L)
cat("q4 biv phylo location-scale (beak+tarsus): identify vs scale?\n\n")
for (N in Ns) {
  set.seed(42); sp <- sample(sp_all, N)
  st <- ape::keep.tip(avonet_tree, sp)
  dep <- ape::node.depth.edgelength(st); ntip <- length(st$tip.label)
  td <- dep[seq_len(ntip)]; tgt <- max(td); ends <- st$edge[,2]
  for (i in seq_len(ntip)) { k <- which(ends==i); st$edge.length[k] <- st$edge.length[k] + (tgt-td[i]) }
  if (any(st$edge.length<=0)) st$edge.length[st$edge.length<=0] <- 1e-9
  sp <- st$tip.label
  dat <- data.frame(
    beak   = as.numeric(scale(log(avonet_traits[sp,"beak_length_culmen_mm"]))),
    tarsus = as.numeric(scale(log(avonet_traits[sp,"tarsus_length_mm"]))),
    species = sp, stringsAsFactors=FALSE)
  form <- bf(mu1 = beak   ~ 1 + phylo(1 | p | species, tree = st),
             mu2 = tarsus ~ 1 + phylo(1 | p | species, tree = st),
             sigma1 = ~ 1 + phylo(1 | p | species, tree = st),
             sigma2 = ~ 1 + phylo(1 | p | species, tree = st),
             rho12 = ~ 1)
  for (strat in c("baseline","penalty")) {
    pen <- if (strat=="penalty") drm_phylo_penalty() else NULL
    t0 <- proc.time()[["elapsed"]]
    fit <- tryCatch(suppressWarnings(drmTMB(form, biv_gaussian(), dat, engine="tmb",
             REML=FALSE, penalty=pen, control=drm_control(se=TRUE))), error=function(e) e)
    dt <- round(proc.time()[["elapsed"]]-t0,1)
    if (inherits(fit,"error")) { cat(sprintf("N=%5d %-9s ERROR %s (%.1fs)\n", N, strat, substr(conditionMessage(fit),1,40), dt)); flush(stdout()); next }
    sds <- tryCatch(unlist(fit$sdpars), error=function(e) NA_real_)
    pd <- tryCatch(isTRUE(fit$sdr$pdHess), error=function(e) NA)
    cat(sprintf("N=%5d %-9s conv=%s pd=%-5s minSD=%.4f t=%.1fs\n",
                N, strat, fit$opt$convergence, pd, min(sds,na.rm=TRUE), dt)); flush(stdout())
  }
  cat("\n")
}
cat("Q4-SCALE DONE\n")
