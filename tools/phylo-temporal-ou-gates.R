#!/usr/bin/env Rscript

# Phase-0 gate runner. It is deliberately fail-closed until the corresponding
# model evidence and fixtures exist.
script <- sub('^--file=', '', grep('^--file=', commandArgs(FALSE), value = TRUE)[[1L]])
root <- normalizePath(file.path(dirname(script), '..'))
setwd(root)
plan <- file.path(root, 'docs/dev-log/plans/2026-09-09-phylo-temporal-ou/PLAN.md')
ledger <- file.path(root, 'docs/dev-log/plans/2026-09-09-phylo-temporal-ou/unlazy/GATES.md')
runner <- file.path(root, 'tools/phylo-temporal-ou-gates.R')

fail <- function(...) stop(..., call. = FALSE)
need_file <- function(path) if (!file.exists(path)) fail('Missing required file: ', path)
need_text <- function(path, patterns) {
  need_file(path)
  text <- paste(readLines(path, warn = FALSE), collapse = '\n')
  absent <- patterns[!vapply(patterns, grepl, logical(1), x = text,
                              fixed = TRUE, USE.NAMES = FALSE)]
  if (length(absent)) fail('Missing contract text: ', paste(absent, collapse = '; '))
}
approval <- function() {
  need_file(ledger)
  text <- readLines(ledger, warn = FALSE)
  at <- grep('^- \\[x\\] G0:', text)
  evidence <- if (length(at) == 1L && at < length(text)) text[[at + 1L]] else ''
  if (length(at) != 1L || !grepl('^  EVIDENCE: ', evidence) ||
      grepl('EVIDENCE: pending', evidence, fixed = TRUE)) {
    fail('G0 approval/source evidence is absent or pending.')
  }
}
validate_fixture <- function(path) {
  if (!file.exists(path)) fail('Missing required fixture: ', path)
  value <- readRDS(path)
  if (!is.list(value) || !identical(value$kind, 'phylo-temporal-ou-g1-fixture') ||
      !is.character(value$source) || !nzchar(value$source)) {
    fail('Invalid G1 fixture.')
  }
  invisible(value)
}
self_test <- function() {
  temp <- tempfile(fileext = '.rds')
  good <- list(kind = 'phylo-temporal-ou-g1-fixture', source = 'self-test')
  saveRDS(good, temp)
  validate_fixture(temp)
  unlink(temp)
  if (!inherits(try(validate_fixture(temp), silent = TRUE), 'try-error')) {
    fail('Missing-fixture negative control passed.')
  }
  cat('PHYLO_TEMPORAL_OU_RUNNER_SELFTEST_PASS controls=1\n')
}
run_oracle_tests <- function() {
  pkgload::load_all(root, quiet = TRUE)
  path <- file.path(root, 'tests/testthat/test-phylo-temporal-ou-dense-oracle.R')
  if (!file.exists(path)) fail('Missing independent dense-oracle test file.')
  results <- testthat::test_file(path, reporter = 'silent')
  expectations <- unlist(lapply(results, `[[`, 'results'), recursive = FALSE)
  bad <- vapply(expectations, function(x) {
    inherits(x, c('expectation_failure', 'expectation_error'))
  }, logical(1))
  if (any(bad)) fail('Independent dense-oracle test suite has failures.')
  invisible(NULL)
}

g3_to_g6 <- function(gate) {
  approval()
  run_oracle_tests()
  cat('PHYLO_TEMPORAL_OU_', gate, '_PASS\n', sep = '')
}

run_methods_tests <- function() {
  pkgload::load_all(root, quiet = TRUE)
  path <- file.path(root, 'tests/testthat/test-phylo-temporal-ou-methods.R')
  if (!file.exists(path)) fail('Missing paired phylo-temporal OU methods test file.')
  results <- testthat::test_file(path, reporter = 'silent')
  expectations <- unlist(lapply(results, `[[`, 'results'), recursive = FALSE)
  bad <- vapply(expectations, function(x) {
    inherits(x, c('expectation_failure', 'expectation_error'))
  }, logical(1))
  if (any(bad)) fail('Paired phylo-temporal OU methods test suite has failures.')
  invisible(NULL)
}

