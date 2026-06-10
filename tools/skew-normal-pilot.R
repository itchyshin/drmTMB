#!/usr/bin/env Rscript
# =============================================================================
# ADEMP simulation pilot: drmTMB fixed-effect skew_normal() family
# =============================================================================
#
# Framework: ADEMP (Morris, White & Crowther 2019, Stat. Med. 38:2074-2102),
# reported per the 11 transparent-reporting items of Williams et al. 2024
# (Methods Ecol. Evol. 15:1926-1939).
#
# SCOPE (locked): skew_normal() is FIXED-EFFECT ONLY. No random effects, no
# structured effects, no bivariate / rho12, no skew-t. This pilot stays in that
# scope: location mu, scale sigma, slant nu, all intercept/fixed-effect only.
#
# A -- Aims
#   Primary:   does fixed-effect skew_normal() recover location (mu), scale
#              (sigma), and slant (nu) with acceptable bias, RMSE, and 95%
#              slant-CI coverage?
#   Secondary: what is the false-positive rate of declaring skew (Wald CI for
#              nu excludes 0) when the truth is nu = 0 (the Gaussian limit)?
#
# D -- Data-generating mechanism
#   Single level (fixed-effect; no hierarchy).
#     x_i      ~ N(0, 1)
#     mu_i      = BETA0_MU + BETA1_MU * x_i           (location, identity link)
#     sigma_i   = SIGMA_TRUE                           (scale, constant)
#     nu        in {0, NU_MODERATE}                    (slant, identity link)
#   Public moment -> native Azzalini (drmTMB's internal map):
#     delta = nu / sqrt(1 + nu^2)
#     omega = sigma / sqrt(1 - (delta * sqrt(2/pi))^2)
#     xi    = mu - omega * delta * sqrt(2/pi)
#   Response (stochastic-representation draw):
#     y_i = xi_i + omega_i * (delta * |Z1_i| + sqrt(1 - delta^2) * Z2_i),
#           Z1, Z2 ~ N(0, 1) independent.
#   Conditions varied:  n in {100, 400}  x  nu_true in {0, NU_MODERATE}  = 4 cells
#   Replicates per cell: N_REPS (default 200; top-of-file parameter).
#   Seeding: master seed -> one deterministic seed per (cell, replicate).
#
# E -- Estimands / targets (truth in parentheses)
#   mu:(Intercept)     (BETA0_MU)                location intercept
#   mu:x               (BETA1_MU)                location slope
#   sigma:(Intercept)  (log(SIGMA_TRUE))         scale intercept, LOG scale
#   nu:(Intercept)     (nu_true)                 slant
#   NB drmTMB's sigma link is log, so coef(fit,"sigma") is on the log scale;
#   the truth for the sigma intercept is therefore log(SIGMA_TRUE).
#
# M -- Methods
#   Single estimator (self-recovery pilot, no comparator):
#     drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = skew_normal(),
#            control = drm_control(optimizer_preset = "careful"))
#
# P -- Performance measures (formulas; MCSE per Williams item 11)
#   convergence rate   mean(opt$convergence == 0)
#   pdHess rate        mean(sdr$pdHess)
#   bias               mean(est - truth)              MCSE sd(est)/sqrt(R)
#   RMSE               sqrt(mean((est - truth)^2))    MCSE sqrt(sd((est-truth)^2)/sqrt(R))  [Morris approx]
#   slant CI available mean(is.finite(lo) & is.finite(hi))
#   slant CI coverage  mean(lo <= nu_true <= hi)      MCSE sqrt(p(1-p)/R)
#   false-positive@nu0 mean(CI for nu excludes 0)     MCSE sqrt(a(1-a)/R)  [Type-I, target 0.05]
#   All performance measures are computed over CONVERGED + pdHess fits only,
#   and the convergence/pdHess rates themselves are reported separately so no
#   failed fit is silently dropped (Williams item 10b).
#
# Output:
#   tools/skew-normal-pilot-results.csv   (one row per cell x parameter, + MCSE)
#   docs/dev-log/skew-normal-pilot.md     (short human summary)
#
# Run:  /usr/local/bin/Rscript tools/skew-normal-pilot.R
# =============================================================================

