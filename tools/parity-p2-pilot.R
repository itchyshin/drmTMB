# P2 pilot: profile/bootstrap interval PARITY between engine="tmb" and
# engine="julia" on a bridge-routed drm-capabilities row (G3: inference
# qualification for the four "partial" rows in
# inst/extdata/julia-capabilities.tsv). This script proves the PIPELINE only
# -- non-empty, finite, in-range confint() output on both engines for the
# same fixture -- NOT interval coverage or calibration. No promotion, no
# capability-ledger row change.
#
# --prerun mode (leaf n5): ONE row (plain_binomial_nonphylo, DRM.jl fixture
# test/parity/fixtures/binomial-trials), method = "bootstrap" only, R = 20,
# on both fixed-effect coefficients of the linear predictor (mu:(Intercept),
# mu:x). Single core, meant to run in well under 15 minutes on Totoro.
#
# Env vars (both required):
#   DRM_JL_PATH      -- path to the DRM.jl checkout providing the fixture
#                        (test/parity/fixtures/binomial-trials/data.csv).
#   DRMTMB_P2_OUT     -- output path for the TSV of per-coefficient rows.
#
# Optional:
#   DRMTMB_WORKTREE  -- if set, pkgload::load_all() that drmTMB source tree
#                        instead of using library(drmTMB) from .libPaths().
#   JULIA_HOME       -- passed straight to JuliaCall; if unset, this script
#                        tries `julia -e 'print(Sys.BINDIR)'` on PATH.
#   DRMTMB_P2_R      -- bootstrap replicate count (default 20).
#   DRMTMB_P2_SEED   -- bootstrap seed (default 20260903).

args <- commandArgs(trailingOnly = TRUE)
prerun <- "--prerun" %in% args

drmjl_path <- Sys.getenv("DRM_JL_PATH", "")
if (!nzchar(drmjl_path)) {
  stop("set DRM_JL_PATH to the pinned DRM.jl checkout", call. = FALSE)
}
out_path <- Sys.getenv("DRMTMB_P2_OUT", "")
if (!nzchar(out_path)) {
  stop("set DRMTMB_P2_OUT to the output TSV path", call. = FALSE)
}
R_boot <- as.integer(Sys.getenv("DRMTMB_P2_R", "20"))
boot_seed <- as.integer(Sys.getenv("DRMTMB_P2_SEED", "20260903"))

Sys.setenv(DRMTMB_JULIA_TESTS = "true")

worktree <- Sys.getenv("DRMTMB_WORKTREE", "")
if (nzchar(worktree)) {
  suppressPackageStartupMessages(library(pkgload))
  pkgload::load_all(worktree, quiet = TRUE)
} else {
  suppressPackageStartupMessages(library(drmTMB))
}

julia_home <- Sys.getenv("JULIA_HOME", "")
if (!nzchar(julia_home) && nzchar(Sys.which("julia"))) {
  julia_home <- tryCatch(
    paste(
      system2("julia", c("-e", "print(Sys.BINDIR)"), stdout = TRUE, stderr = FALSE),
      collapse = ""
    ),
    error = function(e) ""
  )
}
if (nzchar(julia_home)) {
  Sys.setenv(JULIA_HOME = julia_home)
}
options(drmTMB.DRM.jl.path = drmjl_path)

# Stream results per fit -- append + flush immediately so a crash mid-run
# leaves partial evidence, not nothing (2026-07-05 discipline).
con <- file(out_path, open = "wt")
writeLines(paste(
  "row", "coef", "engine", "step", "wall_seconds",
  "ci_lower", "ci_upper", "bootstrap_n", "bootstrap_failed",
  "converged", "pdHess",
  sep = "\t"
), con)
flush(con)
emit <- function(row, coef, engine, step, wall_seconds, ci_lower = NA, ci_upper = NA,
                  bootstrap_n = NA, bootstrap_failed = NA, converged = NA, pdHess = NA) {
  writeLines(paste(
    row, coef, engine, step,
    sprintf("%.4f", wall_seconds),
    ifelse(is.na(ci_lower), "NA", sprintf("%.10g", ci_lower)),
    ifelse(is.na(ci_upper), "NA", sprintf("%.10g", ci_upper)),
    bootstrap_n, bootstrap_failed, converged, pdHess,
    sep = "\t"
  ), con)
  flush(con)
}

log_line <- function(...) {
  cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), sprintf(...), "\n", sep = "")
}

