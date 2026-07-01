# Q-Series spatial sigma SR1000 top-up blocker

## 1. Goal

Run the retained-denominator top-up for
`qseries_spatial_q1_sigma_one_slope` and update mission control with the
row-specific result without promoting interval, coverage, `inference_ready`,
`supported`, REML, AI-REML, bridge, or public-support claims.

## 2. Implemented

Ran the existing sigma-slope coverage-grid runner for the two fixed-covariance
spatial direct-SD targets:

- shard 3: `spatial`, `sigma:(Intercept)`, seeds 740476-741000;
- shard 4: `spatial`, `sigma:x`, seeds 740476-741000.

The new top-up rows live under
`docs/dev-log/simulation-artifacts/2026-06-28-spatial-sigma-slope-coverage-topup-local/`.
The combined SR1000 summary joins those 525 new replicates per endpoint to the
existing SR475 local grid:

- `spatial-sigma-sr1000-combined-summary.tsv`

Updated `structured-re-sigma-slope-spatial-animal-admission-audit.tsv` so the
spatial sigma row is no longer `topup_required`. The top-up is complete and
the honest state is now `admission_blocked` with
`blocked_low_finite_wald_intercept_after_sr1000`.

## 3a. Decisions and Rejected Alternatives

The estimand is the direct structured SD in the Gaussian `sigma` formula:

- `sd:sigma:spatial(1 | site)` for `sigma:(Intercept)`, truth 0.50;
- `sd:sigma:spatial(0 + x | site)` for `sigma:x`, truth 0.38.

The primary channel remains the raw uncorrected log-SD Wald interval. The
location-axis bias+t correction does not apply to `sigma`. Profile intervals
remain diagnostic because finite-profile rates are low and censoring-suspect.

I did not promote the row to `inference_ready`. The top-up was meant to test
the finite-Wald gate, and the intercept endpoint failed that gate after SR1000.

I did not update the support-cell TSV. The correct row-level evidence state is
an admission blocker, not a support-cell interval or coverage promotion.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-28-spatial-sigma-slope-coverage-topup-local/`
- `docs/dev-log/dashboard/structured-re-sigma-slope-spatial-animal-admission-audit.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-spatial-sigma-sr1000-topup-blocker.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-sigma-slope-coverage-grid.R --shard=3 --n_rep=525 --seed_start=740476 --out_dir=docs/dev-log/simulation-artifacts/2026-06-28-spatial-sigma-slope-coverage-topup-local/results/shard_3 --bootstrap=0`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-sigma-slope-coverage-grid.R --shard=4 --n_rep=525 --seed_start=740476 --out_dir=docs/dev-log/simulation-artifacts/2026-06-28-spatial-sigma-slope-coverage-topup-local/results/shard_4 --bootstrap=0`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file docs/dev-log/simulation-artifacts/2026-06-28-spatial-sigma-slope-coverage-topup-local/summarize-spatial-sigma-sr1000.R`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The validator now requires the combined SR1000 summary to contain exactly two
rows, the exact spatial endpoint targets, the exact 740001-741000 seed range,
the exact finite-Wald counts, one-sided miss counts, gate outcomes, and
no-promotion claim-boundary language. It also requires the mission-control
admission row to point at this combined evidence and to stay
`admission_blocked`.

## 7a. Issue Ledger

- `qseries_spatial_q1_sigma_one_slope`: SR1000 top-up complete; still blocked
  because `sigma:(Intercept)` finite-Wald rate is 0.9360, below the 0.95 gate.
- `qseries_animal_q1_sigma_one_slope`: unchanged; still blocked because
  `sigma:x` is absent from the retained-denominator coverage grid.

No GitHub issue was opened. This is a PR #685 evidence/status tranche.

## 8. Consistency Audit

The support-cell TSV was not edited. `qseries_spatial_q1_sigma_one_slope`
keeps `interval_status = planned` and `coverage_status = planned`.

The old SR475 after-task report remains historical. This report supersedes its
spatial next-gate wording: the top-up has now been run, and the remaining
blocker is the spatial `sigma:(Intercept)` finite-Wald rate, not missing
replicates.

## 9. What Did Not Go Smoothly

The top-up did not rescue the row. The `sigma:x` endpoint passed the finite
rate gate, but `sigma:(Intercept)` still had too many boundary/nonfinite Wald
intervals after SR1000. That is useful but slightly grim evidence.

## 10. Known Residuals

This tranche does not promote fixed-covariance spatial sigma to
`inference_ready`, does not support range-estimating spatial models, does not
validate profile-channel reliability, and does not touch animal sigma, matched
`mu+sigma`, q4/q8, non-Gaussian intervals, REML, AI-REML, bridge support,
`supported`, or public support.

The next technical residual is narrower than before: spatial
`sigma:(Intercept)` needs a boundary/nonfinite-Wald fix or a validated
sigma-specific interval channel before the row can be reconsidered.

## 11. Team Learning

Top-up requests should have a clear possible failure state. Here the correct
post-top-up state is not "keep topping up"; it is "fix the finite-Wald
mechanism or validate a sigma-specific interval channel."
