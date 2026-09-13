test_that("OU-sigma R1 contract and independent covariance oracle pass", {
  skip_if_not_installed("ape")
  root <- normalizePath(testthat::test_path("..", ".."))
  checker <- file.path(root, "tools", "verify-phylo-ou-sigma-recovery-calibration.R")
  old_wd <- setwd(root)
  on.exit(setwd(old_wd), add = TRUE)
  for (mode in c("--contract", "--oracle", "--artifacts", "--docs")) {
    output <- system2("Rscript", c(checker, mode), stdout = TRUE, stderr = TRUE)
    expect_null(attr(output, "status"), info = paste(output, collapse = "\n"))
    expect_match(paste(output, collapse = "\n"), "PHYLO_OU_SIGMA_R1_.*_PASS")
  }
})
