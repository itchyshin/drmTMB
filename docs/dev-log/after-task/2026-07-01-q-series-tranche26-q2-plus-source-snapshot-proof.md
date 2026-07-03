# After Task: Q-Series Tranche 26 q2-plus Source-Snapshot Proof

## 1. Goal

Bank the Tranche 26 source-snapshot proof for the q2-plus replicate-108
source-drift gate without running compute, creating a denominator, or moving any
Q-Series status.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche26-source-snapshot-proof.tsv`,
an eight-row proof ledger for the preserved Rorqual SR150 run root. The rows
record that the `/project` run root still has the copied source tree, shard-5 R
library, package cache, metadata, and q2-plus result artifacts; that the source
tree is a copied snapshot rather than a live Git repository; that critical
manifest entries are listed; and that full manifest hashing must happen inside
any future replay job rather than on a login node.

Mission Control now loads and renders the sidecar at dashboard build `r220`.
The validator and focused conversion-contract test check the schema, proof IDs,
source/local `pdHess` disagreement, local metadata paths, no-compute/no-coverage
/no-promotion decisions, unchanged q2-plus support-cell status, and
Fisher/Rose/Noether/Gauss/Grace discussion rows.

## 3a. Decisions and Rejected Alternatives

Chose a proof-only tranche because Tranche 25 required source-snapshot proof
before any source-matched replay could be interpreted. The Rorqual source tree
is present, but it is a copied snapshot without `.git` metadata, so the next
claim-bearing replay must use the preserved source tree and verify the manifest
inside the job.

Rejected full manifest hashing on the Rorqual login node after the check proved
too long for a login-node probe. Rejected local Codex, Totoro, unsynced DRAC,
and any host without the preserved source snapshot for this gate. Rejected
top-up, denominator creation, coverage, q2-plus promotion, q4/q8 inheritance,
REML, AI-REML, bridge, and public-support claims.

The next gate is a checkpointed one-replicate Rorqual replay contract that uses
the preserved source tree, shard-5 library, package cache, and job-internal
manifest verification. If that cannot be kept source-matched, q2-plus parks.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche26-source-snapshot-proof.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche26-q2-plus-source-snapshot-proof.md`
- `docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche26-codex-checkpoint.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Tranche 26 TSV shape check: 9 lines including header, 35 columns on every
  row.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- Dashboard JS extraction plus
  `node --check /tmp/drmtmb-mission-control-index-r220.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 8 Tranche 25 source-match decision
  rows, 8 Tranche 26 source-snapshot proof rows, and 130 member-discussion
  rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts", reporter = "summary")'`: passed.
- `gh issue list --repo itchyshin/drmTMB --state open --search "q2-plus
  source snapshot proof" --limit 10 --json number,title,state,url`: returned
  no Tranche 26-specific issue.
- `gh issue view 687 --repo itchyshin/drmTMB --json
  number,title,state,url,body`: passed; #687 remains a DDF route lead only,
  not Tranche 26 implementation or status authority.
- Support-cell invariant script: 104 support cells, 8 interval
  `inference_ready`, 8 coverage `inference_ready`, 0 structured
  `fit_status = supported`, 0 structured `authority_status = supported`, and
  0 q4 coverage-authorized rows.
- Tranche 26 positive-claim value scan: passed for all 8 rows; every row stays
  `proof_banked_not_executed`, `no_compute_in_tranche26`,
  `coverage_not_authorized`, and `do_not_promote`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche26-q2-plus-source-snapshot-proof.md')"`:
  passed.
- `DRMTMB_DASHBOARD_PORT=8765 PYTHONDONTWRITEBYTECODE=1
  R_PROFILE_USER=/dev/null NOT_CRAN=true sh tools/start-mission-control.sh
  --background`: refreshed the served dashboard copy or confirmed the existing
  `r220` server.
