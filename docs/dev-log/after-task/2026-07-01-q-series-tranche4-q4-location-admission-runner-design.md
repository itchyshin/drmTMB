# After Task: Q-Series Tranche 4 q4 Location Admission-Runner Design

## 1. Goal

Start Tranche 4 without jumping to coverage: bank a retained-denominator q4
location admission-runner design for the exact direct-SD targets already mapped
in Tranche 3.

## 2. Implemented

Added `structured-re-q4-location-admission-runner-design.tsv` with 16 rows, one
for each q4 location direct-SD provider/endpoint target across `phylo()`,
fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`.
Each row links back to the Tranche 3 target-map row, dispatch-plan row, and
exact `profile_targets()` name.

Mission Control now loads the sidecar, shows a `Q4 T4 runner design` card, and
renders the design rows under Structured RE contracts. The validator and
focused R tests require the design to stay one-to-one with the Tranche 3 target
map.

No runner executed. No denominator result, admission result, coverage result,
or support-cell status changed.

## 3a. Decisions and Rejected Alternatives

I kept Tranche 4 as a runner-design contract rather than launching a local,
Totoro, or DRAC smoke immediately. The current q4 location source evidence
still fails the retained-denominator admission gate, so the next useful work is
to freeze exactly what a tiny admission smoke must count.

I set the first planned smoke to `n_rep_planned = 5`. That is large enough to
exercise the retained-denominator accounting and small enough to avoid
misreading the run as coverage.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-location-admission-runner-design.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/version.txt`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche4-q4-location-admission-runner-design.md`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`:
  passed.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}' docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js && node --check /tmp/drmtmb-dashboard-index.js`:
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- `air format tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 Q-Series support cells, 16
  q4 location target-admission map rows, and 16 q4 location admission-runner
  design rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed `10983 PASS / 0 FAIL / 0 WARN / 0 SKIP`.

## 6. Tests of the Tests

The Python validator and R test both source-link the Tranche 4 design rows to
the Tranche 3 target map. They fail if a design row changes its target,
`profile_targets()` name, source target-map ID, source dispatch ID, planned
replicate count, no-coverage/no-promotion decision, host provenance policy,
retained-denominator policy, gate threshold, or no-claim boundary.

## 7a. Issue Ledger

No GitHub issue was opened or closed. This is a stacked Mission Control artifact
on the Tranche 4 branch.

## 8. Consistency Audit

The sidecar keeps the q4 location scope narrow: 16 direct-SD targets only. It
does not introduce derived-correlation interval targets, all-four intercept
targets, q8-shaped targets, non-Gaussian targets, or ordinary comparator
coverage.

All rows have `coverage_decision = coverage_not_authorized` and
`promotion_decision = do_not_promote`. The claim boundary repeats no runner
execution, no denominator result, no coverage grid, no interval reliability, no
`inference_ready`, no `supported`, no q4 REML, no REML, no AI-REML, no q8
inference, no derived-correlation interval claim, no broad bridge support, and
no public support.

## 9. What Did Not Go Smoothly

The app browser could open Mission Control once for the user, but then timed
out while trying to keep Mission Control and the tranche plan side by side. I
left stable localhost URLs in the chat and continued the repo-grounded work.

## 10. Known Residuals

This does not execute the admission runner. The next Tranche 4 step is to
harden or implement the retained-denominator runner so the `n = 5` admission
smoke can record host provenance, every attempted replicate, fit failures,
nonconvergence, `pdHess = FALSE`, warnings, boundaries, finite direct-SD
Wald/profile intervals, and derived-correlation unavailable status.

## 11. Team Learning

For high-q work, the first post-admission-map artifact should name the run
denominator before compute. That keeps Totoro and DRAC useful without letting a
fast host blur the admission gate or turn a tiny smoke into a coverage claim.
