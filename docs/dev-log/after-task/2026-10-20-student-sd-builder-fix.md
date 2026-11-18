# After Task: Student SD builder default for ordinary effects

## Goal

Make ordinary Student random-effect SD formulas reach TMB data assembly and fitting.

## Implemented

The Student model builder now includes an empty phylogenetic SD descriptor beside its ordinary location SD descriptor. The shared TMB assembler can read its standard fields even when the Student model has no phylogenetic SD term. The legacy test for `sd(id)` without a matching random effect now checks the specific actionable error.

## Mathematical Contract

This repairs model assembly only. `sd(id) ~ w` continues to model the log SD of the selected latent location effect. Student `sigma` remains the Student-t scale parameter. No likelihood or covariance equation changed.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-student-sd-regression.R`
- `tests/testthat/test-student-location-scale.R`
- `docs/dev-log/check-log.d/2026-10-21-student-sd-builder-fix.md`
- `docs/dev-log/after-task/2026-10-21-student-sd-builder-fix.md`

The shared `docs/dev-log/check-log.md` was not edited because lane preflight found 424 divergent refs on that path. This task has a dedicated check-log shard; the central log update remains pending ownership clearance.

## Checks Run

- Before the fix, the native family run failed three Student assembly tests with `random_scale$phylo$n_models` missing. This was the expected red result.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "student-sd-regression")'`: 25 passed, 0 failed, 0 skipped.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "student-sd-integration")'`: 30 passed, 0 failed, 0 skipped.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "missing-predictor-student-response")'`: 17 passed, 0 failed, 0 skipped.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "beta-sd-regression|gamma-sd-regression|nbinom2-sd-regression|poisson-sd-regression|student-sd-regression|student-sd-integration|student-location-scale")'`: 233 passed, 0 failed, 0 skipped after the legacy error assertion was updated.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "poisson-sd-(integration|assembly)")'`: 100 passed, 0 failed, 0 skipped.
- Julia SD tests for Beta, Gamma, NB2, Poisson, and Student: 204 passed. The paired DRM.jl worktree was at `70dbf564eb670144c63c08f61ea099084d95add2`.

## Tests Of The Tests

The newly added Student assembly tests failed before the builder change, with three failures caused by the missing structured descriptor. After the fix, assembly passed and the Student integration suite fitted the model and passed its extraction, recovery, and target-routing checks. The broader run caught one stale expected error; after updating it to the current no-matching-random-effect error, the focused family suites passed.

## Consistency Audit

The check searched the project status surfaces with:

`rg -n -i 'student.{0,80}random.effect scale|random.effect scale.{0,80}student' README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd`

It returned no matches for obsolete Student SD rejection wording. No formula grammar, likelihood, vignette example, or pkgdown navigation changed. The check-log shard records the bounded implementation claim and exact test totals.

## GitHub Issue Maintenance

No issue or pull request was changed. The read-only search found #59 for the broader simulation framework and #682 for profile interval methods. This builder fix does not resolve either broader item.

## What Did Not Go Smoothly

The first broad family sweep exposed the missing empty descriptor. The post-fix sweep also found an old test expecting the former generic rejection message. Both failures were corrected at their source, and the same targeted suites then passed.

## Team Learning

When a family joins a shared parameter assembler, its model specification must include the standard empty descriptors for inactive endpoints as well as the active endpoint.

## Known Limitations

These tests establish Student fitting and selected recovery behavior only. They do not establish interval coverage, and this Student slice does not add phylogenetic SD regression. The full general SD goal remains active. The Bernoulli live Julia bridge run also emitted singular-Hessian warnings in two fits, so it does not support a broad uncertainty claim.

## Next Actions

Continue the remaining family, effect, and backend rows in the capability inventory. Keep coverage claims deferred until the later calibration phase. Append this shard to the central check log only after that shared path is cleared.