row_slug <- "plain_binomial_nonphylo"
fixture <- file.path(drmjl_path, "test", "parity", "fixtures", "binomial-trials")
dat <- read.csv(file.path(fixture, "data.csv"), stringsAsFactors = FALSE)
form <- bf(cbind(successes, failures) ~ x)
coef_parms <- c("fixef:mu:(Intercept)", "fixef:mu:x")

log_line("row=%s n=%d -- fitting engine=tmb", row_slug, nrow(dat))
t0 <- proc.time()[["elapsed"]]
fit_tmb <- drmTMB(form, family = stats::binomial(), data = dat, engine = "tmb")
t_fit_tmb <- proc.time()[["elapsed"]] - t0
tmb_converged <- isTRUE(is_converged(fit_tmb))
tmb_pdHess <- isTRUE(fit_tmb$sdr$pdHess)
emit(row_slug, "fit", "tmb", "fit", t_fit_tmb, converged = tmb_converged, pdHess = tmb_pdHess)
log_line("engine=tmb fit done in %.2fs, converged=%s, pdHess=%s", t_fit_tmb, tmb_converged, tmb_pdHess)

if (nzchar(julia_home)) {
  log_line("engine=julia warm-up fit (JuliaCall boot cost excluded from the timed fit)")
  t0 <- proc.time()[["elapsed"]]
  fit_julia_warm <- drmTMB(form, family = stats::binomial(), data = dat, engine = "julia")
  t_warm <- proc.time()[["elapsed"]] - t0
  emit(row_slug, "fit", "julia", "warmup", t_warm)
  log_line("warm-up done in %.2fs", t_warm)
} else {
  log_line("REFUSED: no julia on PATH / JULIA_HOME unset -- Julia half skipped")
  close(con)
  quit(save = "no", status = 1)
}

log_line("engine=julia timed fit")
t0 <- proc.time()[["elapsed"]]
fit_julia <- drmTMB(form, family = stats::binomial(), data = dat, engine = "julia")
t_fit_julia <- proc.time()[["elapsed"]] - t0
julia_converged <- isTRUE(is_converged(fit_julia))
emit(row_slug, "fit", "julia", "fit", t_fit_julia, converged = julia_converged, pdHess = NA)
log_line("engine=julia fit done in %.2fs, converged=%s", t_fit_julia, julia_converged)

for (coef_parm in coef_parms) {
  coef_short <- sub("^fixef:mu:", "", coef_parm)

  log_line("engine=tmb bootstrap R=%d parm=%s", R_boot, coef_parm)
  t0 <- proc.time()[["elapsed"]]
  ci_tmb <- confint(
    fit_tmb,
    parm = coef_parm,
    method = "bootstrap",
    R = R_boot,
    seed = boot_seed
  )
  t_boot_tmb <- proc.time()[["elapsed"]] - t0
  emit(
    row_slug, coef_short, "tmb", "bootstrap", t_boot_tmb,
    ci_lower = ci_tmb$lower[[1L]], ci_upper = ci_tmb$upper[[1L]],
    bootstrap_n = ci_tmb$bootstrap.n[[1L]], bootstrap_failed = ci_tmb$bootstrap.failed[[1L]],
    converged = tmb_converged, pdHess = tmb_pdHess
  )
  log_line(
    "  tmb %s: [%.6f, %.6f] n=%s failed=%s (%.2fs)",
    coef_short, ci_tmb$lower[[1L]], ci_tmb$upper[[1L]],
    ci_tmb$bootstrap.n[[1L]], ci_tmb$bootstrap.failed[[1L]], t_boot_tmb
  )

  log_line("engine=julia bootstrap R=%d parm=%s", R_boot, coef_parm)
  t0 <- proc.time()[["elapsed"]]
  ci_julia <- confint(
    fit_julia,
    parm = coef_parm,
    method = "bootstrap",
    R = R_boot,
    seed = boot_seed
  )
  t_boot_julia <- proc.time()[["elapsed"]] - t0
  emit(
    row_slug, coef_short, "julia", "bootstrap", t_boot_julia,
    ci_lower = ci_julia$lower[[1L]], ci_upper = ci_julia$upper[[1L]],
    bootstrap_n = ci_julia$bootstrap.n[[1L]], bootstrap_failed = ci_julia$bootstrap.failed[[1L]],
    converged = julia_converged, pdHess = NA
  )
  log_line(
    "  julia %s: [%.6f, %.6f] n=%s failed=%s (%.2fs)",
    coef_short, ci_julia$lower[[1L]], ci_julia$upper[[1L]], ci_julia$bootstrap.n[[1L]],
    ci_julia$bootstrap.failed[[1L]], t_boot_julia
  )
}

close(con)
log_line("DONE -- wrote %s", out_path)
cat("PRERUN_OK\n")
