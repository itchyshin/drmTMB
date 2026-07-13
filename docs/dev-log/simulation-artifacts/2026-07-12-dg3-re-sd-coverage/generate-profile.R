# Arc 4a: DG3 RE-SD coverage, profile interval vs Wald(log-SD).
#
# This IID-v2 campaign keeps one raw row per attempted replicate. The summary is
# reconstructed from that raw TSV so fit failures, interval failures, coverage,
# and tail misses remain independently auditable.
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

is_true <- function(x) {
  tolower(trimws(x)) %in% c("1", "true", "yes")
}

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
  stop(
    "Run from the drmTMB repository (or set DRMTMB_REPO). ",
    "Set ALLOW_INSTALLED=true only for an explicit installed-package escape."
  )
}

suppressWarnings(suppressMessages(library(parallel)))

as_positive_integer <- function(name, default) {
  value <- suppressWarnings(as.integer(Sys.getenv(name, default)))
  if (length(value) != 1L || is.na(value) || value < 1L) {
    stop(name, " must be a positive integer.")
  }
  value
}

NSIM <- as_positive_integer("NSIM", "1200")
NCORES_REQUESTED <- as_positive_integer("NCORES", "90")
MS <- suppressWarnings(as.integer(
  strsplit(Sys.getenv("MS", "8,16,32,64"), ",", fixed = TRUE)[[1L]]
))
NEACH <- as_positive_integer("NEACH", "12")
BINOMIAL_TRIALS <- 12L
SEED_BASE <- 20260900L
if (length(MS) < 1L || anyNA(MS) || any(MS < 1L)) {
  stop("MS must be a comma-separated list of positive integers.")
}

NCORES_DETECTED <- suppressWarnings(parallel::detectCores(logical = TRUE))
if (length(NCORES_DETECTED) != 1L || is.na(NCORES_DETECTED)) {
  NCORES_DETECTED <- 1L
}
NCORES_ACTUAL <- min(NCORES_REQUESTED, 90L, NCORES_DETECTED)

LOCAL_OUTPUT_DIR <- file.path(
  "docs", "dev-log", "simulation-artifacts",
  "2026-07-12-dg3-re-sd-coverage"
)
DEFAULT_OUTPUT_DIR <- if (dir.exists(LOCAL_OUTPUT_DIR)) {
  LOCAL_OUTPUT_DIR
} else {
  "~/drmTMB_work"
}
OUTPUT_DIR <- path.expand(Sys.getenv("OUTPUT_DIR", DEFAULT_OUTPUT_DIR))
RAW_OUTPUT <- path.expand(Sys.getenv(
  "RAW_OUTPUT",
  file.path(OUTPUT_DIR, "profile-coverage-results-iid-v2-raw.tsv")
))
SUMMARY_OUTPUT <- path.expand(Sys.getenv(
  "SUMMARY_OUTPUT",
  file.path(OUTPUT_DIR, "profile-coverage-results-iid-v2-summary.tsv")
))
MANIFEST_OUTPUT <- path.expand(Sys.getenv(
  "MANIFEST_OUTPUT",
  file.path(OUTPUT_DIR, "profile-coverage-results-iid-v2-manifest.tsv")
))
for (path in unique(dirname(c(RAW_OUTPUT, SUMMARY_OUTPUT, MANIFEST_OUTPUT)))) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

git_value <- function(args) {
  if (!is_repo) return(NA_character_)
  out <- tryCatch(
    system2(
      "git",
      c("-C", shQuote(repo_root), args),
      stdout = TRUE,
      stderr = FALSE
    ),
    error = function(e) character()
  )
  if (length(out) == 0L) NA_character_ else paste(out, collapse = "\n")
}

GIT_SHA <- git_value(c("rev-parse", "HEAD"))
GIT_DIRTY <- !is.na(git_value(c("status", "--porcelain")))
PACKAGE_VERSION <- as.character(utils::packageVersion("drmTMB"))
GENERATED_AT_UTC <- format(Sys.time(), tz = "UTC", usetz = TRUE)
HOST <- unname(Sys.info()[["nodename"]])
COMMAND <- paste(c("Rscript", commandArgs(trailingOnly = FALSE)), collapse = " ")
SCRIPT_ARGUMENT <- grep(
  "^--file=", commandArgs(trailingOnly = FALSE), value = TRUE
)
GENERATOR_PATH <- if (length(SCRIPT_ARGUMENT) == 1L) {
  normalizePath(sub("^--file=", "", SCRIPT_ARGUMENT), mustWork = TRUE)
} else {
  NA_character_
}
GENERATOR_MD5 <- if (!is.na(GENERATOR_PATH)) {
  unname(tools::md5sum(GENERATOR_PATH))
} else {
  NA_character_
}
SEED_DESIGN <- paste0(
  "reused seed labels: seeds ", SEED_BASE, " + 1:NSIM are reused across ",
  "every spec x M cell; different M values consume different-length RNG streams"
)
Z <- stats::qnorm(0.975)

