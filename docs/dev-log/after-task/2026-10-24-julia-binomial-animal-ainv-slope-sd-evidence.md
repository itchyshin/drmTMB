# After Task: Julia Binomial animal-slope Ainv evidence registration

## 1. Goal

Link the existing focused Julia test for Binomial animal-slope SD regression with direct precision input to its exact required capability row.

## 2. Implemented

Copied the Julia receipt, console log, source snapshots, and test into the drmTMB evidence tree. Added one hash-verified, unreviewed `focused_test` record for the Julia Binomial logit animal numeric slope with `Ainv_precision`.

## 3a. Decisions and Rejected Alternatives

The tested random slope has covariance `D A D`, with `D = diag(exp(W alpha))`. Supplying `Ainv = A^{-1}` must reproduce the same fitted and simulated route as supplying `A`. I kept the record `unreviewed` rather than treating test success as independent claim review. The receipt covers one Julia animal-slope cell only.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-ainv-slope-20261024/`: copied receipt, command, console log, source snapshots, test, and source manifest.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and `direct-sd-evidence-summary.md`: one row added and evidence counts regenerated.
- `docs/dev-log/check-log.d/2026-10-24-julia-binomial-animal-ainv-slope-sd-evidence.md`.
- `LOOP/lanes/general-sd-regression/checkpoint.md`.
- This report.

## 5. Checks Run

- Rechecked all four Julia source and test hashes against the receipt before copying; all matched.
- `python3 tools/general-sd-regression/reconcile_evidence.py --summary docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`: passed with 19,118 candidate rows, 48 evidence records, and 39 distinct rows linked.
- The existing Julia test receipt records 10/10 assertions passing in 15.3 seconds. This evidence-registration step did not rerun that fit.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <absolute report path>`: required report structure passed. Its acceptance-ledger result is `UNKNOWN` because no runnable ledger node/check was present; it does not satisfy a programme gate.

## 6. Tests of the Tests

The copied test contains A/Ainv fit equivalence, named SD prediction, a seeded simulator oracle, and one bootstrap refit. Its exact copied-file hash is bound in the source manifest. No test code changed in this step.

## 8. Consistency Audit

The exact required row was unique and remains `direct_sd_claim=none`; the new receipt is `unreviewed`. The test is Julia-only and supports no R/TMB parity or coverage claim. No implementation, public documentation, or family support claim changed.

## 7a. Issue Ledger

No issue action was needed for evidence registration of an existing route. No issue was opened, commented on, or closed.

## 9. What Did Not Go Smoothly

The shared lease registry took about a minute to grant the exact-path claim. The `graft` command was unavailable in this shell, so the target was resolved from the frozen required-row table and checked by the reconciler. The after-task checker passed its structure check but returned `UNKNOWN` for acceptance because no runnable ledger node/check was present.

## 11. Team Learning

Register narrow test receipts against the exact provider, endpoint, effect, and engine row. Keep the test unreviewed until an independent reviewer checks the claim boundary.

## 10. Known Residuals

This record does not establish R/TMB parity, other Binomial links or providers, broad family support, calibrated intervals, or a programme gate. The linked-row count is an evidence join, not a completion percentage.

## 12. Cross-Product Coverage

This evidence entry covers the Julia Binomial logit animal numeric-slope route with `Ainv_precision` only. It does NOT cover native TMB, the R-to-Julia bridge, another link, endpoint, provider, layout, or response family. No user-facing documentation, pkgdown navigation, NEWS, or design contract changed because this step only registers evidence for an existing Julia route.

## Next Actions

Review the R-to-Julia Poisson animal-slope `Ainv` bridge diff and its ownership before any edit. The existing same-data parity test is the candidate check; the bridge currently appears to block that route before matrix marshalling.
