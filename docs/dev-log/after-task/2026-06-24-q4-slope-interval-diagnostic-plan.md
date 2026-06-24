# After Task: Q4 All-Four One-Slope Interval Diagnostic Plan

Date: 2026-06-24

Branch: `codex/structured-relmat-kq-mu-slope-fixture`

## Goal

Add a target-level interval diagnostic plan for the exact shared-label
bivariate Gaussian q8-shaped all-four one-slope cells in `phylo()`,
fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`.

## Implemented

- Added
  `docs/dev-log/dashboard/structured-re-q4-slope-interval-diagnostic-plan.tsv`.
- Added 144 planned target rows: 36 per provider.
- Split each provider into 8 direct-SD future smoke targets and 28
  derived-correlation targets that remain blocked on interval reconstruction.
- Wired the sidecar into `tools/validate-mission-control.py`.
- Added conversion-contract coverage in
  `tests/testthat/test-structured-re-conversion-contracts.R`.
- Updated the dashboard README, q-series completion map, and check log.

## Mathematical Contract

The plan applies only to the exact shared-label all-four one-slope block:

```r
mu1 = y1 ~ x + provider(1 + x | p | group, ...)
mu2 = y2 ~ x + provider(1 + x | p | group, ...)
sigma1 = ~ x + provider(1 + x | p | group, ...)
sigma2 = ~ x + provider(1 + x | p | group, ...)
```

The endpoint-member set is
`mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, `mu2:x`,
`sigma1:(Intercept)`, `sigma1:x`, `sigma2:(Intercept)`, and `sigma2:x`.
For each provider, the plan records 8 direct SD targets and the 28 pairwise
derived correlations among these endpoint members.

## Files Changed

- `docs/dev-log/dashboard/structured-re-q4-slope-interval-diagnostic-plan.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
rg -n "<q4-slope interval overclaim pattern>" README.md NEWS.md ROADMAP.md docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-q4-slope-interval-diagnostic-plan.tsv tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-24-q4-slope-interval-diagnostic-plan.md
```

Results are recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

The conversion-contract test verifies the 144-row shape, provider counts,
direct-SD versus derived-correlation counts, direct endpoint members, planned
status, current blockers, q-series linkage, and the continued planned
interval/coverage statuses. The mission-control validator independently
reconstructs the expected 32 direct-SD targets and 112 derived-correlation
targets from the q8 endpoint-member set.

## Consistency Audit

The q-series support cells remain at `bridge_status = fixture_parity`,
`interval_status = planned`, `coverage_status = planned`, and
`denominator_policy = fixture_not_coverage`. The new plan sidecar is an
evidence map for future diagnostics only.

## GitHub Issue Maintenance

No issue action was taken in this slice. This is an internal planning sidecar
inside the active structured q-series completion lane.

## What Did Not Go Smoothly

The q4 all-four one-slope cells have 28 derived correlations per provider, so
the diagnostic plan needed a full target inventory rather than only the direct
SD rows. Keeping derived rows explicit prevents accidental interval or coverage
promotion.

## Team Learning

For high-dimensional cells, record derived targets even when they are blocked.
That makes the denominator and reconstruction gaps visible before anyone starts
smoke or grid work.

## Known Limitations

- No interval diagnostics were run in this slice.
- No coverage denominators were admitted.
- Derived-correlation interval reconstruction remains unavailable.
- No q4 interval reliability, interval coverage, q4 REML, native-TMB q4 REML,
  q4 AI-REML, HSquared AI-REML, non-Gaussian REML, broad bridge support, public
  support, DRAC execution, SR150 coverage readiness, or Ayumi-facing reply was
  promoted.

## Next Actions

Run a deterministic direct-SD interval smoke for the 32 direct-SD q4-slope
targets before attempting derived-correlation reconstruction, denominator
admission, calibrated coverage, or public-support wording.
