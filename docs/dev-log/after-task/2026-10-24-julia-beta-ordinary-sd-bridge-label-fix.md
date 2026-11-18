# After Task: Julia Beta ordinary SD bridge label repair

## 1. Goal

Repair the Julia bridge label mismatch that prevented selected-target Beta ordinary mean intercept and independent-slope SD models from fitting, then preserve focused cross-engine evidence.

## 2. Implemented

For Beta, the R bridge now maps the sole SD block to the canonical Julia label `sd`, including formulas that select an explicit random-effect coefficient. A test checks both selected intercept and numeric-slope payload labels. The existing live tests then exercise point recovery and public group-SD outputs across native TMB and Julia.

## 3a. Decisions and Rejected Alternatives

The family fitter requires exactly one SD target, so the bridge uses its canonical `sd` label instead of forwarding the generic hashed selected-target label. The repair leaves Beta family admission rules unchanged.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-beta-sd.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/general-sd-regression/evidence/beta-ordinary-sd-bridge-20261024/`
- `docs/dev-log/after-task/2026-10-24-julia-beta-ordinary-sd-bridge-label-fix.md`

## 5. Checks Run

- Before the fix, the opt-in live bridge filter failed at `drm_julia_bridge_check_coef_labels` for selected intercept and slope targets. Its console and source manifests are retained.
- After the fix, `DRMTMB_JULIA_TESTS=true` with the paired candidate worktree and Julia 1.10 passed the `julia-beta-sd` filter: two live Julia fits and 26 expectations, zero failures, and eight existing `beta()` deprecation warnings. The console and matching before/after source manifests are retained in the evidence directory.
- The same filter without opt-in Julia passed the pure payload-label regression test; live tests were skipped in that invocation.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed; 64 receipts linked to 53 distinct candidate rows, 19,065 unlinked.
- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`: 11 tests passed.
- `git diff --check` on the touched implementation, test, and documentation paths: passed.
- `graft ask` could not run because the CLI is not installed. The repository routing script reported that this checkout has no `LOAD-FIRST` manifest.

## 6. Tests of the Tests

The pure payload-label test failed before the code change because both selected formulas emitted a hashed `sdtarget_*` key instead of `sd`. The retained live failure independently reproduced the same defect before the repair. After the fix, the focused live filter checked both coefficient choices and public output behavior.

## 7a. Issue Ledger

Searched open GitHub issues with `gh issue list --state open --search 'Beta selected SD target Julia bridge' --limit 8`; no matching issue was returned. No issue was opened, changed, or closed.

## 8. Consistency Audit

This repair does not change formula grammar, model equations, family admission, or user-facing syntax. Exact inventory scans were run with `rg -n -i 'beta.*(intercept|slope).*sd|beta.*julia.*(sd|bridge)|julia.*beta.*(sd|bridge)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd tests R man` and `rg -n 'sdtarget_|family_type.*beta|canonical.*sd' R/julia-bridge.R tests/testthat/test-julia-beta-sd.R`. The candidate inventory and generated evidence summary report 64 receipt records and 53 linked rows. The frozen candidate universe and its statuses were not changed. No user documentation or pkgdown navigation changed because the public syntax and supported shape were unchanged.

## 9. What Did Not Go Smoothly

The first live run exposed the mismatch before any optimization began. Eight existing `beta()` deprecation warnings remain in the focused test output; they do not affect the fit result. The Graft executable and a repository `LOAD-FIRST` manifest were unavailable in this checkout.

## 10. Known Residuals

The four linked Beta intercept/slope rows remain unreviewed evidence. This result covers only the tested ordinary mean intercept and independent numeric slope on the paired dirty development candidates. It does not establish structured or correlated Beta effects, other endpoints, interval calibration, or general Julia parity. Coverage validation remains a deferred follow-up.

## 11. Team Learning

Selected coefficient identity and engine payload block identity are separate contracts. The family-specific payload label must follow the fitter's target representation even when the public formula selects one member explicitly. Memory receipt: the user authorized continuing local implementation; the candidate remains dirty and no source was committed. Golden Set: not checked because this label-repair slice did not investigate a known Golden Set mistake class.

## 12. Cross-Product Coverage

Covers: the tested paired native TMB and Julia Beta ordinary mean intercept and independent numeric-slope SD bridge paths, selected-target labels, point recovery, group-SD output, new-data prediction for the intercept fixture, and save/reload for the intercept fixture.

Does NOT cover: interval coverage, structured or correlated Beta random effects, distributional endpoints other than `mu`, broad Beta parity, or completion of the general predictor-dependent random-effect SD goal.
