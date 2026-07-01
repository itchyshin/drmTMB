# After Task: Q-Series q4 animal optimizer-route diagnostic

## 1. Goal

Bank a narrow optimizer-route diagnostic for the animal q4 all-four one-slope
row after the numerical-geometry diagnostic showed failed-Hessian seeds with
large gradients, negative `sdreport` covariance eigenvalues, extreme theta
values, and fallback-selected objectives worse than the best failed default
attempt.

## 2. Implemented

This promotes exactly no Q-Series row under the animal q4 optimizer-route
diagnostic channel, with selected-seed route accounting, and does not claim q4
interval reliability, q4 coverage, `inference_ready`, `supported`, q8 support,
REML, AI-REML, broad bridge support, derived-correlation intervals, or public
support.

Added `tools/run-structured-re-q4-animal-optimizer-route-diagnostic.R`, a
small internal runner that reuses the q4 all-four fixture but restores its own
artifact, dashboard, run-log, session-info, and git-SHA paths after sourcing
the shared helper prefix. The runner compares four selected `more_levels`
seeds (`910101`, `910102`, `910107`, `910110`) across five routes:

- custom `nlminb` budget plus BFGS fallback;
- default `nlminb` ladder without fallback;
- robust preset without fallback;
- two-start multistart without fallback;
- two-start multistart with BFGS fallback.

Added `structured-re-q4-animal-optimizer-route-diagnostic.tsv`, with 20 route
rows. The sidecar records convergence, `pdHess`, objective, selected preset,
attempt summary, selected-objective delta from the best attempt, warning count,
fixed-gradient size, `sdreport` covariance eigenvalue sign, theta magnitude,
derived-correlation conditioning, direct-SD estimate range, route status,
rescue status, source artifact, evidence URL, and diagnostic-only claim
boundaries.

The diagnostic found that seeds `910101` and `910102` were not rescued by any
route. Seven route rows passed the smoke gate, but only on seeds that already
had a passing baseline route. The selected-worse-objective blocker remains
visible on fallback-selected rows.

## 3a. Decisions and Rejected Alternatives

Decision: do not launch q4 animal coverage grids on Nibi, Rorqual, Totoro, or
FIIA from this evidence. Cheap route changes did not rescue the failed-Hessian
seeds, so the next work belongs in a deeper parameter-transform or staged-start
map experiment.

Rejected alternatives:

- Do not count fallback convergence as a route rescue when `pdHess` remains
  false or the selected objective is worse than the best failed route.
- Do not infer q4 coverage readiness from the seven passing smoke rows, because
  they occur only on seeds that were already baseline-pass candidates.
- Do not promote animal q4 all-four, q8-shaped rows, derived correlations,
  REML, AI-REML, bridge parity, or public support.
- Do not spend DRAC array budget on coverage until the denominator is stable.

## 3b. Mathematical Contract

No likelihood, formula grammar, estimator, or interval implementation changed.
The diagnostic uses the same animal A-matrix q4 all-four one-slope formula
shape as the admission and numerical-geometry probes:

- `mu1 = y1 ~ x + animal(1 + x | p | id, A = A)`
- `mu2 = y2 ~ x + animal(1 + x | p | id, A = A)`
- `sigma1 = ~ z + animal(1 + x | p | id, A = A)`
- `sigma2 = ~ z + animal(1 + x | p | id, A = A)`
- `rho12 = ~ 1`

The target is optimizer-route stability around the q4 structured random-effect
block, not interval calibration. Route status is evidence about numerical
admission only.

## 4. Files Touched

- `tools/run-structured-re-q4-animal-optimizer-route-diagnostic.R`
- `docs/dev-log/dashboard/structured-re-q4-animal-optimizer-route-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-optimizer-route-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-optimizer-route-diagnostic.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-optimizer-route-diagnostic.R --overwrite=true --write-dashboard=true`: passed, writing 20 route rows.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse("tools/run-structured-re-q4-animal-optimizer-route-diagnostic.R")); cat("route_runner_parse_ok\n")'`: passed.
- `/opt/homebrew/bin/air format tools/run-structured-re-q4-animal-optimizer-route-diagnostic.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Dashboard JavaScript parse check via `node`: `dashboard_js_ok`.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 20 structured RE q4 animal optimizer-route diagnostic rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 7095 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`: dashboard already listening at `http://127.0.0.1:8765/` after mission-control validation.
- Served dashboard verification: `curl -fsS http://127.0.0.1:8765/version.txt` returned `r110`; `index.html` contained the `q4AnimalOptimizerRouteDiagnostic`, `Animal q4 routes`, and `q4 optimizer routes` markers; `structured-re-q4-animal-optimizer-route-diagnostic.tsv` served 21 lines including the header.

## 6. Tests of the Tests

The focused structured-RE conversion test now requires the exact 20-row route
matrix: four selected seeds crossed with five routes, exact `pdHess` outcomes,
route statuses, rescue statuses, source artifact path, evidence URL,
diagnostic-only interval status, `not_evaluable` coverage status, and
forbidden-claim wording.

This test protects the key failure path: seeds `910101` and `910102` must
remain classified as `no_route_rescue`, and the seven `pdhess_pass_smoke` rows
must stay confined to baseline-passing seeds.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This was a local
diagnostic/dashboard banking slice inside the Q-Series high-q arc.

## 8. Consistency Audit

The linked Q-Series animal q4 all-four one-slope cell remains
`interval_status = diagnostic_only` and `coverage_status = planned`. The new
route sidecar records `interval_claim_status = diagnostic_only` and
`coverage_status = not_evaluable`. The widget keeps fit stability,
optimizer-route evidence, inference readiness, interval status, and coverage
status separate.

Dashboard README, the mission-control validator, and the focused R test use the
same boundary: no coverage, no `inference_ready`, no `supported`, no q8
inference, no q4 REML, no REML, no AI-REML, no broad q4 bridge support, and no
derived-correlation interval claim.

## 9. What Did Not Go Smoothly

The first exploratory route comparison showed the useful signal before the
formal runner existed, so the runner had to be written after the fact and then
checked against the exploratory matrix. A vector/scalar formatting mismatch in
the attempt-summary helper was fixed before the formal run.

The first mission-control run treated `warning_messages` as a mandatory
non-empty field and failed on two legitimate zero-warning pass-smoke rows. The
validator now allows empty `warning_messages` only when `warning_count = 0` and
still errors when a row records warnings without text.

## 10. Known Residuals

Animal q4 all-four direct-SD admission remains blocked. This route diagnostic
does not validate a parameter transform, staged-start map, profile interval
channel, coverage denominator, derived q4 correlation interval, q8 row, REML,
AI-REML, or bridge support.

The next q4 animal experiment should be deeper than route toggles: parameter
transform, staged starts, or an explicit map of which theta/correlation blocks
drive the negative covariance geometry.

## 11. Team Learning

Use FIIA and Totoro for smoke and route rehearsal, but save Nibi/Rorqual
campaign budget for cases where the local artifact contract and denominator
story are already stable. For q4 animal, cheap optimizer route changes are now
exhausted enough that the next useful compute is design-heavy, not larger
coverage arrays.

## 12. Next Actions

- Ask Gauss/Noether to design the parameter-transform or staged-start-map
  experiment for animal q4 all-four.
- Keep q4 coverage-grid design paused until `pdHess` and finite direct-SD
  interval admission rates are stable.
- Ask Fisher/Rose to review any future denominator-policy change before a
  Q-Series status edit.
