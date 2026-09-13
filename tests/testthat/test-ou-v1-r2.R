test_that("R2 information-preflight contract is complete", {
  root <- normalizePath(testthat::test_path("..", "..")); old <- setwd(root); on.exit(setwd(old), add = TRUE)
  out <- system2("Rscript", c("tools/verify-ou-v1-r2.R", "--contract"), stdout = TRUE, stderr = TRUE)
  expect_null(attr(out, "status"), info = paste(out, collapse = "\n")); expect_match(paste(out, collapse = "\n"), "OU_V1_R2_CONTRACT_PASS")
})
