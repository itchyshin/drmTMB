# After Task: Q-Series Tranche 15 q2 Endpoint-SD Bootstrap Smoke Contract

## 1. Goal

Bank the next q2 retained-denominator endpoint-SD movement as an executable but
approval-gated micro-smoke contract. The tranche should spend zero host compute,
preserve endpoint-SD/direct-correlation/q2-plus separation, and make the next
decision honest: whether one provider's `sd_mu2_intercept` bootstrap route is
finite enough to review.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche15-endpoint-sd-bootstrap-smoke-contract.tsv`
with eight rows. Four provider rows name `sd_mu2_intercept` as the only
executable endpoint direct-SD pilot target for the q2 intercept cells. The
component-summary row records the all-provider command shape. Separate rows keep
Tranche 11 direct-correlation and the phylo q2-plus-q2 route outside this
endpoint-SD bootstrap contract.

Added
`tools/run-q2-retained-denominator-tranche15-endpoint-sd-bootstrap-smoke.sh`.
The helper is fail-closed: it refuses to run unless
`DRMTMB_Q2_TRANCHE15_EXECUTION_APPROVED=rose_fisher_noether_grace`. If approved,
it calls the existing q2 intercept smoke runner with
`--estimands=sd_mu2_intercept`, `--bootstrap="${BOOTSTRAP_R}"`,
`--n-rep="${N_REP}"`, `--interval-repair-channel=none`, provider-specific seed
bases, single-threaded BLAS/TMB settings, and `--write-dashboard=false`.

Mission Control now loads and renders the sidecar at dashboard build `r209`.
The Python validator and focused conversion-contract test own the schema,
provider identities, approval gate, exact command strings, source sidecars,
member-review rows, target-separation rows, and no-claim boundary.

## 3a. Decisions and Rejected Alternatives

Selected parametric bootstrap only as the cheapest executable pilot because the
existing q2 intercept runner already accepts `--bootstrap` and the selected
estimand can be restricted to `sd_mu2_intercept`. This is not a bootstrap
reliability claim, coverage design, or support-cell promotion.

Rejected all-provider execution in this tranche. Even with `R = 2` and
`n = 8`, host time should not be spent until Fisher, Rose, Noether, and Grace
explicitly approve one provider, source SHA, host label, seed manifest,
artifact root, and failed-refit accounting.

Rejected using the Tranche 11 direct-correlation command or the q2-plus row as
endpoint-SD evidence. The target identities are different and stay separated.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche15-endpoint-sd-bootstrap-smoke-contract.tsv`
- `tools/run-q2-retained-denominator-tranche15-endpoint-sd-bootstrap-smoke.sh`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche15-q2-endpoint-sd-bootstrap-smoke-contract.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Tranche 15 TSV shape check: 9 lines including header, 34 columns on every
  row.
- `bash -n tools/run-q2-retained-denominator-tranche15-endpoint-sd-bootstrap-smoke.sh`
- No-approval fail-closed probe:
  `sh tools/run-q2-retained-denominator-tranche15-endpoint-sd-bootstrap-smoke.sh`
  returned `rc=64` with the expected refusal and ran no compute.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
- Dashboard JS extraction plus `node --check /tmp/drmtmb-dashboard-index.js`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`
- Positive stale-claim scans for Tranche 15 execution, coverage authorization,
  `inference_ready`, `supported`, promotion, bootstrap execution, endpoint-SD
  smoke results, and bootstrap reliability claims.
- `gh issue view 687 --json number,title,state,url,body --repo itchyshin/drmTMB`

## 6. Tests of the Tests

The focused R contract test fails if the Tranche 15 sidecar is missing, its 34
columns drift, row counts or scope counts change, a provider row loses the
expected q2 support-cell identity, `selected_estimands` stops being
`sd_mu2_intercept`, direct-correlation or q2-plus evidence is pooled into
endpoint-SD, the approval helper text drops the required environment variable,
or Fisher/Rose/Noether/Grace rows are missing.

The Python validator independently checks the same table and also verifies the
helper path, source sidecar references, command-gate token,
`--estimands=sd_mu2_intercept`, `--bootstrap="${BOOTSTRAP_R}"`, provider seed
bases, no-coverage/no-promotion decisions, and the exact no-claim boundary.

## 7a. Issue Ledger

Inspected `https://github.com/itchyshin/drmTMB/issues/687`. It is open and
explicitly describes DDF repair sidecars as a parking issue requiring primary
sources and simulations before implementation or status movement. Tranche 15
does not use that issue as authority; it selects the bootstrap micro-smoke only
because the existing runner can already execute that narrow pilot after
approval.

## 8. Consistency Audit

The sidecar, helper, member-board rows, validator, R test, dashboard README,
completion map, and check-log now say the same thing: Tranche 15 is a banked
bootstrap micro-smoke contract; it has not run; it authorizes no coverage; it
promotes nothing; and it keeps endpoint-SD, direct-correlation, and q2-plus
targets separate.

Mission Control validation still reports 104 Q-Series support cells and 8
Q-Series inference-evidence rows. No files in `R/`, `src/`, formula grammar,
pkgdown, README, NEWS, or public API were changed.

## 9. What Did Not Go Smoothly

The no-approval probe first used `status` as a zsh variable name, which is
read-only in this shell. Re-running the probe with a neutral variable name
confirmed the intended `rc=64` refusal and did not execute compute.

## 10. Known Residuals

No Tranche 15 bootstrap refit has run. The next movement is explicit
Fisher/Rose/Noether/Grace approval for at most one provider endpoint-SD
bootstrap micro-smoke on one host, with retained failed fits, nonfinite
intervals, bootstrap refit attempts, seed manifest, source SHA, host label, and
run logs. Tranche 11 direct-correlation remains separately banked but not
executed. The phylo q2-plus-q2 row still needs its own route design.

## 11. Team Learning

A command string can look like evidence if the surrounding ledger is weak.
Rose's audit should force the words "contract", "not executed", and "not
coverage" into every surface. Fisher and Noether need target identity before
denominators; Grace needs the approval gate, host label, seeds, and artifact
root before any machine spends time.
