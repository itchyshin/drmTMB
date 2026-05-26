# After Task: Phase 18 Count Mu Random-Effect Grid Output Slices 709-718

## Goal

Validate and document the paired Poisson/NB2 `mu` random-effect grid-output
writer for Phase 18, including aggregate, replicate, manifest, failure-ledger,
Wald interval, Wald coverage, direct-SD profile interval, and profile coverage
CSV artifacts beside resumable RDS results.

## Implemented

Added `docs/design/90-phase-18-count-mu-re-grid-output-slices-709-718.md` to
record the source and test evidence. No likelihood, formula grammar, public API,
roxygen topic, pkgdown navigation, or rendered site output changed.

## Mathematical Contract

No model changed. The checked count models remain ordinary non-zero-inflated
location random-effect surfaces:

- Poisson: `bf(count ~ x + (1 | id) + (0 + x | id))`
- NB2: `bf(count ~ x + (1 | id) + (0 + x | id), sigma ~ z)`

The random intercept and independent numeric slope belong to the location part.
NB2 `sigma` remains a fixed-effect overdispersion submodel in this lane.

## Files Changed

- `docs/design/90-phase-18-count-mu-re-grid-output-slices-709-718.md`
- `docs/dev-log/after-task/2026-05-24-phase18-count-mu-re-grid-output-slices-709-718.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
nl -ba inst/sim/run/sim_write_count_mu_random_effect_grid.R | sed -n '1,125p'
nl -ba inst/sim/run/sim_summary_count_mu_random_effect_pilot.R | sed -n '1,115p'
nl -ba inst/sim/run/sim_run_poisson_mu_random_effect_smoke.R | sed -n '35,95p'
nl -ba inst/sim/run/sim_run_nbinom2_mu_random_effect_smoke.R | sed -n '35,100p'
nl -ba tests/testthat/test-phase18-count-mu-random-effect-grid-writer.R | sed -n '1,115p'
Rscript -e "devtools::test(filter = 'phase18-(count-mu-random-effect-grid-writer|count-mu-random-effect-pilot|poisson-mu-random-effect|nbinom2-mu-random-effect|sim-aggregate|sim-uncertainty)', reporter = 'summary')"
```

Results:

- Source reads confirmed the eight table outputs, paired Poisson/NB2 result
  subdirectories, resumable runner forwarding, bounded runner metadata, and
  ordinary location random-effect formulas.
- The focused count `mu` random-effect bundle completed with exit code 0.
- No files were staged or committed.

## Tests Of The Tests

The focused grid-writer test checks paired Poisson/NB2 output, artifact
existence, artifact-manifest existence, aggregate and replicate row counts,
manifest row counts, Wald and profile interval CSV row counts, serial fallback
when `backend = "none"`, overwrite rejection, empty `output_dir`, and malformed
`overwrite` values.

## Consistency Audit

This report stays inside ordinary non-zero-inflated Poisson/NB2 location random
effects. It does not add zero-inflated counts, hurdle counts, zero-truncated NB2
random effects, correlated count slopes, NB2 `sigma` slopes, NB2 `sigma`
phylogeny, q4 count covariance, formula grammar, likelihood code, roxygen
topics, pkgdown navigation, or new user-facing API.

## GitHub Issue Maintenance

No GitHub issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

Two exploratory reads used stale guessed filenames for a combined count summary
and runner. The actual implementation uses the paired pilot summary plus
separate Poisson and NB2 runner files, and the follow-up reads used those paths.

## Team Learning

Count grid-output validation should name the location-submodel boundary each
time, because adjacent NB2 `sigma`, zero-inflation, hurdle, and structured-count
lanes are easy to blur from filenames alone.

## Known Limitations

This is smoke/grid-output evidence, not a final formal coverage claim. The
paired grid remains a small ordinary-count surface; broader structured-count and
inflation/hurdle extensions remain separate work.

## Next Actions

Continue with Slices 719-728 by validating simple grid-output writers for
ordinary Gaussian `mu` slopes, Gaussian `sigma` slopes, and coordinate-spatial
Gaussian `mu` slopes if the dirty tree already contains enough evidence.
