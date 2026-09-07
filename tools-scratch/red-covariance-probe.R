# One measurement of the silent-covariance defect against whatever
# R/julia-diagnostics.R is on disk right now. Run as a subprocess so the
# origin/main and post-change versions are each loaded from scratch.
label <- commandArgs(trailingOnly = TRUE)[[1L]]
suppressMessages(devtools::load_all(".", quiet = TRUE))
source("tools-scratch/mkfit.R")
fit <- drm_redctl_fit(vcov = matrix(NaN, 3L, 3L))
stopifnot(identical(fit$uncertainty$status, "unavailable"))
dc <- check_drm(fit)
cat(sprintf(
  "%s ok=%s rows=%d covrow=%d\n",
  label, toupper(as.character(attr(dc, "ok"))), nrow(dc),
  sum(dc$check == "bridge_covariance")
))
