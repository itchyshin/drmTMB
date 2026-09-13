test_that("OU v1 oracle gate declares independent objective and mutation checks", {
  root <- normalizePath(testthat::test_path("..", ".."))
  old_wd <- setwd(root)
  on.exit(setwd(old_wd), add = TRUE)
  output <- system2("Rscript", c("tools/verify-ou-v1-oracle.R", "--contract"), stdout = TRUE, stderr = TRUE)
  expect_null(attr(output, "status"), info = paste(output, collapse = "\n"))
  expect_match(paste(output, collapse = "\n"), "OU_V1_INDEPENDENT_ORACLE_CONTRACT_PASS")
})
