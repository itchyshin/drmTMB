# After Task: Q-Series Tranche 13 q2 Endpoint-SD Blocker Decision

## 1. Goal

Turn the existing q2 endpoint-SD evidence into an honest blocker decision:
reject top-up of the old `endpoint_zero_boundary_profile_channel` route,
preserve host and target separation, and keep all Q-Series status gates closed.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche13-endpoint-sd-blocker-decision.tsv`
with eight rows. The phylo row records the existing Totoro `n = 32`
`sd_mu2_intercept` endpoint-zero-boundary smoke as diagnostic blocker evidence:
fit, convergence, `pdHess`, Wald finiteness, and profile finiteness were all
`32/32`, but profile coverage was `0.8750` with four upper-tail misses.

Spatial, animal, and relmat are held from repeating that route until a
replacement interval-shape route is reviewed. Tranche 11 direct-correlation and
q2-plus remain separate. Mission Control now loads and renders the sidecar at
dashboard build `r207`; the validator and focused conversion-contract test own
the schema, row identities, support-cell invariants, and reviewer rows.

## 3a. Decisions and Rejected Alternatives

Rejected the cheap-looking top-up of the old endpoint-zero-boundary route. The
phylo `n = 32` evidence says the blocker is interval shape, not fit stability,
so SR475/SR1000 or provider repeats would spend compute without making the next
decision honest.

GitHub issue `https://github.com/itchyshin/drmTMB/issues/687` was inspected and
kept as a route lead only. DDF sidecars need primary-source verification and
row-specific retained-denominator simulation before they can become a Q-Series
gate.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche13-endpoint-sd-blocker-decision.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche13-q2-endpoint-sd-blocker-decision.md`
- `docs/dev-log/recovery-checkpoints/2026-07-01-125224-codex-checkpoint.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- `gh issue view 687 --json number,title,state,url,body --repo itchyshin/drmTMB`
- Tranche 13 TSV shape check: 9 lines including header, 25 columns on every
  row.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
- Dashboard JS extraction plus `node --check /tmp/drmtmb-dashboard-index.js`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`
- Positive stale-claim scan for Tranche 13 execution, host submission, coverage
  authorization, `inference_ready`, `supported`, promotion, and DDF
  implementation claims.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche13-q2-endpoint-sd-blocker-decision.md')"`
- `git diff --check`
- `rm -rf tools/__pycache__ && test ! -d tools/__pycache__`
- Served Mission Control check on `http://127.0.0.1:8765/`: `version.txt =
  r207`, Tranche 13 sidecar has 9 served lines, and `index.html` includes the
  Tranche 13 table.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/codex-checkpoint.R --goal "Q-Series Tranche 13 endpoint-SD blocker decision banked; no compute/status" --next "Design Tranche 14 replacement endpoint-SD interval route ..."` wrote
  `docs/dev-log/recovery-checkpoints/2026-07-01-125224-codex-checkpoint.md`.

## 6. Tests of the Tests

The new focused test fails closed if the Tranche 13 sidecar is missing, row
counts drift, the phylo blocker evidence no longer names profile coverage
`0.8750` and upper-tail misses, repeat-hold providers are accidentally
authorized, direct-correlation evidence is pooled into endpoint-SD, q2-plus
loses its hold row, or Fisher/Rose/Noether/Grace rows are missing.

The Python validator independently verifies the same identities and also checks
that linked q2 support cells remain `point_fit`, `planned`, `planned`, and
`repair_contract_ready_not_coverage`.

## 7a. Issue Ledger

Inspected `https://github.com/itchyshin/drmTMB/issues/687`. It is open and
parks DDF repair sidecars as a future route lead. No comment was posted because
Tranche 13 did not verify primary sources, implement DDF logic, or change
Q-Series status.

## 8. Consistency Audit

The sidecar, member-board rows, validator, R test, dashboard README, completion
map, and check-log all say the same thing: the old endpoint-zero-boundary route
is blocked for top-up, phylo evidence stays diagnostic and host-separated,
direct-correlation Tranche 11 remains separate, and q2-plus needs its own route.

Mission Control validation still reports 104 Q-Series support cells and 8
Q-Series inference-evidence rows. No support-cell status was edited. No files in
`R/`, `src/`, formula grammar, README, NEWS, pkgdown, or public API were
changed.

## 9. What Did Not Go Smoothly

The first GitHub issue lookup used the wrong repository owner. Refreshing the
remote showed the correct owner as `itchyshin/drmTMB`, after which issue #687
loaded cleanly.

The main judgment point was avoiding an attractive but wasteful action:
repeating a route with stable fitting can still be wrong when the retained
evidence shows interval-shape failure.

## 10. Known Residuals

No replacement endpoint-SD route exists yet. DDF sidecars are only a parked lead
until primary sources, equations, implementation design, and retained-denominator
simulation evidence exist. Tranche 11 direct-correlation smoke remains banked
but not executed. The phylo q2-plus-q2 row remains separately blocked.

No new endpoint-SD smoke, coverage job, SR475/SR1000 top-up, host denominator,
interval status, coverage status, `inference_ready`, `supported`, q4/q8, REML,
AI-REML, DDF implementation, bridge, or public-support claim is authorized by
this tranche.

## 11. Team Learning

Fisher's economy rule applies even when fits look clean: if a finite-profile
smoke already shows interval-shape miss imbalance, top-up is not the next honest
step. Rose needs blocker decisions to be written as blockers. Noether needs
provider, endpoint-SD, direct-correlation, and q2-plus denominators separated.
Grace needs old host evidence preserved but not pooled into a new denominator.
