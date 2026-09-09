#!/usr/bin/env Rscript

# Retained local recovery fixture for the first Gaussian temporal AR1 route.
# This is deliberately a one-dataset-per-condition diagnostic, not the
# 1,000-replicate-per-cell interval-calibration campaign.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0L) {
  stop("This runner takes no arguments.", call. = FALSE)
}

root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  stop("Run this script from the drmTMB repository root.", call. = FALSE)
}
pkgload::load_all(root, quiet = TRUE)

out_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-09-08-temporal-ar1-local-recovery"
)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
evidence_files <- file.path(out_dir, c(
  "raw-attempts.csv", "recovery-estimates.csv", "criteria.csv",
  "provenance.csv", "recovery-results.rds"
))
if (any(file.exists(evidence_files))) {
  stop("Retained recovery evidence already exists; do not overwrite it.", call. = FALSE)
}

conditions <- data.frame(
  condition = sprintf("P%02d", seq_len(6L)),
  phi = c(-0.60, -0.30, 0.20, 0.45, 0.70, 0.85),
  seed = 2026090801L + seq_len(6L),
  stringsAsFactors = FALSE
)

truth <- c(`(Intercept)` = 0, between = 0.5, within = 0.5)
time <- c(0L, 1L, 3L, 4L, 6L, 7L)

simulate_fixture <- function(phi, seed, ordinary_intercept) {
  set.seed(seed)
  n_id <- 80L
  n_time <- length(time)
  id_levels <- sprintf("id_%03d", seq_len(n_id))
  id <- factor(rep(id_levels, each = n_time), levels = id_levels)
  occasion <- rep(time, n_id)
  between_id <- rep(rep(c(-0.5, 0.5), each = n_id / 2L), each = n_time)
  within <- unlist(lapply(seq_len(n_id), function(i) {
    sample(rep(c(-0.5, 0.5), length.out = n_time))
  }), use.names = FALSE)
  R <- phi ^ abs(outer(time, time, "-"))
  temporal <- unlist(lapply(seq_len(n_id), function(i) {
    as.vector(t(chol(R)) %*% rnorm(n_time, sd = 0.8))
  }), use.names = FALSE)
  stable <- if (ordinary_intercept) {
    rep(rnorm(n_id, sd = 0.6), each = n_time)
  } else {
    numeric(n_id * n_time)
  }
  data.frame(
    y = truth[["(Intercept)"]] + truth[["between"]] * between_id +
      truth[["within"]] * within + stable + temporal +
      rnorm(n_id * n_time, sd = 0.4),
    id = id,
    occasion = occasion,
    between = between_id,
    within = within
  )
}

fit_fixture <- function(dat, ordinary_intercept) {
  if (ordinary_intercept) {
    drmTMB(
      bf(
        y ~ between + within + (1 | id) +
          temporal(1 | id, time = occasion, structure = "ar1"),
        sigma ~ 1
      ),
      data = dat, family = gaussian(), REML = FALSE
    )
  } else {
    drmTMB(
      bf(
        y ~ between + within +
          temporal(1 | id, time = occasion, structure = "ar1"),
        sigma ~ 1
      ),
      data = dat, family = gaussian(), REML = FALSE
    )
  }
}

safe_fit <- function(dat, ordinary_intercept) {
  started <- proc.time()[["elapsed"]]
  result <- tryCatch(
    list(fit = fit_fixture(dat, ordinary_intercept), error = NA_character_),
    error = function(e) list(fit = NULL, error = conditionMessage(e))
  )
  result$elapsed_sec <- proc.time()[["elapsed"]] - started
  result
}

extract_selected <- function(result, model, condition) {
  if (is.null(result$fit)) {
    return(data.frame(
      fixture = paste(model, condition, sep = "_"), model = model,
      condition = condition, selected = FALSE, error = result$error,
      elapsed_sec = result$elapsed_sec, objective = NA_real_,
      beta_intercept = NA_real_, beta_between = NA_real_, beta_within = NA_real_,
      sd_ordinary = NA_real_, sd_temporal = NA_real_, phi = NA_real_,
      sigma = NA_real_, stringsAsFactors = FALSE
    ))
  }
  fit <- result$fit
  temporal_label <- temporal_mu_sd_label(fit$model$structured$temporal_mu)
  data.frame(
    fixture = paste(model, condition, sep = "_"), model = model,
    condition = condition, selected = TRUE, error = NA_character_,
    elapsed_sec = result$elapsed_sec, objective = -as.numeric(stats::logLik(fit)),
    beta_intercept = unname(fit$coefficients$mu[["(Intercept)"]]),
    beta_between = unname(fit$coefficients$mu[["between"]]),
    beta_within = unname(fit$coefficients$mu[["within"]]),
    sd_ordinary = if (ordinary_intercept) unname(fit$sdpars$mu[["(1 | id)"]]) else NA_real_,
    sd_temporal = unname(fit$sdpars$mu[[temporal_label]]),
    phi = unname(fit$corpars$temporal[[1L]]),
    sigma = exp(unname(fit$coefficients$sigma[["(Intercept)"]])),
    stringsAsFactors = FALSE
  )
}