- Served Mission Control check at `http://127.0.0.1:8765/`: `version.txt`
  returned `r220`; the Tranche 26 sidecar served with 9 lines; `index.html`
  contained the Tranche 26 render label; the served completion map linked the
  Tranche 26 sidecar and preserved the source-matched replay / q2-plus parking
  boundary.
- `git diff --check`: passed.
- Removed generated `tools/__pycache__`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file
  tools/codex-checkpoint.R --goal "Q-Series Tranche 26 q2-plus
  source-snapshot proof banked; no replay/status" --next "Prepare exactly one
  source-matched Rorqual replicate-108 geometry replay contract/job that uses
  the preserved /project source tree, rlib/shard_5, package-cache, exact
  command provenance, and job-internal source manifest verification; do not run
  on login node, local Codex, Totoro, or unsynced DRAC; do not top up, create
  denominators, authorize coverage, pool hosts, or move support-cell status
  from Tranche 26." --output
  docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche26-codex-checkpoint.md`:
  wrote the checkpoint.

## 6. Tests of the Tests

The focused R test reads the Tranche 26 sidecar, checks the exact 35-column
schema, all eight proof IDs, source metadata path, replicate 108 / seed 823108,
source `pdHess = FALSE`, local replay `pdHess = TRUE`, manifest-entry text,
no-compute/no-coverage/no-promotion decisions, unchanged q2-plus support-cell
status, and Fisher/Rose/Noether/Gauss/Grace discussion rows.

The Python validator independently checks the same sidecar and would fail if
the proof rows authorized replay execution, local or Totoro execution,
login-node compute, denominator pooling, coverage, support-cell promotion, or
q2-plus/q4/q8/REML/AI-REML/public support.

## 7a. Issue Ledger

The open issue search for `q2-plus source snapshot proof` returned no
Tranche 26-specific issue. Issue #687 was inspected directly; it remains a DDF
repair-sidecar parking issue and does not authorize Tranche 26 execution,
coverage, q2-plus promotion, q4/q8 inheritance, REML, AI-REML, bridge, or
public support. No new issue was opened.

## 8. Consistency Audit

Mission Control reports 104 Q-Series support cells, 8 Q-Series
inference-evidence summary rows, 8 Tranche 25 source-match decision rows,
8 Tranche 26 source-snapshot proof rows, and 130 member-discussion rows. The
linked support cell `qseries_phylo_q2_plus_q2_intercept` remains
`point_fit/planned/planned` with
`denominator_policy = repair_contract_ready_not_coverage`.

Every Tranche 26 row remains `proof_banked_not_executed`,
`no_compute_in_tranche26`, `coverage_not_authorized`, and `do_not_promote`.
Public APIs, formula grammar, R source, TMB source, package documentation,
README, NEWS, pkgdown, and support-cell statuses were not changed.

## 9. What Did Not Go Smoothly

The remote full-manifest hash check was started during proof gathering and then
stopped because it was too heavy for a login-node probe. That became an explicit
Grace guard: full manifest verification belongs inside the replay job.

The first docs patch used a stale completion-map context and had to be applied
more narrowly. No repository content was left half-edited.

## 10. Known Residuals

Q2-plus remains blocked. Tranche 26 proves only that a source-matched replay is
possible to contract from the preserved Rorqual run root. It does not run the
replay, explain the source `pdHess = FALSE`, create a denominator, authorize
coverage, or move support-cell status.

The next tranche must either write and checkpoint exactly one source-matched
Rorqual replicate-108 replay contract/job with job-internal manifest
verification, or park q2-plus and move to the next Q-Series cell.

## 11. Team Learning

Fisher keeps source proof separate from denominator evidence. Rose keeps proof
rows from becoming status. Noether keeps replicate 108 / seed 823108 and the
five q2-plus targets fixed. Gauss keeps failure classification downstream of a
source-matched replay. Grace keeps cluster policy visible by moving full
manifest verification out of login-node probes and into the replay job.
