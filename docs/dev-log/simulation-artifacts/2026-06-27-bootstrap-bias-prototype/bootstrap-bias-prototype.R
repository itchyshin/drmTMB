#!/usr/bin/env Rscript
#
# PROTOTYPE: parametric-bootstrap bias estimate for the structured-RE mu-slope SD
# at g = 8 (phylo provider, mu1:x target).
#
# QUESTION (read-only experiment, no package source touched):
#   A cheap ORACLE recompute on banked g=8 q2 replicates showed the q2 mu-slope
#   SD ML estimate is biased LOW on the log scale by ~ -0.12 to -0.14
#   (mean of log(estimate) - log(truth) over 475 reps).  Debiasing the log-scale
#   centre by that measured bias and rebuilding the interval with a t(df = g-1 = 7)
#   half-width lifts coverage from Wald-z 0.887 / Wald-t 0.932 to ~0.956.
#   That oracle uses the KNOWN truth.
#
#   This script asks: does a PARAMETRIC-BOOTSTRAP bias estimate (no truth used)
#   recover ~ -0.12, and does a bootstrap-bias-corrected + t interval cover ~0.95?
#
# HONESTY / SCOPE:
#   * Compute-heavy (seeds x B refits).  B and seed-count are kept MODEST for a
#     SIGNAL, not a coverage claim.  With ~15-20 seeds the per-seed coverage
#     estimate has MCSE ~ 0.11 -- report as INDICATIVE only.
#   * Reuses the coverage runner's EXACT DGP and fit by sourcing ONLY its
#     function definitions (lines before the MAIN block).
#   * Bootstrap bias on the LOG scale, mirroring the oracle's log-scale framing.
#
# RUN:
#   R_PROFILE_USER=/dev/null Rscript --no-init-file \
#     docs/dev-log/simulation-artifacts/2026-06-27-bootstrap-bias-prototype/bootstrap-bias-prototype.R
#
# Environment overrides (all optional):
#   BBP_SEED_START (default 730001), BBP_N_SEEDS (default 16),
#   BBP_B (default 100 bootstrap refits per seed),
#   GSWEEP_N_GROUPS (default 8 -- match the runner default).

suppressWarnings(suppressMessages({
  t_total_start <- proc.time()

  `%||%` <- function(x, y) if (is.null(x)) y else x

  # -------------------------------------------------------------------------
  # Locate the repo and the coverage-grid runner.
  # -------------------------------------------------------------------------
  repo_root <- "/Users/z3437171/Dropbox/Github Local/drmTMB"
  runner    <- file.path(repo_root, "tools",
                         "run-structured-re-q2-slope-coverage-grid.R")
  stopifnot(file.exists(runner))

  out_dir <- file.path(
    repo_root, "docs", "dev-log", "simulation-artifacts",
    "2026-06-27-bootstrap-bias-prototype"
  )

  # -------------------------------------------------------------------------
  # Source ONLY the runner's function definitions (everything before MAIN).
  # The MAIN block begins at the line `args <- parse_args(commandArgs(TRUE))`.
  # We copy lines[1:(main_line-1)] to a temp file and source that, so the grid
  # never executes.
  # -------------------------------------------------------------------------
  lines     <- readLines(runner)
  main_line <- grep("^args\\s*<-\\s*parse_args\\(commandArgs\\(TRUE\\)\\)", lines)
  stopifnot(length(main_line) == 1L)
  defs_file <- tempfile("q2-runner-defs-", fileext = ".R")
  writeLines(lines[seq_len(main_line - 1L)], defs_file)

  # Ensure GSWEEP_N_GROUPS is set to the runner default before sourcing/use.
  if (!nzchar(Sys.getenv("GSWEEP_N_GROUPS"))) {
    Sys.setenv(GSWEEP_N_GROUPS = "8")
  }

  # getwd() fallback inside the runner resolves repo_root for the temp-install
  # path (which we never trigger). Set wd so its repo_root fallback is sane.
  old_wd <- getwd()
  setwd(repo_root)
  on.exit(setwd(old_wd), add = TRUE)

  source(defs_file, local = FALSE)

  # The runner's try_load_drmTMB is available; but simplest: load drmTMB now.
  stopifnot(requireNamespace("drmTMB", quietly = TRUE))
  library(drmTMB)

  # Sanity: the functions we depend on must exist.
  stopifnot(
    is.function(make_q2_slope_data),
    is.function(fit_q2_slope),
    is.function(extract_estimate),
    is.function(parm_name_for),
    is.function(truth_for),
    is.function(run_wald)
  )
}))

