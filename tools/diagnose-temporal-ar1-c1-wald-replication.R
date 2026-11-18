#!/usr/bin/env Rscript

# Five fresh, fixed-seed C1 replications for the AR1 Wald-availability issue.
# This is a bounded diagnostic, not the declared 1,000-replicate campaign.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0L) stop("This diagnostic takes no arguments.", call. = FALSE)
root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) stop("Run from the drmTMB root.", call. = FALSE)
pkgload::load_all(root, quiet = TRUE)

out_dir <- Sys.getenv(
  "DRMTMB_TEMPORAL_AR1_C1_REPLICATION_OUT",
  unset = file.path(root, "docs/dev-log/simulation-artifacts/2026-09-09-temporal-ar1-c1-wald-replication")
)
required <- file.path(out_dir, c("replications.csv", "raw-attempts.csv", "summary.csv", "provenance.csv", "results.rds", "session-info.txt", "RESULTS.md"))
if (any(file.exists(required))) stop("C1 replication evidence already exists; do not overwrite it.", call. = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

truth <- c(`(Intercept)` = 0, between = 0.5, within = 0.5)
seeds <- 2026091101L + 0:4

simulate_c1 <- function(seed) {
  set.seed(seed)
  n_id <- 80L; n_time <- 6L; phi <- 0.4
  time <- seq.int(0L, length.out = n_time)
  id_levels <- sprintf("id_%03d", seq_len(n_id))
  id <- factor(rep(id_levels, each = n_time), levels = id_levels)
  occasion <- rep(time, n_id)
  between <- rep(rep(c(-0.5, 0.5), length.out = n_id), each = n_time)
  within <- unlist(lapply(seq_len(n_id), function(i) sample(rep(c(-0.5, 0.5), length.out = n_time))), use.names = FALSE)
  R <- phi ^ abs(outer(time, time, "-"))
  temporal <- unlist(lapply(seq_len(n_id), function(i) as.vector(t(chol(R)) %*% rnorm(n_time, sd = 0.8))), use.names = FALSE)
  stable <- rep(rnorm(n_id, sd = 0.6), each = n_time)
  data.frame(
    y = truth[["between"]] * between + truth[["within"]] * within + stable + temporal + rnorm(n_id * n_time, sd = 0.4),
    id = id, occasion = occasion, between = between, within = within
  )
}

fit_c1 <- function(dat) {
  drmTMB(
    bf(y ~ between + within + (1 | id) + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  )
}

capture <- function(expr) {
  warnings <- character()
  result <- tryCatch(
    withCallingHandlers(expr, warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }),
    error = function(e) e
  )
  list(value = result, warnings = warnings)
}

rows <- vector("list", length(seeds))
attempt_rows <- vector("list", length(seeds))
for (i in seq_along(seeds)) {
  seed <- seeds[[i]]
  started <- proc.time()[["elapsed"]]
  fitted <- capture(fit_c1(simulate_c1(seed)))
  elapsed <- proc.time()[["elapsed"]] - started
  if (inherits(fitted$value, "error")) {
    rows[[i]] <- data.frame(seed, selected = FALSE, objective = NA_real_, elapsed_sec = elapsed,
      pd_hessian = NA, vcov_available = FALSE, interval_available = FALSE,
      warning = paste(fitted$warnings, collapse = " | "), error = conditionMessage(fitted$value), stringsAsFactors = FALSE)
    attempt_rows[[i]] <- data.frame(seed, start = NA_character_, persistence_start = NA_real_, status = "error",
      convergence = NA_integer_, objective = NA_real_, selected = FALSE, stringsAsFactors = FALSE)
    next
  }
  fit <- fitted$value
  covar <- capture(stats::vcov(fit))
  interval <- capture(stats::confint(fit, method = "wald"))
  vcov_available <- !inherits(covar$value, "error") && is.matrix(covar$value) && all(is.finite(covar$value))
  interval_available <- !inherits(interval$value, "error") && nrow(interval$value) == 3L &&
    all(is.finite(interval$value$lower)) && all(is.finite(interval$value$upper))
  rows[[i]] <- data.frame(
    seed, selected = TRUE, objective = -as.numeric(stats::logLik(fit)), elapsed_sec = elapsed,
    pd_hessian = isTRUE(fit$sdr$pdHess), vcov_available, interval_available,
    sigma = exp(unname(fit$coefficients$sigma[["(Intercept)"]])),
    warning = paste(c(fitted$warnings, covar$warnings, interval$warnings), collapse = " | "),
    error = paste(c(if (inherits(covar$value, "error")) conditionMessage(covar$value), if (inherits(interval$value, "error")) conditionMessage(interval$value)), collapse = " | "),
    stringsAsFactors = FALSE
  )
  attempts <- fit$temporal_start_attempts
  attempts$seed <- seed
  attempt_rows[[i]] <- attempts[, c("seed", "start", "persistence_start", "status", "convergence", "objective", "selected")]
}

replications <- do.call(rbind, rows)
attempts <- do.call(rbind, attempt_rows)
summary <- data.frame(
  n_datasets = nrow(replications), selected_finite = sum(replications$selected & is.finite(replications$objective)),
  pd_hessian = sum(replications$pd_hessian %in% TRUE), vcov_available = sum(replications$vcov_available),
  interval_available = sum(replications$interval_available), interval_availability = mean(replications$interval_available),
  median_elapsed_sec = median(replications$elapsed_sec), max_elapsed_sec = max(replications$elapsed_sec),
  stringsAsFactors = FALSE
)
provenance <- data.frame(
  key = c("source_commit", "runner_md5", "seeds", "run_utc", "n_datasets", "n_attempts"),
  value = c(system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
    unname(tools::md5sum(file.path(root, "tools/diagnose-temporal-ar1-c1-wald-replication.R"))),
    paste(seeds, collapse = ","), format(Sys.time(), tz = "UTC", usetz = TRUE), nrow(replications), nrow(attempts)),
  stringsAsFactors = FALSE
)
write.csv(replications, file.path(out_dir, "replications.csv"), row.names = FALSE)
write.csv(attempts, file.path(out_dir, "raw-attempts.csv"), row.names = FALSE)
write.csv(summary, file.path(out_dir, "summary.csv"), row.names = FALSE)
write.csv(provenance, file.path(out_dir, "provenance.csv"), row.names = FALSE)
saveRDS(list(replications = replications, attempts = attempts, summary = summary, provenance = provenance), file.path(out_dir, "results.rds"))
capture.output(sessionInfo(), file = file.path(out_dir, "session-info.txt"))
writeLines(c(
  "# C1 AR1 Wald-availability replication", "",
  "This bounded, five-new-seed replication extends the retained five-seed timing pilot. It does not replace that pilot, change the predeclared 1,000-dataset campaign, or make a coverage claim. It records whether the current free-sigma Wald route is numerically available on each fresh C1 dataset.", "",
  "Every fit retains both signed persistence starts. Unavailable covariance or intervals are recorded as unavailable, not silently replaced by a conditional or constrained calculation."
), file.path(out_dir, "RESULTS.md"))

if (nrow(replications) != length(seeds) || nrow(attempts) != 2L * length(seeds) ||
    any(table(attempts$seed) != 2L) || any(!is.finite(replications$elapsed_sec) | replications$elapsed_sec <= 0)) {
  stop("C1 replication completeness checks failed; retained outputs were written for diagnosis.", call. = FALSE)
}
cat("TEMPORAL_AR1_C1_WALD_REPLICATION_PASS\n")
