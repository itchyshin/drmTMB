#!/usr/bin/env Rscript
# One immutable, paired drmTMB/glmmTMB comparator task.  This is campaign
# plumbing only: it does not change the failed G13 calibration verdict.
args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep('^--file=', commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop('Run with Rscript.', call. = FALSE)
script_path <- normalizePath(sub('^--file=', '', script_arg))
root <- normalizePath(file.path(dirname(script_path), '..'), mustWork = TRUE)
value <- function(prefix) {
  out <- grep(paste0('^', prefix), args, value = TRUE)
  if (length(out) != 1L) return(NULL)
  sub(prefix, '', out)
}
make_schedule <- function(kind, n_species) {
  if (identical(kind, '6_irregular')) return(rep(list(c(0, .5, 2, 4.5, 7, 11)), n_species))
  if (identical(kind, '12_irregular')) return(rep(list(c(0, .25, 1, 2.5, 4, 6.5, 9, 12, 16, 21, 27, 34)), n_species))
  base <- c(0, .5, 1.7, 3.2, 5, 8.1, 11.3, 15.6, 20, 25.4, 31, 38)
  lapply(seq_len(n_species), function(i) base[seq_len(4L + (i - 1L) %% 9L)])
}
simulate_fixture <- function(meta) {
  set.seed(meta$seed)
  tree <- ape::rcoal(meta$n_species)
  tree$tip.label <- sprintf('sp_%03d', seq_len(meta$n_species))
  schedules <- make_schedule(meta$occasions, meta$n_species)
  data <- do.call(rbind, Map(function(species, elapsed) data.frame(species = species, elapsed = elapsed), tree$tip.label, schedules))
  data$species <- factor(data$species, levels = tree$tip.label)
  data$between <- rep(sample(rep(c(-.5, .5), each = meta$n_species / 2L)), lengths(schedules))
  data$within <- unlist(lapply(schedules, function(time) { z <- sample(rep(c(-.5, .5), length.out = length(time))); z - mean(z) }), use.names = FALSE)
  A <- ape::vcv(tree, corr = TRUE)[tree$tip.label, tree$tip.label, drop = FALSE]
  stable <- drop(t(chol(A)) %*% stats::rnorm(meta$n_species, sd = meta$sd_phylo)); names(stable) <- tree$tip.label
  temporal <- unlist(lapply(schedules, function(time) { R <- exp(-meta$decay * abs(outer(time, time, '-'))); drop(t(chol(R)) %*% stats::rnorm(length(time), sd = meta$sd_temporal)) }), use.names = FALSE)
  data$y <- .5 * data$between + .5 * data$within + stable[as.character(data$species)] + temporal + stats::rnorm(nrow(data), sd = meta$sigma)
  list(data = data[sample.int(nrow(data)), , drop = FALSE], tree = tree)
}
self_test <- identical(args, '--self-test')
if (self_test) {
  source(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))
  m <- phylo_temporal_ou_g11_manifest()
  phylo_temporal_ou_g11_validate_manifest(m)
  stopifnot(nrow(m[m$task_id <= 3000L, ]) == 3000L, all(m$cell[m$task_id <= 3000L] %in% c('P1', 'P2', 'P3')))
  cat('PHYLO_TEMPORAL_OU_COMPARATOR_TASK_SELFTEST_PASS\n')
  quit(save = 'no')
}
if (length(args) != 3L || any(!grepl('^--(task|output-dir|source-commit)=', args))) stop('Use --task=<1..3000> --output-dir=<new directory> --source-commit=<40-hex SHA>, or --self-test.', call. = FALSE)
task <- suppressWarnings(as.integer(value('--task=')))
out_dir <- value('--output-dir=')
source_commit <- value('--source-commit=')
if (length(task) != 1L || is.na(task) || task < 1L || task > 3000L) stop('--task must be an integer from 1 through 3000.', call. = FALSE)
if (!nzchar(out_dir) || file.exists(out_dir)) stop('--output-dir must be new.', call. = FALSE)
if (!grepl('^[0-9a-f]{40}$', source_commit)) stop('--source-commit must be a lowercase 40-character SHA.', call. = FALSE)
actual <- if (file.exists(file.path(root, '.git'))) system2('git', c('rev-parse', 'HEAD'), stdout = TRUE, stderr = TRUE) else Sys.getenv('DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_COMMIT', unset = '')
if (length(actual) != 1L || !identical(actual, source_commit)) stop('Source checkout/archive does not equal --source-commit.', call. = FALSE)
if (!requireNamespace('glmmTMB', quietly = TRUE)) stop('glmmTMB is required.', call. = FALSE)
Sys.setenv(OMP_NUM_THREADS = '1', OPENBLAS_NUM_THREADS = '1', MKL_NUM_THREADS = '1', TMB_NTHREADS = '1')
if (identical(Sys.getenv('DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_USE_INSTALLED'), '1')) library(drmTMB) else pkgload::load_all(root, quiet = TRUE)
source(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))
manifest <- phylo_temporal_ou_g11_manifest()
meta <- manifest[manifest$task_id == task, , drop = FALSE]
if (nrow(meta) != 1L || !meta$cell %in% c('P1', 'P2', 'P3')) stop('Frozen manifest task is absent or outside P1--P3.', call. = FALSE)
profile_drm <- function(fit) {
  ci <- stats::confint(fit, parm = 'fixef:mu:(Intercept)', method = 'profile', level = .95, profile_engine = 'tmbprofile', profile_precision = 'fast', trace = FALSE)
  c(estimate = unname(fit$coefficients$mu[['(Intercept)']]), lower = ci$lower, upper = ci$upper)
}
profile_glmm <- function(fit) {
  ci <- stats::confint(fit, parm = 1L, component = 'cond', method = 'profile', level = .95, ncpus = 1L)
  c(estimate = unname(glmmTMB::fixef(fit)$cond[['(Intercept)']]), lower = ci[1L, 1L], upper = ci[1L, 2L])
}
run_engine <- function(engine, generated) {
  started <- proc.time()[['elapsed']]
  answer <- try({
    if (identical(engine, 'drmTMB')) {
      tree <- generated$tree
      fit <- drmTMB(bf(y ~ between + within + phylo(1 | species, tree = tree) + temporal(1 | species, time = elapsed, structure = 'ou'), sigma ~ 1), data = generated$data, family = gaussian(), REML = FALSE)
      values <- profile_drm(fit)
    } else {
      data <- generated$data; data$dummy <- factor(1); data$time_factor <- glmmTMB::numFactor(data$elapsed)
      A <- ape::vcv(generated$tree, corr = TRUE)[generated$tree$tip.label, generated$tree$tip.label, drop = FALSE]
      fit <- glmmTMB::glmmTMB(y ~ between + within + propto(0 + species | dummy, A) + ou(time_factor + 0 | species), data = data, family = gaussian(), REML = FALSE)
      values <- profile_glmm(fit)
    }
    data.frame(engine = engine, selected = TRUE, pd_hess = isTRUE(fit$sdr$pdHess), estimate = values[['estimate']], lower = values[['lower']], upper = values[['upper']], elapsed_sec = proc.time()[['elapsed']] - started, error = NA_character_)
  }, silent = TRUE)
  if (inherits(answer, 'try-error')) data.frame(engine = engine, selected = FALSE, pd_hess = NA, estimate = NA_real_, lower = NA_real_, upper = NA_real_, elapsed_sec = proc.time()[['elapsed']] - started, error = as.character(answer)) else answer
}
dir.create(out_dir, recursive = TRUE)
generated <- simulate_fixture(meta)
results <- do.call(rbind, lapply(c('drmTMB', 'glmmTMB'), run_engine, generated = generated))
results <- cbind(data.frame(task_id = task, id = sprintf('CMP_%04d', task), cell = meta$cell, replicate = meta$replicate, seed = meta$seed), results)
results$profile_available <- results$selected & is.finite(results$lower) & is.finite(results$upper)
criteria <- data.frame(criterion = c('one frozen P1--P3 manifest row', 'two engine rows'), observed = c(nrow(meta), nrow(results)), expected = c(1L, 2L), pass = c(nrow(meta) == 1L, nrow(results) == 2L && identical(results$engine, c('drmTMB', 'glmmTMB'))), stringsAsFactors = FALSE)
provenance <- data.frame(key = c('source_commit', 'worker_md5', 'assessment_helper_md5', 'task_id', 'seed', 'cell', 'drmTMB_version', 'glmmTMB_version', 'profile_level', 'drm_profile_precision'), value = c(source_commit, unname(tools::md5sum(script_path)), unname(tools::md5sum(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))), task, meta$seed, meta$cell, as.character(utils::packageVersion('drmTMB')), as.character(utils::packageVersion('glmmTMB')), '0.95', 'fast'), stringsAsFactors = FALSE)
utils::write.csv(meta, file.path(out_dir, 'manifest-row.csv'), row.names = FALSE)
utils::write.csv(results, file.path(out_dir, 'engine-results.csv'), row.names = FALSE)
utils::write.csv(criteria, file.path(out_dir, 'criteria.csv'), row.names = FALSE)
utils::write.csv(provenance, file.path(out_dir, 'provenance.csv'), row.names = FALSE)
saveRDS(list(manifest = meta, results = results, criteria = criteria, provenance = provenance), file.path(out_dir, 'task-result.rds'))
capture.output(sessionInfo(), file = file.path(out_dir, 'session-info.txt'))
writeLines(c('# Paired phylogenetic-OU comparator task', '', sprintf('Task: %d (%s replicate %d; seed %d).', task, meta$cell, meta$replicate, meta$seed), sprintf('Profiles available: %d/2.', sum(results$profile_available)), 'Each engine result, including failures, is retained for the no-fit campaign re-verifier.'), file.path(out_dir, 'RESULTS.md'))
if (!all(criteria$pass)) stop('Comparator task structure is incomplete; retained artifact is available for diagnosis.', call. = FALSE)
cat('PHYLO_TEMPORAL_OU_COMPARATOR_TASK_PASS\n')
