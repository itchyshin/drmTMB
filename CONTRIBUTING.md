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
