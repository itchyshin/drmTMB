# After Task: Current-Source Bernoulli Timing Pre-run

## 1. Goal

Measure current-source runtime and fit health for the native Bernoulli SD-regression worker using a seed stream that is separate from calibration.

## 2. Implemented

Built the current dirty-worktree package on Totoro and ran all 45 rows of the frozen timing-only manifest at 16 workers. The complete source registry, supervisor receipt, attempt table, per-fit result files, health records, logs, installed package artifacts, and clean source archive are retained under `docs/dev-log/general-sd-regression/evidence/calibration-20261023/timing-current-source-v1/`.

All 45 fits completed with valid 95% profile intervals and independent Laplace-oracle checks. The maximum absolute oracle error was `7.2211e-8`; the maximum absolute gradient was `8.7971e-9`. There were no profile boundaries, warnings, or errors. Supervisor wall time was 29.501 seconds. Each row records `calibration_claim=false`.

## 3a. Decisions and Rejected Alternatives

Use the full frozen 45-row timing stream. Do not reuse any timing observation in a calibration denominator or interpret a valid profile as evidence of calibrated coverage. Preserve the current source and installed-library hashes so runtime estimates refer to this candidate only.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/calibration-20261023/timing-current-source-v1/`
- `docs/dev-log/check-log.d/2026-10-23-source-bound-bernoulli-timing.md`
- `.unlazy/general-sd-regression/GATES.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/after-task/2026-10-23-source-bound-bernoulli-timing.md`

The shared `docs/dev-log/check-log.md` index was left untouched because file-specific preflight found 449 refs with changes not present in this checkout. The evidence is recorded in a new check-log shard.

## 5. Checks Run

- Totoro installation initially failed because macOS AppleDouble sidecars were included as native source files. After removing those metadata files from the isolated source copy, the clean Linux build and package-load tests passed.
- The timing capsule prepared 45 rows with master seed `2026101903`; no fits launched during preparation.
- The Totoro worker completed 45/45 timing fits with zero launch errors. The pinned summary reported 45 valid profiles and `calibration_claim=false`.
- Local receipt readback found 45/45 completed attempts, 45/45 valid profiles, 45/45 independent Laplace-oracle passes, zero boundaries, zero warnings, and zero errors.
- All 26 source-file hashes and all six retained installed-library artifact hashes matched the source registry. The retained source archive SHA-256 is `a37d402265530d4c514d91282e1bfb6b2c2cc1cb1b2b22bb7eae583eeebf8a9a`.
- `Rscript tools/general-sd-regression/native-calibration/test-summarize-timing-095.R` passed, including its tamper-rejection check.
- The conservative projection uses the maximum observed fit time of 10.236 seconds, 188 waves per 3,000-fit batch, and 180 seconds of overhead per batch. This projects 105.2 minutes for 9,000 fits and 126.3 minutes with a 20% allowance. This is below the current 175-minute cap; it is not a calibration result or authorization to skip source and adapter gates.
- After copying and verifying the complete capsule locally, the 104 MB Totoro run directory was moved from `hsq_work` to `/tmp`; it remains recoverable there.

## 6. Tests of the Tests

The timing summarizer's dedicated test passed and verified that all planned rows remain represented, the summary does not report inferential calibration metrics, and tampered results are rejected.

## 7a. Issue Ledger

No issue was opened, edited, or closed. No external data or collaborator examples were used.

## 8. Consistency Audit

The capsule, summary, check-log shard, and programme ledger all preserve `calibration_claim=false`. The current timing manifest is seed-disjoint from frozen look one and look two. The ledger keeps G5 open. This timing run does not change the implementation scope or public support claims.

## 9. What Did Not Go Smoothly

The first package install attempted to compile AppleDouble metadata copied from macOS and failed before any model fit. The build was corrected by removing those sidecars from the isolated Totoro source copy and forcing a clean native compilation. No fit ran against the failed installation.

## 10. Known Residuals

The 45-fit run measures runtime and fit health only. It does not establish interval coverage, false-positive control, recovery across repeated samples, or a calibrated uncertainty claim. G5 remains open. Current-source adapter qualification and the matching source-bound calibration decision must be completed before any second-look calibration campaign. The family/effect/backend capability inventory remains incomplete.

## 11. Team Learning

Cross-platform source transfers must exclude macOS AppleDouble sidecars and prebuilt object or shared-library files. Force a clean native rebuild on the target platform, then verify package loading before starting model fits.

## 12. Cross-Product Coverage

This task covers one native Bernoulli timing-only worker on Totoro. It does NOT cover interval calibration, the Julia engine, other response distributions, structured random effects, the full capability inventory, or programme closeout. Next, qualify the current-source adapter against a seed-disjoint stream and a matching sealed first-look source before evaluating G5.
