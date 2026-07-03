# After Task: Q-Series Tranche 17 q2-plus Repair-Route Screen

## 1. Goal

Advance the Q-Series q2-plus lane without spending compute by turning the
Tranche 16 blocker decomposition into a reviewed repair-route screen. The
screen must identify possible next routes while preserving the current claim
boundary: no executable route, no host run, no top-up, no coverage, no
`inference_ready`, and no support-cell promotion.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche17-q2-plus-repair-route-screen.tsv`
with seven rows. Four rows name candidate q2-plus repair leads: raw `pdHess`
failure taxonomy, a sigma1/sigma2 bounded-profile sidecar, a q2-plus bootstrap
micro-smoke screen, and sigma-side interval-shape calibration. One row routes
cross-block correlations out of q2-plus and into a true q4 design. One row
rejects inheritance from the neighboring Tranche 11 direct-correlation and
Tranche 15 endpoint-SD q2-intercept contracts. The summary row selects no
executable route.

Mission Control now loads and renders the sidecar at dashboard build `r211`.
The Python validator and focused conversion-contract test own the schema, row
counts, reviewer gates, source references, route decisions, support-cell
status invariants, and Fisher/Rose/Noether/Gauss/Grace member-board rows.

## 3a. Decisions and Rejected Alternatives

Rejected moving straight to q2-plus compute. Tranche 16 evidence remains
blocker evidence: `pdHess = 745/750`, the worst retained Wald/profile coverage
is `0.8867`, and the held sigma1/sigma2 correlation smoke retained profile
finiteness `4/5`.

Rejected choosing a bootstrap, bounded-profile, or sigma-side calibration
route from its name alone. Each route needs target identity, failure taxonomy,
failed-fit policy, seed/host/artifact provenance, and blocking reviewer
approval before it can become an executable contract.

Rejected q2-intercept inheritance and q4 inheritance. Tranche 11, Tranche 15,
q2-plus, and true-q4 cross-block targets remain separated.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche17-q2-plus-repair-route-screen.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche17-q2-plus-repair-route-screen.md`
- `docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche17-codex-checkpoint.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Tranche 17 TSV shape check: 8 lines including header, 27 columns on every
  row.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
- Dashboard JS extraction plus `node --check /tmp/drmtmb-dashboard-index.js`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`
- Narrow stale-claim scans for Tranche 17 execution, host submission,
  coverage authorization, top-up, status edits, `inference_ready`,
  `supported`, and promotion claims.
- `gh issue list --repo itchyshin/drmTMB --state open --search "q2-plus retained denominator" --limit 10 --json number,title,state,url`
- `gh issue view 687 --json number,title,state,url,body --repo itchyshin/drmTMB`
- `DRMTMB_DASHBOARD_PORT=8765 PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true sh tools/start-mission-control.sh --background`
- Served Mission Control check on `http://127.0.0.1:8765/`: `version.txt =
  r211`, the Tranche 17 sidecar has 8 served lines, and `index.html` includes
  the Tranche 17 table.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche17-q2-plus-repair-route-screen.md')"`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/codex-checkpoint.R --goal "Q-Series Tranche 17 q2-plus repair-route screen banked; no compute/status" --next "Derive or choose exactly one q2-plus repair route with pdHess/profile failure taxonomy, target identity, failed-fit policy, seed/host/artifact contract, and Fisher/Rose/Noether/Gauss/Grace approval before any smoke. No coverage/status before review." --output docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche17-codex-checkpoint.md`

## 6. Tests of the Tests

The new focused R block reads the Tranche 17 TSV, checks exact schema, row
counts, scope counts, common source paths, reviewer gates, route decisions,
claim-boundary phrases, local source existence, and the q2-plus support-cell
invariants. The test failed risk would be meaningful for this tranche because
any drift from `no_compute_in_tranche17`, `coverage_not_authorized`, or
`do_not_promote` would break the focused contract before a full Mission Control
run.

## 7a. Issue Ledger

The open issue search for `q2-plus retained denominator` returned only issue
#59, the broad simulation-framework issue. Issue #687 was inspected directly;
it remains an open DDF parking issue and is not implementation authority for
Tranche 17. No new issue was opened.

## 8. Consistency Audit

Mission Control still reports 104 Q-Series support cells, 8 Q-Series
inference-evidence summary rows, 7 Tranche 17 q2-plus repair-route screen
rows, and 85 member-discussion rows. The linked support cell
`qseries_phylo_q2_plus_q2_intercept` remains `point_fit/planned/planned` with
`denominator_policy = repair_contract_ready_not_coverage`.

The dashboard README and Q-Series completion map now describe Tranche 17 as a
route screen only. They do not widen formula grammar, public APIs, R source,
pkgdown, README, NEWS, support-cell statuses, q4/q8 status, REML, AI-REML,
bridge support, or public support.

## 9. What Did Not Go Smoothly

The first stale-claim scan was too broad and matched intentional negative
guardrail text in the new sidecar plus older invariant strings. I replaced it
with narrower positive-claim scans before recording the audit result.

The first served-dashboard curl used the source-path URL shape and returned
404 for dashboard assets. The start script serves dashboard assets from the
root path, while design docs live under `docs/design/`, so the served check
was repeated against `/version.txt`, `/structured-re-q2-retained-denominator-tranche17-q2-plus-repair-route-screen.tsv`,
and `/index.html`.

## 10. Known Residuals

No q2-plus route is executable yet. The next tranche must derive or choose
exactly one q2-plus repair route with target identity, raw failure taxonomy or
geometry review, failed-fit policy, source SHA, host label, seed manifest,
artifact root, and Fisher/Rose/Noether/Gauss/Grace approval before any smoke.

Q2-plus still has no coverage authorization, no status promotion, and no
support claim. Cross-block correlations still require a separate true-q4
route.

## 11. Team Learning

Rose's rule should stay active for route screens: naming candidate routes is
not the same as selecting or implementing one. Gauss and Noether need to be
blocking before q2-plus compute because the next honest step depends on both
failure geometry and target identity, not just retained-denominator arithmetic.
