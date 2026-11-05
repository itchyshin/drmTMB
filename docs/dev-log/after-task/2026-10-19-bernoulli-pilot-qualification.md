# After Task: Bernoulli Pilot Compatibility and Adapter Qualification

## 1. Goal

Allow the exact retained six-row pilot manifest to pass current stage-two preparation while keeping all other prior seed streams fail-closed, then qualify the current Bernoulli adapter on three selected fits.

## 2. Implemented

The Python and R validators now admit a missing row ID only when the stream has six rows and master seed `2026101702`. The R verifier still requires the frozen seed sequence, truth order, and pilot labels. The current adapter passed its bounded three-fit Totoro qualification in 32.725 seconds. All three fits converged, returned valid profile intervals, and passed the independent Laplace oracle.

## 3a. Decisions and Rejected Alternatives

Kept the compatibility exception specific to the retained pilot rather than weakening row-ID requirements for qualification or production streams. The qualification receipt explicitly states `campaign_complete=false` and `calibration_claim=false`; it does not resume the interrupted v8 run.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration-stage-two/stage_two.py`
- `tools/general-sd-regression/native-calibration-stage-two/verify-prior-seeds.R`
- `tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`
- `tools/general-sd-regression/native-calibration-stage-two/test-prior-seeds.R`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/stage-two-current-source-audit-20261019-v3/`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/stage-two-qualification-20261019-v3/qualification-prepared/`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/stage-two-qualification-20261019-v3/qualification-prepared/health-interval-rds-hashes.csv`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/stage-two-qualification-20261019-v3/qualification-prepared/health-interval-rds-readback.json`
- This report and its check-log shard

## 5. Checks Run

- Red tests before the validator change failed on the absent `manifest_row` / missing row identity.
- `OPENBLAS_NUM_THREADS=1 python3 -m unittest tools.general-sd-regression.native-calibration-stage-two.test_stage_two`: 30 passed.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-prior-seeds.R tools/general-sd-regression/native-calibration-stage-two`: passed, including no-ID pilot truth and row-order negative controls and missing-ID qualification rejection.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two`: passed.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-verify-first-look-registry.R tools/general-sd-regression/native-calibration-stage-two`: copied-manifest registry and tamper guard passed.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R tools/general-sd-regression/native-calibration-stage-two`: passed its no-fit injected-integrity-failure subprocess test with the expected nonzero child status.
- `git diff --check -- tools/general-sd-regression/native-calibration-stage-two`: passed.
- Independent source audit v3 verified all 17 file hashes and the manifest receipt; digest `f2e1cc709f35a950078ef3914768d12ec6cf65c4b86cf21255fde0565b357b70`.
- Local qualification readback matched the remote preparation/qualification and result hashes. Qualification receipt digest: `b4cc63f179fedafc9873502eaf71e0ffddd75885116185258250c1f99bbc900d`.
- The independent inference reviewer confirmed all three fitted cases converged with positive-definite Hessians, small maximum gradients, valid non-boundary intervals, and passing likelihood oracles. The reviewer initially noted that health and interval RDS files lacked recorded hashes; a six-file remote/local SHA-256 comparison now passes and is recorded in `health-interval-rds-readback.json`.
- A second independent readback confirmed all six RDS hashes, the sidecar manifest digest, and its binding to the qualification receipt.

## 6. Tests of the Tests

The compatibility tests were run red before the fix. The R suite rejects a no-ID pilot after changing only its first truth value, rejects reordered no-ID rows, and rejects qualification data without an ID. Python rejects wrong counts and a qualification stream without an ID. The three remote results were independently mapped to the preselected indices and checked for completed state, valid intervals, and oracle success. Their six health and interval RDS files were hashed remotely and compared with the local copies.

## 7a. Issue Ledger

No issue was changed. This work repairs the private stage-two evidence adapter; the broader implementation remains tracked in the existing programme ledger.

## 8. Consistency Audit

The source audit and qualification evidence live in new versioned directories; v1, v2, the v8 partial run, and prior qualification roots remain unchanged. The remote preparation initially used a staged directory without result files and correctly stopped before fitting. The retry used the reconstructed first-look capsule whose registry and manifest match the external seal. No package API, family support claim, model source, or documentation example changed.

## 9. What Did Not Go Smoothly

The first no-fit preparation attempt selected a staging copy with zero result files. The preparer rejected it before any fits. Read-only seal inspection identified the complete reconstructed capsule, and preparation then passed.

## 10. Known Residuals

This qualifies current adapter operation on three selected fits only. It does not establish interval calibration or authorize the 9,000-attempt campaign. The v8 partial run remains incomplete. Fresh runtime review and user approval are required before a campaign projected above three hours. General random-effect SD support across families, random-effect types, endpoints, and both engines remains unfinished; programme gates G0-G8 remain open.

## 11. Team Learning

When a seal names both a staging directory and a reconstructed raw-attempt directory, verify the complete result-file set before choosing the replay input. Preserve the staged and reconstructed paths distinctly in qualification commands.

## 12. Cross-Product Coverage

Covers: deterministic pilot-stream compatibility, current Bernoulli stage-two adapter preparation, and three selected native/TMB qualification fits.

Does NOT cover: 9,000-fit completion, Bernoulli uncertainty calibration, Julia qualification, general family/effect/endpoint parity, or completion of the programme.

Next action: use the reviewed current-source qualification to make a fresh, bounded full-campaign runtime projection; seek approval before any run projected above three hours.
