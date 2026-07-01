#!/usr/bin/env Rscript
# Second validation grid for the bias-corrected q2 mu-slope SD interval, per the
# sign-off panel (Fisher): (a) a NEAR-BOUNDARY small-SD truth (the regime the
# correction was NOT validated in), (b) extra g (6,12), and (c) ONE-SIDED miss
# rates (below/above), to quantify the residual downward-bias asymmetry, not just
# total coverage. Providers phylo/relmat; engine confint(bias_correct+t).
root <- "/Users/z3437171/Dropbox/Github Local/drmTMB"; setwd(root)
runner <- file.path(root, "tools/run-structured-re-q2-slope-coverage-grid.R")
src <- readLines(runner); ml <- grep("^args\\s*<-\\s*parse_args", src)[1L]
tmp <- tempfile(fileext=".R"); writeLines(src[seq_len(ml-1L)], tmp); source(tmp)
suppressMessages(pkgload::load_all(root, quiet=TRUE))
provs <- c("phylo","relmat"); n_rep <- 300L; seed0 <- 731001L

run_cell <- function(prov, tgt, truth, g) {
  parm <- parm_name_for(prov, tgt)
  nb<-0; cb<-0; below<-0; above<-0
  for (i in seq_len(n_rep)) {
    r <- tryCatch({
      sim <- make_q2_slope_data(prov, seed0+i-1L, 20L); fit <- fit_q2_slope(prov, sim)
      ci <- suppressWarnings(stats::confint(fit, parm=parm, method="wald", small_sample_df="group", bias_correct="group"))
      c(lo=ci$lower[[1]], hi=ci$upper[[1]])
    }, error=function(e) c(lo=NA,hi=NA))
    if (is.finite(r["lo"]) && is.finite(r["hi"])) {
      nb<-nb+1
      if (truth>=r["lo"] && truth<=r["hi"]) cb<-cb+1
      else if (r["hi"]<truth) below<-below+1 else if (r["lo"]>truth) above<-above+1
    }
  }
  cat(sprintf("%-22s g=%-2d truth=%.2f  n=%d  cov=%.3f  miss_below=%.3f  miss_above=%.3f\n",
      paste(prov,tgt), g, truth, nb, cb/nb, below/nb, above/nb))
}

cat("=== (a) NEAR-BOUNDARY small-SD truth (0.35), g=8 ===\n")
TRUTH$sd_mu1_x <- 0.35; TRUTH$sd_mu2_x <- 0.35
Sys.setenv(GSWEEP_N_GROUPS="8")
for (prov in provs) { run_cell(prov,"mu1:x",0.35,8L); run_cell(prov,"mu2:x",0.35,8L) }

cat("\n=== (b) original truths, extra g (6, 12) + one-sided misses ===\n")
TRUTH$sd_mu1_x <- 1.05; TRUTH$sd_mu2_x <- 0.90
for (g in c(6L,12L)) {
  Sys.setenv(GSWEEP_N_GROUPS=as.character(g))
  for (prov in provs) { run_cell(prov,"mu1:x",1.05,g); run_cell(prov,"mu2:x",0.90,g) }
}
cat("\nDONE secondgrid\n")
