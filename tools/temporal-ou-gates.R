#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || length(args) > 2L || !grepl('^G([1-9]|1[0-6])$', args[[1L]])) {
  stop('Usage: Rscript --vanilla tools/temporal-ou-gates.R G<number> [--reverify]', call. = FALSE)
}
gate <- args[[1L]]
reverify <- length(args) == 2L && identical(args[[2L]], '--reverify')
if (length(args) == 2L && !reverify) {
  stop('The only optional argument is --reverify.', call. = FALSE)
}
pass <- function() { cat(sprintf('TEMPORAL_OU_%s_PASS\n', gate)); flush.console() }
fail <- function(message) stop(message, call. = FALSE)
run_file <- function(path) {
  cat(''); flush.console()
  pkgload::load_all('.', compile = TRUE, quiet = TRUE)
  result <- testthat::test_file(path, reporter = 'silent')
  expectations <- unlist(lapply(result, `[[`, 'results'), recursive = FALSE)
  bad <- vapply(expectations, inherits, logical(1L), what = c('expectation_failure', 'expectation_error'))
  if (any(bad)) fail(sprintf('%s failed: %d expectation failure/error result(s).', path, sum(bad)))
}

success <- FALSE
if (identical(gate, 'G1')) {
  files <- file.path('docs/dev-log/simulation-artifacts/2026-09-08-temporal-ar1-calibration-pilot', c('RESULTS.md', 'C1-SEED-2026091002-DIAGNOSIS.md'))
  current_recheck <- 'docs/dev-log/simulation-artifacts/2026-09-09-temporal-ar1-c1-current-source-recheck'
  fresh_replication <- 'docs/dev-log/simulation-artifacts/2026-09-09-temporal-ar1-c1-wald-replication'
  current_boundary <- 'docs/dev-log/simulation-artifacts/2026-09-09-temporal-ar1-c1-current-boundary'
  current_files <- c(
    file.path(current_recheck, c('replications.csv', 'raw-attempts.csv', 'provenance.csv')),
    file.path(fresh_replication, c('replications.csv', 'raw-attempts.csv', 'provenance.csv')),
    file.path(current_boundary, c('profile-summary.csv', 'free-attempts.csv', 'provenance.csv')),
    'docs/dev-log/plans/2026-09-08-temporal-ou/c1-current-source-reconciliation-2026-09-09.md'
  )
  if (!all(file.exists(c(files, current_files)))) fail('G1 cannot find the retained AR1 C1 diagnostic evidence.')
  text <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = '\n')
  guard <- paste(readLines('R/temporal.R', warn = FALSE), collapse = '\n')
  if (!grepl('residual SD approximately', text, fixed = TRUE) || !grepl('OU mean-coefficient Wald intervals are not yet qualified', guard, fixed = TRUE)) fail('G1 requires the retained C1 diagnosis and the public OU interval guard.')
  recheck <- read.csv(file.path(current_recheck, 'replications.csv'), stringsAsFactors = FALSE)
  fresh <- read.csv(file.path(fresh_replication, 'replications.csv'), stringsAsFactors = FALSE)
  profile <- read.csv(file.path(current_boundary, 'profile-summary.csv'), stringsAsFactors = FALSE)
  free <- read.csv(file.path(current_boundary, 'free-attempts.csv'), stringsAsFactors = FALSE)
  verify_provenance <- function(directory, runner) {
    provenance <- read.csv(file.path(directory, 'provenance.csv'), stringsAsFactors = FALSE)
    source_commit <- provenance$value[provenance$key == 'source_commit']
    runner_hash <- provenance$value[provenance$key == 'runner_md5']
    length(source_commit) == 1L && length(runner_hash) == 1L &&
      system2('git', c('cat-file', '-e', paste0(source_commit, '^{commit}'))) == 0L &&
      identical(runner_hash, unname(tools::md5sum(runner)))
  }
  if (nrow(recheck) != 5L || !all(recheck$selected & recheck$pd_hessian & recheck$vcov_available & recheck$interval_available) ||
      nrow(fresh) != 5L || sum(fresh$interval_available) != 4L ||
      !any(!fresh$interval_available & fresh$sigma < 0.001) ||
      nrow(profile) != 10L || nrow(free) != 4L ||
      profile$objective[profile$sigma_fixed == 0.1][[1L]] - min(profile$objective) < 0.005 ||
      any(free$sigma >= 0.001) ||
      !verify_provenance(current_recheck, 'tools/diagnose-temporal-ar1-c1-current-source-recheck.R') ||
      !verify_provenance(fresh_replication, 'tools/diagnose-temporal-ar1-c1-wald-replication.R') ||
      !verify_provenance(current_boundary, 'tools/diagnose-temporal-ar1-c1-current-boundary.R')) {
    fail('G1 current-source C1 reconciliation evidence does not reproduce the historical repair and fresh boundary case.')
  }
  success <- TRUE
} else if (identical(gate, 'G2')) {
  run_file('tests/testthat/test-temporal-ou.R'); success <- TRUE
} else if (identical(gate, 'G3')) {
  run_file('tests/testthat/test-temporal-ou-dense-oracle.R'); success <- TRUE
} else if (identical(gate, 'G4')) {
  native <- paste(readLines('src/drmTMB.cpp', warn = FALSE), collapse = '\n')
  needed <- c('dnorm(u_temporal(first)', 'temporal_mu_elapsed_gap', 'temporal_mu_series_start')
  if (!all(vapply(needed, grepl, logical(1L), x = native, fixed = TRUE))) fail('G4 native OU transition ingredients are missing.')
  run_file('tests/testthat/test-temporal-ou-dense-oracle.R'); success <- TRUE
} else if (identical(gate, 'G5')) {
  run_file('tests/testthat/test-temporal-ou-dense-oracle.R'); success <- TRUE
} else if (identical(gate, 'G6')) {
  run_file('tests/testthat/test-temporal-ou.R'); success <- TRUE
} else if (identical(gate, 'G7')) {
  profile_source <- paste(readLines('R/profile.R', warn = FALSE), collapse = '\n')
  temporal_source <- paste(readLines('R/temporal.R', warn = FALSE), collapse = '\n')
  check_source <- paste(readLines('R/check.R', warn = FALSE), collapse = '\n')
  needed <- c(
    'validate_temporal_profile_parm',
    'restrict_temporal_profile_targets',
    'warn_temporal_profile_hessian',
    'temporal_mean_profile'
  )
  present <- c(
    grepl(needed[[1L]], temporal_source, fixed = TRUE),
    grepl(needed[[2L]], profile_source, fixed = TRUE),
    grepl(needed[[3L]], profile_source, fixed = TRUE),
    grepl(needed[[4L]], check_source, fixed = TRUE)
  )
  if (!all(present)) fail('G7 temporal fixed-effect profile interface or irregular-Hessian diagnostic is absent.')
  run_file('tests/testthat/test-temporal-ou.R')
  run_file('tests/testthat/test-temporal-ou-dense-oracle.R')
  success <- TRUE
} else if (identical(gate, 'G8')) {
  out_dir <- 'docs/dev-log/simulation-artifacts/2026-09-09-temporal-ou-local-recovery'
  required <- file.path(out_dir, c(
    'raw-attempts.csv', 'recovery-estimates.csv', 'criteria.csv',
    'provenance.csv', 'recovery-results.rds', 'session-info.txt', 'RESULTS.md'
  ))
  if (!all(file.exists(required))) fail('G8 requires retained OU recovery outputs.')
  criteria <- read.csv(file.path(out_dir, 'criteria.csv'), stringsAsFactors = FALSE)
  attempts <- read.csv(file.path(out_dir, 'raw-attempts.csv'), stringsAsFactors = FALSE)
  provenance <- read.csv(file.path(out_dir, 'provenance.csv'), stringsAsFactors = FALSE)
  runner_hash <- unname(tools::md5sum('tools/run-temporal-ou-recovery.R'))
  source_commit <- provenance$value[provenance$key == 'source_commit']
  if (length(source_commit) != 1L || system2('git', c('cat-file', '-e', paste0(source_commit, '^{commit}'))) != 0L) fail('G8 recovery provenance does not name a valid source commit.')
  if (!identical(provenance$value[provenance$key == 'runner_md5'], runner_hash)) fail('G8 recovery runner hash does not match the retained source.')
  if (!all(c('convergence', 'warning', 'error') %in% names(attempts)) || !all(criteria$pass) || nrow(attempts) != 24L || any(table(attempts$fixture) != 2L) || any(!is.finite(attempts$decay_start) | attempts$decay_start <= 0)) fail('G8 retained OU recovery criteria or start records are incomplete.')
  success <- TRUE
} else if (identical(gate, 'G9')) {
  out_dir <- 'docs/dev-log/simulation-artifacts/2026-09-09-temporal-ou-pilot'
  required <- file.path(out_dir, c(
    'raw-attempts.csv', 'pilot-results.csv', 'pilot-summary.csv',
    'provenance.csv', 'pilot-results.rds', 'session-info.txt', 'RESULTS.md',
    'resource-replay.txt'
  ))
  if (!all(file.exists(required))) fail('G9 requires retained OU pilot and resource outputs.')
  results <- read.csv(file.path(out_dir, 'pilot-results.csv'), stringsAsFactors = FALSE)
  attempts <- read.csv(file.path(out_dir, 'raw-attempts.csv'), stringsAsFactors = FALSE)
  provenance <- read.csv(file.path(out_dir, 'provenance.csv'), stringsAsFactors = FALSE)
  runner_hash <- unname(tools::md5sum('tools/run-temporal-ou-pilot.R'))
  source_commit <- provenance$value[provenance$key == 'source_commit']
  resource <- paste(readLines(file.path(out_dir, 'resource-replay.txt'), warn = FALSE), collapse = '\n')
  if (length(source_commit) != 1L || system2('git', c('cat-file', '-e', paste0(source_commit, '^{commit}'))) != 0L) fail('G9 pilot provenance does not name a valid source commit.')
  if (!identical(provenance$value[provenance$key == 'runner_md5'], runner_hash)) fail('G9 pilot runner hash does not match the retained source.')
  if (!all(c('pd_hessian', 'n_intervals', 'interval_available', 'interval_status', 'warning', 'error') %in% names(results)) || nrow(results) != 15L || nrow(attempts) != 30L || any(table(attempts$fixture) != 2L) || !all(results$selected & is.finite(results$objective)) || !all(is.finite(results$elapsed_sec) & results$elapsed_sec > 0) || !grepl('maximum resident set size', resource, fixed = TRUE)) fail('G9 retained OU pilot outputs are incomplete.')
  success <- TRUE
} else if (identical(gate, 'G10')) {
  source <- paste(readLines('vignettes/temporal-random-effects.Rmd', warn = FALSE), collapse = '\n')
  needed <- c('Irregular elapsed time with OU', 'positive decay rate', 'duplicate site--time records', 'method = "profile"', 'check_drm(ou_fit)')
  if (!all(vapply(needed, grepl, logical(1L), x = source, fixed = TRUE))) fail('G10 temporal OU reader guidance is incomplete.')
  success <- TRUE
} else if (identical(gate, 'G11')) {
  pkgload::load_all('.', compile = TRUE, quiet = TRUE)
  output_dir <- tempfile('temporal-ou-render-'); dir.create(output_dir)
  rendered <- rmarkdown::render('vignettes/temporal-random-effects.Rmd', output_dir = output_dir, quiet = TRUE)
  if (!file.exists(rendered)) fail('G11 did not create the temporal tutorial HTML.')
  html <- paste(readLines(rendered, warn = FALSE), collapse = '\n')
  if (!grepl('Irregular elapsed time with OU', html, fixed = TRUE)) fail('G11 rendered tutorial omits the OU section.')
  success <- TRUE
} else if (identical(gate, 'G12')) {
  build_status <- system2('R', c('--vanilla', 'CMD', 'build', '.'), stdout = '', stderr = '')
  if (!identical(build_status, 0L)) fail('G12 package build failed.')
  archive <- 'drmTMB_0.7.1.tar.gz'
  if (!file.exists(archive)) fail('G12 build did not create the source archive.')
  check_status <- system2('R', c('CMD', 'check', '--no-manual', archive), stdout = '', stderr = '')
  if (!identical(check_status, 0L)) fail('G12 package check failed.')
  success <- TRUE
} else if (identical(gate, 'G16')) {
  out_dir <- 'docs/dev-log/simulation-artifacts/2026-09-09-temporal-ou-profile-pilot'
  required <- file.path(out_dir, c(
    'raw-attempts.csv', 'profile-pilot-results.csv', 'profile-pilot-summary.csv',
    'provenance.csv', 'profile-pilot-results.rds', 'session-info.txt',
    'RESULTS.md', 'resource-replay.txt'
  ))
  if (!all(file.exists(required))) fail('G16 requires retained temporal OU profile-pilot outputs.')
  results <- read.csv(file.path(out_dir, 'profile-pilot-results.csv'), stringsAsFactors = FALSE)
  attempts <- read.csv(file.path(out_dir, 'raw-attempts.csv'), stringsAsFactors = FALSE)
  provenance <- read.csv(file.path(out_dir, 'provenance.csv'), stringsAsFactors = FALSE)
  runner_hash <- unname(tools::md5sum('tools/run-temporal-ou-profile-pilot.R'))
  source_commit <- provenance$value[provenance$key == 'source_commit']
  resource <- paste(readLines(file.path(out_dir, 'resource-replay.txt'), warn = FALSE), collapse = '\n')
  required_columns <- c(
    'fit_elapsed_sec', 'profile_elapsed_sec', 'pd_hessian',
    'profile_hessian_status', 'n_intervals', 'interval_available',
    'interval_status', 'warning', 'error'
  )
  if (length(source_commit) != 1L ||
      system2('git', c('cat-file', '-e', paste0(source_commit, '^{commit}'))) != 0L ||
      !identical(provenance$value[provenance$key == 'runner_md5'], runner_hash) ||
      !all(required_columns %in% names(results)) ||
      nrow(results) != 15L || nrow(attempts) != 30L ||
      any(table(attempts$fixture) != 2L) ||
      !all(results$selected & is.finite(results$objective)) ||
      !all(is.finite(results$fit_elapsed_sec) & results$fit_elapsed_sec > 0) ||
      !all(is.finite(results$profile_elapsed_sec) & results$profile_elapsed_sec > 0) ||
      any(is.na(results$profile_hessian_status) | !nzchar(results$profile_hessian_status)) ||
      any(is.na(results$interval_status) | !nzchar(results$interval_status)) ||
      any(!is.na(results$error) & nzchar(results$error)) ||
      !grepl('maximum resident set size', resource, fixed = TRUE)) {
    fail('G16 profile-pilot completeness, provenance, or resource evidence is incomplete.')
  }
  success <- TRUE
} else if (identical(gate, 'G15') && reverify) {
  fail('G15 requires authorized, retained OU campaign outputs; reverify never launches a campaign.')
} else {
  fail(sprintf('%s has no executable evidence yet; the gate remains pending.', gate))
}
if (success) pass()
