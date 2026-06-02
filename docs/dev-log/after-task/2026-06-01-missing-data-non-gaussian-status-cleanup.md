# After Task: Missing Data And Non-Gaussian Status Cleanup

## Goal

Clean up the release-facing status surfaces after the missing-data closeout and
answer whether the package is close to finishing the non-Gaussian work.

## Implemented

No likelihood code changed. The cleanup made the current support boundary
explicit in `README.md`, `ROADMAP.md`, `docs/dev-log/known-limitations.md`,
`docs/design/149-missing-data-design.md`, and the module-level missing-data
after-task report.

The release-ready missing-data claim is:

```text
miss_control() is ready for Gaussian response masks, one-at-a-time modelled
missing predictors in univariate Gaussian location models across the implemented
predictor-family set, imputed() summaries, and MD9a.
```

MD9a is the first non-Gaussian response missing-data route: ordinary
`family = poisson()` with one fixed-effect binary `mi()` predictor and complete
count responses.

## Mathematical Contract

The mathematical contract is unchanged. Missing Gaussian responses are masked
or marginalised. One explicit `mi()` predictor is integrated inside the
likelihood by Laplace approximation, deterministic summation, or deterministic
quadrature depending on its predictor-model family. MD9a sums over the two
Bernoulli predictor states inside an ordinary Poisson response likelihood.

## Files Changed

- `README.md`: adds a status-table row for missing data.
- `ROADMAP.md`: adds the missing-data release boundary for the preview.
- `docs/dev-log/known-limitations.md`: adds a missing-data limitation block.
- `docs/design/149-missing-data-design.md`: adds the release-readiness
  interpretation and separates broad non-Gaussian predictor coverage from the
  narrow non-Gaussian response route.
- `docs/dev-log/after-task/2026-05-31-missing-data-module-family-coverage-closeout.md`:
  corrects stale wording that implied all current missing-predictor routes were
  fixed-effect only.

## Checks Run

```sh
Rscript -e "devtools::load_all(); devtools::test(filter = 'missing')"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
rg -n 'one fixed-effect `mi\(\)` predictor at a time|one fixed-effect mi\(\) predictor at a time|only a univariate Gaussian `mi\(\)` predictor|Poisson count predictors belong to the later|non-Gaussian response route.*planned|missing-data.*done.*general|general missing-data framework.*done' README.md ROADMAP.md NEWS.md docs/design/149-missing-data-design.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/dev-log/known-limitations.md docs/dev-log/after-task/2026-05-31-missing-data-module-family-coverage-closeout.md docs/dev-log/after-task/2026-06-01-missing-data-final-tidy-closeout.md vignettes/missing-data.Rmd
Rscript -e "devtools::test()"
```

Results:

- `devtools::test(filter = 'missing')` passed with 479 expectations, no
  failures, warnings, or skips.
- `pkgdown::check_pkgdown()` passed with no problems found.
- `git diff --check` passed.
- The stale scan returned only intentional boundary text: the NEWS MD9a
  planned-extension sentence, the new README missing-data boundary row, and the
  historical scan command recorded in the earlier family-coverage after-task
  report.
- Full `devtools::test()` passed with 9,090 expectations, no failures,
  warnings, or skips.

## Tests Of The Tests

The focused missing-data tests include response-mask checks, independent
likelihood recomputation for missing-predictor families, boundary errors for
unsupported routes, and the MD9a finite two-state Poisson-response likelihood.
The full package suite also reran the non-Gaussian random-slope, structured
count, Phase 18 artifact, and family-specific regression tests.

## Consistency Audit

The repository now tells the same story in the README, roadmap, limitations
file, design note, and after-task reports. Missing data is done for the current
release boundary, not for every possible missing-data workflow. The strongest
non-Gaussian status is fixed-effect one-response families plus first ordinary
`mu` random-effect slices and selected q=1 structured count slices. The package
is not finished for all non-Gaussian combinations: bivariate non-Gaussian and
mixed-response families, broad random effects in `sigma`, `nu`, `zi`, `hu`,
`zoi`, or `coi`, correlated non-Gaussian slopes, most structured
non-Gaussian slopes/covariances, non-Gaussian response missingness beyond
MD9a, and multiple missing predictors remain planned.

## GitHub Issue Maintenance

No issue was changed in this cleanup. The work was a local status cleanup on an
already broad dirty tree; the durable record is this after-task report and the
check-log entry.

## What Did Not Go Smoothly

The term "missing-data capabilities are done" was ambiguous. It could mean the
implemented release surface is coherent, or it could imply a general
missing-data framework. The cleanup resolves that ambiguity by making the
release boundary explicit.

## Team Learning

Future status updates should separate three axes: response family,
missing-data role, and random/structured complexity. "Non-Gaussian is nearly
done" is accurate only for a named axis, not for all combinations.

## Known Limitations

Multiple missing predictors, missing non-Gaussian responses, non-binary
missing predictors in non-Gaussian response models, grouped or structured
non-Gaussian predictor models, EM/profile/REML engines, simulation-based
imputation summaries, response imputation, measurement-error models, and
pigauto interoperability remain future work. Most non-Gaussian structured,
correlated-slope, and multi-response combinations also remain planned.

## Next Actions

Prepare a small reviewable handoff or PR for the missing-data release boundary.
If the next work stays in missing data, choose one explicit next slice such as
multiple Gaussian-response missing predictors, Poisson response plus continuous
Gaussian `mi()`, NB2 response plus binary `mi()`, or response-imputation
summaries.
