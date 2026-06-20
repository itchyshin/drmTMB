# Non-Gaussian fixed-effect recovery + Wald-interval calibration (native R/TMB).
#
# For each one-response non-Gaussian family, fit a fixed-effect mu = b0 + b1*x
# model, recover the mu coefficients on their link scale, and measure Wald
# coverage. Boundary: native R/TMB, fixed-effect mu only, complete data; this
# characterises fixed-effect coefficient recovery + Wald calibration for the
# implemented one-response families. It does not address random/structured
# effects, the scale/shape parameters' intervals, profile/bootstrap intervals,
# bivariate/mixed responses, or the Julia bridge.
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 100L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-nongaussian-fe-recovery-calibration"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

b0 <- 0.5
b1 <- 0.4
master_seed <- 20260620L
ns <- c(300L, 600L)

# family-specific simulators (truth b0,b1 on the family's mu link scale)
simulate_one <- function(fam, n, x) {
  eta <- b0 + b1 * x
  if (fam == "poisson") {
    list(dat = data.frame(y = rpois(n, exp(eta)), x = x), form = bf(y ~ x),
         family = poisson())
  } else if (fam == "nbinom2") {
    list(dat = data.frame(y = rnbinom(n, size = 3, mu = exp(eta)), x = x),
         form = bf(y ~ x, sigma ~ 1), family = nbinom2())
  } else if (fam == "Gamma") {
    sh <- 4
    list(dat = data.frame(y = rgamma(n, shape = sh, scale = exp(eta) / sh), x = x),
         form = bf(y ~ x, sigma ~ 1), family = Gamma(link = "log"))
  } else if (fam == "lognormal") {
    list(dat = data.frame(y = exp(rnorm(n, eta, 0.5)), x = x),
         form = bf(y ~ x, sigma ~ 1), family = lognormal())
  } else if (fam == "beta") {
    mu <- plogis(eta)
    phi <- 8
    list(dat = data.frame(y = rbeta(n, mu * phi, (1 - mu) * phi), x = x),
         form = bf(y ~ x, sigma ~ 1), family = beta())
  } else if (fam == "student") {
    nu <- 6
    sc <- 1 / sqrt(nu / (nu - 2))
    list(dat = data.frame(y = eta + sc * rt(n, nu), x = x),
         form = bf(y ~ x, sigma ~ 1, nu ~ 1), family = student())
  }
}

families <- c("poisson", "nbinom2", "Gamma", "lognormal", "beta", "student")
targets <- c("mu:(Intercept)", "mu:x")
truth <- c("fixef:mu:(Intercept)" = b0, "fixef:mu:x" = b1)

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- data.frame(..., stringsAsFactors = FALSE)
t0 <- Sys.time()
ci <- 0L
for (fam in families) {
  for (n in ns) {
    ci <- ci + 1L
    for (r in seq_len(n_rep)) {
      set.seed(master_seed + ci * 100000L + r)
      x <- rnorm(n)
      spec <- simulate_one(fam, n, x)
      fit <- tryCatch(drmTMB(spec$form, family = spec$family, data = spec$dat),
                      error = function(e) e)
      if (inherits(fit, "error")) {
        add(family = fam, n = n, rep = r, target = "NA", est = NA_real_,
            covered = NA, width = NA_real_, pdhess = NA, status = "fit_error")
        next
      }
      pdh <- isTRUE(fit$sdr$pdHess)
      co <- tryCatch(coef(fit, "mu"), error = function(e) NULL)
      cw <- tryCatch(suppressWarnings(confint(fit, parm = targets)),
                     error = function(e) e)
      if (inherits(cw, "error") || is.null(co)) {
        add(family = fam, n = n, rep = r, target = "NA", est = NA_real_,
            covered = NA, width = NA_real_, pdhess = pdh, status = "confint_error")
        next
      }
      for (tg in unique(cw$parm)) {
        row <- cw[cw$parm == tg, , drop = FALSE][1L, ]
        tv <- truth[[row$parm]]
        nm <- sub("^fixef:mu:", "", row$parm)
        est <- if (nm %in% names(co)) as.numeric(co[[nm]]) else NA_real_
        cov <- pdh && is.finite(row$lower) && is.finite(row$upper) &&
          tv >= row$lower && tv <= row$upper
        add(family = fam, n = n, rep = r, target = row$parm, est = est,
            covered = cov, width = row$upper - row$lower, pdhess = pdh,
            status = as.character(row$conf.status))
      }
    }
  }
}
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
fits <- do.call(rbind, rows)
write.csv(fits, file.path(out_dir, "tables", "nongaussian-fe-fits.csv"), row.names = FALSE)

ok <- fits[!is.na(fits$est), , drop = FALSE]
key <- paste(ok$family, ok$n, ok$target, sep = "|")
agg <- do.call(rbind, lapply(split(ok, key), function(d) {
  tv <- truth[[d$target[[1L]]]]
  pr <- mean(d$covered, na.rm = TRUE)
  m <- sum(!is.na(d$covered))
  data.frame(family = d$family[[1L]], n = d$n[[1L]], target = d$target[[1L]],
             bias = round(mean(d$est) - tv, 4), rmse = round(sqrt(mean((d$est - tv)^2)), 4),
             wald_coverage = round(pr, 4), n_ok = m,
             mcse = round(sqrt(pr * (1 - pr) / max(m, 1)), 4),
             pdhess_rate = round(mean(d$pdhess), 4), stringsAsFactors = FALSE)
}))
write.csv(agg, file.path(out_dir, "tables", "nongaussian-fe-coverage-summary.csv"), row.names = FALSE)
cat("=== non-Gaussian FE recovery + Wald coverage (n_rep=", n_rep, ") ===\n", sep = "")
print(agg, row.names = FALSE)
cat("fit/confint errors:", sum(is.na(fits$est)), "/", nrow(fits),
    "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
