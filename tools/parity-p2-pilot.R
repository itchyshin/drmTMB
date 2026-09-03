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
} else {
  stop("pass one of --prerun, --local-prerun, --full-pilot", call. = FALSE)
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
    bootstrap_ok = FALSE, # drmTMB#1123: bootstrap_response_data() cannot
    # reconstruct a two-column cbind(successes, failures) response.
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

if (mode == "prerun") {
  run_prerun_totoro()
} else if (mode == "local-prerun") {
  run_local_prerun()
} else if (mode == "full-pilot") {
  run_full_pilot()
}