specs <- list(
  gaussian_slope = list(
    true_sd = 0.6,
    sdrow = "log_sd_mu",
    sd_parm = "sd:mu:(0 + x | id)",
    fit = function(d) {
      drmTMB(bf(y ~ x + (0 + x | id)), family = gaussian(), data = d)
    },
    sim = function(M, ne, seed) {
      set.seed(seed)
      id <- factor(rep(seq_len(M), each = ne))
      n <- length(id)
      x <- stats::rnorm(n)
      u <- stats::rnorm(M, sd = 0.6)
      data.frame(
        y = 0.2 + 0.7 * x + u[id] * x + stats::rnorm(n),
        x = x,
        id = id
      )
    }
  ),
  binomial_slope = list(
    true_sd = 0.6,
    sdrow = "log_sd_mu",
    sd_parm = "sd:mu:(0 + x | id)",
    fit = function(d) {
      drmTMB(
        bf(cbind(succ, fail) ~ x + (0 + x | id)),
        family = binomial(),
        data = d
      )
    },
    sim = function(M, ne, seed) {
      set.seed(seed)
      id <- factor(rep(seq_len(M), each = ne))
      n <- length(id)
      x <- stats::rnorm(n)
      u <- stats::rnorm(M, sd = 0.6)
      p <- stats::plogis(-0.2 + 0.7 * x + u[id] * x)
      succ <- stats::rbinom(n, BINOMIAL_TRIALS, p)
      data.frame(
        succ = succ,
        fail = BINOMIAL_TRIALS - succ,
        x = x,
        id = id
      )
    }
  ),
  lognormal_sigma = list(
    true_sd = 0.4,
    sdrow = "log_sd_sigma",
    sd_parm = "sd:sigma:(1 | id)",
    fit = function(d) {
      drmTMB(
        bf(y ~ x, sigma ~ (1 | id)),
        family = lognormal(),
        data = d
      )
    },
    sim = function(M, ne, seed) {
      set.seed(seed)
      id <- factor(rep(seq_len(M), each = ne))
      n <- length(id)
      x <- stats::rnorm(n)
      u <- stats::rnorm(M, sd = 0.4)
      sdlog <- exp(-0.5 + u[id])
      data.frame(
        y = stats::rlnorm(n, meanlog = 0.2 + 0.5 * x, sdlog = sdlog),
        x = x,
        id = id
      )
    }
  )
)

empty_replicate <- function(spec_name, M, seed) {
  data.frame(
    spec = spec_name,
    M = M,
    seed = seed,
    fit_status = NA_character_,
    fit_error = NA_character_,
    convergence = NA_integer_,
    pdHess = NA,
    wald_lower = NA_real_,
    wald_upper = NA_real_,
    wald_covered = NA,
    wald_upper_infinite = NA,
    wald_width = NA_real_,
    profile_lower = NA_real_,
    profile_upper = NA_real_,
    profile_conf_status = NA_character_,
    profile_error = NA_character_,
    profile_finite = FALSE,
    profile_covered = NA,
    truth_below_interval = NA,
    truth_above_interval = NA,
    profile_width = NA_real_,
    stringsAsFactors = FALSE
  )
}

