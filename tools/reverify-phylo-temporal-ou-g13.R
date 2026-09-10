#!/usr/bin/env Rscript
# G13 consumes immutable G12 task archives. It never loads drmTMB or fits data.
args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep('^--file=', commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop('Run with Rscript.', call. = FALSE)
script_path <- normalizePath(sub('^--file=', '', script_arg))
root <- normalizePath(file.path(dirname(script_path), '..'), mustWork = TRUE)
source(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))
value <- function(prefix) { x <- grep(paste0('^', prefix), args, value = TRUE); if (length(x) != 1L) return(NULL); sub(prefix, '', x) }
self_test <- identical(args, '--self-test')
if (self_test) {
  m <- phylo_temporal_ou_g11_manifest(); phylo_temporal_ou_g11_validate_manifest(m)
  stopifnot(nrow(m) == 3500L, nrow(phylo_temporal_ou_g11_targets()) == 12L)
  cat('PHYLO_TEMPORAL_OU_G13_REVERIFY_SELFTEST_PASS\n'); quit(save = 'no')
}
if (length(args) != 2L || any(!grepl('^--(campaign-dir|output-dir)=', args))) {
  stop('Use --campaign-dir=<immutable task archives> --output-dir=<new result directory>, or --self-test.', call. = FALSE)
}
campaign_dir <- normalizePath(value('--campaign-dir='), mustWork = TRUE)
out_dir <- value('--output-dir=')
if (!nzchar(out_dir) || file.exists(out_dir)) stop('G13 refuses to overwrite a retained result directory.', call. = FALSE)
dir.create(out_dir, recursive = TRUE)
manifest <- phylo_temporal_ou_g11_manifest(); targets <- phylo_temporal_ou_g11_targets()
archive_path <- function(task) file.path(campaign_dir, sprintf('task-%04d.tar.gz', task))
read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
read_task <- function(task) {
  archive <- archive_path(task); sha <- paste0(archive, '.sha256')
  base <- data.frame(task_id = task, archive = basename(archive), archive_present = file.exists(archive),
                     sidecar_present = file.exists(sha), sha256 = NA_character_, complete = FALSE,
                     error = NA_character_, stringsAsFactors = FALSE)
  if (!base$archive_present || !base$sidecar_present) { base$error <- 'missing immutable archive or checksum sidecar'; return(list(inventory = base)) }
  hash <- unname(tools::md5sum(archive)) # MD5 is a local corruption check; sidecar carries required SHA-256.
  sidecar <- readLines(sha, warn = FALSE)
  if (length(sidecar) != 1L || !grepl('^[0-9a-f]{64}  ', sidecar)) { base$error <- 'malformed SHA-256 sidecar'; return(list(inventory = base)) }
  base$sha256 <- sub(' .*', '', sidecar)
  tmp <- tempfile('g13-task-'); dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE, force = TRUE), add = TRUE)
  status <- try(utils::untar(archive, exdir = tmp), silent = TRUE)
  if (inherits(status, 'try-error')) { base$error <- 'archive extraction failed'; return(list(inventory = base)) }
  task_root <- file.path(tmp, sprintf('task-%04d', task)); model <- file.path(task_root, 'model-artifact')
  needed <- c('TASK_COMPLETE', 'selected-fit.csv', 'attempts.csv', 'profiles.csv', 'diagnostics.csv', 'criteria.csv', 'provenance.csv')
  if (!all(file.exists(file.path(model, needed)))) { base$error <- 'task archive lacks required completed artifact files'; return(list(inventory = base)) }
  criterion <- read_csv(file.path(model, 'criteria.csv'))
  if (!all(criterion$pass)) { base$error <- 'task criterion failed'; return(list(inventory = base)) }
  base$complete <- TRUE
  list(inventory = base, selected = read_csv(file.path(model, 'selected-fit.csv')),
       attempts = read_csv(file.path(model, 'attempts.csv')), profiles = read_csv(file.path(model, 'profiles.csv')),
       diagnostics = read_csv(file.path(model, 'diagnostics.csv')), provenance = read_csv(file.path(model, 'provenance.csv')))
}
rows <- lapply(manifest$task_id, read_task)
inventory <- do.call(rbind, lapply(rows, `[[`, 'inventory'))
if (!all(inventory$complete)) {
  utils::write.csv(inventory, file.path(out_dir, 'task-inventory.csv'), row.names = FALSE)
  stop('G13 found incomplete or failed immutable task artifacts; inventory retained.', call. = FALSE)
}
bind <- function(name) do.call(rbind, lapply(rows, `[[`, name))
selected <- bind('selected'); attempts <- bind('attempts'); profiles <- bind('profiles'); diagnostics <- bind('diagnostics'); provenance <- bind('provenance')
expected_parm <- targets$parm
strict <- nrow(selected) == 3500L && nrow(attempts) == 7000L && nrow(profiles) == 10500L && nrow(diagnostics) == 3500L &&
  all(table(attempts$id) == 2L) && all(table(profiles$id) == 3L) && setequal(unique(profiles$parm), expected_parm)
