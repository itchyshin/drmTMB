# After Task: Q-Series q4 animal MAP/penalty sensitivity diagnostic

## 1. Goal

Run and bank the local q4 animal all-four hard-seed MAP/penalty sensitivity
diagnostic named by the one-theta release next gate, without launching a DRAC
coverage grid or promoting any Q-Series row.

## 2. Implemented

This promotes exactly no Q-Series row under the animal q4 MAP/penalty
sensitivity diagnostic channel, with hard seeds `910101`, `910102`, and
`910110`, and does not claim q4 interval reliability, q4 coverage,
`inference_ready`, `supported`, q8 inference, q4 REML, REML, AI-REML, broad
bridge support, a production parameterization change, derived-correlation
intervals, or public support.

Added `tools/run-structured-re-q4-animal-map-penalty-sensitivity.R`. The runner
starts from the passing zero-correlation q4 animal map, releases
multi-coordinate `theta_phylo` sets derived from the one-theta non-pass,
top-gain, global non-pass, and all-28 coordinate sets, and optionally applies an
optimizer-layer ridge penalty. The penalty is a sensitivity probe, not a
production prior; `sdreport()` is still evaluated on the unpenalized TMB
curvature at the fitted point.

The dashboard sidecar
`structured-re-q4-animal-map-penalty-sensitivity.tsv` now stores all 30
seed-strategy rows. The raw artifact copy, run log, `sessionInfo.txt`, and
`git-sha.txt` are preserved under
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-map-penalty-local/`.
The result split is 21 `penalty_stabilized_local_mode` rows, seven
`runaway_theta_hessian_blocked` rows, and two `convergence_watch` rows. The
Q-Series support cell, high-q audit row, and compute queue now point to the
MAP/penalty diagnostic as the latest q4 animal blocker evidence while keeping
q4/q8 inference blocked.

## 3a. Decisions and Rejected Alternatives

Decision: keep this result local and diagnostic. The ridge-penalized routes
show that a local interior-like mode can be stabilized by the optimizer, but
that is not an inferential interval channel or a production parameterization.

Decision: the next q4 animal gate should be a production transform/admission
design that can pass the hard seeds without cap saturation, optimizer-layer
ridge penalties, convergence-watch rows, or Hessian-blocked multi-coordinate
rows.

Rejected alternatives:

- Do not call the 21 ridge-stabilized local modes q4 admission.
- Do not treat optimizer-layer ridge penalties as production priors.
- Do not treat the unpenalized multi-coordinate releases as coverage-ready.
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

Each strategy releases a selected set of current TMB `theta_phylo` coordinates
from the zero-correlation map. For ridge rows, the optimizer minimizes the
unpenalized objective plus `0.5 * lambda * sum(theta^2)` for released
coordinates, then reports unpenalized objective, penalized objective, gradients,
direct-SD shifts, and `sdreport()` diagnostics. The direct admission estimands
remain the eight structured SDs; derived-correlation intervals remain outside
this task.

## 4. Files Touched

- `tools/run-structured-re-q4-animal-map-penalty-sensitivity.R`
- `docs/dev-log/dashboard/structured-re-q4-animal-map-penalty-sensitivity.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-map-penalty-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-map-penalty-sensitivity.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse(file = "tools/run-structured-re-q4-animal-map-penalty-sensitivity.R")); cat("parse_ok\n")'`:
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-q4-animal-map-penalty-sensitivity.R --help`:
  passed.
- First smoke:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-map-penalty-sensitivity.R --replicates=910101 --output-dir=/tmp/drmtmb-q4-animal-map-penalty-smoke --overwrite=true --write-dashboard=false`.
  This exposed the output-path reset issue described below.
- Repair run:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-slope-interval-stability-probe.R`:
  passed and restored the q4 slope stability raw artifact to 128 rows plus the
  header and the dashboard sidecar to 64 rows plus the header.
- Corrected smoke after restoring the sibling artifact:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-map-penalty-sensitivity.R --replicates=910101 --output-dir=/tmp/drmtmb-q4-animal-map-penalty-smoke --overwrite=true --write-dashboard=false`:
  passed and wrote `/private/tmp/drmtmb-q4-animal-map-penalty-smoke/structured-re-q4-animal-map-penalty-sensitivity.tsv`.