# ---------------------------------------------------------------------------
# Experiment configuration
# ---------------------------------------------------------------------------
PROVIDER   <- "phylo"
TARGET     <- "mu1:x"
N_EACH     <- 20L                       # 20 obs/group; 8 groups -> 160 obs
G          <- as.integer(Sys.getenv("GSWEEP_N_GROUPS", "8"))
DF_T       <- G - 1L                    # t(df = g - 1 = 7)
TRUTH_VAL  <- truth_for(TARGET)         # 1.05
PARM_NAME  <- parm_name_for(PROVIDER, TARGET)

SEED_START <- as.integer(Sys.getenv("BBP_SEED_START", "730001"))
N_SEEDS    <- as.integer(Sys.getenv("BBP_N_SEEDS",    "16"))
B          <- as.integer(Sys.getenv("BBP_B",          "100"))
SEEDS      <- seq.int(SEED_START, length.out = N_SEEDS)

Z975 <- stats::qnorm(0.975)
T975 <- stats::qt(0.975, df = DF_T)

# Oracle constant measured on banked replicates (log-scale bias).
ORACLE_BIAS <- -0.13   # midpoint of the reported -0.12 .. -0.14 range

message(sprintf(
  "[bbp] provider=%s target=%s g=%d truth=%.3f parm=%s",
  PROVIDER, TARGET, G, TRUTH_VAL, PARM_NAME
))
message(sprintf(
  "[bbp] seeds=%d (%d..%d)  B=%d bootstrap refits/seed  df_t=%d",
  N_SEEDS, SEED_START, SEED_START + N_SEEDS - 1L, B, DF_T
))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
covers <- function(truth, lower, upper) {
  is.finite(lower) && is.finite(upper) && lower <= truth && truth <= upper
}

# Recover the Wald SE on the log scale from a Wald interval on the SD target.
# confint() returns the SD interval already exp-transformed; on the log scale
# the half-width is symmetric, so se_log = (log U - log L) / (2 z_.975).
se_log_from_wald <- function(lower, upper) {
  if (!is.finite(lower) || !is.finite(upper) || lower <= 0 || upper <= 0) {
    return(NA_real_)
  }
  (log(upper) - log(lower)) / (2 * Z975)
}

# Refit-control for bootstrap refits: cheap (no sdreport, drop TMB object),
# mirroring drmTMB's bootstrap_refit_control() default.
REFIT_CONTROL <- drm_control(
  se               = FALSE,
  keep_tmb_object  = FALSE,
  optimizer        = list(eval.max = 1600, iter.max = 1600)
)

# Build a per-simulation `sim`-like object (same structure fit_q2_slope expects)
# with the b-th simulated bivariate response swapped in, then refit and extract.
# Mirrors drmTMB:::bootstrap_response_data for biv_gaussian: simulate.drmTMB
# returns columns sim_<b>_y1 / sim_<b>_y2.
refit_one_bootstrap <- function(base_sim, fit, simulations, b) {
  sim_y1 <- paste0("sim_", b, "_y1")
  sim_y2 <- paste0("sim_", b, "_y2")
  if (!all(c(sim_y1, sim_y2) %in% names(simulations))) {
    return(list(ok = FALSE, theta = NA_real_, status = "missing_sim_cols"))
  }
  new_sim <- base_sim
  new_sim$data$y1 <- simulations[[sim_y1]]
  new_sim$data$y2 <- simulations[[sim_y2]]

  refit <- tryCatch(
    fit_q2_slope_with_control(PROVIDER, new_sim, REFIT_CONTROL),
    error = function(e) e
  )
  if (inherits(refit, "error")) {
    return(list(ok = FALSE, theta = NA_real_, status = "refit_error"))
  }
  conv_ok <- isTRUE(refit$opt$convergence == 0L)
  theta   <- tryCatch(extract_estimate(refit, PROVIDER, TARGET),
                      error = function(e) NA_real_)
  ok <- conv_ok && is.finite(theta) && theta > 0
  list(
    ok     = ok,
    theta  = theta,
    status = if (!conv_ok) "nonconverged"
             else if (!is.finite(theta) || theta <= 0) "bad_theta"
             else "ok"
  )
}

