# ?nbinom2 must say it cannot represent underdispersion and point those users
# to glmmTMB (#1466, owner ruling option (c): docs pointer, no new family).
# The pin reads the committed man/nbinom2.Rd, which the man-sync guard
# (test-man-roxygen-sync.R, #1571) keeps equal to the roxygen block in R/.
test_that('?nbinom2 names the Poisson-limit floor and points to compois/genpois (#1466)', {
  rd <- test_path('..', '..', 'man', 'nbinom2.Rd')
  skip_if_not(file.exists(rd), 'man/ is unavailable in an installed-package check.')
  text <- gsub('\\s+', ' ', paste(readLines(rd, warn = FALSE), collapse = ' '))
  expect_true(grepl('underdispers', text, fixed = TRUE))
  expect_true(grepl('Poisson limit', text, fixed = TRUE))
  expect_true(grepl('boundary (limit)', text, fixed = TRUE))
  expect_true(grepl('glmmTMB::compois', text, fixed = TRUE))
  expect_true(grepl('genpois', text, fixed = TRUE))
})
