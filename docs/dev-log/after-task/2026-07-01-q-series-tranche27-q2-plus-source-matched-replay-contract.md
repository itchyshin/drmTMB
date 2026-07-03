# After Task: Q-Series Tranche 27 q2-plus Source-Matched Replay Contract

## 1. Goal

Bank the Tranche 27 source-matched Rorqual replay job pack for q2-plus
replicate 108 without submitting it, running compute, creating a denominator,
or moving any Q-Series status.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche27-source-matched-replay-contract.tsv`,
an eight-row contract ledger for one future Rorqual SLURM replay of replicate
108 / seed 823108. The contract uses the preserved source runner
`/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q2-retained-pregrid-77b634eda91b-codex-rorqual/source/tools/run-structured-re-q2-plus-q2-intercept-smoke.R`,
the shard-5 R library, package cache, source manifest, and the exact five
retained q2-plus target IDs from the imported Rorqual artifact.

Added `tools/slurm/q2-plus-rep108-source-replay-rorqual.sbatch`. The job pack
is fail-closed: it requires
`DRMTMB_Q2_TRANCHE27_SOURCE_REPLAY_APPROVED=fisher_rose_noether_gauss_grace_manifest_verified`,
refuses non-Rorqual or non-SLURM execution, accepts only array task 108, verifies
the preserved source sha256 manifest inside the job before R starts, then calls
the preserved q2-plus runner with `--n-rep=1`, `--seed-start=108`,
`--seed-base=823000`, and the five retained target contract IDs.

Mission Control now loads and renders the sidecar at dashboard build `r221`.
The validator and focused conversion-contract test check the schema, job-pack
guards, manifest-verification wording, no-submission/no-compute/no-coverage
/no-promotion decisions, unchanged q2-plus support-cell status, and
Fisher/Rose/Noether/Gauss/Grace discussion rows.

## 3a. Decisions and Rejected Alternatives

Chose a non-submitted job pack rather than immediate `sbatch`. Tranche 26
provided source-snapshot proof, but the campaign rules require a checkpoint
before a compute/design tranche moves to execution.

Chose the preserved q2-plus smoke runner rather than a new local diagnostic
runner because it exists in the preserved Rorqual source manifest and remote
source tree. The job passes the exact five retained q2-plus target IDs so it
does not drift into the sixth held sigma-correlation target or q4.

Rejected login-node execution, local Codex, Totoro, Nibi, Trillium, Fir,
unsynced DRAC, denominator creation, top-up, coverage, q2-plus promotion, q4/q8
inheritance, REML, AI-REML, bridge, and public-support claims.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche27-source-matched-replay-contract.tsv`
- `tools/slurm/q2-plus-rep108-source-replay-rorqual.sbatch`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche27-q2-plus-source-matched-replay-contract.md`
- `docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche27-codex-checkpoint.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Tranche 27 TSV shape check: 9 lines including header, 38 columns on every
  row.
- `bash -n tools/slurm/q2-plus-rep108-source-replay-rorqual.sbatch`: passed.
- Preserved source-manifest check for critical entries: the local fetched
  Rorqual manifest includes
  `tools/run-structured-re-q2-plus-q2-intercept-smoke.R`,
  `tools/run-structured-re-q2-retained-denominator-pregrid.R`,
  `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv`,
  and `docs/dev-log/dashboard/structured-re-q2-retained-denominator-design.tsv`.
- BatchMode Rorqual probe confirmed the preserved remote source tree contains
  the q2-plus smoke runner and the two dashboard contract TSVs needed by the
  replay job.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- Dashboard JS extraction plus
  `node --check /tmp/drmtmb-mission-control-index-r221.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 8 Tranche 26 source-snapshot proof
  rows, 8 Tranche 27 source-matched replay-contract rows, and 135
  member-discussion rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts", reporter = "summary")'`: passed.
- `gh issue list --repo itchyshin/drmTMB --state open --search "q2-plus
  source-matched replay contract" --limit 10 --json number,title,state,url`:
  returned no Tranche 27-specific issue.
- `gh issue view 687 --repo itchyshin/drmTMB --json
  number,title,state,url,body`: passed; #687 remains a DDF route lead only,
  not Tranche 27 implementation or status authority.
- Support-cell invariant script: 104 support cells, 8 interval
  `inference_ready`, 8 coverage `inference_ready`, 0 structured
  `fit_status = supported`, 0 structured `authority_status = supported`, and
  0 q4 coverage-authorized rows.
- Tranche 27 positive-claim value scan: passed for all 8 rows; every row stays
  `job_pack_banked_not_submitted`, `contract_banked_not_executed`,
  `no_compute_in_tranche27`, `coverage_not_authorized`, and
  `do_not_promote`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche27-q2-plus-source-matched-replay-contract.md')"`:
  passed.
