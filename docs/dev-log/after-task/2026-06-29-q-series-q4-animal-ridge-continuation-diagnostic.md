# After Task: Q-Series q4 animal ridge-continuation diagnostic

## 1. Goal

Run and bank the local q4 animal all-four hard-seed ridge-continuation
diagnostic before spending Nibi/Rorqual or DRAC time. The diagnostic asks
whether ridge-stabilized multi-coordinate `theta_phylo` fits can be annealed
back to the unpenalized likelihood target.

## 2. Implemented

This promotes exactly no Q-Series row under the animal q4
ridge-continuation diagnostic channel, with hard seeds `910101`, `910102`,
and `910110`, and does not claim q4 interval reliability, q4 coverage,
`inference_ready`, `supported`, q8 inference, q4 REML, REML, AI-REML, broad
bridge support, a production parameterization change, derived-correlation
intervals, or public support.

Added `tools/run-structured-re-q4-animal-ridge-continuation-diagnostic.R`.
The runner starts from the passing zero-correlation q4 animal map, releases
the `seed_nonpass`, `global_nonpass`, and `all28` coordinate sets, then
anneals the optimizer-layer ridge schedule `1 -> 0.1 -> 0.01 -> 0`. Each
stage records the unpenalized objective, penalized objective, gradients,
`sdreport()` Hessian status, covariance diagnostics, direct-SD shifts, and
theta geometry.

The dashboard sidecar
`structured-re-q4-animal-ridge-continuation-diagnostic.tsv` now stores all
36 seed-strategy-stage rows. The raw artifact copy, run log,
`sessionInfo.txt`, and `git-sha.txt` are preserved under
`docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-ridge-continuation-local/`.
The result split is 25 `continuation_penalty_stabilized_local_mode` rows, six
`continuation_runaway_theta_hessian_blocked` rows, two
`continuation_hessian_blocked` rows, two `continuation_convergence_watch`
rows, and one `continuation_unpenalized_large_theta_watch` row. At the final
`lambda = 0` stage, zero of nine hard-seed strategy rows are clean admission
passes.

## 3a. Decisions and Rejected Alternatives

Decision: keep this result local and diagnostic. Ridge continuation shows that
penalty support can stabilize local modes, but annealing back to the
unpenalized target does not produce a clean hard-seed admission route.

Decision: the next q4 animal gate remains the production-transform admission
experiment. The production route must pass hard seeds `910101`, `910102`, and
`910110` without cap saturation, optimizer-layer ridge penalties,
large-theta rows, convergence-watch rows, or Hessian-blocked
multi-coordinate rows.

Rejected alternatives:

- Do not call the single pdHess/convergence-clean but large-theta final row an
  admission pass.
- Do not treat ridge-continuation annealing as a production prior or interval
  method.
- Do not launch DRAC coverage from the current q4 animal all-four route.
- Do not promote q4/q8 interval status, coverage, `inference_ready`,
  `supported`, REML, AI-REML, derived-correlation intervals, bridge support,
  or public support from this diagnostic.

## 3b. Mathematical Contract

No likelihood, estimator, formula grammar, interval channel, or TMB
parameterization changed. The diagnostic uses the current animal A-matrix q4
all-four one-slope model:

- `mu1 = y1 ~ x + animal(1 + x | p | id, A = A)`
- `mu2 = y2 ~ x + animal(1 + x | p | id, A = A)`
- `sigma1 = ~ z + animal(1 + x | p | id, A = A)`
- `sigma2 = ~ z + animal(1 + x | p | id, A = A)`
- `rho12 = ~ 1`

For `lambda > 0`, the optimizer minimizes the unpenalized objective plus
`0.5 * lambda * sum(theta^2)` for released coordinates. At each stage,
`sdreport()` is evaluated against the unpenalized TMB object pinned to the
stage optimum. The final `lambda = 0` stage is the admission-relevant
diagnostic; it did not pass cleanly for any hard-seed strategy row.

## 4. Files Touched

- `tools/run-structured-re-q4-animal-ridge-continuation-diagnostic.R`
- `docs/dev-log/dashboard/structured-re-q4-animal-ridge-continuation-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-ridge-continuation-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/structured-re-q4-animal-transform-admission-contract.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-ridge-continuation-diagnostic.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'parse("tools/run-structured-re-q4-animal-ridge-continuation-diagnostic.R"); cat("parse_ok\n")'`:
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-q4-animal-ridge-continuation-diagnostic.R --help`:
  passed.
- Smoke:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-ridge-continuation-diagnostic.R --replicates=910101 --strategies=seed_nonpass --lambda-schedule=1,0.1,0 --output-dir=/tmp/drmtmb-q4-animal-ridge-continuation-smoke --overwrite=true --write-dashboard=false`:
  passed after fixing the schedule-label and `git_sha` bookkeeping bugs.
