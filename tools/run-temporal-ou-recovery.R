#!/usr/bin/env Rscript

# Retained local recovery fixture for the Gaussian temporal OU route. This is
# point-recovery evidence only, not the later interval-calibration campaign.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0L) {
  stop("This runner takes no arguments.", call. = FALSE)
}

root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  stop("Run this script from the drmTMB repository root.", call. = FALSE)
}
pkgload::load_all(root, quiet = TRUE)

out_dir <- Sys.getenv(
  "DRMTMB_TEMPORAL_OU_RECOVERY_OUT",
  unset = file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-09-09-temporal-ou-local-recovery"
  )
)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
evidence_files <- file.path(out_dir, c(
  "raw-attempts.csv", "recovery-estimates.csv", "criteria.csv",
  "provenance.csv", "recovery-results.rds", "session-info.txt", "RESULTS.md"
))
if (any(file.exists(evidence_files))) {
  stop("Retained recovery evidence already exists; do not overwrite it.", call. = FALSE)
}

conditions <- data.frame(
  condition = sprintf("O%02d", seq_len(6L)),
  decay = c(0.15, 0.25, 0.40, 0.60, 0.85, 1.10),
  seed = 2026090900L + seq_len(6L),
  stringsAsFactors = FALSE
)
truth <- c(`(Intercept)` = 0, between = 0.5, within = 0.5)
elapsed_values <- c(0, 0.5, 1.5, 3, 5, 8)

simulate_fixture <- function(decay, seed, ordinary_intercept) {
  set.seed(seed)
  n_id <- 80L
  n_time <- length(elapsed_values)
  id_levels <- sprintf("site_%03d", seq_len(n_id))
  id <- factor(rep(id_levels, each = n_time), levels = id_levels)
  elapsed <- rep(elapsed_values, n_id)
  between_id <- rep(rep(c(-0.5, 0.5), each = n_id / 2L), each = n_time)
  within <- unlist(lapply(seq_len(n_id), function(i) {
    sample(rep(c(-0.5, 0.5), length.out = n_time))
  }), use.names = FALSE)
  R <- exp(-decay * abs(outer(elapsed_values, elapsed_values, "-")))
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
    id = id, elapsed = elapsed, between = between_id, within = within
  )
}

