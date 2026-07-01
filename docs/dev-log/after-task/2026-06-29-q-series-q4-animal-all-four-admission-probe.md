# After Task: Q-Series animal q4 all-four admission probe

## 1. Goal

Turn the promising animal q4 all-four deterministic stability signal into a
replicated admission smoke, without promoting q4 interval reliability,
coverage, `inference_ready`, `supported`, q8, REML, AI-REML, bridge support, or
public support.

## 2. Implemented

This promotes exactly no Q-Series row under the animal q4 all-four direct-SD
Wald/profile diagnostic channel, with retained fit/Hessian denominator
accounting, and does not claim q4 interval reliability, q4 coverage,
`inference_ready`, `supported`, q8 support, REML, AI-REML, broad bridge
support, or public support.

Added `tools/run-structured-re-q4-animal-all-four-admission-probe.R`, a
replicated animal-only runner for
`qseries_animal_q4_all_four_one_slope_planned`. The runner sources the existing
q4 all-four stability-probe helper prefix so the DGP, formula, target map, and
interval call shape stay aligned with the fixed June 24 q4 diagnostic. It adds
safe `--help`, `--n-rep`, `--seed-start`, `--seed-base`, `--variant`,
`--methods`, `--profile-max-eval`, `--output-dir` / `--out-dir`,
`--overwrite`, and `--write-dashboard` controls.

Ran a two-replicate local smoke for the `more_levels` variant. Both animal q4
fits converged with fallback BFGS, but only one had `pdHess = TRUE`. The
positive-Hessian replicate had finite Wald and endpoint-profile intervals for
all eight direct-SD targets. The `pdHess = FALSE` replicate is retained as
`not_run_pdhess_false`, so the dashboard sidecar reports 1/2 `pdHess`, 8/16
finite Wald target-replicate rows, and 8/16 finite profile target-replicate
rows.

Then ran a corrected 16-replicate Nibi admission tranche, job `16923114`, from
the source snapshot at
`/project/def-snakagaw/snakagaw/drmtmb-qseries/20260629-q4-animal-admission-77b634ed-noload/source`.
The tranche completed with exit `0:0`, but it strengthened the blocker:
16/16 fits converged and only 2/16 had `pdHess = TRUE`. The retained artifact
has 256 method-target-replicate rows, including 112 Wald and 112 profile rows
kept as `not_run_pdhess_false`, 16 finite Wald rows, 14 finite profile rows,
and 2 nonfinite profile rows. The dashboard sidecar now reports
`pdhess_admission_blocked`, not an admission pass.

Added `structured-re-q4-animal-hessian-geometry-diagnostic.tsv`, an
endpoint-level diagnostic derived from the same Nibi artifact. It records all
eight direct-SD endpoints with 16/16 converged fits, 2/16 `pdHess`, zero
estimates below 0.10, incomplete profile finiteness, and
`hessian_geometry_not_simple_boundary`. This makes the next step a
Gauss/Noether q8-shaped Hessian/correlation geometry review rather than more
q4 coverage compute.

## 3a. Decisions and Rejected Alternatives

Decision: do not use Nibi, Rorqual, or Totoro for q4 coverage yet. The local
smoke found a real admission blocker: `pdHess` retention is only 1/2 under this
replicated animal q4 fixture. The Nibi 16-replicate tranche confirmed the
blocker at 2/16 `pdHess`, so the next useful work is numerical geometry review,
not a larger coverage campaign.

Rejected alternatives:

- Do not treat the prior deterministic animal q4 profile-finite endpoints as a
  denominator-admitted row.
- Do not submit q4 coverage arrays to DRAC from a 1/2 `pdHess` smoke.
- Do not submit q4 coverage arrays to DRAC from the 2/16 `pdHess` Nibi
  admission tranche.
- Do not call the animal q4 row `inference_ready` or `supported`.
- Do not borrow this direct-SD evidence for derived q4 correlations, q8 rows,
  REML, AI-REML, bridge parity, or public support.

## 3b. Mathematical Contract

No likelihood, formula grammar, estimator, or interval implementation changed.
The runner uses the same animal A-matrix q4 all-four one-slope DGP and formula
shape as the q4 stability probe:

- `mu1 = y1 ~ x + animal(1 + x | p | id, A = A)`
- `mu2 = y2 ~ x + animal(1 + x | p | id, A = A)`
- `sigma1 = ~ z + animal(1 + x | p | id, A = A)`
- `sigma2 = ~ z + animal(1 + x | p | id, A = A)`
- `rho12 = ~ 1`

The estimands are the eight direct SD targets only:
`mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, `mu2:x`,
`sigma1:(Intercept)`, `sigma1:x`, `sigma2:(Intercept)`, and `sigma2:x`.
Derived correlations remain out of scope.

## 4. Files Touched

- `tools/run-structured-re-q4-animal-all-four-admission-probe.R`
- `docs/dev-log/dashboard/structured-re-q4-animal-all-four-admission-probe.tsv`
- `docs/dev-log/dashboard/structured-re-q4-animal-hessian-geometry-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-all-four-admission-probe-local/`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-all-four-admission-probe-nibi/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/slurm/q4-animal-admission-nibi.sbatch`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-all-four-admission-probe.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-q4-animal-all-four-admission-probe.R --help`: passed and exited before fitting.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'parse("tools/run-structured-re-q4-animal-all-four-admission-probe.R"); cat("parse_ok\n")'`: passed.
- `air format tools/run-structured-re-q4-animal-all-four-admission-probe.R`: passed.
- Plumbing check: `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-all-four-admission-probe.R --n-rep=1 --seed-start=910003 --variant=more_levels --out-dir=/tmp/drmtmb-q4-animal-admission-plumbing --write-dashboard=false --overwrite=true`: passed; wrote to `/tmp` and recorded git SHA `77b634eda91b0173926557ce5c4a3d20853fb215`.
- Local dashboard smoke: `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-all-four-admission-probe.R --n-rep=2 --seed-start=910001 --variant=more_levels --output-dir=docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-all-four-admission-probe-local --write-dashboard=true --overwrite=true`: passed with two converged fits, 1/2 `pdHess`, 8/16 finite Wald direct-SD target-replicate rows, and 8/16 finite profile direct-SD target-replicate rows.
- First Nibi dispatch, job `16922989`: failed before fitting because the
  cluster module did not provide `devtools`; no result artifacts were written.
