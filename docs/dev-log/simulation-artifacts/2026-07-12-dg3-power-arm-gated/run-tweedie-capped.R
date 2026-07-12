# DG3 power-arm TWEEDIE driver, tight per-fit iteration cap + wall-clock
# budget (Curie, 2026-07-12). The toy pass showed tweedie is ~30x slower per
# fit than the other 17 families (132.8s/20 seeds vs ~2-7s/20 seeds); a
# timing probe traced this to a handful of PATHOLOGICAL parameter regions
# where a single nlminb iteration's tweedie-density evaluation is itself slow
# (not merely "too many iterations") -- e.g. one seed took 22.45s even capped
# at iter.max=50, but only 0.17s at iter.max=20. So: (a) use a CUSTOM
# `optimizer` control, which per drm_optimizer_attempt_specs() bypasses the
# default/careful/robust preset ESCALATION LADDER entirely (a single bounded
# attempt only), and (b) additionally enforce a wall-clock budget in this
# driver, breaking the seed loop once the budget is spent and logging exactly
# how many seeds completed + the exact resume command for the remainder.
#
# Non-convergent fits are NOT silently dropped: drmTMB() issues a
# "drmTMB_convergence_warning" when iter.max is hit without convergence
# (R/drmTMB.R: drm_warn_if_not_converged()), which dg3_fit_and_diagnose()
# (harness.R) already catches via tryCatch(warning = ) and records as
# ok = FALSE -- exactly the "log non-convergence as ok=FALSE" behaviour the
# task asked for, with NO new logic needed here.
#
# Usage:
#   Rscript --no-init-file run-tweedie-capped.R <budget_seconds> <max_seeds>

if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
  stop("Set NOT_CRAN=true to run the DG3 power-arm tweedie driver.")
}

args <- commandArgs(trailingOnly = TRUE)
budget_s <- as.numeric(args[[1]])
max_seeds <- as.integer(args[[2]])

suppressMessages(devtools::load_all(".", quiet = TRUE))
source("inst/dg3-power-arm/harness.R")
source("inst/dg3-power-arm/families.R")

out_dir <- "docs/dev-log/simulation-artifacts/2026-07-12-dg3-power-arm-gated"
tsv <- file.path(out_dir, "tweedie.tsv")
log_file <- file.path(out_dir, "tweedie.log")
unlink(tsv)
unlink(log_file)
dg3_write_header(tsv)

capped_control <- drm_control(se = FALSE, optimizer = list(iter.max = 30L, eval.max = 40L))

spec <- dg3_spec_tweedie
# Override every fit_fn's control to the capped control (same model formulas
# and families as families.R's registered spec -- only the optimizer budget
# changes) by rebuilding fit closures inline; families.R itself is NOT
# modified.
armA_fit <- function(dat) {
  drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat, control = capped_control)
}
ms1 <- spec$mis_specs[[1]] # ignore_atom_epsilon_substituted_gamma_SUBSTITUTE
ms1_true <- function(dat) {
  drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat, control = capped_control)
}
ms1_wrong <- function(dat) {
  dat_eps <- dat
  dat_eps$y[dat_eps$y == 0] <- 1e-3
  drmTMB(bf(y ~ x, sigma ~ 1), family = Gamma(link = "log"), data = dat_eps, control = capped_control)
}
ms2 <- spec$mis_specs[[2]] # dispersion_varying_mean_only_SUBSTITUTE
ms2_true <- function(dat) {
  drmTMB(bf(y ~ x, sigma ~ x, nu ~ 1), family = tweedie(), data = dat, control = capped_control)
}
ms2_wrong <- function(dat) {
  drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat, control = capped_control)
}

t_start <- Sys.time()
dg3_heartbeat(log_file, "=== tweedie CAPPED start %s (budget=%.0fs, max_seeds=%d, iter.max=30/eval.max=40) ===\n",
  format(t_start), budget_s, max_seeds)

n_done <- 0L
for (seed in seq_len(max_seeds)) {
  elapsed <- as.numeric(difftime(Sys.time(), t_start, units = "secs"))
  if (elapsed > budget_s) {
    dg3_heartbeat(log_file, "=== budget exhausted (%.1fs > %.0fs) after seed=%d; stopping ===\n",
      elapsed, budget_s, seed - 1L)
    break
  }
  dat_a <- spec$arm_a$dgp(seed, spec$n)
  res_a <- dg3_fit_and_diagnose(dat_a, armA_fit, response = NULL, resid_seed = seed)
  dg3_stream_row(tsv, "tweedie", "A", "true", seed, spec$n, res_a)

  dat_m1 <- ms1$dgp(seed, spec$n)
  res_m1t <- dg3_fit_and_diagnose(dat_m1, ms1_true, response = NULL, resid_seed = seed)
  dg3_stream_row(tsv, "tweedie", ms1$name, "true", seed, spec$n, res_m1t)
  res_m1w <- dg3_fit_and_diagnose(dat_m1, ms1_wrong, response = NULL, resid_seed = seed)
  dg3_stream_row(tsv, "tweedie", ms1$name, "wrong", seed, spec$n, res_m1w)

  dat_m2 <- ms2$dgp(seed, spec$n)
  res_m2t <- dg3_fit_and_diagnose(dat_m2, ms2_true, response = NULL, resid_seed = seed)
  dg3_stream_row(tsv, "tweedie", ms2$name, "true", seed, spec$n, res_m2t)
  res_m2w <- dg3_fit_and_diagnose(dat_m2, ms2_wrong, response = NULL, resid_seed = seed)
  dg3_stream_row(tsv, "tweedie", ms2$name, "wrong", seed, spec$n, res_m2w)

  n_done <- seed
  dg3_heartbeat(log_file, "[tweedie] seed=%d done armA_ok=%s ms1_wrong_ok=%s ms2_wrong_ok=%s (elapsed=%.1fs)\n",
    seed, res_a$ok, res_m1w$ok, res_m2w$ok, as.numeric(difftime(Sys.time(), t_start, units = "secs")))
}

el_all <- as.numeric(difftime(Sys.time(), t_start, units = "secs"))
dg3_heartbeat(log_file, "=== tweedie CAPPED done %s: %d/%d seeds completed in %.1fs ===\n",
  format(Sys.time()), n_done, max_seeds, el_all)
if (n_done < max_seeds) {
  dg3_heartbeat(log_file,
    "RESUME: remaining seeds %d:%d need Totoro/a longer local budget -- exact command in the after-task report.\n",
    n_done + 1L, max_seeds)
}
