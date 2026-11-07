# After Task: Bernoulli second-look adapter qualification

## Goal

Qualify the frozen three-registry Bernoulli second-look adapter without making a calibration claim or launching the 9,000-fit second look.

## Implemented

The v7 Totoro adapter run passed in 60.2931 seconds. Three selected rows, one from each truth block, converged, produced valid profile intervals, and passed the independent Laplace likelihood oracle. The receipt records `PASS`, `attempted=3`, `calibration_claim=false`, and `campaign_complete=false`. An independent reviewer matched the external preparation digest and every retained registry, manifest, supervisor, and result digest.

## Mathematical Contract

For the Bernoulli vertical slice, the group random intercept has a logit-scale standard deviation whose log is regressed on fixed predictors. This adapter check verifies row identity, fit completion, interval production, and likelihood calculation. Three selected fits do not estimate coverage and do not establish calibration.

## Files Changed

- `tools/general-sd-regression/native-calibration-stage-two/README.md` now distinguishes the passing v7 adapter check from the still-unrun second look.
- `docs/dev-log/general-sd-regression/stage-two-execution-design.md` records v7 and marks the earlier v2 probe note as historical.
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/first-look-v4/adapter-qualification-v7/` retains the prepared tree and run receipts.
- `LOOP/lanes/general-sd-regression/checkpoint.md`, `docs/dev-log/check-log.md`, and this report record the evidence and remaining gates.

## Checks Run

- `python3 -m unittest tools.general-sd-regression.native-calibration-stage-two.test_stage_two`: 28 tests passed.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two`: `STAGE_TWO_R_RULES_PASS offsets=3 metrics_tolerance=1e-12`.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-prior-seeds.R tools/general-sd-regression/native-calibration-stage-two`: `PRIOR_SEED_STREAM_NEGATIVES_PASS streams=3`.
- Local receipt replay: `ADAPTER_V7_READBACK_PASS elapsed_seconds=60.29310965212062 attempted=3 valid=3`.
- Qualification receipt SHA-256: `5f7ace0329835c5db4f4ce46bce1d3046e37285a4f4f08e2d5a549ca892aed20`.
- External preparation receipt SHA-256: `148667c74bdfddd5d7260b4c15656deb89f4550003f3394b2caaed0012685598`.

## Tests Of The Tests

The 28 Python tests include no-fit runner checks and integrity-negative fixtures for changed preparation digests and reordered registries. The R rules verify seed-stream negatives. The three production-worker probes also passed the independent likelihood oracle; the test suite itself did not generate those fits.

## Consistency Audit

The adapter README and execution design now state that the v7 adapter passed while the 9,000-fit run and calibration remain open. The reviewer confirmed all copied artifact hashes and the receipt's no-calibration fields. The evidence does not recheck live Totoro files after copying; remote paths in registry files remain historical identifiers. No public package support claim changed.

## GitHub Issue Maintenance

The read-only search for open issues matching “random effect SD regression” returned only broad phase or test-sweep issues (#59, #61, and #1463). No issue was changed because none was a specific adapter execution issue.

## What Did Not Go Smoothly

The first local readback command pointed to the external preparation digest one directory too deep and failed before reading any artifact. Correcting the evidence root produced a passing digest replay. The lane lease registry was outside the writable workspace; a narrow approved lease write was required before edits.

## Team Learning

Keep adapter operation, calibration, and campaign completion as separate claims. An externally retained digest and independent byte readback make that distinction auditable. Reuse that receipt structure for later batch adapters.

## Known Limitations

The frozen first-look decision remains `look2_required`, not acceptance. The 15-process timing registry matches the current `worker.R` hash and the v7 installed-library DLL hash. Its measured projection is 7,956.41 seconds for three batches, below the 10,500-second hard cap. This is operational timing evidence, not calibration. No GO record or second-look capsule exists yet. Julia parity and the remaining family/effect map remain outstanding.

## Next Actions

Prepare the recorded GO and stage-two capsule under the already approved bounded-compute plan, then run and combine the 9,000 second-look attempts. Continue Julia and remaining family/effect implementation in their owned lanes.