g7 <- function() {
  approval()
  run_methods_tests()
  cat('PHYLO_TEMPORAL_OU_G7_PASS\n')
}

run_profile_tests <- function() {
  pkgload::load_all(root, quiet = TRUE)
  path <- file.path(root, 'tests/testthat/test-phylo-temporal-ou-profile.R')
  if (!file.exists(path)) fail('Missing paired phylo-temporal OU profile test file.')
  results <- testthat::test_file(path, reporter = 'silent')
  expectations <- unlist(lapply(results, `[[`, 'results'), recursive = FALSE)
  bad <- vapply(expectations, function(x) {
    inherits(x, c('expectation_failure', 'expectation_error'))
  }, logical(1))
  if (any(bad)) fail('Paired phylo-temporal OU profile test suite has failures.')
  invisible(NULL)
}

g8 <- function() {
  approval()
  run_profile_tests()
  cat('PHYLO_TEMPORAL_OU_G8_PASS\n')
}

g14 <- function() {
  approval()
  article <- file.path(root, 'vignettes/phylogenetic-temporal-effects.Rmd')
  grammar <- file.path(root, 'docs/design/01-formula-grammar.md')
  likelihood <- file.path(root, 'docs/design/03-likelihoods.md')
  pkgdown <- file.path(root, '_pkgdown.yml')
  need_text(article, c(
    'Development status.',
    'phylogenetic--OU model',
    'not as an inference-qualified routine analysis',
    'phylo(1 | species, tree = tree)',
    'temporal(1 | species, time = elapsed_days, structure = "ou")',
    'The model is additive.',
    'A separable phylogeny-by-time field is a different future',
    'genuinely irregular elapsed times',
    'intercept-profile undercoverage in three primary cells',
    'interval-feasibility diagnostic'
  ))
  need_text(grammar, c(
    'Implemented paired interval-feasibility development slice',
    'retained 24-fixture point recovery missed',
    'intercept-profile undercoverage in three primary cells',
    'not inference-ready results'
  ))
  need_text(likelihood, c(
    'Phylogenetic stable intercept plus independent OU deviations',
    'This is additive, not the later separable field',
    'interval-feasibility diagnostics',
    'not inference-ready results'
  ))
  need_text(pkgdown, c(
    'Phylogenetic stable effects and OU deviations (development)',
    'articles/phylogenetic-temporal-effects.html'
  ))
  cat('PHYLO_TEMPORAL_OU_G14_PASS\n')
}

g9b <- function() {
  approval()
  d <- file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-09-phylo-temporal-ou-g9b-pilot-v2')
  criteria <- utils::read.csv(file.path(d, 'criteria.csv'), check.names = FALSE)
  provenance <- utils::read.csv(file.path(d, 'provenance.csv'), check.names = FALSE)
  if (nrow(criteria) != 4L || !all(criteria$pass) ||
      !any(provenance$key == 'runner_md5' & !is.na(provenance$value) & nzchar(provenance$value))) fail('G9b pilot artifacts are incomplete or lack provenance.')
  cat('PHYLO_TEMPORAL_OU_G9B_PILOT_PASS\n')
}

g9b_full <- function() {
  approval()
  d <- file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g9b-full-v5')
  criteria_path <- file.path(d, 'criteria.csv')
  provenance_path <- file.path(d, 'provenance.csv')
  manifest_path <- file.path(d, 'manifest.csv')
  for (path in c(criteria_path, provenance_path, manifest_path,
                 file.path(d, 'contrast-estimates.csv'), file.path(d, 'contrast-attempts.csv'),
                 file.path(d, 'ensemble-estimates.csv'), file.path(d, 'ensemble-attempts.csv'))) need_file(path)
  criteria <- utils::read.csv(criteria_path, check.names = FALSE)
  provenance <- utils::read.csv(provenance_path, check.names = FALSE)
  manifest <- utils::read.csv(manifest_path, check.names = FALSE)
  if (nrow(criteria) != 12L || !all(criteria$pass) ||
      sum(manifest$stream == 'contrast') != 24L || sum(manifest$stream == 'ensemble') != 300L ||
      !any(provenance$key == 'runner_md5' & !is.na(provenance$value) & nzchar(provenance$value))) {
    fail('G9b full-study artifacts are incomplete, failed, or lack provenance.')
  }
  cat('PHYLO_TEMPORAL_OU_G9B_FULL_PASS\n')
}

