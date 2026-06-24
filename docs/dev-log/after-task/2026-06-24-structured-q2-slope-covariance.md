# After Task: Structured Q2 Slope-Only Covariance

## Goal

Open the first bivariate Gaussian structured slope-only q=2 location covariance
cells without promoting bridge parity, intervals, coverage, REML, AI-REML, or
larger intercept-plus-slope structured covariance blocks.

The exact formula cells are matching `0 + x` labelled terms in `mu1` and `mu2`
for `phylo()`, fixed-covariance `spatial()`, A/Ainv `animal()`, and K/Q
`relmat()`.

## Implemented

- Extended structured formula parsing so labelled `0 + x | p | group` terms
  are valid while labelled `1 + x | p | group` remains rejected.
- Added bivariate q=2 coefficient guards that require exactly one matching
  coefficient per endpoint for structured `mu1`/`mu2` covariance.
- Made structured SD labels, correlation labels, `corpairs()`,
  `summary()$covariance`, `profile_targets()`, and `structured_effects()`
  coefficient-aware for the slope-only q=2 cells.
- Added native point-fit/extractor tests for:
  - `phylo(0 + x | p | species, tree = tree)`;
  - `spatial(0 + x | p | site, coords = coords)`;
  - `animal(0 + x | p | id, Ainv = Q)`;
  - `relmat(0 + x | p | id, K = K)` and `relmat(..., Q = Q)`.
- Added four q-series support-cell rows with `fit_status = point_fit`,
  `extractor_status = extractor_ready`, and planned bridge, interval, and
  coverage statuses.

## Mathematical Contract

Each cell is q=2 because it has exactly two endpoint members:

```text
mu1:x
mu2:x
```

The fitted structured SD names are coefficient-aware, such as
`mu1:phylo(0 + x | p | species)` and
`mu2:phylo(0 + x | p | species)`. The fitted correlation row is
`cor(mu1:x,mu2:x | p | group)`.

This is not the same as a labelled `1 + x | p | group` block. That larger
cell would require intercept and slope members for both endpoints, and remains
a later q4/q8 structured covariance gate.

## Files Changed

- `R/parse-formula.R`
- `R/drmTMB.R`
- `R/methods.R`
- `tests/testthat/test-phylo-gaussian.R`
- `tests/testthat/test-spatial-gaussian.R`
- `tests/testthat/test-animal-relmat-gaussian.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tools/validate-mission-control.py`
- `docs/design/01-formula-grammar.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/README.md`
- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `man/structured_effects.Rd`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format R/parse-formula.R R/drmTMB.R R/methods.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-spatial-gaussian.R tests/testthat/test-animal-relmat-gaussian.R tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'phylo-gaussian')"
Rscript --vanilla -e "devtools::test(filter = 'spatial-gaussian')"
Rscript --vanilla -e "devtools::test(filter = 'animal-relmat-gaussian')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
Rscript --vanilla -e "devtools::document()"
python3 -m py_compile tools/validate-mission-control.py
python3 tools/validate-mission-control.py
git diff --check
rg -n "qseries_.*q2_mu1_mu2_one_slope.*(fixture_parity|interval_feasible|inference_ready|supported)|slope-only q2.*(coverage-ready|interval-ready|REML-ready|AI-REML-ready|supported)|structured slope-only q=2.*(coverage result|interval reliability accepted|bridge parity)|phylo\\(1 \\+ x \\| p \\| species.*implemented|spatial\\(1 \\+ x \\| p \\| site.*implemented|animal\\(1 \\+ x \\| p \\| id.*implemented|relmat\\(1 \\+ x \\| p \\| id.*implemented" docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/design/01-formula-grammar.md docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md README.md ROADMAP.md NEWS.md
```

Results:

- `phylo-gaussian` passed with 334 assertions.
- `spatial-gaussian` passed with 209 assertions.
- `animal-relmat-gaussian` passed with 327 assertions.
- `structured-re-conversion-contracts` passed with 1960 assertions.
- `python3 tools/validate-mission-control.py` passed and reported 73
  structured RE q-series cells.
- `git diff --check` passed.
- The final positive-overclaim scan returned no hits.

## Tests Of The Tests

The provider tests check convergence, q=2 endpoint metadata, coefficient names,
structured SD labels, correlation labels, `corpairs()` coefficient columns,
`summary()$covariance`, direct profile targets, `structured_effects()`
endpoint members, and prediction contributions. The relmat test additionally
checks K/Q same-target runtime equality for the slope-only q=2 cell.

The conversion-contract test and mission-control validator require the four new
q-series rows, their native point-fit/extractor statuses, and planned
bridge/interval/coverage statuses. They also require claim-boundary wording for
slope-only scope, broad bridge support, interval reliability, coverage, REML,
and AI-REML.

## Consistency Audit

The formula grammar, q-series map, dashboard README, README, ROADMAP, NEWS, and
`structured_effects()` Rd now separate three cells that should not be conflated:

1. labelled intercept q=2 structured covariance;
2. labelled slope-only q=2 structured covariance;
3. labelled intercept-plus-slope q4/q8 structured covariance.

Only the first two have native point-fit/extractor evidence for the providers
named above. Bridge parity, interval reliability, and coverage remain planned
for the new slope-only q=2 rows.

## GitHub Issue Maintenance

No GitHub issue or PR state was changed. No staging, commit, push, undraft, or
merge action was taken.

## What Did Not Go Smoothly

One existing spatial negative test expected the old intercept-only rejection
message. The code now rejects labelled `1 + x` bivariate structured terms at
the exact one-coefficient q=2 guard, so the test was updated to assert that
boundary.

Running `devtools::document()` produced unrelated roxygen link and author-block
churn. Those generated edits were cleaned back out, leaving only the
`structured_effects()` value-schema update.

## Known Limitations

- No broad structured bridge support.
- No deterministic same-target fixture parity for the new q=2 slope-only cells.
- No interval reliability or coverage.
- No REML, AI-REML, native-TMB q4 REML, HSquared AI-REML, or non-Gaussian REML.
- No intercept-plus-slope structured q4/q8 covariance.
- No multiple structured slopes.
- No structured `rho12`.
- No DRAC execution or SR150 evidence.

## Next Actions

1. Add deterministic same-target fixture evidence for the exact q2 slope-only
   provider cells, starting with relmat K/Q and animal A/Ainv.
2. Design the larger coefficient-aware structured q4 slope block before opening
   labelled `1 + x | p | group` syntax.
3. Keep interval and coverage promotion blocked until there is denominator
   evidence and MCSE-calibrated coverage evidence.
