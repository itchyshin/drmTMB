# R: same data, same start vectors, driven through the fitted TMB object (fit$obj) with nlminb, as drmTMB's own optimiser does.
# usage: DRMTMB_LIB=<lib> Rscript r_probe.R   (run from this directory)
.libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths())); suppressMessages(library(drmTMB))
MS <- file.path("..", "..", "multiseed")
d <- read.csv(file.path(MS, "data", "poisson_spatial_s09.csv")); d$id <- factor(d$g)
cc <- read.csv(file.path(MS, "coords.csv")); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
fm <- bf(y ~ x + spatial(1 + x | id, coords = coords), sd(id, level = "spatial", coef = "(Intercept)") ~ z0, sd(id, level = "spatial", coef = "x") ~ z1)
fit <- drmTMB(fm, family = stats::poisson(), data = d)
obj <- fit$obj; z1u <- unique(d$z1); st <- read.csv("starts.csv"); rows <- list()
rec <- function(label, par, ll, conv, grad) {
  sdv <- exp(par[5] + par[6] * z1u)
  rows[[length(rows) + 1]] <<- data.frame(start = label, ll = sprintf("%.10f", ll), convergence = conv, theta = paste(sprintf("%.10g", par), collapse = ";"),
                                           slope_sd_min = min(sdv), slope_sd_max = max(sdv), max_abs_grad = grad)
  cat(sprintf("%s ll=%.9f conv=%s theta=%s slopeSD[%.2e, %.2e] |g|max=%.1e\n", label, ll, conv, paste(round(par, 3), collapse = " "), min(sdv), max(sdv), grad))
}
rec("default", fit$opt$par, as.numeric(logLik(fit)), fit$opt$convergence, max(abs(obj$gr(fit$opt$par))))
for (k in seq_len(nrow(st))) {
  p0 <- unlist(st[k, c("b0", "b1", "a0_int", "a0_z0", "a1_int", "a1_z1")], use.names = FALSE)
  r <- nlminb(p0, obj$fn, obj$gr, control = list(eval.max = 1000, iter.max = 1000))
  rec(st$start[k], r$par, -r$objective, r$convergence, max(abs(obj$gr(r$par))))
}
write.csv(do.call(rbind, rows), "r_starts.csv", row.names = FALSE)
