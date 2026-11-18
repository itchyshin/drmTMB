args <- commandArgs(trailingOnly = TRUE)
base <- "/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b"
kind <- args[[1L]]
.libPaths(c(file.path(base, if (kind == "baseline") "r-c17-baseline-lib" else "r-publish-opt-lib"), .libPaths()))
library(drmTMB)
root <- file.path(base, if (kind == "baseline") "r-c17-baseline-src" else "r-publish-opt-src")
lines <- readLines(file.path(root, "tools/run-lane-c-c17c1-c14-model15-compatibility.R"))
end <- grep("^fit_one <-", lines)[1L] - 1L
eval(parse(text = lines[seq_len(end)]), envir = globalenv())
output <- list()
for (cell in names(route_spec)) {
  spec <- route_spec[[cell]]
  sim <- spec$simulate(spec$seeds[[1L]])
  fit <- drmTMB::drmTMB(spec$formula(), family = drmTMB::zero_one_beta(), data = sim$data,
                        control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 3000L, iter.max = 3000L)))
  if (kind == "baseline") {
    theta <- fit$opt$par
  } else {
    theta <- readRDS(file.path(base, "evidence/r-c17-common-baseline.rds"))[[cell]]$theta
    stopifnot(identical(names(theta), names(fit$opt$par)))
  }
  fit$obj$env$random.start <- expression(par[random])
  fit$obj$env$last.par.best <- fit$obj$env$last.par
  value <- fit$obj$fn(theta)
  gradient <- fit$obj$gr(theta)
  output[[cell]] <- list(theta = theta, objective = value, gradient = gradient,
                         fitted_objective = fit$opt$objective,
                         convergence = fit$opt$convergence, pdHess = fit$sdr$pdHess)
  cat(cell, "objective", sprintf("%.17g", value), "gradient_max", sprintf("%.17g", max(abs(gradient))), "\n")
}
saveRDS(output, file.path(base, paste0("evidence/r-c17-common-", kind, ".rds")))
