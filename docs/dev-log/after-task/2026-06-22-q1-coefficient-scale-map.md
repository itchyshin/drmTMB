# After Task: Q1 Coefficient-Scale Map

## 1. Goal

Bank SR119 by making the q1 bridge coefficient-scale contract explicit before
the q1 acceptance gate: fixed coefficients remain link-scale, `resd_*`
coefficients reconstruct response-scale structured SDs, and coupled
`recov_*` coefficients reconstruct phylogenetic SDs plus a correlation.

## 2. Implemented

Added three rows to
`docs/dev-log/dashboard/structured-re-q1-reconstruction-map.tsv`:

- `q1_fixed_coef_link_scale_map`
- `q1_structured_sd_response_scale_map`
- `q1_phylo_mu_sigma_recov_map`

Added a focused synthetic reconstruction test in
`tests/testthat/test-julia-inference.R` for `resd_*` and `recov_*`
transformations. Updated
`tests/testthat/test-structured-re-conversion-contracts.R` so its dashboard
contract matches the now-banked q1 parity fixture rows and q2 intentional-error
status.

## 3a. Decisions and Rejected Alternatives

I did not add interval or coverage wording. The map explains point-estimate and
summary reconstruction scales only.

I did not treat the optional live Julia inference skip as a blocker. The SR119
evidence is the synthetic reconstruction and dashboard contract; live bridge
parity is already recorded in the route-specific rows.

## 4. Files Touched

- `tests/testthat/test-julia-inference.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`
- `docs/dev-log/dashboard/structured-re-julia-twin-sync.tsv`
- `docs/dev-log/dashboard/structured-re-q1-reconstruction-map.tsv`
- `docs/dev-log/dashboard/sweep.json`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/216-structured-random-effect-finish-100-slices.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-22-q1-coefficient-scale-map.md`

## 5. Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = 'julia-inference|structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R \
  docs/dev-log/after-task/2026-06-22-q1-coefficient-scale-map.md
```

Result: `julia-inference` and `structured-re-conversion-contracts` passed with
133 assertions, 0 failures, and 0 warnings. One optional live Julia inference
smoke skipped because the DRM.jl phylo engine was not configured; the synthetic
reconstruction and dashboard-contract checks relevant to SR119 ran.

## 6. Tests of the Tests

The new test would fail if `resd_*` coefficients stopped reconstructing as
`exp(resd) * structured_sd_scale`, if coupled `recov_*` Cholesky pieces stopped
producing response-scale `sdpars$mu`, `sdpars$sigma`, and `corpars$phylo`, or
if the dashboard stopped carrying the q1 scale-map rows.

## 7a. Issue Ledger

No GitHub issue, comment, PR, commit, or Ayumi reply was created. SR119 is local
mission-control contract evidence only. The next row is SR120: q1 parity
acceptance gate.

## 8. Consistency Audit

The q1 reconstruction map now names fixed coefficient, structured SD, and
coupled phylogenetic reconstruction scales separately. The finish ledger,
status JSON, sweep JSON, design summaries, and check-log use the same boundary:
scale mapping only, no interval or coverage claim.

## 9. What Did Not Go Smoothly

The older dashboard-contract test still expected all q1 parity fixtures to be
planned and q2 bridge boundaries to exclude `intentional_error`. Updating that
test was part of the SR119 repair because those expectations were stale after
the q1 parity and q2 gate rows were banked.

## 10. Known Residuals

SR119 does not add a new bridge route, calibrated intervals, NB2 parity, q2/q4
support, or public support wording. SR120 still needs the acceptance gate that
ties fixtures, tolerances, negative evidence, and scale maps together.

## 11. Team Learning

Fisher: parity needs scale labels, not just numeric closeness. Emmy: the bridge
must preserve extractor semantics when hiding `resd_*` and `recov_*` rows from
fixed effects. Rose: tests that assert dashboard status need to move with the
ledger instead of freezing old planned states.
