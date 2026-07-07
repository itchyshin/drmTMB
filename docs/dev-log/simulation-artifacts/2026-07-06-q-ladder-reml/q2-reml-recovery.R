#!/usr/bin/env Rscript
# q2 REML recovery arbiter: simulate univariate matched mean-and-scale phylo data
# (2x2 cross-axis block, known sd_mu / sd_sigma / rho), fit ML vs REML, check that
# REML reduces the downward bias in the scale-side phylo SD without breaking.
# Uses devtools::load_all() so it exercises the RELAXED q2 gate on this branch.
suppressPackageStartupMessages({library(ape); library(MASS)})
devtools::load_all("/Users/z3437171/Dropbox/Github Local/drmTMB", quiet=TRUE)

e <- new.env()
load("/Users/z3437171/Dropbox/Github Local/BACE/dev/testing_data/data/avonet_tree.rda", envir=e)
ph <- e$avonet_tree
set.seed(7); sp <- sample(ph$tip.label, 120)
st <- ape::keep.tip(ph, sp)
dep <- ape::node.depth.edgelength(st); ntip <- length(st$tip.label)
td <- dep[seq_len(ntip)]; tgt <- max(td); ends <- st$edge[,2]
for (i in seq_len(ntip)) { k <- which(ends==i); st$edge.length[k] <- st$edge.length[k] + (tgt-td[i]) }
if (any(st$edge.length<=0)) st$edge.length[st$edge.length<=0] <- 1e-9

A  <- ape::vcv(st, corr=TRUE)          # N x N phylo correlation
LA <- chol(A)                          # LA' LA = A
sd_mu <- 0.6; sd_sigma <- 0.4; rho <- 0.4
Sig <- matrix(c(sd_mu^2, rho*sd_mu*sd_sigma, rho*sd_mu*sd_sigma, sd_sigma^2), 2)
LS <- chol(Sig)
b_mu <- 0; b_sig <- log(0.6)
form <- bf(y ~ 1 + phylo(1 | p | species, tree = st),
           sigma ~ 1 + phylo(1 | p | species, tree = st))

sim_one <- function(seed) {
  set.seed(seed)
  Z <- matrix(rnorm(2*ntip), ntip, 2)
  U <- t(LA) %*% Z %*% LS               # N x 2: row = (u_mu, u_sigma)
  mu <- b_mu + U[,1]; ls <- b_sig + U[,2]
  data.frame(y = rnorm(ntip, mu, exp(ls)), species = st$tip.label,
             stringsAsFactors = FALSE)
}
fit_sd <- function(dat, reml) {
  f <- tryCatch(drmTMB(form, gaussian(), dat, engine="tmb", REML=reml,
                       control=drm_control(se=FALSE)),
                error=function(e) e)
  if (inherits(f, "error")) return(c(sd_mu=NA, sd_sigma=NA, err=conditionMessage(f)))
  c(sd_mu=unname(f$sdpars$mu[[1]]), sd_sigma=unname(f$sdpars$sigma[[1]]), err="")
}

cat("verify q2 REML fits with the relaxed gate ...\n")
v <- fit_sd(sim_one(1), TRUE)
cat(sprintf("  single q2 REML: sd_mu=%s sd_sigma=%s %s\n",
            round(as.numeric(v[1]),3), round(as.numeric(v[2]),3), v[3]))
if (is.na(as.numeric(v[1]))) { cat("GATE STILL REJECTS / fit failed -> abort\n"); quit(status=0) }

R <- 30
ml <- reml <- matrix(NA_real_, R, 2, dimnames=list(NULL, c("sd_mu","sd_sigma")))
for (r in 1:R) {
  d <- sim_one(100+r)
  ml[r,]   <- as.numeric(fit_sd(d, FALSE)[1:2])
  reml[r,] <- as.numeric(fit_sd(d, TRUE)[1:2])
  if (r %% 10 == 0) { cat("  rep", r, "done\n"); flush(stdout()) }
}
bias <- function(x, t) mean(x, na.rm=TRUE) - t
cat(sprintf("\nq2 RECOVERY  (truth sd_mu=%.2f sd_sigma=%.2f rho=%.2f)  N=%d R=%d\n",
            sd_mu, sd_sigma, rho, ntip, R))
cat(sprintf("  sd_mu    : ML %.3f (bias %+.3f) | REML %.3f (bias %+.3f)\n",
            mean(ml[,1],na.rm=T), bias(ml[,1],sd_mu), mean(reml[,1],na.rm=T), bias(reml[,1],sd_mu)))
cat(sprintf("  sd_sigma : ML %.3f (bias %+.3f) | REML %.3f (bias %+.3f)\n",
            mean(ml[,2],na.rm=T), bias(ml[,2],sd_sigma), mean(reml[,2],na.rm=T), bias(reml[,2],sd_sigma)))
cat(sprintf("  finite   : ML %d/%d | REML %d/%d\n",
            sum(!is.na(ml[,2])), R, sum(!is.na(reml[,2])), R))
cat("Q2 RECOVERY DONE\n")
