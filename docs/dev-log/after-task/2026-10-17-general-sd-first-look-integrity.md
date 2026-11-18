# After Task: Bernoulli first-look evidence integrity

## Goal

Repair the attempt digest and reconstruction provenance so the retained Bernoulli first-look evidence can be replayed and authenticated without changing model fits or the calibration rule.

## Implemented

The batch digest now requires a result file for every supervisor-completed index, permits failed or timed-out cases to have a partial result file or none, hashes every present in-range result, and rejects out-of-range results. Reconstructed first-look seals pin the independent archive digest and the exact five reconstruction and verification sources. The R replay receipt records the seal digest and the source map.

Totoro capsule-04 reconstructed and replayed all 3,000 first-look attempts. The R verifier returned `FIRST_LOOK_REPLAY_PASS standardized_rows=3000 decision=look2_required`. The v2 seal is `67bcd657226c168477c041710e7f1e6e12eadde4a305da97b2275cba256dafb0`. The standardized CSV and replay receipt hashes are `2b887af87bcce54d0088757d42524bcad20d95d5e96c92910fbd87f4f9f79ba6` and `f6eabe872e6af853e8985d202408d1a836cdbe502abf816e4332e4cd65c53f5a`.

## Mathematical Contract

No likelihood, estimator, formula, or interval rule changed. This work only authenticates the planned-attempt denominator and the code that converts raw first-look results into standardized rows.

## Files Changed

Updated the Python and R stage-two digest and source-verification helpers and their tests under `tools/general-sd-regression/native-calibration-stage-two/`. Updated `docs/dev-log/general-sd-regression/stage-two-execution-design.md`, `docs/dev-log/check-log.md`, `LOOP/lanes/general-sd-regression/checkpoint.md`, and `.unlazy/general-sd-regression/GATES.md`. Added the three v2 replay artifacts under `docs/dev-log/general-sd-regression/evidence/calibration-20261017/` and this report. Capsule-04 is retained on Totoro under `hsq_work/drmtmb-general-sd-calibration-20261017-03/`.

## Checks Run

Python byte-compilation passed. The local Python stage-two suite passed 19/19. R parsing passed; the R stage-two rules test and copied-manifest registry test passed locally and in Totoro capsule-04. The full Totoro R replay passed. A local check verified 3,000 standardized rows, the CSV and replay receipt hashes, all five current source hashes, the archive hash, and the receipt's link to the v2 seal.

An independent artifact audit also matched all three v2 hashes, verified the five source hashes against current code, and confirmed the receipt-to-seal, source-map, attempt-digest, and CSV links.

## Tests Of The Tests

Negative controls reject a missing completed result, an out-of-range result, a changed reconstruction source, an incomplete source map, a tampered archive, and a copied manifest that differs from its registry. Positive controls cover failed-case result files both present and absent. The initial Python runs exposed stale error-message expectations; those expectations were corrected to match the stricter fail-closed behavior before the passing run.

## Consistency Audit

The design note now describes the adapter as implemented and distinguishes reconstruction provenance from second-look preparation and calibration. The gate ledger remains open for G0-G8 and records this as first-look provenance only. The v1 reconstructed seal and receipt remain preserved but are explicitly excluded from later preparation because they lack the source map. No public support claim, example, likelihood equation, or package reference changed.

## GitHub Issue Maintenance

Searched open drmTMB issues for random-effect SD regression and Bernoulli SD syntax. No matching issue was found, so the issue tracker was left unchanged.

## What Did Not Go Smoothly

The original seal omitted raw-result hashes, and the first repair pass still did not bind the source files that created the replay. The first focused test run also found an outdated error-text assertion. The v1 artifacts were retained as history; capsule-04 and new v2 filenames were used for the corrected evidence.

## Team Learning

An integrity seal must bind the raw attempts, the independent archive identity, the source that reconstructs those attempts, and the verifier receipt. For worker failures, require completed outputs but hash any partial output that exists. Independent reviewers caught both the stale-source boundary and the worker's write-before-fit behavior.

## Known Limitations

This does not establish interval calibration, Bernoulli recovery, Julia parity, or broad family/effect support. It does not qualify the adapter or authorize the second-look batches. G0-G8 remain open. The whole-adapter review still needs to confirm closure of earlier seed-row and mandatory-file findings.

## Next Actions

Complete an independent whole-adapter review against the v2 seal. If it passes, state the runtime estimate before the bounded three-row adapter qualification. Keep the 9,000-fit second look behind the measured runtime and its existing approval boundary, then continue the broader R/TMB and Julia implementation.
