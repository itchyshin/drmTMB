test_that("OU v1 G14 runner declares its complete artifact schema", {
  root <- normalizePath(testthat::test_path("..", ".."))
  old_wd <- setwd(root)
  on.exit(setwd(old_wd), add = TRUE)
  output <- system2("Rscript", c("tools/verify-ou-v1-g14.R", "--schema"), stdout = TRUE, stderr = TRUE)
  expect_null(attr(output, "status"), info = paste(output, collapse = "\n"))
  expect_match(paste(output, collapse = "\n"), "OU_V1_G14_SCHEMA_PASS")
})
