# After Task: Q-Series Tranche 16 q2-plus Route Decomposition

## 1. Goal

Advance the Q-Series campaign without spending compute by turning the phylo
q2-plus-q2 retained-denominator blocker into a reviewed decomposition ledger:
separate the five Rorqual SR150 within-block targets, the held
`cor_sigma1_sigma2_intercept` target, true-q4 cross-block blockers, and the
neighboring q2-intercept contracts.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche16-q2-plus-route-decomposition.tsv`
with nine rows. Five rows record the existing Rorqual SR150 q2-plus within-
block targets: `sd_mu1_intercept`, `sd_mu2_intercept`,
`cor_mu1_mu2_intercept`, `sd_sigma1_intercept`, and `sd_sigma2_intercept`.
The ledger records the blocker evidence exactly: cell-level `pdHess = 745/750`,
worst target Wald/profile coverage `0.8867`, target Wald finiteness as low as
`148/150`, and target profile finiteness as low as `149/150`.

One row keeps the held Nibi `cor_sigma1_sigma2_intercept` target separate with
profile finiteness `4/5`. One row rejects cross-block correlations as q2-plus
inheritance; they require a true q4 route. One row keeps Tranche 11 direct-
correlation and Tranche 15 endpoint-SD q2-intercept contracts separate. The
summary row blocks q2-plus top-up until `pdHess`, interval shape, and the held
sigma1/sigma2 correlation route are repaired or explained.

Mission Control now loads and renders the sidecar at dashboard build `r210`.
The Python validator and focused conversion-contract test own the schema,
target rates, target-separation rows, support-cell status invariants, and
Fisher/Rose/Noether/Grace member-board rows.

## 3a. Decisions and Rejected Alternatives

Rejected treating SR150 as a top-up invitation. The existing q2-plus evidence
is useful because it explains why the cell is blocked; it does not authorize
more denominator work. The `pdHess = 745/750` pattern, undercoverage, and held
sigma1/sigma2 correlation profile failure must be handled before any compute.

Rejected q2-intercept inheritance. Tranche 11 direct-correlation and Tranche 15
endpoint-SD contracts target different cells and do not clear q2-plus
`pdHess`, sigma-side, or held-correlation blockers.

Rejected cross-block q2-plus expansion. Mean-scale cross-block correlations are
not block-diagonal q2-plus targets and need a true q4 route before any interval,
coverage, or support claim.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche16-q2-plus-route-decomposition.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche16-q2-plus-route-decomposition.md`
- `docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche16-codex-checkpoint.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Tranche 16 TSV shape check: 10 lines including header, 31 columns on every
  row.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
- Dashboard JS extraction plus `node --check /tmp/drmtmb-dashboard-index.js`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`
- Positive stale-claim scans for Tranche 16 execution, host submission,
  coverage authorization, top-up, status edits, `inference_ready`, `supported`,
  and promotion claims.
- `gh issue list --repo itchyshin/drmTMB --state open --search "q2-plus retained denominator" --limit 10 --json number,title,state,url`
- `gh issue view 687 --json number,title,state,url,body --repo itchyshin/drmTMB`
- `DRMTMB_DASHBOARD_PORT=8765 PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true sh tools/start-mission-control.sh --background`
- Served Mission Control check on `http://127.0.0.1:8765/`: `version.txt =
  r210`, Tranche 16 sidecar has 10 served lines, and `index.html` includes the
  Tranche 16 table.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/codex-checkpoint.R --goal "Q-Series Tranche 16 q2-plus route decomposition banked; no compute/status" --next "Design a target-specific q2-plus repair route for pdHess, interval shape, and held sigma1/sigma2 correlation, or route cross-block correlations through a true q4 design. No compute, coverage, or status edit before Fisher/Rose/Noether/Grace review." --output docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche16-codex-checkpoint.md`

## 6. Tests of the Tests

The focused R contract test fails if the Tranche 16 sidecar is missing, its 31
columns drift, row counts or scope counts change, one of the five SR150 target
rates changes, the held sigma1/sigma2 correlation row loses its Nibi `4/5`
profile-finiteness blocker, cross-block correlations are no longer rejected as
true-q4 targets, q2-intercept dependencies are inherited, support-cell status
moves from `point_fit/planned/planned`, or Fisher/Rose/Noether/Grace rows are
missing.

The Python validator independently verifies the same row identities and also
checks local file references, no-compute/no-coverage/no-promotion decisions,
claim-boundary phrases, reviewer prefixes, and the linked q2-plus support-cell
invariants.

## 7a. Issue Ledger

`gh issue list --search "q2-plus retained denominator"` found only the broad
simulation framework issue #59. No issue comment was posted because Tranche 16
does not implement a new method, execute compute, or change status.

Issue `https://github.com/itchyshin/drmTMB/issues/687` remains open as a DDF
parking issue. It is not implementation authority for Tranche 16, but its
guardrails agree with this tranche: primary sources and retained-denominator
evidence are required before any Q-Series status movement.

## 8. Consistency Audit

The sidecar, member-board rows, validator, R test, dashboard README, completion
map, and check-log now say the same thing: Tranche 16 decomposes q2-plus
blockers only; SR150 is blocker evidence; the sigma1/sigma2 correlation target
is still held; cross-block correlations are q4; neighboring q2-intercept
contracts do not transfer; and no compute or status movement is authorized.

Mission Control validation still reports 104 Q-Series support cells and 8
Q-Series inference-evidence rows. No files in `R/`, `src/`, formula grammar,
pkgdown, README, NEWS, or public API were changed.

## 9. What Did Not Go Smoothly

The first focused R test rerun expected numeric coverage values, but the new
TSV columns are character because the held and cross-block rows contain
`not_applicable`. The test was corrected to assert the character values owned
by the TSV.

## 10. Known Residuals

No q2-plus repair route is executable yet. The next movement is a target-
specific q2-plus route for the `pdHess = 745/750` pattern, interval-shape
undercoverage, and held `cor_sigma1_sigma2_intercept` profile failure, or a
separate true-q4 route for cross-block correlations. Tranche 11 and Tranche 15
remain separately banked and unexecuted.

## 11. Team Learning

When a retained-denominator pregrid already exists, Rose must still ask whether
it is result evidence or blocker evidence. Fisher needs top-up blocked when the
problem is interval shape or finiteness, Noether needs target identity split
before inheritance, and Grace needs every next run to start from a repaired
route contract rather than from "we already have SR150."