# fit_q2_slope builds the formula but hardcodes its own control; we need a
# cheaper control for refits.  Reconstruct the same formula path but pass our
# control.  (Same formula/family/data semantics as fit_q2_slope.)
fit_q2_slope_with_control <- function(provider, sim, control) {
  tree <- sim$tree
  form <- bf(
    mu1    = y1 ~ x + phylo(0 + x | p | species, tree = tree),
    mu2    = y2 ~ x + phylo(0 + x | p | species, tree = tree),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12  = ~1
  )
  drmTMB(
    form,
    family  = biv_gaussian(),
    data    = sim$data,
    control = control
  )
}

# ---------------------------------------------------------------------------
# Main loop over seeds
# ---------------------------------------------------------------------------
rows <- vector("list", length(SEEDS))

for (i in seq_along(SEEDS)) {
  seed <- SEEDS[i]
  t_seed_start <- proc.time()

  rec <- list(
    seed             = seed,
    theta_hat        = NA_real_,
    truth            = TRUTH_VAL,
    wald_lower       = NA_real_,
    wald_upper       = NA_real_,
    se_log           = NA_real_,
    bias_boot        = NA_real_,
    n_refit_ok       = NA_integer_,
    n_refit_tried    = B,
    m_bc             = NA_real_,
    bc_t_lower       = NA_real_,
    bc_t_upper       = NA_real_,
    cover_wald_z     = NA,
    cover_wald_t     = NA,
    cover_oracle_bc  = NA,
    cover_boot_bc_t  = NA,
    fit_status       = "ok",
    elapsed_sec      = NA_real_
  )

  # --- generate data + fit the original model ------------------------------
  sim <- tryCatch(make_q2_slope_data(PROVIDER, seed, N_EACH),
                  error = function(e) e)
  if (inherits(sim, "error")) {
    rec$fit_status <- paste0("sim_error: ", conditionMessage(sim))
    rec$elapsed_sec <- (proc.time() - t_seed_start)[["elapsed"]]
    rows[[i]] <- rec
    message(sprintf("[bbp] seed=%d  SIM ERROR: %s", seed, conditionMessage(sim)))
    next
  }

  fit <- tryCatch(fit_q2_slope(PROVIDER, sim), error = function(e) e)
  if (inherits(fit, "error")) {
    rec$fit_status <- paste0("fit_error: ", conditionMessage(fit))
    rec$elapsed_sec <- (proc.time() - t_seed_start)[["elapsed"]]
    rows[[i]] <- rec
    message(sprintf("[bbp] seed=%d  FIT ERROR: %s", seed, conditionMessage(fit)))
    next
  }

  theta_hat <- tryCatch(extract_estimate(fit, PROVIDER, TARGET),
                        error = function(e) NA_real_)
  rec$theta_hat <- theta_hat

  # --- Wald interval on the original fit (for se_log + reference coverage) --
  wi <- run_wald(fit, PARM_NAME)
  rec$wald_lower <- wi$lower
  rec$wald_upper <- wi$upper
  se_log <- se_log_from_wald(wi$lower, wi$upper)
  rec$se_log <- se_log

  if (!is.finite(theta_hat) || theta_hat <= 0 || !is.finite(se_log)) {
    rec$fit_status <- "bad_point_or_se"
    rec$elapsed_sec <- (proc.time() - t_seed_start)[["elapsed"]]
    rows[[i]] <- rec
    message(sprintf("[bbp] seed=%d  bad theta_hat/se_log (theta=%.4g se_log=%.4g)",
                    seed, theta_hat, se_log))
    next
  }

  log_theta_hat <- log(theta_hat)

  # --- reference intervals that DO NOT need the bootstrap ------------------
  # Wald-z (raw, as confint returns)
  rec$cover_wald_z <- covers(TRUTH_VAL, wi$lower, wi$upper)
  # Wald-t: same centre/se_log but t(df) width on the log scale
  wt_lo <- exp(log_theta_hat - T975 * se_log)
  wt_hi <- exp(log_theta_hat + T975 * se_log)
  rec$cover_wald_t <- covers(TRUTH_VAL, wt_lo, wt_hi)
  # Oracle bias-corrected + t (uses the MEASURED oracle bias, i.e. uses truth)
  m_oracle <- log_theta_hat - ORACLE_BIAS
  oc_lo <- exp(m_oracle - T975 * se_log)
  oc_hi <- exp(m_oracle + T975 * se_log)
  rec$cover_oracle_bc <- covers(TRUTH_VAL, oc_lo, oc_hi)

  # --- PARAMETRIC BOOTSTRAP: simulate B responses, refit each --------------
  simulations <- tryCatch(
    stats::simulate(fit, nsim = B, seed = seed + 5e5),
    error = function(e) e
  )
  if (inherits(simulations, "error")) {
    rec$fit_status <- paste0("simulate_error: ", conditionMessage(simulations))
    rec$elapsed_sec <- (proc.time() - t_seed_start)[["elapsed"]]
    rows[[i]] <- rec
    message(sprintf("[bbp] seed=%d  SIMULATE ERROR: %s", seed,
                    conditionMessage(simulations)))
    next
  }

  theta_star <- numeric(0)
  for (b in seq_len(B)) {
    res <- refit_one_bootstrap(sim, fit, simulations, b)
    if (isTRUE(res$ok)) {
      theta_star <- c(theta_star, res$theta)
    }
  }
  n_ok <- length(theta_star)
  rec$n_refit_ok <- n_ok

  if (n_ok >= 2L) {
    bias_boot <- mean(log(theta_star)) - log_theta_hat
    rec$bias_boot <- bias_boot
    m_bc <- log_theta_hat - bias_boot
    rec$m_bc <- m_bc
    bc_lo <- exp(m_bc - T975 * se_log)
    bc_hi <- exp(m_bc + T975 * se_log)
    rec$bc_t_lower <- bc_lo
    rec$bc_t_upper <- bc_hi
    rec$cover_boot_bc_t <- covers(TRUTH_VAL, bc_lo, bc_hi)
  } else {
    rec$fit_status <- sprintf("too_few_refits (%d ok)", n_ok)
  }

  rec$elapsed_sec <- (proc.time() - t_seed_start)[["elapsed"]]
  rows[[i]] <- rec

  message(sprintf(
    paste0("[bbp] seed=%d  theta_hat=%.4f  bias_boot=%s  n_ok=%d/%d  ",
           "bc_t=[%s] cov_bc_t=%s  (%.1fs)"),
    seed, theta_hat,
    if (is.finite(rec$bias_boot)) sprintf("%+.4f", rec$bias_boot) else "NA",
    rec$n_refit_ok %||% NA, B,
    if (is.finite(rec$bc_t_lower)) sprintf("%.3f,%.3f", rec$bc_t_lower, rec$bc_t_upper) else "NA",
    rec$cover_boot_bc_t,
    rec$elapsed_sec
  ))
}

