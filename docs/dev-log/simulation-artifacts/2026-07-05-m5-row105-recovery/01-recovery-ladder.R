# M5 row-105 crossed recovery ladder (STREAMING; one row per fit, flushed
# the instant each fit finishes -- NOT after the whole batch).
#
# Q: does the SIMULTANEOUS two-provider structured NB2 mean
#   y ~ x + spatial(1 | site, coords) + relmat(1 | id, Q)
# recover sd_spatial, sd_relmat, sigma_nb2 honestly on a genuinely CROSSED
# site x id design, with bias/rmse FALLING as #levels rises (seed-averaged)?
#
# Design: 3 crossed rungs (n_lvl = n_site = n_id in {10, 20, 30}, n_rep
# adjusted to hold nrow in the hundreds-low-thousands) x >=30 seeds each,
# PLUS one small non-crossed CONTROL rung (n_lvl = 10, few seeds) that
# demonstrates the confounding the crossed design is designed to avoid.
#
# Usage:
#   Rscript 01-recovery-ladder.R <n_lvl_csv> <n_seeds> <include_control> <n_cores>
# Defaults: n_lvl = 10,20,30 ; n_seeds = 30 ; include_control = 1 ; n_cores = 20
#
# Streaming discipline: dispatch jobs onto forked workers via mcparallel(),
# then poll with mccollect(wait = FALSE) so EACH job's row is written and
# flushed to 01-results.tsv as soon as that job's worker exits -- a
# stop/crash mid-batch leaves every already-finished fit on disk. A
# heartbeat line is also appended to 01-recovery.log per finished job.

suppressMessages(devtools::load_all(".", quiet = TRUE))
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

art <- "docs/dev-log/simulation-artifacts/2026-07-05-m5-row105-recovery"
source(file.path(art, "00-helpers.R"))

argv <- commandArgs(trailingOnly = TRUE)
n_lvl_grid <- if (length(argv) >= 1L) {
  as.integer(strsplit(argv[[1L]], ",", fixed = TRUE)[[1L]])
} else c(10L, 20L, 30L)
n_seeds <- if (length(argv) >= 2L) as.integer(argv[[2L]]) else 30L
include_control <- if (length(argv) >= 3L) as.logical(as.integer(argv[[3L]])) else TRUE
n_cores <- if (length(argv) >= 4L) as.integer(argv[[4L]]) else 20L

# n_rep chosen per rung to hold nrow roughly in [400, 900].
n_rep_for <- function(n_lvl) {
  if (n_lvl <= 10L) 4L else if (n_lvl <= 20L) 2L else 1L
}

tsv <- file.path(art, "01-results.tsv")
logf <- file.path(art, "01-recovery.log")
hb <- function(...) {
  msg <- sprintf(...)
  cat(msg, file = logf, append = TRUE)
  cat(msg)
  flush(stdout())
}

cols <- c(
  "rung", "crossed", "n_lvl", "n_rep", "seed", "nobs", "n_pairs",
  "n_possible_pairs", "conv", "pdHess", "se_finite",
  "sd_spatial_hat", "sd_relmat_hat", "sigma_nb2_hat",
  "sd_spatial_true", "sd_relmat_true", "sigma_nb2_true",
  "cap_sat", "elapsed_s", "error"
)
cat(paste(cols, collapse = "\t"), "\n", file = tsv)

hb(
  "start %s | n_lvl=%s n_seeds=%d control=%s cores=%d\n",
  format(Sys.time()), paste(n_lvl_grid, collapse = ","), n_seeds,
  include_control, n_cores
)

CTRL <- drm_control(se = TRUE, optimizer = list(eval.max = 1000, iter.max = 1000))

# Runs INSIDE the forked worker; returns a plain list (no TSV I/O here so the
# parent is the sole writer and there is no interleaved-write race).
fit_one <- function(rung, crossed, n_lvl, n_rep, seed) {
  t0 <- Sys.time()
  out <- tryCatch({
    sim <- r105_crossed_data(
      n_lvl = n_lvl, n_rep = n_rep, seed = seed, crossed = crossed
    )
    fit <- suppressWarnings(r105_fit(sim, control = CTRL))
    sdpars_mu <- fit$sdpars$mu
    se_vec <- suppressWarnings(sqrt(diag(fit$sdr$cov.fixed)))
    # No cross-field theta/rho parameter exists for this scoped 2-field
    # architecture (both fields are q=1, per the after-task math contract);
    # cap_sat reports whether any FITTED CORRELATION parameter (from
    # fit$corpars, if any exist elsewhere in the model) saturates the
    # (-1, 1) cap. For row 105 this is expected to always be FALSE.
    rho_all <- unlist(fit$corpars, use.names = FALSE)
    cap_sat <- if (length(rho_all)) any(abs(rho_all) > 0.99) else FALSE
    list(
      conv = fit$opt$convergence,
      pdHess = isTRUE(fit$sdr$pdHess),
      se_finite = all(is.finite(se_vec)) && length(se_vec) > 0L,
      sd_spatial_hat = unname(sdpars_mu[["spatial(1 | site)"]]),
      sd_relmat_hat = unname(sdpars_mu[["relmat(1 | id)"]]),
      sigma_nb2_hat = unname(sigma(fit)[[1L]]),
      nobs = nrow(sim$data),
      n_pairs = sim$n_pairs,
      n_possible_pairs = sim$n_possible_pairs,
      truth = unname(sim$truth),
      cap_sat = cap_sat,
      error = NA_character_
    )
  }, error = function(e) list(error = conditionMessage(e)))
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  out$elapsed <- el
  out
}

