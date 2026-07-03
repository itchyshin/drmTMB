# After Task: Q-Series Tranche 30 q2-plus Critical-Manifest Replay Contract

## 1. Goal

Bank a narrower q2-plus replay contract after Tranche 29 failed before R, while
preserving the decision boundary: no submission, no compute, no denominator, no
coverage, and no support-cell status movement.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche30-critical-manifest-replay-contract.tsv`,
an eight-row contract ledger for a possible Rorqual replay of replicate 108 /
seed 823108. The sidecar selects `bank_critical_manifest_replay_contract` over
parking q2-plus for now, limits the retained target set to the same five
q2-plus target IDs, and records that Tranche 29's failed full-manifest entry
`./tools/run-structured-re-q2-intercept-smoke.R` is outside that five-target
replay.

Added
`tools/slurm/q2-plus-rep108-critical-manifest-replay-rorqual.sbatch`, a
non-submitted, fail-closed job pack. It requires
`DRMTMB_Q2_TRANCHE30_CRITICAL_REPLAY_APPROVED=fisher_rose_noether_gauss_grace_critical_manifest_contract_verified`,
refuses non-Rorqual/non-SLURM/non-108 execution, writes an excluded
full-manifest-failure note, verifies only the listed critical manifest entries
inside the job before R starts, and calls the preserved q2-plus smoke runner
for the five retained targets.

Mission Control build `r224` loads and renders the sidecar. The validator,
focused conversion-contract test, dashboard README, completion map, and member
discussion board were updated to enforce the contract-only claim.

## 3a. Decisions and Rejected Alternatives

Chose a critical-manifest replay contract rather than parking q2-plus
immediately. The rationale is narrow: Tranche 29 stopped before R because the
full manifest checked a q2 intercept runner outside the five-target q2-plus
replay. A reviewed critical-manifest replay is the least compute path that
could answer the q2-plus source-matched question honestly.

Rejected an automatic retry or resubmission of job 15027970. Tranche 30 banks a
new contract only; it does not authorize execution by itself. Also rejected
local Codex, Totoro, Nibi, Trillium, Fir, unsynced DRAC, login-node execution,
host pooling, top-up, coverage, q2-plus promotion, q4/q8 inheritance, REML,
AI-REML, bridge support, and public support.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche30-critical-manifest-replay-contract.tsv`
- `tools/slurm/q2-plus-rep108-critical-manifest-replay-rorqual.sbatch`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche30-q2-plus-critical-manifest-replay-contract.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Tranche 30 TSV shape check: 9 lines including header, 36 columns on every
  row.
- `bash -n tools/slurm/q2-plus-rep108-critical-manifest-replay-rorqual.sbatch`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- Dashboard JS extraction plus
  `node --check /tmp/drmtmb-mission-control-index-r224.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells, 8 Tranche 28 source-replay submission rows,
  8 Tranche 29 source-replay terminal-review rows, 8 Tranche 30
  critical-manifest replay-contract rows, and 150 member-discussion rows.
- Focused `devtools::test(filter = "structured-re-conversion-contracts")`:
  passed with 13,268 expectations, 0 failures, 0 warnings, and 0 skips.
- Support-cell invariant scan: 104 support cells, 8 interval
  `inference_ready`, 8 coverage `inference_ready`, 0 structured
  `authority_status = supported`, and 0 q4 coverage-authorized rows.
- Tranche 30 positive scan: all 8 rows are
  `job_pack_banked_not_submitted`, `contract_banked_not_executed`,
  `no_compute_in_tranche30`, `coverage_not_authorized`, and
  `do_not_promote`.
- GitHub issue search for `q2-plus critical manifest replay` returned no
  matching open issue; #687 remains a DDF route parking issue only.
- Served dashboard probe on `http://127.0.0.1:8766`: `version.txt` returned
  `r224`, the Tranche 30 sidecar served with 9 lines, `index.html` contained
  the Tranche 30 render label, and the served completion map mentioned the
  Tranche 30 sidecar.

## 6. Tests of the Tests

The focused R test reads the Tranche 30 sidecar, checks its 36-column schema,
all eight row IDs and scopes, exact common values, forbidden hosts, critical
manifest file list, excluded full-manifest failure, no-compute/no-coverage
/no-promotion decisions, claim-boundary text, next-gate text, unchanged
support-cell status, sbatch guard strings, and accepted Fisher/Rose/Noether
/Gauss/Grace discussion rows.

The Python validator independently checks the same contract and would fail if
the sidecar claimed execution, a denominator, coverage authorization,
support-cell promotion, unsupported host execution, or a full-manifest retry.
It also checks that the sbatch does not contain `sha256sum -c
"$SOURCE_MANIFEST"`.

## 7a. Issue Ledger

No Tranche 30-specific GitHub issue was found. Issue #687 was inspected and
remains a separate DDF repair-sidecar parking issue; it does not authorize this
critical-manifest replay, any q2-plus status change, q4/q8 inheritance, REML,
AI-REML, bridge support, or public support.

## 8. Consistency Audit

The q2-plus support cell remains `point_fit/planned/planned` with
`denominator_policy = repair_contract_ready_not_coverage`. Mission Control
still reports 104 Q-Series cells, 8 interval-ready rows, 8 coverage-ready rows,
0 structured `supported` rows, and 0 q4 coverage-authorized rows.

Public APIs, formula grammar, `R/`, `src/`, pkgdown, README, NEWS, and
support-cell statuses were not changed.

## 9. What Did Not Go Smoothly

The Tranche 29 replay failed for a file outside the immediate q2-plus replay
question because the submitted job checked the full preserved source manifest.
Tranche 30 fixes only the next contract boundary; it does not erase the full
manifest failure or convert the failed job into evidence.

## 10. Known Residuals

Q2-plus remains blocked. Tranche 30 creates no denominator, pdHess/profile
classification, coverage evidence, or status movement.

The next gate is a checkpoint before any submission. If approved, submit
exactly one Rorqual SLURM array task 108 with the Tranche 30 approval token and
review terminal artifacts in a new tranche. If the critical-manifest gate fails,
park q2-plus.

## 11. Team Learning

Fisher keeps a replay contract separate from a denominator. Rose keeps the
contract from becoming a resubmission or status claim. Noether keeps the five
q2-plus target identities exact. Gauss withholds Hessian taxonomy until R
artifacts exist. Grace makes host provenance and job-internal manifest
verification explicit before compute.
