# After Task: Q-Series Tranche 18 q2-plus Failure Taxonomy

## 1. Goal

Advance the Q-Series q2-plus lane without spending compute by selecting the
cheapest post-screen repair route: classify existing SR150 and Nibi failure
evidence before writing any runner, smoke contract, top-up, or coverage plan.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche18-q2-plus-failure-taxonomy.tsv`
with eight rows. Five rows classify the Rorqual SR150 q2-plus within-block
targets. One row classifies the held Nibi `cor_sigma1_sigma2_intercept`
profile-root failure. One row records the selected route gate: existing-
artifact failure taxonomy first, no runner contract yet. The summary row
blocks compute until a post-taxonomy fail-closed contract chooses exactly one
target and failure class.

The taxonomy records the shared SR150 `pdHess` loss on replicate 108, missing-
`rlang` artifact-dependency failures on replicates 29 and 53, sigma-side
upper-tail profile miss patterns, direct-correlation undercoverage, and the
Nibi held sigma1/sigma2 profile-root error on replicate 3.

Mission Control now loads and renders the sidecar at dashboard build `r212`.
The Python validator and focused conversion-contract test own the schema, row
counts, failure classes, source references, member-board rows, and q2-plus
support-cell invariants.

## 3a. Decisions and Rejected Alternatives

Selected failure taxonomy as the first post-screen route because it spends no
compute and explains whether the next contract should target Hessian geometry,
profile geometry, dependency-clean rerun, sigma-side interval shape, or the
held sigma correlation.

Rejected a runner contract in Tranche 18. The selected route is diagnostic
review, not execution. No target is ready for a smoke until Fisher, Rose,
Noether, Gauss, and Grace choose the exact target and failure class.

Rejected pooling q2 intercept, q2-plus, and true-q4 evidence. The taxonomy
keeps direct-SD, direct-correlation, sigma-side, held-correlation, and
cross-block targets separated.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche18-q2-plus-failure-taxonomy.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche18-q2-plus-failure-taxonomy.md`
- `docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche18-codex-checkpoint.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Tranche 18 TSV shape check: 9 lines including header, 37 columns on every
  row.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
- Dashboard JS extraction plus `node --check /tmp/drmtmb-dashboard-index.js`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`
- Narrow stale-claim scans for Tranche 18 execution, host submission,
  coverage authorization, top-up, status edits, `inference_ready`,
  `supported`, and promotion claims.
- `gh issue list --repo itchyshin/drmTMB --state open --search "q2-plus retained denominator" --limit 10 --json number,title,state,url`
- `gh issue view 687 --json number,title,state,url,body --repo itchyshin/drmTMB`
- `DRMTMB_DASHBOARD_PORT=8765 PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true sh tools/start-mission-control.sh --background`
- Served Mission Control check on `http://127.0.0.1:8765/`: `version.txt =
  r212`, the Tranche 18 sidecar has 9 served lines, `index.html` includes the
  Tranche 18 table, and the served completion map includes the Tranche 18
  paragraph.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche18-q2-plus-failure-taxonomy.md')"`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/codex-checkpoint.R --goal "Q-Series Tranche 18 q2-plus failure taxonomy banked; no compute/status" --next "Choose exactly one post-taxonomy q2-plus route and write a fail-closed contract for one target/failure class only, with source SHA, host label, seed manifest, artifact root, failed-fit policy, and Fisher/Rose/Noether/Gauss/Grace approval before any smoke. No coverage/status before review." --output docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche18-codex-checkpoint.md`

## 6. Tests of the Tests

The focused R block reads the Tranche 18 TSV and checks exact schema, row
counts, scope counts, common source paths, failure classes, selected route
decision, member-board rows, local source existence, and support-cell
invariants. It would fail if any row drifted from `no_compute_in_tranche18`,
`coverage_not_authorized`, or `do_not_promote`.

## 7a. Issue Ledger

The open issue search for `q2-plus retained denominator` returned only issue
#59, the broad simulation-framework issue. Issue #687 was inspected directly;
it remains an open DDF parking issue and is not implementation authority for
Tranche 18. No new issue was opened.

## 8. Consistency Audit

Mission Control reports 104 Q-Series support cells, 8 Q-Series inference-
evidence summary rows, 8 Tranche 18 q2-plus failure-taxonomy rows, and 90
member-discussion rows. The linked support cell
`qseries_phylo_q2_plus_q2_intercept` remains `point_fit/planned/planned` with
`denominator_policy = repair_contract_ready_not_coverage`.

The dashboard README and Q-Series completion map now describe Tranche 18 as
evidence triage only. They do not widen formula grammar, public APIs, R source,
pkgdown, README, NEWS, q4/q8 status, REML, AI-REML, bridge support, or public
support.

## 9. What Did Not Go Smoothly

The raw SR150 replicate taxonomy showed mixed blocker classes rather than one
clean numerical story. Replicate 108 is a shared `pdHess`/Wald-finiteness
blocker, but some profile failures are artifact-dependency failures tied to
missing `rlang`, while other rows point to interval-shape or upper-tail miss
patterns. That makes a broad rerun tempting, but the tranche deliberately
stops before any rerun.

## 10. Known Residuals

No q2-plus route is executable yet. The next tranche must choose one target and
one failure class, then write a fail-closed post-taxonomy contract with source
SHA, host label, seed manifest, artifact root, failed-fit policy, and
Fisher/Rose/Noether/Gauss/Grace approval before any smoke.

Q2-plus still has no coverage authorization, no status promotion, and no
support claim. Cross-block correlations still require a separate true-q4
route.

## 11. Team Learning

Failure taxonomy is valuable precisely because it slows the campaign down
before compute. Rose keeps taxonomy from becoming a status claim, Gauss keeps
dependency failures separate from Hessian/profile geometry, and Noether keeps
target identity from collapsing under a convenient summary label.
