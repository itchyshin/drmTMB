# After Task: Q-Series Count-Intercept Caveat Diagnostic

## 1. Goal

Explain the three non-Gaussian q1 count `mu` intercept recovery caveats from the
local 80-rep recovery grid, without changing interval, coverage,
`inference_ready`, `supported`, REML, AI-REML, bridge, q2/q4, high-q, or public
support claims.

## 2. Implemented

This promotes exactly no support cell. It adds a condition-level blocker
diagnostic for `qseries_phylo_poisson_q1_mu_intercept`,
`qseries_phylo_nbinom2_q1_mu_intercept`, and
`qseries_spatial_nbinom2_q1_mu_intercept` under the recovery-only diagnostic
channel with failures retained in the local denominator and does not claim
interval readiness, coverage readiness, `inference_ready`, `supported`, REML,
AI-REML, bridge support, q2/q4 count covariance, high-q evidence, or public
support.

The diagnostic sidecar records 12 condition rows. Phylo Poisson has four
`condition_near_zero_caveat` rows; phylo NB2 has four
`condition_pdhess_caveat` rows; spatial NB2 has two weak-signal
`condition_near_zero_caveat` rows and two stronger-signal
`condition_recovery_ok` rows.

## 3a. Decisions and Rejected Alternatives

The diagnostic target is the structured random-effect standard deviation on
the public SD scale. A condition row is caveated when the local 80-rep
condition denominator has either `pdHess = FALSE` above the 2% recovery gate or
at least 25% of structured-SD estimates below `1e-4`. These are recovery
diagnostics only, not interval or coverage diagnostics.

Rejected alternatives: I did not reclassify the three caveated rows as clean
recovery evidence, did not treat stronger-signal spatial NB2 conditions as
row-level recovery, and did not launch a new simulation grid before mining the
raw denominator evidence already present.

## 4. Files Touched

- `tools/summarize-structured-re-count-intercept-caveat-diagnostic.R`
- `docs/dev-log/dashboard/structured-re-count-intercept-caveat-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-grid-local/tables/count-intercept-caveat-diagnostic.csv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-count-intercept-caveat-diagnostic.md`

## 5. Checks Run

```sh
/opt/homebrew/bin/air format tools/summarize-structured-re-count-intercept-caveat-diagnostic.R
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-count-intercept-caveat-diagnostic.R
python3 -m py_compile tools/validate-mission-control.py
sed -n '/<script>/,/<\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-count-intercept-caveat-diagnostic.md')"
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
git diff --check
```

Results: the summarizer wrote 12 condition-level caveat diagnostic rows;
`tools/validate-mission-control.py` reported `mission_control_ok`; dashboard
JavaScript syntax passed; the after-task structure check passed; the focused
`structured-re-conversion-contracts` test passed with 6307 PASS / 0 FAIL /
0 WARN / 0 SKIP; and `git diff --check` passed.

## 6. Tests of the Tests

The focused dashboard test now reads
`structured-re-count-intercept-caveat-diagnostic.tsv` and checks the exact
12-row shape, the three caveated cells, four condition rows per cell, the
`1e-4` near-zero threshold, 80 retained replicates per condition, the expected
phylo Poisson near-zero verdicts, the expected phylo NB2 pdHess verdicts, and
the mixed weak-signal/stronger-signal spatial NB2 verdicts.

## 7a. Issue Ledger

No GitHub issue action was taken in this slice. The work updates local
mission-control evidence on PR #685's branch and does not open or close a
public capability claim.

## 8. Consistency Audit

`tools/validate-mission-control.py` now requires the 12-row sidecar, exact
caveated cell set, exact no-promotion claim boundary, `interval_status =
unsupported`, `coverage_status = planned`, `authority_status = source`, and a
next gate that keeps intervals and coverage unsupported. The widget shows the
new sidecar link, condition count, worst near-zero rate, and verdict classes
only on recovery-caveated count-intercept rows.

## 9. What Did Not Go Smoothly

The first manual regrouping pass collapsed the phylo formal shard's slope
conditions by tree shape. The final sidecar groups on `internal_cell_id`, so it
retains all four formal-shard conditions for each phylo family.

## 10. Known Residuals

This diagnostic reuses the existing local 80-rep grid. It does not test a
larger denominator, larger mean count, stronger phylo SD, or cluster-replicated
top-up. Phylo Poisson and phylo NB2 remain caveated in every current condition,
and spatial NB2 is clean only in the stronger-signal conditions.

## Next Actions

Run a targeted denominator diagnostic for the three caveated cells with
stronger signal and/or larger count denominators before changing non-Gaussian
recovery wording. Do not use this sidecar for intervals, coverage, q2/q4,
REML, AI-REML, bridge support, `supported`, or high-q claims.

## 11. Team Learning

Recovery caveats need condition-level neighbors, not only row-level summaries.
A row-level caveat can mix weak-signal denominator behavior with cleaner
conditions, as spatial NB2 does here.