- Local no-`devtools` smoke after fixing the runner:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-all-four-admission-probe.R --n-rep=1 --seed-start=910201 --variant=more_levels --methods=wald --output-dir=/tmp/drmtmb-q4-animal-admission-no-load-all --write-dashboard=false --overwrite=true --attempt-temp-install --no-load-all`: passed.
- Corrected Nibi dispatch, job `16923114`: `COMPLETED`, exit `0:0`, elapsed
  `00:08:06`, with result artifacts fetched into
  `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-all-four-admission-probe-nibi/`.
- `air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including one structured RE q4 animal all-four admission probe row and eight q4 animal Hessian-geometry diagnostic rows backed by the Nibi 16-replicate artifact.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 6996 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `git diff --check`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`: dashboard already listening at `http://127.0.0.1:8765/`.
- Served dashboard verification: `curl -fsS http://127.0.0.1:8765/version.txt` returned `r108`, and the new `structured-re-q4-animal-hessian-geometry-diagnostic.tsv` served with eight Nibi-derived endpoint rows.

## 6. Tests of the Tests

The first local smoke found two runner-plumbing defects before dashboard
promotion: `--out-dir` was not accepted as an alias for `--output-dir`, and
the git-SHA writer failed when the repository path contained a space. The
follow-up plumbing check verified both fixes. A second rerun caught a stale
`source_artifact` path caused by sourcing the existing q4 helper prefix; the
runner now restores its own artifact directory after sourcing and the dashboard
sidecar link resolves locally. The mission-control validator and focused R
dashboard contract now require the exact one-row admission schema, the
eight-row endpoint geometry schema, raw 256-row Nibi interval artifact, 2/16
`pdHess` split, retained `not_run_pdhess_false` rows, profile nonfinite rows,
coverage `not_evaluable`, diagnostic-only claim wording, and the linked
Q-Series row's fixture-only status.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This was a local
diagnostic/dashboard banking slice inside the Q-Series high-q arc.

## 8. Consistency Audit

The Q-Series support cell remains planned for interval and coverage status.
The widget tables say `diagnostic_only` and `not_evaluable`, not
`inference_ready`. The claim boundaries explicitly reject coverage evidence,
`inference_ready`, `supported`, q8 inference, q4 REML, REML, AI-REML, broad q4
bridge support, and derived-correlation interval promotion. The dashboard README
now documents the admission sidecar and the endpoint Hessian-geometry sidecar
next to the existing q4 all-four stability probe, and mission-control will fail
if either sidecar drifts into a promotion-looking claim. The dashboard build
marker is `r108` for the Nibi-backed sidecars.

## 9. What Did Not Go Smoothly

The first smoke wrote to the default repo artifact directory because the runner
did not yet accept `--out-dir`. The git SHA file was empty on that first pass
because `git -C` was invoked from R without guarding the space in `Github
Local`. Both were fixed before the final dashboard-writing run. The first
focused R contract also failed on a cosmetic `table()` dimname mismatch; the
test now compares the exact table shape R writes. The first Nibi dispatch then
failed because the cluster module did not provide `devtools`; the runner now
supports `--attempt-temp-install --no-load-all` and filters the inherited
`devtools::load_all()` line from the sourced q4 stability prefix.

## 10. Known Residuals

Animal q4 all-four direct-SD admission is not passed. The immediate blocker is
replicate-level Hessian stability: 2/16 Nibi admission-tranche fits had
`pdHess = TRUE`. The endpoint geometry sidecar suggests this is not a simple
near-zero SD boundary collapse because all endpoint rows have
`n_estimate_lt_0_10 = 0`; it still requires numerical review of the
q8-shaped Hessian/correlation parameterization. The finite interval rate is
therefore not a coverage denominator and must not be interpreted as interval
reliability. Derived q4 correlations, q8 rows, REML, AI-REML, and bridge parity
remain separate future work.

## 11. Team Learning

DRAC should be used only for admission gates until the denominator is stable.
For this row, the 16-replicate Nibi tranche confirms that the pdHess rate is
far below the 95% admission gate. Fisher's review agrees that no q4 coverage,
q1 `mu` top-up, or spatial sigma top-up is inference-safe until the active
blockers change. The right next task is Gauss/Noether numerical geometry, not
more replicates or a coverage grid.

## 12. Next Actions

- Keep coverage status `not_evaluable` until `pdHess` and finite direct-SD
  interval rates clear the admission gate.
- Ask Gauss/Noether to inspect why the replicated animal A-matrix q4 all-four
  geometry produces 14/16 non-positive Hessians under the current DGP.
- Ask Fisher and Rose to review any future admission-threshold change before
  editing Q-Series status rows.
