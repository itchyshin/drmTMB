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
    'do not use `confint()`'
  ))
  need_text(grammar, c(
    'Implemented paired point-fit development slice',
    'retained 24-fixture point recovery missed',
    'not an inference-qualified interval workflow'
  ))
  need_text(likelihood, c(
    'Phylogenetic stable intercept plus independent OU deviations',
    'This is additive, not the later separable field',
    'point-fit development route'
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
  d <- file.path(root, 'docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g9b-full-v2')
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

g15 <- function() {
  approval()
  article <- file.path(root, 'vignettes/phylogenetic-temporal-effects.Rmd')
  need_text(article, c(
    'genuinely irregular elapsed times',
    'elapsed_values <- c(0, 0.5, 2.5, 5)',
    'phylo(1 | species, tree = tree)',
    'temporal(1 | species, time = elapsed_days, structure = "ou")',
    'do not use `confint()`'
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
} else if (args %in% c('G3', 'G4', 'G5', 'G6')) {
  g3_to_g6(args)
} else if (identical(args, 'G7')) {
  g7()
} else if (identical(args, 'G8')) {
  g8()
} else if (identical(args, 'G9b')) {
  g9b()
} else if (identical(args, 'G9b-full')) {
  g9b_full()
} else if (identical(args, 'G14')) {
  g14()
} else if (identical(args, 'G15')) {
  g15()
} else {
  fail('Use --self-test, G1 through G8, G14, or G15; other model gates remain unavailable.')
}
