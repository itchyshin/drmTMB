## F5-tiny-n-gaussian: drmTMB on the n = 8 Gaussian location-scale datasets of sweep-oct16 t4.
## Run from this folder:  Rscript f5_drmTMB.R > f5_drmTMB.out 2>&1
## Data: ../../data/gauss_n8_rNN.csv (written by ../../t4_gen_data.R; nominal seed
## 20261016400 + rep - 1, R seed = nominal %% 2^31 = 933663568 + rep - 1).
## Model: drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d)
suppressPackageStartupMessages(library(drmTMB))
cat("drmTMB", as.character(packageVersion("drmTMB")), "| TMB", as.character(packageVersion("TMB")), "\n")
cat("drmTMB checkout HEAD (R/ and src/ identical to ca3ddefa5ea11bbfd3b765615dfbb89305d2485a):",
    tryCatch(system("git -C /home/user/drmTMB rev-parse HEAD", intern = TRUE), error = function(e) NA), "\n")
print(sessionInfo())
ddir <- "../../data"
rd <- function(r) read.csv(file.path(ddir, sprintf("gauss_n8_r%02d.csv", r)))
ll_exact <- function(th, d) sum(dnorm(d$y, th[1] + th[2] * d$x, exp(th[3] + th[4] * d$x), log = TRUE))

## best value of the exact likelihood found by the engine-independent scan (f5_reference.R);
## for r06 / r19 / r49 the likelihood is unbounded, so "best" is the best finite local max
best <- if (file.exists("f5_reference_maxima.csv")) {
  A <- read.csv("f5_reference_maxima.csv"); A <- A[A$grid_edge == 0, ]
  tapply(A$ll, A$rep, max)
} else NULL

fit1 <- function(d, ctrl = drm_control()) {
  w <- character()
  f <- withCallingHandlers(
    tryCatch(drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d, control = ctrl),
             error = function(e) { w <<- c(w, paste("ERROR:", conditionMessage(e))); NULL }),
    warning = function(cnd) { w <<- c(w, conditionMessage(cnd)); invokeRestart("muffleWarning") })
  list(fit = f, warn = w)
}
summ <- function(lab, r, d, o) {
  f <- o$fit
  if (is.null(f)) { cat(sprintf("  %-26s %s\n", lab, paste(o$warn, collapse = " | "))); return(invisible(NULL)) }
  th <- unlist(fixef(f))
  ls <- th[3] + th[4] * d$x
  ## #1503-style rule: Newton step in SE units, from the stored gradient and sdreport covariance
  nstep <- tryCatch({
    V <- f$sdr$cov.fixed; g <- as.numeric(f$gradient)
    max(abs(V %*% g) / sqrt(diag(V)))
  }, error = function(e) NA_real_)
  ## pieces of the #1509 trigger (draft PR, not on the pin): lower clamp hit, log-sigma spread
  ## > log(1e4), smallest-scale observation fitted exactly (|Pearson residual| < 1e-3)
  imin <- which.min(ls); pear <- (d$y[imin] - th[1] - th[2] * d$x[imin]) / exp(ls[imin])
  cat(sprintf(paste0("  %-26s logLik %10.5f | exact ll at estimate %10.5f | best %s | conv %-5s status %-10s",
                     " | max|grad| %.1e | Newton step/SE %.1e | log sigma [%.2f, %.2f] spread %.1f | Pearson(min-scale obs) %.1e\n"),
              lab, as.numeric(logLik(f)), ll_exact(th, d),
              if (is.null(best)) "NA" else sprintf("%9.5f", best[as.character(r)]),
              is_converged(f), convergence_status(f), max(abs(f$gradient)), nstep,
              min(ls), max(ls), diff(range(ls)), pear))
  if (length(o$warn)) cat("    warnings:", paste(gsub("\n", " ", unique(o$warn)), collapse = " || "), "\n")
  chk <- tryCatch(check_drm(f), error = function(e) NULL)
  if (!is.null(chk)) {
    b <- chk[chk$status %in% c("warning", "error", "note"), c("check", "status")]
    cat("    check_drm:", if (nrow(b)) paste0(b$check, "=", b$status, collapse = "; ") else "all ok", "\n")
  }
  invisible(f)
}

reps <- c(5, 9, 28, 4, 29, 30, 31, 6, 19, 49)
for (r in reps) {
  d <- rd(r)
  cat(sprintf("\n=== gauss_n8_r%02d (R seed %d) ===\n", r, 933663568L + 100L * 0L + r - 1L))
  summ("default", r, d, fit1(d))
  summ("multi_start = 10", r, d, fit1(d, drm_control(multi_start = 10)))
  summ("logsigma_clamp = NULL", r, d, fit1(d, drm_control(logsigma_clamp = NULL)))
  summ("clamp NULL + multi_start 10", r, d, fit1(d, drm_control(logsigma_clamp = NULL, multi_start = 10)))
}

## multi_start = 10 on all 50 n = 8 datasets: which reps does it move, and by how much?
cat("\n=== default vs multi_start = 10 on all 50 gauss_n8 datasets ===\n")
for (r in 1:50) {
  d <- rd(r); a <- fit1(d)$fit; b <- fit1(d, drm_control(multi_start = 10))$fit
  la <- as.numeric(logLik(a)); lb <- as.numeric(logLik(b))
  if (abs(lb - la) > 1e-6)
    cat(sprintf("r%02d default %.5f (conv %s) -> multi_start %.5f (conv %s, status %s); gain %.4f\n",
                r, la, is_converged(a), lb, is_converged(b), convergence_status(b), lb - la))
}
cat("(reps not listed: multi_start = 10 returned the default logLik to 1e-6)\n")
