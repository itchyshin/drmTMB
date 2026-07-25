# Arc 6 direct bivariate-lognormal rho12 coverage campaign.
#
# This driver is deliberately self-contained so a committed source checkout can
# run it on Totoro after `R CMD INSTALL`. It retains every outer-fit attempt and
# every interval status. The reported conditional coverage denominator is named
# explicitly; unsuccessful interval attempts are never silently discarded.
#
# Environment:
#   NSIM (300), BOOTSTRAP_R (199), NCORES (90), SEED_BASE (2026072406),
#   OUTDIR (docs/dev-log/simulation-artifacts/2026-07-24-biv-lognormal-rho12-coverage),
#   SMOKE (false).  Set SMOKE=true only for the non-empty local gate.

suppressWarnings(Sys.setenv(OPENBLAS_NUM_THREADS = "1"))

env_value <- function(name, default) {
  value <- Sys.getenv(name)
  if (nzchar(value)) value else default
}

as_flag <- function(value) {
  tolower(value) %in% c("true", "1", "yes")
}

NSIM <- as.integer(env_value("NSIM", "300"))
BOOTSTRAP_R <- as.integer(env_value("BOOTSTRAP_R", "199"))
NCORES <- as.integer(env_value("NCORES", "90"))
SEED_BASE <- as.integer(env_value("SEED_BASE", "2026072406"))
SMOKE <- as_flag(env_value("SMOKE", "false"))
QUIET <- as_flag(env_value("QUIET", "false"))
OUTDIR <- env_value(
  "OUTDIR",
  file.path(
    "docs", "dev-log", "simulation-artifacts",
    "2026-07-24-biv-lognormal-rho12-coverage"
  )
)

if (!requireNamespace("drmTMB", quietly = TRUE)) {
  stop("Install this drmTMB checkout before running the coverage driver.")
}
if (!requireNamespace("parallel", quietly = TRUE)) {
  stop("The base parallel package is required.")
}
if (is.na(NSIM) || NSIM < 1L || is.na(BOOTSTRAP_R) || BOOTSTRAP_R < 2L) {
  stop("`NSIM` must be positive and `BOOTSTRAP_R` must be at least two.")
}
if (is.na(NCORES) || NCORES < 1L || NCORES > 100L) {
  stop("`NCORES` must be between 1 and 100 under the Totoro shared-host limit.")
}
if (SMOKE) {
  NSIM <- 1L
  BOOTSTRAP_R <- min(BOOTSTRAP_R, 9L)
}

