# After Task: Q4 Slope Identity Preflight

## Goal

Record the exact identity contract for future bivariate Gaussian structured
all-four one-slope cells before adding q4 slope runtime code. This slice should
make the next runtime implementation judgeable without promoting runtime,
bridge, interval, coverage, REML, AI-REML, or public support claims.

## Implemented

Added `tools/run-structured-re-q4-slope-identity-preflight.R`. The script reads
`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` and writes
`docs/dev-log/dashboard/structured-re-q4-slope-identity-preflight.tsv` with one
row each for `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and
K-matrix `relmat()`.

The sidecar records the exact eight endpoint members:

```text
mu1:(Intercept)
mu1:x
mu2:(Intercept)
mu2:x
sigma1:(Intercept)
sigma1:x
sigma2:(Intercept)
sigma2:x
```

It also records eight planned direct-SD target placeholders and 28 labelled
covariance pairs. The linked q-series support cells now point to this sidecar
as their current evidence surface while keeping all implementation and
inference statuses planned.

## Mathematical Contract

The future all-four one-slope cell is q8-shaped: four distributional endpoints
times intercept and one slope. It is not the q4 all-four intercept cell, not a
q2 location-only slope cell, and not four independent q1 slopes. The covariance
layout must be labelled over the full endpoint/coefficient member set before
bridge parity or interval diagnostics can be meaningful.

## Files Changed

- `tools/run-structured-re-q4-slope-identity-preflight.R`
- `docs/dev-log/dashboard/structured-re-q4-slope-identity-preflight.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript --vanilla tools/run-structured-re-q4-slope-identity-preflight.R`
- `air format tools/run-structured-re-q4-slope-identity-preflight.R tests/testthat/test-structured-re-conversion-contracts.R`
- `python3 -m py_compile tools/validate-mission-control.py`
- `python3 tools/validate-mission-control.py`
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
- q4-slope overclaim scan across README, ROADMAP, NEWS, design docs,
  dashboard files, after-task notes, tests, and tools.
- `git diff --check`

All checks passed. Mission-control reported four structured RE q4 slope
identity-preflight rows, and the focused conversion-contract test completed
with 2,550 assertions.

## Tests Of The Tests

The focused conversion-contract test checks the sidecar schema, provider set,
eight-member endpoint order, coefficient order, eight planned direct-SD
targets, 28 labelled covariance-pair count, planned statuses, and linked
q-series support-cell boundaries.

## Consistency Audit

The q-series support-cell rows, dashboard README, design map, validator, and
conversion-contract test now share one identity contract for the q4 all-four
one-slope cells. All wording keeps the row at preflight-only status.

## GitHub Issue Maintenance

No GitHub issue or PR was opened, updated, undrafted, merged, staged, or
committed for this local slice.

## What Did Not Go Smoothly

No runtime obstacle was handled in this slice because this was an intentional
control-plane gate. The main risk was overclaiming q4 slope support from an
identity table, so the validator now requires all linked support-cell statuses
to remain planned.

## Team Learning

For q-series work, identity should be banked at the endpoint/coefficient level
before runtime code. That makes the later implementation smaller: it has to
match the eight-member order and 28-pair covariance contract, not rediscover it.

## Known Limitations

No q4 all-four one-slope model was fitted. There is no extractor output, bridge
parity, interval reliability, coverage, q4 REML, native-TMB q4 REML, q4
AI-REML, HSquared AI-REML, non-Gaussian REML, broad bridge support, public
optimizer control, DRAC execution, SR150 readiness, or Ayumi-facing reply.

## Next Actions

Implement the coefficient-aware q4 all-four one-slope runtime mapping and
provider tests against this identity preflight. Keep bridge parity, intervals,
coverage, and REML language behind separate evidence rows.
