test_that('fixed-tree true-covariance GLS diagnostic self-tests and remains no-fit', {
  worker <- testthat::test_path('..', '..', 'tools', 'run-phylo-temporal-ou-fixed-tree-truth-gls.R')
  output <- system2('Rscript', c('--vanilla', worker, '--self-test'), stdout = TRUE, stderr = TRUE)
  expect_null(attr(output, 'status'))
  expect_true(any(grepl('PHYLO_TEMPORAL_OU_FIXED_TREE_TRUTH_GLS_SELFTEST_PASS', output, fixed = TRUE)))
  text <- paste(readLines(worker, warn = FALSE), collapse = '\n')
  expect_false(grepl('drmTMB\\s*\\(', text))
  expect_true(grepl('mechanism diagnostic, not calibration evidence', text, fixed = TRUE))
})
