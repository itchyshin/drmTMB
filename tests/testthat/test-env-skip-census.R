# Guard for the environment-skip census (blind spot #2).
#
# PR #1222 measured the tests that `R CMD check` cannot reach because
# `.Rbuildignore` removes their premise from the tarball. This file guards the
# other family: tests the RUNNER cannot reach, because it lacks a package, an
# executable, an environment variable or an operating system. Both print as
# skips inside a green summary line, and a permanent skip is not a pass.
#
# Everything here is pure logic -- source parsing and a DESCRIPTION read. No
# fits, no package load beyond drmTMB itself. It runs under `R CMD check` on
# every runner, which is the point: a census that could only be re-derived from
# a source checkout would be inside blind spot #1.

source(testthat::test_path("helper-env-skip-census.R"))

census_path <- function() {
  system.file("extdata", "env-skip-census.tsv", package = "drmTMB")
}

test_that("the committed env-skip census matches the test suite", {
  path <- census_path()
  skip_if(!nzchar(path) || !file.exists(path), "env-skip-census.tsv not installed")

  census <- drm_skip_census(".")
  expect_gt(nrow(census), 0L)

  derived <- drm_env_skip_census_tsv(census)
  committed <- readLines(path, warn = FALSE)

  # Both directions. A new skip nobody censused is the blind spot growing; a
  # censused site that no longer exists is the census rotting. The failure this
  # guards against is precisely a list that goes stale unnoticed, so the
  # comparison is byte-for-byte rather than a count.
  if (!identical(derived, committed)) {
    only_new <- setdiff(derived, committed)
    only_old <- setdiff(committed, derived)
    fail(paste0(
      "inst/extdata/env-skip-census.tsv is out of date.\n",
      if (length(only_new)) paste0(
        "  NOT IN CENSUS (new or changed skip site):\n    ",
        paste(utils::head(only_new, 10L), collapse = "\n    "), "\n"
      ) else "",
      if (length(only_old)) paste0(
        "  IN CENSUS BUT NO LONGER PRESENT:\n    ",
        paste(utils::head(only_old, 10L), collapse = "\n    "), "\n"
      ) else "",
      "  Re-derive with: Rscript tools/write-env-skip-census.R"
    ))
  }
  expect_identical(derived, committed)
})

test_that("every skip_if_not_installed() target is a declared dependency", {
  # THIS is the disease guard, not bookkeeping.
  #
  # `skip_if_not_installed("foo")` on a package the CI runner installs costs
  # nothing: the test runs. On a package the runner never installs, the test
  # skips on every run forever, prints inside the green summary, and the
  # capability it guards is claimed but never exercised.
  #
  # setup-r-dependencies installs DESCRIPTION dependencies, including
  # Depends, Imports, LinkingTo, and Suggests. A target outside those fields
  # is a permanent skip by construction -- caught on the first run.
  census <- drm_skip_census(".")
  targets <- drm_skip_installed_targets(census)
  expect_gt(length(targets), 0L)

  desc <- utils::packageDescription("drmTMB")
  dependency_fields <- c("Depends", "Imports", "LinkingTo", "Suggests")
  dependencies <- unlist(desc[dependency_fields], use.names = FALSE)
  dependencies <- dependencies[!is.na(dependencies) & nzchar(dependencies)]
  skip_if(!length(dependencies), "DESCRIPTION has no dependency fields in this install")
  declared <- trimws(gsub("\\s*\\(.*?\\)", "", unlist(strsplit(dependencies, ","))))
  declared <- declared[nzchar(declared)]

  # drmTMB itself is always available inside its own test suite.
  undeclared <- setdiff(targets, c(declared, "drmTMB"))
  expect_identical(
    undeclared, character(0),
    info = paste0(
      "skip_if_not_installed() names ", paste(undeclared, collapse = ", "),
      ", which is not declared in Depends, Imports, LinkingTo, or Suggests. ",
      "CI never installs that package, so the guarded test skips permanently. ",
      "Declare the dependency or remove the unreachable guard."
    )
  )
})

test_that("environment-permanent gates are the two the owner has ruled on", {
  # A gate class that never runs on CI is an owner decision, not an accident.
  # Today there are exactly two, both deliberate and both recorded:
  #
  #   engine-drm-jl  the live DRM.jl engine behind `engine = "julia"`. CI sets
  #                  no DRM_JL_PATH and installs no Julia. THIS ONE GUARDS A
  #                  DOCUMENTED, EXPORTED CAPABILITY and is the open finding.
  #   env-var-optin  skip_fragile_recovery(), fenced on purpose and documented
  #                  in docs/dev-log/known-limitations.md.
  #
  # A THIRD class appearing here means someone has added a permanently-skipped
  # family without anyone deciding to. That is the thing to notice.
  census <- drm_skip_census(".")
  permanent <- census[census$axis == "environment" & census$ci_status == "skips", , drop = FALSE]
  expect_identical(
    sort(unique(permanent$gate_class), method = "radix"),
    c("engine-drm-jl", "env-var-optin")
  )
})
