# After Task: Q-Series q4 animal start-map diagnostic

## 1. Goal

Bank a lower-level start/map diagnostic for the animal q4 all-four one-slope
row after optimizer-route comparisons failed to rescue the failed-Hessian
seeds, without promoting q4 interval reliability, coverage, `inference_ready`,
`supported`, q8, REML, AI-REML, bridge support, or public support.

## 2. Implemented

This promotes exactly no Q-Series row under the animal q4 start/map diagnostic
channel, with selected-seed TMB map/start accounting, and does not claim q4
interval reliability, q4 coverage, `inference_ready`, `supported`, q8 support,
REML, AI-REML, broad bridge support, derived-correlation intervals, or public
support.

Added `tools/run-structured-re-q4-animal-start-map-diagnostic.R`, a small
internal runner that builds the same animal q4 all-four TMB object through the
internal bivariate Gaussian spec path. The runner compares four selected
`more_levels` seeds (`910101`, `910102`, `910107`, `910110`) across seven
strategies:

- all-free default starts;
- all-free small positive correlation starts;
- all-free DGP-SD starts;
- zero-correlation map with default SD starts;
- zero-correlation map with DGP-SD starts;
- fixed-SD plus zero-correlation map;
- all-free fit seeded from the zero-correlation solution.

Added `structured-re-q4-animal-start-map-diagnostic.tsv`, with 28 strategy
rows. The sidecar records map state, start source, staged source, convergence,
`pdHess`, objective, warnings, fixed-gradient size, `sdreport` covariance
eigenvalues, theta magnitude, direct-SD estimate range, strategy status,
blocker component, source artifact, evidence URL, and diagnostic-only claim
boundaries.

The diagnostic localizes the q4 animal blocker to the free q4 correlation
block. Zero-correlation map rows had `pdHess = TRUE` in 12/12 cases and passed
the smoke gate in 11/12 cases. All-free and diagonal-staged all-free
strategies remained blocked on seeds `910101`, `910102`, and `910110`.

## 3a. Decisions and Rejected Alternatives

Decision: do not launch q4 animal coverage arrays on Nibi, Rorqual, Totoro, or
FIIA from this evidence. The next useful work is a q4 correlation-parameter
transform or constrained-correlation admission experiment.

Rejected alternatives:

- Do not treat zero-correlation map success as all-free q4 inference readiness.
- Do not treat diagonal staged starts as a rescue when the all-free fit still
  returns gradient/Hessian blockers.
- Do not promote animal q4 all-four, q8-shaped rows, derived correlations,
  REML, AI-REML, bridge parity, or public support.
- Do not spend DRAC array budget on coverage until the all-free correlation
  denominator is stable.

## 3b. Mathematical Contract

No likelihood, formula grammar, estimator, or interval implementation changed.
The diagnostic uses the same animal A-matrix q4 all-four one-slope formula
shape as the admission, numerical-geometry, and optimizer-route probes:

- `mu1 = y1 ~ x + animal(1 + x | p | id, A = A)`
- `mu2 = y2 ~ x + animal(1 + x | p | id, A = A)`
- `sigma1 = ~ z + animal(1 + x | p | id, A = A)`
- `sigma2 = ~ z + animal(1 + x | p | id, A = A)`
- `rho12 = ~ 1`

The target is TMB start/map stability around the q4 structured
random-effect block, not interval calibration. Fixing `theta_phylo` at zero is
an internal diagnostic map, not a supported user-facing model claim.

## 4. Files Touched

- `tools/run-structured-re-q4-animal-start-map-diagnostic.R`
- `docs/dev-log/dashboard/structured-re-q4-animal-start-map-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-start-map-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-start-map-diagnostic.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-start-map-diagnostic.R --overwrite=true --write-dashboard=true`: passed, writing 28 start/map rows.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse("tools/run-structured-re-q4-animal-start-map-diagnostic.R")); cat("start_map_runner_parse_ok\n")'`: passed.
- `/opt/homebrew/bin/air format tools/run-structured-re-q4-animal-start-map-diagnostic.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Dashboard JavaScript parse check via `node`: `dashboard_js_ok`.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 28 structured RE q4 animal start-map diagnostic rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 7146 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q4-animal-start-map-diagnostic.md')"`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`: passed after a fresh `mission_control_ok`; the dashboard was already listening at `http://127.0.0.1:8765/`.
- Served dashboard verification: `curl -fsS http://127.0.0.1:8765/version.txt` returned `r111`; `index.html` contained the `q4AnimalStartMapDiagnostic`, `Animal q4 start/map`, `structured-re-q4-animal-start-map-diagnostic`, and `q4 start/map` markers; the start/map TSV served 29 lines including the header.

## 6. Tests of the Tests

The focused structured-RE conversion test now requires the exact 28-row
start/map matrix: four selected seeds crossed with seven strategies, exact
`pdHess` outcomes, strategy statuses, blocker components, source artifact path,
evidence URL, diagnostic-only interval status, `not_evaluable` coverage status,
and forbidden-claim wording.

This test protects the key failure path: zero-correlation maps can pass smoke,
but the all-free and diagonal-staged all-free fits must remain classified as
free-q4-correlation blockers for seeds `910101`, `910102`, and `910110`.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This was a local
diagnostic/dashboard banking slice inside the Q-Series high-q arc.

## 8. Consistency Audit

The linked Q-Series animal q4 all-four one-slope cell remains
`interval_status = diagnostic_only` and `coverage_status = planned`. The new
start/map sidecar records `interval_claim_status = diagnostic_only` and
`coverage_status = not_evaluable`. The widget keeps fit stability, start/map
evidence, inference readiness, interval status, and coverage status separate.

Dashboard README, the mission-control validator, and the focused R test use the
same boundary: no coverage, no `inference_ready`, no `supported`, no q8
inference, no q4 REML, no REML, no AI-REML, no broad q4 bridge support, and no
derived-correlation interval claim.

## 9. What Did Not Go Smoothly

The first exploratory lower-level script failed because the known A-matrix was
not available in the formula environment. The second failed because the manual
TMB object path had not added the covariance-probe parameters that the package
adds before `MakeADFun`. Both failures were corrected before the formal runner
was written.

## 10. Known Residuals

Animal q4 all-four all-free correlation admission remains blocked. This
diagnostic does not validate a q4 correlation transform, constrained
correlation route, profile interval channel, coverage denominator, derived q4
correlation interval, q8 row, REML, AI-REML, or bridge support.

One fixed-SD zero-correlation row passed `pdHess` but stayed
`start_map_watch` because its fixed-gradient size was just above the smoke
threshold. That is still diagnostic-only and does not support promotion.

## 11. Team Learning

When q4 all-free fits fail but zero-correlation maps pass, the next slice
should target the correlation parameterization rather than adding optimizer
routes or launching coverage. Keep FIIA/Totoro for small route/map rehearsals
and reserve Nibi/Rorqual for denominators only after the all-free admission
story is stable.

## 12. Next Actions

- Ask Gauss/Noether to design the q4 correlation-parameter transform or
  constrained-correlation admission experiment.
- Keep q4 coverage-grid design paused until all-free correlation admission has
  stable `pdHess` and finite direct-SD interval rates.
- Ask Fisher/Rose to review any future denominator-policy change before a
  Q-Series status edit.
