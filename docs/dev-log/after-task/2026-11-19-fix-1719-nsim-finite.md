# After Task: finite `nsim` guard for sibling count validators (#1719)

## Goal

Make every non-`simulate.drmTMB()` simulation count reject `Inf` and other
non-counts with a drmTMB abort instead of a base-R error.

## Implemented

One helper, `drm_validate_nsim()`, used at the five sites listed in #1719.
It also rejects counts above the integer range, which `as.integer()` would
otherwise turn into `NA`.

## Mathematical Contract

No likelihood or simulation draw changed. Valid counts are coerced with
`as.integer()` exactly as before.

## Files Changed

- `R/utils.R`, `R/adequacy.R`, `R/associate-pairs.R`, `R/julia-simulate.R`
- `tests/testthat/test-fix-1719-nsim-finite.R`
- `NEWS.md`
- `docs/dev-log/check-log.d/2026-11-19-fix-1719-nsim-finite.md`

## Checks Run

See the check-log shard.

## Tests Of The Tests

On main every new test errors: `Inf` produced a coercion warning and a
`simpleError`. The Julia Binomial site is reached with a mocked
`drm_julia_binomial_sd_simulation_spec()`, so no Julia is needed.

## Consistency Audit

The shared message is "`nsim` must be one finite positive whole number.",
close to the old Julia wording. `simulate.drmTMB()` (#1696) was left alone
because PR #1701's branch already covers it.

## GitHub Issue Maintenance

Refs #1719.

## Known Limitations

`simulate.drmTMB()` still has no `nsim` guard until #1696 lands; it could
adopt `drm_validate_nsim()`.

## Next Actions

Draft pull request for #1719.
