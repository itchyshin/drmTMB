# After Task: Q-Series spatial sigma boundary diagnostic

## 1. Goal

Make the current-source spatial q1 `sigma:(Intercept)` blocker visible in the
Q-Series widget and validator, using the Nibi diagnostic run rather than
promoting `qseries_spatial_q1_sigma_one_slope`.

## 2. Implemented

This promotes exactly no Q-Series row under either the raw log-SD Wald channel
or the profile channel, with retained 475-replicate denominator accounting, and
does not claim spatial sigma `inference_ready`, `supported`,
range-estimating spatial support, matched `mu+sigma`, q2, q4/q8, REML,
AI-REML, bridge support, or public support.

Added `structured-re-spatial-sigma-boundary-diagnostic.tsv`, a one-row
current-source Nibi sidecar for `qseries_spatial_q1_sigma_one_slope`. Job
`16920961` ran 475 planned replicates against local source
`77b634eda91b0173926557ce5c4a3d20853fb215`: 475/475 fits converged with
`pdHess = TRUE`, but only 443/475 Wald intervals were finite and 32 estimates
were boundary-small. Finite-Wald coverage was 438/443 = 0.9887, but retained
Wald coverage was 438/475 = 0.9221. The profile channel was finite for
475/475 replicates but covered only 423/475 = 0.8905, with 5 lower and 47
upper misses. The sidecar therefore records
`boundary_estimate_blocker_reproduced` and `do_not_promote`.

The mission-control widget now renders a "Spatial sigma diag" summary card,
links the affected support-cell row to the diagnostic artifact, and includes
the diagnostic in the row-level evidence note. The linked Q-Series support
cell remains `interval_status = planned` and `coverage_status = planned`.

## 3a. Decisions and Rejected Alternatives

Decision: use Nibi as the primary DRAC host for this blocker confirmation and
keep Rorqual for confirmation or overflow. Totoro was treated as reachable but
not batch-usable from the current key path, so no compute time was spent trying
to force this diagnostic through Totoro.

Rejected alternatives:

- Do not top up spatial sigma again while the finite-Wald loss is boundary
  shaped; more replicates would make the failure estimate sharper without
  removing the blocker.
- Do not use finite-subset Wald coverage as an inference-ready claim because
  retained-denominator coverage falls below the gate.
- Do not use profile coverage as a rescue channel because the profile channel
  covers only 0.8905 with strong upper-tail miss imbalance.
- Do not edit `structured-re-q-series-support-cells.tsv` from this diagnostic.

## 3b. Mathematical Contract

No likelihood, formula grammar, or interval implementation changed. The
diagnostic reuses the existing spatial q1 sigma one-slope simulation target
and records empirical denominator behaviour for the direct SD target
`sd:sigma:spatial(1 | site)`. The contract is descriptive: finite intervals,
coverage, lower/upper misses, and boundary-small estimates are reported under
the retained replicate denominator, and no status promotion follows from
survivor-only coverage.

## 4. Files Touched

- `tools/slurm/spatial-sigma-boundary-nibi.sbatch`
- `tools/summarize-structured-re-spatial-sigma-boundary-diagnostic.R`
- `docs/dev-log/dashboard/structured-re-spatial-sigma-boundary-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-spatial-sigma-boundary-nibi/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-spatial-sigma-boundary-diagnostic.md`

## 5. Checks Run

- `ssh -o BatchMode=yes nibi true`: passed; Nibi is usable for batch work.
- `ssh -o BatchMode=yes rorqual true`: passed; Rorqual is usable for overflow
  or confirmation.
- `ssh -o BatchMode=yes totoro true`: failed with
  `Permission denied (publickey,password)`; Totoro was not used for this run.
- `ssh -o BatchMode=yes fiia true`: failed because the `fiia` alias does not
  resolve from this shell.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-sigma-slope-coverage-grid.R --shard=3 --n_rep=20 --seed_start=742001 --out_dir=/tmp/drmtmb-spatial-sigma-current-smoke --bootstrap=0 --attempt-temp-install`: passed; 20/20 fits, 18/20 finite Wald intervals, 16/20 finite profile intervals.
- `sbatch tools/slurm/spatial-sigma-boundary-nibi.sbatch`: submitted Nibi job
  `16920961`.
- `sacct -j 16920961`: completed with exit code `0:0`, elapsed `00:10:36`,
  MaxRSS about 3.65 GB.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-spatial-sigma-boundary-diagnostic.R --artifact_dir=docs/dev-log/simulation-artifacts/2026-06-29-spatial-sigma-boundary-nibi --output=docs/dev-log/dashboard/structured-re-spatial-sigma-boundary-diagnostic.tsv --cluster_host=nibi --cluster_job=16920961 --package_git_sha=77b634eda91b0173926557ce5c4a3d20853fb215`: passed.
