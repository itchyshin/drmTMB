test_that('paired phylogenetic-OU comparator pilot self-tests and declares its scope', {
  worker <- testthat::test_path('..', '..', 'tools', 'run-phylo-temporal-ou-comparator-pilot.R')
  output <- system2('Rscript', c('--vanilla', worker, '--self-test'), stdout = TRUE, stderr = TRUE)
  expect_null(attr(output, 'status'))
  expect_true(any(grepl('PHYLO_TEMPORAL_OU_COMPARATOR_PILOT_SELFTEST_PASS', output, fixed = TRUE)))
  text <- paste(readLines(worker, warn = FALSE), collapse = '\n')
  expect_true(grepl('glmmTMB', text, fixed = TRUE))
  expect_true(grepl('does not qualify a temporal OU interval', text, fixed = TRUE))
})
