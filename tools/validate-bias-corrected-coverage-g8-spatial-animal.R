#!/usr/bin/env Rscript
# Engine bias-corrected+t coverage at g=8 for the spatial + animal q2 mu-slope
# SD endpoints. This is row-specific revalidation evidence only: it does not
# promote all four providers, the q2 correlation target, or supported status.
# SR475.
root <- "/Users/z3437171/Dropbox/Github Local/drmTMB"; setwd(root); Sys.setenv(GSWEEP_N_GROUPS="8")
runner <- file.path(root, "tools/run-structured-re-q2-slope-coverage-grid.R")
src <- readLines(runner); ml <- grep("^args\\s*<-\\s*parse_args", src)[1L]
tmp <- tempfile(fileext=".R"); writeLines(src[seq_len(ml-1L)], tmp); source(tmp)
suppressMessages(pkgload::load_all(root, quiet=TRUE))
z <- qnorm(0.975)
covers <- function(t,lo,hi) if (is.finite(lo)&&is.finite(hi)) (t>=lo && t<=hi) else NA
cells <- expand.grid(provider=c("spatial","animal"), target=c("mu1:x","mu2:x"), stringsAsFactors=FALSE)
n_rep <- 475L; seed0 <- 730001L
rows <- list()
for (k in seq_len(nrow(cells))) {
  prov<-cells$provider[k]; tgt<-cells$target[k]; parm<-parm_name_for(prov,tgt); truth<-truth_for(tgt)
  cat(sprintf("[%s] %s %s\n", format(Sys.time(),"%H:%M:%S"), prov, tgt))
  for (i in seq_len(n_rep)) {
    r <- tryCatch({
      sim <- make_q2_slope_data(prov, seed0+i-1L, 20L); fit <- fit_q2_slope(prov, sim)
      ciz  <- suppressWarnings(stats::confint(fit, parm=parm, method="wald"))
      cibc <- suppressWarnings(stats::confint(fit, parm=parm, method="wald", small_sample_df="group", bias_correct="group"))
      list(zl=ciz$lower[[1]],zu=ciz$upper[[1]],bl=cibc$lower[[1]],bu=cibc$upper[[1]],ok=TRUE)
    }, error=function(e) list(ok=FALSE))
    if (isTRUE(r$ok)) rows[[length(rows)+1L]] <- data.frame(provider=prov,target=tgt,seed=seed0+i-1L,truth=truth,
      bc_lower=r$bl,bc_upper=r$bu,wald_contains=covers(truth,r$zl,r$zu),bc_contains=covers(truth,r$bl,r$bu),stringsAsFactors=FALSE)
  }
}
out <- do.call(rbind, rows)
outdir <- file.path(root,"docs/dev-log/simulation-artifacts/2026-06-27-bias-corrected-engine-coverage-g8-spatial-animal")
dir.create(outdir, showWarnings=FALSE, recursive=TRUE)
write.table(out, file.path(outdir,"replicates.tsv"), sep="\t", row.names=FALSE, quote=FALSE)
mcse <- function(p,n) if (n>0) sqrt(p*(1-p)/n) else NA_real_
cat("\n=== ENGINE bc+t coverage g=8 (spatial+animal, SR475) ===\n")
cat(sprintf("%-16s %5s %8s %8s %8s\n","cell","n","wald_z","bc+t","mcse"))
for (k in seq_len(nrow(cells))) {
  sub<-out[out$provider==cells$provider[k] & out$target==cells$target[k],]
  nb<-sum(!is.na(sub$bc_contains)); cb<-mean(sub$bc_contains,na.rm=TRUE); cz<-mean(sub$wald_contains,na.rm=TRUE)
  cat(sprintf("%-16s %5d %8.3f %8.3f %8.4f\n", paste(cells$provider[k],cells$target[k]), nb, cz, cb, mcse(cb,nb)))
}
cat("DONE spatial+animal\n")