# ---------------------------------------------------------------------------
# Assemble + write per-seed table
# ---------------------------------------------------------------------------
tab <- do.call(rbind, lapply(rows, function(r) {
  data.frame(
    seed            = r$seed,
    theta_hat       = r$theta_hat,
    truth           = r$truth,
    se_log          = r$se_log,
    bias_boot       = r$bias_boot,
    n_refit_ok      = r$n_refit_ok %||% NA_integer_,
    n_refit_tried   = r$n_refit_tried,
    m_bc            = r$m_bc,
    bc_t_lower      = r$bc_t_lower,
    bc_t_upper      = r$bc_t_upper,
    cover_wald_z    = r$cover_wald_z,
    cover_wald_t    = r$cover_wald_t,
    cover_oracle_bc = r$cover_oracle_bc,
    cover_boot_bc_t = r$cover_boot_bc_t,
    fit_status      = r$fit_status,
    elapsed_sec     = round(r$elapsed_sec, 2),
    stringsAsFactors = FALSE
  )
}))

tsv_path <- file.path(out_dir, "bootstrap-bias-prototype-results.tsv")
utils::write.table(tab, tsv_path, sep = "\t", quote = FALSE,
                   row.names = FALSE, na = "NA")

# ---------------------------------------------------------------------------
# Aggregate report
# ---------------------------------------------------------------------------
ok_bias  <- tab[is.finite(tab$bias_boot), ]
mean_bias_boot <- if (nrow(ok_bias)) mean(ok_bias$bias_boot) else NA_real_
sd_bias_boot   <- if (nrow(ok_bias) > 1) sd(ok_bias$bias_boot) else NA_real_

mean_log_bias_point <- {
  v <- log(tab$theta_hat[is.finite(tab$theta_hat) & tab$theta_hat > 0]) - log(TRUTH_VAL)
  if (length(v)) mean(v) else NA_real_
}

