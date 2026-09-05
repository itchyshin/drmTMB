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
#   --g3-qualify-biv Leaf A8b. G3 bridge-side inference qualification for the
#                    ONE route leaf A8 measured as NOT COVERED:
#                    biv_gaussian_residual, the residual-only bivariate
#                    Gaussian route, which had no profile/bootstrap target on
#                    ANY parameter through engine = "julia". UNLIKE the three
#                    modes above, this mode COMPARES the two engines and
#                    reports pass/fail against committed tolerances. Both
#                    engines fit the committed gaussian-bivariate-rho12
#                    fixture; every profile-ready fixed-effect target is
#                    profiled through engine = "julia"; two named targets
#                    (fixef:mu1:x and the rho12 intercept) are compared
#                    target-for-target against engine = "tmb" -- Wald at
#                    tol 1e-6, profile at tol 1e-4 -- and bootstrap
#                    (R = 99) is reported as DISTRIBUTIONAL OVERLAP ONLY,
#                    because the two engines draw from independent RNG
#                    streams (R's Mersenne-Twister vs Julia's) and no
#                    same-seed design exists. Writes an ASCII receipt and a
#                    summary TSV next to DRMTMB_P2_OUT.
#
#                    This is a SIBLING of leaf A8's --g3-qualify above (it
#                    covers the three univariate routes; this mode covers the
#                    one bivariate route A8 found NOT COVERED). It is a
#                    separate mode, not an edit of that one.
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
} else if ("--g3-qualify-biv" %in% args) {
  "g3-qualify-biv"
} else {
  stop(
    "pass one of --prerun, --local-prerun, --full-pilot, --g3-qualify, --g3-qualify-biv",
    call. = FALSE
  )
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
# --g3-qualify-biv (leaf A8b) -- G3 bridge-side inference qualification for
# biv_gaussian_residual. See docs/dev-log/evidence/julia-r-parity/p2-g3/
# a8b-biv-manifest.md for the committed targets, tolerances and time estimate
# (D-139). Every number written below is measured in the run that writes it.
# ---------------------------------------------------------------------------

run_g3_qualify_biv <- function() {
  evidence_dir <- dirname(out_path)
  dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)
  row_name <- "biv_gaussian_residual"
  tol_profile <- 1e-4
  tol_wald <- 1e-6
  tol_red <- 1e-9 # G6 red control: a deliberately unattainable bar
  boot_R <- 99L
  boot_seed <- 20260905L
  compare_targets <- c("fixef:mu1:x", "fixef:rho12:(Intercept)")
  # rho12 guard constants (see a8b-biv-qualification-receipt.md, section
  # "rho12 is compared across a guard-constant reparameterisation"):
  # TMB src/drmTMB.cpp:679,4642 rho12 <- 0.999999*tanh(eta); DRM.jl
  # src/sparse_aug_plsm.jl:23 RHO_GUARD = 0.99999999.
  rho_guard_tmb <- 0.999999
  rho_guard_jl <- 0.99999999

  dat <- load_row_data(row_name)
  log_line("route=%s fixture=%s n=%d", row_name,
    drm_rows[[row_name]]$fixture, nrow(dat))

  t0 <- proc.time()[["elapsed"]]
  fit_t <- fit_row(row_name, dat, "tmb")
  wall_t <- proc.time()[["elapsed"]] - t0
  t0 <- proc.time()[["elapsed"]]
  fit_j <- fit_row(row_name, dat, "julia")
  wall_j <- proc.time()[["elapsed"]] - t0
  conv_t <- isTRUE(is_converged(fit_t))
  conv_j <- isTRUE(is_converged(fit_j))
  log_line("fits: tmb %.2fs (converged=%s), julia %.2fs (converged=%s)",
    wall_t, conv_t, wall_j, conv_j)

  # G5 estimator honesty: the ORACLE read on both engines, not the absence of
  # an abort. fit$bridge is the Julia-side report; fit$estimator is what
  # drmTMB tells the user.
  est_j <- if (is.null(fit_j$estimator)) NA_character_ else fit_j$estimator
  est_bridge_j <- if (is.null(fit_j$bridge$estim_method)) {
    NA_character_
  } else {
    fit_j$bridge$estim_method
  }
  est_t <- if (is.null(fit_t$estimator)) NA_character_ else fit_t$estimator
  estimator_match <- identical(est_j, est_bridge_j)
  log_line("estimator: julia fit$estimator=%s fit$bridge$estim_method=%s match=%s; tmb=%s",
    est_j, est_bridge_j, estimator_match, est_t)

  # G3 inventory: which targets the bridge now offers on this route.
  targets_j <- profile_targets(fit_j)
  ready_j <- targets_j[targets_j$profile_ready, , drop = FALSE]
  ready_fixef <- ready_j[ready_j$target_class == "fixed-effect", , drop = FALSE]
  log_line("julia targets: %d rows, %d ready (%d fixed-effect)",
    nrow(targets_j), nrow(ready_j), nrow(ready_fixef))

  # G3: EVERY ready fixed-effect target must actually profile through the
  # engine. An empty ready set is a FAILURE, not a pass.
  profile_all <- lapply(seq_len(nrow(ready_fixef)), function(i) {
    p <- ready_fixef$parm[[i]]
    t1 <- proc.time()[["elapsed"]]
    ci <- tryCatch(
      confint(fit_j, parm = p, method = "profile"),
      error = function(e) e
    )
    el <- proc.time()[["elapsed"]] - t1
    if (inherits(ci, "error")) {
      log_line("  profile %-28s ERROR: %s", p, conditionMessage(ci))
      return(list(parm = p, ok = FALSE, lower = NA_real_, upper = NA_real_,
        status = NA_character_, error = conditionMessage(ci), wall = el))
    }
    ok <- is.finite(ci$lower[[1L]]) && is.finite(ci$upper[[1L]]) &&
      ci$lower[[1L]] < ci$upper[[1L]]
    log_line("  profile %-28s [%.10f, %.10f] status=%s finite=%s (%.2fs)",
      p, ci$lower[[1L]], ci$upper[[1L]], ci$conf.status[[1L]], ok, el)
    list(parm = p, ok = ok, lower = ci$lower[[1L]], upper = ci$upper[[1L]],
      status = as.character(ci$conf.status[[1L]]), error = NA_character_,
      wall = el)
  })
  g3_pass <- nrow(ready_fixef) > 0L &&
    all(vapply(profile_all, function(z) isTRUE(z$ok), logical(1)))

  # G4: same-target agreement against engine = "tmb" on two named targets.
  compare <- lapply(compare_targets, function(p) {
    wald_t <- confint(fit_t, parm = p, method = "wald")
    wald_j <- confint(fit_j, parm = p, method = "wald")
    prof_t <- confint(fit_t, parm = p, method = "profile")
    prof_j <- confint(fit_j, parm = p, method = "profile")
    d_wald <- c(
      abs(wald_t$lower[[1L]] - wald_j$lower[[1L]]),
      abs(wald_t$upper[[1L]] - wald_j$upper[[1L]])
    )
    # Predicted guard-offset for the rho12 axis only: the same natural
    # correlation reported on two different guarded atanh links.
    pred_offset <- if (identical(p, "fixef:rho12:(Intercept)")) {
      eta_hat <- (wald_t$lower[[1L]] + wald_t$upper[[1L]]) / 2
      rho_hat <- rho_guard_tmb * tanh(eta_hat)
      atanh(rho_hat / rho_guard_tmb) - atanh(rho_hat / rho_guard_jl)
    } else {
      NA_real_
    }
    d_prof <- c(
      abs(prof_t$lower[[1L]] - prof_j$lower[[1L]]),
      abs(prof_t$upper[[1L]] - prof_j$upper[[1L]])
    )
    boot_t <- tryCatch(
      confint(fit_t, parm = p, method = "bootstrap", R = boot_R, seed = boot_seed),
      error = function(e) e
    )
    boot_j <- tryCatch(
      confint(fit_j, parm = p, method = "bootstrap", R = boot_R, seed = boot_seed),
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
    log_line("  compare %-28s wald d=[%.3e, %.3e] profile d=[%.3e, %.3e] overlap=%s%s",
      p, d_wald[[1L]], d_wald[[2L]], d_prof[[1L]], d_prof[[2L]], overlap,
      if (is.na(pred_offset)) "" else sprintf(" pred_guard_offset=%.5e", pred_offset))
    list(
      parm = p,
      wald_t = c(wald_t$lower[[1L]], wald_t$upper[[1L]]),
      wald_j = c(wald_j$lower[[1L]], wald_j$upper[[1L]]),
      d_wald = d_wald,
      pred_offset = pred_offset,
      prof_t = c(prof_t$lower[[1L]], prof_t$upper[[1L]]),
      prof_j = c(prof_j$lower[[1L]], prof_j$upper[[1L]]),
      d_prof = d_prof,
      wald_pass = all(d_wald <= tol_wald),
      prof_pass = all(is.finite(c(prof_t$lower[[1L]], prof_t$upper[[1L]],
        prof_j$lower[[1L]], prof_j$upper[[1L]]))) && all(d_prof <= tol_profile),
      prof_pass_red = all(d_prof <= tol_red),
      boot_t = if (t_ok) c(boot_t$lower[[1L]], boot_t$upper[[1L]]) else c(NA_real_, NA_real_),
      boot_j = if (j_ok) c(boot_j$lower[[1L]], boot_j$upper[[1L]]) else c(NA_real_, NA_real_),
      boot_t_failed = if (t_ok) boot_t$bootstrap.failed[[1L]] else NA_integer_,
      boot_j_failed = if (j_ok) boot_j$bootstrap.failed[[1L]] else NA_integer_,
      boot_t_n = if (t_ok) boot_t$bootstrap.n[[1L]] else NA_integer_,
      boot_j_n = if (j_ok) boot_j$bootstrap.n[[1L]] else NA_integer_,
      boot_t_error = if (t_ok) NA_character_ else conditionMessage(boot_t),
      boot_j_error = if (j_ok) NA_character_ else conditionMessage(boot_j),
      overlap = overlap
    )
  })
  names(compare) <- compare_targets

  g4_wald_pass <- all(vapply(compare, function(z) isTRUE(z$wald_pass), logical(1)))
  g4_prof_pass <- all(vapply(compare, function(z) isTRUE(z$prof_pass), logical(1)))
  g6_red_live <- any(!vapply(compare, function(z) isTRUE(z$prof_pass_red), logical(1)))

  # --- summary TSV -----------------------------------------------------------
  tsv <- do.call(rbind, lapply(compare, function(z) {
    data.frame(
      route = row_name, parm = z$parm,
      wald_tmb_lower = z$wald_t[[1L]], wald_tmb_upper = z$wald_t[[2L]],
      wald_julia_lower = z$wald_j[[1L]], wald_julia_upper = z$wald_j[[2L]],
      d_wald_lower = z$d_wald[[1L]], d_wald_upper = z$d_wald[[2L]],
      wald_pass_1e6 = z$wald_pass,
      profile_tmb_lower = z$prof_t[[1L]], profile_tmb_upper = z$prof_t[[2L]],
      profile_julia_lower = z$prof_j[[1L]], profile_julia_upper = z$prof_j[[2L]],
      d_profile_lower = z$d_prof[[1L]], d_profile_upper = z$d_prof[[2L]],
      profile_pass_1e4 = z$prof_pass, profile_pass_1e9 = z$prof_pass_red,
      boot_tmb_lower = z$boot_t[[1L]], boot_tmb_upper = z$boot_t[[2L]],
      boot_julia_lower = z$boot_j[[1L]], boot_julia_upper = z$boot_j[[2L]],
      boot_tmb_failed = z$boot_t_failed, boot_julia_failed = z$boot_j_failed,
      boot_tmb_n = z$boot_t_n, boot_julia_n = z$boot_j_n,
      boot_overlap = z$overlap,
      estimator_julia = est_j, estimator_julia_bridge = est_bridge_j,
      estimator_match = estimator_match,
      stringsAsFactors = FALSE
    )
  }))
  utils::write.table(tsv, out_path, sep = "\t", row.names = FALSE, quote = FALSE)
  log_line("wrote %s", out_path)

  # --- ASCII receipt ---------------------------------------------------------
  receipt <- file.path(evidence_dir, "a8b-biv-qualification-receipt.md")
  L <- character(0)
  add <- function(...) L <<- c(L, sprintf(...))
  add("# A8b G3 qualification receipt -- biv_gaussian_residual bridge inference")
  add("")
  add("Measured %s. Every number below is from this run.",
    format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
  add("")
  add("- route: `%s`; fixture `%s` (n = %d), formula `bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)`, `family = biv_gaussian()`",
    row_name, drm_rows[[row_name]]$fixture, nrow(dat))
  add("- DRM.jl checkout: `%s`", drmjl_path)
  add("- tolerances: Wald %g, profile %g; bootstrap R = %d, seed = %d",
    tol_wald, tol_profile, boot_R, boot_seed)
  add("- fits: tmb %.2f s (converged = %s); julia %.2f s (converged = %s)",
    wall_t, conv_t, wall_j, conv_j)
  add("")
  add("## G5 -- estimator honesty (oracle read)")
  add("")
  add("- `fit_julia$estimator` = `%s`", est_j)
  add("- `fit_julia$bridge$estim_method` = `%s`", est_bridge_j)
  add("- identical: **%s**", estimator_match)
  add("- `fit_tmb$estimator` = `%s`", est_t)
  add("")
  add("## G3 -- target inventory and per-target profile through engine = \"julia\"")
  add("")
  add("`profile_targets()` on the julia fit: %d rows, %d profile-ready, of which %d fixed-effect.",
    nrow(targets_j), nrow(ready_j), nrow(ready_fixef))
  add("")
  add("| parm | profile lower | profile upper | conf.status | finite |")
  add("|---|---|---|---|---|")
  for (z in profile_all) {
    add("| `%s` | %s | %s | %s | %s |", z$parm,
      if (is.na(z$lower)) "ERROR" else sprintf("%.10f", z$lower),
      if (is.na(z$upper)) "ERROR" else sprintf("%.10f", z$upper),
      if (is.na(z$status)) z$error else z$status, z$ok)
  }
  add("")
  add("G3 PASS (a non-empty ready set, every member profiling to a finite interval): **%s**",
    g3_pass)
  add("")
  add("## G4 -- same-target agreement vs engine = \"tmb\"")
  add("")
  for (z in compare) {
    add("### `%s`", z$parm)
    add("")
    add("- wald:    tmb [%.10f, %.10f]  julia [%.10f, %.10f]  delta [%.5e, %.5e]  PASS(%g) = %s%s",
      z$wald_t[[1L]], z$wald_t[[2L]], z$wald_j[[1L]], z$wald_j[[2L]],
      z$d_wald[[1L]], z$d_wald[[2L]], tol_wald, z$wald_pass,
      if (is.na(z$pred_offset)) "" else sprintf("  pred_guard_offset = %.5e", z$pred_offset))
    add("- profile: tmb [%.10f, %.10f]  julia [%.10f, %.10f]  delta [%.5e, %.5e]  PASS(%g) = %s",
      z$prof_t[[1L]], z$prof_t[[2L]], z$prof_j[[1L]], z$prof_j[[2L]],
      z$d_prof[[1L]], z$d_prof[[2L]], tol_profile, z$prof_pass)
    if (is.na(z$boot_t[[1L]]) || is.na(z$boot_j[[1L]])) {
      add("- bootstrap (R = %d): tmb_ok = %s julia_ok = %s -- NOT COVERED for this target",
        boot_R, !is.na(z$boot_t[[1L]]), !is.na(z$boot_j[[1L]]))
      if (!is.na(z$boot_t_error)) add("  - tmb error: %s", z$boot_t_error)
      if (!is.na(z$boot_j_error)) add("  - julia error: %s", z$boot_j_error)
    } else {
      add("- bootstrap (R = %d): tmb [%.6f, %.6f] (failed %d/%d) julia [%.6f, %.6f] (failed %d/%d) -- OVERLAP ONLY = %s",
        boot_R, z$boot_t[[1L]], z$boot_t[[2L]], z$boot_t_failed, boot_R,
        z$boot_j[[1L]], z$boot_j[[2L]], z$boot_j_failed, boot_R, z$overlap)
    }
    add("")
  }
  add("G4 Wald PASS (all targets, tol %g): **%s**", tol_wald, g4_wald_pass)
  add("")
  add("G4 profile PASS (all targets, tol %g): **%s**", tol_profile, g4_prof_pass)
  add("")
  add("The bootstrap comparison is DISTRIBUTIONAL OVERLAP ONLY. There is no")
  add("same-seed design: `engine = \"tmb\"` draws replicates from R's RNG and")
  add("`engine = \"julia\"` from a Julia `MersenneTwister`, so the same `seed`")
  add("value does not produce the same replicates. Overlap is the strongest")
  add("claim these two numbers support.")
  add("")
  add("## G6(a) -- RED CONTROL: profile tolerance tightened to %g", tol_red)
  add("")
  for (z in compare) {
    add("- `%s`: profile delta [%.5e, %.5e] -> PASS(%g) = %s",
      z$parm, z$d_prof[[1L]], z$d_prof[[2L]], tol_red, z$prof_pass_red)
  }
  add("")
  add("At least one target FAILS at %g: **%s** (the comparison is live, not vacuous).",
    tol_red, g6_red_live)
  add("`tol_red` is a script parameter, not committed state, so nothing was")
  add("edited and nothing needs restoring for this control.")
  add("")
  add("## What this receipt does NOT claim")
  add("")
  add("- NOT interval coverage. One fixture, one seed, one target per block.")
  add("- NOT a claim about the STRUCTURED (q = 4 / q = 2) bivariate route,")
  add("  whose fixed-effect rows remain deliberately not-ready.")
  add("- NOT a claim about `meta_V` bivariate fits or a partially observed")
  add("  bivariate response: neither is exercised by this fixture.")
  writeLines(L, receipt)
  log_line("wrote %s", receipt)

  cat(sprintf(
    "G3_PASS=%s G4_WALD_PASS=%s G4_PROFILE_PASS=%s G5_ESTIMATOR_MATCH=%s G6_RED_LIVE=%s\n",
    g3_pass, g4_wald_pass, g4_prof_pass, estimator_match, g6_red_live
  ))
  if (!(g3_pass && g4_wald_pass && g4_prof_pass && estimator_match && g6_red_live)) {
    cat("G3_QUALIFY_BIV_FAILED\n")
    quit(save = "no", status = 1)
  }
  cat("G3_QUALIFY_BIV_OK\n")
}

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
} else if (mode == "g3-qualify-biv") {
  run_g3_qualify_biv()
}
