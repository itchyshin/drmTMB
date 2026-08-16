# D-117 REML arm --- paired ML vs REML profile-interval coverage on the A1 cell.
#
# The D-93 packet (2026-08-15) names REML as the one lever that is implemented on
# this exact target (ledger mc-0265) and has never had its coverage measured.
# This runner measures it.
#
# DESIGN: paired. Each replicate generates ONE dataset and fits it TWICE --- once
# with REML = FALSE, once with REML = TRUE --- so the comparison is within-dataset
# and the paired difference has no between-sample noise. It also means the ML arm
# is a CONTROL: run at nrep = 100000 on the campaign library it must reproduce the
# banked 0.9248, and if it does not, the harness is wrong and the REML number is
# not to be trusted.
#
# The data-generating block below is copied VERBATIM from
#   ../2026-08-04-d117-10group-profile-gate/d117_profile_gate.R
# including the seed formula, so identical seeds produce identical datasets.
# Do not "improve" it --- byte-equivalence with the banked ML arm is the point.
#
#   Rscript --no-init-file d117_reml_arm.R --cell=1 --nrep=200 --cores=8 \
#       --outdir=OUT --repo=/path/to/drmTMB
#
# Cells are the D-117 indices: 1 = g10_n10_sd05, 4 = g10_n04_sd05,
# 5 = g10_n04_sd10, 6 = g10_n10_sd10.

args <- commandArgs(trailingOnly = TRUE)
arg_of <- function(k, default = NA_character_) {
  hit <- grep(sprintf("^--%s=", k), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(sprintf("^--%s=", k), "", hit[[1L]])
}

cell_i  <- as.integer(arg_of("cell"))
n_rep   <- as.integer(arg_of("nrep", "200"))
n_cores <- as.integer(arg_of("cores", "1"))
out_dir <- arg_of("outdir", "results")
repo    <- arg_of("repo")

if (is.na(cell_i)) stop("--cell is required.", call. = FALSE)

script_dir <- local({
  f <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(f)) dirname(normalizePath(sub("^--file=", "", f[[1L]]))) else getwd()
})
source(file.path(script_dir, "a1_profile_common.R"))

if (!is.na(repo)) {
  if (!requireNamespace("pkgload", quietly = TRUE)) stop("pkgload required.", call. = FALSE)
  pkgload::load_all(repo, quiet = TRUE)
} else {
  library(drmTMB)
}

# --- the grid (identical to the ML gate) -----------------------------------
GRID <- data.frame(
  cell_i   = c(1L, 4L, 5L, 6L),
  n_groups = c(10L, 10L, 10L, 10L),
  n_per    = c(10L, 4L, 4L, 10L),
  sd_mu    = c(0.5, 0.5, 1.0, 1.0),
  cell_id  = c("g10_n10_sd05", "g10_n04_sd05", "g10_n04_sd10", "g10_n10_sd10"),
  kind     = c("reproduction", "new", "new", "new"),
  stringsAsFactors = FALSE
)
cell <- GRID[GRID$cell_i == cell_i, , drop = FALSE]
if (nrow(cell) != 1L) stop("Unknown cell index: ", cell_i, call. = FALSE)

TRUE_BETA  <- 0.5
TRUE_SIGMA <- 0.7
TARGET     <- "sd:mu:(1 | g)"

sha256_of <- function(path) {
  cmd <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else if (nzchar(Sys.which("shasum"))) "shasum" else NA_character_
  if (is.na(cmd) || !file.exists(path)) return(NA_character_)
  a <- if (identical(cmd, "shasum")) c("-a", "256", path) else path
  o <- suppressWarnings(system2(cmd, a, stdout = TRUE, stderr = FALSE))
  if (length(o)) strsplit(o[[1L]], "[[:space:]]+")[[1L]][[1L]] else NA_character_
}
SOURCE_HASH <- sha256_of(file.path(script_dir, "d117_reml_arm.R"))
HELPER_HASH <- sha256_of(file.path(script_dir, "a1_profile_common.R"))
PKG_COMMIT  <- Sys.getenv("DRMTMB_COMMIT", unset = NA_character_)
PKG_VERSION <- as.character(utils::packageVersion("drmTMB"))