fit_fixture <- function(dat, ordinary_intercept) {
  if (ordinary_intercept) {
    drmTMB(
      bf(
        y ~ between + within + (1 | id) +
          temporal(1 | id, time = elapsed, structure = "ou"),
        sigma ~ 1
      ),
      data = dat, family = gaussian(), REML = FALSE
    )
  } else {
    drmTMB(
      bf(
        y ~ between + within +
          temporal(1 | id, time = elapsed, structure = "ou"),
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

extract_selected <- function(result, model, condition, ordinary_intercept) {
  fixture <- paste(model, condition, sep = "_")
  if (is.null(result$fit)) {
    return(data.frame(
      fixture = fixture, model = model, condition = condition, selected = FALSE,
      error = result$error, elapsed_sec = result$elapsed_sec, objective = NA_real_,
      beta_intercept = NA_real_, beta_between = NA_real_, beta_within = NA_real_,
      sd_ordinary = NA_real_, sd_temporal = NA_real_, decay = NA_real_,
      sigma = NA_real_, stringsAsFactors = FALSE
    ))
  }
  fit <- result$fit
  temporal_label <- temporal_mu_sd_label(fit$model$structured$temporal_mu)
  data.frame(
    fixture = fixture, model = model, condition = condition, selected = TRUE,
    error = NA_character_, elapsed_sec = result$elapsed_sec,
    objective = -as.numeric(stats::logLik(fit)),
    beta_intercept = unname(fit$coefficients$mu[["(Intercept)"]]),
    beta_between = unname(fit$coefficients$mu[["between"]]),
    beta_within = unname(fit$coefficients$mu[["within"]]),
    sd_ordinary = if (ordinary_intercept) unname(fit$sdpars$mu[["(1 | id)"]]) else NA_real_,
    sd_temporal = unname(fit$sdpars$mu[[temporal_label]]),
    decay = unname(fit$decaypars$temporal[[1L]]),
    sigma = exp(unname(fit$coefficients$sigma[["(Intercept)"]])),
    stringsAsFactors = FALSE
  )
}

extract_attempts <- function(result, model, condition) {
  fixture <- paste(model, condition, sep = "_")
  if (is.null(result$fit)) {
    return(data.frame(
      fixture = fixture, model = model, condition = condition, start = NA_character_,
      decay_start = NA_real_, status = "error", convergence = NA_integer_,
      objective = NA_real_, elapsed_sec = result$elapsed_sec, selected = FALSE,
      error = result$error, stringsAsFactors = FALSE
    ))
  }
  attempts <- result$fit$temporal_start_attempts
  attempts$fixture <- fixture
  attempts$model <- model
  attempts$condition <- condition
  attempts$error <- NA_character_
  attempts[, c(
    "fixture", "model", "condition", "start", "decay_start", "status",
    "convergence", "objective", "elapsed_sec", "selected", "error"
  )]
}

selected_rows <- list()
attempt_rows <- list()
index <- 1L
for (ordinary_intercept in c(FALSE, TRUE)) {
  model <- if (ordinary_intercept) "ordinary_plus_ou" else "ou_only"
  for (j in seq_len(nrow(conditions))) {
    condition <- conditions[j, , drop = FALSE]
    result <- safe_fit(
      simulate_fixture(
        decay = condition$decay,
        seed = condition$seed + if (ordinary_intercept) 100L else 0L,
        ordinary_intercept = ordinary_intercept
      ),
      ordinary_intercept = ordinary_intercept
    )
    selected_rows[[index]] <- extract_selected(
      result, model, condition$condition, ordinary_intercept
    )
    attempt_rows[[index]] <- extract_attempts(result, model, condition$condition)
    index <- index + 1L
  }
}

selected <- do.call(rbind, selected_rows)
attempts <- do.call(rbind, attempt_rows)
truth_rows <- do.call(rbind, lapply(c("ou_only", "ordinary_plus_ou"), function(model) {
  data.frame(
    fixture = paste(model, conditions$condition, sep = "_"),
    model = model, condition = conditions$condition, decay = conditions$decay,
    beta_intercept = truth[["(Intercept)"]], beta_between = truth[["between"]],
    beta_within = truth[["within"]],
    sd_ordinary = if (model == "ordinary_plus_ou") 0.6 else NA_real_,
    sd_temporal = 0.8, sigma = 0.4, stringsAsFactors = FALSE
  )
}))
recovery <- merge(selected, truth_rows, by = c("fixture", "model", "condition"),
                  suffixes = c("_estimate", "_truth"), all.x = TRUE)

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
median_abs_decay_error <- stats::median(abs(recovery$decay_estimate - recovery$decay_truth), na.rm = TRUE)

# Fixed before the first run. These criteria support only broad point recovery.
criteria <- data.frame(
  criterion = c(
    "twelve selected finite fits",
    "twenty-four retained positive-decay-start attempts",
    "mean absolute fixed-effect error <= 0.20",
    "median absolute SD error <= 0.35",
    "median absolute decay error <= 0.40"
  ),
  observed = c(
    sum(selected_ok), nrow(attempts), mean_abs_beta_error,
    median_abs_sd_error, median_abs_decay_error
  ),
  threshold = c("12", "24", "<= 0.20", "<= 0.35", "<= 0.40"),
  pass = c(
    sum(selected_ok) == 12L,
    nrow(attempts) == 24L && all(table(attempts$fixture) == 2L) &&
      all(is.finite(attempts$decay_start) & attempts$decay_start > 0),
    is.finite(mean_abs_beta_error) && mean_abs_beta_error <= 0.20,
    is.finite(median_abs_sd_error) && median_abs_sd_error <= 0.35,
    is.finite(median_abs_decay_error) && median_abs_decay_error <= 0.40
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
    unname(tools::md5sum(file.path(root, "tools/run-temporal-ou-recovery.R"))),
    format(Sys.time(), tz = "UTC", usetz = TRUE), nrow(recovery), nrow(attempts)
  ),
  stringsAsFactors = FALSE
)
write.csv(provenance, file.path(out_dir, "provenance.csv"), row.names = FALSE)
saveRDS(list(conditions = conditions, truth = truth_rows, attempts = attempts,
             recovery = recovery, criteria = criteria, provenance = provenance),
        file.path(out_dir, "recovery-results.rds"))
writeLines(sub("[[:space:]]+$", "", capture.output(sessionInfo())),
           file.path(out_dir, "session-info.txt"))
writeLines(c(
  "# Temporal OU local recovery results", "",
  "This bounded fixture has six predeclared decay conditions and both admitted Gaussian OU forms. It retains two optimizer starts per fit and evaluates point recovery only. It does not establish Wald interval calibration, profile-interval validity, or coverage."
), file.path(out_dir, "RESULTS.md"))

if (!all(criteria$pass)) {
  stop("Temporal OU recovery criteria failed; retained outputs were written for diagnosis.", call. = FALSE)
}
cat("TEMPORAL_OU_RECOVERY_PASS\n")
