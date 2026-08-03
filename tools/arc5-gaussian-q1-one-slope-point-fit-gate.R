#!/usr/bin/env Rscript

# Arc 5 point-fit gate + local profile smoke for the four `legacy_02`
# (one-slope, ML) q1 cells: mc-0286 (mu spatial), mc-0289 (sigma spatial),
# mc-0298 (mu animal), mc-0310 (mu relmat). See
# tools/arc5-gaussian-q1-one-slope-fixtures.R's header for the fixture
# design and provenance.
#
# Two phases, run per cell:
#   1. Point-fit gate: 5 seeds, ML, predeclared mean relative error <= 0.35
#      on the primary (intercept) target. No profiling in this phase.
#   2. For cells passing phase 1 ONLY: local interval smoke on the SAME 5
#      seeds -- one retained stats::profile() call per seed on the primary
#      target, reporting conf.status/lower/estimate/upper/convergence/pdHess/
#      boundary and whether the interval brackets the truth.
#
# Streams one row per (cell, phase, seed) fit to stdout AND to a TSV,
# flushing after every row, so a stop mid-run still leaves usable evidence.

args <- commandArgs(trailingOnly = TRUE)
script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]]))
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
source("tools/arc5-gaussian-q1-one-slope-fixtures.R")

out_dir <- "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/4775443f-332b-48b0-aa32-ec256d627713/scratchpad"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
gate_path <- file.path(out_dir, "arc5-gaussian-q1-one-slope-gate.tsv")
smoke_path <- file.path(out_dir, "arc5-gaussian-q1-one-slope-smoke.tsv")
log_path <- file.path(out_dir, "arc5-gaussian-q1-one-slope-gate.log")
gate_con <- file(gate_path, open = "a")
smoke_con <- file(smoke_path, open = "a")
logcon <- file(log_path, open = "a")

cells <- list(
  "mc-0286" = list(
    target = "sd:mu:spatial(1 | site)",
    fit_fn = function(fx) drmTMB::drmTMB(
      {
        coords <- fx$object$coords
        drmTMB::bf(y ~ x + drmTMB::spatial(1 + x | site, coords = coords), sigma ~ 1)
      },
      family = stats::gaussian(), data = fx$data
    ),
    build_fixture = function(seed) arc5_gaussian_mu_one_slope_fixture(
      "spatial", M = 16L, n_each = 20L, seed = seed
    )
  ),
  "mc-0310" = list(
    target = "sd:mu:relmat(1 | id)",
    fit_fn = function(fx) drmTMB::drmTMB(
      {
        K <- fx$object$K
        drmTMB::bf(y ~ x + drmTMB::relmat(1 + x | id, K = K), sigma ~ 1)
      },
      family = stats::gaussian(), data = fx$data
    ),
    build_fixture = function(seed) arc5_gaussian_mu_one_slope_fixture(
      "relmat", M = 16L, n_each = 20L, seed = seed
    )
  ),
  "mc-0298" = list(
    target = "sd:mu:animal(1 | id)",
    fit_fn = function(fx) drmTMB::drmTMB(
      {
        A <- fx$object$A
        drmTMB::bf(y ~ x + drmTMB::animal(1 + x | id, A = A), sigma ~ 1)
      },
      family = stats::gaussian(), data = fx$data
    ),
    build_fixture = function(seed) arc5_gaussian_mu_one_slope_fixture(
      "animal", n_founders = 8L, n_each = 20L, seed = seed
    )
  ),
  "mc-0289" = list(
    target = "sd:sigma:spatial(1 | site)",
    fit_fn = function(fx) drmTMB::drmTMB(
      {
        coords <- fx$object$coords
        drmTMB::bf(y ~ x, sigma ~ drmTMB::spatial(1 + x | site, coords = coords))
      },
      family = stats::gaussian(), data = fx$data
    ),
    build_fixture = function(seed) arc5_gaussian_sigma_spatial_one_slope_fixture(
      n_side = 5L, n_each = 24L, seed = seed
    )
  )
)

seed_families <- list(
  "mc-0286" = 2861:2865,
  "mc-0310" = 3101:3105,
  "mc-0298" = 2981:2985,
  "mc-0289" = 2891:2895
)

run_gate <- function(cell_id, spec, seed) {
  writeLines(sprintf("[%s] %s seed=%d gate starting", format(Sys.time()), cell_id, seed), logcon)
  flush(logcon)
  t0 <- Sys.time()
  row <- tryCatch({
    fx <- spec$build_fixture(seed)
    fit <- spec$fit_fn(fx)
    fit_time <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    targets <- drmTMB::profile_targets(fit)
    tr <- subset(targets, parm == spec$target)
    stopifnot(nrow(tr) == 1L)
    est <- as.numeric(tr$estimate[[1L]])
    truth <- fx$true_sd_intercept
    rel_err <- abs(est - truth) / truth
    data.frame(
      cell_id = cell_id, phase = "gate", seed = seed,
      condition_number = fx$object$condition_number,
      truth = truth, estimate = est, rel_err = rel_err,
      convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
      profile_ready = isTRUE(tr$profile_ready[[1L]]),
      fit_time_s = round(fit_time, 3), error = "",
      stringsAsFactors = FALSE
    )
  }, error = function(e) {
    data.frame(
      cell_id = cell_id, phase = "gate", seed = seed,
      condition_number = NA_real_,
      truth = NA_real_, estimate = NA_real_, rel_err = NA_real_,
      convergence = NA_integer_, pdHess = NA,
      profile_ready = NA,
      fit_time_s = as.numeric(difftime(Sys.time(), t0, units = "secs")),
      error = conditionMessage(e), stringsAsFactors = FALSE
    )
  })
  row
}

