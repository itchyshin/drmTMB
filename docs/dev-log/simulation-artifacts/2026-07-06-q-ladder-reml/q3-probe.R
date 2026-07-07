suppressPackageStartupMessages({library(drmTMB); library(ape)})
e <- new.env()
load("/Users/z3437171/Dropbox/Github Local/BACE/dev/testing_data/data/avonet_traits.rda", envir=e)
load("/Users/z3437171/Dropbox/Github Local/BACE/dev/testing_data/data/avonet_tree.rda", envir=e)
tr <- e$avonet_traits; ph <- e$avonet_tree
sp <- intersect(rownames(tr), ph$tip.label)
set.seed(1); sp <- sample(sp, 250)          # SAME subtree as the q-ladder q4 (pd=FALSE)
st <- ape::keep.tip(ph, sp)
dep <- ape::node.depth.edgelength(st); ntip <- length(st$tip.label)
td <- dep[seq_len(ntip)]; tgt <- max(td); ends <- st$edge[,2]
for (i in seq_len(ntip)) { k <- which(ends==i); st$edge.length[k] <- st$edge.length[k] + (tgt-td[i]) }
if (any(st$edge.length<=0)) st$edge.length[st$edge.length<=0] <- 1e-9
sp <- st$tip.label
dat <- data.frame(beak=as.numeric(scale(log(tr[sp,"beak_length_culmen_mm"]))),
                  tarsus=as.numeric(scale(log(tr[sp,"tarsus_length_mm"]))),
                  species=sp, stringsAsFactors=FALSE)
report <- function(tag, form) {
  fit <- tryCatch(suppressWarnings(drmTMB(form, biv_gaussian(), dat, engine="tmb",
           REML=FALSE, control=drm_control(se=TRUE))), error=function(e) e)
  if (inherits(fit,"error")) { cat(sprintf("%-6s ERROR: %s\n", tag, substr(conditionMessage(fit),1,55))); return(invisible()) }
  sds <- unlist(fit$sdpars); pd <- tryCatch(isTRUE(fit$sdr$pdHess), error=function(e) NA)
  cat(sprintf("%-6s conv=%s pd=%-5s minSD=%.4f\n", tag, fit$opt$convergence, pd, min(sds,na.rm=TRUE)))
}
# q3a: means correlated (|p|), scale-side phylo present but INDEPENDENT (no |p|)
report("q3a", bf(mu1=beak~1+phylo(1|p|species,tree=st), mu2=tarsus~1+phylo(1|p|species,tree=st),
                 sigma1=~1+phylo(1|species,tree=st), sigma2=~1+phylo(1|species,tree=st), rho12=~1))
# q3b: means correlated (|p|), sigmas FIXED (no scale phylo) -- convergence baseline
report("q3b", bf(mu1=beak~1+phylo(1|p|species,tree=st), mu2=tarsus~1+phylo(1|p|species,tree=st),
                 sigma1=~1, sigma2=~1, rho12=~1))
cat("Q3 PROBE DONE\n")