- Full local diagnostic:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-ridge-continuation-diagnostic.R --replicates=910101,910102,910110 --overwrite=true --write-dashboard=true`:
  passed, writing 36 dashboard and artifact rows.
- After the first full run, Rose/Fisher review tightened the status rule so a
  final unpenalized row with `theta_max_abs > 100` is a large-theta watch, not
  an admission smoke pass. The full local diagnostic was rerun with the
  stricter rule and produced zero clean final-stage admission passes.
- Dashboard JavaScript parse check with `node --check
  /tmp/drmtmb-dashboard-index.js`: passed.
- `R_PROFILE_USER=/dev/null python3 -m py_compile tools/validate-mission-control.py`:
  passed.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed
  with `mission_control_ok`, including 104 structured RE q-series cells, 36
  structured RE q4 animal ridge-continuation diagnostic rows, and 7 structured
  RE q4 animal transform-admission contract rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 7819 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q4-animal-ridge-continuation-diagnostic.md')"`:
  passed with `after-task structure check passed`.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt`
  returned `r128`; the ridge-continuation TSV served 37 lines including the
  header; `/` contained `q4AnimalRidgeContinuationDiagnostic`, `Animal q4
  anneal`, and `q4 ridge continuation`; the support cell and high-q queue
  served the no-large-theta / no-DRAC next gate.

## 6. Tests of the Tests

The focused structured-RE conversion test now requires the exact 36-row matrix:
three hard seeds crossed with three strategies and four ridge-continuation
stages. It checks the diagnostic-only claim boundary, artifact equality,
schedule, source sidecars, the 25/6/2/2/1 status split, the nine final-stage
statuses, and the absence of a final
`continuation_unpenalized_admission_smoke_pass`.

The mission-control validator now reads the sidecar, requires the same row
matrix, final-stage status split, local artifact links, and forbidden-claim
phrases. The transform-admission contract, high-q audit, support-cell row, and
campaign queue now include large-theta rows as a blocker before Nibi/Rorqual or
DRAC work.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This was a local
diagnostic/dashboard banking slice inside the Q-Series high-q arc.

## 8. Consistency Audit

The linked Q-Series row
`qseries_animal_q4_all_four_one_slope_planned` remains diagnostic/high-q
gated. The sidecar records `interval_claim_status = diagnostic_only` and
`coverage_status = not_evaluable` for every row. The dashboard build is
`r128`; the widget displays the ridge-continuation card, link, note, and
table while keeping the transform-admission contract as the next gate.

## 9. What Did Not Go Smoothly

The first smoke caught a scalar/vector bug in the schedule label. The second
smoke wrote rows but failed at the final status summary because the `git_sha`
helper reused the name `out` and overwrote the result data frame. Both bugs
were fixed before the full artifact was banked.

The first full run initially classified one final `lambda = 0` row as
`continuation_unpenalized_admission_smoke_pass`. Review showed that row had
very large theta magnitude, so the status rule was tightened and the full run
was repeated. The final banked sidecar records that row as
`continuation_unpenalized_large_theta_watch`.

## 10. Known Residuals

Animal q4 all-four correlation admission remains blocked. This diagnostic does
not validate an unrestricted all-free q4 model, an interior bounded transform,
a production penalized likelihood, a q4 coverage denominator, q4
derived-correlation intervals, q8, REML, AI-REML, or bridge support.

## 11. Team Learning

Annealing a ridge-supported local mode is a useful numerical microscope, but
it is not an admission route unless the final unpenalized target has stable
theta, convergence, `pdHess`, and finite covariance on all hard seeds. DRAC
coverage should stay reserved for a route that passes that local admission
gate first.

## 12. Next Actions

- Implement a production-transform admission experiment for hard seeds
  `910101`, `910102`, and `910110`.
- Use local first and Totoro/FIIA second for diagnostic smoke; use
  Nibi/Rorqual only for a prespecified admission probe.
- Keep DRAC coverage-grid design paused until the hard-seed q4 animal
  correlation gate passes without cap saturation, optimizer-layer ridge
  penalties, large-theta rows, convergence-watch rows, or Hessian-blocked
  multi-coordinate rows.
