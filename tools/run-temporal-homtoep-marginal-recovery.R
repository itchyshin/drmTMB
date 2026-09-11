#!/usr/bin/env Rscript

# Frozen point-recovery runner for the identified marginal homogeneous Toeplitz
# provider. It deliberately does not reuse the retired latent-process fixtures:
# sigma is the total within-series covariance SD here.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0L) stop("This runner takes no arguments.", call. = FALSE)
root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  stop("Run from the drmTMB repository root.", call. = FALSE)
}
pkgload::load_all(root, compile = TRUE, quiet = TRUE)

out_dir <- Sys.getenv(
  "DRMTMB_TEMPORAL_HOMTOEP_MARGINAL_RECOVERY_OUT",
  unset = file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-09-10-temporal-homtoep-marginal-recovery-v1"
  )
)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
needed <- c(
  "raw-attempts.csv", "recovery-estimates.csv", "criteria.csv",
  "provenance.csv", "recovery-results.rds", "session-info.txt", "RESULTS.md"
)
if (any(file.exists(file.path(out_dir, needed)))) {
  stop("Retained recovery evidence already exists; do not overwrite it.", call. = FALSE)
}

# Frozen before the retained run. A--C are primary; D is a small-panel stress
# cell reported in full but excluded from primary point-recovery thresholds.
conditions <- data.frame(
  cell = rep(c("A_ar1", "B_nonexponential", "C_negative_lag", "D_stress"), each = 3L),
  replicate = rep(seq_len(3L), times = 4L),
  n_id = rep(c(80L, 80L, 80L, 20L), each = 3L),
  occasion_count = rep(c(6L, 6L, 6L, 4L), each = 3L),
  seed = 2026091100L + seq_len(12L),
  stringsAsFactors = FALSE
)
truth <- c(`(Intercept)` = 0, between = 0.5, within = 0.5, sigma_total = 0.8)
truth_rho <- list(
  A_ar1 = c(1, 0.55^(1:5)),
  B_nonexponential = drmTMB:::temporal_homtoep_correlations(c(
    atanh(0.45), atanh(-0.30), atanh(0.20), atanh(0.10), atanh(-0.05)
  )),
  C_negative_lag = drmTMB:::temporal_homtoep_correlations(c(
    atanh(-0.45), atanh(0.15), atanh(-0.10), atanh(0.05), 0
  )),
  D_stress = drmTMB:::temporal_homtoep_correlations(c(
    atanh(0.80), atanh(-0.20), atanh(0.10)
  ))
)

simulate_fixture <- function(cell, n_id, occasion_count, seed) {
  set.seed(seed)
  occasion <- rep(seq.int(0L, occasion_count - 1L), n_id)
  id <- factor(rep(sprintf("id_%03d", seq_len(n_id)), each = occasion_count))
  between <- rep(rep(c(-0.5, 0.5), length.out = n_id), each = occasion_count)
  within <- unlist(lapply(seq_len(n_id), function(i) {
    sample(rep(c(-0.5, 0.5), length.out = occasion_count))
  }), use.names = FALSE)
  rho <- truth_rho[[cell]]
  root <- chol(stats::toeplitz(rho))
  error <- unlist(lapply(seq_len(n_id), function(i) {
    as.vector(truth[["sigma_total"]] * t(root) %*% stats::rnorm(occasion_count))
  }), use.names = FALSE)
  data.frame(
    y = truth[["(Intercept)"]] + truth[["between"]] * between +
      truth[["within"]] * within + error,
    id = id,
    occasion = occasion,
    between = between,
    within = within
  )
}

