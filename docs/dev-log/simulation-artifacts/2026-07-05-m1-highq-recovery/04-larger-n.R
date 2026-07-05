# M1 recovery — LARGER-n + param + iterations (does pdHess flip at Santi-scale?).
# Streaming (append+flush per fit). Separates data-size from convergence:
#  - push n to 512 / 1024 (Santi-scale groups),
#  - raise iter cap to rule out iteration-limit conv=1,
#  - compare param 0 (UNSTRUCTURED_CORR) vs param 1 (partial-corr Cholesky).
suppressMessages(devtools::load_all("."))
art <- "docs/dev-log/simulation-artifacts/2026-07-05-m1-highq-recovery"
source(file.path(art, "00-helpers.R"))
tsv <- file.path(art, "04-larger-n-results.tsv")
log <- file.path(art, "04-larger-n.log")
hb <- function(...) { cat(sprintf(...), file = log, append = TRUE); cat(sprintf(...)) }
cols <- c("block","param","n_tip","n_each","n_obs","q","seed","conv","pdHess",
          "se_finite","max_abs_rho_hat","cap_saturated","rmse","frobenius","elapsed_s","error")
cat(paste(cols, collapse="\t"), "\n", file = tsv)
cat(sprintf("start %s\n", format(Sys.time())), file = log)
CTRL <- list(eval.max = 8000, iter.max = 8000)

fit_it <- function(block, dat, tree) {
  f4 <- bf(mu1=y1~x+phylo(1|p|species,tree=tree), mu2=y2~x+phylo(1|p|species,tree=tree),
           sigma1=~z+phylo(1|p|species,tree=tree), sigma2=~z+phylo(1|p|species,tree=tree), rho12=~1)
  f8 <- bf(mu1=y1~x+phylo(1+x|p|species,tree=tree), mu2=y2~x+phylo(1+x|p|species,tree=tree),
           sigma1=~z+phylo(1+x|p|species,tree=tree), sigma2=~z+phylo(1+x|p|species,tree=tree), rho12=~1)
  suppressWarnings(drmTMB(if (block=="q4") f4 else f8, family=biv_gaussian(), data=dat, control=CTRL))
}
do_one <- function(block, param, n_tip, n_each, seed) {
  q <- if (block=="q4") 4L else 8L
  old <- options(drmTMB.internal.qgt2_corr_parameterization = param)
  on.exit(options(old), add = TRUE)
  sim <- if (block=="q4") simulate_q4_all_four(seed,n_tip,n_each) else simulate_q8_all_four_one_slope(seed,n_tip,n_each)
  t0 <- Sys.time()
  fit <- tryCatch(fit_it(block, sim$data, sim$tree), error=function(e) e)
  el <- as.numeric(difftime(Sys.time(), t0, units="secs"))
  if (inherits(fit,"error")) {
    row <- c(block,param,n_tip,n_each,nrow(sim$data),q,seed,NA,NA,NA,NA,NA,NA,NA,round(el,1),gsub("\t"," ",conditionMessage(fit)))
    hb("[%s p%d] n_tip=%4d ERROR %s (%.1fs)\n", block, param, n_tip, conditionMessage(fit), el)
  } else {
    rho_hat <- unname(fit$corpars$phylo); rho_true <- unname(upper_tri_vec(sim$truth$corr))
    m <- recovery_metrics(rho_hat, rho_true); fro <- frobenius_corr(corr_from_upper(rho_hat,q), sim$truth$corr)
    se <- suppressWarnings(sqrt(diag(fit$sdr$cov.fixed)))
    row <- c(block,param,n_tip,n_each,nrow(sim$data),q,seed,fit$opt$convergence,isTRUE(fit$sdr$pdHess),
             all(is.finite(se)),round(m$max_abs_rho_hat,4),m$cap_saturated,round(m$rmse,4),round(fro,4),round(el,1),NA)
    hb("[%s p%d] n_tip=%4d conv=%s pdHess=%s max|rho|=%.3f rmse=%.3f frob=%.3f (%.1fs)\n",
       block, param, n_tip, fit$opt$convergence, isTRUE(fit$sdr$pdHess), m$max_abs_rho_hat, m$rmse, fro, el)
  }
  cat(paste(row, collapse="\t"), "\n", file = tsv, append = TRUE); flush(stdout())
}
# Fast-first: q4 at scale (cheap) confirms the anchor recovers with enough groups.
do_one("q4", 0L, 512L, 6L, 20260801L)
do_one("q4", 0L, 1024L, 4L, 20260801L)
# q8 at Santi-scale, param 0 then param 1.
do_one("q8", 0L, 512L, 6L, 20260901L)
do_one("q8", 1L, 512L, 6L, 20260901L)
do_one("q8", 0L, 1024L, 4L, 20260901L)
do_one("q8", 1L, 1024L, 4L, 20260901L)
hb("done %s\n", format(Sys.time()))
