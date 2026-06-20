# rho12 ~ x PROFILE-interval calibration (native R/TMB, fixed-effect bivariate).
#
# Same DGP as the rho12 ~ x recovery (2026-06-20-rho12-predictor-recovery): a
# bivariate Gaussian with predictor-dependent residual correlation
#   bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~ x),
# rho12_i = 0.999999 * tanh(a0 + a1 * x_i). Here we measure the empirical coverage
# and width of PROFILE-likelihood confidence intervals (confint(method="profile"))
# for the two rho12 coefficients, with Wald intervals computed alongside for
# comparison, and we track profile-interval failures (conf.status) honestly.
# Boundary: native R/TMB, fixed-effect only; profile calibration for the
# predictor-dependent rho12 coefficients (the lead novelty), not random-effect,
# structured, or bridge rho12.
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 100L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-rho12-profile-calibration"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

a0 <- 0.4; a1 <- 0.5
b_mu1 <- c(0.2, 0.6); b_mu2 <- c(-0.1, 0.4); s1 <- 1.0; s2 <- 1.0
targets <- c("rho12:(Intercept)", "rho12:x")            # short form for the parm arg
truth <- c("fixef:rho12:(Intercept)" = a0, "fixef:rho12:x" = a1)  # confint returns long form
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
    e1 <- rnorm(n); e2 <- rho * e1 + sqrt(pmax(1 - rho^2, 0)) * rnorm(n)
    dat <- data.frame(y1 = m1 + s1 * e1, y2 = m2 + s2 * e2, x = x)
    form <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~x)
    fit <- tryCatch(drmTMB(form, family = biv_gaussian(), data = dat), error = function(e) e)
    if (inherits(fit, "error")) {
      add(cell = ci, n = n, rep = r, method = "NA", target = "NA", covered = NA,
          width = NA_real_, pdhess = NA, status = "fit_error"); next
    }
    pdh <- isTRUE(fit$sdr$pdHess)
    pw <- tryCatch(suppressWarnings(confint(fit, parm = targets, method = "profile")),
                   error = function(e) e)
    wl <- tryCatch(suppressWarnings(confint(fit, parm = targets, method = "wald")),
                   error = function(e) e)
    record <- function(tab, method) {
      if (inherits(tab, "error") || is.null(tab)) {
        add(cell = ci, n = n, rep = r, method = method, target = "NA", covered = NA,
            width = NA_real_, pdhess = pdh, status = paste0(method, "_error")); return(invisible())
      }
      for (i in seq_len(nrow(tab))) {
        row <- tab[i, , drop = FALSE]
        tg <- as.character(row$parm)               # long form e.g. fixef:rho12:x
        if (!tg %in% names(truth)) next
        tv <- truth[[tg]]
        ok_ci <- is.finite(row$lower) && is.finite(row$upper)
        cov <- pdh && ok_ci && tv >= row$lower && tv <= row$upper
        add(cell = ci, n = n, rep = r, method = method, target = sub("^fixef:", "", tg),
            covered = if (ok_ci) cov else NA,
            width = if (ok_ci) row$upper - row$lower else NA_real_,
            pdhess = pdh, status = as.character(row$conf.status))
      }
    }
    record(pw, "profile"); record(wl, "wald")
  }
}
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
fits <- do.call(rbind, rows)
write.csv(fits, file.path(out_dir, "tables", "rho12-profile-calibration-fits.csv"), row.names = FALSE)

ok <- fits[fits$target != "NA", , drop = FALSE]
key <- paste(ok$n, ok$method, ok$target, sep = "|")
agg <- do.call(rbind, lapply(split(ok, key), function(d) {
  cov_rows <- d$covered[!is.na(d$covered)]
  pr <- if (length(cov_rows)) mean(cov_rows) else NA_real_
  m <- length(cov_rows)
  data.frame(
    n = d$n[[1L]], method = d$method[[1L]], target = d$target[[1L]],
    coverage = if (is.na(pr)) NA_real_ else round(pr, 4),
    mcse = if (is.na(pr)) NA_real_ else round(sqrt(pr * (1 - pr) / max(m, 1)), 4),
    mean_width = round(mean(d$width, na.rm = TRUE), 4),
    n_ok = m, n_attempt = nrow(d),
    ci_fail_rate = round(mean(is.na(d$covered)), 4),
    pdhess_rate = round(mean(d$pdhess, na.rm = TRUE), 4),
    stringsAsFactors = FALSE
  )
}))
agg <- agg[order(agg$n, agg$target, agg$method), ]
write.csv(agg, file.path(out_dir, "tables", "rho12-profile-calibration-summary.csv"), row.names = FALSE)
cat("=== rho12 ~ x PROFILE vs WALD calibration (n_rep=", n_rep, " per cell) ===\n", sep = "")
print(agg, row.names = FALSE)
cat("fit errors:", sum(fits$target == "NA" & fits$status == "fit_error"),
    "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
