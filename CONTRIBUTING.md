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

Long simulation studies should live outside CRAN-time tests.