g9c <- function() {
  need_file(ledger)
  text <- readLines(ledger, warn = FALSE)
  at <- grep('^- \\[x\\] G9c:', text)
  evidence <- if (length(at) == 1L && at < length(text)) text[[at + 1L]] else ''
  if (length(at) != 1L || !grepl('^  EVIDENCE: ', evidence) ||
      !grepl('user approved G9c', evidence, fixed = TRUE)) {
    fail('G9c limited-pilot approval is absent.')
  }
}

g10 <- function() {
  approval()
  g9c()
  d <- file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g10-pilot-v2')
  required <- c('manifest.csv', 'selected-fits.csv', 'attempts.csv', 'profiles.csv', 'diagnostics.csv',
                'warnings.csv', 'progress.csv', 'criteria.csv', 'provenance.csv', 'g10-pilot-results.rds', 'session-info.txt', 'RESULTS.md')
  for (path in file.path(d, required)) need_file(path)
  manifest <- utils::read.csv(file.path(d, 'manifest.csv'), check.names = FALSE)
  selected <- utils::read.csv(file.path(d, 'selected-fits.csv'), check.names = FALSE)
  attempts <- utils::read.csv(file.path(d, 'attempts.csv'), check.names = FALSE)
  profiles <- utils::read.csv(file.path(d, 'profiles.csv'), check.names = FALSE)
  diagnostics <- utils::read.csv(file.path(d, 'diagnostics.csv'), check.names = FALSE)
  progress <- utils::read.csv(file.path(d, 'progress.csv'), check.names = FALSE)
  criteria <- utils::read.csv(file.path(d, 'criteria.csv'), check.names = FALSE)
  provenance <- utils::read.csv(file.path(d, 'provenance.csv'), check.names = FALSE)
  expected_cells <- c('P1', 'P2', 'P3', 'P4')
  expected_parm <- paste0('fixef:mu:', c('(Intercept)', 'between', 'within'))
  complete <- nrow(manifest) == 20L && identical(sort(unique(manifest$cell)), expected_cells) &&
    all(table(manifest$cell) == 5L) && length(unique(manifest$seed)) == 20L &&
    nrow(selected) == 20L && all(manifest$id %in% selected$id) &&
    nrow(attempts) == 40L && all(table(attempts$id) == 2L) && all(manifest$id %in% attempts$id) &&
    nrow(profiles) == 60L && all(table(profiles$id) == 3L) && all(manifest$id %in% profiles$id) &&
    setequal(unique(profiles$parm), expected_parm) && nrow(diagnostics) == 20L &&
    all(manifest$id %in% diagnostics$id) && nrow(progress) == 20L && all(manifest$id %in% progress$id) &&
    nrow(criteria) == 6L && all(criteria$pass) &&
    all(c('source_commit', 'runner_md5', 'profile_engine', 'profile_precision', 'profile_level') %in% provenance$key) &&
    identical(provenance$value[provenance$key == 'profile_engine'], 'tmbprofile') &&
    identical(provenance$value[provenance$key == 'profile_precision'], 'fast') &&
    identical(provenance$value[provenance$key == 'profile_level'], '0.95')
  if (!complete) fail('G10 pilot artifacts are incomplete, malformed, or lack complete denominators.')
  cat('PHYLO_TEMPORAL_OU_G10_PASS\n')
}

