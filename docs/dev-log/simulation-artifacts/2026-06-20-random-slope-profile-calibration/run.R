# Gaussian random-slope fixed-effect PROFILE-interval calibration (native R/TMB).
#
# Same DGP as the random-slope recovery (2026-06-20-gaussian-random-slope-recovery):
# bf(y ~ x + (1 + x | id), sigma ~ 1). Measures PROFILE-likelihood interval coverage
# for the two FIXED-effect mu coefficients (the random-effect SD intervals are a
# separate, harder target and are NOT addressed here), with Wald alongside.
# Coefficient profiles use the fast endpoint solver via profile_engine="auto".
# Boundary: native R/TMB, Gaussian, one correlated random-slope block; fixed-effect
# profile calibration only. Random-effect SD interval calibration is not claimed.
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 100L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-random-slope-profile-calibration"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

b0 <- 0.2; b1 <- 0.5; sigma <- 0.6
sd_int <- 0.5; sd_slope <- 0.35; rho <- 0.2
master_seed <- 20260620L
ngroups <- c(40L, 80L)
n_per_group <- 8L
targets <- c("mu:(Intercept)", "mu:x")
truth <- c("fixef:mu:(Intercept)" = b0, "fixef:mu:x" = b1)

sim_one <- function(n_group) {
  S <- matrix(c(sd_int^2, rho * sd_int * sd_slope,
                rho * sd_int * sd_slope, sd_slope^2), 2)
  U <- matrix(stats::rnorm(n_group * 2L), ncol = 2L) %*% chol(S)
  id <- factor(rep(seq_len(n_group), each = n_per_group))
  x <- rep(seq(-1, 1, length.out = n_per_group), times = n_group)
  mu <- b0 + b1 * x + U[id, 1L] + U[id, 2L] * x
  data.frame(y = stats::rnorm(length(mu), mu, sigma), x = x, id = id)
}

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- data.frame(..., stringsAsFactors = FALSE)
t0 <- Sys.time(); ci <- 0L
for (n_group in ngroups) {
  ci <- ci + 1L
  for (r in seq_len(n_rep)) {
    set.seed(master_seed + ci * 100000L + r)
    dat <- sim_one(n_group)
    fit <- tryCatch(drmTMB(bf(y ~ x + (1 + x | id), sigma ~ 1),
                           family = gaussian(), data = dat),
                    error = function(e) e)
    if (inherits(fit, "error")) {
      add(n_group = n_group, rep = r, method = "NA", target = "NA",
          covered = NA, width = NA_real_, pdhess = NA, status = "fit_error"); next
    }
    pdh <- isTRUE(fit$sdr$pdHess)
    record <- function(method) {
      tab <- tryCatch(suppressWarnings(confint(fit, parm = targets, method = method)),
                      error = function(e) e)
      if (inherits(tab, "error") || is.null(tab)) {
        add(n_group = n_group, rep = r, method = method, target = "NA",
            covered = NA, width = NA_real_, pdhess = pdh,
            status = paste0(method, "_error")); return(invisible())
      }
      for (i in seq_len(nrow(tab))) {
        row <- tab[i, , drop = FALSE]; tg <- as.character(row$parm)
        if (!tg %in% names(truth)) next
        tv <- truth[[tg]]; ok_ci <- is.finite(row$lower) && is.finite(row$upper)
        cov <- pdh && ok_ci && tv >= row$lower && tv <= row$upper
        add(n_group = n_group, rep = r, method = method,
            target = sub("^fixef:", "", tg),
            covered = if (ok_ci) cov else NA,
            width = if (ok_ci) row$upper - row$lower else NA_real_,
            pdhess = pdh, status = as.character(row$conf.status))
      }
    }
    record("profile"); record("wald")
  }
}
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
fits <- do.call(rbind, rows)
write.csv(fits, file.path(out_dir, "tables", "random-slope-profile-fits.csv"), row.names = FALSE)

ok <- fits[fits$target != "NA", , drop = FALSE]
key <- paste(ok$n_group, ok$method, ok$target, sep = "|")
agg <- do.call(rbind, lapply(split(ok, key), function(d) {
  cov_rows <- d$covered[!is.na(d$covered)]
  pr <- if (length(cov_rows)) mean(cov_rows) else NA_real_
  m <- length(cov_rows)
  data.frame(n_group = d$n_group[[1L]], method = d$method[[1L]], target = d$target[[1L]],
             coverage = if (is.na(pr)) NA_real_ else round(pr, 4),
             mcse = if (is.na(pr)) NA_real_ else round(sqrt(pr * (1 - pr) / max(m, 1)), 4),
             mean_width = round(mean(d$width, na.rm = TRUE), 4),
             n_ok = m, ci_fail_rate = round(mean(is.na(d$covered)), 4),
             pdhess_rate = round(mean(d$pdhess, na.rm = TRUE), 4),
             stringsAsFactors = FALSE)
}))
agg <- agg[order(agg$n_group, agg$target, agg$method), ]
write.csv(agg, file.path(out_dir, "tables", "random-slope-profile-summary.csv"), row.names = FALSE)
cat("=== Random-slope fixed-effect PROFILE vs WALD calibration (n_rep=", n_rep, ") ===\n", sep = "")
print(agg, row.names = FALSE)
cat("fit errors:", sum(fits$target == "NA" & fits$status == "fit_error"),
    "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
