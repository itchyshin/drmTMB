# After Task: Structured Native ML q1 Evidence

## 1. Goal

Bank the first implementation/evidence tranche for the structured
random-effect balance arc: SR011-SR020, covering current native ML q1 smoke
evidence for `phylo()`, coordinate `spatial()`, `animal()`, `relmat()`, and
q1-only `phylo_interaction()`.

## 2. Implemented

SR011-SR020 are banked in
`docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`. Each row points
to the focused test file that currently exercises the relevant q1 fit surface.

No model code changed. This tranche banks current evidence for existing native
ML q1 support and keeps inference, REML, bridge, q2, and q4 claims separate.

## 3. Decisions and Rejected Alternatives

The main decision was to reuse the focused fitted-model tests instead of
duplicating q1 smoke tests. The existing tests already cover convergence,
positive structured SDs, profile-target visibility, prediction contributions,
diagnostics, and neighbouring unsupported-route errors.

I did not promote count-model q1 support into non-Gaussian REML language. Count
structured rows remain ML point/status evidence only.

## 4. Files Created or Changed

- `docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`
- `docs/dev-log/after-task/2026-06-22-structured-re-native-ml-q1.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

```sh
NOT_CRAN=true Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-phylo-gaussian.R"); testthat::test_file("tests/testthat/test-spatial-gaussian.R"); testthat::test_file("tests/testthat/test-animal-relmat-gaussian.R"); testthat::test_file("tests/testthat/test-phylo-interaction.R"); testthat::test_file("tests/testthat/test-count-structured-mu.R")'
```

Outcomes:

- `test-phylo-gaussian.R`: 269 pass.
- `test-spatial-gaussian.R`: 144 pass.
- `test-animal-relmat-gaussian.R`: 156 pass.
- `test-phylo-interaction.R`: 55 pass.
- `test-count-structured-mu.R`: 124 pass.
- The focused q1 tranche had zero failures, warnings, or skips.

Mission-control validation and `git diff --check` are rerun in the closing gate
for this combined structured-balance update.

## 6. Tests of the Tests

The focused files include actual fitted `drmTMB` objects, convergence and
`pdHess` checks where appropriate, named structured SD assertions,
profile-target checks, prediction contribution checks, and rejection tests for
planned neighbouring routes. The q1 evidence therefore checks more than parser
acceptance.

## 7. Issue Ledger

No GitHub issue was touched. This tranche is local evidence banking.

## 8. Consistency Audit

SR011-SR020 stay inside the native TMB ML q1 boundary. They do not claim native
REML, AI-REML, q2/q4 support, bridge parity, public optimizer controls, or
calibrated interval coverage.

## 9. What Did Not Go Smoothly

The only awkward part is that q1 count support is split across different test
files: `phylo_interaction()` count fits live with the interaction tests, while
spatial/animal/`relmat()` count fits live in `test-count-structured-mu.R`.
That split is acceptable, but future slice ledgers should keep the evidence
paths explicit.

## 10. Known Limitations and Next Actions

SR021 starts the Native ML q2 tranche. q2 scale, q4 location-scale, structured
slopes, exact-Gaussian REML, inference coverage, and R-to-Julia bridge parity
remain queued.

## 11. Team Learning

For q1 structural-dependence evidence, fitted-model tests are more valuable
than grammar-only evidence. They show whether the label, SD, contribution,
diagnostic, and neighbouring-error surfaces move together.
