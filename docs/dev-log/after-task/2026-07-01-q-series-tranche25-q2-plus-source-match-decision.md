# After Task: Q-Series Tranche 25 q2-plus Source-Match Decision

## 1. Goal

Bank the post-Tranche-24 q2-plus decision gate without compute: either prove a
source-matched Rorqual/DRAC geometry replay is possible, or park q2-plus rather
than spending on unverifiable repeats.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche25-source-match-decision.tsv`,
an eight-row no-compute decision contract for the q2-plus replicate-108 source
drift found in Tranche 24. The sidecar requires source snapshot proof before
any Rorqual or DRAC replay can be interpreted: dirty source state, R session,
package library, runner inputs, exact command, host label, output path, and a
source-diff manifest. It explicitly excludes local Codex, Totoro, unsynced
DRAC, and other non-source-matched repeats for this gate.

Mission Control now loads and renders the sidecar at dashboard build `r219`.
The validator and focused conversion-contract test check the schema, source
paths, source/local `pdHess` disagreement, no-compute/no-coverage/no-promotion
decisions, unchanged q2-plus support-cell status, and the
Fisher/Rose/Noether/Gauss/Grace discussion rows.

## 3a. Decisions and Rejected Alternatives

Chose a source-match contract rather than immediate remote compute. Tranche 24
showed local `pdHess = TRUE` while the Rorqual source artifact remains
`pdHess = FALSE`; another fast local or Totoro replay would not answer that
source-drift question.

Rejected immediate top-up, denominator creation, coverage, q2-plus promotion,
and q4/q8 inheritance. Rejected treating #687 DDF ideas as authority for this
gate; #687 remains a parking issue requiring primary-source review and
row-specific retained-denominator evidence.

The next gate is a checkpointed source-snapshot proof check. If the Rorqual
dirty source state can be recovered or recreated on DRAC with an explicit
manifest, run exactly one replicate-108 geometry reconstruction. If it cannot
be proven, park q2-plus.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche25-source-match-decision.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche25-q2-plus-source-match-decision.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Tranche 25 TSV shape check: 9 lines including header, 37 columns on every
  row.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- Dashboard JS extraction plus
  `node --check /tmp/drmtmb-mission-control-index-r219.js`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 8 Tranche 24 geometry-result rows,
  8 Tranche 25 source-match decision rows, and 125 member-discussion rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts", reporter = "summary")'`: passed.
- `gh issue list --repo itchyshin/drmTMB --state open --search "q2-plus
  source match decision" --limit 10 --json number,title,state,url`: returned
  broad standing issues #491 and #59, with no Tranche 25-specific source-match
  issue.
- `gh issue view 687 --repo itchyshin/drmTMB --json
  number,title,state,url,body`: passed; #687 remains a DDF route lead only,
  not Tranche 25 implementation or status authority.
- Support-cell invariant script: 104 support cells, 8 interval
  `inference_ready`, 8 coverage `inference_ready`, 0 `authority_status =
  supported`, and 0 q4 coverage-authorized rows.
- Tranche 25 positive-claim value scan: passed for all 8 rows; every row stays
  `contract_banked_not_executed`, `no_compute_in_tranche25`,
  `coverage_not_authorized`, and `do_not_promote`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche25-q2-plus-source-match-decision.md')"`:
  passed.
- `DRMTMB_DASHBOARD_PORT=8765 PYTHONDONTWRITEBYTECODE=1
  R_PROFILE_USER=/dev/null NOT_CRAN=true sh tools/start-mission-control.sh
  --background`: refreshed the served dashboard copy or confirmed the existing
  `r219` server.
- Served Mission Control check at `http://127.0.0.1:8765/`: `version.txt`
  returned `r219`; the Tranche 25 sidecar served with 9 lines; `index.html`
  contained the Tranche 25 render label; the served completion map linked the
  Tranche 25 sidecar and preserved the q2-plus park-if-source-match-fails
  boundary.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file
  tools/codex-checkpoint.R --goal "Q-Series Tranche 25 q2-plus source-match
  decision contract banked; no compute/status" --next "Choose between
  source-snapshot proof for one source-matched Rorqual/DRAC replicate-108
  geometry reconstruction and explicit q2-plus parking. Do not run local Codex,
  Totoro, unsynced DRAC, or any host without source snapshot proof; do not top
  up, create denominators, authorize coverage, pool hosts, or move support-cell
  status from Tranche 25." --output
  docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche25-codex-checkpoint.md`:
  wrote the checkpoint.

## 6. Tests of the Tests

The focused R test reads the Tranche 25 sidecar, checks the exact 37-column
schema, all eight decision IDs, source paths, replicate 108 / seed 823108,
source `pdHess = FALSE`, local replay `pdHess = TRUE`, approval-token text,
required outputs, no-compute/no-coverage/no-promotion decisions, unchanged
q2-plus support-cell status, and Fisher/Rose/Noether/Gauss/Grace discussion
rows.

The Python validator independently checks the same sidecar and would fail if
the contract authorized local or Totoro repeats, unsynced DRAC, denominator
pooling, coverage, or support-cell promotion.

## 7a. Issue Ledger

The open issue search for `q2-plus source match decision` returned only broad
standing issues #491 and #59. Neither authorizes this source-match gate or
requires a new issue before banking the no-compute contract. Issue #687 was
inspected directly; it remains a DDF repair-sidecar parking issue and does not
authorize Tranche 25 execution, coverage, q2-plus promotion, q4/q8 inheritance,
REML, AI-REML, bridge, or public support. No new issue was opened.

## 8. Consistency Audit

Mission Control reports 104 Q-Series support cells, 8 Q-Series
inference-evidence summary rows, 8 Tranche 24 geometry-result rows,
8 Tranche 25 source-match decision rows, and 125 member-discussion rows. The
linked support cell `qseries_phylo_q2_plus_q2_intercept` remains
`point_fit/planned/planned` with
`denominator_policy = repair_contract_ready_not_coverage`.

Every Tranche 25 row remains `contract_banked_not_executed`,
`no_compute_in_tranche25`, `coverage_not_authorized`, and `do_not_promote`.
Public APIs, formula grammar, R source, package documentation, README, NEWS,
pkgdown, and support-cell statuses were not changed.

## 9. What Did Not Go Smoothly

The first validator run caught two useful mistakes: `index.html` still carried
the `r218` build tag after `version.txt` moved to `r219`, and the Rorqual/DRAC
host-forbidden lists did not explicitly mention `unsynced_drac` and
`any_host_without_source_snapshot`. Both were corrected before validation
passed.

## 10. Known Residuals

Q2-plus remains blocked. Tranche 25 is a source-match decision contract only;
it does not recover the Rorqual dirty source state, run remote compute, explain
the source `pdHess = FALSE`, create a denominator, authorize coverage, or move
support-cell status.

The next tranche must either prove the source snapshot and run one
source-matched Rorqual/DRAC replicate-108 geometry reconstruction, or park
q2-plus and move to the next Q-Series cell.

## 11. Team Learning

Fisher keeps denominator evidence source-matched. Rose keeps a compute contract
from becoming execution or status. Noether keeps replicate 108 / seed 823108
and the five q2-plus targets fixed. Gauss keeps numerical interpretation tied
to the failing source snapshot. Grace keeps Totoro available for other
Q-Series work while excluding it from this source-match gate.