one <- function(spec_name, spec, M, ne, seed) {
  out <- empty_replicate(spec_name, M, seed)
  d <- spec$sim(M, ne, seed)
  fit_error <- NULL
  fit <- tryCatch(
    spec$fit(d),
    error = function(e) {
      fit_error <<- conditionMessage(e)
      NULL
    }
  )
  if (is.null(fit)) {
    out$fit_status <- "fit_error"
    out$fit_error <- fit_error
    return(out)
  }

  out$convergence <- suppressWarnings(as.integer(fit$opt$convergence[[1L]]))
  out$pdHess <- isTRUE(fit$sdr$pdHess)
  if (!isTRUE(out$convergence == 0L)) {
    out$fit_status <- "nonconverged"
    return(out)
  }
  if (!isTRUE(out$pdHess)) {
    out$fit_status <- "pdHess_bad"
    return(out)
  }
  out$fit_status <- "eligible"

  sm <- summary(fit$sdr)
  sd_row <- which(rownames(sm) == spec$sdrow)
  if (length(sd_row) >= 1L) {
    estimate <- sm[sd_row[[1L]], "Estimate"]
    se <- sm[sd_row[[1L]], "Std. Error"]
    out$wald_lower <- exp(estimate - Z * se)
    out$wald_upper <- exp(estimate + Z * se)
    out$wald_upper_infinite <- !is.finite(out$wald_upper)
    out$wald_covered <- spec$true_sd >= out$wald_lower &&
      spec$true_sd <= out$wald_upper
    if (!out$wald_upper_infinite) {
      out$wald_width <- out$wald_upper - out$wald_lower
    }
  }

  profile_error <- NULL
  ci <- tryCatch(
    confint(fit, parm = spec$sd_parm, method = "profile"),
    error = function(e) {
      profile_error <<- conditionMessage(e)
      NULL
    }
  )
  if (!is.null(profile_error)) {
    out$profile_error <- profile_error
  }
  if (!is.null(ci) && nrow(ci) >= 1L) {
    out$profile_lower <- suppressWarnings(as.numeric(ci$lower[[1L]]))
    out$profile_upper <- suppressWarnings(as.numeric(ci$upper[[1L]]))
    out$profile_conf_status <- as.character(ci$conf.status[[1L]])
    out$profile_finite <- identical(out$profile_conf_status, "profile") &&
      is.finite(out$profile_lower) && is.finite(out$profile_upper)
    if (out$profile_finite) {
      out$profile_covered <- spec$true_sd >= out$profile_lower &&
        spec$true_sd <= out$profile_upper
      out$truth_below_interval <- spec$true_sd < out$profile_lower
      out$truth_above_interval <- spec$true_sd > out$profile_upper
      out$profile_width <- out$profile_upper - out$profile_lower
    }
  } else if (is.null(profile_error)) {
    out$profile_error <- "profile returned no rows"
  }
  out
}

exact_binomial_ci <- function(n_cover, n_total) {
  if (n_total < 1L) return(c(low = NA_real_, high = NA_real_))
  stats::setNames(
    as.numeric(stats::binom.test(n_cover, n_total)$conf.int),
    c("low", "high")
  )
}

mean_or_na <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) NA_real_ else mean(x)
}

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
  n_truth_below_interval <- sum(
    x$truth_below_interval[profile_finite] %in% TRUE
  )
  n_truth_above_interval <- sum(
    x$truth_above_interval[profile_finite] %in% TRUE
  )

  stopifnot(
    nsim == n_fit_error + n_nonconverged + n_pdhess_bad + n_eligible,
    n_eligible == n_profile_finite + n_profile_failed,
    n_profile_finite == n_cover + n_truth_below_interval +
      n_truth_above_interval
  )

  coverage <- if (n_profile_finite > 0L) {
    n_cover / n_profile_finite
  } else {
    NA_real_
  }
  coverage_mcse <- if (n_profile_finite > 0L) {
    sqrt(coverage * (1 - coverage) / n_profile_finite)
  } else {
    NA_real_
  }
  coverage_ci <- exact_binomial_ci(n_cover, n_profile_finite)

  data.frame(
    spec = x$spec[[1L]],
    M = x$M[[1L]],
    n_ok = n_eligible,
    nsim = nsim,
    n_fit_error = n_fit_error,
    n_nonconverged = n_nonconverged,
    n_pdHess_bad = n_pdhess_bad,
    n_eligible = n_eligible,
    sd_true = true_sd,
    neach = NEACH,
    binomial_trials = if (identical(x$spec[[1L]], "binomial_slope")) {
      BINOMIAL_TRIALS
    } else {
      NA_integer_
    },
    seed_base = SEED_BASE,
    seed_design = SEED_DESIGN,
    ncores_actual = NCORES_ACTUAL,
    wald_coverage = mean_or_na(x$wald_covered[eligible]),
    wald_hi_inf_rate = mean_or_na(x$wald_upper_infinite[eligible]),
    profile_coverage = coverage,
    n_cover = n_cover,
    n_truth_below_interval = n_truth_below_interval,
    n_truth_above_interval = n_truth_above_interval,
    n_profile_finite = n_profile_finite,
    n_profile_failed = n_profile_failed,
    coverage_mcse = coverage_mcse,
    coverage_exact_ci_low = coverage_ci[["low"]],
    coverage_exact_ci_high = coverage_ci[["high"]],
    profile_finite_rate = if (n_eligible > 0L) {
      n_profile_finite / n_eligible
    } else {
      NA_real_
    },
    profile_failed_rate = if (n_eligible > 0L) {
      n_profile_failed / n_eligible
    } else {
      NA_real_
    },
    profile_width = mean_or_na(x$profile_width[profile_finite]),
    wald_width = mean_or_na(x$wald_width[eligible]),
    stringsAsFactors = FALSE
  )
}

