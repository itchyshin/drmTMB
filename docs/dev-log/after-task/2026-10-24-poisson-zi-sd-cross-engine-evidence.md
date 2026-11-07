# After Task: Poisson ZIP SD cross-engine evidence

## Goal

Establish current-source evidence for the ordinary mean-intercept SD rows in the zero-inflated Poisson route on native TMB and Julia.

## Implemented

Added one source-stable cross-engine test receipt and linked exactly the native and Julia `zi_poisson`, `mu`, iid-intercept candidate rows. Both rows remain unreviewed. No model code or public support claim changed in this evidence task.

## Mathematical Contract

For each group g, the ordinary mean random intercept has variance `exp(2 * (W_g alpha))`. The ZIP zero-inflation predictor remains fixed-effect-only. This evidence covers one ordinary mean intercept only.

## Files Changed

- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md` (regenerated)
- `docs/dev-log/general-sd-regression/evidence/poisson-zi-sd-cross-engine-20261024/`
- `docs/dev-log/check-log.md` and `docs/dev-log/check-log.d/2026-10-24-poisson-zi-sd-cross-engine-evidence.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- This report

## Checks Run

The source-stable command was `devtools::test(filter = "julia-poisson-zi-sd-regression", reporter = "summary", stop_on_failure = TRUE)` with the paired Julia candidate and one Julia/OpenBLAS thread. It exited 0; one live Julia bridge test passed with no failures or skips. Before/after manifests match for 169 source files. The receipt and console are in `docs/dev-log/general-sd-regression/evidence/poisson-zi-sd-cross-engine-20261024/`.

The reconciler passed: 19,118 candidate rows, 45 receipt records, 36 linked rows, and 19,082 unlinked rows. These counts measure evidence linkage, not implementation completion.

## Tests Of The Tests

The bridge fixture fits both engines to the same synthetic data and checks convergence, the positive SD-predictor coefficient, cross-engine coefficient agreement, group and observation-level SD outputs, target names, and the absence of a residual `sigma`. The current receipt does not include the separate Julia scalar-integration or simulation-oracle test.

## Consistency Audit

The tested boundary is one ordinary `mu` random intercept, fixed-effect-only `zi`, and no offsets. ZIP slopes, structured ZIP effects, hurdle models, and calibrated uncertainty remain unverified. The relevant Julia family/tutorial/navigation files have concurrent foreign refs, so I left user-facing docs untouched and sent the DRM work lane a coordination note requesting a doc owner. The R NEWS still contains a statement that Julia ZIP SD parity is open and needs correction after the owner handoff.

## GitHub Issue Maintenance

No issue action was taken because this evidence-only update changes no package behavior. The coordinated docs and stale NEWS wording remain open work.

## What Did Not Go Smoothly

A prior reviewer summary described a group-versus-row prediction comparison. The current test compares row-level predictions with row-level fitted scales and separately checks group-level scales, so that concern does not apply to this source. The full docs paths are concurrently edited by other refs and were not changed.

## Team Learning

Check the exact current test expression before carrying forward a review finding. Source-bound receipts must pin both engine trees and both test files for a bridge claim.

## Known Limitations

This evidence closes no programme gate and does not validate interval coverage. The overall family, endpoint, effect, provider, layout, and engine universe remains open. User-facing ZIP SD documentation is still pending the docs-lane handoff.

## Next Actions

Get the docs-path ownership handoff, add a runnable bounded ZIP example, and continue the full capability matrix. Keep the current ZIP evidence limited to the tested intercept route.
