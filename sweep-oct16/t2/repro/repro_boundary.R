# t2 repro (R side): the same datasets fitted by drmTMB ca3ddef (native TMB).
# Run from this directory: Rscript repro_boundary.R
suppressPackageStartupMessages(library(drmTMB))
f <- bf(y ~ x + (1 | g), sigma ~ z)
cat("== sd(g) boundary, n = 50, G = 20 ==\n")
for (file in c("n0050_G20_rep121.csv", "n0050_G20_rep143.csv",
               "n0050_G20_rep175.csv", "n0050_G20_rep253.csv")) {
  d <- read.csv(file)
  d$g <- factor(d$g)
  fit <- suppressWarnings(drmTMB(f, data = d))
  ci <- suppressWarnings(confint(fit, method = "wald"))
  r <- ci[ci$parm == "sd:mu:(1 | g)", ]
  cat(sprintf("%-22s logLik = %.6f  is_converged = %s  status = %s  sd(g) = %.3g  Wald = [%g, %g] (%s)\n",
              file, as.numeric(logLik(fit)), is_converged(fit),
              convergence_status(fit), fit$sdpars$mu[[1]], r$lower, r$upper,
              r$conf.status))
  pr <- suppressWarnings(confint(fit, parm = "sd:mu:(1 | g)", method = "profile"))
  cat(sprintf("%-22s profile sd(g) = [%g, %g] (%s, boundary = %s)\n", "", pr$lower, pr$upper,
              pr$conf.status, pr$profile.boundary))
}
cat("\n== all-singleton groups, n = 50, G = 50 ==\n")
for (file in c("n0050_G50_rep068.csv", "n0050_G50_rep072.csv", "n0050_G50_rep077.csv")) {
  d <- read.csv(file)
  d$g <- factor(d$g)
  res <- tryCatch(drmTMB(f, data = d), error = function(e) e)
  cat(sprintf("%-22s %s\n", file,
              if (inherits(res, "error")) paste("refused:", gsub("\\s+", " ", conditionMessage(res)))
              else "fitted"))
}
