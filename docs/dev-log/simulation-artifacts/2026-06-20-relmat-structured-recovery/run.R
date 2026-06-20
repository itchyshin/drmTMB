# Gaussian relmat (known-relatedness) random-intercept recovery (native R/TMB).
# Fits y ~ x + relmat(1 | id, Q = Q), sigma ~ 1 with a known AR(1) relatedness
# matrix K (Q = solve(K)) and recovers the fixed effects, the relmat random-effect
# SD, and residual sigma. Headline quantity for the "Structural dependencies"
# matrix point cell: the known-relatedness RE SD. Boundary: native R/TMB, Gaussian,
# one relmat block with a user-supplied known K, complete data; POINT recovery +
# fixed-effect Wald coverage only (RE-SD interval calibration NOT claimed).
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 50L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-relmat-structured-recovery"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

b0 <- 0.25; b1 <- 0.45; sigma <- 0.4; sd_K <- 0.6
master_seed <- 20260620L
n_ids <- c(40L, 80L); n_each <- 6L
truth <- c("fixef:mu:(Intercept)" = b0, "fixef:mu:x" = b1,
           "sd_relmat" = sd_K, "sigma" = sigma)

make_K <- function(n_id) {
  id_levels <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.5^abs(i - j))  # AR(1) corr, PD
  dimnames(K) <- list(id_levels, id_levels)
  K
}

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- data.frame(..., stringsAsFactors = FALSE)
t0 <- Sys.time(); ci <- 0L
for (n_id in n_ids) {
  ci <- ci + 1L
  K <- make_K(n_id); Q <- solve(K); cK <- t(chol(K))
  id_levels <- rownames(K)
  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  for (r in seq_len(n_rep)) {
    set.seed(master_seed + ci * 100000L + r)
    u <- sd_K * as.vector(cK %*% stats::rnorm(n_id)); names(u) <- id_levels
    y <- b0 + b1 * x + u[id] + stats::rnorm(length(id), 0, sigma)
    dat <- data.frame(y = y, x = x, id = id)
    fit <- tryCatch(drmTMB(bf(y ~ x + relmat(1 | id, Q = Q), sigma ~ 1),
                           family = gaussian(), data = dat),
                    error = function(e) e)
    if (inherits(fit, "error")) {
      add(n_id = n_id, rep = r, target = "NA", est = NA_real_, covered = NA,
          pdhess = NA, status = "fit_error"); next
    }
    pdh <- isTRUE(fit$sdr$pdHess)
    co <- tryCatch(coef(fit, "mu"), error = function(e) NULL)
    sdp <- fit$sdpars$mu
    sig <- tryCatch(as.numeric(sigma(fit))[1L], error = function(e) NA_real_)
    cw <- tryCatch(suppressWarnings(confint(fit, parm = c("mu:(Intercept)", "mu:x"))),
                   error = function(e) NULL)
    sd_relmat <- {
      v <- sdp[grepl("relmat", names(sdp))]
      if (length(v) >= 1L) as.numeric(v[[1L]]) else NA_real_
    }
    est <- c(
      "fixef:mu:(Intercept)" = if (!is.null(co) && "(Intercept)" %in% names(co)) as.numeric(co[["(Intercept)"]]) else NA_real_,
      "fixef:mu:x" = if (!is.null(co) && "x" %in% names(co)) as.numeric(co[["x"]]) else NA_real_,
      "sd_relmat" = sd_relmat,
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
      add(n_id = n_id, rep = r, target = tg, est = est[[tg]],
          covered = if (tg %in% c("fixef:mu:(Intercept)", "fixef:mu:x")) cov_lookup(tg) else NA,
          pdhess = pdh, status = "ok")
    }
  }
}
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
fits <- do.call(rbind, rows)
write.csv(fits, file.path(out_dir, "tables", "relmat-recovery-fits.csv"), row.names = FALSE)

ok <- fits[!is.na(fits$est) & fits$target != "NA", , drop = FALSE]
key <- paste(ok$n_id, ok$target, sep = "|")
agg <- do.call(rbind, lapply(split(ok, key), function(d) {
  tv <- truth[[d$target[[1L]]]]
  cov_rows <- d$covered[!is.na(d$covered)]
  pr <- if (length(cov_rows)) mean(cov_rows) else NA_real_
  m <- length(cov_rows)
  data.frame(n_id = d$n_id[[1L]], target = d$target[[1L]], truth = tv,
             mean_est = round(mean(d$est), 4), bias = round(mean(d$est) - tv, 4),
             rel_bias = round((mean(d$est) - tv) / tv, 3),
             rmse = round(sqrt(mean((d$est - tv)^2)), 4),
             wald_coverage = if (is.na(pr)) NA_real_ else round(pr, 4),
             cov_mcse = if (is.na(pr)) NA_real_ else round(sqrt(pr * (1 - pr) / max(m, 1)), 4),
             pdhess_rate = round(mean(d$pdhess), 4), n_used = nrow(d),
             stringsAsFactors = FALSE)
}))
write.csv(agg, file.path(out_dir, "tables", "relmat-recovery-summary.csv"), row.names = FALSE)
cat("=== Gaussian relmat (known-K) recovery (n_rep=", n_rep, ") ===\n", sep = "")
print(agg, row.names = FALSE)
cat("fit errors:", sum(fits$target == "NA"), "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
