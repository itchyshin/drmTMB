test_that("check-log.d is the live log and check-log.md is marked frozen", {
  readme <- test_path("..", "..", "docs", "dev-log", "check-log.d", "README.md")
  frozen <- test_path("..", "..", "docs", "dev-log", "check-log.md")
  skip_if_not(file.exists(readme), "check-log.d README is not in this build")
  skip_if_not(file.exists(frozen), "check-log.md is not in this build")

  readme_text <- paste(readLines(readme, warn = FALSE), collapse = "\n")
  expect_match(readme_text, "YYYY-MM-DD-<slice>[.]md")
  expect_match(readme_text, "Do not append new")

  head <- paste(readLines(frozen, n = 12L, warn = FALSE), collapse = "\n")
  expect_match(head, "Frozen historical check log")
  expect_match(head, "check-log[.]d")
  expect_match(head, "#1113")
})
