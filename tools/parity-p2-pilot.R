# P2 pilot: interval PARITY between engine="tmb" and engine="julia" on the
# four bridge-routed "partial" rows in inst/extdata/julia-capabilities.tsv
# (G3: inference qualification). Every mode below proves the PIPELINE only --
# non-empty, finite, in-range confint() output on both engines for the same
# fixture/seed -- NOT interval coverage or an interval-property claim. No
# promotion, no capability-ledger row change, TSVs untouched.
#
# Modes (mutually exclusive, pick one via commandArgs):
#
#   --prerun        Totoro leaf n5. ONE row (plain_binomial_nonphylo),
#                    method = "bootstrap" (R = 20), both engines, single
#                    fixture draw (no reseed). ABANDONED on Totoro -- see
#                    docs/dev-log/evidence/julia-r-parity/p2-pilot/
#                    2026-09-03-prerun-receipt.md (JuliaCall embedding
#                    segfault, unrelated to this script).
#
#   --local-prerun   Leaf n5b, step 1. ONE row (plain_binomial_nonphylo),
#                    method = "profile" (bootstrap is blocked for this row's
#                    two-column cbind(successes, failures) response by
#                    drmTMB#1123), both engines, the SAME committed fixture
#                    draw used on Totoro (no reseed). Meant for < 10 min.
#
#   --full-pilot     Leaf n5b, step 2 (only run if the local-prerun receipt
#                    says decision: RUN). All four partial rows x {wald,
#                    profile} x both engines x 5 seeds, plus bootstrap for
#                    the three rows whose response is a single stored column
#                    (base_gaussian_location_scale, biv_gaussian_residual,
#                    gaussian_response_mask -- NOT plain_binomial_nonphylo,
#                    #1123). Each seed re-simulates a fresh response from the
#                    row's TMB fit via simulate.drmTMB(), refits both
#                    engines on that draw, then calls confint() for each
#                    eligible method. Parallelised over seeds with
#                    parallel::mclapply(), <= 6 cores.
#
#   --g3-qualify     Leaf A8. UNLIKE the three modes above, THIS mode DOES
#                    feed a capability-ledger promotion: for the 3 rows with a
#                    ready profile/bootstrap target (base_gaussian_location_
#                    scale, gaussian_response_mask, plain_binomial_nonphylo),
#                    wald + profile CI parity on ONE fixed-effect target
#                    (fixef:mu:x, tol 1e-4) plus bootstrap distributional
#                    overlap (R = 99); for biv_gaussian_residual, records the
#                    bridge's own refusal (no ready target exists on that
#                    route -- NOT COVERED, not promoted); one purpose-built
#                    quasi-separation binomial cell exercises the DRM.jl#631
#                    profile-endpoint-failure backstop through the public
#                    confint.drmTMB_julia() entry point; and a red control
#                    re-checks the measured profile deltas at a tightened
#                    1e-9 tolerance. See
#                    docs/dev-log/evidence/julia-r-parity/p2-g3/manifest.md
#                    (targets/tolerances/time estimate, committed first per
#                    D-139) and .../g3-qualification-receipt.md (this run's
#                    numbers).
#
# Env vars:
#   DRM_JL_PATH       -- path to the DRM.jl checkout providing the row
#                         fixtures (test/parity/fixtures/<slug>/data.csv).
#                         Required for --prerun/--local-prerun/--full-pilot.
#   DRMTMB_P2_OUT      -- output TSV path (streamed, flushed per row).
#   DRMTMB_WORKTREE   -- if set, pkgload::load_all() that drmTMB source tree
#                         instead of using library(drmTMB) from .libPaths().
#   JULIA_HOME        -- passed straight to JuliaCall; if unset, this script
#                         tries `julia -e 'print(Sys.BINDIR)'` on PATH.
#   DRMTMB_P2_R        -- bootstrap replicate count (default 20).
#   DRMTMB_P2_SEED     -- pre-run bootstrap/profile seed (default 20260903).
#   DRMTMB_P2_CORES    -- --full-pilot mclapply core count (default 4, cap 6).
#   DRMTMB_P2_SEEDS    -- --full-pilot seed count (default 5).

args <- commandArgs(trailingOnly = TRUE)
mode <- if ("--prerun" %in% args) {
  "prerun"
} else if ("--local-prerun" %in% args) {
  "local-prerun"
} else if ("--full-pilot" %in% args) {
  "full-pilot"
} else if ("--g3-qualify" %in% args) {
  "g3-qualify"
} else {
  stop("pass one of --prerun, --local-prerun, --full-pilot, --g3-qualify", call. = FALSE)
}

drmjl_path <- Sys.getenv("DRM_JL_PATH", "")
if (!nzchar(drmjl_path)) {
  stop("set DRM_JL_PATH to the pinned DRM.jl checkout", call. = FALSE)
}
out_path <- Sys.getenv("DRMTMB_P2_OUT", "")
if (!nzchar(out_path)) {
  stop("set DRMTMB_P2_OUT to the output TSV path", call. = FALSE)
}
R_boot <- as.integer(Sys.getenv("DRMTMB_P2_R", "20"))
single_seed <- as.integer(Sys.getenv("DRMTMB_P2_SEED", "20260903"))
n_cores <- min(6L, as.integer(Sys.getenv("DRMTMB_P2_CORES", "4")))
n_seeds <- as.integer(Sys.getenv("DRMTMB_P2_SEEDS", "5"))

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