extract_attempts <- function(result, model, condition) {
  fixture <- paste(model, condition, sep = "_")
  if (is.null(result$fit)) {
    return(data.frame(
      fixture = fixture, model = model, condition = condition,
      start = NA_character_, persistence_start = NA_real_, status = "error",
      convergence = NA_integer_, objective = NA_real_, elapsed_sec = result$elapsed_sec,
      selected = FALSE, error = result$error, stringsAsFactors = FALSE
    ))
  }
  attempts <- result$fit$temporal_start_attempts
  attempts$fixture <- fixture
  attempts$model <- model
  attempts$condition <- condition
  attempts$error <- NA_character_
  attempts[, c(
    "fixture", "model", "condition", "start", "persistence_start", "status",
    "convergence", "objective", "elapsed_sec", "selected", "error"
  )]
}

selected_rows <- list()
attempt_rows <- list()
index <- 1L
for (ordinary_intercept in c(FALSE, TRUE)) {
  model <- if (ordinary_intercept) "ordinary_plus_ar1" else "ar1_only"
  for (j in seq_len(nrow(conditions))) {
    condition <- conditions[j, , drop = FALSE]
    dat <- simulate_fixture(
      phi = condition$phi,
      seed = condition$seed + if (ordinary_intercept) 100L else 0L,
      ordinary_intercept = ordinary_intercept
    )
    result <- safe_fit(dat, ordinary_intercept)
    selected_rows[[index]] <- extract_selected(result, model, condition$condition)
    attempt_rows[[index]] <- extract_attempts(result, model, condition$condition)
    index <- index + 1L
  }
}

selected <- do.call(rbind, selected_rows)
attempts <- do.call(rbind, attempt_rows)
truth_rows <- do.call(rbind, lapply(c("ar1_only", "ordinary_plus_ar1"), function(model) {
  data.frame(
    fixture = paste(model, conditions$condition, sep = "_"),
    model = model, condition = conditions$condition, phi = conditions$phi,
    beta_intercept = truth[["(Intercept)"]], beta_between = truth[["between"]],
    beta_within = truth[["within"]], sd_ordinary = if (model == "ordinary_plus_ar1") 0.6 else NA_real_,
    sd_temporal = 0.8, sigma = 0.4, stringsAsFactors = FALSE
  )
}))
recovery <- merge(selected, truth_rows, by = c("fixture", "model", "condition"), suffixes = c("_estimate", "_truth"), all.x = TRUE)

selected_ok <- recovery$selected & is.finite(recovery$objective)
mean_abs_beta_error <- mean(abs(unlist(lapply(c("intercept", "between", "within"), function(name) {
  recovery[[paste0("beta_", name, "_estimate")]] - recovery[[paste0("beta_", name, "_truth")]]
}))), na.rm = TRUE)
sd_error <- c(
  abs(recovery$sd_temporal_estimate - recovery$sd_temporal_truth),
  abs(recovery$sigma_estimate - recovery$sigma_truth),
  abs(recovery$sd_ordinary_estimate - recovery$sd_ordinary_truth)
)
median_abs_sd_error <- stats::median(sd_error, na.rm = TRUE)
median_abs_phi_error <- stats::median(abs(recovery$phi_estimate - recovery$phi_truth), na.rm = TRUE)

# These are recovery-fixture diagnostics, fixed before this run.  They require
# every selected fit, all 24 starts, and broadly recover the generating values;
# they do not make a coverage claim.
criteria <- data.frame(
  criterion = c(
    "twelve selected finite fits",
    "twenty-four retained signed-start attempts",
    "mean absolute fixed-effect error <= 0.20",
    "median absolute SD error <= 0.35",
    "median absolute persistence error <= 0.30"
  ),
  observed = c(
    sum(selected_ok), nrow(attempts), mean_abs_beta_error,
    median_abs_sd_error, median_abs_phi_error
  ),
  threshold = c("12", "24", "<= 0.20", "<= 0.35", "<= 0.30"),
  pass = c(
    sum(selected_ok) == 12L,
    nrow(attempts) == 24L && all(table(attempts$fixture) == 2L),
    is.finite(mean_abs_beta_error) && mean_abs_beta_error <= 0.20,
    is.finite(median_abs_sd_error) && median_abs_sd_error <= 0.35,
    is.finite(median_abs_phi_error) && median_abs_phi_error <= 0.30
  ),
  stringsAsFactors = FALSE
)

write.csv(attempts, file.path(out_dir, "raw-attempts.csv"), row.names = FALSE)
write.csv(recovery, file.path(out_dir, "recovery-estimates.csv"), row.names = FALSE)
write.csv(criteria, file.path(out_dir, "criteria.csv"), row.names = FALSE)
provenance <- data.frame(
  key = c("source_commit", "runner_md5", "run_utc", "n_fixtures", "n_attempts"),
  value = c(
    system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
    unname(tools::md5sum(file.path(root, "tools/run-temporal-ar1-recovery.R"))),
    format(Sys.time(), tz = "UTC", usetz = TRUE),
    nrow(recovery), nrow(attempts)
  ),
  stringsAsFactors = FALSE
)
write.csv(provenance, file.path(out_dir, "provenance.csv"), row.names = FALSE)
saveRDS(list(conditions = conditions, truth = truth_rows, attempts = attempts,
             recovery = recovery, criteria = criteria, provenance = provenance),
        file.path(out_dir, "recovery-results.rds"))

if (!all(criteria$pass)) {
  stop("Temporal AR1 recovery criteria failed; retained outputs were written for diagnosis.", call. = FALSE)
}
cat("TEMPORAL_AR1_RECOVERY_PASS\n")
