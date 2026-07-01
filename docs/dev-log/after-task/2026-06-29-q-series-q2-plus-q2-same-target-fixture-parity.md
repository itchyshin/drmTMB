# After Task: Q-Series q2-plus-q2 same-target fixture parity

## 1. Goal

Bank deterministic same-target fixture parity for the
`qseries_phylo_q2_plus_q2_intercept` contract without promoting the row. This
slice follows the q2-plus-q2 interval-denominator contract and only closes the
fixture/extractor prerequisite before local deterministic smoke work.

## 2. Implemented

This promotes exactly no Q-Series row under the q2-plus-q2 same-target fixture
channel, with the q2-plus-q2 contract denominator policy, and does not claim
interval reliability, coverage, `inference_ready`, `supported`, q2-only
location support, q4/q8, non-Gaussian support, REML, AI-REML, broad bridge
support, or public support.

Added a deterministic `q2_plus_q2` payload fixture for the phylo
`mu1+mu2;sigma1+sigma2` intercept row. The fixture has four endpoint fixed
effects, two location-block structured SD targets, one location-block
correlation target, two scale-block structured SD targets, and one scale-block
correlation target. It deliberately has no `mu`-to-`sigma` cross-block
correlation terms.

Updated the q2 fixture contract so the `q2_plus_q2_not_q4` row is
`fixture_available` for native, direct DRM.jl, and R-via-Julia fixture routes,
with `bridge_status = fixture_parity`. The claim boundary still says this is
not full q4, interval reliability, coverage, REML, AI-REML, broad bridge
support, or public support.

Updated the q2-plus-q2 intercept sidecar and neighbouring low-q ledgers from
`same_target_fixture_pending` to `same_target_fixture_parity`. The next gate is
now local deterministic q2-plus-q2 intercept smoke with retained
fit/convergence/`pdHess`/`confint`/profile/bootstrap-attempt accounting before
any Totoro/FIIA, Nibi/Rorqual, or DRAC work.

## 3a. Decisions and Rejected Alternatives

Decision: the same-target fixture is block diagonal. It proves that the
location q2 block and scale q2 block can be represented by the same target
contract across the three fixture routes. It does not create cross-block
correlation targets.

Decision: the fixture records unavailable profile, bootstrap, coverage,
cross-block-correlation, REML, and AI-REML extractors explicitly. This makes the
absence of inference evidence part of the payload rather than an unstated
future assumption.

Rejected alternative: do not move the support cell to `fixture_parity` or
`inference_ready`. The row still has no runtime smoke, denominator accounting,
finite interval fraction, one-sided miss table, MCSE, profile channel, or
bootstrap accounting.

## 4. Files Touched

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q2-plus-q2-same-target-fixture-parity.md`

## 5. Checks Run

- `/opt/homebrew/bin/air format inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 structured RE q-series
  cells, 35 Gaussian low-q status-audit rows, 23 Gaussian low-q row-selection
  rows, and 10 q2-plus-q2 intercept-contract rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-bridge-fixtures")'`:
  755 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  8071 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q2-plus-q2-same-target-fixture-parity.md')"`:
  passed with `after-task structure check passed`.
- `rg -n "same_target_fixture_pending|Add same-target q2-plus-q2|add same-target fixture" docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R || true`:
  returned no stale pending-fixture text.
- `python3 - <<'PY' ... PY`: confirmed the q2-plus-q2 intercept contract has
  10 rows, all pointing to this after-task report, all with
  `same_target_fixture_parity`, and all with `promotion_decision =
  do_not_promote`.
- `git diff --check -- inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-29-q-series-q2-plus-q2-same-target-fixture-parity.md`:
  passed.

## 6. Tests of the Tests

The new fixture test reconstructs the native, direct DRM.jl, and R-via-Julia
fixture payloads and checks exact coefficient ordering, unavailable inference
extractors, absence of `mu`-to-`sigma` coefficient terms, zero coefficient
deltas, zero log-likelihood delta, and passed fixture parity. The dashboard
contract test reads the q2-plus-q2 intercept TSV directly and requires the
same-target fixture parity phrase, the new after-task evidence link, and the
local deterministic smoke next gate.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is a local
mission-control and fixture-contract slice inside the active Q-Series evidence
board.

## 8. Consistency Audit

The support-cell row still remains `fit_status = point_fit`,
`interval_status = planned`, and `coverage_status = planned`. The
q2-plus-q2 contract, low-q audit row, row-selection ledgers, validator, and
focused tests all now agree that same-target fixture parity is covered but
local deterministic smoke, denominator accounting, interval diagnostics,
coverage, and status promotion are still future gates.

Stale-claim scan targeted this slice:

- `rg -n "same_target_fixture_pending|Add same-target q2-plus-q2|add same-target fixture" docs/dev-log/dashboard docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local tests inst tools`

## 9. What Did Not Go Smoothly

The first search after the mechanical TSV replacement was too broad and flooded
the console with unrelated q4 `same_target_fixture_parity` rows. The follow-up
inspection narrowed to the q2-plus-q2 contract and the focused checker/test
expectations.

## 10. Known Residuals

Q-Series is not complete. The q2-plus-q2 intercept row still needs local
deterministic smoke before any Totoro/FIIA or DRAC work. Sigma-side targets do
not inherit the location-axis bias+t default. Cross-block mean-scale
correlations remain unavailable until a true q4 route exists. Gaussian q4/q6/q8
rows, non-Gaussian interval/coverage rows, REML, AI-REML, and `supported`
claims remain separate future arcs.

## 11. Team Learning

When a sidecar begins to claim a fixture prerequisite, point the sidecar's
evidence URL at the report that actually banks that prerequisite. Otherwise the
widget can look coherent while the evidence trail still points to an older,
narrower boundary contract.
