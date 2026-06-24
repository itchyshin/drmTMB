# After Task: Structured Native ML q4 Evidence

## 1. Goal

Bank SR031-SR040 for native TMB ML q4 structured random-effect status across
`phylo()`, coordinate `spatial()`, `animal()`, and `relmat()`.

## 2. Implemented

SR031-SR040 are banked in
`docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`.

`docs/design/209-structured-q4-native-ml-status.md` records the q4 boundary:
constant all-four q4 blocks have current point/extractor evidence, while q4
correlation intervals, calibrated coverage, native q4 REML, bridge parity, and
non-Gaussian q4 remain unclaimed.

## 3. Decisions and Rejected Alternatives

I banked q4 as point/extractor evidence, not as interval evidence. The tests
show four endpoint SDs and six latent correlation rows, but q4 correlations
remain derived targets with `profile_ready = FALSE`.

I did not treat one-observation scale-side warnings as support failures. They
are diagnostics that steer users toward fixed-effect scale or more replication.

## 4. Files Created or Changed

- `docs/design/209-structured-q4-native-ml-status.md`
- `docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`
- `docs/dev-log/after-task/2026-06-22-structured-re-native-ml-q4.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

The focused fitted-model tests were run in the SR011-SR020 tranche and also
cover the q4 point/extractor rows:

```sh
NOT_CRAN=true Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-phylo-gaussian.R"); testthat::test_file("tests/testthat/test-spatial-gaussian.R"); testthat::test_file("tests/testthat/test-animal-relmat-gaussian.R"); testthat::test_file("tests/testthat/test-phylo-interaction.R"); testthat::test_file("tests/testthat/test-count-structured-mu.R")'
```

Outcomes:

- `test-phylo-gaussian.R`: 269 pass.
- `test-spatial-gaussian.R`: 144 pass.
- `test-animal-relmat-gaussian.R`: 156 pass.
- `test-phylo-interaction.R`: 55 pass.
- `test-count-structured-mu.R`: 124 pass.
- The focused run had zero failures, warnings, or skips.

Mission-control validation and `git diff --check` are rerun in the closing gate
for this combined structured-balance update.

## 6. Tests of the Tests

The q4 tests check fitted objects, finite objectives, endpoint SD names, six
latent correlation rows, `corpairs()`, `summary(fit)$covariance`, q4 diagnostic
rows, derived-correlation target status, interval unavailability, and partial
or unlabelled q4 rejection paths.

## 7. Issue Ledger

No GitHub issue was touched. This is local evidence banking.

## 8. Consistency Audit

SR031-SR040 stay inside native TMB ML q4 point/extractor scope. They do not
promote native q4 REML, HSquared AI-REML, R-to-Julia bridge parity, public
optimizer controls, non-Gaussian q4, or interval coverage.

## 9. What Did Not Go Smoothly

The slice label "q4 one-observation warning" is broader than the current
structured q4 tests. The durable evidence lives in known limitations and the
scale-phylo diagnostic ledger, so this tranche records it as a diagnostic
boundary rather than adding a new unsupported test fixture.

## 10. Known Limitations and Next Actions

SR041 starts the structured slopes tranche. q4 predictor-dependent
correlations, q4 direct correlation intervals, q4 REML, and q4 bridge parity
remain queued.

## 11. Team Learning

For all-four structured blocks, point/extractor success and interval readiness
must be different rows. Otherwise a working `corpairs()` table can be mistaken
for a supported interval workflow.