row_from_result <- function(j, out) {
  has_error <- !is.null(out$error) && !is.na(out$error)
  if (has_error) {
    c(
      j$rung, j$crossed, j$n_lvl, j$n_rep, j$seed, NA, NA, NA, NA, NA, NA,
      NA, NA, NA, NA, NA, NA, NA, round(out$elapsed, 2),
      gsub("\t", " ", out$error)
    )
  } else {
    c(
      j$rung, j$crossed, j$n_lvl, j$n_rep, j$seed, out$nobs, out$n_pairs,
      out$n_possible_pairs, out$conv, out$pdHess, out$se_finite,
      round(out$sd_spatial_hat, 5), round(out$sd_relmat_hat, 5),
      round(out$sigma_nb2_hat, 5), out$truth[[1L]], out$truth[[2L]],
      out$truth[[3L]], out$cap_sat, round(out$elapsed, 2), NA
    )
  }
}

write_row <- function(row) {
  cat(paste(row, collapse = "\t"), "\n", file = tsv, append = TRUE)
  flush(stdout())
}

# Build the job list: crossed ladder rungs first (the decisive question),
# then the (small, few-seed) non-crossed control rung. Seeds stay well under
# .Machine$integer.max (2147483647): base 202607L * 10000L (~2.026e9) leaves
# headroom for a rung offset (x1000) + seed index (<1000).
seed_base <- 202607L * 10000L
jobs <- list()
for (n_lvl in n_lvl_grid) {
  n_rep <- n_rep_for(n_lvl)
  for (s in seq_len(n_seeds)) {
    jobs[[length(jobs) + 1L]] <- list(
      rung = sprintf("crossed_n%d", n_lvl), crossed = TRUE,
      n_lvl = n_lvl, n_rep = n_rep, seed = seed_base + n_lvl * 1000L + s
    )
  }
}
if (isTRUE(include_control)) {
  n_lvl_ctrl <- n_lvl_grid[[1L]]
  n_rep_ctrl <- n_rep_for(n_lvl_ctrl)
  n_seeds_ctrl <- min(n_seeds, 10L)
  for (s in seq_len(n_seeds_ctrl)) {
    jobs[[length(jobs) + 1L]] <- list(
      rung = sprintf("noncrossed_control_n%d", n_lvl_ctrl), crossed = FALSE,
      n_lvl = n_lvl_ctrl, n_rep = n_rep_ctrl, seed = seed_base + 900000L + s
    )
  }
}

hb("jobs queued: %d\n", length(jobs))

# --- Streaming dispatch: bounded worker pool via mcparallel/mccollect. -----
# At most n_cores jobs are ever in flight; as each completes it is written
# and flushed immediately, then the next queued job is launched.
pending <- jobs
inflight <- list()  # pid-as-character -> job
n_done <- 0L
n_err <- 0L

launch_next <- function() {
  if (!length(pending)) return(invisible(NULL))
  j <- pending[[1L]]
  pending[[1L]] <<- NULL
  proc <- parallel::mcparallel(
    fit_one(j$rung, j$crossed, j$n_lvl, j$n_rep, j$seed),
    silent = TRUE
  )
  inflight[[as.character(proc$pid)]] <<- j
}

for (i in seq_len(min(n_cores, length(pending)))) launch_next()

while (length(inflight)) {
  res <- parallel::mccollect(
    as.integer(names(inflight)), wait = FALSE, timeout = 2
  )
  if (length(res)) {
    for (pid_chr in names(res)) {
      j <- inflight[[pid_chr]]
      out <- res[[pid_chr]]
      if (is.null(out) || inherits(out, "try-error")) {
        out <- list(error = "mcparallel worker returned NULL/try-error", elapsed = NA_real_)
      }
      write_row(row_from_result(j, out))
      n_done <- n_done + 1L
      if (!is.null(out$error) && !is.na(out$error)) {
        n_err <- n_err + 1L
        hb(
          "[%d/%d] %s n_lvl=%d seed=%d ERROR %s (%.1fs)\n",
          n_done, length(jobs), j$rung, j$n_lvl, j$seed, out$error,
          if (is.null(out$elapsed)) NA else out$elapsed
        )
      } else {
        hb(
          "[%d/%d] %s n_lvl=%d seed=%d conv=%s pdHess=%s sd_sp=%.3f sd_rl=%.3f sig=%.3f (%.1fs)\n",
          n_done, length(jobs), j$rung, j$n_lvl, j$seed, out$conv,
          out$pdHess, out$sd_spatial_hat, out$sd_relmat_hat,
          out$sigma_nb2_hat, out$elapsed
        )
      }
      inflight[[pid_chr]] <- NULL
      launch_next()
    }
  }
}

hb("done %s | jobs=%d errors=%d\n", format(Sys.time()), length(jobs), n_err)
