#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || length(args) > 2L || !grepl('^G([1-9]|1[0-5])$', args[[1L]])) {
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
  if (!all(file.exists(files))) fail('G1 cannot find the retained AR1 C1 diagnostic evidence.')
  text <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = '\n')
  guard <- paste(readLines('R/temporal.R', warn = FALSE), collapse = '\n')
  if (!grepl('residual SD approximately', text, fixed = TRUE) || !grepl('OU mean-coefficient Wald intervals are not yet qualified', guard, fixed = TRUE)) fail('G1 requires the retained C1 diagnosis and the public OU interval guard.')
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
  if (!all(criteria$pass) || nrow(attempts) != 24L || any(table(attempts$fixture) != 2L) || any(!is.finite(attempts$decay_start) | attempts$decay_start <= 0)) fail('G8 retained OU recovery criteria or start records are incomplete.')
  success <- TRUE
} else if (identical(gate, 'G10')) {
  source <- paste(readLines('vignettes/temporal-random-effects.Rmd', warn = FALSE), collapse = '\n')
  needed <- c('Irregular elapsed time with OU', 'positive decay rate', 'duplicate site--time records')
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
} else if (identical(gate, 'G15') && reverify) {
  fail('G15 requires authorized, retained OU campaign outputs; reverify never launches a campaign.')
} else {
  fail(sprintf('%s has no executable evidence yet; the gate remains pending.', gate))
}
if (success) pass()
