old_wd <- getwd()
setwd(testthat::test_path("..", ".."))
withr::defer(setwd(old_wd))
runner_path <- file.path(getwd(), "tools", "run-arc6-bernoulli-nbinom2-f4r-private.R")
source(runner_path, local = TRUE)

f4r_test_sha <- paste(rep("a", 40L), collapse = "")

test_that("F4R freezes the distinct 16-cell and 16,000-attempt seed schedule", {
  grid <- f4r_grid(); manifest <- f4r_seed_manifest(grid)
  expect_equal(nrow(grid), 16L); expect_equal(nrow(manifest), 16000L)
  expect_identical(manifest$seed[[1L]], 2026481001L)
  expect_identical(manifest$seed[[1001L]], 2026482001L)
  expect_identical(manifest$seed[[16000L]], 2026497000L)
  expect_equal(length(unique(manifest$seed)), 16000L)
  expect_silent(f4r_validate_seed_manifest(manifest))
  tampered <- manifest; tampered$cell_id[[1L]] <- "f4r-c99"
  expect_error(f4r_validate_seed_manifest(tampered), "frozen 16,000-attempt")
})

test_that("F4R remains preparation-only and inherits the private blob gate", {
  opts <- f4r_parse_args(c("--mode=prepare", paste0("--expected-sha=", f4r_test_sha), "--out-dir=f4r-prep"))
  expect_identical(opts$expected_sha, f4r_test_sha)
  expect_error(f4r_parse_args(c("--mode=execute", paste0("--expected-sha=", f4r_test_sha), "--out-dir=x")), "Usage")
  root <- tempfile("f4r-root-"); dir.create(root); dir.create(file.path(root, "R")); file.create(file.path(root, "DESCRIPTION"))
  fake_git <- function(command, args, stdout, stderr) {
    if (identical(args, c("status", "--porcelain"))) return(character())
    if (identical(args, c("rev-parse", "HEAD"))) return(f4r_test_sha)
    if (startsWith(args[[2L]], "HEAD:")) return("bad-blob")
    stop("unexpected fake Git call")
  }
  expect_error(f4r_preflight(f4r_test_sha, root, fake_git), "blob mismatch")
  good_git <- function(command, args, stdout, stderr) {
    if (identical(args, c("status", "--porcelain"))) return(character())
    if (identical(args, c("rev-parse", "HEAD"))) return(f4r_test_sha)
    path <- sub("^HEAD:", "", args[[2L]])
    unname(f4_private_engine_blobs[[path]])
  }
  gate <- f4r_preflight(f4r_test_sha, root, good_git)
  expect_equal(nrow(gate$seed_manifest), 16000L)
  expect_silent(f4r_validate_seed_manifest(gate$seed_manifest))
})
