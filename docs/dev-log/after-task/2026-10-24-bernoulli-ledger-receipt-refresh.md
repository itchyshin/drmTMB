# After Task: Bernoulli evidence receipt refresh

## Goal

Restore source-bound evidence for the existing Bernoulli R-to-Julia bridge rows after their test and implementation sources changed.

## Implemented

Refreshed the three existing Binomial/Bernoulli evidence rows using one current-source rerun. The rows remain `unreviewed`; no capability row was promoted and no programme gate was closed.

## Mathematical Contract

No model or likelihood code changed. The receipt covers the existing logit Bernoulli mean random-intercept, numeric-slope, and tested unlabelled correlated q2 bridge checks only.

## Files Changed

- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md` (regenerated)
- `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261024-rerun/`
- `docs/dev-log/check-log.md` and `docs/dev-log/check-log.d/2026-10-24-bernoulli-ledger-receipt-refresh.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- This report

## Checks Run

The focused command was `devtools::test(filter = "julia-binomial-sd", reporter = "summary", stop_on_failure = TRUE)` with the Julia bridge enabled and one Julia/OpenBLAS thread. It exited 0; five live Julia bridge tests ran with no failures or skips. Two numerically singular Hessian warnings occurred at variance/dispersion boundaries. The test output, receipt, and stable before/after SHA-256 manifests are in `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261024-rerun/`.

The evidence reconciler passed: 19,118 candidate rows, 43 receipt records, 34 linked rows, and 19,084 unlinked rows. This is an evidence-link count, not a completion fraction.

## Tests Of The Tests

The existing focused bridge suite was rerun against the current candidate source. No test code changed during the run. The suite exercises fitting and public bridge outputs; it is not an independent calibration study.

## Consistency Audit

The refreshed rows retain `unreviewed` status and narrow Bernoulli scope. The result summary records the boundary warnings and states that it does not establish calibrated intervals or broad family support. No user-facing syntax, model equations, or docs changed.

## GitHub Issue Maintenance

No issue action was taken because this evidence-only repair changes no package behavior and claims no new capability.

## What Did Not Go Smoothly

The old receipt failed validation because 12 of its 167 pinned source files and the test source had changed. An initial focused rerun passed, then a second run captured stable before/after manifests for the replacement receipt.

## Team Learning

Refresh a source-bound receipt only after rerunning the exact focused suite and capturing before/after source hashes. Do not repair stale evidence by editing recorded hashes alone.

## Known Limitations

This does not close a programme gate. Coverage calibration remains deferred and unvalidated. The full family, endpoint, effect, provider, layout, and two-engine universe remains open; 19,084 candidate rows have no linked receipt.

## Next Actions

Continue closing the frozen capability universe with current-source tests and paired-engine evidence. Keep the Bernoulli gate distinct from broad programme completion.
