# Q-Series q1 Mu+Sigma Intercept Local Smoke

## 1. Goal

Add a row-specific local smoke for the four Gaussian low-q q1 matched
`mu+sigma` intercept cells, while keeping all support-cell status fields
unchanged.

## 2. Implemented

- Added `tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R`.
- Ran the local n=1 smoke for phylo, spatial, animal, and relmat matched
  `mu+sigma` intercept rows.
- Retained three target rows per provider: direct `sd_mu`, direct `sd_sigma`,
  and the same-group `mu`-to-`sigma` random-effect correlation.
- Wrote the dashboard sidecar
  `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv`.
- Wrote raw artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-sigma-intercept-smoke-local/`.
- Updated `tools/validate-mission-control.py` so the sidecar and artifact bundle
  are mission-control guarded.
- Updated the widget to show a separate `Low-q mu+sigma` count, row-level links,
  and a detail table.
- Updated the dashboard README and bumped the widget version to `r137`.

## 3a. Decisions and Rejected Alternatives

- I kept the older low-q row-selection table on `matched_mu_sigma_design_hold`.
  The smoke is an overlay diagnostic, not a Fisher/Rose host-gate promotion.
- I used default-Wald `confint()` targets only. The purpose of this slice was a
  tiny target smoke, not profile calibration, bootstrap calibration, or coverage.
- I did not promote spatial, animal, or relmat despite 3/3 usable intervals in
  this seed. One replicate is smoke evidence only, and matched `mu+sigma` must
  not inherit q1 `mu`, q1 `sigma`, q2, q4/q8, or non-Gaussian evidence.

## 4. Files Touched

- `tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-sigma-intercept-smoke-local/structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-sigma-intercept-smoke-local/structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-sigma-intercept-smoke-local/structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke-seed-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-sigma-intercept-smoke-local/sessionInfo.txt`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-sigma-intercept-smoke-local/git-sha.txt`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q1-mu-sigma-intercept-local-smoke.md`

## 5. Checks Run

- `/opt/homebrew/bin/air format
  tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file
  tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R --help`:
  passed and printed the runner options.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file
  tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R
  --overwrite=true`: passed and wrote 4 summary rows and 12 target rows.
- Artifact inspection with `Rscript --no-init-file`: all four providers have
  3/3 `fit_ok`, 3/3 converged, 3/3 `pdHess`, and 3/3 `confint_ok` target rows;
  phylo has 2/3 usable intervals because the correlation target is
  `wald_at_boundary`; spatial, animal, and relmat have 3/3 usable intervals.
- Dashboard JavaScript parse check from `docs/dev-log/dashboard/index.html`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells and 4 Gaussian low-q `mu+sigma` intercept smoke
  rows.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q1-mu-sigma-intercept-local-smoke.md')"`:
  passed with `after-task structure check passed`.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: passed with 8253 PASS / 0 FAIL /
  0 WARN / 0 SKIP.

## 6. Tests of the Tests

The validator checks the mirrored dashboard summary against the artifact
summary, requires 12 retained target rows and 4 seed rows, pins the support
cells to `point_fit/planned/planned`, and requires phylo to retain
`wald_at_boundary` for the correlation target. If a future edit drops the
boundary warning, silently promotes a row, changes the target map, or rewrites
the artifact without the dashboard mirror, mission control should fail.

## 7a. Issue Ledger

- Added: a reproducible local smoke runner for q1 matched `mu+sigma` intercept
  rows.
- Added: a validator-owned smoke sidecar for those four support cells.
- Found and retained: phylo same-group `mu`-to-`sigma` correlation hits a
  boundary Wald interval in this seed, so the phylo cell remains
  diagnostic-only.
- Deferred: Fisher/Rose review is still required before any Totoro/FIIA smoke;
  Nibi/Rorqual/DRAC remain blocked.

## 8. Consistency Audit

- The support-cell TSV still has all four q1 `mu+sigma` intercept rows at
  `fit_status = point_fit`, `interval_status = planned`, and
  `coverage_status = planned`.
- The low-q row-selection sidecar still holds matched `mu+sigma` rows as local
  design holds.
- The widget now links these rows to the new smoke artifact without marking
  them `inference_ready`.
- The dashboard README describes the new sidecar as local smoke evidence only.
- Mission control counts the new four-row sidecar and rejects broad promotion
  wording.

## 9. What Did Not Go Smoothly

The first exploratory phylo probes hit helper and tree-validity issues before
the target labels were known. After switching to an ultrametric `ape::rcoal()`
probe, the real `confint()` labels became clear. The final smoke then exposed
the useful blocker: the phylo correlation Wald interval is at the boundary.

## 10. Known Residuals

This promotes exactly no Q-Series row. It is not coverage evidence, not
interval reliability, not `inference_ready`, not `supported`, not q2/q4/q8,
not non-Gaussian, not REML, not AI-REML, not bridge support, not public
support, and not cluster authorization. The next gate is Fisher/Rose review of
the target smoke and a decision on whether the correlation target needs a
profile or boundary-aware route before any larger denominator.

## 11. Team Learning

Matched location-scale rows need target-level accounting from the first smoke.
Fit stability can look clean while one correlation interval is already warning
at the boundary, so the dashboard should continue showing stability,
interval-usability, and inference-readiness as separate signals.
