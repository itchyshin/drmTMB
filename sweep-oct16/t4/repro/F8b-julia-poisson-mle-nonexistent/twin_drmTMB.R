## F8b supplementary (twin context only; the finding is about DRModels.jl):
## the same two datasets (t4 cell 15 reps 3 and 27) on drmTMB and on stats::glm.
## Run from this directory:  Rscript twin_drmTMB.R > twin_drmTMB.out 2>&1
suppressPackageStartupMessages(library(drmTMB))
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
for (r in c(3L, 27L)) {
  d <- read.csv(file.path("..", "..", "data", sprintf("pois_n8_lowmean_r%02d.csv", r)))
  cat("\n=== rep", r, ": y =", d$y, "\n")
  w <- character()
  f <- withCallingHandlers(
    drmTMB(bf(y ~ 1 + x), family = poisson(), data = d),
    warning = function(cnd) { w <<- c(w, conditionMessage(cnd)); invokeRestart("muffleWarning") })
  cat("drmTMB: converged =", is_converged(f), " logLik =", format(as.numeric(logLik(f)), digits = 12), "\n")
  print(cbind(estimate = fixef(f)$mu, se = sqrt(diag(vcov(f)))))
  cat("warnings:", length(w), if (length(w)) paste(w, collapse = " || ") else "", "\n")
  g <- withCallingHandlers(glm(y ~ x, family = poisson(), data = d),
    warning = function(cnd) { cat("glm warning:", conditionMessage(cnd), "\n"); invokeRestart("muffleWarning") })
  cat("stats::glm: converged =", g$converged, " iter =", g$iter, "\n")
  print(coef(summary(g))[, 1:2])
}
cat("\n"); print(sessionInfo())