# ---- Top-of-file parameters (scale reps here) -------------------------------
N_REPS        <- 200L                    # replicates per cell (-> 500/1000 to tighten MCSE)
N_GRID        <- c(100L, 400L)           # sample sizes
NU_MODERATE   <- 4                       # moderate positive slant (delta ~ 0.97)
NU_GRID       <- c(0, NU_MODERATE)       # symmetric vs moderate right-skew
BETA0_MU      <- 0.20                    # location intercept (truth)
BETA1_MU      <- 0.45                    # location slope (truth)
SIGMA_TRUE    <- 1.00                    # public moment SD (constant)
CONF_LEVEL    <- 0.95                    # CI / coverage level
MASTER_SEED   <- 20260610L               # master seed (Williams item 6)

PKG_PATH      <- "/Users/z3437171/worktrees/drmTMB-skewpilot"
RESULTS_CSV   <- file.path(PKG_PATH, "tools", "skew-normal-pilot-results.csv")
SUMMARY_MD    <- file.path(PKG_PATH, "docs", "dev-log", "skew-normal-pilot.md")

# ---- Load drmTMB from worktree source (installed build lacks skew_normal) ----
suppressMessages(suppressWarnings(
  pkgload::load_all(PKG_PATH, quiet = TRUE, export_all = FALSE)
))
stopifnot(exists("skew_normal"), exists("drmTMB"), exists("bf"))

# ---- DGP helpers ------------------------------------------------------------
# Public moment (mu, sigma, nu) -> native Azzalini (xi, omega, delta).
# Mirrors drmTMB's internal skew_normal_public_to_native() exactly.
skew_public_to_native <- function(mu, sigma, nu) {
  delta      <- nu / sqrt(1 + nu^2)
  mean_shift <- delta * sqrt(2 / pi)
  omega      <- sigma / sqrt(1 - mean_shift^2)
  xi         <- mu - omega * mean_shift
  list(xi = xi, omega = omega, delta = delta)
}

# One synthetic data set for a given (n, nu_true), seeded.
simulate_cell_data <- function(n, nu_true, seed) {
  set.seed(seed)
  x     <- stats::rnorm(n)
  mu    <- BETA0_MU + BETA1_MU * x
  sigma <- rep(SIGMA_TRUE, n)
  nat   <- skew_public_to_native(mu = mu, sigma = sigma, nu = nu_true)
  z1    <- abs(stats::rnorm(n))
  z2    <- stats::rnorm(n)
  y     <- nat$xi + nat$omega * (nat$delta * z1 + sqrt(1 - nat$delta^2) * z2)
  data.frame(x = x, y = y)
}

# Truth vector keyed by drmTMB coefficient name (sigma on LOG scale).
cell_truth <- function(nu_true) {
  c(
    "mu:(Intercept)"    = BETA0_MU,
    "mu:x"              = BETA1_MU,
    "sigma:(Intercept)" = log(SIGMA_TRUE),
    "nu:(Intercept)"    = nu_true
  )
}

# ---- Fit + extract one replicate -------------------------------------------
# Returns a one-row data.frame of per-replicate diagnostics + estimates + the
# slant Wald interval. Wrapped so a single bad fit never aborts the pilot.
fit_one_rep <- function(dat, nu_true) {
  out <- data.frame(
    converged    = FALSE,
    pdHess       = FALSE,
    est_mu_int   = NA_real_,
    est_mu_x     = NA_real_,
    est_sig_int  = NA_real_,
    est_nu_int   = NA_real_,
    nu_ci_lo     = NA_real_,
    nu_ci_hi     = NA_real_,
    nu_ci_avail  = FALSE,
    nu_ci_status = NA_character_,
    error        = NA_character_,
    stringsAsFactors = FALSE
  )

  fit <- tryCatch(
    drmTMB(
      bf(y ~ x, sigma ~ 1, nu ~ 1),
      family  = skew_normal(),
      data    = dat,
      control = drm_control(optimizer_preset = "careful")
    ),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    out$error <- conditionMessage(fit)
    return(out)
  }

  out$converged <- isTRUE(fit$opt$convergence == 0)
  out$pdHess    <- isTRUE(fit$sdr$pdHess)

  cf_mu  <- stats::coef(fit, "mu")
  cf_sig <- stats::coef(fit, "sigma")
  cf_nu  <- stats::coef(fit, "nu")
  out$est_mu_int  <- unname(cf_mu[["(Intercept)"]])
  out$est_mu_x    <- unname(cf_mu[["x"]])
  out$est_sig_int <- unname(cf_sig[["(Intercept)"]])
  out$est_nu_int  <- unname(cf_nu[["(Intercept)"]])

  ci <- tryCatch(
    stats::confint(fit, parm = "nu:(Intercept)", level = CONF_LEVEL),
    error = function(e) e
  )
  if (!inherits(ci, "error") && nrow(ci) == 1L) {
    out$nu_ci_lo     <- ci$lower[[1L]]
    out$nu_ci_hi     <- ci$upper[[1L]]
    out$nu_ci_status <- as.character(ci$conf.status[[1L]])
    out$nu_ci_avail  <- is.finite(out$nu_ci_lo) && is.finite(out$nu_ci_hi)
  }
  out
}

