## F1-julia-aliased-sigma: drmTMB side (for comparison only; the R twin is drmTMB #1470 / #1478).
## Same data as repro_min.jl: t4 cell 13 rep 1 (nominal seed 20261017600, R seed 933664768).
## Run from this directory: Rscript repro_drmTMB.R > repro_drmTMB.out 2>&1
suppressPackageStartupMessages(library(drmTMB))
d <- read.csv(file.path("..", "..", "data", "collin_sigma_exact_r01.csv"))
cat("n =", nrow(d), "; max |z - (2x + 1)| =", max(abs(d$z - (2 * d$x + 1))), "\n")
cat("qr(model.matrix(~ x + z))$rank =", qr(model.matrix(~ x + z, d))$rank, "of 3 (default tol 1e-7)\n")

show_fit <- function(label, expr) {
  cat("\n===", label, "===\n")
  w <- character()
  fit <- withCallingHandlers(expr, warning = function(c) { w <<- c(w, conditionMessage(c)); invokeRestart("muffleWarning") })
  if (length(w)) cat("warnings:", paste(unique(w), collapse = " | "), "\n")
  cat("is_converged =", is_converged(fit), "  convergence_status =", convergence_status(fit),
      "  logLik =", format(as.numeric(logLik(fit)), digits = 12), "\n")
  print(unlist(fixef(fit)))
  v <- tryCatch(vcov(fit), error = function(e) paste("vcov() ERROR:", conditionMessage(e)))
  if (is.character(v)) cat(v, "\n") else print(sqrt(diag(v)))
  chk <- check_drm(fit)
  print(as.data.frame(chk)[chk$status != "ok", c("check", "status")], row.names = FALSE)
  cat("check_drm ok attribute =", isTRUE(attr(chk, "ok")), "\n")
  invisible(fit)
}
d$xdup <- d$x
show_fit("sigma ~ x + z (cell 13)", drmTMB(bf(y ~ x, sigma ~ x + z), family = gaussian(), data = d))
show_fit("sigma ~ x + xdup", drmTMB(bf(y ~ x, sigma ~ x + xdup), family = gaussian(), data = d))
show_fit("y ~ x + z, sigma ~ x", drmTMB(bf(y ~ x + z, sigma ~ x), family = gaussian(), data = d))
show_fit("reduced: sigma ~ x", drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d))

cat("\npackageVersion('drmTMB') =", as.character(packageVersion("drmTMB")), "\n")
cat("drmTMB RemoteSha / GithubSHA1 =", paste(c(packageDescription("drmTMB")$RemoteSha, packageDescription("drmTMB")$GithubSHA1), collapse = " "), "\n")
print(sessionInfo())
