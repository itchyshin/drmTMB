# mc-0242 — Gamma sigma random-intercept RE-SD interval + coverage campaign.
#
# Provenance: structure adapted from the Arc-4a DG3 profile harness
# docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/generate-profile.R
# (iid-uncentered, one raw row per replicate, summary reconstructed from raw).
# Gamma-only; adds per-M RE-SD point-bias reporting at the coverage fixture and a
# SMOKE mode that gates the campaign. Frozen design: scratchpad/mc0242-gamma-sigma-gate-spec.md (rev 2).
#
# Estimand: population SD of the sigma random intercept on the log-CV scale, true 0.40.
# Interval scored on the NATURAL RE-SD scale (confint transformation="exp"; Wald exp()s the SE):
#   coverage = 1{ 0.40 in [exp(L_int), exp(U_int)] }.
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

is_true <- function(x) tolower(trimws(x)) %in% c("1", "true", "yes")

repo_root <- normalizePath(Sys.getenv("DRMTMB_REPO", "."), mustWork = FALSE)
description <- file.path(repo_root, "DESCRIPTION")
is_repo <- file.exists(description) &&
  any(grepl("^Package: drmTMB$", readLines(description, warn = FALSE)))
allow_installed <- is_true(Sys.getenv("ALLOW_INSTALLED", "false"))

if (is_repo) {
  if (!requireNamespace("pkgload", quietly = TRUE)) {
    stop("pkgload is required to compile and load drmTMB from the repository.")
  }
  suppressWarnings(suppressMessages(pkgload::load_all(repo_root)))
  source_mode <- "pkgload::load_all"
} else if (allow_installed) {
  suppressWarnings(suppressMessages(library(drmTMB)))
  source_mode <- "installed_package_escape"
} else {
  stop("Run from the drmTMB repository (or set DRMTMB_REPO). ",
       "Set ALLOW_INSTALLED=true only for an explicit installed-package escape.")
}

suppressWarnings(suppressMessages(library(parallel)))

as_positive_integer <- function(name, default) {
  value <- suppressWarnings(as.integer(Sys.getenv(name, default)))
  if (length(value) != 1L || is.na(value) || value < 1L) {
    stop(name, " must be a positive integer.")
  }
  value
}

SMOKE <- is_true(Sys.getenv("SMOKE", "false"))
NSIM <- if (SMOKE) 1L else as_positive_integer("NSIM", "1200")
NCORES_REQUESTED <- as_positive_integer("NCORES", "90")
MS <- suppressWarnings(as.integer(
  strsplit(Sys.getenv("MS", "8,16,32,64"), ",", fixed = TRUE)[[1L]]
))
NEACH <- as_positive_integer("NEACH", "12")
SEED_BASE <- 20260900L
TRUE_SD <- 0.4
if (length(MS) < 1L || anyNA(MS) || any(MS < 1L)) {
  stop("MS must be a comma-separated list of positive integers.")
}

NCORES_DETECTED <- suppressWarnings(parallel::detectCores(logical = TRUE))
if (length(NCORES_DETECTED) != 1L || is.na(NCORES_DETECTED)) NCORES_DETECTED <- 1L
NCORES_ACTUAL <- min(NCORES_REQUESTED, 90L, NCORES_DETECTED)

DEFAULT_OUTPUT_DIR <- file.path(
  "docs", "dev-log", "simulation-artifacts", "2026-07-17-gamma-sigma-re-coverage"
)
OUTPUT_DIR <- path.expand(Sys.getenv("OUTPUT_DIR", DEFAULT_OUTPUT_DIR))
suffix <- if (SMOKE) "smoke" else "iid"
RAW_OUTPUT <- file.path(OUTPUT_DIR, sprintf("coverage-results-%s-raw.tsv", suffix))
SUMMARY_OUTPUT <- file.path(OUTPUT_DIR, sprintf("coverage-results-%s-summary.tsv", suffix))
MANIFEST_OUTPUT <- file.path(OUTPUT_DIR, sprintf("coverage-results-%s-manifest.tsv", suffix))
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