log_line <- function(...) {
  cat(sprintf("[%s] ", format(Sys.time(), "%H:%M:%S")), sprintf(...), "\n", sep = "")
}

# Stream results per row -- append + flush immediately so a crash mid-run
# leaves partial evidence, not nothing (2026-07-05 discipline). Only used by
# --prerun/--local-prerun (single R process, no forking); --full-pilot writes
# its own table once at the end (see run_full_pilot()), since mclapply()
# forks would each hold a stale copy of this connection.
con <- NULL
open_stream <- function() {
  con <<- file(out_path, open = "wt")
  writeLines(paste(
    "row", "coef", "engine", "method", "seed", "step", "wall_seconds",
    "ci_lower", "ci_upper", "converged",
    sep = "\t"
  ), con)
  flush(con)
}
emit <- function(row, coef, engine, method, seed, step, wall_seconds,
                  ci_lower = NA, ci_upper = NA, converged = NA) {
  writeLines(paste(
    row, coef, engine, method, seed, step,
    sprintf("%.4f", wall_seconds),
    ifelse(is.na(ci_lower), "NA", sprintf("%.10g", ci_lower)),
    ifelse(is.na(ci_upper), "NA", sprintf("%.10g", ci_upper)),
    converged,
    sep = "\t"
  ), con)
  flush(con)
}

# ---------------------------------------------------------------------------
# Row registry -- the four partial rows in inst/extdata/julia-capabilities.tsv
# ---------------------------------------------------------------------------

row_gaussian_response_mask_data <- function() {
  set.seed(1L)
  n <- 60L
  x <- stats::rnorm(n)
  y <- 0.3 + 0.5 * x + stats::rnorm(n) * exp(0.1 * x)
  y[1:6] <- NA
  data.frame(y = y, x = x)
}

drm_rows <- list(
  base_gaussian_location_scale = list(
    formula = quote(bf(y ~ x, sigma ~ x)),
    family = quote(stats::gaussian()),
    fixture = "gaussian-locscale",
    coefs = c("fixef:mu:(Intercept)", "fixef:mu:x"),
    bootstrap_ok = TRUE,
    missing_ctrl = NULL
  ),
  biv_gaussian_residual = list(
    formula = quote(bf(
      mu1 = y1 ~ x, mu2 = y2 ~ x,
      sigma1 = ~1, sigma2 = ~1, rho12 = ~1
    )),
    family = quote(drmTMB::biv_gaussian()),
    fixture = "gaussian-bivariate-rho12",
    coefs = c("fixef:mu1:x", "fixef:mu2:x"),
    bootstrap_ok = TRUE,
    missing_ctrl = NULL
  ),
  plain_binomial_nonphylo = list(
    formula = quote(bf(cbind(successes, failures) ~ x)),
    family = quote(stats::binomial()),
    fixture = "binomial-trials",
    coefs = c("fixef:mu:(Intercept)", "fixef:mu:x"),
    bootstrap_ok = TRUE, # drmTMB#1123 (bootstrap_response_data() could not
    # reconstruct a two-column cbind(successes, failures) response) was FIXED
    # on commit 6a4a05894, already an ancestor of this branch. A8 (2026-09-05)
    # re-probed directly: bootstrap now completes on both engines (5/5
    # successful refits at R=5 in ~8s on engine="julia"). Corrected from
    # FALSE; see docs/dev-log/evidence/julia-r-parity/p2-g3/manifest.md.
    missing_ctrl = NULL
  ),
  gaussian_response_mask = list(
    formula = quote(bf(y ~ x, sigma ~ x)),
    family = quote(stats::gaussian()),
    fixture = NULL, # synthetic (row_gaussian_response_mask_data()), matches
    # tests/testthat/test-julia-missing.R's live-Julia recipe exactly
    # (seed = 1, n = 60, y[1:6] <- NA).
    coefs = c("fixef:mu:(Intercept)", "fixef:mu:x"),
    bootstrap_ok = TRUE,
    missing_ctrl = quote(drmTMB::miss_control(response = "include"))
  )
)

load_row_data <- function(row_name) {
  spec <- drm_rows[[row_name]]
  if (is.null(spec$fixture)) {
    return(row_gaussian_response_mask_data())
  }
  fixture_dir <- file.path(drmjl_path, "test", "parity", "fixtures", spec$fixture)
  utils::read.csv(file.path(fixture_dir, "data.csv"), stringsAsFactors = FALSE)
}

fit_row <- function(row_name, dat, engine) {
  spec <- drm_rows[[row_name]]
  fit_args <- list(
    eval(spec$formula),
    family = eval(spec$family),
    data = dat,
    engine = engine
  )
  if (!is.null(spec$missing_ctrl)) {
    fit_args$missing <- eval(spec$missing_ctrl)
  }
  do.call(drmTMB, fit_args)
}

# ---------------------------------------------------------------------------
# --prerun (Totoro leaf n5) -- unchanged bootstrap-only single-row logic.
# ---------------------------------------------------------------------------

