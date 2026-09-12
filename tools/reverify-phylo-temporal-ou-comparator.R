#!/usr/bin/env Rscript
# No-fit closure for immutable paired comparator task archives.
args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep('^--file=', commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop('Run with Rscript.', call. = FALSE)
root <- normalizePath(file.path(dirname(sub('^--file=', '', script_arg)), '..'), mustWork = TRUE)
source(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))
value <- function(prefix) { x <- grep(paste0('^', prefix), args, value = TRUE); if (length(x) != 1L) return(NULL); sub(prefix, '', x) }
manifest <- function() {
  x <- phylo_temporal_ou_g11_manifest()
  x[x$task_id <= 3000L, , drop = FALSE]
}
validate_result <- function(x, expected, task) {
  need <- c('task_id', 'id', 'cell', 'replicate', 'seed', 'engine', 'selected', 'pd_hess', 'estimate', 'lower', 'upper', 'elapsed_sec', 'error', 'profile_available')
  if (!all(need %in% names(x)) || nrow(x) != 2L || !identical(as.integer(x$task_id), rep(task, 2L)) || !identical(x$id, rep(sprintf('CMP_%04d', task), 2L)) || !identical(as.character(x$cell), rep(expected$cell, 2L)) || !identical(as.character(x$engine), c('drmTMB', 'glmmTMB'))) stop('Comparator result has an invalid task, cell, or engine structure.', call. = FALSE)
  x
}
if (identical(args, '--self-test')) {
  m <- manifest(); stopifnot(nrow(m) == 3000L, identical(sort(unique(m$cell)), c('P1', 'P2', 'P3')))
  good <- data.frame(task_id = c(1L, 1L), id = c('CMP_0001', 'CMP_0001'), cell = c('P1', 'P1'), replicate = c(1L, 1L), seed = c(2026101001L, 2026101001L), engine = c('drmTMB', 'glmmTMB'), selected = TRUE, pd_hess = TRUE, estimate = 0, lower = -1, upper = 1, elapsed_sec = 1, error = NA_character_, profile_available = TRUE)
  validate_result(good, m[1, , drop = FALSE], 1L)
  bad <- good; bad$cell[[2L]] <- 'P2'; stopifnot(inherits(try(validate_result(bad, m[1, , drop = FALSE], 1L), silent = TRUE), 'try-error'))
  cat('PHYLO_TEMPORAL_OU_COMPARATOR_REVERIFY_SELFTEST_PASS\n'); quit(save = 'no')
}
if (length(args) != 2L || any(!grepl('^--(campaign-dir|output-dir)=', args))) stop('Use --campaign-dir=<immutable task archives> --output-dir=<new result directory>, or --self-test.', call. = FALSE)
campaign_dir <- normalizePath(value('--campaign-dir='), mustWork = TRUE)
out_dir <- value('--output-dir=')
if (!nzchar(out_dir) || file.exists(out_dir)) stop('Re-verifier refuses to overwrite a retained output directory.', call. = FALSE)
dir.create(out_dir, recursive = TRUE)
m <- manifest()
read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
read_task <- function(task) {
  archive <- file.path(campaign_dir, sprintf('task-%04d.tar.gz', task)); sidecar <- paste0(archive, '.sha256')
  inventory <- data.frame(task_id = task, archive_present = file.exists(archive), sidecar_present = file.exists(sidecar), checksum_valid = FALSE, complete = FALSE, error = NA_character_, stringsAsFactors = FALSE)
  if (!inventory$archive_present || !inventory$sidecar_present) { inventory$error <- 'missing archive or SHA-256 sidecar'; return(list(inventory = inventory)) }
  check <- suppressWarnings(system2('sha256sum', c('-c', basename(sidecar)), stdout = TRUE, stderr = TRUE, wd = dirname(archive)))
  if (!is.null(attr(check, 'status'))) { inventory$error <- 'SHA-256 sidecar does not verify archive'; return(list(inventory = inventory)) }
  inventory$checksum_valid <- TRUE
  tmp <- tempfile('comparator-reverify-'); dir.create(tmp); on.exit(unlink(tmp, recursive = TRUE, force = TRUE), add = TRUE)
  if (inherits(try(utils::untar(archive, exdir = tmp), silent = TRUE), 'try-error')) { inventory$error <- 'archive extraction failed'; return(list(inventory = inventory)) }
  model <- file.path(tmp, sprintf('task-%04d', task), 'model-artifact')
  needed <- c('TASK_COMPLETE', 'manifest-row.csv', 'engine-results.csv', 'criteria.csv', 'provenance.csv')
  if (!all(file.exists(file.path(model, needed)))) { inventory$error <- 'archive lacks required completed model artifact'; return(list(inventory = inventory)) }
  criteria <- read_csv(file.path(model, 'criteria.csv'))
  if (!all(criteria$pass)) { inventory$error <- 'task structural criterion failed'; return(list(inventory = inventory)) }
  expected <- m[m$task_id == task, , drop = FALSE]
  result <- try(validate_result(read_csv(file.path(model, 'engine-results.csv')), expected, task), silent = TRUE)
  if (inherits(result, 'try-error')) { inventory$error <- conditionMessage(attr(result, 'condition')); return(list(inventory = inventory)) }
  inventory$complete <- TRUE
  list(inventory = inventory, result = result, provenance = read_csv(file.path(model, 'provenance.csv')))
}
rows <- lapply(m$task_id, read_task)
inventory <- do.call(rbind, lapply(rows, `[[`, 'inventory'))
utils::write.csv(inventory, file.path(out_dir, 'task-inventory.csv'), row.names = FALSE)
if (!all(inventory$complete)) stop('Comparator campaign is incomplete or corrupt; inventory retained.', call. = FALSE)
results <- do.call(rbind, lapply(rows, `[[`, 'result'))
provenance <- do.call(rbind, lapply(rows, `[[`, 'provenance'))
keys <- c('source_commit', 'worker_md5', 'assessment_helper_md5', 'drmTMB_version', 'glmmTMB_version', 'profile_level', 'drm_profile_precision')
values <- lapply(keys, function(k) unique(provenance$value[provenance$key == k])); names(values) <- keys
if (any(vapply(values, length, integer(1)) != 1L) || !grepl('^[0-9a-f]{40}$', values$source_commit) || !identical(values$profile_level, '0.95') || !identical(values$drm_profile_precision, 'fast')) stop('Comparator campaign has mixed or malformed provenance.', call. = FALSE)
if (nrow(results) != 6000L || anyDuplicated(paste(results$task_id, results$engine))) stop('Comparator campaign lacks the complete engine-task denominator.', call. = FALSE)
results$covers <- results$profile_available & results$lower <= 0 & results$upper >= 0
summary <- do.call(rbind, lapply(split(results, interaction(results$cell, results$engine, drop = TRUE)), function(x) data.frame(cell = x$cell[[1L]], engine = x$engine[[1L]], n_attempted = nrow(x), n_available = sum(x$profile_available), availability = mean(x$profile_available), coverage_all = mean(x$covers), coverage_conditional = if (any(x$profile_available)) mean(x$covers[x$profile_available]) else NA_real_, lower_tail_all = mean(x$profile_available & x$lower > 0), upper_tail_all = mean(x$profile_available & x$upper < 0), mean_interval_width = if (any(x$profile_available)) mean(x$upper[x$profile_available] - x$lower[x$profile_available]) else NA_real_, mean_elapsed_sec = mean(x$elapsed_sec), stringsAsFactors = FALSE)))
wide <- reshape(results[, c('task_id', 'cell', 'engine', 'estimate', 'lower', 'upper', 'covers')], idvar = c('task_id', 'cell'), timevar = 'engine', direction = 'wide')
paired <- data.frame(cell = unique(wide$cell), stringsAsFactors = FALSE)
paired <- do.call(rbind, lapply(split(wide, wide$cell), function(x) data.frame(cell = x$cell[[1L]], n = nrow(x), n_cover_disagree = sum(x$covers.drmTMB != x$covers.glmmTMB), mean_abs_estimate_difference = mean(abs(x$estimate.drmTMB - x$estimate.glmmTMB)), p95_abs_lower_difference = unname(stats::quantile(abs(x$lower.drmTMB - x$lower.glmmTMB), .95)), p95_abs_upper_difference = unname(stats::quantile(abs(x$upper.drmTMB - x$upper.glmmTMB), .95)), stringsAsFactors = FALSE)))
utils::write.csv(results, file.path(out_dir, 'engine-results.csv'), row.names = FALSE)
utils::write.csv(summary, file.path(out_dir, 'summary.csv'), row.names = FALSE)
utils::write.csv(paired, file.path(out_dir, 'paired-summary.csv'), row.names = FALSE)
utils::write.csv(provenance, file.path(out_dir, 'provenance.csv'), row.names = FALSE)
writeLines(c('# Paired phylogenetic-OU comparator re-verification', '', sprintf('Archives inspected: %d.', nrow(inventory)), sprintf('Source commit: %s.', values$source_commit), 'No model fit was launched by this re-verifier.'), file.path(out_dir, 'RESULTS.md'))
cat('PHYLO_TEMPORAL_OU_COMPARATOR_REVERIFY_PASS\n')
