#!/usr/bin/env Rscript
# Engine coverage validation of the bias-corrected + t interval at g=16 and g=32.
# Complements the g=8 SR475 run; confirms the ENGINE (confint) holds nominal as g
# grows (no over-correction), matching the post-hoc cross-g result. The engine
# auto-resolves g from the fit, so we only set GSWEEP_N_GROUPS per level.
root <- "/Users/z3437171/Dropbox/Github Local/drmTMB"; setwd(root)
runner <- file.path(root, "tools/run-structured-re-q2-slope-coverage-grid.R")
src <- readLines(runner); ml <- grep("^args\\s*<-\\s*parse_args", src)[1L]
tmp <- tempfile(fileext=".R"); writeLines(src[seq_len(ml-1L)], tmp); source(tmp)
suppressMessages(pkgload::load_all(root, quiet=TRUE))
z <- qnorm(0.975)
covers <- function(t,lo,hi) if (is.finite(lo)&&is.finite(hi)) (t>=lo && t<=hi) else NA
cells <- expand.grid(provider=c("phylo","relmat"), target=c("mu1:x","mu2:x"), stringsAsFactors=FALSE)
n_rep <- 300L; seed0 <- 730001L
for (g in c(16L, 32L)) {
  Sys.setenv(GSWEEP_N_GROUPS=as.character(g))
  cat(sprintf("\n===== g=%d (GSWEEP_N_GROUPS=%d) =====\n", g, g))
  cat(sprintf("%-16s %5s %8s %8s\n","cell","n","wald_z","bc+t"))
  tot_b<-0; tot_n<-0; tot_z<-0; tot_nz<-0
  for (k in seq_len(nrow(cells))) {
    prov<-cells$provider[k]; tgt<-cells$target[k]; parm<-parm_name_for(prov,tgt); truth<-truth_for(tgt)
    nb<-0; cb<-0; nz<-0; cz<-0
    for (i in seq_len(n_rep)) {
      r <- tryCatch({
        sim <- make_q2_slope_data(prov, seed0+i-1L, 20L); fit <- fit_q2_slope(prov, sim)
        ciz  <- suppressWarnings(stats::confint(fit, parm=parm, method="wald"))
        cibc <- suppressWarnings(stats::confint(fit, parm=parm, method="wald", small_sample_df="group", bias_correct="group"))
        list(z=covers(truth,ciz$lower[[1]],ciz$upper[[1]]), b=covers(truth,cibc$lower[[1]],cibc$upper[[1]]))
      }, error=function(e) list(z=NA,b=NA))
      if (!is.na(r$z)) { nz<-nz+1; cz<-cz+r$z }
      if (!is.na(r$b)) { nb<-nb+1; cb<-cb+r$b }
    }
    cat(sprintf("%-16s %5d %8.3f %8.3f\n", paste(prov,tgt), nb, cz/nz, cb/nb))
    tot_b<-tot_b+cb; tot_n<-tot_n+nb; tot_z<-tot_z+cz; tot_nz<-tot_nz+nz
  }
  cat(sprintf("POOLED g=%d  n=%d  wald_z=%.3f  bc+t=%.3f\n", g, tot_n, tot_z/tot_nz, tot_b/tot_n))
}
cat("\nDONE multi-g\n")
