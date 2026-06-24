# After Task: Q2 Slope Denominator Extension

## Goal

Run a small deterministic denominator-extension diagnostic for bivariate
Gaussian structured q2 slope-only `mu1`/`mu2` targets after the denominator
admission ledger, without promoting interval reliability, coverage, REML,
AI-REML, q4/q8, or broad bridge support.

## Implemented

- Added `tools/run-structured-re-q2-slope-denominator-extension.R`, a
  rerunnable two-variant Wald/profile diagnostic harness.
- Wrote the method-level artifact at
  `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-denominator-extension/structured-re-q2-slope-denominator-extension-results.tsv`.
- Added
  `docs/dev-log/dashboard/structured-re-q2-slope-denominator-extension.tsv`
  with 24 variant-target status rows.
- Wired the sidecar into `tools/validate-mission-control.py` and
  `tests/testthat/test-structured-re-conversion-contracts.R`.
- Updated the dashboard README, q-series completion map, and check log.

## Mathematical Contract

The diagnostic covers two deterministic fixture variants, `extension_seed_a`
and `extension_seed_b`, for the four structured providers and three q2 slope
targets per provider:

- `sd:mu:mu1:provider(0 + x | p | group)`
- `sd:mu:mu2:provider(0 + x | p | group)`
- `cor:provider:cor(mu1:x,mu2:x | p | group)`

Each variant runs Wald and endpoint-profile intervals. A row is marked
`extension_candidate` only when the target was already a
`diagnostic_denominator_candidate` in the denominator-admission ledger, the
extension fit has `pdHess = TRUE`, and both Wald/profile intervals are finite.
Rows held back by the earlier smoke profile failure remain
`not_admitted_from_smoke` even when the extension run is finite.

## Files Changed

- `tools/run-structured-re-q2-slope-denominator-extension.R`
- `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-denominator-extension/structured-re-q2-slope-denominator-extension-results.tsv`
- `docs/dev-log/dashboard/structured-re-q2-slope-denominator-extension.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-q2-slope-denominator-extension.R
air format tools/run-structured-re-q2-slope-denominator-extension.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
```

## Evidence Result

The harness wrote 48 method rows and 24 dashboard rows. All 24 dashboard rows
have finite Wald/profile diagnostics and `pdHess = TRUE`. Twenty rows are
`extension_candidate`; the animal and relmat correlation targets in both
variants remain `not_admitted_from_smoke` because the earlier smoke run had
endpoint-profile failure.

## Tests Of The Tests

The R conversion-contract test checks the 24-row sidecar, the 48-row raw
artifact, the 20/4 extension split, the link back to
`structured-re-q2-slope-denominator-admission.tsv`, the finite Wald/profile
method counts, and unchanged q-series interval, coverage, and denominator
policy statuses. The Python validator independently checks row identity,
variant settings, provider-specific claim boundaries, source paths, and linked
support-cell status.

## Consistency Audit

The dashboard README and q-series completion map call this a deterministic
denominator-extension diagnostic. The sidecar keeps
`coverage_status = not_evaluated` and does not claim coverage-evaluable
denominator evidence, interval reliability, coverage acceptance, REML,
AI-REML, q4/q8, or broad bridge support.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is internal q-series evidence-ladder
work.

## What Did Not Go Smoothly

The extension run itself was finite, including for the two correlation targets
held out by the earlier smoke profile failure. The sidecar deliberately keeps
those two targets out of denominator admission until the earlier failed profile
is explained or repeated away by a predeclared denominator rule.

## Team Learning

Denominator admission needs provenance, not just the newest finite diagnostic.
The held-out rows are a useful example: a later finite extension does not erase
an earlier failed smoke profile unless the evidence ladder explicitly says how
to reconcile repeated diagnostics.

## Known Limitations

This slice does not provide calibrated coverage, interval reliability, coverage
MCSE, REML, AI-REML, broad bridge support, range-estimating spatial support,
pedigree/Ainv bridge marshalling, relmat Q bridge marshalling,
intercept-plus-slope q4/q8 structured slope support, two-slope support, or
non-Gaussian structured slope support.

## Next Actions

Define the replicated denominator rule before running a larger q2 coverage
pre-grid: specify how many deterministic or random seeds are needed, how failed
profiles are retained in denominators, and what MCSE threshold would be needed
before any coverage claim. Keep SR150 blocked until coverage-evaluable
denominator evidence and MCSE-calibrated coverage evidence exist.
