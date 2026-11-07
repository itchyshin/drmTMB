# After Task: Current-Source Gamma SD Bridge Evidence

## 1. Goal

Refresh exact evidence for Gamma random-effect SD regression through native TMB and the Julia bridge, and reconcile the results to the frozen capability rows.

## 2. Implemented

No model code changed. Three synthetic checks now have current-source receipts: an ordinary random intercept, an independent numeric random slope, and a phylogenetic random intercept. The active evidence overlay links the native and Julia rows separately. Two older Gamma receipts with stale test-file hashes and two earlier phylogenetic receipts superseded by the combined run were preserved in an archive and removed from the active overlay.

## 3a. Decisions and Rejected Alternatives

No parameterization changed. These tests exercise predictor-dependent SDs on the log-SD scale, using the existing Gamma log-link model and existing random-effect or phylogenetic covariance. The phylogenetic test keeps the tree kernel as supplied; alternate kernel scaling was outside this slice. I left `src/bridge.jl` untouched because other refs carry changes there and its handover marker identifies another owner.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/gamma-phylo-point-parity-20261022/`: captured the exact test output, recorded both successful runs in the source manifest, and preserved four superseded receipt rows.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and `direct-sd-evidence-summary.md`: replaced stale Gamma receipts with six current-source engine-by-mechanism receipts.
- `docs/dev-log/check-log.d/2026-10-22-gamma-phylo-point-parity-isolated.md`: recorded commands and outcomes.

## 5. Checks Run

- Three filtered `testthat::test_file()` runs passed: Gamma ordinary intercept, Gamma independent numeric slope, and Gamma phylogenetic intercept. Each ran one live Julia fit and its matched native TMB fit; each test reported 12 passing expectations.
- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`: 10 tests passed.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed with 19,118 frozen rows, 11 rows linked to receipts, and 19,107 without linked receipts.
- Rechecked all 198 source entries against the captured native and Julia worktrees: zero missing or changed files; the current test-file hash matches the manifest.

## 6. Tests of the Tests

Each synthetic fixture compares the same data and formula across TMB and Julia. The ordinary-intercept check verifies the SD coefficient direction and grouped and row-level outputs. The slope check verifies its positive direction, an absolute difference below 0.6 from the planted 0.5 coefficient, and cross-engine agreement. The phylogenetic check compares coefficient names, SD coefficients, and tip-level predictions. Each mechanism has one synthetic dataset; the checks include no independent likelihood oracle or multi-replicate recovery study.

## 7a. Issue Ledger

Reviewed open issue [#1520](https://github.com/itchyshin/drmTMB/issues/1520), which tracks random effects in `rho12` and planned slope-specific SD formulas. It remains open because this evidence slice does not finish that scope. No issue comment was posted.

## 8. Consistency Audit

The evidence summary explicitly says receipts do not establish general support, identifiability, admission, or calibrated coverage. No user-facing documentation or capability claim changed. Coverage remains deferred. Post-draft self-review of this report (2026-10-22): perceived AI-like style 2/10, medium confidence. The phrase “11 rows linked to receipts” is specific and traceable, so no wording repair was needed. Scientific gate: not applicable to this evidence report. Factual gate: pass against the saved test output, manifest, and reconciliation. Reference gate: not applicable; no external references are cited.

## 9. What Did Not Go Smoothly

Passing `desc` through `devtools::test()` failed before fitting because that wrapper treats it as an unsupported filter argument. Switching to `testthat::test_file()` isolated the cases correctly. Reconciliation then found two older receipts tied to a previous version of the test file; the original records were retained in the archive and replaced with current-source receipts. A first ledger update also needed its manifest digest refreshed after the manifest gained the combined-run receipt; reconciliation caught the mismatch before the summary was regenerated.

## 10. Known Residuals

These six receipts cover three Gamma rows per engine, each from one synthetic dataset. They do not validate interval coverage, broad Gamma support, alternative phylogenetic inputs, animal or spatial effects, correlated blocks, or Julia's Gamma animal-slope path. A prior full-file run recorded a Gamma animal-slope schema-label error in Julia; this task did not rerun or repair that case because `src/bridge.jl` has unmerged work across multiple refs and an ownership handover marker. G2 is the only passed programme gate; G3, G4, and G6–G8 remain open. Coverage calibration remains deferred.

## 11. Team Learning

When a test file changes, old receipts should not remain in the active evidence join with a mutable path and obsolete hash. Archive the old row metadata, rerun the exact cases against current sources, and let the reconciliation check verify the replacement before reporting counts.

## 12. Cross-Product Coverage

This evidence slice covers three Gamma `mu` rows per engine: one iid intercept, one independent numeric slope, and one tree-input phylogenetic intercept. It does NOT cover the other response families, SD endpoints, random-effect providers, block structures, or remaining Julia/TMB capability combinations. It does NOT cover calibrated interval coverage, which remains deferred. Continue the family/effect row audit using exact current-source receipts. Coordinate ownership of the Julia bridge before diagnosing or changing the separate Gamma animal-slope route; the full goal remains active.