- Full local diagnostic:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-map-penalty-sensitivity.R --replicates=910101,910102,910110 --overwrite=true --write-dashboard=true`:
  passed, writing 30 dashboard and artifact rows.
- `R_PROFILE_USER=/dev/null python3 -m py_compile tools/validate-mission-control.py`:
  passed; `tools/__pycache__` was removed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed
  with `mission_control_ok`, including 104 structured RE q-series cells and 30
  structured RE q4 animal MAP/penalty sensitivity rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 7724 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q4-animal-map-penalty-sensitivity.md')"`:
  passed with `after-task structure check passed`.
- `git diff --check`: passed.
- Dashboard JavaScript parse check with `node --check
  /tmp/drmtmb-dashboard-index.js`: passed.
- Stale wording scan:
  `rg -n "multi-coordinate MAP/penalty sensitivity or a production-transform|MAP/penalty sensitivity or a production-transform|next work is local multi-coordinate MAP/penalty|before MAP/penalty sensitivity" docs/dev-log/dashboard docs/dev-log/after-task docs/dev-log/check-log.md tests tools`:
  only matched the historical q4 animal next-gate synthesis after-task note.
- `env R_PROFILE_USER=/dev/null DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`:
  passed with `mission_control_ok`; the server was already listening at
  `http://127.0.0.1:8765/`.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt` returned
  `r125`; the MAP/penalty TSV served 31 lines including the header; `/`
  contained `q4AnimalMapPenaltySensitivity`, `Animal q4 MAP`, and
  `q4 MAP/penalty`; the high-q queue row served the production-transform /
  no-DRAC-coverage next action.

## 6. Tests of the Tests

The focused structured-RE conversion test now requires the exact 30-row matrix:
three hard seeds crossed with 10 MAP/penalty strategies. It checks the hard seed
IDs, diagnostic-only claim boundary, artifact equality, the 21/7/2
stabilized/runaway/watch status split, ridge-positive stabilized rows, and
unpenalized runaway rows with large released theta and numerical-domain
warnings.

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
MAP/penalty link and summary beside the admission, numerical-geometry,
optimizer-route, start/map, bounded-correlation, and one-theta q4 animal
diagnostics. The dashboard build was bumped to `r125`.

## 9. What Did Not Go Smoothly

The first smoke repeated the path-reset problem seen in the one-theta runner:
sourcing the q4 stability helper overwrote output-path variables and briefly
wrote MAP/penalty rows into the old q4 slope stability artifact path. I reset
the MAP/penalty output paths after sourcing, reran the original q4 slope
stability probe to restore the raw artifact and dashboard sidecar, verified the
raw artifact had the q4 slope schema and 129 lines, and then reran the smoke
before writing the real artifact.

The scientific result is also not a rescue. Ridge penalties stabilize local
modes, but the unpenalized multi-coordinate release still has seven
runaway/Hessian-blocked rows and two convergence-watch rows. That keeps q4
animal admission closed.

## 10. Known Residuals

Animal q4 all-four correlation admission remains blocked. This diagnostic does
not validate an unrestricted all-free q4 model, an interior bounded transform,
a production penalized likelihood, a q4 coverage denominator, q4
derived-correlation intervals, q8, REML, AI-REML, or bridge support.

## 11. Team Learning

MAP/penalty sensitivity is useful as a numerical microscope: it shows that the
hard seeds have stabilizable local modes, but only through an optimizer-layer
penalty that trades inference meaning for geometry. DRAC should stay reserved
for a later admission or coverage run after a production transform or
denominator contract exists.

## 12. Next Actions

- Ask Gauss/Noether to design a production transform/admission experiment for
  the hard q4 animal free-correlation block.
- Keep q4 coverage-grid design paused until the hard-seed correlation gate
  passes without cap saturation, optimizer-layer ridge penalties,
  convergence-watch rows, or Hessian-blocked multi-coordinate rows.
- Ask Fisher/Rose to review any future denominator-policy change before a
  Q-Series status edit.