conditions <- expand.grid(
  n = c(100L, 300L, 1000L),
  rho12_truth = c(0, 0.5, 0.85),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
conditions$cell_id <- sprintf(
  "n%04d_rho%03d",
  conditions$n,
  round(100 * conditions$rho12_truth)
)

dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
OUTDIR <- normalizePath(OUTDIR, mustWork = TRUE)
raw_path <- file.path(OUTDIR, "direct-biv-lognormal-rho12-attempts.csv")
bootstrap_path <- file.path(OUTDIR, "direct-biv-lognormal-rho12-bootstrap-attempts.csv")
summary_path <- file.path(OUTDIR, "direct-biv-lognormal-rho12-summary.csv")
manifest_path <- file.path(OUTDIR, "direct-biv-lognormal-rho12-manifest.csv")
if (any(file.exists(c(raw_path, bootstrap_path, summary_path, manifest_path)))) {
  stop("Coverage output already exists; choose a new OUTDIR rather than overwrite it.")
}

draw_data <- function(cell, seed) {
  set.seed(seed)
  n <- cell$n[[1L]]
  x <- stats::rnorm(n)
  sigma1 <- 0.4
  sigma2 <- 0.7
  rho <- cell$rho12_truth[[1L]]
  e1 <- stats::rnorm(n)
  e2 <- rho * e1 + sqrt(1 - rho^2) * stats::rnorm(n)
  data.frame(
    y1 = exp(0.35 + 0.45 * x + sigma1 * e1),
    y2 = exp(-0.15 - 0.30 * x + sigma2 * e2),
    x = x
  )
}

empty_interval <- function(method) {
  list(
    status = paste0(method, "_error"),
    lower = NA_real_,
    upper = NA_real_,
    message = NA_character_,
    bootstrap_success = NA_integer_,
    bootstrap_failed = NA_integer_
  )
}

extract_interval <- function(result, method) {
  out <- empty_interval(method)
  if (inherits(result, "error")) {
    out$message <- conditionMessage(result)
    return(out)
  }
  out$status <- result$conf.status[[1L]]
  out$lower <- result$lower[[1L]]
  out$upper <- result$upper[[1L]]
  out$message <- result$profile.message[[1L]]
  if (identical(method, "bootstrap")) {
    out$bootstrap_success <- result$bootstrap.n[[1L]]
    out$bootstrap_failed <- result$bootstrap.failed[[1L]]
  }
  out
}

one_attempt <- function(task) {
  cell <- conditions[conditions$cell_id == task$cell_id, , drop = FALSE]
  dat <- draw_data(cell, task$seed)
  fit <- tryCatch(
    drmTMB::drmTMB(
      drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
      family = drmTMB::biv_lognormal(), data = dat
    ),
    error = function(error) error
  )
  base <- data.frame(
    cell_id = task$cell_id,
    n = cell$n[[1L]],
    rho12_truth = cell$rho12_truth[[1L]],
    replicate = task$replicate,
    seed = task$seed,
    fit_ok = !inherits(fit, "error"),
    convergence = NA_integer_,
    pdHess = NA,
    rho12_estimate = NA_real_,
    fit_message = NA_character_,
    stringsAsFactors = FALSE
  )
  for (method in c("wald", "profile", "bootstrap")) {
    base[[paste0(method, "_status")]] <- NA_character_
    base[[paste0(method, "_lower")]] <- NA_real_
    base[[paste0(method, "_upper")]] <- NA_real_
    base[[paste0(method, "_message")]] <- NA_character_
    base[[paste0(method, "_covered")]] <- NA
  }
  base$bootstrap_success <- NA_integer_
  base$bootstrap_failed <- NA_integer_
  if (inherits(fit, "error")) {
    base$fit_message <- conditionMessage(fit)
    return(list(attempt = base, bootstrap_attempts = data.frame()))
  }
  base$convergence <- fit$opt$convergence
  base$pdHess <- fit$sdr$pdHess
  # `rho12(fit)` is rowwise fitted association; this campaign has an
  # intercept-only target, so retain its coefficient-scale estimate once.
  base$rho12_estimate <- 0.999999 * tanh(unname(stats::coef(fit, dpar = "rho12")[[1L]]))
  methods <- list(
    wald = tryCatch(
      stats::confint(fit, parm = "rho12", method = "wald"),
      error = function(error) error
    ),
    profile = tryCatch(
      stats::confint(fit, parm = "rho12", method = "profile", profile_engine = "endpoint"),
      error = function(error) error
    ),
    bootstrap = tryCatch(
      stats::confint(
        fit, parm = "rho12", method = "bootstrap", R = BOOTSTRAP_R,
        seed = task$bootstrap_seed
      ),
      error = function(error) error
    )
  )
  bootstrap_attempts <- data.frame()
  for (method in names(methods)) {
    interval <- extract_interval(methods[[method]], method)
    base[[paste0(method, "_status")]] <- interval$status
    base[[paste0(method, "_lower")]] <- interval$lower
    base[[paste0(method, "_upper")]] <- interval$upper
    base[[paste0(method, "_message")]] <- interval$message
    base[[paste0(method, "_covered")]] <- is.finite(interval$lower) &&
      is.finite(interval$upper) &&
      cell$rho12_truth[[1L]] >= interval$lower &&
      cell$rho12_truth[[1L]] <= interval$upper
    if (identical(method, "bootstrap")) {
      base$bootstrap_success <- interval$bootstrap_success
      base$bootstrap_failed <- interval$bootstrap_failed
      details <- attr(methods[[method]], "bootstrap.diagnostics", exact = TRUE)
      if (is.data.frame(details)) {
        details$cell_id <- task$cell_id
        details$n <- cell$n[[1L]]
        details$rho12_truth <- cell$rho12_truth[[1L]]
        details$outer_replicate <- task$replicate
        details$outer_seed <- task$seed
        details$outer_bootstrap_seed <- task$bootstrap_seed
        bootstrap_attempts <- details
      }
    }
  }
  list(attempt = base, bootstrap_attempts = bootstrap_attempts)
}

tasks <- do.call(rbind, lapply(seq_len(nrow(conditions)), function(i) {
  data.frame(
    cell_id = conditions$cell_id[[i]],
    replicate = seq_len(NSIM),
    seed = SEED_BASE + i * 100000L + seq_len(NSIM),
    bootstrap_seed = SEED_BASE + i * 100000L + 50000L + seq_len(NSIM),
    stringsAsFactors = FALSE
  )
}))

if (!QUIET) message(sprintf(
  "Arc 6 direct biv_lognormal rho12 coverage: cells=%d, NSIM=%d, bootstrap=%d, cores=%d, smoke=%s",
  nrow(conditions), NSIM, BOOTSTRAP_R, NCORES, SMOKE
))
started <- Sys.time()
attempt_results <- parallel::mclapply(
  seq_len(nrow(tasks)),
  function(i) one_attempt(tasks[i, , drop = FALSE]),
  mc.cores = min(NCORES, nrow(tasks)),
  mc.preschedule = FALSE
)
attempts <- do.call(rbind, lapply(attempt_results, `[[`, "attempt"))
bootstrap_attempts <- do.call(
  rbind,
  Filter(nrow, lapply(attempt_results, `[[`, "bootstrap_attempts"))
)
if (is.null(bootstrap_attempts)) bootstrap_attempts <- data.frame()
utils::write.csv(attempts, raw_path, row.names = FALSE)
utils::write.csv(bootstrap_attempts, bootstrap_path, row.names = FALSE)

binomial_interval <- function(x, n) {
  if (!is.finite(x) || n < 1L) return(c(NA_real_, NA_real_))
  stats::binom.test(x, n)$conf.int
}
summarise_method <- function(dat, method) {
  status <- dat[[paste0(method, "_status")]]
  lower <- dat[[paste0(method, "_lower")]]
  upper <- dat[[paste0(method, "_upper")]]
  scored <- is.finite(lower) & is.finite(upper) & status == method
  hits <- dat[[paste0(method, "_covered")]][scored]
  all_hits <- dat[[paste0(method, "_covered")]]
  all_hits[is.na(all_hits)] <- FALSE
  n_scored <- sum(scored)
  n_hit <- sum(hits)
  n_hit_all <- sum(all_hits)
  ci <- binomial_interval(n_hit, n_scored)
  ci_all <- binomial_interval(n_hit_all, nrow(dat))
  finite_estimates <- is.finite(dat$rho12_estimate)
  data.frame(
    method = method,
    n_attempted = nrow(dat),
    n_fit_ok = sum(dat$fit_ok),
    n_converged = sum(dat$convergence == 0, na.rm = TRUE),
    n_pdHess = sum(dat$pdHess %in% TRUE, na.rm = TRUE),
    n_interval = n_scored,
    n_interval_failed = nrow(dat) - n_scored,
    coverage_conditional = if (n_scored > 0L) n_hit / n_scored else NA_real_,
    coverage_ci_low = ci[[1L]],
    coverage_ci_high = ci[[2L]],
    coverage_all_attempts = n_hit_all / nrow(dat),
    coverage_all_ci_low = ci_all[[1L]],
    coverage_all_ci_high = ci_all[[2L]],
    mean_width = if (n_scored > 0L) mean(upper[scored] - lower[scored]) else NA_real_,
    point_bias = if (any(finite_estimates)) {
      mean(dat$rho12_estimate[finite_estimates] - dat$rho12_truth[finite_estimates])
    } else NA_real_,
    point_rmse = if (any(finite_estimates)) {
      sqrt(mean((dat$rho12_estimate[finite_estimates] - dat$rho12_truth[finite_estimates])^2))
    } else NA_real_,
    stringsAsFactors = FALSE
  )
}
summary <- do.call(rbind, lapply(split(attempts, attempts$cell_id), function(dat) {
  method_summary <- do.call(rbind, lapply(c("wald", "profile", "bootstrap"), function(method) {
    summarise_method(dat, method)
  }))
  method_summary$cell_id <- dat$cell_id[[1L]]
  method_summary$n <- dat$n[[1L]]
  method_summary$rho12_truth <- dat$rho12_truth[[1L]]
  method_summary <- method_summary[, c(
    "cell_id", "n", "rho12_truth", setdiff(names(method_summary), c("cell_id", "n", "rho12_truth"))
  )]
  row.names(method_summary) <- NULL
  method_summary
}))
row.names(summary) <- NULL
utils::write.csv(summary, summary_path, row.names = FALSE)

manifest <- data.frame(
  key = c(
    "git_sha", "package_version", "host", "started", "elapsed_seconds",
    "openblas_threads", "ncores", "nsim_per_cell", "bootstrap_replicates",
    "seed_base", "cells", "smoke"
  ),
  value = c(
    tryCatch(system("git rev-parse HEAD", intern = TRUE), error = function(e) NA_character_),
    as.character(utils::packageVersion("drmTMB")), Sys.info()[["nodename"]],
    as.character(started), as.numeric(difftime(Sys.time(), started, units = "secs")),
    Sys.getenv("OPENBLAS_NUM_THREADS"), NCORES, NSIM, BOOTSTRAP_R,
    SEED_BASE, paste(conditions$cell_id, collapse = ";"), SMOKE
  ),
  stringsAsFactors = FALSE
)
utils::write.csv(manifest, manifest_path, row.names = FALSE)
if (!QUIET) {
  message("Wrote retained-attempts coverage outputs to ", OUTDIR)
  print(summary)
}