git_value <- function(args) {
  if (!is_repo) return(NA_character_)
  out <- tryCatch(system2("git", c("-C", shQuote(repo_root), args),
                          stdout = TRUE, stderr = FALSE),
                  error = function(e) character())
  if (length(out) == 0L) NA_character_ else paste(out, collapse = "\n")
}
GIT_SHA <- git_value(c("rev-parse", "HEAD"))
PACKAGE_VERSION <- as.character(utils::packageVersion("drmTMB"))
GENERATED_AT_UTC <- format(Sys.time(), tz = "UTC", usetz = TRUE)
HOST <- unname(Sys.info()[["nodename"]])
Z <- stats::qnorm(0.975)

# --- the frozen Gamma(CV, log) sigma-RE spec (gate-spec rev 2 §2) --------------
gamma_sigma <- list(
  true_sd = TRUE_SD,
  sdrow   = "log_sd_sigma",
  sd_parm = "sd:sigma:(1 | id)",
  fit = function(d) {
    drmTMB(bf(y ~ x, sigma ~ (1 | id)), family = Gamma(link = "log"), data = d)
  },
  sim = function(M, ne, seed) {
    set.seed(seed)
    id <- factor(rep(seq_len(M), each = ne)); n <- length(id)
    x  <- stats::rnorm(n)
    u  <- stats::rnorm(M, sd = TRUE_SD)       # IID, UNCENTERED
    mu <- exp(0.2 + 0.5 * x)
    cv <- exp(-0.6 + u[id])
    data.frame(y = stats::rgamma(n, shape = 1 / cv^2, scale = mu * cv^2), x = x, id = id)
  }
)

empty_replicate <- function(M, seed) {
  data.frame(
    spec = "gamma_sigma", M = M, seed = seed,
    fit_status = NA_character_, fit_error = NA_character_,
    convergence = NA_integer_, pdHess = NA,
    sd_hat = NA_real_,                         # exp(estimate) = natural-scale RE-SD point estimate
    wald_lower = NA_real_, wald_upper = NA_real_, wald_covered = NA,
    wald_upper_infinite = NA, wald_width = NA_real_,
    profile_lower = NA_real_, profile_upper = NA_real_,
    profile_conf_status = NA_character_, profile_error = NA_character_,
    profile_finite = FALSE, profile_covered = NA,
    truth_below_interval = NA, truth_above_interval = NA, profile_width = NA_real_,
    stringsAsFactors = FALSE
  )
}

