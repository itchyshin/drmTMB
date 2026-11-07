# After Task: Bernoulli Stage-Two Timing Pre-Run

## 1. Goal

Measure runtime and worker correctness for a bounded 45-fit Bernoulli SD-regression pre-run on Totoro. The pre-run measures throughput and worker integrity; it makes no calibration estimate.

## 2. Implemented

The pre-run runner now checks external preparation and qualification receipts, the frozen 9,000-row source manifest, all three prepared-batch registries, the exact imported Python modules, the R worker, the qualified installed package artifacts, and the R launcher before creating output or starting a fit. An independent source reviewer approved the final runner and design hashes before execution.

All 45 selected fits completed in 38.101 seconds. Every result passed the configured convergence, Hessian, gradient, clamp, profile interval, warning/error, and independent Laplace-oracle checks. The observed mean fit time was 9.828 seconds; median 10.008 seconds; 90th percentile 11.389 seconds; minimum 7.093 seconds; maximum 12.946 seconds. Maximum single-child RSS was 265,256 KiB. Aggregate concurrent RSS was not measured.

The two runtime projections for 9,000 fits were 98.28 minutes from summed fit service time divided by 15 workers, and 127.00 minutes from observed batch wall time. The service projection adds 8.59 seconds for measured setup across three batches. Totoro has no queue, so the queue allowance was zero. These projections do not include unmeasured shared-host contention or aggregate memory.

## 3a. Decisions and Rejected Alternatives

The runner keeps immutable execution paths and source hashes as hard preconditions. It does not accept staged copies merely because their file contents match. The timing results are kept separate from recovery and coverage evidence. The 15 duplicated indices are disclosed and excluded from new attempt counts.

## 3b. Mathematical Contract

The worker fits the frozen Bernoulli model `y ~ x + (1 | id)` with `sd(id) ~ w`, where `w` varies the latent random-intercept SD on the log scale. A passing timing result verifies only this worker's configured numerical checks; it does not establish recovery or interval coverage.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/timing-pre-run-20261019-v1/run_timing_pre_run.py`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/timing-pre-run-20261019-v1/DESIGN.md`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/timing-pre-run-20261019-v1/totoro-output/` (241 files copied and matched to the remote SHA-256 manifest)
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/attempt-reconciliation-20261019-v1/reconcile_attempts.py`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/attempt-reconciliation-20261019-v1/attempts.csv` and `reconciliation-receipt.json`
- This after-task report and its check-log shard

Runner SHA-256: `10554c6bf78a9e97c41959c235721a4d08570c1d1ed79b69c4403432b9cde2b7`. Design SHA-256: `821196c75338a8f2f6f7f49e527958b8a43c3e203ad3a1a63e000ea892bad305`. Timing receipt SHA-256: `0402f317b5338792839c24ecf1114cf82eea252d1435d5a7225d9fc4cd4e2aaf`. Remote-output readback manifest SHA-256: `31942d23f0fb7384fb54deb3900e27acfa61cbf7b99ea874db98cf8e219946f0`.

Reconciliation script SHA-256: `adbd4cff0691a1cb2cc4aa50030f22be01802e1db5e6ad878adb49b7c0ebd72c`. The 9,000-row ledger SHA-256 is `658611c0ce7c0f78c44de78616818b437224af031d5d9fa7418cdb9f7e2079f1`; its receipt SHA-256 is `c4a3b14ea4f8de64937da00f320e212e175111da97d2a43f83976c035cfc560a`.

## 5. Checks Run

