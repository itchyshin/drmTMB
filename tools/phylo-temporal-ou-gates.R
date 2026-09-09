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
} else {
  fail('Only --self-test and G1 are available before model fixtures are implemented.')
}
