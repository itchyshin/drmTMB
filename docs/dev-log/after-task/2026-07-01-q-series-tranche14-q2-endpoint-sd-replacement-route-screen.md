# After Task: Q-Series Tranche 14 q2 Endpoint-SD Replacement-Route Screen

## 1. Goal

Bank the next q2 retained-denominator endpoint-SD movement as a no-compute
route screen: identify plausible replacement-route families, keep source links
as leads only, and preserve Fisher/Rose/Noether/Grace gates before any smoke,
coverage, or status movement.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche14-endpoint-sd-replacement-route-screen.tsv`
with eight rows. Five rows screen candidate endpoint-SD route families:
Satterthwaite-style variance-component DDF, Kenward-Roger-style DDF analogues,
parametric bootstrap intervals, boundary-likelihood diagnostics, and Cox-Reid
adjusted-profile or orthogonalization ideas. These are primary-source leads,
not derivations or implemented routes.

The sidecar also keeps Tranche 11 direct-correlation evidence separate, keeps
the phylo q2-plus-q2 cell on its own route, and records a tranche summary. Every
row stays `no_compute_in_tranche14`, `coverage_not_authorized`, and
`do_not_promote`. Mission Control now loads and renders the sidecar at dashboard
build `r208`; the Python validator and focused R contract test own the schema,
route identities, source-link leads, reviewer rows, q2-plus support-cell
invariants, and no-claim boundary.

## 3a. Decisions and Rejected Alternatives

Rejected treating named methods as implementation evidence. A JSTOR, PubMed,
Project Euclid, Taylor & Francis, or Wiley link is not enough to select an
endpoint-SD interval route; the route must first prove the `sd_mu2_intercept`
target identity, transformation, failed-fit policy, retained-denominator rule,
and executable smoke contract.

Rejected spending host time in this tranche. Totoro, Nibi, Rorqual, Trillium,
and DRAC remain unavailable for this lane until one route has a reviewed source,
seed, host, run-root, artifact, and approval contract.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche14-endpoint-sd-replacement-route-screen.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche14-q2-endpoint-sd-replacement-route-screen.md`
- `docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche14-codex-checkpoint.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Tranche 14 TSV shape check: 9 lines including header, 27 columns on every
  row.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
- Dashboard JS extraction plus `node --check /tmp/drmtmb-dashboard-index.js`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`
- `gh issue view 687 --json number,title,state,url,body --repo itchyshin/drmTMB`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`
- Positive stale-claim scan for Tranche 14 execution, host submission, coverage
  authorization, `inference_ready`, `supported`, promotion, DDF implementation,
  bootstrap implementation, and adjusted-profile implementation claims.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche14-q2-endpoint-sd-replacement-route-screen.md')"`
- `git diff --check`
- `rm -rf tools/__pycache__ && test ! -d tools/__pycache__`
- `DRMTMB_DASHBOARD_PORT=8765 PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true sh tools/start-mission-control.sh --background`
- Served Mission Control check on `http://127.0.0.1:8765/`: `version.txt =
  r208`, Tranche 14 sidecar has 9 served lines, and `index.html` includes the
  Tranche 14 table.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/codex-checkpoint.R --goal "Q-Series Tranche 14 endpoint-SD replacement-route screen banked; no compute/status" --next "Select or derive one Tranche 15 executable q2 endpoint-SD replacement route or switch to a separate q2-plus route; no compute before Fisher/Rose/Noether/Grace approval." --output docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche14-codex-checkpoint.md`

## 6. Tests of the Tests

The focused R contract test fails if the Tranche 14 sidecar is missing, row
counts drift, one of the five candidate routes disappears, source links stop
naming the expected primary-source leads, direct-correlation or q2-plus evidence
is pooled into endpoint-SD, q2-plus status moves from `point_fit/planned/planned`,
or Fisher/Rose/Noether/Grace reviewer rows are missing.

The Python validator independently verifies the same row identities and also
checks local file references, all 27 required columns, no-compute/no-coverage/no-
promotion decisions, route-screen scope counts, and the exact no-claim boundary.

## 7a. Issue Ledger

Inspected `https://github.com/itchyshin/drmTMB/issues/687`. It is open and
explicitly says the DDF route note is a parking issue, not implementation
authority. No comment was posted because Tranche 14 did not verify derivations,
implement DDF/bootstrap/adjusted-profile logic, execute compute, or change
Q-Series status.

## 8. Consistency Audit

The sidecar, member-board rows, validator, R test, dashboard README, completion
map, and check-log now say the same thing: Tranche 14 is a source-link route
screen only; primary sources are leads, not derivations; no candidate is
selected as executable; direct-correlation and q2-plus remain separate; and no
status moves.

Mission Control validation still reports 104 Q-Series support cells and 8
Q-Series inference-evidence rows. No files in `R/`, `src/`, formula grammar,
pkgdown, README, NEWS, or public API were changed.

## 9. What Did Not Go Smoothly

The sidecar existed before the dashboard and validator knew about it, so the
first Rose pass had to distinguish "file present" from "Mission Control owns
the tranche." The validator wiring was the real completion step.

## 10. Known Residuals

No endpoint-SD replacement route is executable yet. Satterthwaite, Kenward-
Roger, bootstrap, boundary-likelihood, and adjusted-profile ideas still need
derivation and target-identity review before any smoke contract. Tranche 11
direct-correlation smoke remains banked but not executed. The phylo q2-plus-q2
row remains separately blocked.

## 11. Team Learning

When a route screen names familiar methods, Rose must force the wording to say
"lead" rather than "method." Fisher and Noether need a derivation before
denominators, and Grace needs a source/seed/host/artifact contract before any
host spend.
