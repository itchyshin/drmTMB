# After Task: Binomial animal-slope provider equivalence

## 1. Goal

Check whether the native Bernoulli animal-slope SD route gives the same fitted result when one pedigree covariance is supplied as pedigree data, covariance `A`, or precision `Ainv`.

## 2. Implemented

No production code changed. A synthetic test now compares the three input forms for one q1 animal slope with `sd(id, level = "animal") ~ z`. It aligns group SD predictions by their group labels and confirms positive recovery of the SD slope.

## 3a. Decisions and Rejected Alternatives

The test derives covariance `A` from a synthetic pedigree and supplies `Ainv` as the inverse of the same matrix after a joint row and column permutation. Predictions are compared by group name rather than position because provider routes may return a different order. This slice adds a provider-equivalence check rather than claiming wider animal-model or cross-engine support.

## 4. Files Touched

- `tests/testthat/test-binomial-animal-slope-sd-regression.R` adds the independent pedigree fixture and provider comparison.
- `docs/dev-log/general-sd-regression/inventory.md` records this narrow result and corrects a stale Julia Tweedie failure note using its later passing reports.
- `docs/dev-log/check-log.d/2026-10-23-binomial-animal-slope-provider-equivalence.md` records the command and source binding.
- This report records the test boundary and remaining work.

## 5. Checks Run

- `OMP_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-slope-sd-regression")'`: 32 assertions passed, with no failures, warnings, or skips, in 42.0 seconds.
- `git diff --check` on the test and three documentation receipts: passed.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-10-23-binomial-animal-slope-provider-equivalence.md`: passed after the report was aligned to the required 12-section structure.
- `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py <absolute report path>`: 0 findings in 646 words; no em dashes.

## 6. Tests of the Tests

The initial provider comparison reached all three fits and confirmed equal likelihoods and SD coefficients. Its first failure was the test comparing prediction vectors in their provider-specific ordering. The corrected assertions match values by group name. The fixture also permutes `Ainv` labels relative to the observed factor order and requires a positive fitted SD slope. Existing tests in the same file retain negative checks for correlated animal blocks and mixing ordinary random effects with this route.

## 7a. Issue Ledger

An open-issue search for `animal slope SD regression binomial Ainv pedigree` returned no matching issues. No issue was changed. The central `docs/dev-log/check-log.md` was left untouched because preflight found 434 refs with divergent work on that file; the dated receipt records this slice.

## 8. Consistency Audit

The test formula, generated data, pedigree-derived matrix, inverse precision, and named SD predictions refer to the same animal groups and slope coefficient. The candidate inventory now records that the Julia Tweedie related-matrix test has later passing reports after its mode-polish repair; it no longer describes that route as currently failing. No user-facing syntax or behavior changed, so NEWS and public formula guides did not need edits.

## 9. What Did Not Go Smoothly

The first test draft passed `fx$pedigree` directly inside the formula marker, but structured formula objects require a named symbol. After binding the pedigree locally, the first meaningful comparison exposed only an ordering assumption in the test. Both issues were corrected before the passing run. The first report also used headings that the required checker does not accept; it has been rewritten to match the repository protocol.

## 10. Known Residuals

This is one fixed-seed native TMB Bernoulli q1 animal slope-only fixture. It does not establish a recovery grid, profile or bootstrap integrity for every provider input, Julia parity, other families or effect types, or interval calibration. The programme gates remain open. Shared central check-log ownership also remains with its active editors.

## 11. Team Learning

Compare structured-provider predictions by group labels rather than returned vector position. A joint permutation of precision-matrix labels gives a compact check that the formula path preserves group identity.

## 12. Cross-Product Coverage

This slice covers the native TMB `mu` endpoint for one Bernoulli animal slope-only effect with pedigree, `A`, and permuted `Ainv` providers. It checks fit likelihoods, SD coefficients, and group-named SD predictions. It does NOT cover other families, random-effect types, parameter endpoints, provider layouts, Julia, prediction or simulation methods beyond the group SD comparison, storage, profile/bootstrap refits, or interval calibration. The remaining cells stay open in `.unlazy/general-sd-regression/GATES.md`.
