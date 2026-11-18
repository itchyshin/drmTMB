# After Task: Clean-Current Bernoulli Look-Two Preflight

## 1. Goal

Build a no-fit path that maps the frozen clean-current look-two seed design into three verifiable batches and prevents mismatched batches or profile levels from reaching the calibration decision.

## 2. Implemented

The adapter now validates the frozen look-two CSV digest and exact row mapping, creates three deterministic 3,000-row batches, and retains local and global indices. The 95% runner and worker accept this batch identity and check its seed, source, profile, batch fields, and exact column schema before fitting. The stage-two combiner rejects retained results that lack the requested 95% profile level.

## 3a. Decisions and Rejected Alternatives

No model equation, likelihood, estimator, or calibration threshold changed. The adapter preserves the predeclared look-two truths and seeds. The fitted profile interval remains 95%; the repeated-look Monte Carlo interval remains 97.5% under the existing staged contract. The implementation keeps the old manifest and result history intact and adds a separate source-mapped route for the frozen clean-current look two.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration-stage-two/clean_current_stage_two.py` and `test_stage_two.py`
- `tools/general-sd-regression/native-calibration-stage-two/stage-two-rules.R`, `test-stage-two-rules.R`, `combine-stage-two.R`, and `test-combine-stage-two.R`
- `tools/general-sd-regression/native-calibration/worker-095.R` and `run-095.py`
- `docs/dev-log/general-sd-regression/stage-two-execution-design.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `python3 tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`: 36 tests passed, including all three clean-current batch mappings and wrong-master, wrong-batch, wrong-level, wrong-claim, wrong-seed, and altered-row controls.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two`: `STAGE_TWO_R_RULES_PASS`.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R`: `STAGE_TWO_LEGACY_REPLAY_REJECT_PASS`; the no-fit fixture was rejected for missing profile-level metadata.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-verify-first-look-registry.R tools/general-sd-regression/native-calibration-stage-two`: external registry test passed.
- `python3 tools/general-sd-regression/native-calibration/test-clean-current-route.py .../look1.csv`: runner accepted the frozen look-one path and rejected altered seed and subset inputs.
- `Rscript tools/general-sd-regression/native-calibration/test-clean-manifests.R`: all deterministic clean-current manifest and exclusion checks passed.
- Python compilation and R parsing passed for the changed runner and worker. `git diff --check` passed after the report was finalized.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <report>`: required report structure passed; the programme acceptance ledger returned its nine currently unmet gates, so this slice does not close the larger goal.

## 6. Tests of the Tests

Mutation cases alter source seeds, global indices, batch IDs, master seeds, profile levels, claims, and row counts. They fail in the adapter or pre-fit runner gate. The combiner regression first exposed the desired missing-profile-level error; its expected marker was updated to assert that exact rejection. An initial Python test fixture path pointed one directory too high; correcting it produced the final 36/36 passing run.

## 7a. Issue Ledger

Issue #59 is the matching open simulation tracker. No issue was opened or closed. The GitHub connector rejected the attempted status comment because the exact external disclosure was not explicitly authorized; no alternate posting route was used. The update remains local in this report.

## 8. Consistency Audit

The execution design now distinguishes this no-fit preflight from full clean-current stage-two readiness. A targeted search for `clean.current`, `NO.GO`, `look.two`, and `stage.two` found the older adapter specification still labeled historical. No public model syntax or family-support claim changed, so README, NEWS, formula grammar, and pkgdown navigation were not edited. The source-bound replay process was no longer running, and no local replay seal was found; its completion remains unverified.

## 9. What Did Not Go Smoothly

NotebookLM authentication remains unavailable. The CLI identifies `itchyshin@gmail.com` and finds cookies, but passive `token_fetch` still fails with a DNS lookup error. No research synthesis is claimed.

## 10. Known Residuals

This slice does not complete clean-current preparation and sealing, source-bound replay verification, the independent three-fit qualification, clean-current end-to-end combination, runtime measurement, or look-two calibration. The existing combiner remains wired to historical manifest/master identities, so these batches are not yet a runnable look-two campaign. No look-two fits were launched. The full Bernoulli inference gate and the larger native/Julia family-effect programme remain open.

## 11. Team Learning

The prior adapter audit correctly separated a historically repaired adapter from the current seed design. Reusing its batch machinery without a clean-source mapping would have admitted the wrong seed stream. The new converter and runner tests bind the source rows before any fit. A new negative control also exposed a worker-side schema omission that accepted a batch without `look`; the validator now rejects missing and unexpected columns.

## 12. Cross-Product Coverage

This no-fit R/TMB adapter slice does NOT cover Julia execution, family-wide SD regression, random-effect types outside the frozen Bernoulli intercept calibration DGP, or calibrated look-two uncertainty. It also does NOT cover fit qualification or the full second-look decision.

## Next Actions

1. Obtain and verify the completed source-bound first-look replay receipt and external seal.
2. Finish clean-current stage-two preparation, source registry, and healthy combiner tests.
3. Run the three-case adapter qualification only after the source and replay gates pass; re-estimate runtime before any larger campaign.
4. Reconnect NotebookLM through an authenticated personal-account CLI session and complete the cited methods review.
