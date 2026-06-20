# Gaussian spatial (coordinate-kernel) random-intercept recovery (native R/TMB).
# Fits y ~ x + spatial(1 | site, coords = coords), sigma ~ 1 and recovers the fixed
# effects, the spatial RE SD, and residual sigma. The model's spatial kernel is a
# FIXED exponential correlation exp(-dist / range) with range = median positive
# pairwise distance (unit diagonal; only the SD scaling is estimated, not the
# range). The DGP replicates that exponential kernel INDEPENDENTLY, so sd_spatial
# maps 1:1 to the reported SD. Headline for the "Structural dependencies" matrix
# point cell: the spatial RE SD. Boundary: native R/TMB, Gaussian, one spatial
# block with a fixed coordinate kernel, repeated records per site, complete data;
# POINT recovery + fixed-effect Wald coverage only (RE-SD interval calibration NOT
# claimed).
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 50L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-spatial-coords-recovery"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

b0 <- 0.3; b1 <- 0.5; sigma <- 0.4; sd_sp <- 0.5
master_seed <- 20260620L
n_sites <- c(20L, 40L); n_each <- 7L
truth <- c("fixef:mu:(Intercept)" = b0, "fixef:mu:x" = b1,
           "sd_spatial" = sd_sp, "sigma" = sigma)

# Exponential correlation kernel matching drm_spatial_coords_precision: unit
# diagonal, range = median positive pairwise distance.
exp_kernel <- function(coords) {
  D <- as.matrix(stats::dist(coords))
  pos <- D[D > 0]
  range <- stats::median(pos)
  if (!is.finite(range) || range <= 0) range <- max(pos)
  exp(-D / range)
}

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- data.frame(..., stringsAsFactors = FALSE)
t0 <- Sys.time(); ci <- 0L
for (n_site in n_sites) {
  ci <- ci + 1L
  set.seed(40000L + n_site)                          # fixed known coords per cell
  site_levels <- paste0("site_", seq_len(n_site))
  coords <- data.frame(x = stats::runif(n_site), y = stats::runif(n_site))
  rownames(coords) <- site_levels
  K <- exp_kernel(coords); cK <- t(chol(K))
  site <- rep(site_levels, each = n_each)
  xx <- rep(seq(-1, 1, length.out = n_each), n_site)
  for (r in seq_len(n_rep)) {
    set.seed(master_seed + ci * 100000L + r)
    u <- sd_sp * as.vector(cK %*% stats::rnorm(n_site)); names(u) <- site_levels
    y <- b0 + b1 * xx + u[site] + stats::rnorm(length(site), 0, sigma)
    dat <- data.frame(y = y, x = xx, site = site)
    fit <- tryCatch(drmTMB(bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ 1),
                           family = gaussian(), data = dat),
                    error = function(e) e)
    if (inherits(fit, "error")) {
      add(n_site = n_site, rep = r, target = "NA", est = NA_real_, covered = NA,
          pdhess = NA, status = "fit_error"); next
    }
    pdh <- isTRUE(fit$sdr$pdHess)
    co <- tryCatch(coef(fit, "mu"), error = function(e) NULL)
    sdp <- fit$sdpars$mu
    sig <- tryCatch(as.numeric(sigma(fit))[1L], error = function(e) NA_real_)
    cw <- tryCatch(suppressWarnings(confint(fit, parm = c("mu:(Intercept)", "mu:x"))),
                   error = function(e) NULL)
    sd_spatial <- {
      v <- sdp[grepl("spatial", names(sdp))]
      if (length(v) >= 1L) as.numeric(v[[1L]]) else NA_real_
    }
    est <- c(
      "fixef:mu:(Intercept)" = if (!is.null(co) && "(Intercept)" %in% names(co)) as.numeric(co[["(Intercept)"]]) else NA_real_,
      "fixef:mu:x" = if (!is.null(co) && "x" %in% names(co)) as.numeric(co[["x"]]) else NA_real_,
      "sd_spatial" = sd_spatial,
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
      add(n_site = n_site, rep = r, target = tg, est = est[[tg]],
          covered = if (tg %in% c("fixef:mu:(Intercept)", "fixef:mu:x")) cov_lookup(tg) else NA,
          pdhess = pdh, status = "ok")
    }
  }
}
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
fits <- do.call(rbind, rows)
write.csv(fits, file.path(out_dir, "tables", "spatial-recovery-fits.csv"), row.names = FALSE)

ok <- fits[!is.na(fits$est) & fits$target != "NA", , drop = FALSE]
key <- paste(ok$n_site, ok$target, sep = "|")
agg <- do.call(rbind, lapply(split(ok, key), function(d) {
  tv <- truth[[d$target[[1L]]]]
  cov_rows <- d$covered[!is.na(d$covered)]
  pr <- if (length(cov_rows)) mean(cov_rows) else NA_real_
  m <- length(cov_rows)
  data.frame(n_site = d$n_site[[1L]], target = d$target[[1L]], truth = tv,
             mean_est = round(mean(d$est), 4), bias = round(mean(d$est) - tv, 4),
             rel_bias = round((mean(d$est) - tv) / tv, 3),
             rmse = round(sqrt(mean((d$est - tv)^2)), 4),
             wald_coverage = if (is.na(pr)) NA_real_ else round(pr, 4),
             cov_mcse = if (is.na(pr)) NA_real_ else round(sqrt(pr * (1 - pr) / max(m, 1)), 4),
             pdhess_rate = round(mean(d$pdhess), 4), n_used = nrow(d),
             stringsAsFactors = FALSE)
}))
write.csv(agg, file.path(out_dir, "tables", "spatial-recovery-summary.csv"), row.names = FALSE)
cat("=== Gaussian spatial (coordinate kernel) recovery (n_rep=", n_rep, ") ===\n", sep = "")
print(agg, row.names = FALSE)
cat("fit errors:", sum(fits$target == "NA"), "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
