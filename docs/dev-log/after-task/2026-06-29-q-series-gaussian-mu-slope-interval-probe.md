# After Task: Q-Series Gaussian Mu-Slope Interval Probe

## 1. Goal

Advance the four Gaussian q1 `mu` one-slope Q-Series rows from smoke-only
evidence to a local interval-admission rung, without promoting interval
coverage, `inference_ready`, `supported`, REML, AI-REML, q2/q4/q8, sigma,
non-Gaussian, bridge, or public-support claims.

## 2. Implemented

This promotes exactly no support cell. The support-cell rows for
`qseries_phylo_q1_mu_one_slope`, `qseries_spatial_q1_mu_one_slope`,
`qseries_animal_q1_mu_one_slope`, and
`qseries_relmat_q1_mu_one_slope` remain `fit_status = point_fit`,
`interval_status = planned`, and `coverage_status = planned`.

The local probe refit two small replicates per provider and ran default
`confint()` for the direct location-axis structured-SD targets. Phylo,
fixed-covariance spatial, and relmat each had 4/4 finite default intervals,
4/4 converged and `pdHess = TRUE` rows, and zero boundary Wald statuses. The
animal row had 4/4 converged and `pdHess = TRUE` rows but only 3/4 finite
default intervals because `sd:mu:animal(1 | id)` hit one boundary Wald status.

`structured-re-gaussian-mu-slope-admission-audit.tsv` now drives the widget:
phylo, spatial, and relmat display as `mu_slope_pregrid_planned`; animal
displays as `admission_blocked`. The target-level pregrid dry-run admits seven
clean direct-SD targets to an SR150 retained-outcome manifest and keeps the
animal intercept SD as a visible holdout.

## 3a. Decisions and Rejected Alternatives

The interval route is default `confint()` on the response-scale direct SD
targets, using the location-axis small-sample correction already installed for
structured-SD targets. The probe is intentionally not a coverage grid: SR2 per
provider is enough to verify names, status fields, finite interval accounting,
and boundary visibility, but not enough for coverage wording.

Rejected alternatives: no q1 `mu` row was promoted by analogy from q2 or sigma
evidence; the animal row was not hidden behind the three clean providers; and
the SR150 pregrid manifest was not described as coverage-evaluable because the
nominal MCSE at 0.95 coverage is 0.017795, above the 0.01 gate.

## 4. Files Touched

- `tools/run-structured-re-gaussian-mu-slope-interval-probe.R`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-admission-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-coverage-pregrid-dry-run.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-probe-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-interval-probe.md`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-interval-probe.R
```

Result: the generator wrote a four-row admission audit, an eight-row pregrid
dry-run ledger, a 16-row interval-probe result table, an eight-row probe
summary, a 150-row pregrid seed manifest, a 1050-row pregrid cell manifest,
`sessionInfo.txt`, `git-sha.txt`, and a run log.

Further validation is recorded in `docs/dev-log/check-log.md`.

## 6. Tests of the Tests

The mission-control validator now checks the new admission audit and pregrid
dry-run ledgers. It requires the linked support cells to stay Gaussian q1
`mu` one-slope rows with `interval_status = planned` and
`coverage_status = planned`, verifies the artifact row counts, verifies seven
pregrid targets plus one visible holdout, and requires claim boundaries to
mention no coverage-evaluable denominator evidence, `inference_ready`,
`supported`, REML, AI-REML, and public-support non-claims.

## 7a. Issue Ledger

No GitHub issue action was taken in this slice. The work updates local
mission-control evidence on the current Q-Series branch and does not open or
close a public capability claim.

## 8. Consistency Audit

The 104-row Q-Series table still has exactly five `inference_ready` rows and
zero structured rows called `supported`. The new widget states are sidecar
states only: three q1 `mu` rows are pregrid-planned, one q1 `mu` row is
admission-blocked, and all four remain not inference-ready until a retained
coverage denominator with MCSE `<= 0.01` and miss-balance review exists.

## 9. What Did Not Go Smoothly

The first all-provider terminal probe sourced only the DGP and summarise files;
the fit wrappers live in the smoke-runner files. After sourcing the runner
files, the probe completed. The first generator run also failed to capture the
git SHA because `git -C` was assembled in a way that split the workspace path
at the space in `Github Local`; the generator now changes to the repo root
before calling `git rev-parse HEAD`.

## 10. Known Residuals

The animal intercept SD boundary status is a real admission caveat for this
tiny probe. The next animal step is a boundary-focused interval diagnostic,
not row promotion. The seven clean targets may proceed to an SR150 pregrid,
but SR150 is still not enough for MCSE `<= 0.01`; support-grade or
`inference_ready` wording would need retained failures, finite interval rates,
one-sided misses, top-up to at least SR475/SR500 and likely SR1000 for stable
miss balance, plus Fisher and Rose review.

## Next Actions

Run the SR150 pregrid for the seven clean target endpoints with all outcomes
retained, while keeping `sd:mu:animal(1 | id)` as a visible holdout until the
boundary interval behaviour is diagnosed.

## 11. Team Learning

Q-Series row states need both cell-level and target-level evidence. A cell can
be fit-stable while one endpoint is not yet denominator-admitted; the widget
should expose that asymmetry instead of flattening all providers into one
status.
