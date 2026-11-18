# Check log: env-skip census row for #1706

**Date:** 2026-11-18
**Branch:** `cursor/fix-1706-foreign-family-6448`

## Goal

Record the `skip_if_not_installed("glmmTMB")` call site that
`tests/testthat/test-fix-1706-foreign-family.R` added, so the committed
env-skip census matches the suite.

## Change

`Rscript tools/write-env-skip-census.R` added one row:

```text
test-fix-1706-foreign-family.R	suggests-package	environment	runs	1
```

The gate class is `runs`: `glmmTMB` is in Suggests, and CI installs Suggests.
No test was skipped, deleted, or retoleranced. `origin/main` was merged
first; that merge already carried the Laplace-bridge census rows from
`02a0de28a`.

## Why this is not a main failure

Coverage on `origin/main` `74007c485` succeeded as run `44318236120`. The red
job is PR #1715 coverage shard 6/9, run `44318344293`. The failure text names
this missing row.

## Verification

R 4.3.3. `Rscript tools/write-env-skip-census.R --check` printed
`env-skip census up to date: 2032 skip call sites`.

Installed this branch with `R CMD INSTALL --library=$HOME/R/library1715`.
`NOT_CRAN=true`. `glmmTMB` was installed.

| File | Result |
| --- | --- |
| `test-env-skip-census.R` | pass (5) |
| `test-fix-1706-foreign-family.R` | pass (19) |

## Claim boundary

The other coverage shards on this PR were already green. They were not rerun.
