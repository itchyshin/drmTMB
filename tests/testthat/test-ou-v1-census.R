test_that("OU v1 frozen capability census verifies", {
  root <- normalizePath(testthat::test_path("..", ".."))
  old_wd <- setwd(root)
  on.exit(setwd(old_wd), add = TRUE)
  output <- system2("Rscript", c("tools/verify-ou-v1-census.R", "--frozen"), stdout = TRUE, stderr = TRUE)
  expect_null(attr(output, "status"), info = paste(output, collapse = "\n"))
  expect_match(paste(output, collapse = "\n"), "OU_V1_CENSUS_FROZEN_PASS")
})
