## 1. Goal

Fix the second-look adapter's healthy batch-hash comparison, test the current integrity controls, and record whether the adapter is ready for qualification.

## 2. Implemented

Added `native_sd_stage_two_hash_maps_equal()` to normalize named vectors and JSON lists, require unique non-empty batch keys, and compare hashes by key. `combine-stage-two.R` now uses this function. Added a JSON-shaped healthy reordered map fixture plus value, missing-key, and duplicate-key controls. Updated the execution-design note and check log with the current review result, source hashes, tests, and remaining seal requirement.

## 3a. Decisions and Rejected Alternatives

Kept the comparison in the shared rule file so the combiner and pure tests call the same function. Rejected comparing `as.character()` outputs because it discards the batch names needed to bind each hash to its batch. Assumed the sealed batch map represents each batch ID as a unique string key; the validator rejects missing or duplicate keys if that contract changes.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration-stage-two/stage-two-rules.R`
- `tools/general-sd-regression/native-calibration-stage-two/combine-stage-two.R`
- `tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R`
- `docs/dev-log/general-sd-regression/stage-two-execution-design.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-17-stage-two-hash-map-repair.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

## 5. Checks Run

- `python3 -m unittest tools.general-sd-regression.native-calibration-stage-two.test_stage_two`: PASS, 21 tests.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two`: PASS, `STAGE_TWO_R_RULES_PASS`.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-prior-seeds.R tools/general-sd-regression/native-calibration-stage-two`: PASS, `PRIOR_SEED_STREAM_NEGATIVES_PASS streams=3`.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-verify-first-look-registry.R`: PASS, including copied-manifest tamper guard.
- Current hashes: `stage_two.py` `7da3fd9058f87d83c5a2028894349f3b231069fe6cad16a7fdbbc5c559cf9b32`; `stage-two-rules.R` `89abcdc512301f34078857feec9e30f70582594455278ee162b81d1c1c371f26`; `combine-stage-two.R` `1d3fd683a5e3d84a1a2bc869fae11868d92cd7c1264d6773020f86e9d60dbb0d`.
- `git diff --check`: PASS after the repair and report edits.

## 6. Tests of the Tests

The healthy fixture parses a JSON object into the same list shape used by the combiner. It proves the prior comparison rejects matching hashes when names are dropped, while the shared validator accepts them after key normalization. Changed hash, missing key, and duplicate key fixtures all fail.

## 7a. Issue Ledger

- Fixed: matching attempt hashes in a valid JSON list were rejected because `as.character()` dropped batch names.
- Still open: the existing v2 source seal pins earlier adapter source hashes. The retained 19/19 result predates the current source and is historical only.
- No preparation, qualification fit, or second-look fit was run.

## 8. Consistency Audit

Checked the combiner's run-receipt comparison against the new shared helper and exercised that helper with the parsed JSON representation. The negative controls cover hash mismatch, missing batch, and duplicate batch IDs. Prior-seed and copied-manifest registry tests also pass on the current source.

## 9. What Did Not Go Smoothly

The first independent review correctly found a comparison that pure tests did not reach. Source-hash review also showed that the old seal cannot validate this current snapshot, so passing current unit tests is not enough to qualify the adapter.

## 10. Known Residuals

A new source-bound first-look reconstruction and replay receipt must bind the final adapter sources, followed by independent review. The qualification capsule and its three fits remain unprepared. The larger second-look campaign remains gated separately. Runtime cleanup still uses deadline checks around worker stages rather than one enclosing hard supervisor cap.

## 11. Team Learning

Memory receipt: loaded the routed drmTMB manifest and applied its source-pin, negative-control, and compute-gate guidance. Golden Set: not run; the reviewed failure was specific to this adapter's JSON map comparison. A production parser's exact decoded data shape belongs in positive tests, not only in hand-built atomic fixtures.

## 12. Cross-Product Coverage

Covers: the R stage-two combiner's batch-hash map comparison; Python and R adapter integrity unit tests; first-look prior-seed and registry controls.

Does NOT cover: source-bound reconstruction/replay under a new seal; adapter qualification; model fitting, recovery or calibration; Totoro/DRAC execution; any change to the frozen decision rule; or remaining SD regression families, effects, endpoints and backends.