- `git diff --check`: passed.
- `DRMTMB_DASHBOARD_PORT=8765 PYTHONDONTWRITEBYTECODE=1
  R_PROFILE_USER=/dev/null NOT_CRAN=true sh tools/start-mission-control.sh
  --background`: refreshed the served dashboard copy or confirmed the existing
  `r221` server.
- Served Mission Control check at `http://127.0.0.1:8765/`: `version.txt`
  returned `r221`; the Tranche 27 sidecar served with 9 lines; `index.html`
  contained the Tranche 27 render label; the served completion map linked the
  Tranche 27 sidecar and sbatch and preserved the non-submitted Rorqual job-pack
  boundary.
- Removed generated `tools/__pycache__`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file
  tools/codex-checkpoint.R --goal "Q-Series Tranche 27 q2-plus source-matched
  replay job pack banked; no submission/status" --next "Either submit exactly
  one approved Rorqual SLURM array task 108 with
  DRMTMB_Q2_TRANCHE27_SOURCE_REPLAY_APPROVED=fisher_rose_noether_gauss_grace_manifest_verified
  and then review the source-matched artifacts, or park q2-plus if the
  manifest, preserved runner, or Rorqual job gate fails; do not run on login
  node, local Codex, Totoro, Nibi, Trillium, Fir, unsynced DRAC, or any
  source-unverified host; do not top up, create denominators, authorize
  coverage, pool hosts, or move support-cell status from Tranche 27." --output
  docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche27-codex-checkpoint.md`:
  wrote the checkpoint.

## 6. Tests of the Tests

The focused R test reads the Tranche 27 sidecar, checks the exact 38-column
schema, all eight contract IDs, the approval token, forbidden hosts, replicate
108 / seed 823108, `n_rep = 1`, five retained target IDs, expected output
files, no-submission/no-compute/no-coverage/no-promotion decisions, unchanged
q2-plus support-cell status, the sbatch guard strings, and the
Fisher/Rose/Noether/Gauss/Grace discussion rows.

The Python validator independently checks the same sidecar and sbatch text. It
would fail if the job pack dropped the approval gate, accepted non-Rorqual or
non-108 execution, omitted source manifest verification, changed target IDs,
authorized denominator pooling, or moved coverage/support-cell status.

## 7a. Issue Ledger

The open issue search for `q2-plus source-matched replay contract` returned no
Tranche 27-specific issue. Issue #687 was inspected directly; it remains a DDF
repair-sidecar parking issue and does not authorize Tranche 27 execution,
coverage, q2-plus promotion, q4/q8 inheritance, REML, AI-REML, bridge, or
public support. No new issue was opened.

## 8. Consistency Audit

Mission Control reports 104 Q-Series support cells, 8 Q-Series
inference-evidence summary rows, 8 Tranche 26 source-snapshot proof rows,
8 Tranche 27 source-matched replay-contract rows, and 135 member-discussion
rows. The linked support cell `qseries_phylo_q2_plus_q2_intercept` remains
`point_fit/planned/planned` with
`denominator_policy = repair_contract_ready_not_coverage`.

Every Tranche 27 row remains `job_pack_banked_not_submitted`,
`contract_banked_not_executed`, `no_compute_in_tranche27`,
`coverage_not_authorized`, and `do_not_promote`. Public APIs, formula grammar,
R source, TMB source, package documentation, README, NEWS, pkgdown, and
support-cell statuses were not changed.

## 9. What Did Not Go Smoothly

The retained-denominator pregrid wrapper looked tempting at first, but it
correctly refuses `--n-rep != 150`, so it cannot be the one-replicate replay
tool. The contract therefore uses the lower-level preserved q2-plus smoke
runner and passes the exact retained target IDs.

The job pack has to avoid using `rorqual` in the runner-level `host-class`
because that older runner treats Rorqual/Nibi as an `n = 5` substitute-smoke
mode. The sbatch records Rorqual provenance in its metadata and SLURM guards,
while passing `source_matched_replay_preserved_snapshot` to the runner.

## 10. Known Residuals

Q2-plus remains blocked. Tranche 27 creates a reviewed job pack only; it does
not submit the job, run the replay, explain the source `pdHess = FALSE`, create
a denominator, authorize coverage, or move support-cell status.

The next tranche must either submit exactly this one Rorqual SLURM task after
checkpointed approval and review the artifacts, or park q2-plus if the manifest
or preserved-runner gate fails.

## 11. Team Learning

Fisher keeps `n = 1` replay evidence separate from denominators. Rose keeps a
banked sbatch file from becoming execution or status. Noether keeps replicate
108 / seed 823108 and the five retained target IDs fixed. Gauss keeps the
replay focused on the source `pdHess` disagreement. Grace keeps full source
manifest verification inside the Rorqual job and blocks login-node or mixed-host
execution.
