#!/usr/bin/env Rscript
# Approved G10 timing and diagnostics pilot.  It is deliberately not a coverage
# campaign: its role is to measure the frozen P1--P4 design before G11/G12.
args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep('^--file=', commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop('Run this script through Rscript.', call. = FALSE)
script_path <- normalizePath(sub('^--file=', '', script_arg))
root <- normalizePath('.', mustWork = TRUE)
if (!file.exists(file.path(root, 'DESCRIPTION'))) stop('Run from the drmTMB root.', call. = FALSE)

mode <- if ('--preflight' %in% args) 'preflight' else 'full'
args <- setdiff(args, '--preflight')
option_value <- function(prefix, default = NULL) {
  found <- grep(paste0('^', prefix), args, value = TRUE)
  if (!length(found)) return(default)
  if (length(found) != 1L) stop('Specify ', prefix, ' at most once.', call. = FALSE)
  sub(prefix, '', found)
}
cell_arg <- option_value('--cells=', if (identical(mode, 'preflight')) 'P1' else 'P1,P2,P3,P4')
replicate_arg <- option_value('--replicates=', if (identical(mode, 'preflight')) '1' else '5')
known_args <- c(paste0('--cells=', cell_arg), paste0('--replicates=', replicate_arg))
if (anyDuplicated(args) || length(setdiff(args, known_args))) {
  stop('Use only --preflight, --cells=P1[,P2,...], and --replicates=<positive integer>.', call. = FALSE)
}
selected_cells <- strsplit(cell_arg, ',', fixed = TRUE)[[1L]]
if (!length(selected_cells) || any(!selected_cells %in% c('P1', 'P2', 'P3', 'P4'))) {
  stop('Unknown G10 cell.', call. = FALSE)
}
replicates <- suppressWarnings(as.integer(replicate_arg))
if (length(replicates) != 1L || is.na(replicates) || replicates < 1L) {
  stop('--replicates must be a positive whole number.', call. = FALSE)
}
if (identical(mode, 'full') && (!identical(selected_cells, c('P1', 'P2', 'P3', 'P4')) || replicates != 5L)) {
  stop('The retained G10 pilot must use all P1--P4 cells and five seeds per cell.', call. = FALSE)
}
if (identical(mode, 'preflight') && (!identical(selected_cells, 'P1') || replicates != 1L)) {
  stop('The G10 preflight is frozen as one P1 seed.', call. = FALSE)
}

pkgload::load_all(root, quiet = TRUE)
base_out <- Sys.getenv(
  'DRMTMB_PHYLO_TEMPORAL_OU_G10_OUT',
  unset = file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g10-pilot')
)
out_dir <- if (identical(mode, 'preflight')) file.path(base_out, 'preflight-p1-seed-2026091701-v2') else base_out
required <- c(
  'manifest.csv', 'selected-fits.csv', 'attempts.csv', 'profiles.csv', 'diagnostics.csv',
  'warnings.csv', 'criteria.csv', 'provenance.csv', 'g10-pilot-results.rds', 'session-info.txt', 'RESULTS.md'
)
if (any(file.exists(file.path(out_dir, required)))) {
  stop('G10 pilot artifacts already exist; do not overwrite retained evidence.', call. = FALSE)
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

truth <- c(intercept = 0, between = 0.5, within = 0.5, sd_temporal = 0.8, sigma = 0.4)
cells <- data.frame(
  cell = c('P1', 'P2', 'P3', 'P4'),
  n_species = c(80L, 80L, 80L, 20L),
  schedule = c('p1', 'p2', 'p3', 'p1'),
  sd_phylo = c(0.6, 1.0, 0.6, 1.0),
  decay = c(0.40, 0.15, 0.70, 0.15),
  role = c('primary_short_series', 'primary_persistent_signal', 'primary_unbalanced', 'stress'),
  stringsAsFactors = FALSE
)
cells <- cells[cells$cell %in% selected_cells, , drop = FALSE]
make_schedule <- function(kind, n_species) {
  if (identical(kind, 'p1')) return(rep(list(c(0, 0.5, 2, 4.5, 7, 11)), n_species))
  if (identical(kind, 'p2')) return(rep(list(c(0, 0.25, 1, 2.5, 4, 6.5, 9, 12, 16, 21, 27, 34)), n_species))
  base <- c(0, 0.5, 1.7, 3.2, 5, 8.1, 11.3, 15.6, 20, 25.4, 31, 38)
  lapply(seq_len(n_species), function(i) base[seq_len(4L + (i - 1L) %% 9L)])
}
within_values <- function(schedules) {
  unlist(lapply(schedules, function(time) {
    value <- sample(rep(c(-0.5, 0.5), length.out = length(time)))
    value - mean(value)
  }), use.names = FALSE)
}
make_manifest <- function(cells, replicates) {
  rows <- lapply(seq_len(nrow(cells)), function(i) {
    cell <- cells[i, , drop = FALSE]
    data.frame(
      cell = cell$cell, replicate = seq_len(replicates),
      seed = as.integer(2026091700L + (match(cell$cell, c('P1', 'P2', 'P3', 'P4')) - 1L) * 100L + seq_len(replicates)),
      n_species = cell$n_species, schedule = cell$schedule, sd_phylo_truth = cell$sd_phylo,
      decay_truth = cell$decay, role = cell$role, stringsAsFactors = FALSE
    )
  })
  manifest <- do.call(rbind, rows)
  manifest$id <- sprintf('%s_%02d', manifest$cell, manifest$replicate)
  manifest[, c('id', 'cell', 'replicate', 'seed', 'n_species', 'schedule', 'sd_phylo_truth', 'decay_truth', 'role')]
}
manifest <- make_manifest(cells, replicates)
utils::write.csv(manifest, file.path(out_dir, 'manifest.csv'), row.names = FALSE)

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

rows <- lapply(seq_len(nrow(manifest)), function(i) run_one(manifest[i, , drop = FALSE]))
selected <- do.call(rbind, lapply(rows, `[[`, 'selected'))
attempts <- do.call(rbind, lapply(rows, `[[`, 'attempts'))
profiles <- do.call(rbind, lapply(rows, `[[`, 'profiles'))
diagnostics <- do.call(rbind, lapply(rows, `[[`, 'diagnostics'))
warnings <- do.call(rbind, lapply(rows, `[[`, 'warnings'))
if (is.null(warnings)) warnings <- data.frame(id = character(), stage = character(), warning = character())
criteria <- data.frame(
  criterion = c('complete generated-dataset denominator', 'complete selected-fit records',
                'complete configured two-start denominator', 'complete fixed-mean profile records',
                'complete diagnostics records', 'recorded source and runner provenance'),
  observed = c(nrow(manifest), nrow(selected), nrow(attempts), nrow(profiles), nrow(diagnostics), 2L),
  expected = c(nrow(manifest), nrow(manifest), 2L * nrow(manifest), 3L * nrow(manifest), nrow(manifest), 2L),
  pass = c(nrow(manifest) == nrow(selected), nrow(selected) == nrow(manifest),
           nrow(attempts) == 2L * nrow(manifest) && all(table(attempts$id) == 2L),
           nrow(profiles) == 3L * nrow(manifest) && all(table(profiles$id) == 3L),
           nrow(diagnostics) == nrow(manifest), TRUE), stringsAsFactors = FALSE
)
provenance <- data.frame(
  key = c('source_commit', 'runner_md5', 'run_utc', 'mode', 'cells', 'replicates_per_cell', 'seeds',
          'profile_engine', 'profile_precision', 'profile_level', 'command'),
  value = c(system2('git', c('rev-parse', 'HEAD'), stdout = TRUE), unname(tools::md5sum(script_path)),
            format(Sys.time(), tz = 'UTC', usetz = TRUE), mode, paste(selected_cells, collapse = ','), replicates,
            paste(manifest$seed, collapse = ','), 'tmbprofile', 'fast', '0.95', paste(commandArgs(), collapse = ' ')),
  stringsAsFactors = FALSE
)
utils::write.csv(selected, file.path(out_dir, 'selected-fits.csv'), row.names = FALSE)
utils::write.csv(attempts, file.path(out_dir, 'attempts.csv'), row.names = FALSE)
utils::write.csv(profiles, file.path(out_dir, 'profiles.csv'), row.names = FALSE)
utils::write.csv(diagnostics, file.path(out_dir, 'diagnostics.csv'), row.names = FALSE)
utils::write.csv(warnings, file.path(out_dir, 'warnings.csv'), row.names = FALSE)
utils::write.csv(criteria, file.path(out_dir, 'criteria.csv'), row.names = FALSE)
utils::write.csv(provenance, file.path(out_dir, 'provenance.csv'), row.names = FALSE)
saveRDS(list(truth = truth, manifest = manifest, selected = selected, attempts = attempts, profiles = profiles,
             diagnostics = diagnostics, warnings = warnings, criteria = criteria, provenance = provenance),
        file.path(out_dir, 'g10-pilot-results.rds'))
capture.output(sessionInfo(), file = file.path(out_dir, 'session-info.txt'))
profile_summary <- aggregate(available ~ cell + parm, data = profiles, FUN = function(x) sprintf('%d/%d', sum(x), length(x)))
writeLines(c(
  '# G10 timed pilot', '', sprintf('Mode: %s.', mode),
  sprintf('Generated datasets: %d; configured starts: %d; fixed-mean profile attempts: %d.', nrow(manifest), nrow(attempts), nrow(profiles)),
  sprintf('Total fit elapsed seconds: %.3f; total profile elapsed seconds: %.3f.', sum(selected$elapsed_sec, na.rm = TRUE), sum(profiles$elapsed_sec, na.rm = TRUE)),
  sprintf('Warnings retained: %d.', nrow(warnings)), '', 'Profile availability (available/attempted):',
  capture.output(print(profile_summary, row.names = FALSE)), '',
  'This measures timing, memory, diagnostics, and profile availability only. It is not a coverage or inference claim and does not authorize G12.'
), file.path(out_dir, 'RESULTS.md'))
if (!all(criteria$pass)) stop('G10 pilot denominator is incomplete; immutable artifacts were retained for diagnosis.', call. = FALSE)
cat(if (identical(mode, 'preflight')) 'PHYLO_TEMPORAL_OU_G10_PREFLIGHT_PASS\n' else 'PHYLO_TEMPORAL_OU_G10_PILOT_PASS\n')
