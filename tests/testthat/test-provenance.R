# Build-provenance surface (DRM.jl#473 / D4).
#
# `packageVersion("drmTMB")` cannot distinguish two builds that report the
# same version string but differ on commits under R/, src/, NAMESPACE. These
# tests cover drm_provenance()'s record shape, the honest degraded path when
# no build was baked, the dirty-tree flag captured by the build-time script,
# and that a fitted object carries the stamp.

runner_path <- testthat::test_path("..", "..", "tools", "drmtmb_provenance.R")
testthat::skip_if_not(file.exists(runner_path), "requires tools/drmtmb_provenance.R")
source(runner_path, local = TRUE)

test_that("drm_provenance() returns a stable, typed record shape", {
  rec <- drm_provenance()
  expect_type(rec, "list")
  expect_named(
    rec,
    c("package_version", "git_sha", "git_dirty", "build_time", "source", "reason", "queried_at")
  )
  expect_type(rec$package_version, "character")
  expect_length(rec$package_version, 1L)
  expect_true(is.character(rec$git_sha))
  expect_true(is.logical(rec$git_dirty))
  expect_true(is.character(rec$build_time))
  expect_type(rec$source, "character")
  expect_true(rec$source %in% c("baked", "baked-without-git", "unavailable"))
  expect_true(is.character(rec$reason))
  expect_type(rec$queried_at, "character")
  expect_match(rec$queried_at, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$")
})

test_that("drm_provenance() degrades honestly when no build was baked", {
  # In this test session drmTMB was loaded by devtools/testthat, not
  # installed via `configure`, so inst/build-provenance.dcf does not exist.
  # That is the true no-git-determinable-here state -- confirm it is
  # reported as NA-with-reason, not guessed.
  baked <- tryCatch(
    system.file("build-provenance.dcf", package = "drmTMB"),
    error = function(e) ""
  )
  skip_if(nzchar(baked) && file.exists(baked), "a baked file exists in this install; degraded path not exercised")

  rec <- drm_provenance()
  expect_identical(rec$source, "unavailable")
  expect_true(is.na(rec$git_sha))
  expect_true(is.na(rec$git_dirty))
  expect_true(is.na(rec$build_time))
  expect_false(is.na(rec$reason))
  expect_match(rec$reason, "build-provenance")
})

test_that("drmtmb_capture_git_state() reports NA with a reason when there is no .git", {
  root <- withr::local_tempdir()
  state <- drmtmb_capture_git_state(root)
  expect_true(is.na(state$git_sha))
  expect_true(is.na(state$git_dirty))
  expect_false(is.na(state$reason))
  expect_match(state$reason, "\\.git|git")
})

test_that("drmtmb_capture_git_state() flags a dirty working tree and reports the SHA", {
  skip_if_not(nzchar(Sys.which("git")), "requires a git executable")

  root <- withr::local_tempdir()
  run_git <- function(...) {
    system2("git", args = c("-C", root, ...), stdout = TRUE, stderr = TRUE)
  }
  run_git("init", "--quiet")
  run_git("config", "user.email", "test@example.com")
  run_git("config", "user.name", "Test")
  writeLines("one", file.path(root, "tracked.txt"))
  run_git("add", "tracked.txt")
  run_git("commit", "--quiet", "-m", "initial")

  clean_state <- drmtmb_capture_git_state(root)
  expect_false(is.na(clean_state$git_sha))
  expect_match(clean_state$git_sha, "^[0-9a-f]{40}$")
  expect_identical(clean_state$git_dirty, FALSE)

  writeLines("two", file.path(root, "tracked.txt"))
  dirty_state <- drmtmb_capture_git_state(root)
  expect_identical(dirty_state$git_sha, clean_state$git_sha)
  expect_identical(dirty_state$git_dirty, TRUE)
})

test_that("two different builds produce distinguishable provenance -- the problem this slice solves", {
  # Motivation (measured 2026-08-24, re-measured 2026-09-01): an installed
  # build can sit dozens of commits behind origin/main on R/, src/, and
  # NAMESPACE while `packageVersion("drmTMB")` stays "0.7.0" on both. If two
  # different commits produced identical drm_provenance() git_sha values,
  # this feature would not have solved that problem. Exercise the exact
  # capture path `configure` duplicates (drmtmb_capture_git_state()) across
  # two commits of the same repo and confirm the SHAs differ.
  skip_if_not(nzchar(Sys.which("git")), "requires a git executable")

  root <- withr::local_tempdir()
  run_git <- function(...) {
    system2("git", args = c("-C", root, ...), stdout = TRUE, stderr = TRUE)
  }
  run_git("init", "--quiet")
  run_git("config", "user.email", "test@example.com")
  run_git("config", "user.name", "Test")

  writeLines("one", file.path(root, "R.txt"))
  run_git("add", "R.txt")
  run_git("commit", "--quiet", "-m", "build-A-an-old-R-commit")
  build_a <- drmtmb_capture_git_state(root)

  writeLines("two", file.path(root, "R.txt"))
  run_git("add", "R.txt")
  run_git("commit", "--quiet", "-m", "build-B-a-later-R-commit")
  build_b <- drmtmb_capture_git_state(root)

  expect_false(is.na(build_a$git_sha))
  expect_false(is.na(build_b$git_sha))
  expect_false(identical(build_a$git_sha, build_b$git_sha))
})

test_that("drmtmb_provenance() script-level record composes package version and git state", {
  root <- withr::local_tempdir()
  rec <- drmtmb_provenance(root)
  expect_true(all(c("package_version", "git_sha", "git_dirty", "build_time", "source", "reason") %in% names(rec)))
  expect_identical(rec$source, "unavailable")
  expect_false(is.na(rec$reason))
})

test_that("a fitted drmTMB object carries the provenance stamp", {
  set.seed(1)
  n <- 30
  x <- rnorm(n)
  y <- rnorm(n, mean = 1 + 0.5 * x)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(mu = y ~ x), data = dat, family = gaussian())

  expect_true("provenance" %in% names(fit))
  rec <- fit$provenance
  expect_named(
    rec,
    c("package_version", "git_sha", "git_dirty", "build_time", "source", "reason", "queried_at")
  )
  expect_identical(rec$package_version, as.character(utils::packageVersion("drmTMB")))
})

