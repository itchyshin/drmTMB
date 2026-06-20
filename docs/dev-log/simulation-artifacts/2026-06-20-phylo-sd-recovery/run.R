# Gaussian phylogenetic random-intercept SD recovery (native R/TMB). Fits
# y ~ x + phylo(1 | species, tree = tree), sigma ~ 1 with a fixed known tree per
# cell and recovers the fixed effects, the phylogenetic RE SD, and residual sigma.
# Headline quantity: the phylogenetic SD. Boundary: native R/TMB, Gaussian, one
# phylo block, known tree, one obs/species, complete data; POINT recovery +
# fixed-effect Wald coverage only (RE-SD interval calibration NOT claimed).
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 50L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-phylo-sd-recovery"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

b0 <- 0.3; b1 <- 0.5; sigma <- 0.4; sd_phy <- 0.7
master_seed <- 20260620L
n_sps <- c(60L, 120L, 240L)
truth <- c("fixef:mu:(Intercept)" = b0, "fixef:mu:x" = b1,
           "sd_phylo" = sd_phy, "sigma" = sigma)

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- data.frame(..., stringsAsFactors = FALSE)
t0 <- Sys.time(); ci <- 0L
for (n_sp in n_sps) {
  ci <- ci + 1L
  set.seed(10000L + n_sp)                       # fixed known tree per cell
  tree <- ape::rcoal(n_sp); tree$tip.label <- paste0("sp", seq_len(n_sp))
  Cc <- stats::cov2cor(ape::vcv(tree)); cC <- t(chol(Cc))
  tips <- tree$tip.label
  for (r in seq_len(n_rep)) {
    set.seed(master_seed + ci * 100000L + r)
    u <- sd_phy * as.vector(cC %*% stats::rnorm(n_sp)); names(u) <- tips
    x <- stats::rnorm(n_sp)
    y <- b0 + b1 * x + u[tips] + stats::rnorm(n_sp, 0, sigma)
    dat <- data.frame(y = y, x = x, species = tips)
    fit <- tryCatch(drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
                           family = gaussian(), data = dat),
                    error = function(e) e)
    if (inherits(fit, "error")) {
      add(n_sp = n_sp, rep = r, target = "NA", est = NA_real_, covered = NA,
          pdhess = NA, status = "fit_error"); next
    }
    pdh <- isTRUE(fit$sdr$pdHess)
    co <- tryCatch(coef(fit, "mu"), error = function(e) NULL)
    sdp <- fit$sdpars$mu
    sig <- tryCatch(as.numeric(sigma(fit))[1L], error = function(e) NA_real_)
    cw <- tryCatch(suppressWarnings(confint(fit, parm = c("mu:(Intercept)", "mu:x"))),
                   error = function(e) NULL)
    sd_phylo <- {
      v <- sdp[grepl("phylo", names(sdp))]
      if (length(v) >= 1L) as.numeric(v[[1L]]) else NA_real_
    }
    est <- c(
      "fixef:mu:(Intercept)" = if (!is.null(co) && "(Intercept)" %in% names(co)) as.numeric(co[["(Intercept)"]]) else NA_real_,
      "fixef:mu:x" = if (!is.null(co) && "x" %in% names(co)) as.numeric(co[["x"]]) else NA_real_,
      "sd_phylo" = sd_phylo,
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
      add(n_sp = n_sp, rep = r, target = tg, est = est[[tg]],
          covered = if (tg %in% c("fixef:mu:(Intercept)", "fixef:mu:x")) cov_lookup(tg) else NA,
          pdhess = pdh, status = "ok")
    }
  }
}
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
fits <- do.call(rbind, rows)
write.csv(fits, file.path(out_dir, "tables", "phylo-sd-recovery-fits.csv"), row.names = FALSE)

ok <- fits[!is.na(fits$est) & fits$target != "NA", , drop = FALSE]
key <- paste(ok$n_sp, ok$target, sep = "|")
agg <- do.call(rbind, lapply(split(ok, key), function(d) {
  tv <- truth[[d$target[[1L]]]]
  cov_rows <- d$covered[!is.na(d$covered)]
  pr <- if (length(cov_rows)) mean(cov_rows) else NA_real_
  m <- length(cov_rows)
  data.frame(n_sp = d$n_sp[[1L]], target = d$target[[1L]], truth = tv,
             mean_est = round(mean(d$est), 4), bias = round(mean(d$est) - tv, 4),
             rel_bias = round((mean(d$est) - tv) / tv, 3),
             rmse = round(sqrt(mean((d$est - tv)^2)), 4),
             wald_coverage = if (is.na(pr)) NA_real_ else round(pr, 4),
             cov_mcse = if (is.na(pr)) NA_real_ else round(sqrt(pr * (1 - pr) / max(m, 1)), 4),
             pdhess_rate = round(mean(d$pdhess), 4), n_used = nrow(d),
             stringsAsFactors = FALSE)
}))
write.csv(agg, file.path(out_dir, "tables", "phylo-sd-recovery-summary.csv"), row.names = FALSE)
cat("=== Gaussian phylo SD recovery (n_rep=", n_rep, ") ===\n", sep = "")
print(agg, row.names = FALSE)
cat("fit errors:", sum(fits$target == "NA"), "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
