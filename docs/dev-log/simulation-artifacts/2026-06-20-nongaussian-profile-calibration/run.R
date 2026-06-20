# Non-Gaussian fixed-effect mu PROFILE-interval calibration (native R/TMB).
#
# For each implemented one-response non-Gaussian family, fit a fixed-effect
# mu = b0 + b1*x model and measure PROFILE-likelihood interval coverage for the two
# mu coefficients (on their link scale), with Wald computed alongside. Coefficient
# profiles now use the fast endpoint solver via profile_engine = "auto" (feat: the
# endpoint engine handles fixed-effect coefficients), which makes this calibration
# tractable. Boundary: native R/TMB, fixed-effect mu only, complete data;
# characterises profile-interval calibration for the implemented one-response
# families. Not random/structured effects, scale/shape intervals, or the bridge.
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 100L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-nongaussian-profile-calibration"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

b0 <- 0.5; b1 <- 0.4
master_seed <- 20260620L
ns <- c(300L, 600L)

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
    mu <- plogis(eta); phi <- 8
    list(dat = data.frame(y = rbeta(n, mu * phi, (1 - mu) * phi), x = x),
         form = bf(y ~ x, sigma ~ 1), family = beta())
  } else if (fam == "student") {
    nu <- 6; sc <- 1 / sqrt(nu / (nu - 2))
    list(dat = data.frame(y = eta + sc * rt(n, nu), x = x),
         form = bf(y ~ x, sigma ~ 1, nu ~ 1), family = student())
  }
}

families <- c("poisson", "nbinom2", "Gamma", "lognormal", "beta", "student")
targets <- c("mu:(Intercept)", "mu:x")
truth <- c("fixef:mu:(Intercept)" = b0, "fixef:mu:x" = b1)

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- data.frame(..., stringsAsFactors = FALSE)
t0 <- Sys.time(); ci <- 0L
for (fam in families) {
  for (n in ns) {
    ci <- ci + 1L
    for (r in seq_len(n_rep)) {
      set.seed(master_seed + ci * 100000L + r)
      x <- rnorm(n)
      sim <- simulate_one(fam, n, x)
      fit <- tryCatch(drmTMB(sim$form, family = sim$family, data = sim$dat),
                      error = function(e) e)
      if (inherits(fit, "error")) {
        add(family = fam, n = n, rep = r, method = "NA", target = "NA",
            covered = NA, width = NA_real_, pdhess = NA, status = "fit_error"); next
      }
      pdh <- isTRUE(fit$sdr$pdHess)
      record <- function(method) {
        tab <- tryCatch(suppressWarnings(confint(fit, parm = targets, method = method)),
                        error = function(e) e)
        if (inherits(tab, "error") || is.null(tab)) {
          add(family = fam, n = n, rep = r, method = method, target = "NA",
              covered = NA, width = NA_real_, pdhess = pdh,
              status = paste0(method, "_error")); return(invisible())
        }
        for (i in seq_len(nrow(tab))) {
          row <- tab[i, , drop = FALSE]; tg <- as.character(row$parm)
          if (!tg %in% names(truth)) next
          tv <- truth[[tg]]; ok_ci <- is.finite(row$lower) && is.finite(row$upper)
          cov <- pdh && ok_ci && tv >= row$lower && tv <= row$upper
          add(family = fam, n = n, rep = r, method = method,
              target = sub("^fixef:", "", tg),
              covered = if (ok_ci) cov else NA,
              width = if (ok_ci) row$upper - row$lower else NA_real_,
              pdhess = pdh, status = as.character(row$conf.status))
        }
      }
      record("profile"); record("wald")
    }
  }
}
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
fits <- do.call(rbind, rows)
write.csv(fits, file.path(out_dir, "tables", "nongaussian-profile-fits.csv"), row.names = FALSE)

ok <- fits[fits$target != "NA", , drop = FALSE]
key <- paste(ok$family, ok$n, ok$method, ok$target, sep = "|")
agg <- do.call(rbind, lapply(split(ok, key), function(d) {
  cov_rows <- d$covered[!is.na(d$covered)]
  pr <- if (length(cov_rows)) mean(cov_rows) else NA_real_
  m <- length(cov_rows)
  data.frame(family = d$family[[1L]], n = d$n[[1L]], method = d$method[[1L]],
             target = d$target[[1L]],
             coverage = if (is.na(pr)) NA_real_ else round(pr, 4),
             mcse = if (is.na(pr)) NA_real_ else round(sqrt(pr * (1 - pr) / max(m, 1)), 4),
             mean_width = round(mean(d$width, na.rm = TRUE), 4),
             n_ok = m, ci_fail_rate = round(mean(is.na(d$covered)), 4),
             pdhess_rate = round(mean(d$pdhess, na.rm = TRUE), 4),
             stringsAsFactors = FALSE)
}))
agg <- agg[order(agg$family, agg$n, agg$target, agg$method), ]
write.csv(agg, file.path(out_dir, "tables", "nongaussian-profile-summary.csv"), row.names = FALSE)
cat("=== Non-Gaussian mu PROFILE vs WALD calibration (n_rep=", n_rep, ") ===\n", sep = "")
print(agg, row.names = FALSE)
cat("fit errors:", sum(fits$target == "NA" & fits$status == "fit_error"),
    "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
