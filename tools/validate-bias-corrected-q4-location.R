#!/usr/bin/env Rscript
# Does the bias correction unlock the q4-location (biv mu1+mu2) SD intervals?
# q4-location is fragile at small g (pdHess failures), so track finite fraction
# AND coverage on the finite denominator. Providers phylo/relmat; g=8 and g=16.
root <- "/Users/z3437171/Dropbox/Github Local/drmTMB"; setwd(root)
runner <- file.path(root, "tools/run-structured-re-q4-location-coverage-grid.R")
src <- readLines(runner); ml <- grep("^args\\s*<-\\s*parse_args", src)[1L]
tmp <- tempfile(fileext=".R"); writeLines(src[seq_len(ml-1L)], tmp); source(tmp)
suppressMessages(pkgload::load_all(root, quiet=TRUE))
z <- qnorm(0.975)
grp_for <- function(p) switch(p, phylo="species", spatial="site", animal="id", relmat="id")
sd_parm <- function(prov, member){
  resp <- sub(":.*","",member); coef <- if (grepl("Intercept", member)) "1" else "0 + x"
  paste0("sd:mu:", resp, ":", prov, "(", coef, " | p | ", grp_for(prov), ")")
}
members <- c("mu1:(Intercept)","mu1:x","mu2:(Intercept)","mu2:x")
provs <- c("phylo","relmat"); n_rep <- 200L; seed0 <- 850001L
for (g in c(8L,16L)) {
  Sys.setenv(GSWEEP_N_GROUPS=as.character(g))
  cat(sprintf("\n===== q4-location g=%d =====\n", g)); cat(sprintf("%-30s %5s %7s %8s %8s\n","cell","n_fin","pdHess","wald_z","bc+t"))
  for (prov in provs) for (mem in members) {
    parm <- sd_parm(prov, mem); truth <- truth_for(mem)
    nfin<-0; nbc<-0; npd<-0; cz<-0; cb<-0; ntot<-0
    for (i in seq_len(n_rep)) {
      r <- tryCatch({
        sim <- make_q4_location_data(prov, seed0+i-1L, 20L); fit <- fit_q4_location(prov, sim)
        pd <- isTRUE(fit$sdr$pdHess)
        ciz <- suppressWarnings(stats::confint(fit, parm=parm, method="wald"))
        cibc<- suppressWarnings(stats::confint(fit, parm=parm, method="wald", small_sample_df="group", bias_correct="group"))
        list(pd=pd, zl=ciz$lower[[1]],zu=ciz$upper[[1]], bl=cibc$lower[[1]],bu=cibc$upper[[1]])
      }, error=function(e) NULL)
      if (is.null(r)) next
      ntot<-ntot+1; if (isTRUE(r$pd)) npd<-npd+1
      if (is.finite(r$zl)&&is.finite(r$zu)) { nfin<-nfin+1; cz<-cz+(truth>=r$zl&&truth<=r$zu) }
      if (is.finite(r$bl)&&is.finite(r$bu)) { nbc<-nbc+1; cb<-cb+(truth>=r$bl&&truth<=r$bu) }
    }
    cat(sprintf("%-30s %5d %7.2f %8.3f %8.3f\n", paste(prov,mem), nbc, npd/max(ntot,1),
      if(nfin>0) cz/nfin else NA, if(nbc>0) cb/nbc else NA))
  }
}
cat("\nDONE q4-location\n")
