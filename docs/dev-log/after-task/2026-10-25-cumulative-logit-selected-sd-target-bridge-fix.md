# After Task: Cumulative-logit selected SD target bridge fix

## 1. Goal

Repair the Julia bridge labels for selected cumulative-logit location SD targets, and record the focused evidence without promoting the broader family or inference claims.

## 2. Implemented

The R bridge now sends the canonical Julia `sd` block label for cumulative-logit SD formulas, including explicitly selected intercept and numeric-slope targets. The change aligns the bridge payload with the single scale block exposed by the cumulative-logit fitter. It does not change the likelihood or model parameterization.

## 3a. Decisions and Rejected Alternatives

The selected target keeps its existing `sdtarget_*` identity inside the R model object; the bridge translates it to the canonical Julia `sd` block only at the transport boundary. No likelihood or covariance parameterization change was made. Broader cumulative-logit formula changes were rejected as out of scope for a label-marshalling defect.

## Mathematical Contract

For each selected coefficient, the model remains `log(tau_g) = W_g alpha`. This repair changes only the identity used to map a fitted SD target between R and Julia; the formula design, covariance, and likelihood are unchanged. Evidence is limited to one complete-response ordinary location intercept and one numeric location slope.

## 4. Files Touched

- `R/julia-bridge.R`: canonical `sd` label for Beta and cumulative-logit single-target fitters.
- `tests/testthat/test-julia-cumulative-logit-sd-target-labels.R`: pure bridge-payload regression for intercept and slope selectors.
- `docs/dev-log/general-sd-regression/inventory.md`, `docs/dev-log/check-log.md`, and this report: exact status and check record.
- `docs/dev-log/general-sd-regression/evidence/cumulative-logit-sd-bridge-20261025/`: failed reproduction and restored-source rerun evidence.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`: four hash-bound focused receipts.

The existing intercept and slope live-test files were restored byte-for-byte to their receipt-bound original source. Their SHA-256 values match the historical manifests. No user-facing API or model documentation changed because the supported formulas and model behavior did not change.

## 5. Checks Run

- Before the fix, the selected-target regression reproduced the mismatch for both intercept and slope: the R bridge supplied a hashed target key while the Julia fit exposed `sd`.
- After the fix, the pure regression filter passed all 6 expectations.
- R parsing passed for the bridge and focused test sources.
- The restored-source live filter passed 36 expectations with exit code 0, including native TMB and Julia fits for both intercept and slope. The captured run shows Julia startup and four model fits. The generic test footer reports zero live tests because the historical tests use a manual opt-in guard; the body output records the live assertions. Before and after source manifests match.
- `python3 tools/general-sd-regression/reconcile_evidence.py` passed: 19,118 candidates, 68 receipt records, 55 linked rows, 19,063 unlinked rows.
- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py` passed 11 tests.
- The consistency search used `rg -n -i 'cumulative.?logit.*(intercept.only|slope|sd)|cumulative_logit.*sd'` over `README.md`, `docs/dev-log/internal-roadmap.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, `_pkgdown.yml`, `docs/design`, `vignettes`, `R`, `tests`, and `man`. Existing vignettes already describe the same narrow intercept and slope boundaries; no navigation or public claim needed changing.
- `git diff --check` and prose validation are recorded with the final closeout checks below.

## 6. Tests of the Tests

The pure selector test failed before the bridge fix for both selected targets and passed afterward. The live filter also reproduced the selected slope-label failure before the fix. Its failed console is retained in `docs/dev-log/general-sd-regression/evidence/cumulative-logit-sd-bridge-20261025/console.log`; the successful restored-source run is in `pass-restored-tests/`.

## 8. Consistency Audit

The cumulative-logit row in the inventory now records the selected-target label rerun and its evidence boundary. The check log records the same claim and ledger totals. Existing formula and distribution guides already say that ordinary intercept and independent numeric-slope routes have focused same-data checks, while structured effects, other distributional parameters, interval coverage, and broader family parity remain outside this evidence. No unrelated documentation was revised.

## 7a. Issue Ledger

Searched open issues for `cumulative-logit SD bridge target label`. The only result was #1463, “Test sweep 3 Oct 2026: what passed,” a broad test-sweep record with no actionable issue for this bridge label repair. No issue was opened, closed, or edited.

## 9. What Did Not Go Smoothly

An initial live attempt used an invalid `JULIA_HOME` and stopped before entering Julia. A later run exposed the intended label mismatch. During test setup, adding a live-test skip helper directly to receipt-bound historical test files invalidated their recorded source hashes. Those files were restored exactly, the pure regression was moved to a new test file, and the final run verified identical before and after source manifests. An initial ledger append also produced a malformed first key; it was repaired from the frozen universe and the reconciler and its 11 tests passed before the cumulative receipts were appended.

## 11. Team Learning

For evidence-bound legacy tests, add new regression coverage in a separate file unless the existing receipt is deliberately being superseded. Confirm source manifests before and after a live run, and treat generic live-test counters as suspect when older tests use custom opt-in guards; preserve the actual fit output.

## 10. Known Residuals

The four receipts remain unreviewed candidate evidence. They cover only a complete-response cumulative-logit `mu` intercept and numeric slope under the focused fixtures. They do not establish interval calibration, structured cumulative-logit SD regression, scale/discrimination SD regression, or broad Julia/TMB parity. No capability row is promoted and no programme gate closes. The exact evidence overlay has 68 records linked to 55 of 19,118 candidate rows; 19,063 remain unlinked.

## 12. Cross-Product Coverage

For the engine dimension, this slice covers the R bridge to the paired Julia cumulative-logit fitter and native TMB comparison on one ordinary intercept and one numeric slope. It does NOT cover other families, structured providers, bivariate structures, missing-data variants, other distributional parameters, interval workflows, or calibration. This is not completion of the overall predictor-dependent SD programme.

## Next Actions

Continue with a distinct unlinked capability row from the frozen inventory, first checking existing implementation and ownership. Keep interval-coverage validation deferred as approved, and record any implementation-only evidence at its exact row and tier.

Memory receipt: `route.py` returned no LOAD-FIRST manifest for this worktree. The repository instructions, frozen SD inventory, paired bridge implementation, and focused test sources supplied the task context. Golden Set: not run; this bridge-label repair does not alter model likelihoods or target calculations.
