# After Task: Q-Series q2-plus-q2 local smoke

## 1. Goal

Run and bank the local deterministic smoke for
`qseries_phylo_q2_plus_q2_intercept` without promoting the row. This slice
checks that the six within-block q2-plus-q2 targets can produce a native
R/TMB fit, convergence, `pdHess`, and finite Wald/profile intervals before
any Totoro/FIIA or DRAC denominator work.

## 2. Implemented

This promotes exactly no Q-Series row under the q2-plus-q2 local-smoke
channel, with all attempted replicate rows retained, and does not claim
interval reliability, coverage, `inference_ready`, `supported`, q2-only
location support, q4/q8, non-Gaussian support, REML, AI-REML, broad bridge
support, or public support.

Added `tools/run-structured-re-q2-plus-q2-intercept-smoke.R`, a local-only
runner for the phylo `mu1+mu2;sigma1+sigma2` intercept row. The runner writes
a dashboard summary, raw replicate rows, a seed manifest, `sessionInfo.txt`,
and `git-sha.txt` under
`docs/dev-log/simulation-artifacts/2026-06-29-q2-plus-q2-intercept-local-smoke/`.

The smoke ran one deterministic replicate with bootstrap disabled. All six
within-block targets passed the smoke gate: the fit converged, `pdHess` was
true, all six Wald intervals were finite, and all six endpoint-profile
intervals were finite. The four mean-scale cross-block correlations remain
blocked in the q2-plus-q2 contract and were not attempted.

Aligned the q2-plus-q2 sigma endpoint SD profile targets with the live
structured q>2 target inventory. Current `profile_targets()` names the
scale-block direct SDs as `sd:mu:sigma1:phylo(1 | pl | species)` and
`sd:mu:sigma2:phylo(1 | pl | species)`, so the contract now records those
names instead of stale semantic `sd:sigma:*` names.

Updated the support-cell, Gaussian low-q audit, row-selection, validator, and
focused tests so the row now says local smoke passed and the next gate is
Fisher/Rose review before any Totoro/FIIA smoke or denominator work. The
support-cell statuses remain `point_fit`, `planned`, and `planned`.

## 3a. Decisions and Rejected Alternatives

Decision: local smoke is a stability and interval-finiteness prerequisite, not
coverage evidence. The summary records one replicate because this gate is
only meant to verify the exact row and artifact contract before wider compute.

Decision: q2-plus-q2 stays block diagonal. The two q2 blocks have direct SD
and within-block correlation targets, but no mean-scale cross-block
correlation target exists without a true q4 route.

Rejected alternative: do not label this row `inference_ready` or `supported`.
There is no calibrated denominator, MCSE, one-sided miss balance, stress-g
check, or Fisher/Rose sign-off for a tier promotion.

Rejected alternative: do not apply the location-axis bias+t default to the
sigma-side q2-plus-q2 SD targets. Those rows remain on a raw sigma-specific
channel until a separate sigma interval route is validated.

## 4. Files Touched

- `tools/run-structured-re-q2-plus-q2-intercept-smoke.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-local-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-plus-q2-intercept-local-smoke/`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q2-plus-q2-local-smoke.md`

## 5. Checks Run

- `/opt/homebrew/bin/air format tools/run-structured-re-q2-plus-q2-intercept-smoke.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q2-plus-q2-intercept-smoke.R --overwrite=true`:
  passed and wrote the q2-plus-q2 local-smoke artifact bundle.
- `python3 - <<'PY' ... PY`: inspected the generated summary and replicate
  TSVs; confirmed six summary rows and six replicate rows, all
  `local_smoke_passed`, convergence `0`, `pdHess = TRUE`, finite Wald
  intervals, finite profile intervals, and no one-sided misses in the one
  smoke replicate.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 structured RE q-series
  cells, 10 q2-plus-q2 intercept-contract rows, and 6 q2-plus-q2 intercept
  local-smoke rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  8148 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q2-plus-q2-local-smoke.md')"`:
  passed with `after-task structure check passed`.
- `rg -n "run local deterministic q2-plus-q2 intercept smoke before any denominator work|Run local deterministic q2-plus-q2 intercept smoke|no smoke until Fisher/Rose review|same-target fixture parity covered;no smoke" docs/dev-log/dashboard docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py || true`:
  returned no stale source-ledger matches after the cleanup.
- `rg -n "sd:sigma:sigma[12]:phylo\\(1 \\| ps \\| species\\)" docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R || true`:
  returned no stale q2-plus-q2 sigma target names.

## 6. Tests of the Tests

The focused conversion-contract test reads the q2-plus-q2 local-smoke sidecar,
the raw replicate artifact, and the seed manifest. It requires exactly the six
direct within-block contract IDs, rejects the four blocked cross-block
contract IDs, checks exact `target_parm` names, checks that the dashboard
summary mirrors the artifact summary, and verifies that the linked support
cell remains `point_fit/planned/planned`.

The validator adds the same checks at mission-control level and also verifies
claim boundaries, source-contract links, artifact paths, seed role, and
bootstrap-disabled accounting.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is a local
mission-control evidence slice inside the active Q-Series board.

## 8. Consistency Audit

The support-cell row, Gaussian low-q audit row, row-selection ledger,
q2-plus-q2 interval contract, local-smoke sidecar, raw replicate artifact,
validator, and focused tests now agree on the same state:
local deterministic smoke passed for six within-block targets, but interval
and coverage statuses are still planned and no tier promotion occurred.

The q2-plus-q2 contract no longer uses stale `sd:sigma:sigma1` or
`sd:sigma:sigma2` profile target names for the scale-block direct SDs. It now
matches the live `profile_targets()` inventory for structured q>2 fits.

Stale-claim scans targeted this slice:

- `rg -n "run local deterministic q2-plus-q2 intercept smoke before any denominator work|Run local deterministic q2-plus-q2 intercept smoke|no smoke until Fisher/Rose review|same-target fixture parity covered;no smoke" docs/dev-log/dashboard docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py || true`
- `rg -n "sd:sigma:sigma[12]:phylo\\(1 \\| ps \\| species\\)" docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R || true`

## 9. What Did Not Go Smoothly

The first validator pass caught that the row-selection ledger's `artifact_dir`
must keep pointing at the row-selection artifact, even when `evidence_url`
points at the new smoke sidecar. The fix kept the row-selection artifact as
the mirror target and used the smoke sidecar only as evidence.

The q2-plus-q2 contract also exposed a naming mismatch: sigma-side direct SD
targets are represented in the current structured q>2 profile inventory under
`sd:mu:sigma*`, not the older semantic `sd:sigma:*` labels.

## 10. Known Residuals

Q-Series is not complete. This smoke does not provide coverage, MCSE,
one-sided miss balance beyond one replicate, Fisher/Rose sign-off, q4/q8
evidence, non-Gaussian interval evidence, REML, AI-REML, bridge support,
`supported`, or public support.

The next admissible q2-plus-q2 step is Fisher/Rose review of the local smoke,
then a Totoro/FIIA smoke only if they accept the row-specific denominator
contract. Nibi/Rorqual/DRAC remain blocked before denominator design and
review.

## 11. Team Learning

When a status ledger points to a new smoke artifact, keep the row-selection
artifact and the smoke artifact as separate evidence surfaces. The former
proves the queue contract; the latter proves the runtime smoke. Mixing the two
looks tidy but breaks the widget's reproducibility contract.