g11 <- function() {
  approval()
  g10()
  d <- file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g11-corrected-target-contract')
  required <- c('manifest.csv', 'targets.csv', 'known-failing-coverage.csv', 'provenance.csv', 'RESULTS.md')
  for (path in file.path(d, required)) need_file(path)
  helper <- file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R')
  worker <- file.path(root, 'tools', 'run-phylo-temporal-ou-g11-contract.R')
  need_file(helper); need_file(worker)
  source(helper, local = environment())
  manifest <- utils::read.csv(file.path(d, 'manifest.csv'), stringsAsFactors = FALSE)
  targets <- utils::read.csv(file.path(d, 'targets.csv'), stringsAsFactors = FALSE)
  failing <- utils::read.csv(file.path(d, 'known-failing-coverage.csv'), stringsAsFactors = FALSE)
  provenance <- utils::read.csv(file.path(d, 'provenance.csv'), stringsAsFactors = FALSE)
  phylo_temporal_ou_g11_validate_manifest(manifest)
  expected_targets <- phylo_temporal_ou_g11_targets()
  if (!identical(targets, expected_targets) || nrow(failing) != 1L ||
      !identical(failing$cell[[1L]], 'P1') || !identical(failing$parm[[1L]], 'fixef:mu:(Intercept)') ||
      !isTRUE(all.equal(failing$coverage_all[[1L]], 0.90))) {
    fail('G11 target or known-failing fixture is malformed.')
  }
  value <- function(key) provenance$value[provenance$key == key]
  if (length(value('source_commit')) != 1L || !grepl('^[0-9a-f]{40}$', value('source_commit')) ||
      !identical(value('contract_worker_md5'), unname(tools::md5sum(worker))) ||
      !identical(value('assessment_helper_md5'), unname(tools::md5sum(helper))) ||
      !identical(value('campaign_datasets'), '3500') || !identical(value('primary_datasets'), '3000') ||
      !identical(value('stress_datasets'), '500') || !identical(value('profile_level'), '0.95')) {
    fail('G11 contract provenance is incomplete or forged.')
  }
  output <- system2('Rscript', c('--vanilla', worker, '--self-test'), stdout = TRUE, stderr = TRUE)
  if (!is.null(attr(output, 'status')) || !any(grepl('PHYLO_TEMPORAL_OU_G11_CONTRACT_SELFTEST_PASS', output, fixed = TRUE))) {
    fail('G11 contract worker self-test failed.')
  }
  test_path <- file.path(root, 'tests/testthat/test-phylo-temporal-ou-g11.R')
  results <- testthat::test_file(test_path, reporter = 'silent')
  expectations <- unlist(lapply(results, `[[`, 'results'), recursive = FALSE)
  bad <- vapply(expectations, function(x) inherits(x, c('expectation_failure', 'expectation_error')), logical(1))
  if (any(bad)) fail('G11 assessment tests failed.')
  cat('PHYLO_TEMPORAL_OU_G11_PASS\n')
}

g13 <- function() {
  approval()
  d <- file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g13-truthfix')
  required <- c('RECEIPT.md', 'RESULTS.md', 'task-inventory.csv', 'summary.csv', 'assessment.csv', 'slurm-provenance.txt')
  for (path in file.path(d, required)) need_file(path)
  need_text(file.path(d, 'RECEIPT.md'), c(
    'The Rorqual re-verifier consumed the 3,500 sealed G12 task archives',
    'It did not load `drmTMB` or launch a model fit.',
    'Totoro independently reran the same no-refit verifier'
  ))
  source(file.path(root, 'tools', 'assess-phylo-temporal-ou-g11.R'), local = environment())
  inventory <- utils::read.csv(file.path(d, 'task-inventory.csv'), stringsAsFactors = FALSE)
  summary <- utils::read.csv(file.path(d, 'summary.csv'), stringsAsFactors = FALSE, check.names = FALSE)
  retained <- utils::read.csv(file.path(d, 'assessment.csv'), stringsAsFactors = FALSE, check.names = FALSE)
  if (nrow(inventory) != 3500L || !all(inventory$complete) ||
      nrow(summary) != 12L || nrow(retained) != 12L) {
    fail('G13 retained output has an incomplete immutable denominator.')
  }
  assessed <- phylo_temporal_ou_g11_assess(summary)
  checked <- c('cell', 'parm', 'qualification', 'criterion_availability', 'criterion_coverage',
               'criterion_bias', 'criterion_profile_se')
  if (!identical(retained[, checked], assessed[, checked])) {
    fail('G13 retained assessment does not reproduce from its immutable summary.')
  }
  primary <- assessed$primary
  if (!all(assessed$qualification[primary] == 'qualified_in_simulated_cell')) {
    failed <- paste(assessed$cell[primary & assessed$qualification != 'qualified_in_simulated_cell'],
                    assessed$parm[primary & assessed$qualification != 'qualified_in_simulated_cell'], sep = '/')
    fail('G13 primary calibration criteria are unmet: ', paste(failed, collapse = ', '))
  }
  cat('PHYLO_TEMPORAL_OU_G13_PASS\n')
}

