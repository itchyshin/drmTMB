# After Task: Q-Series q4 animal one-theta release diagnostic

## 1. Goal

Run the local q4 animal all-four hard-seed one-theta release diagnostic named
by the previous Gauss/Noether next-gate synthesis, without launching a DRAC
coverage grid or promoting any Q-Series row.

## 2. Implemented

This promotes exactly no Q-Series row under the animal q4 one-theta release
diagnostic channel, with hard seeds `910101`, `910102`, and `910110` and a
one-free-`theta_phylo` denominator, and does not claim q4 interval reliability,
q4 coverage, `inference_ready`, `supported`, q8 inference, q4 REML, REML,
AI-REML, broad bridge support, a production parameterization change, derived
correlation intervals, or public support.

Added `tools/run-structured-re-q4-animal-one-theta-release-diagnostic.R`. The
runner starts from the passing zero-correlation q4 animal map, releases exactly
one of the 28 `theta_phylo` coordinates at a time, and records objective gain
versus the zero map, `pdHess`, fixed-gradient maximum, `sdr$cov.fixed`
eigenvalues, released theta magnitude, and direct-SD shifts.

The dashboard sidecar
`structured-re-q4-animal-one-theta-release-diagnostic.tsv` now stores all 84
seed-coordinate rows. The raw artifact copy, run log, `sessionInfo.txt`, and
`git-sha.txt` are preserved under
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-one-theta-release-local/`.
The result split is 73 `one_theta_release_pass_smoke` rows, nine
`release_watch` rows, and two `hessian_blocked` rows. The Q-Series support
cell, high-q audit row, and compute queue now point to the one-theta diagnostic
as the latest q4 animal blocker evidence while keeping q4/q8 inference
blocked.

## 3a. Decisions and Rejected Alternatives

Decision: keep this result local and diagnostic. The single-coordinate releases
are informative, but two rows still become Hessian blocked with runaway theta
values and negative `sdr$cov.fixed` eigenvalues.

Decision: the next q4 animal gate should be a multi-coordinate MAP/penalty
sensitivity experiment or a production-transform design review, not a DRAC
coverage grid.

Rejected alternatives:

- Do not call 73 stable one-coordinate releases q4 admission.
- Do not treat the zero-correlation control or one-coordinate releases as
  unrestricted all-free q4 support.
- Do not promote q4/q8 interval status, coverage, `inference_ready`,
  `supported`, REML, AI-REML, derived-correlation intervals, bridge support, or
  public support from this diagnostic.

## 3b. Mathematical Contract

No likelihood, estimator, formula grammar, interval channel, or TMB
parameterization changed. The diagnostic uses the current animal A-matrix q4
all-four one-slope model:

- `mu1 = y1 ~ x + animal(1 + x | p | id, A = A)`
- `mu2 = y2 ~ x + animal(1 + x | p | id, A = A)`
- `sigma1 = ~ z + animal(1 + x | p | id, A = A)`
- `sigma2 = ~ z + animal(1 + x | p | id, A = A)`
- `rho12 = ~ 1`

Each release fixes 27 q4 animal correlation coordinates at zero and frees one
coordinate under the current TMB `theta_phylo` parameterization. The
lower-triangle endpoint-pair labels are a diagnostic map only; the direct
admission estimands remain the eight structured SDs.

## 4. Files Touched

- `tools/run-structured-re-q4-animal-one-theta-release-diagnostic.R`
- `docs/dev-log/dashboard/structured-re-q4-animal-one-theta-release-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-one-theta-release-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-stability-probe/structured-re-q4-slope-interval-stability-probe-results.tsv`
- `docs/dev-log/dashboard/structured-re-q4-slope-interval-stability-probe.tsv`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-one-theta-release-diagnostic.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse(file = "tools/run-structured-re-q4-animal-one-theta-release-diagnostic.R")); cat("parse_ok\n")'`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-q4-animal-one-theta-release-diagnostic.R --help`: passed.
- First smoke:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-one-theta-release-diagnostic.R --replicates=910101 --theta-indices=1 --output-dir=/tmp/drmtmb-q4-animal-one-theta-smoke --overwrite=true --write-dashboard=false`.
  This exposed the output-path reset bug described below.
- Repair run:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-slope-interval-stability-probe.R`:
  passed and restored the q4 slope stability artifact to 128 raw rows plus the
  64-row dashboard summary.
- Corrected smoke:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-one-theta-release-diagnostic.R --replicates=910101 --theta-indices=1 --output-dir=/tmp/drmtmb-q4-animal-one-theta-smoke --overwrite=true --write-dashboard=false`:
  passed and wrote the intended `/tmp` artifact.
