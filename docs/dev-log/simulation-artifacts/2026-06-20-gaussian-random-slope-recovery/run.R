# Gaussian random-slope recovery (native R/TMB). Fits y ~ x + (1 + x | id),
# sigma ~ 1 and recovers the fixed effects AND the random intercept/slope SDs.
# The headline quantity for the "Random slopes" matrix point cell is the
# random-SLOPE SD. Boundary: native R/TMB, Gaussian, one correlated random-slope
# block, complete data; point-recovery + fixed-effect Wald coverage only (RE-SD
# interval calibration is a separate, harder target and is NOT claimed here).
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 50L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-gaussian-random-slope-recovery"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

b0 <- 0.2; b1 <- 0.5; sigma <- 0.6
sd_int <- 0.5; sd_slope <- 0.35; rho <- 0.2
master_seed <- 20260620L
ngroups <- c(40L, 80L)
n_per_group <- 8L
truth <- c("fixef:mu:(Intercept)" = b0, "fixef:mu:x" = b1,
           "sd_int" = sd_int, "sd_slope" = sd_slope, "sigma" = sigma)

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
      add(n_group = n_group, rep = r, target = "NA", est = NA_real_,
          covered = NA, pdhess = NA, status = "fit_error"); next
    }
    pdh <- isTRUE(fit$sdr$pdHess)
    co <- tryCatch(coef(fit, "mu"), error = function(e) NULL)
    sdp <- fit$sdpars$mu
    sig <- tryCatch(as.numeric(sigma(fit))[1L], error = function(e) NA_real_)
    cw <- tryCatch(suppressWarnings(confint(fit, parm = c("mu:(Intercept)", "mu:x"))),
                   error = function(e) NULL)
    get_sd <- function(pat) {
      v <- sdp[grepl(pat, names(sdp))]
      if (length(v) >= 1L) as.numeric(v[[1L]]) else NA_real_
    }
    est <- c(
      "fixef:mu:(Intercept)" = if (!is.null(co) && "(Intercept)" %in% names(co)) as.numeric(co[["(Intercept)"]]) else NA_real_,
      "fixef:mu:x" = if (!is.null(co) && "x" %in% names(co)) as.numeric(co[["x"]]) else NA_real_,
      "sd_int" = get_sd(":\\(Intercept\\)$"),
      "sd_slope" = get_sd(":x$"),
      "sigma" = sig
    )
    cov_lookup <- function(tg) {
      if (is.null(cw)) return(NA)
      row <- cw[cw$parm == tg, , drop = FALSE]
      if (nrow(row) == 0L) return(NA)
      tv <- truth[[tg]]
      pdh && is.finite(row$lower[1L]) && is.finite(row$upper[1L]) &&
        tv >= row$lower[1L] && tv <= row$upper[1L]
    }
    for (tg in names(est)) {
      add(n_group = n_group, rep = r, target = tg, est = est[[tg]],
          covered = if (tg %in% c("fixef:mu:(Intercept)", "fixef:mu:x")) cov_lookup(tg) else NA,
          pdhess = pdh, status = "ok")
    }
  }
}
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
fits <- do.call(rbind, rows)
write.csv(fits, file.path(out_dir, "tables", "random-slope-fits.csv"), row.names = FALSE)

ok <- fits[!is.na(fits$est) & fits$target != "NA", , drop = FALSE]
key <- paste(ok$n_group, ok$target, sep = "|")
agg <- do.call(rbind, lapply(split(ok, key), function(d) {
  tv <- truth[[d$target[[1L]]]]
  cov_rows <- d$covered[!is.na(d$covered)]
  pr <- if (length(cov_rows)) mean(cov_rows) else NA_real_
  m <- length(cov_rows)
  data.frame(n_group = d$n_group[[1L]], target = d$target[[1L]], truth = tv,
             mean_est = round(mean(d$est), 4), bias = round(mean(d$est) - tv, 4),
             rel_bias = round((mean(d$est) - tv) / tv, 3),
             rmse = round(sqrt(mean((d$est - tv)^2)), 4),
             wald_coverage = if (is.na(pr)) NA_real_ else round(pr, 4),
             cov_mcse = if (is.na(pr)) NA_real_ else round(sqrt(pr * (1 - pr) / max(m, 1)), 4),
             pdhess_rate = round(mean(d$pdhess), 4),
             n_used = nrow(d), stringsAsFactors = FALSE)
}))
write.csv(agg, file.path(out_dir, "tables", "random-slope-recovery-summary.csv"), row.names = FALSE)
cat("=== Gaussian random-slope recovery (n_rep=", n_rep, ") ===\n", sep = "")
print(agg, row.names = FALSE)
cat("fit errors:", sum(fits$target == "NA"), "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
