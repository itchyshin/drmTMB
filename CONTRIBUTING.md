# Contributing to drmTMB

`drmTMB` is early-stage software. Contributions should be small, tested, and
linked to the project design documents.

## Definition of Done

A modelling feature is complete only when it includes:

- implementation;
- simulation or unit tests;
- documentation;
- a runnable example;
- a check-log entry;
- review for likelihood, parameterization, and scope.

## Scope

The package is for univariate and bivariate distributional regression. General
high-dimensional multivariate models belong in companion packages such as
`gllvmTMB`.

## Development Checks

Use these commands before review:

```r
devtools::document()
devtools::test()
devtools::check()
```

Regenerate documentation with exactly roxygen2 7.3.2, the version recorded as
`RoxygenNote` in `DESCRIPTION` (decision of 25 October 2026, issue #1140). Do
not regenerate `man/*.Rd` or `NAMESPACE` with a newer roxygen2, and do not bump
`RoxygenNote`: a newer version rewrites many unrelated help files. Check the
installed version first with `packageVersion("roxygen2")`; if it differs,
install 7.3.2 (for example `remotes::install_version("roxygen2", "7.3.2")`)
before running `devtools::document()`.

Long simulation studies should live outside CRAN-time tests.

## Test coverage

Line coverage is measured with covr on GitHub Actions (`test-coverage`), using
the same `DRMTMB_TEST_SHARD="k/4"` partition as repository CI so each test file
is counted once, on Ubuntu and R-release only. The producer plants the Unix
Rcheck layout `00_pkg_src/drmTMB` at the covr library root so existing
source-path guards (`drm_src_path`, `drm_pkg_path`) still see `src/`, `R/`,
and `man/` under `tools::testInstalledPackage`. Do not skip those guards on
covr.

On `pull_request` events GitHub checks out the merge commit (`GITHUB_SHA`),
not the branch head. Coverage identity records `checkout_sha` /
`coverage_commit` (what tests ran), `github_sha`, and `branch_head`
(`github.event.pull_request.head.sha`). Codecov upload uses GitHub OIDC from
a separate main-only workflow (`codecov-upload`). Pull requests generate
coverage reports but cannot upload before an owner-authorized merge: the
uploader is not on the default branch and never receives credentials on a
PR. Do not add a coverage badge until a main-branch Codecov report exists
for a tested commit. Do not request a Codecov token or App grant unless a
main-branch uploader actually fails to authenticate.
