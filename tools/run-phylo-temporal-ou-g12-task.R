#!/usr/bin/env Rscript
# Approved G10 timing and diagnostics pilot.  It is deliberately not a coverage
# campaign: its role is to measure the frozen P1--P4 design before G11/G12.
# Source-pinned G12 campaign worker. One invocation generates, fits, and
# profiles exactly one immutable task from the frozen G11 manifest.
args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep('^--file=', commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop('Run this script through Rscript.', call. = FALSE)
script_path <- normalizePath(sub('^--file=', '', script_arg))
root <- normalizePath('.', mustWork = TRUE)
if (!file.exists(file.path(root, 'DESCRIPTION'))) stop('Run from the drmTMB source root.', call. = FALSE)

option_value <- function(prefix, default = NULL) {
  found <- grep(paste0('^', prefix), args, value = TRUE)
  if (!length(found)) return(default)
  if (length(found) != 1L) stop('Specify ', prefix, ' at most once.', call. = FALSE)
  sub(prefix, '', found)
}
self_test <- identical(args, '--self-test')
if (!self_test && (length(args) != 3L || any(!grepl('^--(task|output-dir|source-commit)=', args)))) {
  stop('Use --self-test or exactly --task=<1..3500> --output-dir=<empty directory> --source-commit=<40-hex SHA>.', call. = FALSE)
}
if (self_test) {
  source(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))
  manifest <- utils::read.csv(file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g11-contract/manifest.csv'), stringsAsFactors = FALSE)
  phylo_temporal_ou_g11_validate_manifest(manifest)
  cat('PHYLO_TEMPORAL_OU_G12_WORKER_SELFTEST_PASS\n')
  quit(save = 'no', status = 0L)
}
task_arg <- suppressWarnings(as.integer(option_value('--task=')))
out_dir <- option_value('--output-dir=')
source_commit <- option_value('--source-commit=')
if (length(task_arg) != 1L || is.na(task_arg) || task_arg < 1L || task_arg > 3500L) stop('--task must be an integer from 1 through 3500.', call. = FALSE)
if (!is.character(out_dir) || !nzchar(out_dir)) stop('--output-dir must name an empty task directory.', call. = FALSE)
if (!is.character(source_commit) || !grepl('^[0-9a-f]{40}$', source_commit)) stop('--source-commit must be a 40-character lowercase Git SHA.', call. = FALSE)
actual_commit <- if (dir.exists(file.path(root, '.git'))) system2('git', c('rev-parse', 'HEAD'), stdout = TRUE, stderr = TRUE) else Sys.getenv('DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_COMMIT', unset = '')
if (length(actual_commit) != 1L || !identical(actual_commit, source_commit)) stop('Source archive or checkout does not equal --source-commit.', call. = FALSE)
if (dir.exists(out_dir) || file.exists(out_dir)) stop('Refuse to overwrite a retained G12 task artifact.', call. = FALSE)
source(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))
manifest <- utils::read.csv(file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g11-contract/manifest.csv'), stringsAsFactors = FALSE)
phylo_temporal_ou_g11_validate_manifest(manifest)
meta <- manifest[manifest$task_id == task_arg, , drop = FALSE]
if (nrow(meta) != 1L) stop('Frozen manifest did not yield exactly one requested task.', call. = FALSE)
meta$id <- sprintf('G12_%04d', meta$task_id)
meta$schedule <- c('6_irregular' = 'p1', '12_irregular' = 'p2', '4_to_12_irregular' = 'p3')[[meta$occasions]]
if (is.null(meta$schedule) || is.na(meta$schedule)) stop('Frozen manifest contains an unsupported occasion schedule.', call. = FALSE)
meta$sd_phylo_truth <- meta$sd_phylo
meta$decay_truth <- meta$decay
if (identical(Sys.getenv('DRMTMB_PHYLO_TEMPORAL_OU_G12_USE_INSTALLED'), '1')) {
  library(drmTMB)
} else {
  pkgload::load_all(root, quiet = TRUE)
}
truth <- c(intercept = 0, between = 0.5, within = 0.5, sd_temporal = meta$sd_temporal, sigma = meta$sigma)
make_schedule <- function(kind, n_species) {
  if (identical(kind, 'p1')) return(rep(list(c(0, 0.5, 2, 4.5, 7, 11)), n_species))
  if (identical(kind, 'p2')) return(rep(list(c(0, 0.25, 1, 2.5, 4, 6.5, 9, 12, 16, 21, 27, 34)), n_species))
  if (identical(kind, 'p3')) {
    base <- c(0, 0.5, 1.7, 3.2, 5, 8.1, 11.3, 15.6, 20, 25.4, 31, 38)
    return(lapply(seq_len(n_species), function(i) base[seq_len(4L + (i - 1L) %% 9L)]))
  }
  stop('Frozen manifest contains an unsupported occasion schedule.', call. = FALSE)
}
within_values <- function(schedules) {
  unlist(lapply(schedules, function(time) {
    value <- sample(rep(c(-0.5, 0.5), length.out = length(time)))
    value - mean(value)
  }), use.names = FALSE)
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(meta, file.path(out_dir, 'manifest-row.csv'), row.names = FALSE)
simulate_fixture <- function(meta) {
  set.seed(meta$seed)
  tree <- ape::rcoal(meta$n_species)
  tree$tip.label <- sprintf('sp_%03d', seq_len(meta$n_species))
  schedules <- make_schedule(meta$schedule, meta$n_species)
  data <- do.call(rbind, Map(function(species, elapsed) data.frame(species = species, elapsed = elapsed), tree$tip.label, schedules))
  data$species <- factor(data$species, levels = tree$tip.label)
  data$between <- rep(sample(rep(c(-0.5, 0.5), each = meta$n_species / 2L)), lengths(schedules))
  data$within <- within_values(schedules)
  A <- ape::vcv(tree, corr = TRUE)[tree$tip.label, tree$tip.label, drop = FALSE]
  stable <- drop(t(chol(A)) %*% stats::rnorm(meta$n_species, sd = meta$sd_phylo_truth))
  names(stable) <- tree$tip.label
  temporal <- unlist(lapply(schedules, function(time) {
    R <- exp(-meta$decay_truth * abs(outer(time, time, '-')))
    drop(t(chol(R)) %*% stats::rnorm(length(time), sd = truth[['sd_temporal']]))
  }), use.names = FALSE)
  data$y <- truth[['intercept']] + truth[['between']] * data$between + truth[['within']] * data$within +
    stable[as.character(data$species)] + temporal + stats::rnorm(nrow(data), sd = truth[['sigma']])
  list(data = data[sample.int(nrow(data)), , drop = FALSE], tree = tree)
}
peak_r_mb <- function() {
  usage <- gc()
  sum(usage[, 'max used'] * c(56, 8)) / 1024^2
}
record_warning <- function(expr, collector, id, stage) {
  withCallingHandlers(expr, warning = function(w) {
    collector$rows[[length(collector$rows) + 1L]] <- data.frame(
      id = id, stage = stage, warning = conditionMessage(w), stringsAsFactors = FALSE
    )
    invokeRestart('muffleWarning')
  })
}
empty_attempts <- function(meta, error) {
  data.frame(id = meta$id, cell = meta$cell, replicate = meta$replicate,
             start = c('negative', 'positive'), decay_start = c(-0.3, 0.3), status = 'fit_error',
             convergence = NA_integer_, objective = NA_real_, elapsed_sec = NA_real_, selected = FALSE,
             error = error, stringsAsFactors = FALSE)
}
profile_rows_for_error <- function(meta, message) {
  data.frame(id = meta$id, cell = meta$cell, replicate = meta$replicate,
             parm = paste0('fixef:mu:', c('(Intercept)', 'between', 'within')),
             available = FALSE, conf_status = 'unavailable', lower = NA_real_, upper = NA_real_,
             elapsed_sec = NA_real_, error = message, stringsAsFactors = FALSE)
}
run_one <- function(meta) {
  collector <- new.env(parent = emptyenv())
  collector$rows <- list()
  generated <- simulate_fixture(meta)
  fit_started <- proc.time()[['elapsed']]
  fitted <- tryCatch(record_warning({
    tree <- generated$tree
    drmTMB(
      bf(y ~ between + within + phylo(1 | species, tree = tree) +
           temporal(1 | species, time = elapsed, structure = 'ou'), sigma ~ 1),
      data = generated$data, family = gaussian(), REML = FALSE
    )
  }, collector, meta$id, 'fit'), error = identity)
  fit_elapsed <- proc.time()[['elapsed']] - fit_started
  if (inherits(fitted, 'error')) {
    return(list(
      selected = data.frame(id = meta$id, cell = meta$cell, replicate = meta$replicate, selected = FALSE,
                            n_observation = nrow(generated$data), elapsed_sec = fit_elapsed, peak_r_mb = peak_r_mb(),
                            objective = NA_real_, beta_intercept = NA_real_, beta_between = NA_real_, beta_within = NA_real_,
                            error = conditionMessage(fitted), stringsAsFactors = FALSE),
      attempts = empty_attempts(meta, conditionMessage(fitted)),
      profiles = profile_rows_for_error(meta, conditionMessage(fitted)),
      diagnostics = data.frame(id = meta$id, convergence = NA_integer_, pd_hess = NA, optimizer_message = NA_character_,
                               profile_available = 0L, fit_warning_count = length(collector$rows), profile_warning_count = 0L,
                               stringsAsFactors = FALSE),
      warnings = if (length(collector$rows)) do.call(rbind, collector$rows) else data.frame(id = character(), stage = character(), warning = character())
    ))
  }
  temporal <- fitted$model$structured$temporal_mu
  selected <- data.frame(
    id = meta$id, cell = meta$cell, replicate = meta$replicate, selected = TRUE, n_observation = nrow(generated$data),
    elapsed_sec = fit_elapsed, peak_r_mb = peak_r_mb(), objective = -as.numeric(stats::logLik(fitted)),
    beta_intercept = unname(fitted$coefficients$mu[['(Intercept)']]),
    beta_between = unname(fitted$coefficients$mu[['between']]), beta_within = unname(fitted$coefficients$mu[['within']]),
    error = NA_character_, stringsAsFactors = FALSE
  )
  attempts <- fitted$temporal_start_attempts
  if (is.null(attempts) || nrow(attempts) != 2L) {
    attempts <- empty_attempts(meta, 'temporal_start_attempts did not retain exactly two starts')
  } else {
    attempts$id <- meta$id; attempts$cell <- meta$cell; attempts$replicate <- meta$replicate; attempts$error <- NA_character_
    attempts <- attempts[, c('id', 'cell', 'replicate', 'start', 'decay_start', 'status', 'convergence', 'objective', 'elapsed_sec', 'selected', 'error')]
  }
  targets <- profile_targets(fitted)
  profile_parm <- targets$parm[targets$target_class == 'fixed-effect' & targets$dpar == 'mu']
  expected_parm <- paste0('fixef:mu:', c('(Intercept)', 'between', 'within'))
  if (!setequal(profile_parm, expected_parm)) {
    profiles <- profile_rows_for_error(meta, 'mean profile target registry does not contain exactly the three frozen targets')
  } else {
    profiles <- lapply(expected_parm, function(parm) {
      started <- proc.time()[['elapsed']]
      value <- tryCatch(record_warning(
        stats::confint(fitted, parm = parm, method = 'profile', level = 0.95,
                       profile_engine = 'tmbprofile', profile_precision = 'fast', trace = FALSE),
        collector, meta$id, paste0('profile:', parm)
      ), error = identity)
      elapsed <- proc.time()[['elapsed']] - started
      if (inherits(value, 'error')) return(data.frame(id = meta$id, cell = meta$cell, replicate = meta$replicate,
        parm = parm, available = FALSE, conf_status = 'unavailable', lower = NA_real_, upper = NA_real_, elapsed_sec = elapsed,
        error = conditionMessage(value), stringsAsFactors = FALSE))
      data.frame(id = meta$id, cell = meta$cell, replicate = meta$replicate, parm = parm,
                 available = identical(value$conf.status, 'profile') && is.finite(value$lower) && is.finite(value$upper),
                 conf_status = value$conf.status, lower = value$lower, upper = value$upper, elapsed_sec = elapsed,
                 error = NA_character_, stringsAsFactors = FALSE)
    })
    profiles <- do.call(rbind, profiles)
  }
  warning_table <- if (length(collector$rows)) do.call(rbind, collector$rows) else data.frame(id = character(), stage = character(), warning = character())
  diagnostics <- data.frame(
    id = meta$id, convergence = if (length(fitted$opt$convergence) == 1L) fitted$opt$convergence else NA_integer_,
    pd_hess = isTRUE(fitted$sdr$pdHess),
    optimizer_message = if (length(fitted$opt$message) == 1L) as.character(fitted$opt$message) else NA_character_,
    profile_available = sum(profiles$available), fit_warning_count = sum(warning_table$stage == 'fit'),
    profile_warning_count = sum(grepl('^profile:', warning_table$stage)), stringsAsFactors = FALSE
  )
  list(selected = selected, attempts = attempts, profiles = profiles, diagnostics = diagnostics, warnings = warning_table)
}

result <- run_one(meta)
selected <- result$selected
attempts <- result$attempts
profiles <- result$profiles
warnings <- result$warnings
if (is.null(warnings) || !nrow(warnings)) warnings <- data.frame(id = character(), stage = character(), warning = character(), stringsAsFactors = FALSE)
diagnostics <- result$diagnostics
criteria <- data.frame(
  criterion = c('one manifest task', 'two temporal starts retained', 'three fixed-mean profiles retained', 'one diagnostics record', 'source-pinned provenance'),
  observed = c(nrow(meta), nrow(attempts), nrow(profiles), nrow(diagnostics), 1L),
  expected = c(1L, 2L, 3L, 1L, 1L),
  pass = c(nrow(meta) == 1L, nrow(attempts) == 2L, nrow(profiles) == 3L, nrow(diagnostics) == 1L, TRUE),
  stringsAsFactors = FALSE
)
provenance <- data.frame(
  key = c('source_commit', 'worker_md5', 'assessment_helper_md5', 'task_id', 'seed', 'cell', 'run_utc', 'profile_engine', 'profile_precision', 'profile_level', 'command'),
  value = c(source_commit, unname(tools::md5sum(script_path)), unname(tools::md5sum(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))),
            meta$task_id, meta$seed, meta$cell, format(Sys.time(), tz = 'UTC', usetz = TRUE), 'tmbprofile', 'fast', '0.95', paste(commandArgs(), collapse = ' ')),
  stringsAsFactors = FALSE
)
utils::write.csv(selected, file.path(out_dir, 'selected-fit.csv'), row.names = FALSE)
utils::write.csv(attempts, file.path(out_dir, 'attempts.csv'), row.names = FALSE)
utils::write.csv(profiles, file.path(out_dir, 'profiles.csv'), row.names = FALSE)
utils::write.csv(diagnostics, file.path(out_dir, 'diagnostics.csv'), row.names = FALSE)
utils::write.csv(warnings, file.path(out_dir, 'warnings.csv'), row.names = FALSE)
utils::write.csv(criteria, file.path(out_dir, 'criteria.csv'), row.names = FALSE)
utils::write.csv(provenance, file.path(out_dir, 'provenance.csv'), row.names = FALSE)
saveRDS(list(manifest = meta, selected = selected, attempts = attempts, profiles = profiles,
             diagnostics = diagnostics, warnings = warnings, criteria = criteria, provenance = provenance),
        file.path(out_dir, 'task-result.rds'))
capture.output(sessionInfo(), file = file.path(out_dir, 'session-info.txt'))
writeLines(c('# G12 source-pinned task artifact', '',
  sprintf('Task: %d (%s replicate %d; seed %d).', meta$task_id, meta$cell, meta$replicate, meta$seed),
  sprintf('Fit selected: %s; profile endpoints available: %d/3.', selected$selected, diagnostics$profile_available),
  'Unavailable fits or intervals are retained as data and count in G13 all-attempt denominators.',
  'This artifact is an input to G13 re-verification, not a public inference claim.'), file.path(out_dir, 'RESULTS.md'))
writeLines('PHYLO_TEMPORAL_OU_G12_TASK_COMPLETE', file.path(out_dir, 'TASK_COMPLETE'))
if (!all(criteria$pass)) stop('G12 task denominator is incomplete; retained artifact is available for diagnosis.', call. = FALSE)
cat('PHYLO_TEMPORAL_OU_G12_TASK_PASS\n')
