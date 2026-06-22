# After Task: Phylo Extractor Status Fields

## Goal

Bank S029 by pinning summary and extractor status fields for phylogenetic q2
and q4 rows without promoting Wald or interval support.

## Implemented

Added focused assertions to `tests/testthat/test-phylo-gaussian.R` for
`corpairs()` default status fields, q2 `corpairs(conf.int = TRUE)` newdata
requirements, q4 `corpairs(conf.int = TRUE)` derived-interval status,
q4 `summary(fit)$covariance` covariance interval status, and block-diagonal
q2-plus-q2 point-only status.

Added `docs/dev-log/dashboard/phylo-extractor-status.tsv` and
`docs/design/184-phylo-extractor-status-fields.md`, then extended the
mission-control validator and start script so the extractor status table is
checked and served.

## Checks Run

```sh
Rscript -e 'devtools::test(filter = "phylo-gaussian", reporter = "summary")'
tools/validate-mission-control.py
git diff --check
```

Result: focused `phylo-gaussian` tests passed, mission-control validation
passed with the extractor status table, and `git diff --check` was clean.

## Consistency Audit

This is an extractor-status slice. It does not change model behavior, formula
grammar, REML support, bridge support, q4 support, interval coverage,
non-Gaussian REML wording, HSquared AI-REML status, or Ayumi-facing text.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use S030 to refresh and read back the live native phylo dashboard bundle.