manifest <- data.frame(
  key = c(
    "generated_at_utc", "command", "host", "source_mode", "allow_installed",
    "repo_root", "git_sha", "git_dirty", "package_version",
    "generator_path", "generator_md5", "nsim", "MS",
    "neach", "binomial_trials", "seed_base", "seed_design",
    "openblas_num_threads", "ncores_requested", "ncores_detected",
    "ncores_actual", "raw_output", "summary_output", "manifest_output"
  ),
  value = c(
    GENERATED_AT_UTC, COMMAND, HOST, source_mode, allow_installed,
    if (is_repo) repo_root else NA_character_, GIT_SHA, GIT_DIRTY,
    PACKAGE_VERSION, GENERATOR_PATH, GENERATOR_MD5, NSIM,
    paste(MS, collapse = ","), NEACH, BINOMIAL_TRIALS,
    SEED_BASE, SEED_DESIGN, Sys.getenv("OPENBLAS_NUM_THREADS"),
    NCORES_REQUESTED, NCORES_DETECTED, NCORES_ACTUAL, RAW_OUTPUT,
    SUMMARY_OUTPUT, MANIFEST_OUTPUT
  ),
  stringsAsFactors = FALSE
)
write.table(
  manifest,
  MANIFEST_OUTPUT,
  sep = "\t",
  row.names = FALSE,
  quote = TRUE
)

raw_cells <- list()
for (spec_name in names(specs)) {
  spec <- specs[[spec_name]]
  for (M in MS) {
    seeds <- SEED_BASE + seq_len(NSIM)
    cell <- parallel::mclapply(
      seeds,
      function(seed) one(spec_name, spec, M, NEACH, seed),
      mc.cores = NCORES_ACTUAL
    )
    raw_cells[[length(raw_cells) + 1L]] <- do.call(rbind, cell)
    raw <- do.call(rbind, raw_cells)
    write.table(
      raw,
      RAW_OUTPUT,
      sep = "\t",
      row.names = FALSE,
      quote = TRUE,
      na = "NA"
    )
    cat(sprintf(
      "%-16s M=%-3d attempted=%d eligible=%d profile_finite=%d\n",
      spec_name,
      M,
      nrow(raw_cells[[length(raw_cells)]]),
      sum(raw_cells[[length(raw_cells)]]$fit_status == "eligible"),
      sum(raw_cells[[length(raw_cells)]]$profile_finite %in% TRUE)
    ))
  }
}

# Re-read the retained raw artifact: the published summary has no hidden state.
raw <- utils::read.delim(
  RAW_OUTPUT,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = "NA"
)
cell_keys <- interaction(raw$spec, raw$M, drop = TRUE, lex.order = TRUE)
summary_rows <- lapply(split(raw, cell_keys), function(x) {
  summarize_cell(x, specs[[x$spec[[1L]]]]$true_sd)
})
summary_tab <- do.call(rbind, summary_rows)
row.names(summary_tab) <- NULL
write.table(
  summary_tab,
  SUMMARY_OUTPUT,
  sep = "\t",
  row.names = FALSE,
  quote = TRUE,
  na = "NA"
)

cat(
  "\nWROTE ", RAW_OUTPUT,
  "\nWROTE ", SUMMARY_OUTPUT,
  "\nWROTE ", MANIFEST_OUTPUT,
  "\nDG3-PROFILE IID-V2 DONE\n",
  sep = ""
)
