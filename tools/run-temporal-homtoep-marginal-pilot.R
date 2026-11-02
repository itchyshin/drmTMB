#!/usr/bin/env Rscript
# Frozen, bounded timing pilot for the identified marginal homogeneous Toeplitz model.
args <- commandArgs(trailingOnly = TRUE)
if (length(args)) stop("This runner takes no arguments.", call. = FALSE)
root <- normalizePath('.', mustWork = TRUE)
if (!file.exists(file.path(root, 'DESCRIPTION'))) stop('Run from the drmTMB repository root.', call. = FALSE)
pkgload::load_all(root, compile = TRUE, quiet = TRUE)
out_dir <- Sys.getenv('DRMTMB_TEMPORAL_HOMTOEP_MARGINAL_PILOT_OUT', unset = file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-10-temporal-homtoep-marginal-pilot-v1'))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
needed <- c('raw-attempts.csv', 'pilot-results.csv', 'pilot-summary.csv', 'provenance.csv', 'pilot-results.rds', 'session-info.txt', 'RESULTS.md')
if (any(file.exists(file.path(out_dir, needed)))) stop('Retained pilot evidence already exists; do not overwrite it.', call. = FALSE)

conditions <- data.frame(cell = rep(c('P1_ar1', 'P2_nonexponential', 'P3_negative_lag'), each = 5L), replicate = rep(1:5, 3L), n_id = 80L, n_time = 6L, seed = 2026091200L + seq_len(15L), stringsAsFactors = FALSE)
rho_by_cell <- list(P1_ar1 = c(1, 0.55^(1:5)), P2_nonexponential = drmTMB:::temporal_homtoep_correlations(c(atanh(.45), atanh(-.30), atanh(.20), atanh(.10), atanh(-.05))), P3_negative_lag = drmTMB:::temporal_homtoep_correlations(c(atanh(-.45), atanh(.15), atanh(-.10), atanh(.05), 0)))
simulate_panel <- function(cell, n_id, n_time, seed) {
  set.seed(seed)
  id <- factor(rep(sprintf('id_%03d', seq_len(n_id)), each = n_time))
  occasion <- rep(0:(n_time - 1L), n_id)
  x_between <- rep(rep(c(-.5, .5), length.out = n_id), each = n_time)
  x_within <- unlist(lapply(seq_len(n_id), function(i) sample(rep(c(-.5, .5), length.out = n_time))), use.names = FALSE)
  root <- chol(toeplitz(rho_by_cell[[cell]]))
  error <- unlist(lapply(seq_len(n_id), function(i) as.vector(.8 * t(root) %*% rnorm(n_time))), use.names = FALSE)
  data.frame(y = .5 * x_between + .5 * x_within + error, id = id, occasion = occasion, x_between = x_between, x_within = x_within)
}
fit_panel <- function(dat) {
  warns <- character(); started <- proc.time()[['elapsed']]
  fit <- withCallingHandlers(tryCatch(drmTMB::drmTMB(drmTMB::bf(y ~ x_between + x_within + temporal(1 | id, time = occasion, structure = 'homtoep'), sigma ~ 1), data = dat, family = stats::gaussian(), REML = FALSE), error = identity), warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart('muffleWarning') })
  elapsed <- proc.time()[['elapsed']] - started
  rss <- suppressWarnings(as.numeric(system2('ps', c('-o', 'rss=', '-p', Sys.getpid()), stdout = TRUE)))
  list(fit = fit, elapsed_sec = elapsed, warning = paste(warns, collapse = ' | '), rss_kb = rss)
}
rows <- list(); attempts <- list()
for (i in seq_len(nrow(conditions))) {
  cnd <- conditions[i, ]; fixture <- paste(cnd$cell, sprintf('r%02d', cnd$replicate), sep = '_')
  ans <- fit_panel(simulate_panel(cnd$cell, cnd$n_id, cnd$n_time, cnd$seed))
  if (inherits(ans$fit, 'error')) {
    rows[[i]] <- data.frame(fixture = fixture, cell = cnd$cell, replicate = cnd$replicate, selected = FALSE, finite_objective = FALSE, pd_hessian = FALSE, objective = NA_real_, elapsed_sec = ans$elapsed_sec, rss_kb = ans$rss_kb, warning = ans$warning, error = conditionMessage(ans$fit))
    attempts[[i]] <- data.frame(fixture = fixture, cell = cnd$cell, replicate = cnd$replicate, start = NA_integer_, status = 'error', convergence = NA_integer_, objective = NA_real_, elapsed_sec = ans$elapsed_sec, selected = FALSE, warning = ans$warning, error = conditionMessage(ans$fit))
  } else {
    fit <- ans$fit
    rows[[i]] <- data.frame(fixture = fixture, cell = cnd$cell, replicate = cnd$replicate, selected = is.finite(fit$opt$objective), finite_objective = is.finite(fit$opt$objective), pd_hessian = isTRUE(fit$sdr$pdHess), objective = fit$opt$objective, elapsed_sec = ans$elapsed_sec, rss_kb = ans$rss_kb, warning = ans$warning, error = NA_character_)
    a <- fit$temporal_start_attempts; a$fixture <- fixture; a$cell <- cnd$cell; a$replicate <- cnd$replicate; a$warning <- ans$warning; a$error <- NA_character_; attempts[[i]] <- a[, c('fixture', 'cell', 'replicate', 'start', 'status', 'convergence', 'objective', 'elapsed_sec', 'selected', 'warning', 'error')]
  }
}
results <- do.call(rbind, rows); attempts <- do.call(rbind, attempts)
summary <- aggregate(cbind(elapsed_sec, rss_kb) ~ cell, results, function(x) c(median = median(x, na.rm = TRUE), maximum = max(x, na.rm = TRUE)))
criteria <- c(nrow(results) == 15L, nrow(attempts) == 15L, all(results$selected & results$finite_objective), all(table(attempts$fixture) == 1L), all(is.finite(results$rss_kb) & results$rss_kb > 0))
write.csv(attempts, file.path(out_dir, 'raw-attempts.csv'), row.names = FALSE); write.csv(results, file.path(out_dir, 'pilot-results.csv'), row.names = FALSE); write.csv(summary, file.path(out_dir, 'pilot-summary.csv'), row.names = FALSE)
provenance <- data.frame(key = c('source_commit', 'runner_md5', 'run_utc', 'n_fixtures', 'n_attempts'), value = c(system2('git', c('rev-parse', 'HEAD'), stdout = TRUE), unname(tools::md5sum(file.path(root, 'tools/run-temporal-homtoep-marginal-pilot.R'))), format(Sys.time(), tz = 'UTC', usetz = TRUE), nrow(results), nrow(attempts)))
write.csv(provenance, file.path(out_dir, 'provenance.csv'), row.names = FALSE); saveRDS(list(conditions = conditions, results = results, attempts = attempts, summary = summary, provenance = provenance), file.path(out_dir, 'pilot-results.rds')); writeLines(c('# Marginal homogeneous Toeplitz timing pilot', '', 'Fifteen frozen fits: five independent seeds for each of three primary covariance shapes. `rss_kb` is the post-fit resident memory observed from the runner process, not a peak-memory claim. This is not interval or coverage evidence.'), file.path(out_dir, 'RESULTS.md')); capture.output(sessionInfo(), file = file.path(out_dir, 'session-info.txt'))
if (!all(criteria)) stop('Marginal Toeplitz pilot completeness criteria failed; retained outputs were written for diagnosis.', call. = FALSE)
cat('TEMPORAL_HOMTOEP_MARGINAL_PILOT_PASS\n')
