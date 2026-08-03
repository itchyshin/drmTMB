#!/usr/bin/env Rscript

# Arc 4b point-fit + local profile gate for mc-0123 (`sd:mu:mu1:spatial(1 |
# p | site)`), the exact target family analogue of mc-0124's B3 promotion.
# See tools/arc4-q6-spatial-mu1-fixture.R's header for why this fixture is
# independent of mc-0124's own (unreachable) DGP.
#
# Same shared seed family the gate and the tools/run-arc2-profile-
# feasibility.R campaign both use (the current tightened contract requires
# the gate and any later campaign to share ONE seed family -- see
# docs/dev-log/after-task/2026-08-02-arc3-fixture-construction.md section 3a).
# Streams one row per seed to stdout AND to a TSV, flushing after every row,
# so a stop mid-run still leaves usable evidence.

args <- commandArgs(trailingOnly = TRUE)
script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]]))
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
source("tools/arc4-q6-spatial-mu1-fixture.R")

out_dir <- "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/4775443f-332b-48b0-aa32-ec256d627713/scratchpad"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_path <- file.path(out_dir, "arc4-q6-spatial-mu1-gate.tsv")
log_path <- file.path(out_dir, "arc4-q6-spatial-mu1-gate.log")
con <- file(out_path, open = "a")
logcon <- file(log_path, open = "a")

target <- "sd:mu:mu1:spatial(1 | p | site)"
seeds <- c(2026080301L, 2026080302L, 2026080303L, 2026080304L, 2026080305L)

run_one <- function(seed) {
  writeLines(sprintf("[%s] seed=%d starting", format(Sys.time()), seed), logcon)
  flush(logcon)
  t0 <- Sys.time()
  row <- tryCatch({
    fx <- arc4_q6_spatial_mu1_fixture(seed = seed)
    coords <- fx$coords
    fit <- drmTMB::drmTMB(
      drmTMB::bf(
        mu1 = y1 ~ x + z + drmTMB::spatial(1 + x + z | p | site, coords = coords),
        mu2 = y2 ~ x + z + drmTMB::spatial(1 + x + z | p | site, coords = coords),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = drmTMB::biv_gaussian(), data = fx$data,
      control = drmTMB::drm_control(optimizer_preset = "robust")
    )
    fit_time <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    targets <- drmTMB::profile_targets(fit)
    tr <- subset(targets, parm == target)
    profile_ready <- nrow(tr) == 1L && isTRUE(tr$profile_ready) && identical(tr$target_type, "direct")
    est <- if (nrow(tr) == 1L) tr$estimate[[1L]] else NA_real_
    true_val <- fx$true_sd_mu1_intercept
    rel_err <- abs(est - true_val) / true_val

    conf_status <- NA_character_; lower <- NA_real_; upper <- NA_real_
    profile_time <- NA_real_; profile_message <- ""
    if (profile_ready) {
      t1 <- Sys.time()
      prof <- tryCatch(stats::profile(fit, parm = target, trace = FALSE), error = identity)
      profile_time <- as.numeric(difftime(Sys.time(), t1, units = "secs"))
      if (inherits(prof, "error")) {
        profile_message <- conditionMessage(prof)
      } else {
        conf_status <- unique(prof$conf.status)[[1L]]
        lower <- unique(prof$conf.low)[[1L]]
        upper <- unique(prof$conf.high)[[1L]]
        profile_message <- unique(prof$profile.message)[[1L]]
      }
    }
    finite_ordered <- profile_ready && all(is.finite(c(lower, est, upper))) && lower < est && est < upper
    brackets_true <- isTRUE(finite_ordered) && lower < true_val && true_val < upper
    rel_err_pass <- is.finite(rel_err) && rel_err <= 0.35
    data.frame(
      cell_id = "mc-0123", target = target, seed = seed,
      n_site = 72L, n_each = 20L, n_obs = nrow(fx$data),
      true_val = true_val, estimate = est, rel_err = rel_err,
      rel_err_pass = rel_err_pass,
      convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
      fit_time_s = round(fit_time, 3),
      profile_ready = profile_ready, conf_status = conf_status,
      lower = lower, upper = upper, finite_ordered = finite_ordered,
      brackets_true = brackets_true,
      profile_time_s = round(profile_time, 3), profile_message = profile_message,
      seed_pass = isTRUE(rel_err_pass) && isTRUE(brackets_true),
      error = "", stringsAsFactors = FALSE
    )
  }, error = function(e) {
    data.frame(
      cell_id = "mc-0123", target = target, seed = seed,
      n_site = 72L, n_each = 20L, n_obs = NA_integer_,
      true_val = NA_real_, estimate = NA_real_, rel_err = NA_real_,
      rel_err_pass = NA,
      convergence = NA_integer_, pdHess = NA,
      fit_time_s = as.numeric(difftime(Sys.time(), t0, units = "secs")),
      profile_ready = NA, conf_status = NA_character_,
      lower = NA_real_, upper = NA_real_, finite_ordered = NA,
      brackets_true = NA,
      profile_time_s = NA_real_, profile_message = "",
      seed_pass = NA,
      error = conditionMessage(e), stringsAsFactors = FALSE
    )
  })
  row
}

header_written <- FALSE
for (seed in seeds) {
  row <- run_one(seed)
  utils::write.table(
    row, con, sep = "\t", quote = FALSE, row.names = FALSE,
    col.names = !header_written
  )
  flush(con)
  header_written <- TRUE
  print(row[c(
    "seed", "estimate", "true_val", "rel_err", "rel_err_pass", "convergence", "pdHess",
    "conf_status", "lower", "upper", "brackets_true", "seed_pass", "error"
  )])
  flush(stdout())
  writeLines(sprintf(
    "[%s] seed=%d done: estimate=%.3f rel_err=%.3f rel_err_pass=%s brackets_true=%s seed_pass=%s",
    format(Sys.time()), seed,
    ifelse(is.na(row$estimate), NA, row$estimate),
    ifelse(is.na(row$rel_err), NA, row$rel_err),
    as.character(row$rel_err_pass), as.character(row$brackets_true), as.character(row$seed_pass)
  ), logcon)
  flush(logcon)
}
close(con)
close(logcon)

all_rows <- utils::read.delim(out_path, colClasses = "character")
all_pass <- all(as.logical(all_rows$seed_pass[all_rows$seed %in% as.character(seeds)]))
cat(sprintf(
  "\nARC4B MC-0123 GATE: %d/%d seeds pass (rel_err<=0.35 AND brackets true). Overall: %s\n",
  sum(as.logical(all_rows$seed_pass)), length(seeds), if (isTRUE(all_pass)) "PASS" else "FAIL"
))
