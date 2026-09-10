#!/usr/bin/env Rscript
# Writes or self-tests the frozen G11 calibration contract. It never fits data.
args <- commandArgs(trailingOnly = TRUE)
script_arg <- grep('^--file=', commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop('Run this script through Rscript.', call. = FALSE)
script_path <- normalizePath(sub('^--file=', '', script_arg))
root <- normalizePath('.', mustWork = TRUE)
if (!file.exists(file.path(root, 'DESCRIPTION'))) stop('Run from the drmTMB root.', call. = FALSE)
source(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))

out_dir <- Sys.getenv('DRMTMB_PHYLO_TEMPORAL_OU_G11_OUT', unset = file.path(
  root, 'docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g11-contract'
))
self_test <- function() {
  manifest <- phylo_temporal_ou_g11_manifest()
  phylo_temporal_ou_g11_validate_manifest(manifest)
  if (!inherits(try(phylo_temporal_ou_g11_validate_manifest(manifest[-1L, , drop = FALSE]), silent = TRUE), 'try-error')) {
    stop('Incomplete-denominator negative control passed.', call. = FALSE)
  }
  reference <- do.call(rbind, lapply(c('P1', 'P2', 'P3', 'P4'), function(cell) {
    n <- if (identical(cell, 'P4')) 500L else 1000L
    data.frame(cell = cell, parm = paste0('fixef:mu:', c('(Intercept)', 'between', 'within')),
      n_attempted = n, n_available = n, availability = 1, coverage_all = 0.95,
      coverage_conditional = 0.95, coverage_mcse = sqrt(.95 * .05 / n),
      lower_tail_all = .025, upper_tail_all = .025, lower_tail_conditional = .025, upper_tail_conditional = .025,
      bias = .02, empirical_sd = 1, mean_interval_width = 2 * stats::qnorm(.975),
      source_commit = paste(rep('a', 40L), collapse = ''), worker_md5 = paste(rep('b', 32L), collapse = ''),
      stringsAsFactors = FALSE)
  }))
  phylo_temporal_ou_g11_assess(reference)
  forged <- reference; forged$worker_md5[[1L]] <- 'forged'
  if (!inherits(try(phylo_temporal_ou_g11_assess(forged), silent = TRUE), 'try-error')) {
    stop('Forged-provenance negative control passed.', call. = FALSE)
  }
  failing <- reference; failing$coverage_all[[1L]] <- .90; failing$coverage_mcse[[1L]] <- sqrt(.90 * .10 / 1000)
  if (phylo_temporal_ou_g11_assess(failing)$qualification[[1L]] != 'unqualified_in_simulated_cell') {
    stop('Known failing-coverage control was not retained.', call. = FALSE)
  }
  cat('PHYLO_TEMPORAL_OU_G11_CONTRACT_SELFTEST_PASS\n')
}
if (identical(args, '--self-test')) {
  self_test()
  quit(save = 'no', status = 0L)
}
if (length(args)) stop('Use --self-test or no arguments to write the frozen contract.', call. = FALSE)
required <- c('manifest.csv', 'targets.csv', 'known-failing-coverage.csv', 'provenance.csv', 'RESULTS.md')
if (any(file.exists(file.path(out_dir, required)))) stop('G11 contract artifacts already exist; do not overwrite.', call. = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
manifest <- phylo_temporal_ou_g11_manifest(); targets <- phylo_temporal_ou_g11_targets()
known_failing <- data.frame(cell = 'P1', parm = 'fixef:mu:(Intercept)', coverage_all = .90,
                            coverage_mcse = sqrt(.90 * .10 / 1000), expected_qualification = 'unqualified_in_simulated_cell')
provenance <- data.frame(key = c('source_commit', 'contract_worker_md5', 'assessment_helper_md5', 'run_utc', 'campaign_datasets', 'primary_datasets', 'stress_datasets', 'profile_level'),
  value = c(system2('git', c('rev-parse', 'HEAD'), stdout = TRUE), unname(tools::md5sum(script_path)),
            unname(tools::md5sum(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'))), format(Sys.time(), tz = 'UTC', usetz = TRUE),
            3500L, 3000L, 500L, '0.95'), stringsAsFactors = FALSE)
utils::write.csv(manifest, file.path(out_dir, 'manifest.csv'), row.names = FALSE)
utils::write.csv(targets, file.path(out_dir, 'targets.csv'), row.names = FALSE)
utils::write.csv(known_failing, file.path(out_dir, 'known-failing-coverage.csv'), row.names = FALSE)
utils::write.csv(provenance, file.path(out_dir, 'provenance.csv'), row.names = FALSE)
writeLines(c('# G11 profile-calibration contract', '', 'P1--P3: 1,000 data sets each; P4 stress: 500.',
  'Each data set profiles intercept, between-species, and within-species fixed mean effects.',
  'All-attempt coverage counts unavailable endpoints as uncovered; conditional coverage is reported separately.',
  'Primary qualification: availability >= 0.99; coverage +/- MCSE within 0.925--0.975; |bias| <= 0.10 empirical SD; profile-SE analogue ratio in [0.90, 1.10].',
  'P4 is stress report only. This contract is not campaign authority.'), file.path(out_dir, 'RESULTS.md'))
cat('PHYLO_TEMPORAL_OU_G11_CONTRACT_WRITE_PASS\n')
