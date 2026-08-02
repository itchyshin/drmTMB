# After Task: B4-CI C4 canonical Lane B integration

## Goal

Canonically promote only the approved final 23 retained Lane B cells from the immutable source `574c1108e16e3b0fe4ba88e254a34673508db901`, on frozen main `f41dfc01a812af1294ee86790dc3e8d39e412c50`.

## Implemented

`tools/integrate_b4_ci_c4.py` imports the ordered C4 allowlist and exactly 23 matching evidence rows, 23 verified-to-verified transitions, and 69 receipt/trace/interval blobs. The approved packet is `9b9f30f089214e160db1bb1344bbd313440c683c8f35056cf2b1c6b40f245525`.

## Mathematical Contract

Each row claims one finite, ordered, unclamped `tmbprofile` interval for its named direct target under its retained fixture. This is not coverage, calibration, inference readiness, provider-wide support, or a broader formula claim.

## Files Changed

The C4 importer/test/manifest, the capability ledger and its regenerated surfaces, 69 source-bound artifact blobs, and the inherited C3 later-cohort verifier. No package code, formulas, public API, coverage, missing-response, association, Lane A/C, or external dashboard-overlay file changed.

## Checks Run

- `python3 -m unittest tools.tests.test_capability_ledger tools.tests.test_b4_ci_c1 tools.tests.test_b4_ci_c2 tools.tests.test_b4_ci_c3 tools.tests.test_b4_ci_c4`
- C1 current, C2/C3 later-cohort, and C4 exact verifiers
- `python3 tools/capability_ledger.py --check`
- `git diff --check`

## Tests Of The Tests

The new C4 test rejects an unapproved ID, B3/exclusion/association/C17/C3 changes, a mismatched receipt target, broadened claim wording, and missing evidence or transition rows.

## Consistency Audit

The C4 source closure is 69 distinct blobs with zero absolute-path replacements. Current `interval_feasible` is 161: C4 adds 11 point-fit and 12 diagnostic-only rows to the post-C3 global 138. Targeted stale-wording search covered `B4-CI|point_fit_recovery.*interval_feasible|interval_feasible.*point_fit_recovery` across README, ROADMAP, NEWS, design, dev-log, and vignettes; historical counts remain historical reports rather than live claims.

## GitHub Issue Maintenance

No issue was opened: this is the approved final cohort of the existing B4-CI PR sequence. The next external action is one C4 PR and its normal CI gate.

## What Did Not Go Smoothly

The inherited frozen-census guard and B3 paired-mu1 guard stopped the first regeneration, as intended. C4 updates them narrowly to 80 frozen point-fit rows and permits only `mc-0101`, `mc-0145`, and `mc-0167` as separately C4-evidenced paired rows.

## Team Learning

Later cohorts must make earlier exact verifiers explicitly later-cohort-aware rather than weakening their original exact baseline checks.

## Known Limitations

All deferred B4 boundaries remain deferred. The canonical claim remains interval feasibility only.

## Next Actions

Commit, push `codex/b4-ci-c4-exact-23`, open the C4 PR, require fresh CI on its unchanged head, merge only when green and mergeable, then perform the complete 108-cell reconciliation audit.