g15 <- function() {
  approval()
  article <- file.path(root, 'vignettes/phylogenetic-temporal-effects.Rmd')
  need_text(article, c(
    'genuinely irregular elapsed times',
    'elapsed_values <- c(0, 0.5, 2.5, 5)',
    'phylo(1 | species, tree = tree)',
    'temporal(1 | species, time = elapsed_days, structure = "ou")',
    'interval-feasibility diagnostic',
    'not a reportable'
  ))
  if (!requireNamespace('rmarkdown', quietly = TRUE)) {
    fail('G15 requires rmarkdown to render the reader workflow.')
  }
  pkgload::load_all(root, quiet = TRUE)
  render_dir <- file.path(tempdir(), 'phylo-temporal-ou-g15-render')
  dir.create(render_dir, recursive = TRUE, showWarnings = FALSE)
  rendered <- rmarkdown::render(
    article,
    output_dir = render_dir,
    intermediates_dir = render_dir,
    envir = globalenv(),
    quiet = TRUE
  )
  if (!file.exists(rendered)) {
    fail('G15 render did not produce an HTML article.')
  }
  need_text(rendered, c(
    'Phylogenetic stable effects and temporal OU deviations',
    'Development status.',
    'genuinely irregular elapsed times',
    'inference-qualified routine analysis'
  ))
  cat('PHYLO_TEMPORAL_OU_G15_PASS\n')
}

g16 <- function() {
  approval()
  d <- file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-11-phylo-temporal-ou-closeout')
  receipt <- file.path(d, 'package-check-receipt.txt')
  log <- file.path(d, 'package-check.log')
  need_text(receipt, 'P1_G16_SOURCE_CHECK_STATUS=0')
  need_text(log, c('* checking for file', '* checking tests ...', 'Running ‘testthat.R’', 'Status: OK'))
  cat('PHYLO_TEMPORAL_OU_G16_PASS\n')
}

g17 <- function() {
  approval()
  report <- file.path(root, 'docs/dev-log/after-task/2026-09-11-phylo-temporal-ou-closeout.md')
  need_text(report, c(
    'Noether found',
    'Pat found',
    'interval-feasibility diagnostics',
    'not reportable as inference-ready'
  ))
  cat('PHYLO_TEMPORAL_OU_G17_PASS\n')
}

g18 <- function() {
  approval()
  g16(); g17(); g14(); g15()
  completed <- c('G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'G7', 'G8', 'G9b', 'G9b-full', 'G9c', 'G10', 'G11', 'G12', 'G14', 'G15', 'G16', 'G17')
  need_text(ledger, paste0('- [x] ', completed, ':'))
  need_text(ledger, c('- [ ] G9:', '- [ ] G13:', 'G13 is unmet; no later temporal structure may begin'))
  output <- suppressWarnings(system2('Rscript', c('--vanilla', runner, 'G13', '--reverify'), stdout = TRUE, stderr = TRUE))
  if (is.null(attr(output, 'status')) ||
      !any(grepl('G13 primary calibration criteria are unmet:', output, fixed = TRUE)) ||
      !any(grepl('P1/fixef:mu:(Intercept)', output, fixed = TRUE)) ||
      !any(grepl('P2/fixef:mu:(Intercept)', output, fixed = TRUE)) ||
      !any(grepl('P3/fixef:mu:(Intercept)', output, fixed = TRUE))) {
    fail('G18 expected the retained red G13 calibration verdict.')
  }
  cat('PHYLO_TEMPORAL_OU_G18_INTERVAL_FEASIBILITY_PASS\n')
}

g2_worker <- function() {
  pkgload::load_all(root, quiet = TRUE)
  set.seed(202609091L)
  tree <- ape::rcoal(4L)
  tree$tip.label <- paste0('sp', seq_len(ape::Ntip(tree)))
  data <- expand.grid(species = tree$tip.label, elapsed = c(0, 1, 3, 6),
                      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  data$x <- stats::rnorm(nrow(data))
  data$y <- 0.2 + 0.4 * data$x + stats::rnorm(nrow(data), sd = 0.4)
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + drmTMB::phylo(1 | species, tree = tree) +
                 drmTMB::temporal(1 | species, time = elapsed, structure = 'ou'),
               sigma ~ 1),
    data = data[sample.int(nrow(data)), , drop = FALSE], family = stats::gaussian(), REML = FALSE
  )
  temporal <- fit$model$structured$temporal_mu
  if (!isTRUE(fit$model$structured$phylo_mu$has) || !isTRUE(temporal$paired_phylo_stable) ||
      !identical(temporal$group, 'species') || !identical(temporal$minimum_distinct_lags, 3L)) {
    fail('Paired phylo-plus-OU layout is incomplete.')
  }
  bad <- try(drmTMB::drmTMB(
    drmTMB::bf(y ~ drmTMB::phylo(1 | species, tree = tree) +
                 drmTMB::temporal(1 | other, time = elapsed, structure = 'ou'), sigma ~ 1),
    data = transform(data, other = species), family = stats::gaussian(), REML = FALSE
  ), silent = TRUE)
  if (!inherits(bad, 'try-error')) fail('Mismatched phylo/temporal IDs were accepted.')
  cat('PHYLO_TEMPORAL_OU_G2_WORKER_PASS\n')
}

