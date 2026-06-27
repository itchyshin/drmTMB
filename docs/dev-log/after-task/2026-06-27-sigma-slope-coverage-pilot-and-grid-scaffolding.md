## 1. Goal

Begin the gated coverage stage of the q-series plan for the Gaussian
structured-RE sigma one-slope cells: de-risk the coverage methodology with a
local pilot, then build a cluster-ready SR475 grid runner + SLURM deployment so
the maintainer can execute the full coverage grid on DRAC (fir). No cluster job
is submitted in this slice; coverage evidence is NOT yet produced.

## 2. Implemented

- Added `tools/run-structured-re-sigma-slope-coverage-pilot.R`: a local 100-rep
  coverage pilot (phylo + relmat; sigma:(Intercept) and sigma:x direct-SD
  targets; log-scale Wald intervals; coverage vs known truth). Result:
  near-nominal coverage 96-98% across all four pilot cells, 100/100 converged.
- Added `tools/run-structured-re-sigma-slope-coverage-grid.R`: a cluster-ready,
  resumable SR475 grid runner for the 7 admitted targets (phylo x2, spatial x2,
  animal x1, relmat x2; animal sigma:x is the excluded profile-failure holdout),
  Wald + endpoint-profile intervals, boundary rows retained, shard CLI for SLURM
  arrays.
- Added `tools/slurm/sigma-slope-coverage-grid.sbatch`: SLURM array
  (`--array=1-7`, `def-snakagaw_cpu`, thread-pinned, scratch->project copy).
- Added `tools/slurm/DEPLOY-sigma-slope-coverage.md`: copy-paste deploy runbook
  (transfer, install drmTMB on fir, test, submit, collect).
- Added pilot + grid-smoke artifacts under
  `docs/dev-log/simulation-artifacts/`.

## 3a. Decisions and Rejected Alternatives

- I built the pilot first to de-risk the methodology before any cluster spend,
  rather than submitting a full grid blind. The pilot's near-nominal coverage
  justified building the full grid.
- The maintainer runs the cluster deployment: the harness exfiltration guard
  blocks me from transferring the package to fir, so I produced a complete,
  verified deployment package for the maintainer to execute instead.
- I scoped the grid to the 7 admitted denominator targets and kept animal
  sigma:x as a visible holdout, matching the banked denominator-admission
  sidecar.
- Bootstrap is off by default in the grid (Wald + profile primary) for speed;
  boundary non-finite rows are retained, not dropped.

## 4. Files Touched

- `docs/dev-log/after-task/2026-06-27-sigma-slope-coverage-pilot-and-grid-scaffolding.md`
- `docs/dev-log/simulation-artifacts/2026-06-27-sigma-slope-coverage-pilot/` (3 TSVs)
- `docs/dev-log/simulation-artifacts/sigma-slope-coverage-grid-smoke-local/` (14 TSVs)
- `tools/run-structured-re-sigma-slope-coverage-pilot.R`
- `tools/run-structured-re-sigma-slope-coverage-grid.R`
- `tools/slurm/sigma-slope-coverage-grid.sbatch`
- `tools/slurm/DEPLOY-sigma-slope-coverage.md`

(The build tarball `drmTMB_0.1.4.tar.gz` is regenerable via `R CMD build` and is
not committed.)

## 5. Checks Run

- `air format` on both runners passed.
- `Rscript --vanilla -e "parse(...)"` on both runners passed.
- `python3 tools/validate-mission-control.py` still reports `mission_control_ok`
  (no banked sidecar was changed).
- Local pilot: 400 fits (100 reps x phylo/relmat x 2 targets), 100% converged,
  coverage 96-98% over finite intervals.
- Local grid smoke: all 7 shards run at n_rep=6 end-to-end; measured ~0.1-0.2 s
  per replicate; resumability and shard map verified.
- DGP/model covariance alignment verified against the engine: spatial uses
  `drm_spatial_coords_precision(coords)` (R/drmTMB.R), animal `A=` is the
  additive relationship covariance, phylo/relmat pilot-validated.

## 6. Tests of the Tests

- The pilot/grid place the structured marker only in `sigma` with a plain `mu`,
  so a pass proves the rejection-free fit path and the SD interval target are
  exercised for the scale side specifically.
- The DGP draws structured effects using the same package covariance functions
  the model fits against (same `coords`, same `A`, same tree), so coverage is
  not an artifact of a mismatched data-generating covariance.
- The grid runner is resumable (skips seeds already written), so a requeued
  SLURM array task does not double-count or lose seeds.

## 7a. Issue Ledger

- Fixed: the sbatch `--time` rationale was internally inconsistent and 40x off
  the measured per-fit time; corrected to reflect ~0.1-1.0 s/fit (grid is
  minutes, not hours).
- Deferred: the SR475 coverage grid itself is NOT run here; the maintainer
  executes it on fir (harness blocks agent code transfer). Coverage evidence,
  denominator accounting, and any `coverage_status` promotion are future work.
- Deferred: spatial + animal coverage are estimated by the grid, not
  pre-validated (only phylo + relmat are pilot-validated).

## 8. Consistency Audit

- The 7-shard map in the runner matches the sbatch array and the banked
  denominator-admission targets; animal sigma:x stays excluded.
- Truth values (sd 0.50 / 0.38, mu 0.40/0.25, log-sigma -0.90) match the
  existing sigma-slope interval-smoke / stability-probe fixtures.
- No banked dashboard sidecar, validator, or existing test was modified; the
  mission-control validator remains green.

## 9. What Did Not Go Smoothly

- The cluster R/TMB/drmTMB environment is not set up on fir, so "submit" first
  requires a first-time drmTMB compile-deploy. The deploy runbook documents the
  login-node vs salloc compile path and the TMB/Matrix-skew fallback.
- The harness exfiltration guard hard-blocks transferring the package to the
  cluster, so the run is handed to the maintainer rather than driven end-to-end.

## 10. Known Residuals

- No coverage evidence exists yet; this slice is pilot + scaffolding only.
- Spatial profile intervals have a known non-finite rate; retained in the
  denominator and to be accounted for when results are analyzed.
- After results land: compute per-target coverage, bank a coverage sidecar +
  validator + after-task, and only then move sigma-slope `coverage_status` off
  `planned`. Do not promote `supported` without the full ladder.

## 11. Team Learning

De-risk before spend: a small local coverage pilot (100 reps) cheaply confirmed
near-nominal coverage and a correct DGP/model covariance match before committing
any cluster allocation. Verifying the data-generating covariance against the
engine's own construction functions is the key guard against a coverage grid
that runs cleanly but measures the wrong thing.
