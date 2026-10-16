## F3-r-complete-separation: does draft PR #1442 (head a8af9ab4, branch
## claude/separation-1268) change the verdict on the same 100 datasets?
## Usage (from this directory):
##   Rscript verify_pr1442.R <private library holding drmTMB built from a8af9ab4> > verify_pr1442.out 2>&1
lib <- commandArgs(trailingOnly = TRUE)[1]
stopifnot(!is.na(lib), dir.exists(file.path(lib, "drmTMB")))
suppressPackageStartupMessages(library(drmTMB, lib.loc = lib))
cat("drmTMB", as.character(packageVersion("drmTMB", lib.loc = lib)), "loaded from", lib, "\n")
cat("has drm_separation_screen:", exists("drm_separation_screen", envir = asNamespace("drmTMB")), "\n\n")

d <- read.csv("../../data/bin_complete_r01.csv")
warns <- list()
fit <- withCallingHandlers(drmTMB(bf(y ~ x), family = binomial(), data = d),
  warning = function(w) { warns[[length(warns) + 1]] <<- w; invokeRestart("muffleWarning") })
cat("bin_complete rep 1: warnings =", length(warns), "; classes =", paste(class(warns[[1]]), collapse = "/"), "\n")
cat(conditionMessage(warns[[1]]), "\n")
print(sqrt(diag(vcov(fit))))
cat("is_converged():", is_converged(fit), "; convergence_status():", convergence_status(fit), "\n")
chk <- check_drm(fit); cat("check_drm ok:", attr(chk, "ok"), "\n")
print(as.data.frame(chk)[chk$status != "ok", c("check", "status")], right = FALSE)

res <- list()
for (cell in c("bin_complete", "bin_quasi")) for (r in 1:50) {
  d <- read.csv(sprintf("../../data/%s_r%02d.csv", cell, r))
  nw <- 0L; sepw <- FALSE
  fit <- withCallingHandlers(drmTMB(bf(y ~ x), family = binomial(), data = d),
    warning = function(w) { nw <<- nw + 1L; sepw <<- sepw || inherits(w, "drmTMB_separation_warning"); invokeRestart("muffleWarning") })
  res[[length(res) + 1]] <- data.frame(cell = cell, rep = r, sep_warn = sepw,
    flagged = paste(fit$separation$flagged, collapse = "+"),
    converged = is_converged(fit), status = convergence_status(fit),
    check_ok = isTRUE(attr(check_drm(fit), "ok")))
}
res <- do.call(rbind, res)
for (cell in unique(res$cell)) {
  s <- res[res$cell == cell, ]
  cat("\n==", cell, "(50 seeds) == separation warning:", sum(s$sep_warn),
      "; is_converged TRUE:", sum(s$converged), "; check_drm ok TRUE:", sum(s$check_ok), "\n")
  print(table(flagged = s$flagged, status = s$status))
}
cat("\n"); sessionInfo()
