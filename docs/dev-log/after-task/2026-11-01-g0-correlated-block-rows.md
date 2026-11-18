# After Task: G0 correlated-block rows for phylo, relmat and spatial

## 1. Goal

Extend the finite SD-regression universe so that same-endpoint correlated
intercept-slope (q2) blocks exist for the phylo, relmat and coordinate-spatial
providers, as `animal_correlated_block` has since 2026-10-29, and link the
existing 2026-11-01 Gaussian receipt to the rows it covers.

## 2. Implemented

- `mechanism-templates.tsv`: added `phylo_correlated_block`,
  `relmat_correlated_block` and `spatial_correlated_block`.
- `block-rules.tsv`: added rules `P2-phylo-within`, `R2-relmat-within` and
  `SP2-spatial-within` (native and Julia rows each, six rows).
- `tools/general-sd-regression/universe.py`: new `WITHIN_ENDPOINT_Q2_BLOCKS`
  tuple replaces the three `== "animal_correlated_block"` checks; the summary
  text now computes the named-rule count instead of hard-coding 31.
- Regenerated `required-rows.tsv` and `required-universe.md` with the
  generator: 20,350 to 21,246 rows (896 new), 28 to 31 templates, 150 to 156
  rule rows, 31 to 34 named rules. Every one of the 20,350 earlier row keys is
  present and byte-identical (checked by comparing the old and new TSV by
  `row_key`: 0 missing, 0 changed). The 896 new rows are all `unresolved` or
  `blocked_base_plumbing`; none is `required`, and `direct_sd_claim` is `none`
  throughout.
- Appended four ledger lines to `direct-sd-evidence.tsv` (status
  `unreviewed`) linking native Gaussian `relmat_correlated_block` (K covariance)
  and `phylo_correlated_block` (tree), each for `mu:I` and `mu:x1`, to the
  existing evidence directory `evidence/gaussian-structured-q2-sd-20261101d/`.
  Receipt, manifest and test digests are copied from that directory's existing
  ledger lines; no receipt file was touched. The regenerated
  `direct-sd-evidence-summary.md` reports 398 records and 309 linked rows.
- Correction notes appended to `universe-contract.md`,
  `block-dimension-contract.md` and `universe-final-review.md`. Earlier counts
  there are left as history.

## 3. Decision that differs from the brief

The brief expected correlated q2 routes for Poisson, NB2, Binomial, Gamma and
Beta. Reading the tests shows otherwise. In
`test-count-structured-q2-more-providers-sd.R`,
`test-binomial-phylo-spatial-q2-sd.R`, `test-binomial-relmat-q2-sd.R` and the
Gamma and Beta phylo, relmat and spatial q2 tests, the oracle prior is
`kronecker(diag(2), K)` (two independent fields, no rho), and the count test
refuses the labelled `relmat(1 + x | p | id)` form. Those routes are already
represented by the `*_numeric_slope` templates, so none was linked to the new
rows. The only correlated native routes at the pin for these providers are
Gaussian relmat and phylo (labelled `(1 + x | p | id)`, shared rho,
`test-gaussian-structured-q2-sd.R`). The native spatial q2 SD route is refused
in that file, so `spatial_correlated_block` is a pure obligation with no
evidence link. The earlier OPTIONAL patch cited the Gamma and Beta tests as
shape sources for the correlated rules; that was wrong and the pins here cite
the Gaussian test instead. Only the Gaussian `mu` rows are linked; the Gaussian
`sigma` rows and the relmat Q-precision rows have no test and stay unlinked.

## 4. Pinned tool tests updated (deliberate universe correction)

`tools/general-sd-regression/tests/test_universe.py`, with a comment at each
change: mechanism-templates hash, block-rules hash, Julia Binomial probit and
cloglog link-variant count 144 to 160, still-blocked count 78 to 94 (the same 16
new Julia non-logit rows, blocked because no non-logit base route is admitted),
and "expected 150" to "expected 156" block-dimension rules. No tolerance was
loosened and no assertion removed. One new test,
`test_phylo_relmat_spatial_within_endpoint_correlated_q2_rows`, checks the
rule ids, layout, q shape, status set, `direct_sd_claim`, and coordinates-only
spatial input.

## 5. Checks run (private copy, Mac, one process at a time)

- `python3 tools/general-sd-regression/universe.py`: wrote 21,246 rows.
- `python3 tools/general-sd-regression/tests/test_universe.py`: 23 tests OK.
- `test_inventory.py`: 5 OK. `test_reconcile_evidence.py`: 11 OK.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: pass,
  candidate_rows=21,246, linked_rows=309, unlinked_rows=20,937,
  evidence_records=398 (before: 20,350 / 305 / 394).
- `NOT_CRAN=true` single-process `testthat::test_file()` on `tests/testthat/test-gaussian-structured-q2-sd.R`: 64 passed, 0 failed, 0 errors, 0 skipped (native TMB; Julia bridge not exercised). This matches the 64 in the existing receipt.

## 6. Does not cover

No R code, likelihood, formula grammar or Julia source changed. No calibration,
recovery or parity claim. The new rows are obligations, not support. Julia
engine rows are classified only by the generic link rules. The universe is
still unreviewed by an independent reviewer (G0 stays open).

## 7. Open items

- Decide whether the Gaussian `sigma` endpoint and relmat Q-precision rows need
  their own tests.
- Decide whether a native correlated spatial q2 SD route is wanted; until then
  `SP2-spatial-within` rows remain unresolved.
- Independent review of the 896 new rows.