cov_rate <- function(x) {
  x <- x[!is.na(x)]
  if (!length(x)) return(c(rate = NA_real_, n = 0))
  c(rate = mean(x), n = length(x))
}
mcse <- function(p, n) if (is.na(p) || n == 0) NA_real_ else sqrt(p * (1 - p) / n)

cz <- cov_rate(tab$cover_wald_z)
ct <- cov_rate(tab$cover_wald_t)
co <- cov_rate(tab$cover_oracle_bc)
cb <- cov_rate(tab$cover_boot_bc_t)

mean_refit_ok <- mean(tab$n_refit_ok, na.rm = TRUE)
refit_success_rate <- {
  num <- sum(tab$n_refit_ok, na.rm = TRUE)
  den <- sum(tab$n_refit_tried[is.finite(tab$n_refit_ok)], na.rm = TRUE)
  if (den > 0) num / den else NA_real_
}

elapsed_total <- (proc.time() - t_total_start)[["elapsed"]]

fmt_cov <- function(c) sprintf("%.3f (n=%d, MCSE=%.3f)",
                               c[["rate"]], as.integer(c[["n"]]),
                               mcse(c[["rate"]], as.integer(c[["n"]])))

cat("\n")
cat("===========================================================\n")
cat(" BOOTSTRAP BIAS PROTOTYPE -- AGGREGATE\n")
cat(" provider=phylo  target=mu1:x  g=", G, "  truth=", TRUTH_VAL, "\n", sep = "")
cat("===========================================================\n")
cat(sprintf("seeds run                       : %d (%d..%d)\n",
            N_SEEDS, SEED_START, SEED_START + N_SEEDS - 1L))
cat(sprintf("bootstrap refits / seed (B)     : %d\n", B))
cat(sprintf("refit success rate              : %.3f (mean %.1f ok / %d per seed)\n",
            refit_success_rate, mean_refit_ok, B))
cat("-----------------------------------------------------------\n")
cat(sprintf("ORACLE log-bias (known truth)   : %+.3f  [reported -0.12..-0.14]\n",
            ORACLE_BIAS))
cat(sprintf("mean point log-bias this sample : %+.4f  (log(theta_hat)-log(truth))\n",
            mean_log_bias_point))
cat(sprintf("mean BOOTSTRAP log-bias estimate: %+.4f  (sd across seeds %.4f)\n",
            mean_bias_boot, sd_bias_boot))
cat(sprintf("  -> bootstrap recovers oracle? : diff = %+.4f\n",
            mean_bias_boot - ORACLE_BIAS))
cat("-----------------------------------------------------------\n")
cat("COVERAGE across seeds (INDICATIVE; MCSE ~0.11 at n~16):\n")
cat(sprintf("  Wald-z                        : %s\n", fmt_cov(cz)))
cat(sprintf("  Wald-t (df=%d)                 : %s\n", DF_T, fmt_cov(ct)))
cat(sprintf("  oracle-bc + t (uses truth)    : %s\n", fmt_cov(co)))
cat(sprintf("  bootstrap-bc + t (NO truth)   : %s\n", fmt_cov(cb)))
cat("-----------------------------------------------------------\n")
cat(sprintf("total runtime                   : %.1f s (%.1f min)\n",
            elapsed_total, elapsed_total / 60))
cat(sprintf("results TSV                     : %s\n", tsv_path))
cat("===========================================================\n\n")

# Per-seed table to console
print(tab[, c("seed", "theta_hat", "bias_boot", "n_refit_ok",
              "cover_wald_z", "cover_wald_t", "cover_oracle_bc",
              "cover_boot_bc_t", "fit_status")],
      row.names = FALSE)

# One-line verdict heuristic (printed for convenience; final judgement in prose).
recover_ok  <- is.finite(mean_bias_boot) &&
  abs(mean_bias_boot - ORACLE_BIAS) <= 0.05
cov_near_nom <- is.finite(cb[["rate"]]) && abs(cb[["rate"]] - 0.95) <= 2 * mcse(cb[["rate"]], as.integer(cb[["n"]]))
cat(sprintf(
  "\nVERDICT (heuristic): bootstrap-recovers-oracle=%s ; bc+t-near-nominal=%s\n",
  recover_ok, cov_near_nom
))
