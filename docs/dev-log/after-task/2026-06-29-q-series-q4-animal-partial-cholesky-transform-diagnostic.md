# Q-Series q4 Animal Partial-Cholesky Transform Diagnostic

## 1. Goal

Run the next local q4 animal all-four one-slope hard-seed diagnostic for
`qseries_animal_q4_all_four_one_slope_planned`, using a partial-correlation
Cholesky coordinate route as an attempted all-free transform before spending
Totoro, Nibi, Rorqual, or DRAC time.

## 2. Implemented

- Added `tools/run-structured-re-q4-animal-partial-cholesky-transform-diagnostic.R`.
- Ran hard seeds `910101`, `910102`, and `910110` under the `more_levels`
  animal q4 all-four design.
- Compared three routes per seed: the zero-correlation control, the current
  all-free staged route, and the partial-Cholesky all-free route.
- Wrote the dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-animal-partial-cholesky-transform-diagnostic.tsv`
  and the retained raw artifact under
  `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-cholesky-transform-local/`.
- Updated the Q-Series widget to render the sidecar as a separate animal q4
  partial-Cholesky table and summary card.
- Updated the support-cell row, high-q audit row, campaign queue, transform
  admission contract, dashboard README, completion map, design gate, validator,
  and focused conversion-contract test so the route is visible as blocked
  diagnostic evidence.

The result is negative and useful: the partial-Cholesky all-free route has
0/3 local hard-seed admission passes. All three partial rows have convergence
code 1 and `pdHess = FALSE`; seeds `910101` and `910110` are large-eta blocked,
and direct-SD interval finiteness is only 7/8, 0/8, and 2/8.

## 3a. Decisions and Rejected Alternatives

- I did not submit Totoro, FIIA, Nibi, Rorqual, or DRAC work. The local hard
  seeds already blocked the route, so a cluster run would only make the same
  failure more expensive.
- I kept the partial-Cholesky route diagnostic-only. It is an optimizer-layer
  coordinate attempt around the current all-free route, not a reviewed
  lower-level TMB/C++ production parameterization.
- I did not promote any q4 or q8 row. The exact row remains high-q gated and
  diagnostic-only.
- I kept direct-SD intervals labelled as `sdreport_wald_inner_tmb_curvature`.
  They are not profile intervals, calibrated intervals, coverage evidence, or
  a support-grade denominator.

## 4. Files Touched

- `tools/run-structured-re-q4-animal-partial-cholesky-transform-diagnostic.R`
- `docs/dev-log/dashboard/structured-re-q4-animal-partial-cholesky-transform-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-cholesky-transform-local/structured-re-q4-animal-partial-cholesky-transform-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-cholesky-transform-local/structured-re-q4-animal-partial-cholesky-transform-run-log.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-cholesky-transform-local/sessionInfo.txt`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-cholesky-transform-local/git-sha.txt`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/structured-re-q4-animal-transform-admission-contract.tsv`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/design/220-structured-q4-animal-production-transform-gate.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-stability-probe/structured-re-q4-slope-interval-stability-probe-results.tsv`
- `docs/dev-log/dashboard/structured-re-q4-slope-interval-stability-probe.tsv`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse("tools/run-structured-re-q4-animal-partial-cholesky-transform-diagnostic.R")); cat("partial_cholesky_runner_parse_ok\n")'`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-q4-animal-partial-cholesky-transform-diagnostic.R --help`: passed.
- Smoke run with seed `910101`, `--write-dashboard=false`, and output under
  `/tmp/drmtmb-q4-animal-partial-cholesky-smoke`: passed after resetting the
  runner output paths.
- Full local diagnostic with hard seeds `910101,910102,910110` and
  `--write-dashboard=true`: passed after fixing the numeric guard in
  `log10_condition()`.
- The original q4 slope interval stability probe was rerun to restore the
  accidentally clobbered artifact path; the restored raw artifact has 129 lines
  and the restored dashboard sidecar has 65 lines.
- `R_PROFILE_USER=/dev/null python3 -m py_compile tools/validate-mission-control.py`: passed.
- Dashboard JavaScript extraction plus `node --check /tmp/drmtmb-dashboard-index.js`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q4-animal-partial-cholesky-transform-diagnostic.md')"`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series cells and 9 structured RE q4 animal partial-Cholesky transform diagnostic rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 7890 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `git diff --check`: passed.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt`
  returned `r130`; the partial-Cholesky TSV served 10 lines including the
  header; `/` contained `BUILD = "r130"`, `Animal q4 partial`,
  `q4AnimalPartialCholeskyDiagnostic`, `q4 partial`, and `partial-Cholesky`;
  the served TSV status counts matched the retained sidecar.

## 6. Tests of the Tests

The new validator and focused test both assert the exact three-seed by
three-route key set, the 3/4/2 route-status count split, the 6/3
reference-versus-blocked admission split, the 0/3 partial-route admission pass
count, the source artifact path, and the forbidden claim phrases. A change that
turns a partial-Cholesky row into an admission pass, drops the raw artifact, or
softens the no-coverage/no-support boundary should fail both gates.

## 7a. Issue Ledger

- New blocker recorded: the partial-Cholesky all-free route is not eligible for
  Totoro/FIIA, Nibi/Rorqual, or DRAC escalation because it fails all three local
  hard seeds.
- Existing blocker retained: animal q4 all-four remains blocked on lower-level
  TMB/C++ parameterization design plus objective/report equivalence tests.

## 8. Consistency Audit

I checked the Q-Series support-cell row, high-q audit, campaign queue,
transform-admission contract, widget rendering, dashboard README, completion
map, design gate, validator, and focused test. All now describe the
partial-Cholesky sidecar as blocked diagnostic evidence, not an inference,
coverage, support, q8, REML, AI-REML, production-parameterization, or public
support claim.

## 9. What Did Not Go Smoothly

- The first smoke exposed a copied-prefix path bug: sourcing the q4 stability
  helper reset `artifact_path`, so the smoke briefly wrote partial-Cholesky rows
  into the old q4 slope stability artifact path. I reset the new runner paths
  immediately after sourcing and reran the original q4 slope stability probe to
  restore the raw and dashboard artifacts.
- The first full local run failed in `log10_condition()` because a diagnostic
  branch passed a nonnumeric value. I hardened the helper to coerce safely and
  reran the full diagnostic.

## 10. Known Residuals

- No lower-level TMB/C++ production transform exists yet for the q8-shaped
  animal all-four route.
- No q4 animal coverage denominator is authorized.
- No q4 animal row is `inference_ready` or `supported`.
- The direct-SD interval entries in this diagnostic are inner TMB
  `sdreport()` Wald curvature checks only, not calibrated intervals or profile
  intervals.

## 11. Team Learning

Connected compute is useful only after the local admission contract earns it.
For q4 animal all-four, local hard-seed diagnostics should now stop at the
design gate until a lower-level TMB/C++ parameterization has objective/report
equivalence tests; optimizer-layer coordinate wrappers have repeatedly located
the blocker but have not produced a production route.