test_that("configure.win is a POSIX sh script that bakes the provenance DCF", {
  # R CMD INSTALL on Windows runs configure.win with the Rtools `sh`, not with
  # cmd.exe. A batch-file configure.win (`@echo off`, `REM`) made every
  # Windows source install fail with "configuration failed for package".
  src_root <- testthat::test_path("..", "..")
  win <- file.path(src_root, "configure.win")
  unix <- file.path(src_root, "configure")
  testthat::skip_if_not(file.exists(win) && file.exists(unix), "requires the source tree")
  sh <- Sys.which("sh")
  testthat::skip_if(!nzchar(sh), "requires sh")

  first <- readLines(win, n = 1L, warn = FALSE)
  expect_identical(first, "#!/bin/sh")
  expect_false(any(grepl(
    "^\\s*(@echo|REM\\b|setlocal|goto|call :)",
    readLines(win, warn = FALSE),
    ignore.case = TRUE
  )))
  expect_identical(system2(sh, c("-n", shQuote(win)), stdout = FALSE, stderr = FALSE), 0L)

  scratch <- withr::local_tempdir()
  file.copy(c(win, unix), scratch)
  status <- withr::with_dir(scratch, system2(sh, "configure.win", stdout = FALSE, stderr = FALSE))
  expect_identical(status, 0L)
  dcf <- read.dcf(file.path(scratch, "inst", "build-provenance.dcf"))
  expect_identical(colnames(dcf), c("GitSHA", "GitDirty", "GitReason", "BuildTimeUTC"))
  expect_identical(unname(dcf[1, "GitSHA"]), "NA")
  expect_match(unname(dcf[1, "GitReason"]), "no .git directory|git executable not found")
})