one <- function(spec, M, ne, seed, true_sd) {
  out <- empty_replicate(M, seed)
  d <- spec$sim(M, ne, seed)
  fit_error <- NULL
  fit <- tryCatch(spec$fit(d), error = function(e) { fit_error <<- conditionMessage(e); NULL })
  if (is.null(fit)) { out$fit_status <- "fit_error"; out$fit_error <- fit_error; return(out) }

  out$convergence <- suppressWarnings(as.integer(fit$opt$convergence[[1L]]))
  out$pdHess <- isTRUE(fit$sdr$pdHess)
  if (!isTRUE(out$convergence == 0L)) { out$fit_status <- "nonconverged"; return(out) }
  if (!isTRUE(out$pdHess)) { out$fit_status <- "pdHess_bad"; return(out) }
  out$fit_status <- "eligible"

  sm <- summary(fit$sdr)
  sd_row <- which(rownames(sm) == spec$sdrow)
  if (length(sd_row) >= 1L) {
    estimate <- sm[sd_row[[1L]], "Estimate"]
    se <- sm[sd_row[[1L]], "Std. Error"]
    out$sd_hat <- exp(estimate)                       # natural-scale point estimate (§2 bias reporting)
    out$wald_lower <- exp(estimate - Z * se)
    out$wald_upper <- exp(estimate + Z * se)
    out$wald_upper_infinite <- !is.finite(out$wald_upper)
    out$wald_covered <- true_sd >= out$wald_lower && true_sd <= out$wald_upper
    if (!out$wald_upper_infinite) out$wald_width <- out$wald_upper - out$wald_lower
  }

  profile_error <- NULL
  ci <- tryCatch(confint(fit, parm = spec$sd_parm, method = "profile"),
                 error = function(e) { profile_error <<- conditionMessage(e); NULL })
  if (!is.null(profile_error)) out$profile_error <- profile_error
  if (!is.null(ci) && nrow(ci) >= 1L) {
    out$profile_lower <- suppressWarnings(as.numeric(ci$lower[[1L]]))
    out$profile_upper <- suppressWarnings(as.numeric(ci$upper[[1L]]))
    out$profile_conf_status <- as.character(ci$conf.status[[1L]])
    out$profile_finite <- identical(out$profile_conf_status, "profile") &&
      is.finite(out$profile_lower) && is.finite(out$profile_upper)
    if (out$profile_finite) {
      out$profile_covered <- true_sd >= out$profile_lower && true_sd <= out$profile_upper
      out$truth_below_interval <- true_sd < out$profile_lower
      out$truth_above_interval <- true_sd > out$profile_upper
      out$profile_width <- out$profile_upper - out$profile_lower
    }
  } else if (is.null(profile_error)) {
    out$profile_error <- "profile returned no rows"
  }
  out
}

exact_binomial_ci <- function(n_cover, n_total) {
  if (n_total < 1L) return(c(low = NA_real_, high = NA_real_))
  stats::setNames(as.numeric(stats::binom.test(n_cover, n_total)$conf.int), c("low", "high"))
}
mean_or_na <- function(x) { x <- x[!is.na(x)]; if (length(x) == 0L) NA_real_ else mean(x) }

summarize_cell <- function(x, true_sd) {
  nsim <- nrow(x)
  n_fit_error <- sum(x$fit_status == "fit_error")
  n_nonconverged <- sum(x$fit_status == "nonconverged")
  n_pdhess_bad <- sum(x$fit_status == "pdHess_bad")
  eligible <- x$fit_status == "eligible"
  n_eligible <- sum(eligible)
  profile_finite <- eligible & x$profile_finite %in% TRUE
  n_profile_finite <- sum(profile_finite)
  n_profile_failed <- sum(eligible & !x$profile_finite %in% TRUE)
  n_cover <- sum(x$profile_covered[profile_finite] %in% TRUE)
  n_below <- sum(x$truth_below_interval[profile_finite] %in% TRUE)
  n_above <- sum(x$truth_above_interval[profile_finite] %in% TRUE)
  stopifnot(
    nsim == n_fit_error + n_nonconverged + n_pdhess_bad + n_eligible,
    n_eligible == n_profile_finite + n_profile_failed,
    n_profile_finite == n_cover + n_below + n_above
  )
  coverage <- if (n_profile_finite > 0L) n_cover / n_profile_finite else NA_real_
  mcse <- if (n_profile_finite > 0L) sqrt(coverage * (1 - coverage) / n_profile_finite) else NA_real_
  ci <- exact_binomial_ci(n_cover, n_profile_finite)
  sd_hat_mean <- mean_or_na(x$sd_hat[eligible])
  data.frame(
    spec = "gamma_sigma", M = x$M[[1L]], nsim = nsim, n_eligible = n_eligible,
    n_fit_error = n_fit_error, n_nonconverged = n_nonconverged, n_pdHess_bad = n_pdhess_bad,
    sd_true = true_sd, neach = NEACH,
    sd_hat_mean = sd_hat_mean,
    rel_bias_mean = if (is.na(sd_hat_mean)) NA_real_ else (sd_hat_mean - true_sd) / true_sd,
    wald_coverage = mean_or_na(x$wald_covered[eligible]),
    wald_hi_inf_rate = mean_or_na(x$wald_upper_infinite[eligible]),
    profile_coverage = coverage, n_cover = n_cover,
    n_truth_below_interval = n_below, n_truth_above_interval = n_above,
    n_profile_finite = n_profile_finite, n_profile_failed = n_profile_failed,
    coverage_mcse = mcse, coverage_exact_ci_low = ci[["low"]], coverage_exact_ci_high = ci[["high"]],
    profile_finite_rate = if (n_eligible > 0L) n_profile_finite / n_eligible else NA_real_,
    profile_width = mean_or_na(x$profile_width[profile_finite]),
    wald_width = mean_or_na(x$wald_width[eligible]),
    stringsAsFactors = FALSE
  )
}