- `air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R tools/summarize-structured-re-spatial-sigma-boundary-diagnostic.R`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `bash -n tools/slurm/spatial-sigma-boundary-nibi.sbatch`: passed.
- Extracting the dashboard script from `docs/dev-log/dashboard/index.html` and
  running `node --check /tmp/drmtmb-dashboard-script.js`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 1 structured RE spatial sigma
  boundary-diagnostic row.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: passed with 6803 PASS / 0 FAIL / 0 WARN / 0 SKIP after the test path fix.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-spatial-sigma-boundary-diagnostic.md')"`: passed.
- `git diff --check`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`: passed after normalizing permissions on the fetched Nibi artifact directory; the dashboard was already listening at `http://127.0.0.1:8765/`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r104`.
- `curl -fsS http://127.0.0.1:8765/structured-re-spatial-sigma-boundary-diagnostic.tsv | sed -n '1,2p'`: served the diagnostic header and `spatial_sigma_boundary_nibi_current_source` row.
- `curl -fsS http://127.0.0.1:8765/index.html | rg 'r104|Spatial sigma diag|structured-re-spatial-sigma-boundary-diagnostic|spatialSigmaBoundaryDiagnostic'`: found all widget markers.
- `curl -fsS http://127.0.0.1:8765/docs/dev-log/simulation-artifacts/2026-06-29-spatial-sigma-boundary-nibi/03-spatial-sigma_intercept-replicates.tsv | sed -n '1,1p'`: served the linked replicate TSV header.

## 6. Tests of the Tests

The first focused R run failed because the new test compared the SLURM job id
as a character string after `read.delim()` had inferred it as an integer, and
because the evidence path was resolved relative to the test working directory
instead of the repository root. The fixed test now coerces `cluster_job` to
character, resolves the linked artifact with `structured_re_artifact_path()`,
and parses the replicate TSV header. The passing test therefore checks both
the row contract and the local evidence file rather than only testing that a
sidecar row exists.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. The live issue sweeps
returned no open matches:

- `gh issue list --state open --search "qseries spatial sigma boundary" --limit 10`
- `gh issue list --state open --search "structured re sigma q-series" --limit 10`

## 8. Consistency Audit

The sidecar, widget, README, validator, and focused R test now agree that this
is blocker-only evidence for `qseries_spatial_q1_sigma_one_slope`. The support
cell stays `planned/planned`, and the claim boundary explicitly blocks
`inference_ready`, `supported`, q2, q4/q8, REML, AI-REML, bridge support, and
public support.

The dashboard wording was checked around the Q-Series support-cell section so
the spatial sigma diagnostic appears alongside the other row-level blockers
rather than in a promotion summary. The mission-control validator also checks
that the evidence URL resolves locally and that the linked support cell has
not been promoted.

## 9. What Did Not Go Smoothly

The existing SR1000 spatial sigma blocker looked like a denominator problem
until the current-source Nibi run showed the same finite-Wald loss with
boundary-small estimates. The first R test also exposed two small contract
details: TSV type inference for numeric-looking identifiers, and repo-relative
artifact paths inside `devtools::test()`.

The first dashboard serve attempt also failed while copying the fetched Nibi
artifact directory because the directory modes were too restrictive for the
`/tmp/drm-dashboard` mirror. Normalizing permissions on that one artifact
directory fixed the serve path without changing the scientific artifact
contents.

## 10. Known Residuals

Spatial q1 sigma remains blocked. A sigma-specific interval channel,
DGP/estimator adjustment, or a clearer boundary-aware claim would be needed
before another top-up is useful. This diagnostic does not address animal
sigma, matched `mu+sigma`, q2, q4/q8, non-Gaussian rows, REML, AI-REML, or
bridge support.

## 11. Team Learning

For Q-Series sigma rows, denominator loss must be classified by failure shape
before spending cluster budget on top-ups. If nonfinite Wald intervals are
boundary-small, the next tranche should change the interval route or estimand
rather than simply increasing `n_rep`.

## 12. Next Actions

- Use Nibi as the default sustained DRAC host and Rorqual as the independent
  confirmation/overflow host.
- Keep Totoro out of the compute path until batch auth is clean.
- Decide whether the next Q-Series slice should be a sigma-specific interval
  design, a Gaussian low-q non-sigma gate, or a high-q stability gate.
