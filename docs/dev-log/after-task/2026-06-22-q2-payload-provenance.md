# After-Task: SR129 q2 Payload Provenance

## Goal

Bank q2 payload provenance as row-shaped evidence before any q2 R-via-Julia
bridge route work. The contract must preserve source repositories, branches,
heads, payload version, estimator, endpoint, matrix ID, matrix digest, matrix
level obligations, and dirty-state policy.

## Changes

- Added `phase18_structured_re_q2_payload_provenance()` to derive provenance
  rows from the q2 payload fixture.
- Added `structured-re-q2-payload-provenance.tsv` with four q2 structured
  targets: `phylo()`, `spatial()`, `animal()`, and `relmat()`.
- Added validator checks for source heads, matrix digest, required levels,
  version fields, dirty-state policy, and q2 support boundaries.
- Updated the dashboard UI and dashboard README to show the provenance sidecar.
- Extended focused R fixture and dashboard-contract tests.

## Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts')"
```

Result:

- `structured-re-bridge-fixtures` and `structured-re-conversion-contracts`
  passed with 216 assertions, 0 failures, 0 warnings, and 0 skips.
- `python3 tools/validate-mission-control.py` passed with 4 q2
  payload-provenance rows.

## Boundary

This banks provenance-contract evidence only. It does not promote q2
R-via-Julia bridge support, direct q2 fit support, q2 REML, q4 support,
interval coverage, public bridge support, a commit, a PR, or an Ayumi-facing
reply.

## Update 2026-06-23

The phylo provenance row now records narrow experimental q2 bridge fixture
evidence for one complete-response exact-Gaussian ML target. The provenance
contract still rejects public/broad support wording and keeps spatial, animal,
and relmat q2 bridge rows planned.