g2 <- function() {
  approval()
  output <- system2('Rscript', c('--vanilla', runner, '--g2-worker'), stdout = TRUE, stderr = TRUE)
  if (!is.null(attr(output, 'status')) ||
      !any(grepl('PHYLO_TEMPORAL_OU_G2_WORKER_PASS', output, fixed = TRUE))) {
    fail('P1 paired parser/layout worker failed.')
  }
  cat('PHYLO_TEMPORAL_OU_G2_PASS\n')
}

g1 <- function() {
  approval()
  need_text(plan, c('stable phylogenetic intercept plus independent OU',
                    'deliberately **not** the separable field'))
  invoked <- sub('^--file=', '', grep('^--file=', commandArgs(FALSE), value = TRUE)[[1L]])
  if (!identical(normalizePath(runner), normalizePath(invoked))) {
    fail('Runner was not invoked from its canonical path.')
  }
  fixture <- tempfile(fileext = '.rds')
  saveRDS(list(kind = 'phylo-temporal-ou-g1-fixture',
               source = system2('git', c('rev-parse', 'HEAD'), stdout = TRUE)), fixture)
  validate_fixture(fixture)
  unlink(fixture)
  if (!inherits(try(validate_fixture(fixture), silent = TRUE), 'try-error')) {
    fail('G1 missing-fixture negative control passed.')
  }
  cat('PHYLO_TEMPORAL_OU_G1_PASS\n')
}
args <- commandArgs(trailingOnly = TRUE)
if (identical(args, '--self-test')) {
  self_test()
} else if (identical(args, 'G1')) {
  g1()
} else if (identical(args, 'G2')) {
  g2()
} else if (identical(args, '--g2-worker')) {
  g2_worker()
} else if (length(args) == 1L && args %in% c('G3', 'G4', 'G5', 'G6')) {
  g3_to_g6(args)
} else if (identical(args, 'G7')) {
  g7()
} else if (identical(args, 'G8')) {
  g8()
} else if (identical(args, 'G9b')) {
  g9b()
} else if (identical(args, 'G9b-full')) {
  g9b_full()
} else if (identical(args, 'G10')) {
  g10()
} else if (identical(args, 'G11')) {
  g11()
} else if (identical(args, c('G13', '--reverify'))) {
  g13()
} else if (identical(args, 'G14')) {
  g14()
} else if (identical(args, 'G15')) {
  g15()
} else if (identical(args, 'G16')) {
  g16()
} else if (identical(args, 'G17')) {
  g17()
} else if (identical(args, c('G18', '--reverify'))) {
  g18()
} else {
  fail('Use --self-test, G1 through G8, G10, G11, G13 --reverify, G14 through G17, or G18 --reverify; other model gates remain unavailable.')
}