run_smoke <- function(cell_id, spec, seed) {
  writeLines(sprintf("[%s] %s seed=%d smoke starting", format(Sys.time()), cell_id, seed), logcon)
  flush(logcon)
  t0 <- Sys.time()
  row <- tryCatch({
    fx <- spec$build_fixture(seed)
    fit <- spec$fit_fn(fx)
    truth <- fx$true_sd_intercept
    est <- unname(drmTMB::profile_targets(fit)$estimate[
      drmTMB::profile_targets(fit)$parm == spec$target
    ])
    prof <- stats::profile(fit, parm = spec$target, trace = FALSE)
    conf_status <- unique(prof$conf.status)[[1L]]
    lower <- unique(prof$conf.low)[[1L]]
    upper <- unique(prof$conf.high)[[1L]]
    message_txt <- unique(prof$profile.message)[[1L]]
    finite_ordered <- all(is.finite(c(lower, est, upper))) && lower < est && est < upper
    brackets <- is.finite(lower) && is.finite(upper) && truth >= lower && truth <= upper
    data.frame(
      cell_id = cell_id, phase = "smoke", seed = seed,
      truth = truth, estimate = est, rel_err = abs(est - truth) / truth,
      convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
      conf_status = conf_status, lower = lower, upper = upper,
      finite_ordered = finite_ordered, brackets_truth = brackets,
      profile_message = message_txt,
      fit_time_s = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 3),
      error = "", stringsAsFactors = FALSE
    )
  }, error = function(e) {
    data.frame(
      cell_id = cell_id, phase = "smoke", seed = seed,
      truth = NA_real_, estimate = NA_real_, rel_err = NA_real_,
      convergence = NA_integer_, pdHess = NA,
      conf_status = NA_character_, lower = NA_real_, upper = NA_real_,
      finite_ordered = NA, brackets_truth = NA,
      profile_message = "",
      fit_time_s = as.numeric(difftime(Sys.time(), t0, units = "secs")),
      error = conditionMessage(e), stringsAsFactors = FALSE
    )
  })
  row
}

gate_header_written <- file.exists(gate_path) && file.info(gate_path)$size > 0
gate_results <- list()
for (cell_id in names(cells)) {
  spec <- cells[[cell_id]]
  seeds <- seed_families[[cell_id]]
  rows <- lapply(seeds, function(seed) run_gate(cell_id, spec, seed))
  cell_gate <- do.call(rbind, rows)
  gate_results[[cell_id]] <- cell_gate
  utils::write.table(
    cell_gate, gate_con, sep = "\t", quote = FALSE, row.names = FALSE,
    col.names = !gate_header_written
  )
  flush(gate_con)
  gate_header_written <- TRUE
  print(cell_gate[c("cell_id", "seed", "condition_number", "estimate", "rel_err", "convergence", "pdHess", "error")])
  flush(stdout())
  mean_rel_err <- mean(cell_gate$rel_err, na.rm = TRUE)
  gate_pass <- !any(is.na(cell_gate$rel_err)) && mean_rel_err <= 0.35
  writeLines(sprintf(
    "[%s] %s GATE mean_rel_err=%.4f -> %s", format(Sys.time()), cell_id,
    mean_rel_err, if (gate_pass) "PASS" else "FAIL"
  ), logcon)
  flush(logcon)
  message(sprintf("%s gate mean_rel_err=%.4f -> %s", cell_id, mean_rel_err, if (gate_pass) "PASS" else "FAIL"))

  if (gate_pass) {
    smoke_rows <- lapply(seeds, function(seed) run_smoke(cell_id, spec, seed))
    cell_smoke <- do.call(rbind, smoke_rows)
    smoke_header_written <- file.exists(smoke_path) && file.info(smoke_path)$size > 0
    utils::write.table(
      cell_smoke, smoke_con, sep = "\t", quote = FALSE, row.names = FALSE,
      col.names = !smoke_header_written
    )
    flush(smoke_con)
    print(cell_smoke[c(
      "cell_id", "seed", "estimate", "rel_err", "conf_status", "lower", "upper",
      "finite_ordered", "brackets_truth", "error"
    )])
    flush(stdout())
  }
}
close(gate_con); close(smoke_con); close(logcon)
message("Done. Gate results: ", gate_path, " ; smoke results: ", smoke_path)