manifest <- data.frame(
  key = c("generated_at_utc", "host", "source_mode", "git_sha", "package_version",
          "smoke", "nsim", "MS", "neach", "true_sd", "seed_base",
          "openblas_num_threads", "ncores_actual", "raw_output", "summary_output"),
  value = c(GENERATED_AT_UTC, HOST, source_mode, GIT_SHA, PACKAGE_VERSION,
            SMOKE, NSIM, paste(MS, collapse = ","), NEACH, TRUE_SD, SEED_BASE,
            Sys.getenv("OPENBLAS_NUM_THREADS"), NCORES_ACTUAL, RAW_OUTPUT, SUMMARY_OUTPUT),
  stringsAsFactors = FALSE
)
write.table(manifest, MANIFEST_OUTPUT, sep = "\t", row.names = FALSE, quote = TRUE)

raw_cells <- list()
for (M in MS) {
  seeds <- SEED_BASE + seq_len(NSIM)
  cell <- parallel::mclapply(seeds, function(s) one(gamma_sigma, M, NEACH, s, TRUE_SD),
                             mc.cores = NCORES_ACTUAL)
  raw_cells[[length(raw_cells) + 1L]] <- do.call(rbind, cell)
  raw <- do.call(rbind, raw_cells)
  write.table(raw, RAW_OUTPUT, sep = "\t", row.names = FALSE, quote = TRUE, na = "NA")
  last <- raw_cells[[length(raw_cells)]]
  cat(sprintf("gamma_sigma M=%-3d attempted=%d eligible=%d profile_finite=%d\n",
              M, nrow(last), sum(last$fit_status == "eligible"),
              sum(last$profile_finite %in% TRUE)))
}

raw <- utils::read.delim(RAW_OUTPUT, stringsAsFactors = FALSE, check.names = FALSE, na.strings = "NA")
summary_tab <- do.call(rbind, lapply(split(raw, raw$M), summarize_cell, true_sd = TRUE_SD))
row.names(summary_tab) <- NULL
write.table(summary_tab, SUMMARY_OUTPUT, sep = "\t", row.names = FALSE, quote = TRUE, na = "NA")

cat("\nWROTE ", RAW_OUTPUT, "\nWROTE ", SUMMARY_OUTPUT, "\nWROTE ", MANIFEST_OUTPUT, "\n", sep = "")

# --- SMOKE STOP criterion (gate-spec rev 2 §6): every M must converge + return a
#     finite in-range profile interval on the coverage fixture, else HALT non-zero. -----
if (SMOKE) {
  fail <- summary_tab[
    summary_tab$n_eligible < 1L | summary_tab$n_profile_finite < 1L, , drop = FALSE
  ]
  if (nrow(fail) > 0L) {
    stop("SMOKE FAILED at M=", paste(fail$M, collapse = ","),
         ": no eligible fit and/or no finite profile interval. HALT before campaign.")
  }
  cat("SMOKE PASSED: all M in {", paste(MS, collapse = ","),
      "} converged with a finite profile interval on the coverage fixture.\n", sep = "")
}
cat("GAMMA-SIGMA-RE ", suffix, " DONE\n", sep = "")
