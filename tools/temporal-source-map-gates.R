#!/usr/bin/env Rscript

script <- sub('^--file=', '', grep('^--file=', commandArgs(FALSE), value = TRUE)[[1L]])
root <- normalizePath(file.path(dirname(script), '..'))
setwd(root)
p1_runner <- file.path(root, 'tools/phylo-temporal-ou-gates.R')
source_map <- file.path(root, 'docs/dev-log/plans/2026-09-09-phylo-temporal-ou/source-map.md')
fingerprint <- file.path(root, 'docs/dev-log/plans/2026-09-09-phylo-temporal-ou/source-fingerprint.md')
fail <- function(...) stop(..., call. = FALSE)
section <- function(text, heading, next_heading = NULL) {
  lines <- strsplit(text, '\n', fixed = TRUE)[[1]]
  start <- match(heading, lines)
  if (is.na(start)) return('')
  rest <- lines[(start + 1L):length(lines)]
  if (!is.null(next_heading)) {
    end <- match(next_heading, rest)
    if (!is.na(end)) rest <- rest[seq_len(end - 1L)]
  }
  paste(rest, collapse = '\n')
}
validate_source_map <- function(path) {
  if (!file.exists(path)) fail('Missing cited source map: ', path)
  text <- paste(readLines(path, warn = FALSE), collapse = '\n')
  need <- c('## Verified sources', '## Unverified leads', 'glmmTMB', 'Matilda',
            'Felsenstein', 'NotebookLM source')
  missing <- need[!vapply(need, grepl, logical(1), x = text, fixed = TRUE)]
  if (length(missing)) fail('Source map lacks: ', paste(missing, collapse = '; '))
  verified <- section(text, '## Verified sources', '## Unverified leads')
  if (!grepl('](', verified, fixed = TRUE) || !grepl('https://', verified, fixed = TRUE)) fail('Verified source section has no Markdown citation.')
  if (grepl('UNVERIFIED|Unverified lead', verified, ignore.case = TRUE)) {
    fail('Verified source section labels a lead as verified.')
  }
}
validate_fingerprint <- function(path) {
  if (!file.exists(path)) fail('Missing source fingerprint: ', path)
  text <- paste(readLines(path, warn = FALSE), collapse = '\n')
  need <- c('Source commit:', 'Execution branch:', 'Source input SHA-256:',
            'R:', 'TMB:', 'Native library:')
  missing <- need[!vapply(need, grepl, logical(1), x = text, fixed = TRUE)]
  if (length(missing)) fail('Fingerprint lacks: ', paste(missing, collapse = '; '))
  commit <- regmatches(text, regexpr('Source commit: `?[0-9a-f]{40}`?', text, perl = TRUE))
  if (!nzchar(commit)) fail('Fingerprint source commit is malformed.')
  hash <- strsplit(system2('shasum', c('-a', '256', 'src/drmTMB.cpp'), stdout = TRUE), '\\s+')[[1]][1]
  if (!grepl(hash, text, fixed = TRUE)) fail('Fingerprint source input hash is stale.')
  r_version <- R.version$version.string
  tmb_version <- as.character(utils::packageVersion('TMB'))
  if (!grepl(r_version, text, fixed = TRUE) || !grepl(tmb_version, text, fixed = TRUE)) {
    fail('Fingerprint R or TMB version is stale.')
  }
}
self_test <- function() {
  bad_map <- tempfile(fileext = '.md')
  writeLines(c('## Verified sources', 'uncited material', '## Unverified leads', 'Matilda glmmTMB'), bad_map)
  if (!inherits(try(validate_source_map(bad_map), silent = TRUE), 'try-error')) {
    fail('Uncited-source negative control passed.')
  }
  bad_fingerprint <- tempfile(fileext = '.md')
  writeLines('Source commit: stale', bad_fingerprint)
  if (!inherits(try(validate_fingerprint(bad_fingerprint), silent = TRUE), 'try-error')) {
    fail('Incomplete-fingerprint negative control passed.')
  }
  cat('TEMPORAL_SOURCE_MAP_RUNNER_SELFTEST_PASS controls=2\n')
}
bootstrap <- function() {
  self_test()
  status <- system2('Rscript', c('--vanilla', p1_runner, '--self-test'), stdout = TRUE, stderr = TRUE)
  if (!identical(attr(status, 'status'), NULL) ||
      !any(grepl('PHYLO_TEMPORAL_OU_RUNNER_SELFTEST_PASS', status, fixed = TRUE))) {
    fail('P1 runner self-test failed.')
  }
  cat('TEMPORAL_SOURCE_MAP_M01_BOOTSTRAP_PASS\n')
}
args <- commandArgs(trailingOnly = TRUE)
if (identical(args, '--self-test')) {
  self_test()
} else if (identical(args, 'M01-bootstrap')) {
  bootstrap()
} else if (identical(args, 'M02')) {
  validate_source_map(source_map)
  cat('TEMPORAL_SOURCE_MAP_M02_PASS\n')
} else if (identical(args, 'M03')) {
  validate_fingerprint(fingerprint)
  cat('TEMPORAL_SOURCE_MAP_M03_PASS\n')
} else {
  fail('Use --self-test, M01-bootstrap, M02 or M03.')
}