- Local `py_compile` and `--help` smoke checks passed.
- Totoro verified the staged runner and design against the reviewed hashes.
- The runner passed all source, receipt, library, module, R launcher, R version, R home, and prepared-batch checks before launching workers.
- The final Totoro timing receipt reports `PASS`, 45 planned and attempted fits, three complete batches, no interruption, and no failed health or oracle checks.
- All 241 copied output files matched the remote size and SHA-256 manifest; zero files were missing or mismatched.
- The timing projection is 98.28 minutes by summed service time plus measured setup, and 127.00 minutes by observed batch wall time. Both are below three hours. They are throughput estimates, not authorization or evidence for a calibration claim.
- Independent reviewer approved the final runner and design for this bounded timing pre-run only.
- The reproducible attempt reconciliation checked all 9,000 frozen rows. It marks 412 unique seeds consumed and 8,588 eligible for a future attempt: indices 383–3,000, 3,016–6,000, and 6,016–9,000.

## 6. Tests of the Tests

Two deliberately encountered pre-fit mismatches confirmed that the runner stopped before creating an output directory or launching a fit: the preparation receipt had a specific `prepared_not_launched` state, and the first invocation supplied staged copies where the sealed registries required immutable source paths. The corrected checks accepted the exact retained receipt and source paths. The 45 fitted cases then exercised the numerical health and oracle assertions.

## 7a. Issue Ledger

Read-only searches for `"sd(group)" predictor` and `"random-effect" "sd" regression` found no open issue specifically tracking this timing pre-run or its source-binding repair. No issue was created, commented on, or closed.

## 8. Consistency Audit

No package source, public formula, family support claim, vignette, reference page, or pkgdown navigation changed. The unlazy programme ledger still leaves G0 through G8 open. No GitHub issue directly matched this timing-pilot checkpoint; the read-only issue search led to no issue update. The existing v8 run remains incomplete.

The v8 batch-1 manifest hash matches the qualification manifest. Its supervisor records 382 started indices: 366 completed, 16 interrupted, and 2,618 not started. Index 382 has no result file but had started, so it remains a consumed attempt and must not be retried. The timing pre-run repeated indices 1–15, which v8 had already completed. Its indices 3,001–3,015 and 6,001–6,015 were new relative to that v8 batch. The reconciliation script verifies those overlaps and maps every stage-two row to a future-attempt eligibility status. This overlap does not change the throughput measurements, but it must remain visible in any future recovery ledger.

## 9. What Did Not Go Smoothly

The first runner version rejected the valid preparation receipt because it expected `PASS` instead of the retained `prepared_not_launched` status. After that correction, a second pre-fit check correctly rejected staged source copies whose paths did not match the immutable registry. The final invocation used the sealed paths. I also failed to check the v8 attempt ledger before choosing indices 1–15 for the timing pilot; those fits duplicated prior completed attempts. I recorded and excluded that overlap rather than treating the repeated fits as new evidence.

## 10. Known Residuals

This timing pilot is not an independent recovery study and makes no calibration claim. Only 30 of its 45 global stage-two indices were new relative to v8; no timing-pilot fit is used as recovery or interval-calibration evidence. The run recorded maximum single-child RSS, not aggregate concurrent RSS. The 9,000-fit projections exclude shared-host contention. The full stage-two run has 8,588 rows left eligible for a first attempt, split into batch counts 2,618, 2,985, and 2,985. The general R/TMB plus Julia feature remains unfinished.

## 11. Team Learning

Before selecting a timing or recovery subset, reconcile every selected global index against all existing attempt receipts, including partial runs and interrupted workers. Bind not only file hashes but also executable paths, loaded modules, package artifacts, and runtime launchers before starting workers.

## 12. Cross-Product Coverage

Covers: source-bound Totoro timing and worker-integrity evidence for 45 Bernoulli SD-regression fits, plus reconciliation of their indices with the existing v8 attempt receipt.

Does NOT cover: recovery or interval-calibration evidence from any timing-pilot fit, aggregate concurrent memory, the 8,588 eligible stage-two rows, Julia parity, other families or random-effect types, or formal programme gates G0–G8.

Next action: prepare a continuation runner for indices 383–3,000, 3,016–6,000, and 6,016–9,000, with the frozen 9,000-row manifest unchanged and all prior attempts retained. Update the runtime and memory assessment before further production fits.
