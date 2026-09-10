test_that('temporal gate runners fail closed and pass their self-tests', {
  runner <- normalizePath(file.path('..', '..', 'tools', 'phylo-temporal-ou-gates.R'))
  source_runner <- normalizePath(file.path('..', '..', 'tools', 'temporal-source-map-gates.R'))
  expect_match(system2('Rscript', c('--vanilla', runner, '--self-test'), stdout = TRUE),
               'PHYLO_TEMPORAL_OU_RUNNER_SELFTEST_PASS')
  expect_match(system2('Rscript', c('--vanilla', source_runner, '--self-test'), stdout = TRUE),
               'TEMPORAL_SOURCE_MAP_RUNNER_SELFTEST_PASS')
  expect_true(any(grepl('TEMPORAL_SOURCE_MAP_M01_BOOTSTRAP_PASS',
                        system2('Rscript', c('--vanilla', source_runner, 'M01-bootstrap'), stdout = TRUE),
                        fixed = TRUE)))
  expect_match(system2('Rscript', c('--vanilla', source_runner, 'M02'), stdout = TRUE),
               'TEMPORAL_SOURCE_MAP_M02_PASS')
  expect_match(system2('Rscript', c('--vanilla', source_runner, 'M03'), stdout = TRUE),
               'TEMPORAL_SOURCE_MAP_M03_PASS')
  expect_match(system2('Rscript', c('--vanilla', runner, 'G14'), stdout = TRUE),
               'PHYLO_TEMPORAL_OU_G14_PASS')
  expect_match(system2('Rscript', c('--vanilla', runner, 'G15'), stdout = TRUE),
               'PHYLO_TEMPORAL_OU_G15_PASS')
  expect_match(system2('Rscript', c('--vanilla', runner, 'G9b-full'), stdout = TRUE),
               'PHYLO_TEMPORAL_OU_G9B_FULL_PASS')
  bad <- suppressWarnings(system2('Rscript', c('--vanilla', runner, 'G9'), stdout = TRUE, stderr = TRUE))
  expect_false(is.null(attr(bad, 'status')))
  expect_match(system2('Rscript', c('--vanilla', runner, 'G10'), stdout = TRUE),
               'PHYLO_TEMPORAL_OU_G10_PASS')
  expect_true(any(grepl('PHYLO_TEMPORAL_OU_G11_PASS',
                        system2('Rscript', c('--vanilla', runner, 'G11'), stdout = TRUE),
                        fixed = TRUE)))
})