run_prerun_totoro <- function() {
  open_stream()
  row_slug <- "plain_binomial_nonphylo"
  dat <- load_row_data(row_slug)
  coef_parms <- drm_rows[[row_slug]]$coefs

  log_line("row=%s n=%d -- fitting engine=tmb", row_slug, nrow(dat))
  t0 <- proc.time()[["elapsed"]]
  fit_tmb <- fit_row(row_slug, dat, "tmb")
  t_fit_tmb <- proc.time()[["elapsed"]] - t0
  tmb_converged <- isTRUE(is_converged(fit_tmb))
  emit(row_slug, "fit", "tmb", "fit", NA, "fit", t_fit_tmb, converged = tmb_converged)
  log_line("engine=tmb fit done in %.2fs, converged=%s", t_fit_tmb, tmb_converged)

  if (!nzchar(julia_home)) {
    log_line("REFUSED: no julia on PATH / JULIA_HOME unset")
    close(con)
    quit(save = "no", status = 1)
  }

  log_line("engine=julia warm-up fit")
  t0 <- proc.time()[["elapsed"]]
  invisible(fit_row(row_slug, dat, "julia"))
  t_warm <- proc.time()[["elapsed"]] - t0
  emit(row_slug, "fit", "julia", "warmup", NA, "warmup", t_warm)

  log_line("engine=julia timed fit")
  t0 <- proc.time()[["elapsed"]]
  fit_julia <- fit_row(row_slug, dat, "julia")
  t_fit_julia <- proc.time()[["elapsed"]] - t0
  julia_converged <- isTRUE(is_converged(fit_julia))
  emit(row_slug, "fit", "julia", "fit", NA, "fit", t_fit_julia, converged = julia_converged)

  for (coef_parm in coef_parms) {
    coef_short <- sub("^fixef:mu:", "", coef_parm)
    t0 <- proc.time()[["elapsed"]]
    ci_tmb <- confint(fit_tmb, parm = coef_parm, method = "bootstrap", R = R_boot, seed = single_seed)
    t_boot_tmb <- proc.time()[["elapsed"]] - t0
    emit(row_slug, coef_short, "tmb", "bootstrap", single_seed, "ci", t_boot_tmb,
         ci_lower = ci_tmb$lower[[1L]], ci_upper = ci_tmb$upper[[1L]], converged = tmb_converged)

    t0 <- proc.time()[["elapsed"]]
    ci_julia <- confint(fit_julia, parm = coef_parm, method = "bootstrap", R = R_boot, seed = single_seed)
    t_boot_julia <- proc.time()[["elapsed"]] - t0
    emit(row_slug, coef_short, "julia", "bootstrap", single_seed, "ci", t_boot_julia,
         ci_lower = ci_julia$lower[[1L]], ci_upper = ci_julia$upper[[1L]], converged = julia_converged)
  }
  close(con)
  cat("PRERUN_OK\n")
}

# ---------------------------------------------------------------------------
# --local-prerun (leaf n5b, step 1) -- one row, method = "profile", both
# engines, the SAME fixture draw (no reseed).
# ---------------------------------------------------------------------------

run_local_prerun <- function() {
  open_stream()
  row_slug <- "plain_binomial_nonphylo"
  dat <- load_row_data(row_slug)
  coef_parms <- drm_rows[[row_slug]]$coefs

  log_line("row=%s n=%d -- fitting engine=tmb", row_slug, nrow(dat))
  t0 <- proc.time()[["elapsed"]]
  fit_tmb <- fit_row(row_slug, dat, "tmb")
  t_fit_tmb <- proc.time()[["elapsed"]] - t0
  tmb_converged <- isTRUE(is_converged(fit_tmb))
  emit(row_slug, "fit", "tmb", "fit", NA, "fit", t_fit_tmb, converged = tmb_converged)
  log_line("engine=tmb fit done in %.4fs, converged=%s", t_fit_tmb, tmb_converged)

  log_line("engine=julia warm-up fit (JuliaCall boot cost)")
  t0 <- proc.time()[["elapsed"]]
  invisible(fit_row(row_slug, dat, "julia"))
  t_warm <- proc.time()[["elapsed"]] - t0
  emit(row_slug, "fit", "julia", "warmup", NA, "warmup", t_warm)
  log_line("warm-up done in %.4fs", t_warm)

  log_line("engine=julia timed fit")
  t0 <- proc.time()[["elapsed"]]
  fit_julia <- fit_row(row_slug, dat, "julia")
  t_fit_julia <- proc.time()[["elapsed"]] - t0
  julia_converged <- isTRUE(is_converged(fit_julia))
  emit(row_slug, "fit", "julia", "fit", NA, "fit", t_fit_julia, converged = julia_converged)
  log_line("engine=julia fit done in %.4fs, converged=%s", t_fit_julia, julia_converged)

  for (coef_parm in coef_parms) {
    coef_short <- sub("^fixef:mu:", "", coef_parm)

    t0 <- proc.time()[["elapsed"]]
    ci_tmb <- confint(fit_tmb, parm = coef_parm, method = "profile")
    t_prof_tmb <- proc.time()[["elapsed"]] - t0
    emit(row_slug, coef_short, "tmb", "profile", NA, "ci", t_prof_tmb,
         ci_lower = ci_tmb$lower[[1L]], ci_upper = ci_tmb$upper[[1L]], converged = tmb_converged)
    log_line("  tmb %s profile: [%.6f, %.6f] (%.4fs)", coef_short, ci_tmb$lower[[1L]], ci_tmb$upper[[1L]], t_prof_tmb)

    t0 <- proc.time()[["elapsed"]]
    ci_julia <- confint(fit_julia, parm = coef_parm, method = "profile")
    t_prof_julia <- proc.time()[["elapsed"]] - t0
    emit(row_slug, coef_short, "julia", "profile", NA, "ci", t_prof_julia,
         ci_lower = ci_julia$lower[[1L]], ci_upper = ci_julia$upper[[1L]], converged = julia_converged)
    log_line("  julia %s profile: [%.6f, %.6f] (%.4fs)", coef_short, ci_julia$lower[[1L]], ci_julia$upper[[1L]], t_prof_julia)
  }
  close(con)
  cat("LOCAL_PRERUN_OK\n")
}

