# Lead-novelty rho12 ~ predictors recovery (native R/TMB, fixed-effect bivariate).
#
# Bivariate Gaussian with a predictor-dependent residual correlation:
#   mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ x
# rho12 uses the guarded atanh link: rho12_i = 0.999999 * tanh(a0 + a1 * x_i).
# We recover (a0, a1) on the atanh linear-predictor scale and measure bias and
# Wald coverage across replicates. Boundary: native R/TMB, fixed-effect only;
# this characterises identifiability of the predictor-dependent rho12 (the lead
# novelty), not random-effect, structured, or bridge rho12.
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 100L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-rho12-predictor-recovery"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

# truth on the atanh linear-predictor scale (rho ~ 0.0..0.76 over x in +-2)
a0 <- 0.4
a1 <- 0.5
b_mu1 <- c(0.2, 0.6)
b_mu2 <- c(-0.1, 0.4)
s1 <- 1.0
s2 <- 1.0
targets <- c("rho12:(Intercept)", "rho12:x")
truth <- c("fixef:rho12:(Intercept)" = a0, "fixef:rho12:x" = a1)
cells <- data.frame(n = c(300L, 600L))
master_seed <- 20260620L

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- data.frame(..., stringsAsFactors = FALSE)
t0 <- Sys.time()
for (ci in seq_len(nrow(cells))) {
  n <- cells$n[[ci]]
  for (r in seq_len(n_rep)) {
    set.seed(master_seed + ci * 100000L + r)
    x <- rnorm(n)
    m1 <- b_mu1[1] + b_mu1[2] * x
    m2 <- b_mu2[1] + b_mu2[2] * x
    rho <- 0.999999 * tanh(a0 + a1 * x)
    e1 <- rnorm(n)
    e2 <- rho * e1 + sqrt(pmax(1 - rho^2, 0)) * rnorm(n)
    dat <- data.frame(y1 = m1 + s1 * e1, y2 = m2 + s2 * e2, x = x)
    form <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~x)
    fit <- tryCatch(drmTMB(form, family = biv_gaussian(), data = dat), error = function(e) e)
    if (inherits(fit, "error")) {
      add(cell = ci, n = n, rep = r, target = "NA", est = NA_real_, covered = NA,
          width = NA_real_, pdhess = NA, status = "fit_error")
      next
    }
    pdh <- isTRUE(fit$sdr$pdHess)
    co <- tryCatch(coef(fit, "rho12"), error = function(e) NULL)
    ci_w <- tryCatch(suppressWarnings(confint(fit, parm = targets)), error = function(e) e)
    if (inherits(ci_w, "error") || is.null(co)) {
      add(cell = ci, n = n, rep = r, target = "NA", est = NA_real_, covered = NA,
          width = NA_real_, pdhess = pdh, status = "confint_error")
      next
    }
    for (tg in unique(ci_w$parm)) {
      row <- ci_w[ci_w$parm == tg, , drop = FALSE][1L, ]
      tv <- truth[[row$parm]]
      est <- suppressWarnings(co[sub("^fixef:rho12:", "", row$parm)])
      cov <- pdh && is.finite(row$lower) && is.finite(row$upper) &&
        tv >= row$lower && tv <= row$upper
      add(cell = ci, n = n, rep = r, target = row$parm,
          est = if (length(est)) as.numeric(est) else NA_real_,
          covered = cov, width = row$upper - row$lower, pdhess = pdh,
          status = as.character(row$conf.status))
    }
  }
}
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
fits <- do.call(rbind, rows)
write.csv(fits, file.path(out_dir, "tables", "rho12-recovery-fits.csv"), row.names = FALSE)

ok <- fits[!is.na(fits$est), , drop = FALSE]
key <- paste(ok$n, ok$target, sep = "|")
agg <- do.call(rbind, lapply(split(ok, key), function(d) {
  tv <- truth[[d$target[[1L]]]]
  pr <- mean(d$covered, na.rm = TRUE)
  m <- sum(!is.na(d$covered))
  data.frame(
    n = d$n[[1L]], target = d$target[[1L]], truth = tv,
    mean_est = round(mean(d$est), 4), bias = round(mean(d$est) - tv, 4),
    rmse = round(sqrt(mean((d$est - tv)^2)), 4),
    wald_coverage = round(pr, 4), n_ok = m,
    mcse = round(sqrt(pr * (1 - pr) / max(m, 1)), 4),
    pdhess_rate = round(mean(d$pdhess), 4), stringsAsFactors = FALSE
  )
}))
write.csv(agg, file.path(out_dir, "tables", "rho12-recovery-summary.csv"), row.names = FALSE)
cat("=== rho12 ~ x recovery (n_rep=", n_rep, " per cell) ===\n", sep = "")
print(agg)
cat("fit/confint errors:", sum(is.na(fits$est)), "/", nrow(fits),
    "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