fit_one <- function(dat) {
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  result <- withCallingHandlers(
    tryCatch(
      list(fit = drmTMB::drmTMB(
        drmTMB::bf(
          y ~ between + within + temporal(1 | id, time = occasion, structure = "homtoep"),
          sigma ~ 1
        ),
        data = dat,
        family = stats::gaussian(),
        REML = FALSE
      )),
      error = function(e) list(fit = NULL, error = conditionMessage(e))
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  result$elapsed_sec <- proc.time()[["elapsed"]] - started
  result$warning <- paste(warnings, collapse = " | ")
  result
}

selected_rows <- list()
attempt_rows <- list()
for (i in seq_len(nrow(conditions))) {
  condition <- conditions[i, , drop = FALSE]
  fixture <- paste(condition$cell, sprintf("r%02d", condition$replicate), sep = "_")
  result <- fit_one(simulate_fixture(
    condition$cell, condition$n_id, condition$occasion_count, condition$seed
  ))
  if (is.null(result$fit)) {
    selected_rows[[i]] <- data.frame(
      fixture = fixture, cell = condition$cell, replicate = condition$replicate,
      selected = FALSE, error = result$error, warning = result$warning,
      elapsed_sec = result$elapsed_sec, objective = NA_real_,
      beta_intercept = NA_real_, beta_between = NA_real_, beta_within = NA_real_,
      sigma_total = NA_real_, lag_rmse = NA_real_
    )
    attempt_rows[[i]] <- data.frame(
      fixture = fixture, cell = condition$cell, replicate = condition$replicate,
      start = NA_integer_, status = "error", convergence = NA_integer_,
      objective = NA_real_, elapsed_sec = result$elapsed_sec, selected = FALSE,
      warning = result$warning, error = result$error
    )
  } else {
    fit <- result$fit
    estimated_rho <- c(1, unname(fit$corpars$temporal))
    selected_rows[[i]] <- data.frame(
      fixture = fixture, cell = condition$cell, replicate = condition$replicate,
      selected = is.finite(fit$opt$objective), error = NA_character_,
      warning = result$warning, elapsed_sec = result$elapsed_sec,
      objective = fit$opt$objective,
      beta_intercept = unname(fit$coefficients$mu[["(Intercept)"]]),
      beta_between = unname(fit$coefficients$mu[["between"]]),
      beta_within = unname(fit$coefficients$mu[["within"]]),
      sigma_total = stats::sigma(fit)[[1L]],
      lag_rmse = sqrt(mean((estimated_rho - truth_rho[[condition$cell]])^2))
    )
    attempts <- fit$temporal_start_attempts
    attempts$fixture <- fixture
    attempts$cell <- condition$cell
    attempts$replicate <- condition$replicate
    attempts$warning <- result$warning
    attempts$error <- NA_character_
    attempt_rows[[i]] <- attempts[, c(
      "fixture", "cell", "replicate", "start", "status", "convergence",
      "objective", "elapsed_sec", "selected", "warning", "error"
    )]
  }
}
selected <- do.call(rbind, selected_rows)
attempts <- do.call(rbind, attempt_rows)
primary <- selected$cell %in% c("A_ar1", "B_nonexponential", "C_negative_lag")
primary_selected <- selected[primary, , drop = FALSE]
coefficient_error <- c(
  abs(primary_selected$beta_intercept - truth[["(Intercept)"]]),
  abs(primary_selected$beta_between - truth[["between"]]),
  abs(primary_selected$beta_within - truth[["within"]])
)
criteria <- data.frame(
  criterion = c(
    "nine selected finite primary fits", "twelve retained start attempts",
    "primary mean absolute fixed-effect error <= 0.20",
    "primary median absolute total-SD error <= 0.25",
    "primary median lag RMSE <= 0.35"
  ),
  observed = c(
    sum(primary_selected$selected), nrow(attempts),
    mean(coefficient_error, na.rm = TRUE),
    median(abs(primary_selected$sigma_total - truth[["sigma_total"]]), na.rm = TRUE),
    median(primary_selected$lag_rmse, na.rm = TRUE)
  ),
  threshold = c("9", "12", "<= 0.20", "<= 0.25", "<= 0.35"),
  pass = c(
    sum(primary_selected$selected) == 9L,
    nrow(attempts) == 12L && all(table(attempts$fixture) == 1L),
    is.finite(mean(coefficient_error, na.rm = TRUE)) && mean(coefficient_error, na.rm = TRUE) <= 0.20,
    is.finite(median(abs(primary_selected$sigma_total - truth[["sigma_total"]]), na.rm = TRUE)) &&
      median(abs(primary_selected$sigma_total - truth[["sigma_total"]]), na.rm = TRUE) <= 0.25,
    is.finite(median(primary_selected$lag_rmse, na.rm = TRUE)) &&
      median(primary_selected$lag_rmse, na.rm = TRUE) <= 0.35
  ),
  stringsAsFactors = FALSE
)

write.csv(attempts, file.path(out_dir, "raw-attempts.csv"), row.names = FALSE)
write.csv(selected, file.path(out_dir, "recovery-estimates.csv"), row.names = FALSE)
write.csv(criteria, file.path(out_dir, "criteria.csv"), row.names = FALSE)
provenance <- data.frame(
  key = c("source_commit", "runner_md5", "run_utc", "n_fixtures", "n_attempts"),
  value = c(
    system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
    unname(tools::md5sum(file.path(root, "tools/run-temporal-homtoep-marginal-recovery.R"))),
    format(Sys.time(), tz = "UTC", usetz = TRUE), nrow(selected), nrow(attempts)
  )
)
write.csv(provenance, file.path(out_dir, "provenance.csv"), row.names = FALSE)
saveRDS(
  list(
    conditions = conditions, truth = truth, truth_rho = truth_rho,
    attempts = attempts, recovery = selected, criteria = criteria,
    provenance = provenance
  ),
  file.path(out_dir, "recovery-results.rds")
)
writeLines(c(
  "# Marginal homogeneous Toeplitz local recovery",
  "",
  "Twelve frozen point-recovery fixtures: three AR1-shaped, three non-exponential, three negative-lag primary fits, and three retained small-panel stress fits.",
  "The stress cell is reported but excluded from primary criteria. This is neither interval nor coverage evidence."
), file.path(out_dir, "RESULTS.md"))
capture.output(sessionInfo(), file = file.path(out_dir, "session-info.txt"))
if (!all(criteria$pass)) {
  stop("Marginal Toeplitz recovery criteria failed; retained outputs were written for diagnosis.", call. = FALSE)
}
cat("TEMPORAL_HOMTOEP_MARGINAL_RECOVERY_PASS\n")