# One estimator arm: fit, extract the SD estimate, profile the interval.
# `reml` is passed straight through to drmTMB(REML=). A fit that errors returns
# a row whose status says so rather than a silently dropped replicate.
one_arm <- function(dat, reml) {
  out <- list(
    fit_converged = FALSE, pdHess = NA, estimate_sd = NA_real_,
    profile_status = "not_run", profile_engine = NA_character_,
    profile_boundary = NA, profile_conf_status = NA_character_,
    profile_message = NA_character_, profile_lower = NA_real_,
    profile_upper = NA_real_, profile_width = NA_real_, profile_covers = NA,
    profile_miss_direction = NA_character_, outer_status = "outer_fit_failed",
    reml_flag = NA
  )
  fit <- try(drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(),
                    data = dat, REML = reml), silent = TRUE)
  if (inherits(fit, "try-error")) {
    out$profile_message <- as.character(fit)
    return(out)
  }
  # Engagement receipt: read the flag back off the fitted object rather than
  # trusting that the argument was honoured. A silently-ignored REML= would
  # otherwise look like "REML does not help".
  out$reml_flag <- tryCatch({
    v <- fit$REML
    if (is.null(v)) v <- fit$call$REML
    if (is.null(v)) NA else isTRUE(as.logical(v))
  }, error = function(e) NA)

  out$fit_converged <- isTRUE(fit$opt$convergence == 0L)
  out$pdHess <- isTRUE(fit$sdr$pdHess)

  pars <- summary(fit)$parameters
  est  <- pars$estimate[pars$parm == TARGET]
  out$estimate_sd <- if (length(est) == 1L) est else NA_real_

  prof_ci <- suppressWarnings(try(
    stats::confint(fit, parm = "variance_components", method = "profile",
                   profile_engine = "auto"), silent = TRUE))
  prof <- a1_interval_row(prof_ci, TARGET, cell$sd_mu, "profile")
  out$profile_status <- prof$status
  out$profile_engine <- prof$profile_engine
  out$profile_boundary <- prof$profile_boundary
  out$profile_conf_status <- prof$profile_conf_status
  out$profile_message <- prof$profile_message
  out$profile_lower <- prof$lower
  out$profile_upper <- prof$upper
  out$profile_width <- prof$width
  out$profile_covers <- prof$covers
  out$profile_miss_direction <- prof$miss_direction
  out$outer_status <- if (out$fit_converged) "ok" else "outer_not_converged"
  out
}

one_rep <- function(r) {
  # --- VERBATIM from d117_profile_gate.R: seed formula and DGP --------------
  seed <- 20260727L + 100000L * cell$cell_i + r
  set.seed(seed)
  g <- factor(rep(seq_len(cell$n_groups), each = cell$n_per))
  x <- rnorm(length(g))
  u <- rnorm(cell$n_groups, 0, cell$sd_mu)
  y <- 1 + TRUE_BETA * x + u[as.integer(g)] + rnorm(length(g), 0, TRUE_SIGMA)
  dat <- data.frame(y = y, x = x, g = g)
  # -------------------------------------------------------------------------

  base <- list(
    study_id = "d117_reml_arm", cell_id = cell$cell_id,
    cell_kind = cell$kind, seed = seed, attempt_id = r, truth_sd = cell$sd_mu,
    n_groups = cell$n_groups, n_per_group = cell$n_per,
    package_commit = PKG_COMMIT, package_version = PKG_VERSION,
    source_hash = SOURCE_HASH, helper_hash = HELPER_HASH,
    host = unname(Sys.info()[["nodename"]]),
    timestamp = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )

  t0 <- Sys.time()
  # Two independent fits of the SAME data. Each drmTMB() call builds its own
  # AD object, so the REML fit cannot warm-start from the ML fit's inner
  # optimisation -- the false-pass mechanism that a reused MakeADFun() creates.
  ml   <- one_arm(dat, reml = FALSE)
  reml <- one_arm(dat, reml = TRUE)

  names(ml)   <- paste0(names(ml),   "_ml")
  names(reml) <- paste0(names(reml), "_reml")

  as.data.frame(c(base, ml, reml, list(
    elapsed_sec = as.numeric(difftime(Sys.time(), t0, units = "secs"))
  )), stringsAsFactors = FALSE)
}

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
res <- if (n_cores > 1L) {
  parallel::mclapply(seq_len(n_rep), one_rep, mc.cores = n_cores, mc.preschedule = TRUE)
} else {
  lapply(seq_len(n_rep), one_rep)
}
bad <- vapply(res, function(z) !is.data.frame(z), logical(1))
if (any(bad)) stop(sprintf("%d replicate(s) returned a non-data.frame (mclapply error).", sum(bad)), call. = FALSE)

out <- do.call(rbind, res)
f <- file.path(out_dir, sprintf("%s.csv", cell$cell_id))
write.csv(out, f, row.names = FALSE)

cov_ml   <- mean(!is.na(out$profile_covers_ml)   & out$profile_covers_ml)
cov_reml <- mean(!is.na(out$profile_covers_reml) & out$profile_covers_reml)
cat("WROTE", f, "rows", nrow(out), "\n")
cat("  coverage(profile, ML,   all-attempt) =", sprintf("%.4f", cov_ml), "\n")
cat("  coverage(profile, REML, all-attempt) =", sprintf("%.4f", cov_reml), "\n")
cat("  paired delta (REML - ML)             =", sprintf("%+.4f", cov_reml - cov_ml), "\n")
cat("  finite intervals ML / REML =", sum(out$profile_status_ml == "valid"), "/",
    sum(out$profile_status_reml == "valid"), "of", nrow(out), "\n")
cat("  mean SD estimate ML / REML =", sprintf("%.4f", mean(out$estimate_sd_ml, na.rm = TRUE)),
    "/", sprintf("%.4f", mean(out$estimate_sd_reml, na.rm = TRUE)),
    " (truth", cell$sd_mu, ")\n")
cat("  ENGAGEMENT: rows where REML estimate != ML estimate =",
    sum(is.finite(out$estimate_sd_ml) & is.finite(out$estimate_sd_reml) &
          out$estimate_sd_ml != out$estimate_sd_reml), "of", nrow(out), "\n")
cat("  reml_flag read back from fit (REML arm):",
    paste(unique(out$reml_flag_reml), collapse = ","), "\n")
