#!/usr/bin/env Rscript
# Oracle bias-correction recompute on banked g=8 q2 coverage replicates.
#
# Tests the CEILING of a centre fix for the g=8 mu-slope SD under-coverage.
# All four interval methods (Wald, Wald-t, profile, percentile-bootstrap) are
# centred on the ML variance-component estimate, which is biased LOW at small g.
# Here we DEBIAS the log-scale centre by the MEASURED mean log-shrinkage
# (oracle: uses the known truth), then build a t(df=g-1) interval around the
# debiased centre, and recompute coverage. This bounds what ANY real
# bias-corrected estimator could achieve.
#
# Result (pooled over 8 q2 cells, n=3800, g=8):
#   Wald-z 0.887  ->  Wald-t 0.932  ->  ORACLE bias-corrected + t  0.956
# i.e. correcting the centre (log-bias ~ -0.12 to -0.14) reaches nominal.
# => the g=8 wall is the CENTRE; a centre fix reaches nominal; `supported` at
#    deployment-g is reachable IF the bias can be estimated in practice (the
#    parametric-bootstrap-bias prototype tests that separately).

z <- qnorm(0.975); g <- 8L; tq <- qt(0.975, g - 1)
dir <- "docs/dev-log/simulation-artifacts/2026-06-27-q2-slope-coverage-grid-local"
files <- list.files(dir, pattern = "-(mu1_x|mu2_x)-replicates.tsv$", full.names = TRUE)
cat(sprintf("%-22s %6s %7s %7s %12s %8s\n",
            "cell", "n", "wald_z", "wald_t", "oracle_bc_t", "logbias"))
agg <- list()
for (f in files) {
  prov <- strsplit(basename(f), "-")[[1]][2]
  tgt  <- sub(".*-(mu[12]_x)-replicates.tsv", "\\1", basename(f))
  d <- read.delim(f, stringsAsFactors = FALSE)
  est <- suppressWarnings(as.numeric(d$estimate))
  tru <- suppressWarnings(as.numeric(d$truth_value))
  L <- suppressWarnings(as.numeric(d$wald_lower))
  U <- suppressWarnings(as.numeric(d$wald_upper))
  ok <- is.finite(L) & is.finite(U) & L > 0 & U > 0 & is.finite(est) & est > 0 & is.finite(tru)
  L <- L[ok]; U <- U[ok]; est <- est[ok]; tru <- tru[ok]
  se <- (log(U) - log(L)) / (2 * z)
  m  <- log(est)
  logbias <- mean(m - log(tru))      # ORACLE measured mean log-shrinkage
  mb <- m - logbias                  # debiased centre
  cov_z  <- mean(tru >= L & tru <= U)
  cov_t  <- mean(tru >= exp(m - tq * se)  & tru <= exp(m + tq * se))
  cov_bc <- mean(tru >= exp(mb - tq * se) & tru <= exp(mb + tq * se))
  agg[[paste(prov, tgt)]] <- c(n = length(tru), z = cov_z, t = cov_t, bc = cov_bc, lb = logbias)
  cat(sprintf("%-22s %6d %7.3f %7.3f %12.3f %8.3f\n",
              paste(prov, tgt), length(tru), cov_z, cov_t, cov_bc, logbias))
}
M <- do.call(rbind, agg); w <- M[, "n"]
cat(sprintf("\nPOOLED (n=%d)   wald_z=%.3f  wald_t=%.3f  ORACLE_bc+t=%.3f\n",
            sum(w), sum(M[, "z"] * w) / sum(w),
            sum(M[, "t"] * w) / sum(w), sum(M[, "bc"] * w) / sum(w)))
