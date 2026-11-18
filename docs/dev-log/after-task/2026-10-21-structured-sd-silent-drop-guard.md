# After Task: Structured SD formulas fail explicitly in three family builders

## Goal

Prevent Student-t, skew-normal, and zero-one beta builders from silently dropping structured random-effect SD formulas they do not implement.

## Implemented

Each builder now stops with an error that names the requested structured effect class. Existing ordinary location SD assembly is unchanged.

## Mathematical Contract

No likelihood or covariance equation changed. This guard prevents a requested structured SD model from being mistaken for the different model obtained after silently omitting that formula.

## Files Changed

`R/drmTMB.R`; the Student-t, skew-normal, and zero-one-beta SD regression tests; `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`; this report; and the check-log fragment.

## Checks Run

The three focused regression test files passed with `devtools::load_all()` and `testthat::test_file()`. Before the fix, all three negative tests failed because their builders returned a model specification instead of an error. `git diff --check` and the repository's stale-wording searches are recorded after they run.

## Tests Of The Tests

The Student negative test failed before the code change. The new skew-normal and zero-one-beta negative tests were also run before the code change and failed for the same reason. The same test files contain ordinary intercept or slope assembly checks, which pass after the change.

## Consistency Audit

The adapter map now says that these builders reject the structured SD formulas they do not support. Existing family limitations remain in force. The status inventory was checked in `README.md`, `docs/dev-log/internal-roadmap.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, and `_pkgdown.yml`, using `rg --count-matches -i 'random-effect SD|sd\(group\)|structured effects'` across those paths. No formula grammar or navigation change was made. A relevant `NEWS.md` edit was deferred because preflight found many divergent references changing that file; the feature status is already documented as excluding structured effects.

## GitHub Issue Maintenance

Searched open drmTMB issues for structured SD reports involving these families. No issue matching this specific silent-drop behavior was found, so no issue was changed.

## What Did Not Go Smoothly

The initial Student-t reproduction led to two more affected builders. A live Gaussian animal lane held its own tests, design notes, and `check-log.md`; those files were left untouched, and this evidence is recorded in a `check-log.d` fragment. The shared `R/drmTMB.R` diff was reviewed before editing, and the code change stayed within the disjoint family-builder span. The project instructions name `tools/check-after-task.R`, but that script is absent in this checkout; I checked the report sections manually against the template.

## Team Learning

When a builder classifies an SD formula separately from ordinary `sd()` entries, tests should assert that every classified route is either wired into the model specification or rejected. A parsed formula is not evidence that the likelihood consumes it.

## Known Limitations

Structured SD fitting remains unsupported in these three families. This change adds an explicit error only. It does not establish fitting, recovery, uncertainty calibration, or Julia parity.

## Next Actions

Continue the approved general SD-regression goal with the next supported family and effect combination. Keep the overall goal active until its cross-family, cross-effect, two-engine, and calibrated-uncertainty gates are met.
