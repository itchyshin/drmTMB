# After Task: Ayumi Native ML Bootstrap Accounting

## 1. Goal

Bank A026 by adding a small native ML bootstrap plumbing smoke that records
refit counts and per-refit diagnostics for univariate phylo targets.

## 2. Implemented

Added a focused `skip_on_cran()` test in
`tests/testthat/test-phylo-gaussian.R` for two native TMB ML Gaussian cells:

- mean-side `sd:mu:phylo(1 | species)`;
- scale-side `sd:sigma:phylo(1 | species)`.

Each target uses `confint(method = "bootstrap", R = 2)` and checks
`bootstrap.n`, `bootstrap.failed`, and the `"bootstrap.diagnostics"` attribute
for `refit_status`, `target_available`, and `draw_used`.

## 3a. Decisions and Rejected Alternatives

The test is deliberately a plumbing smoke, not a coverage study. It uses two
refits and stays out of CRAN runs. The matched mean-plus-scale cell is not
promoted here because tiny matched bootstrap probes can return structured
partial/refit-failure rows; that belongs with recovery and boundary-status
evidence, not this plumbing gate.

## 4. Files Touched

- `tests/testthat/test-phylo-gaussian.R`
- `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`
- `docs/dev-log/after-task/2026-06-22-ayumi-native-ml-bootstrap-accounting.md`

## 5. Checks Run

```sh
air format tests/testthat/test-phylo-gaussian.R
git diff --check
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "phylo-gaussian", reporter = "summary")'
```

The focused phylogenetic Gaussian tests passed.

## 6. Tests of the Tests

The test would fail if bootstrap intervals stopped attaching diagnostics, if
successful refit counts stopped matching the returned interval row, or if
target availability was lost during refits.

## 7a. Issue Ledger

No GitHub issue was edited. The row is local mission-control evidence for the
Ayumi balance arc and does not change the public reply state.

## 8. Consistency Audit

The ledger row uses `plumbing only no coverage claim` as its boundary. Known
truth recovery, matched-cell bootstrap behaviour, scale-clamp diagnostics, and
native ML summary rows remain separate A027-A030 gates.

## 9. What Did Not Go Smoothly

A hand-built ad hoc tree used during probing was not ultrametric and was
rejected correctly. The committed test uses existing ultrametric package
fixtures instead.

## 10. Known Residuals

This test has only two bootstrap refits and does not evaluate interval
coverage, MCSE, matched mean-scale bootstrap stability, or Ayumi-scale runtime.

## 11. Team Learning

Bootstrap support language should name the accounting layer first: requested
refits, successful refits, failed refits, target availability, and per-refit
messages. Coverage and scientific interpretability are later claims.
