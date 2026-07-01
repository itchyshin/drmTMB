# Q-Series animal sigma SR1000 reconciliation

## 1. Goal

Reconcile the stale animal `sigma:x` missing-coverage holdout by running
retained-denominator evidence for the exact
`qseries_animal_q1_sigma_one_slope` endpoints, then update mission control
without promoting interval, coverage, `inference_ready`, `supported`, REML,
AI-REML, bridge, or public-support claims.

## 2. Implemented

Ran the existing sigma-slope coverage-grid runner for the animal
`sigma:(Intercept)` top-up and an artifact-local wrapper for animal `sigma:x`:

- shard 5: `animal`, `sigma:(Intercept)`, seeds 740476-741000;
- artifact-local shard 8: `animal`, `sigma:x`, seeds 740001-741000.

The wrapper lives at
`docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/run-animal-sigma-x-grid.R`.
It reuses `tools/run-structured-re-sigma-slope-coverage-grid.R` with a local
shard-map extension. The canonical runner was not changed.

The combined SR1000 summary is
`docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/animal-sigma-sr1000-combined-summary.tsv`.
It joins the earlier SR475 intercept run, the new SR525 intercept top-up, and
the new SR1000 `sigma:x` run.

Updated
`docs/dev-log/dashboard/structured-re-sigma-slope-spatial-animal-admission-audit.tsv`
so the animal sigma row is no longer a missing-coverage holdout. Its current
dashboard state is `calibration_required`, with
`candidate_wald_channel_pending_fisher_rose_signoff`.

## 3a. Decisions and Rejected Alternatives

The estimand is the direct structured SD in the Gaussian `sigma` formula:

- `sd:sigma:animal(1 | id)` for `sigma:(Intercept)`, truth 0.50;
- `sd:sigma:animal(0 + x | id)` for `sigma:x`, truth 0.38.

The primary channel remains the raw uncorrected log-SD Wald interval. The
location-axis bias+t correction does not apply to `sigma`.

I did not promote the row to `inference_ready`. Both endpoints pass the raw
Wald finite-rate and MCSE gates, but Fisher/Rose sign-off is not recorded and
the profile channel remains low-finite/censoring-suspect.

I did not update the support-cell TSV. The correct row-level state is candidate
evidence pending inference audit, not a support-cell status promotion.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/`
- `docs/dev-log/dashboard/structured-re-sigma-slope-spatial-animal-admission-audit.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-animal-sigma-sr1000-reconciliation.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/run-animal-sigma-x-grid.R --shard=8 --n_rep=1 --seed_start=740001 --out_dir=docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/results/shard_8-smoke --bootstrap=0`: passed after wrapper fixes.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-sigma-slope-coverage-grid.R --shard=5 --n_rep=525 --seed_start=740476 --out_dir=docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/results/shard_5 --bootstrap=0`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/run-animal-sigma-x-grid.R --shard=8 --n_rep=1000 --seed_start=740001 --out_dir=docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/results/shard_8 --bootstrap=0`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file docs/dev-log/simulation-artifacts/2026-06-28-animal-sigma-slope-coverage-topup-local/summarize-animal-sigma-sr1000.R`: passed.

## 6. Tests of the Tests

The validator now requires the animal SR1000 summary to contain exactly two
rows, the exact animal endpoint targets, the exact 740001-741000 seed range,
the exact finite-Wald counts, one-sided miss counts, gate outcomes, and
no-promotion claim-boundary language.

The admission-audit validator also requires the animal row to point at this
combined artifact, to remain `linked_interval_status = planned` and
`linked_coverage_status = planned`, and to stay `promotion_decision =
do_not_promote`.

## 7a. Issue Ledger

- `qseries_animal_q1_sigma_one_slope`: SR1000 evidence is now present for both
  endpoints; raw-Wald gates pass, but the row remains unpromoted pending
  Fisher/Rose audit and profile-channel caveat review.
- `qseries_spatial_q1_sigma_one_slope`: unchanged; still
  `admission_blocked` because the spatial `sigma:(Intercept)` finite-Wald
  rate remains below 0.95 after SR1000.

No GitHub issue was opened. This is a PR #685 evidence/status tranche.

## 8. Consistency Audit

The support-cell TSV was not edited. `qseries_animal_q1_sigma_one_slope` keeps
`interval_status = planned` and `coverage_status = planned`.

The June 24 denominator-rule sidecar remains historical provenance: it still
records why animal `sigma:x` was excluded from the first canonical pregrid.
The June 28 admission audit supersedes the widget's missing-coverage state but
does not rewrite that earlier rule.

## 9. What Did Not Go Smoothly

The artifact-local wrapper needed two smoke fixes before it correctly extended
the shard map and validation range. Once fixed, the one-rep smoke and SR1000
run completed cleanly.

The evidence is also asymmetric in a way that deserves Fisher's eye:
`sigma:x` has strong raw-Wald coverage but only 726/1000 finite profile
intervals.

## 10. Known Residuals

This tranche does not promote animal sigma to `inference_ready`, does not
validate profile-channel reliability, does not support pedigree/Ainv bridge
marshalling, and does not touch matched `mu+sigma`, q4/q8, non-Gaussian
intervals, REML, AI-REML, bridge support, `supported`, or public support.

The next gate is an inference audit: Fisher/Rose should inspect raw-Wald
channel adequacy, one-sided misses, low profile finite rates, and denominator
retention before any exact-row status edit.

## 11. Team Learning

A missing-coverage holdout can become a measured candidate without becoming a
status promotion. The dashboard vocabulary needs that middle state because it
prevents both stale blockers and overconfident support claims.
