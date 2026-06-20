# Gaussian animal-model (pedigree additive-genetic) random-intercept recovery
# (native R/TMB). Fits y ~ x + animal(1 | id, A = A), sigma ~ 1 with a genuine
# pedigree-derived numerator relationship matrix A (Henderson's recursive NRM) and
# recovers the fixed effects, the additive-genetic RE SD, and residual sigma.
# Headline for the "Structural dependencies" matrix point cell: the animal RE SD.
# Boundary: native R/TMB, Gaussian, one animal block with a known pedigree A,
# repeated records per individual, complete data; POINT recovery + fixed-effect
# Wald coverage only (RE-SD interval calibration NOT claimed).
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 50L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-animal-pedigree-recovery"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

b0 <- 0.25; b1 <- 0.45; sigma <- 0.4; sd_a <- 0.6
master_seed <- 20260620L
n_ids <- c(40L, 80L); n_each <- 6L
truth <- c("fixef:mu:(Intercept)" = b0, "fixef:mu:x" = b1,
           "sd_animal" = sd_a, "sigma" = sigma)

# Build a pedigree (founders, then offspring with two distinct earlier parents) and
# the numerator relationship matrix A via Henderson's recursive method (parents
# precede offspring). Non-inbred founders have A[i,i] = 1, so sd_a is the
# additive-genetic SD on the A scale (the quantity the animal model reports).
make_pedigree_A <- function(n_id) {
  n_founder <- max(4L, n_id %/% 4L)
  sire <- dam <- rep(NA_integer_, n_id)
  for (i in seq_len(n_id)) {
    if (i > n_founder) {
      par <- sample.int(i - 1L, 2L)
      sire[i] <- par[[1L]]; dam[i] <- par[[2L]]
    }
  }
  A <- matrix(0, n_id, n_id)
  for (i in seq_len(n_id)) {
    s <- sire[i]; d <- dam[i]
    if (!is.na(s) && !is.na(d)) {
      A[i, i] <- 1 + 0.5 * A[s, d]
      for (j in seq_len(i - 1L)) A[i, j] <- A[j, i] <- 0.5 * (A[j, s] + A[j, d])
    } else {
      A[i, i] <- 1
    }
  }
  id_levels <- paste0("id", seq_len(n_id))
  dimnames(A) <- list(id_levels, id_levels)
  A
}

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- data.frame(..., stringsAsFactors = FALSE)
t0 <- Sys.time(); ci <- 0L
for (n_id in n_ids) {
  ci <- ci + 1L
  set.seed(30000L + n_id)                          # fixed known pedigree per cell
  A <- make_pedigree_A(n_id); cA <- t(chol(A))
  id_levels <- rownames(A)
  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  for (r in seq_len(n_rep)) {
    set.seed(master_seed + ci * 100000L + r)
    u <- sd_a * as.vector(cA %*% stats::rnorm(n_id)); names(u) <- id_levels
    y <- b0 + b1 * x + u[id] + stats::rnorm(length(id), 0, sigma)
    dat <- data.frame(y = y, x = x, id = id)
    fit <- tryCatch(drmTMB(bf(y ~ x + animal(1 | id, A = A), sigma ~ 1),
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
    sd_animal <- {
      v <- sdp[grepl("animal", names(sdp))]
      if (length(v) >= 1L) as.numeric(v[[1L]]) else NA_real_
    }
    est <- c(
      "fixef:mu:(Intercept)" = if (!is.null(co) && "(Intercept)" %in% names(co)) as.numeric(co[["(Intercept)"]]) else NA_real_,
      "fixef:mu:x" = if (!is.null(co) && "x" %in% names(co)) as.numeric(co[["x"]]) else NA_real_,
      "sd_animal" = sd_animal,
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
write.csv(fits, file.path(out_dir, "tables", "animal-recovery-fits.csv"), row.names = FALSE)

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
write.csv(agg, file.path(out_dir, "tables", "animal-recovery-summary.csv"), row.names = FALSE)
cat("=== Gaussian animal (pedigree NRM) recovery (n_rep=", n_rep, ") ===\n", sep = "")
print(agg, row.names = FALSE)
cat("fit errors:", sum(fits$target == "NA"), "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
