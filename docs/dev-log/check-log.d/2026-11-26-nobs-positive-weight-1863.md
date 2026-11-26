# 2026-11-26 — nobs positive-weight count (#1863)

## Scope

Implemented approved 26 Nov decision: `nobs()` and `logLik` `nobs` attribute count
rows with likelihood weight `> 0`; `BIC()`, `df.residual()`, and `aicc()` use
that count. Documentation keeps non-frequency-weight wording.

## Evidence

Cloud agent: `test-fix-1863-weights-not-frequency.R` (2 tests, 83 expectations),
`test-fix-1699-nobs-zero-weight.R` (7 tests, 73 expectations), plus
`test-model-comparison.R`, `test-gaussian-location-scale.R`, `test-poisson-mean.R`
with `pkgload::load_all()`.

No `tools/recertify-c17.py` run; no capability-ledger edits.