if (!strict) stop('G13 denominator or target structure is incomplete.', call. = FALSE)
keys <- c('source_commit', 'worker_md5', 'assessment_helper_md5', 'profile_engine', 'profile_precision', 'profile_level')
prov <- lapply(keys, function(k) unique(provenance$value[provenance$key == k])); names(prov) <- keys
if (any(vapply(prov, length, integer(1)) != 1L) || !grepl('^[0-9a-f]{40}$', prov$source_commit) ||
    !grepl('^[0-9a-f]{32}$', prov$worker_md5) || !identical(prov$profile_engine, 'tmbprofile') ||
    !identical(prov$profile_precision, 'fast') || !identical(prov$profile_level, '0.95')) stop('G13 provenance is malformed or mixed.', call. = FALSE)
profiles$task_id <- as.integer(sub('^G12_', '', profiles$id)); profiles <- merge(profiles, manifest[, c('task_id', 'cell')], by = 'task_id', all.x = TRUE, sort = FALSE)
selected$task_id <- as.integer(sub('^G12_', '', selected$id)); selected <- merge(selected, manifest[, c('task_id', 'cell')], by = 'task_id', all.x = TRUE, sort = FALSE)
truth_for <- setNames(targets$truth, targets$parm)
beta_for <- c('fixef:mu:(Intercept)' = 'beta_intercept', 'fixef:mu:between' = 'beta_between', 'fixef:mu:within' = 'beta_within')
summary <- do.call(rbind, lapply(seq_len(nrow(targets)), function(i) {
  target <- targets[i, ]; p <- profiles[profiles$cell == target$cell & profiles$parm == target$parm, , drop = FALSE]
  s <- selected[selected$cell == target$cell, , drop = FALSE]; est <- s[[beta_for[[target$parm]]]]
  avail <- p$available & is.finite(p$lower) & is.finite(p$upper); covered <- avail & p$lower <= target$truth & p$upper >= target$truth
  data.frame(cell = target$cell, parm = target$parm, n_attempted = nrow(p), n_available = sum(avail), availability = mean(avail),
    coverage_all = mean(covered), coverage_conditional = if (any(avail)) mean(covered[avail]) else NA_real_, coverage_mcse = sqrt(mean(covered) * (1 - mean(covered)) / nrow(p)),
    lower_tail_all = mean(avail & p$lower > target$truth), upper_tail_all = mean(avail & p$upper < target$truth),
    lower_tail_conditional = if (any(avail)) mean(p$lower[avail] > target$truth) else NA_real_, upper_tail_conditional = if (any(avail)) mean(p$upper[avail] < target$truth) else NA_real_,
    bias = mean(est - target$truth), empirical_sd = stats::sd(est), mean_interval_width = if (any(avail)) mean(p$upper[avail] - p$lower[avail]) else NA_real_,
    source_commit = prov$source_commit, worker_md5 = prov$worker_md5, stringsAsFactors = FALSE)
}))
assessed <- phylo_temporal_ou_g11_assess(summary)
utils::write.csv(inventory, file.path(out_dir, 'task-inventory.csv'), row.names = FALSE); utils::write.csv(summary, file.path(out_dir, 'summary.csv'), row.names = FALSE)
utils::write.csv(assessed, file.path(out_dir, 'assessment.csv'), row.names = FALSE)
writeLines(c('# G13 immutable campaign re-verification', '', sprintf('Archives inspected: %d.', nrow(inventory)), sprintf('Source commit: %s.', prov$source_commit),
  sprintf('Primary qualified rows: %d/9.', sum(assessed$qualification == 'qualified_in_simulated_cell')), 'No model fit was launched by this re-verifier.'), file.path(out_dir, 'RESULTS.md'))
cat('PHYLO_TEMPORAL_OU_G13_REVERIFY_PASS\n')