# ---- Per-cell seed plan (Williams items 6, 7) ------------------------------
conditions <- expand.grid(
  n  = N_GRID,
  nu = NU_GRID,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
conditions$cell_id <- sprintf(
  "skew_fe_n%04d_nu%02d", conditions$n, round(conditions$nu)
)
n_cells <- nrow(conditions)

set.seed(MASTER_SEED)
# One independent stream of replicate seeds per cell.
seed_matrix <- matrix(
  sample.int(.Machine$integer.max, size = n_cells * N_REPS),
  nrow = n_cells, ncol = N_REPS
)

# ---- MCSE helpers -----------------------------------------------------------
mcse_mean <- function(x) stats::sd(x) / sqrt(length(x))           # bias, any mean
mcse_rmse <- function(err) {                                       # Morris approx
  sq <- err^2
  sqrt(stats::sd(sq) / sqrt(length(sq)))
}
mcse_prop <- function(p, n) sqrt(p * (1 - p) / n)                  # coverage, Type-I

# ---- Run -------------------------------------------------------------------
message(sprintf(
  "skew_normal fixed-effect ADEMP pilot: %d cells x %d reps = %d fits",
  n_cells, N_REPS, n_cells * N_REPS
))
t_start <- Sys.time()

rows <- list()

for (ci in seq_len(n_cells)) {
  n        <- conditions$n[ci]
  nu_true  <- conditions$nu[ci]
  cell_id  <- conditions$cell_id[ci]
  truth    <- cell_truth(nu_true)

  reps <- vector("list", N_REPS)
  for (r in seq_len(N_REPS)) {
    dat       <- simulate_cell_data(n = n, nu_true = nu_true, seed = seed_matrix[ci, r])
    reps[[r]] <- fit_one_rep(dat, nu_true = nu_true)
  }
  rep_df <- do.call(rbind, reps)

  n_conv   <- sum(rep_df$converged)
  n_pd     <- sum(rep_df$converged & rep_df$pdHess)
  # Performance over converged + pdHess fits (Williams item 10b: rates kept).
  ok <- rep_df$converged & rep_df$pdHess
  ok_df <- rep_df[ok, , drop = FALSE]
  R_ok  <- nrow(ok_df)

  # Per-parameter bias / RMSE / MCSE over OK fits.
  param_est <- list(
    "mu:(Intercept)"    = ok_df$est_mu_int,
    "mu:x"              = ok_df$est_mu_x,
    "sigma:(Intercept)" = ok_df$est_sig_int,
    "nu:(Intercept)"    = ok_df$est_nu_int
  )

  for (pname in names(param_est)) {
    est <- param_est[[pname]]
    tv  <- truth[[pname]]
    err <- est - tv

    bias_val  <- if (R_ok > 0) mean(err) else NA_real_
    bias_mcse <- if (R_ok > 1) mcse_mean(est) else NA_real_
    rmse_val  <- if (R_ok > 0) sqrt(mean(err^2)) else NA_real_
    rmse_mcse <- if (R_ok > 1) mcse_rmse(err) else NA_real_

    # Slant-specific extras only populated on the nu row.
    is_nu <- identical(pname, "nu:(Intercept)")
    ci_avail_rate <- NA_real_
    cov_val <- NA_real_; cov_mcse <- NA_real_
    fp_val  <- NA_real_; fp_mcse  <- NA_real_

    if (is_nu && R_ok > 0) {
      ci_avail_rate <- mean(ok_df$nu_ci_avail)
      cov_ok <- ok_df[ok_df$nu_ci_avail, , drop = FALSE]
      Rc <- nrow(cov_ok)
      if (Rc > 0) {
        covered <- (cov_ok$nu_ci_lo <= tv) & (tv <= cov_ok$nu_ci_hi)
        cov_val <- mean(covered)
        cov_mcse <- mcse_prop(cov_val, Rc)
        if (nu_true == 0) {
          excl0 <- (cov_ok$nu_ci_lo > 0) | (cov_ok$nu_ci_hi < 0)
          fp_val  <- mean(excl0)
          fp_mcse <- mcse_prop(fp_val, Rc)
        }
      }
    }

    rows[[length(rows) + 1L]] <- data.frame(
      cell_id            = cell_id,
      n                  = n,
      nu_true            = nu_true,
      parameter          = pname,
      truth              = tv,
      n_rep              = N_REPS,
      n_converged        = n_conv,
      n_conv_pdHess      = n_pd,
      conv_rate          = n_conv / N_REPS,
      pdHess_rate        = n_pd / N_REPS,
      n_used             = R_ok,
      bias               = bias_val,
      bias_mcse          = bias_mcse,
      rmse               = rmse_val,
      rmse_mcse          = rmse_mcse,
      slant_ci_avail     = ci_avail_rate,
      slant_coverage     = cov_val,
      slant_coverage_mcse = cov_mcse,
      false_pos_nu0      = fp_val,
      false_pos_nu0_mcse = fp_mcse,
      stringsAsFactors   = FALSE
    )
  }

  message(sprintf(
    "  %s: conv %d/%d, pdHess %d/%d",
    cell_id, n_conv, N_REPS, n_pd, N_REPS
  ))
}

results <- do.call(rbind, rows)
rownames(results) <- NULL

t_elapsed <- as.numeric(difftime(Sys.time(), t_start, units = "secs"))
message(sprintf("Total runtime: %.1f s", t_elapsed))

# ---- Write CSV --------------------------------------------------------------
utils::write.csv(results, RESULTS_CSV, row.names = FALSE)
message("Wrote ", RESULTS_CSV)

# ---- sessionInfo (Williams item 6) -----------------------------------------
si_path <- file.path(PKG_PATH, "tools", "skew-normal-pilot-sessionInfo.txt")
writeLines(capture.output(utils::sessionInfo()), si_path)

# ---- Build markdown summary -------------------------------------------------
fmt <- function(x, d = 3) ifelse(is.na(x), "--", formatC(x, format = "f", digits = d))
pct <- function(x, d = 1) ifelse(is.na(x), "--", paste0(formatC(100 * x, format = "f", digits = d), "%"))

# Convergence table (one row per cell).
conv_tbl <- unique(results[, c("cell_id", "n", "nu_true", "n_rep",
                               "conv_rate", "pdHess_rate", "n_used")])
conv_lines <- apply(conv_tbl, 1L, function(r) {
  sprintf("| `%s` | %s | %s | %s | %s | %s | %s |",
          r[["cell_id"]], r[["n"]], r[["nu_true"]], r[["n_rep"]],
          pct(as.numeric(r[["conv_rate"]])), pct(as.numeric(r[["pdHess_rate"]])),
          r[["n_used"]])
})

# Bias / RMSE table (one row per cell x parameter).
br_lines <- apply(results, 1L, function(r) {
  sprintf("| `%s` | %s | %s | %s | %s (%s) | %s (%s) |",
          r[["cell_id"]], r[["parameter"]], r[["truth"]], r[["n_used"]],
          fmt(as.numeric(r[["bias"]])), fmt(as.numeric(r[["bias_mcse"]])),
          fmt(as.numeric(r[["rmse"]])), fmt(as.numeric(r[["rmse_mcse"]])))
})

# Slant coverage + false-positive (nu rows only).
nu_rows <- results[results$parameter == "nu:(Intercept)", , drop = FALSE]
cov_lines <- apply(nu_rows, 1L, function(r) {
  sprintf("| `%s` | %s | %s | %s | %s (%s) | %s |",
          r[["cell_id"]], r[["nu_true"]], r[["n_used"]],
          pct(as.numeric(r[["slant_ci_avail"]])),
          pct(as.numeric(r[["slant_coverage"]])), pct(as.numeric(r[["slant_coverage_mcse"]])),
          ifelse(is.na(r[["false_pos_nu0"]]), "--",
                 paste0(pct(as.numeric(r[["false_pos_nu0"]])), " (",
                        pct(as.numeric(r[["false_pos_nu0_mcse"]])), ")")))
})

md <- c(
  "# Skew-normal fixed-effect ADEMP pilot",
  "",
  sprintf("_Generated %s by `tools/skew-normal-pilot.R`._", format(Sys.Date())),
  "",
  "Formal ADEMP pilot (Morris, White & Crowther 2019, *Stat. Med.*;",
  "reported per Williams et al. 2024, *Methods Ecol. Evol.* 11-item checklist)",
  "for drmTMB's **fixed-effect** `skew_normal()` family. Scope is fixed-effect",
  "only -- no random / structured / bivariate / `rho12` / skew-t.",
  "",
  "## Design",
  "",
  sprintf("- **Conditions:** n in {%s} x true slant nu in {%s} = %d cells.",
          paste(N_GRID, collapse = ", "), paste(NU_GRID, collapse = ", "), n_cells),
  sprintf("- **Replicates:** %d per cell (master seed %d; per-(cell,rep) seeds).",
          N_REPS, MASTER_SEED),
  sprintf("- **Truth:** mu = %.2f + %.2f x, sigma = %.2f (constant), nu in {%s}.",
          BETA0_MU, BETA1_MU, SIGMA_TRUE, paste(NU_GRID, collapse = ", ")),
  "- **Estimator:** `drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = skew_normal(),`",
  "  `control = drm_control(optimizer_preset = \"careful\"))`.",
  sprintf("- **CI / coverage level:** %.0f%% (Wald).", 100 * CONF_LEVEL),
  sprintf("- `sigma:(Intercept)` truth is on the **log** scale (= log(%.2f) = %.3f).",
          SIGMA_TRUE, log(SIGMA_TRUE)),
  sprintf("- **Runtime:** %.1f s on R %s, drmTMB %s.",
          t_elapsed, getRversion(), as.character(utils::packageVersion("drmTMB"))),
  "",
  "Performance measures are computed over **converged + pdHess** fits; the",
  "convergence and pdHess rates are reported separately so no failed fit is",
  "silently dropped (Williams item 10b). MCSE in parentheses.",
  "",
  "## Convergence",
  "",
  "| cell | n | nu | reps | converged | pdHess | n used |",
  "|---|---|---|---|---|---|---|",
  conv_lines,
  "",
  "## Bias & RMSE (MCSE)",
  "",
  "| cell | parameter | truth | n used | bias (MCSE) | RMSE (MCSE) |",
  "|---|---|---|---|---|---|",
  br_lines,
  "",
  "## Slant interval: availability, coverage, false-positive at nu = 0",
  "",
  "| cell | nu | n used | CI avail | coverage (MCSE) | false-pos@nu0 (MCSE) |",
  "|---|---|---|---|---|---|",
  cov_lines,
  "",
  "_Coverage = fraction of replicates whose Wald CI for `nu:(Intercept)`",
  "contains the truth. False-positive@nu0 = fraction whose CI **excludes 0**",
  "when the truth is nu = 0 (a Type-I rate; nominal target ~5%)._",
  "",
  "## Reproduce",
  "",
  "```sh",
  "/usr/local/bin/Rscript tools/skew-normal-pilot.R",
  "```",
  "",
  sprintf("Scale precision by raising `N_REPS` (currently %d) at the top of the",
          N_REPS),
  "script: 500 -> coverage MCSE ~1%, 1000 -> ~0.7%.",
  ""
)

writeLines(md, SUMMARY_MD)
message("Wrote ", SUMMARY_MD)

# ---- Console headline -------------------------------------------------------
message("\n=== HEADLINE ===")
for (i in seq_len(nrow(nu_rows))) {
  r <- nu_rows[i, ]
  message(sprintf(
    "%s | conv %s pdHess %s | nu bias %s rmse %s | cov %s | fp@nu0 %s",
    r$cell_id, pct(r$conv_rate), pct(r$pdHess_rate),
    fmt(r$bias), fmt(r$rmse), pct(r$slant_coverage),
    ifelse(is.na(r$false_pos_nu0), "n/a", pct(r$false_pos_nu0))
  ))
}