- Three-seed/three-theta rehearsal:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-one-theta-release-diagnostic.R --replicates=910101,910102,910110 --theta-indices=1,8,28 --output-dir=/tmp/drmtmb-q4-animal-one-theta-3x3 --overwrite=true --write-dashboard=false`:
  passed with eight pass-smoke rows and one `release_watch` row.
- Full local diagnostic:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-one-theta-release-diagnostic.R --replicates=910101,910102,910110 --theta-indices=all --overwrite=true --write-dashboard=true`:
  passed, writing 84 dashboard and artifact rows.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed
  with `mission_control_ok`, including 84 structured RE q4 animal one-theta
  release diagnostic rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 7665 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q4-animal-one-theta-release-diagnostic.md')"`:
  passed with `after-task structure check passed`.
- `git diff --check`: passed.
- Dashboard JavaScript parse check with `node --check
  /tmp/drmtmb-dashboard-index.js`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Stale wording scan for pre-result one-theta next-gate phrases returned no
  matches.
- `env R_PROFILE_USER=/dev/null DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`:
  passed with `mission_control_ok`; the server was already listening at
  `http://127.0.0.1:8765/`.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt` returned
  `r124`; `/` contained `q4AnimalOneThetaReleaseDiagnostic`, `q4 one-theta`,
  and `one-theta release diagnostic`; the one-theta TSV served 85 lines
  including the header; the high-q queue row served the updated
  MAP/penalty/production-transform next action.

## 6. Tests of the Tests

The focused structured-RE conversion test now requires the exact 84-row matrix:
three hard seeds crossed with 28 released `theta_phylo` coordinates. It checks
the hard seed IDs, the assumed endpoint-pair map, diagnostic-only claim
boundary, artifact equality, the 73/9/2 pass/watch/Hessian status split, and
the two specific Hessian-blocked rows: `910101/theta26` and `910110/theta13`.

The mission-control validator now reads the sidecar, requires the same row
matrix and status split, verifies local artifact links, and rejects missing
guard phrases such as `no coverage`, `no inference_ready`, `no supported`,
`no q8 inference`, `no q4 REML`, `no REML`, and `no AI-REML`.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This was a local
diagnostic/dashboard banking slice inside the Q-Series high-q arc.

## 8. Consistency Audit

The linked Q-Series row
`qseries_animal_q4_all_four_one_slope_planned` remains diagnostic/high-q gated.
The sidecar records `interval_claim_status = diagnostic_only` and
`coverage_status = not_evaluable` for every row. The widget displays the new
one-theta link and summary beside the admission, numerical-geometry,
optimizer-route, start/map, and bounded-correlation q4 animal diagnostics.
The dashboard build was bumped to `r124`.

## 9. What Did Not Go Smoothly

The first smoke exposed a runner bug: sourcing the q4 stability helper
overwrote the new runner's local output-path variables, so the first smoke
briefly wrote the one-theta table into the old q4 slope stability raw artifact
path. I fixed the path reset, reran the original q4 slope stability probe to
restore the expected stability schema, and then reran the one-theta smoke.

The scientific result is also not a clean rescue. Most single-coordinate
releases are stable local smokes, but the failure pattern is still visible:
nine rows remain `release_watch`, and two rows are Hessian blocked with large
theta magnitudes. That keeps q4 animal admission closed.

## 10. Known Residuals

Animal q4 all-four correlation admission remains blocked. This diagnostic does
not validate an unrestricted all-free q4 model, an interior bounded transform,
a penalized likelihood, a q4 coverage denominator, q4 derived-correlation
intervals, q8, REML, AI-REML, or bridge support.

## 11. Team Learning

One-coordinate release is a useful microscope: it separates broadly stable
single correlation coordinates from a smaller set of problematic coordinates,
but it does not solve the joint 28-correlation geometry. DRAC should stay
reserved for later, after a local multi-coordinate design passes hard seeds.

## 12. Next Actions

- Ask Gauss/Noether to choose between a multi-coordinate MAP/penalty
  sensitivity experiment and a production-transform design review.
- Keep q4 coverage-grid design paused until the hard-seed correlation gate
  passes without runaway theta or negative `sdr$cov.fixed` eigenvalues.
- Ask Fisher/Rose to review any future denominator-policy change before a
  Q-Series status edit.
