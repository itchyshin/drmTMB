# After Task: Q-Series q2-plus-q2 Fisher/Rose sign-off

## 1. Goal

Record Fisher and Rose sign-off for the
`qseries_phylo_q2_plus_q2_intercept` local-smoke gate and advance only the
next gate to a tiny Totoro/FIIA `n=5` smoke.

## 2. Implemented

This promotes exactly no Q-Series row under the q2-plus-q2 smoke-review
channel, with the denominator policy still `not_coverage_evidence`, and does
not claim interval reliability, coverage, MCSE adequacy, `inference_ready`,
`supported`, q2-only location support, q4/q8, non-Gaussian support, REML,
AI-REML, bridge support, or public support.

Fisher and Rose both returned `sign_off_next_smoke` for the local deterministic
q2-plus-q2 smoke. The dashboard ledgers now say the next allowed work is only a
Totoro/FIIA `n=5` smoke for the six direct within-block targets. The four
mean-scale cross-block correlations remain blocked until a true q4 route
exists.

Updated the q2-plus-q2 support cell, Gaussian low-q audit row, row-selection
row and mirror artifact, q2-plus-q2 interval contract, and local-smoke
sidecar/mirror. The support-cell statuses remain `point_fit`, `planned`, and
`planned`.

## 3a. Decisions and Rejected Alternatives

The q2-plus-q2 row is block diagonal: one q2 block for `mu1+mu2` and one q2
block for `sigma1+sigma2`. The smokeable targets are the two location-block
direct SDs, the within-location-block correlation, the two scale-block direct
SDs, and the within-scale-block correlation. Mean-scale cross-block
correlations are not targets of this model route.

The sigma-side targets remain on a sigma-specific interval route. They do not
inherit the default location-axis bias+t correction.

Rejected alternative: do not move the support cell to `inference_ready` or
`supported`. The sign-off only permits a tiny follow-up smoke; it is not
coverage, MCSE, or support-grade evidence.

Rejected alternative: do not reroute this smoke to Nibi/Rorqual/DRAC. The
contract names Totoro/FIIA for the next smoke and keeps denominator work
blocked.

## 4. Files Touched

- `AGENTS.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-local-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-plus-q2-intercept-local-smoke/structured-re-q2-plus-q2-intercept-local-smoke.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q2-plus-q2-fisher-rose-signoff.md`

## 5. Checks Run

- `/opt/homebrew/bin/air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 structured RE q-series
  cells, 10 q2-plus-q2 intercept-contract rows, and 6 q2-plus-q2 intercept
  local-smoke rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  8150 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 nibi 'hostname; pwd; echo DRMTMB_HOST_OK'`:
  passed.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 rorqual 'hostname; pwd; echo DRMTMB_HOST_OK'`:
  passed.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 totoro 'hostname; pwd; echo DRMTMB_HOST_OK'`:
  failed with non-interactive authentication denied.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 fiia 'hostname; pwd; echo DRMTMB_HOST_OK'`:
  failed because no `fiia` host alias was configured.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 fir 'hostname; pwd; echo DRMTMB_HOST_OK'`:
  passed, but a shallow search of `$HOME` and
  `/project/def-snakagaw/snakagaw` found no `drmTMB` checkout.

## 6. Tests of the Tests

The focused conversion-contract test now requires the q2-plus-q2 row-selection
state to be `ready_for_totoro_fiia_smoke`, the run mode to be
`totoro_fiia_n5_smoke_after_fisher_rose_signoff`, and the direct contract rows
to be `ready_for_totoro_fiia_n5_smoke`. It still verifies that the dashboard
summary mirrors the artifact summary, that only the six direct within-block
targets appear in the smoke sidecar, and that the linked support cell remains
`point_fit/planned/planned`.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is a local
mission-control evidence-gate update inside the active Q-Series board.

## 8. Consistency Audit

`AGENTS.md`, the support-cell row, Gaussian low-q audit row, row-selection
ledger, q2-plus-q2 interval contract, local-smoke sidecar, artifact mirrors,
validator, and focused tests now tell the same story: Fisher/Rose accepted the
local smoke as a prerequisite for a small Totoro/FIIA smoke, but no tier or
public-support claim changed.

Historical after-task notes that say Fisher/Rose review was the next gate are
left intact because they were true when written. This report supersedes that
state for current work.

## 9. What Did Not Go Smoothly

The q2-plus-q2 row had several distinct evidence surfaces: support cell,
low-q audit, row-selection, interval contract, local-smoke dashboard sidecar,
and two artifact mirrors. Keeping the status as a next-gate update rather than
a promotion required touching all of them together.

## 10. Known Residuals

Q-Series is not complete. This sign-off does not provide the Totoro/FIIA
`n=5` smoke result, calibrated denominator evidence, coverage, MCSE, one-sided
miss balance, q4/q8 evidence, non-Gaussian interval evidence, REML, AI-REML,
bridge support, `supported`, or public support.

Totoro/FIIA host access or checkout still blocks execution. The latest
non-interactive check found Totoro authentication denied, no `fiia` alias, and
reachable `fir` with no `drmTMB` checkout. Do not reroute this smoke to
Nibi/Rorqual/DRAC without changing and reviewing the contract.

## 11. Team Learning

When Rose and Fisher sign off a smoke gate, record the sign-off as a gate-state
transition, not as inference evidence. That keeps the board useful without
letting review language masquerade as denominator evidence.

## Next Actions

Resolve Totoro/FIIA access or checkout. Once reachable, run only the six direct
within-block q2-plus-q2 targets at `n=5`, retain every attempted row, keep
bootstrap accounting explicit, and write no status promotion from the smoke
alone.