# ---------------------------------------------------------------------------
# --full-pilot (leaf n5b, step 2) -- 4 rows x {wald, profile} x 2 engines x
# n_seeds seeds, plus bootstrap for the 3 bootstrap_ok rows. Parallel over
# seeds via parallel::mclapply(), <= 6 cores.
# ---------------------------------------------------------------------------

simulate_row_response <- function(row_name, fit_tmb, seed) {
  sim <- simulate(fit_tmb, nsim = 1, seed = seed)
  dat <- fit_tmb$data
  if (row_name == "plain_binomial_nonphylo") {
    trials <- fit_tmb$model$trials
    successes <- sim[[1L]]
    dat$successes <- successes
    dat$failures <- trials - successes
  } else if (row_name == "biv_gaussian_residual") {
    dat$y1 <- sim[[paste0("sim_1_y1")]]
    dat$y2 <- sim[[paste0("sim_1_y2")]]
  } else {
    dat$y <- sim[[1L]]
  }
  dat
}

run_one_cell <- function(row_name, seed) {
  spec <- drm_rows[[row_name]]
  base_dat <- load_row_data(row_name)
  fit_tmb0 <- fit_row(row_name, base_dat, "tmb")
  dat_seed <- simulate_row_response(row_name, fit_tmb0, seed)

  out <- list()
  t0 <- proc.time()[["elapsed"]]
  fit_tmb <- fit_row(row_name, dat_seed, "tmb")
  t_fit_tmb <- proc.time()[["elapsed"]] - t0
  tmb_ok <- isTRUE(is_converged(fit_tmb))

  t0 <- proc.time()[["elapsed"]]
  fit_julia <- tryCatch(fit_row(row_name, dat_seed, "julia"), error = function(e) NULL)
  t_fit_julia <- proc.time()[["elapsed"]] - t0
  julia_ok <- !is.null(fit_julia) && isTRUE(is_converged(fit_julia))

  methods <- c("wald", "profile", if (spec$bootstrap_ok) "bootstrap")
  rows <- list()
  for (coef_parm in spec$coefs) {
    for (method in methods) {
      r_arg <- if (method == "bootstrap") R_boot else 199L
      t0 <- proc.time()[["elapsed"]]
      ci_tmb <- tryCatch(
        confint(fit_tmb, parm = coef_parm, method = method, R = r_arg, seed = seed),
        error = function(e) NULL
      )
      t_tmb <- proc.time()[["elapsed"]] - t0
      t0 <- proc.time()[["elapsed"]]
      ci_julia <- if (julia_ok) {
        tryCatch(
          confint(fit_julia, parm = coef_parm, method = method, R = r_arg, seed = seed),
          error = function(e) NULL
        )
      } else {
        NULL
      }
      t_julia <- proc.time()[["elapsed"]] - t0
      rows[[length(rows) + 1L]] <- data.frame(
        row = row_name, coef = coef_parm, method = method, seed = seed,
        wall_tmb = t_tmb, wall_julia = t_julia,
        ci_lower_tmb = if (is.null(ci_tmb)) NA_real_ else ci_tmb$lower[[1L]],
        ci_upper_tmb = if (is.null(ci_tmb)) NA_real_ else ci_tmb$upper[[1L]],
        ci_lower_julia = if (is.null(ci_julia)) NA_real_ else ci_julia$lower[[1L]],
        ci_upper_julia = if (is.null(ci_julia)) NA_real_ else ci_julia$upper[[1L]],
        tmb_converged = tmb_ok, julia_converged = julia_ok,
        fit_wall_tmb = t_fit_tmb, fit_wall_julia = t_fit_julia,
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

run_full_pilot <- function() {
  # parallel::mclapply() forks the process; on macOS, starting a fresh
  # JuliaCall/libjulia session (which touches CoreFoundation via R's own
  # linked frameworks) inside a fork is unsafe and reliably segfaults every
  # worker ("The process has forked and you cannot use this CoreFoundation
  # functionality safely"). PSOCK workers are independent freshly-spawned R
  # processes (matching the individually-timed Rscript probes that worked),
  # not forks, so JuliaCall booting inside them is safe. Still
  # parallel::<...>, still <= 6 cores, still BLAS-pinned per worker.
  suppressPackageStartupMessages(library(parallel))
  row_names <- names(drm_rows)
  seeds <- seq_len(n_seeds)
  cells <- expand.grid(row_name = row_names, seed = seeds, stringsAsFactors = FALSE)
  log_line("full-pilot: %d row x seed cells on %d PSOCK workers", nrow(cells), n_cores)

  cl <- makeCluster(n_cores, type = "PSOCK")
  on.exit(stopCluster(cl), add = TRUE)
  clusterExport(cl, c(
    "drm_rows", "drmjl_path", "julia_home", "worktree", "R_boot",
    "load_row_data", "fit_row", "simulate_row_response", "run_one_cell",
    "row_gaussian_response_mask_data"
  ), envir = environment())
  clusterEvalQ(cl, {
    Sys.setenv(DRMTMB_JULIA_TESTS = "true", OPENBLAS_NUM_THREADS = "1")
    if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
    options(drmTMB.DRM.jl.path = drmjl_path)
    if (nzchar(worktree)) {
      suppressPackageStartupMessages(library(pkgload))
      pkgload::load_all(worktree, quiet = TRUE)
    } else {
      suppressPackageStartupMessages(library(drmTMB))
    }
    NULL
  })

  results <- parLapply(cl, seq_len(nrow(cells)), function(i) {
    row_name <- cells$row_name[[i]]
    seed <- cells$seed[[i]]
    tryCatch(
      run_one_cell(row_name, seed),
      error = function(e) {
        data.frame(
          row = row_name, coef = NA_character_, method = NA_character_, seed = seed,
          wall_tmb = NA_real_, wall_julia = NA_real_,
          ci_lower_tmb = NA_real_, ci_upper_tmb = NA_real_,
          ci_lower_julia = NA_real_, ci_upper_julia = NA_real_,
          tmb_converged = NA, julia_converged = NA,
          fit_wall_tmb = NA_real_, fit_wall_julia = NA_real_,
          stringsAsFactors = FALSE
        )
      }
    )
  })

  out <- do.call(rbind, results)
  utils::write.table(out, out_path, sep = "\t", row.names = FALSE, quote = FALSE)
  cat("FULL_PILOT_OK\n")
}

# ---------------------------------------------------------------------------
# --g3-qualify (leaf A8) -- G3 bridge-side inference qualification. For the
# 3 routes with a ready profile/bootstrap target (base_gaussian_location_scale,
# gaussian_response_mask, plain_binomial_nonphylo): fit both engines on the
# COMMITTED fixture, compare wald + profile CIs on ONE named fixed-effect
# target (fixef:mu:x) at tol_ci = 1e-4, and compare bootstrap CIs (R = 99)
# by distributional overlap (independent RNG streams -- see the G1 manifest).
# For biv_gaussian_residual: attempt profile and record the bridge's own
# refusal (no ready target exists on this route -- a structural gap, not a
# numerical fluke). Then one purpose-built quasi-separation binomial cell
# exercises the DRM.jl#631 profile-endpoint-failure backstop through the
# ACTUAL public confint.drmTMB_julia() entry point (G4 boundary honesty /
# G8 regression test), and a G6 red control re-checks the measured profile
# deltas against a tightened 1e-9 tolerance. See
# docs/dev-log/evidence/julia-r-parity/p2-g3/manifest.md for the committed
# targets/tolerances/time estimate (D-139).
# ---------------------------------------------------------------------------

run_g3_qualify <- function() {
  evidence_dir <- dirname(out_path)
  dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)
  tol_ci <- 1e-4
  boot_R <- 99L
  boot_seed <- 20260905L
  qualifiable <- c(
    "base_gaussian_location_scale", "gaussian_response_mask",
    "plain_binomial_nonphylo"
  )

  fixef_x_target <- function(row_name) {
    spec <- drm_rows[[row_name]]
    spec$coefs[grepl(":x$", spec$coefs)][[1L]]
  }

  qualify_route <- function(row_name) {
    spec <- drm_rows[[row_name]]
    dat <- load_row_data(row_name)
    target <- fixef_x_target(row_name)
    log_line("=== route=%s target=%s ===", row_name, target)

    t0 <- proc.time()[["elapsed"]]
    fit_t <- fit_row(row_name, dat, "tmb")
    wall_fit_t <- proc.time()[["elapsed"]] - t0
    t0 <- proc.time()[["elapsed"]]
    fit_j <- fit_row(row_name, dat, "julia")
    wall_fit_j <- proc.time()[["elapsed"]] - t0

    conv_t <- isTRUE(is_converged(fit_t))
    conv_j <- isTRUE(is_converged(fit_j))
    estimator_j <- if (is.null(fit_j$estimator)) NA_character_ else fit_j$estimator

    wald_t <- confint(fit_t, parm = target, method = "wald")
    wald_j <- confint(fit_j, parm = target, method = "wald")
    d_wald_lower <- abs(wald_t$lower[[1L]] - wald_j$lower[[1L]])
    d_wald_upper <- abs(wald_t$upper[[1L]] - wald_j$upper[[1L]])

    prof_t <- confint(fit_t, parm = target, method = "profile")
    prof_j <- confint(fit_j, parm = target, method = "profile")
    prof_t_finite <- is.finite(prof_t$lower[[1L]]) && is.finite(prof_t$upper[[1L]])
    prof_j_finite <- is.finite(prof_j$lower[[1L]]) && is.finite(prof_j$upper[[1L]])
    d_prof_lower <- abs(prof_t$lower[[1L]] - prof_j$lower[[1L]])
    d_prof_upper <- abs(prof_t$upper[[1L]] - prof_j$upper[[1L]])
    prof_pass <- prof_t_finite && prof_j_finite &&
      d_prof_lower <= tol_ci && d_prof_upper <= tol_ci

    boot <- NULL
    if (isTRUE(spec$bootstrap_ok)) {
      boot_t <- tryCatch(
        confint(fit_t, parm = target, method = "bootstrap", R = boot_R, seed = boot_seed),
        error = function(e) e
      )
      boot_j <- tryCatch(
        confint(fit_j, parm = target, method = "bootstrap", R = boot_R, seed = boot_seed),
        error = function(e) e
      )
      t_ok <- !inherits(boot_t, "error")
      j_ok <- !inherits(boot_j, "error")
      overlap <- if (t_ok && j_ok) {
        max(boot_t$lower[[1L]], boot_j$lower[[1L]]) <=
          min(boot_t$upper[[1L]], boot_j$upper[[1L]])
      } else {
        NA
      }
      boot <- list(
        t_ok = t_ok, j_ok = j_ok,
        t_error = if (t_ok) NA_character_ else conditionMessage(boot_t),
        j_error = if (j_ok) NA_character_ else conditionMessage(boot_j),
        t_lower = if (t_ok) boot_t$lower[[1L]] else NA_real_,
        t_upper = if (t_ok) boot_t$upper[[1L]] else NA_real_,
        j_lower = if (j_ok) boot_j$lower[[1L]] else NA_real_,
        j_upper = if (j_ok) boot_j$upper[[1L]] else NA_real_,
        overlap = overlap,
        t_failed = if (t_ok) boot_t$bootstrap.failed[[1L]] else NA_integer_,
        j_failed = if (j_ok) boot_j$bootstrap.failed[[1L]] else NA_integer_,
        t_used = if (t_ok) boot_t$bootstrap.n[[1L]] else NA_integer_,
        j_used = if (j_ok) boot_j$bootstrap.n[[1L]] else NA_integer_
      )
    }

    list(
      row = row_name, target = target, conv_t = conv_t, conv_j = conv_j,
      estimator_j = estimator_j,
      wald_t_lower = wald_t$lower[[1L]], wald_t_upper = wald_t$upper[[1L]],
      wald_j_lower = wald_j$lower[[1L]], wald_j_upper = wald_j$upper[[1L]],
      d_wald_lower = d_wald_lower, d_wald_upper = d_wald_upper,
      prof_t_lower = prof_t$lower[[1L]], prof_t_upper = prof_t$upper[[1L]],
      prof_j_lower = prof_j$lower[[1L]], prof_j_upper = prof_j$upper[[1L]],
      d_prof_lower = d_prof_lower, d_prof_upper = d_prof_upper,
      prof_pass = prof_pass, boot = boot,
      wall_fit_t = wall_fit_t, wall_fit_j = wall_fit_j
    )
  }

  route_results <- lapply(qualifiable, qualify_route)
  names(route_results) <- qualifiable

  # --- biv_gaussian_residual: attempt and record the bridge's own refusal. ---
  log_line("=== route=biv_gaussian_residual (expect: no ready target) ===")
  biv_dat <- load_row_data("biv_gaussian_residual")
  biv_fit_j <- fit_row("biv_gaussian_residual", biv_dat, "julia")
  biv_targets <- profile_targets(biv_fit_j)
  biv_all_not_ready <- all(!biv_targets$profile_ready)
  biv_refusal_msg <- tryCatch(
    {
      confint(biv_fit_j, parm = "fixef:mu1:x", method = "profile")
      NA_character_
    },
    error = function(e) conditionMessage(e)
  )
  log_line("biv_gaussian_residual: all targets not-ready=%s, refusal=%s",
    biv_all_not_ready, biv_refusal_msg)

  # --- G4 boundary honesty / G8 #631 regression cell -------------------------
  log_line("=== boundary cell: quasi-complete-separation binomial ===")
  set.seed(99L)
  n_sep <- 40L
  x_sep <- c(rep(-2, n_sep / 2L), rep(2, n_sep / 2L))
  trials_sep <- rep(8L, n_sep)
  p_sep <- ifelse(x_sep < 0, 0.02, 0.98)
  successes_sep <- stats::rbinom(n_sep, trials_sep, p_sep)
  dat_sep <- data.frame(
    successes = successes_sep, failures = trials_sep - successes_sep, x = x_sep
  )
  fit_sep_j <- drmTMB(
    bf(cbind(successes, failures) ~ x), family = stats::binomial(),
    data = dat_sep, engine = "julia"
  )
  fit_sep_t <- drmTMB(
    bf(cbind(successes, failures) ~ x), family = stats::binomial(),
    data = dat_sep, engine = "tmb"
  )
  sep_j_coef <- coef(fit_sep_j)$mu[["x"]]
  sep_t_coef <- coef(fit_sep_t)$mu[["x"]]
  sep_j_profile <- tryCatch(
    confint(fit_sep_j, parm = "fixef:mu:x", method = "profile"),
    error = function(e) e
  )
  sep_t_profile <- tryCatch(
    confint(fit_sep_t, parm = "fixef:mu:x", method = "profile"),
    error = function(e) e
  )
  sep_j_errored <- inherits(sep_j_profile, "error")
  sep_j_msg <- if (sep_j_errored) conditionMessage(sep_j_profile) else NA_character_
  # G8: the #631 backstop must fire -- confint() must NEVER hand back a
  # non-finite bound on this coefficient. Either it errors (the backstop
  # refused, as designed) or it returns a fully finite interval. A silently
  # returned Inf/-Inf is the ONE outcome that fails this check.
  sep_j_never_infinite <- if (sep_j_errored) {
    TRUE
  } else {
    is.finite(sep_j_profile$lower[[1L]]) && is.finite(sep_j_profile$upper[[1L]])
  }
  if (!isTRUE(sep_j_never_infinite)) {
    stop(
      "G8 FAILED: engine=\"julia\" profile confint() returned a non-finite ",
      "bound on the quasi-separation fixture instead of erroring or ",
      "flagging -- the DRM.jl#631 backstop did not fire.",
      call. = FALSE
    )
  }
  g8_pass <- TRUE

  # Diagnostic-only: read the raw per-endpoint flags DRM.jl computed for this
  # coefficient, via a temporary mirror of the registered bridge glue that
  # returns DRM.profile_result()'s auditable row instead of the flattened,
  # backstop-guarded one. Never part of the public API; failure here does not
  # fail the leaf (G8's pass/fail is decided above, from the public API only).
  raw_flags <- tryCatch(
    {
      drm_julia_setup()
      payload_sep <- fit_sep_j$bridge_payload
      JuliaCall::julia_command(paste(
        sep = "\n",
        "function drmTMB_probe_raw_stats(formula, family, data, tree, options, dpar, coefname)",
        "    dat = DRM._bridge_data(data)",
        "    bundle, dat = DRM._bridge_formula(formula, family, dat)",
        "    fam = DRM._bridge_family(family)",
        "    opts = DRM._bridge_options(options)",
        "    tree_obj = tree === nothing ? nothing : DRM._bridge_tree(tree)",
        "    fit = DRM._bridge_fit(bundle, fam, dat; tree = tree_obj, K = nothing, A = nothing, coords = nothing, options = opts)",
        "    blockparm = Symbol(dpar)",
        "    result = DRM.profile_result(fit; level = 0.95, parm = blockparm => String(coefname))",
        "    row = filter(r -> r.param === blockparm && r.coef == coefname, result.ci)[1]",
        "    s = filter(r -> r.param === blockparm && r.coef == coefname, result.stats)[1]",
        "    return Dict{String,Any}(\"lower\" => row.lower, \"upper\" => row.upper,",
        "        \"lower_endpoint_failed\" => s.lower_endpoint_failed,",
        "        \"upper_endpoint_failed\" => s.upper_endpoint_failed,",
        "        \"lower_unbounded\" => s.lower_unbounded,",
        "        \"upper_unbounded\" => s.upper_unbounded)",
        "end"
      ))
      JuliaCall::julia_call(
        "drmTMB_probe_raw_stats",
        payload_sep$formula, fit_sep_j$model$model_type, as.list(payload_sep$data),
        payload_sep$tree,
        if (length(payload_sep$options) == 0L) NULL else payload_sep$options,
        "mu", "x"
      )
    },
    error = function(e) list(error = conditionMessage(e))
  )
  log_line("boundary cell: julia coef=%.3f tmb coef=%.3f julia_errored=%s",
    sep_j_coef, sep_t_coef, sep_j_errored)

  # --- G6 red control: tighten tolerance to 1e-9, expect >= 1 route to FAIL --
  tol_red <- 1e-9
  red_fail <- vapply(qualifiable, function(rn) {
    r <- route_results[[rn]]
    isTRUE(r$d_prof_lower > tol_red || r$d_prof_upper > tol_red)
  }, logical(1L))
  g6_live <- any(red_fail)
  log_line("G6 red control (tol=1e-9): routes failing = %s (live=%s)",
    paste(qualifiable[red_fail], collapse = ", "), g6_live)

  # --- write receipts ---------------------------------------------------
  summary_rows <- do.call(rbind, lapply(qualifiable, function(rn) {
    r <- route_results[[rn]]
    data.frame(
      route = rn, target = r$target, tmb_converged = r$conv_t,
      julia_converged = r$conv_j, julia_estimator = r$estimator_j,
      d_wald_lower = r$d_wald_lower, d_wald_upper = r$d_wald_upper,
      d_profile_lower = r$d_prof_lower, d_profile_upper = r$d_prof_upper,
      profile_pass_tol_1e4 = r$prof_pass,
      profile_fail_tol_1e9 = isTRUE(red_fail[[rn]]),
      bootstrap_t_ok = if (is.null(r$boot)) NA else r$boot$t_ok,
      bootstrap_j_ok = if (is.null(r$boot)) NA else r$boot$j_ok,
      bootstrap_overlap = if (is.null(r$boot)) NA else r$boot$overlap,
      bootstrap_t_failed = if (is.null(r$boot)) NA_integer_ else r$boot$t_failed,
      bootstrap_j_failed = if (is.null(r$boot)) NA_integer_ else r$boot$j_failed,
      stringsAsFactors = FALSE
    )
  }))
  utils::write.table(
    summary_rows, out_path, sep = "\t", row.names = FALSE, quote = FALSE
  )

  receipt_path <- file.path(evidence_dir, "g3-qualification-receipt.md")
  con_r <- file(receipt_path, open = "wt")
  wl <- function(...) writeLines(sprintf(...), con_r)
  wl("# A8 G3 qualification receipt -- measured %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
  wl("")
  wl("tol_ci (wald/profile, both bounds) = %.0e; bootstrap R = %d, seed = %d", tol_ci, boot_R, boot_seed)
  wl("")
  wl("## G2 (profile) / G5 (estimator) per route")
  wl("")
  for (rn in qualifiable) {
    r <- route_results[[rn]]
    wl("### %s (target `%s`)", rn, r$target)
    wl("- converged: tmb=%s julia=%s; julia estimator=%s", r$conv_t, r$conv_j, r$estimator_j)
    wl("- wald: tmb=[%.10g, %.10g] julia=[%.10g, %.10g] delta=[%.6g, %.6g]",
      r$wald_t_lower, r$wald_t_upper, r$wald_j_lower, r$wald_j_upper, r$d_wald_lower, r$d_wald_upper)
    wl("- profile: tmb=[%.10g, %.10g] julia=[%.10g, %.10g] delta=[%.6g, %.6g] PASS(tol=1e-4)=%s",
      r$prof_t_lower, r$prof_t_upper, r$prof_j_lower, r$prof_j_upper,
      r$d_prof_lower, r$d_prof_upper, r$prof_pass)
    if (!is.null(r$boot)) {
      if (r$boot$t_ok && r$boot$j_ok) {
        wl("- bootstrap (R=%d): tmb=[%.6g, %.6g] (failed=%d/%d) julia=[%.6g, %.6g] (failed=%d/%d) OVERLAP=%s",
          boot_R, r$boot$t_lower, r$boot$t_upper, r$boot$t_failed, boot_R,
          r$boot$j_lower, r$boot$j_upper, r$boot$j_failed, boot_R, r$boot$overlap)
      } else {
        wl("- bootstrap (R=%d): tmb_ok=%s julia_ok=%s -- NOT COVERED for this route",
          boot_R, r$boot$t_ok, r$boot$j_ok)
        if (!r$boot$t_ok) wl("  tmb error: %s", r$boot$t_error)
        if (!r$boot$j_ok) wl("  julia error: %s", r$boot$j_error)
      }
    } else {
      wl("- bootstrap: not attempted (bootstrap_ok=FALSE for this row)")
    }
    wl("")
  }
  wl("## biv_gaussian_residual -- NOT COVERED (no ready target)")
  wl("")
  wl("profile_targets() reports profile_ready=FALSE for all %d rows (all-not-ready=%s).",
    nrow(biv_targets), biv_all_not_ready)
  wl("confint(method=\"profile\") on fixef:mu1:x raised:")
  wl("")
  wl("> %s", biv_refusal_msg)
  wl("")
  wl("## G4/G8 -- boundary honesty / #631 regression cell")
  wl("")
  wl("Quasi-complete-separation binomial (n=%d, x in {-2,2}, p in {0.02,0.98}, trials=8).",
    n_sep)
  wl("- julia coef(mu:x)=%.6g; tmb coef(mu:x)=%.6g", sep_j_coef, sep_t_coef)
  wl("- julia profile confint(): errored=%s", sep_j_errored)
  if (sep_j_errored) wl("  message: %s", sep_j_msg)
  wl("- G8 (never a non-finite bound reaches the caller): PASS=%s", g8_pass)
  if (is.null(raw_flags$error)) {
    wl("- raw DRM.jl profile_result() stats for mu:x (diagnostic, bypasses the R flatten): lower=%s upper=%s lower_endpoint_failed=%s upper_endpoint_failed=%s lower_unbounded=%s upper_unbounded=%s",
      raw_flags$lower, raw_flags$upper, raw_flags$lower_endpoint_failed,
      raw_flags$upper_endpoint_failed, raw_flags$lower_unbounded, raw_flags$upper_unbounded)
  } else {
    wl("- raw-flags diagnostic probe failed (non-fatal, does not affect G8): %s", raw_flags$error)
  }
  if (!inherits(sep_t_profile, "error")) {
    wl("- tmb profile confint() on the same fixture: [%.6g, %.6g], boundary=%s (context only; TMB's optimizer does not land at the same boundary on this fixture)",
      sep_t_profile$lower[[1L]], sep_t_profile$upper[[1L]], sep_t_profile$profile.boundary[[1L]])
  }
  wl("")
  wl("## G6 -- RED CONTROL (tolerance tightened to 1e-9)")
  wl("")
  for (rn in qualifiable) {
    r <- route_results[[rn]]
    wl("- %s: profile delta=[%.6g, %.6g] -> %s at tol=1e-9",
      rn, r$d_prof_lower, r$d_prof_upper, if (isTRUE(red_fail[[rn]])) "FAILS" else "passes")
  }
  wl("")
  wl("Comparison is LIVE (not vacuous): %s", if (g6_live) "at least one route fails at tol=1e-9, as expected a priori." else "UNEXPECTED -- no route failed at tol=1e-9; investigate before promoting.")
  wl("Tolerance restored to the committed 1e-4 bar above (no code change was made -- tol_ci is a script parameter, not hardcoded state).")
  close(con_r)

  log_line("wrote %s", out_path)
  log_line("wrote %s", receipt_path)
  cat("G3_QUALIFY_OK\n")
}

if (mode == "prerun") {
  run_prerun_totoro()
} else if (mode == "local-prerun") {
  run_local_prerun()
} else if (mode == "full-pilot") {
  run_full_pilot()
} else if (mode == "g3-qualify") {
  run_g3_qualify()
}
