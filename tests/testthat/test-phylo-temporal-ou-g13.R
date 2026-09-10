test_that('phylo OU G13 re-verifier is manifest-bound and refuses incomplete artifacts', {
  worker <- testthat::test_path('..', '..', 'tools', 'reverify-phylo-temporal-ou-g13.R')
  self <- system2('Rscript', c('--vanilla', worker, '--self-test'), stdout = TRUE, stderr = TRUE)
  expect_null(attr(self, 'status'))
  expect_true(any(grepl('PHYLO_TEMPORAL_OU_G13_REVERIFY_SELFTEST_PASS', self, fixed = TRUE)))
  input <- tempfile('g13-incomplete-'); output <- tempfile('g13-output-'); dir.create(input)
  on.exit(unlink(c(input, output), recursive = TRUE, force = TRUE), add = TRUE)
  incomplete <- suppressWarnings(system2('Rscript', c('--vanilla', worker, paste0('--campaign-dir=', input), paste0('--output-dir=', output)), stdout = TRUE, stderr = TRUE))
  expect_false(is.null(attr(incomplete, 'status')))
  expect_true(file.exists(file.path(output, 'task-inventory.csv')))
})

test_that('phylo OU G13 re-verifier contains no fit invocation', {
  worker <- testthat::test_path('..', '..', 'tools', 'reverify-phylo-temporal-ou-g13.R')
  text <- paste(readLines(worker, warn = FALSE), collapse = '\n')
  expect_false(grepl('drmTMB\\s*\\(', text))
  expect_true(grepl('No model fit was launched', text, fixed = TRUE))
})
