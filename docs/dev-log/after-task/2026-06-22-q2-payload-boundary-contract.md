# 2026-06-22 - SR121 q2 payload boundary contract

## Goal

Bank the q2 bridge entry point as a target-specific payload and boundary
contract without promoting R-via-Julia q2 support.

## Changes

- Added `structured-re-q2-payload-contract.tsv` with explicit q2 payload rows for
  `phylo()`, coordinate `spatial()`, `animal()`, `relmat()`, and the q2 REML
  boundary.
- Added `phase18_structured_re_q2_payload_fixture()` to the structured-RE bridge
  fixture helpers. The fixture records deterministic `mu1`/`mu2` coefficient
  ordering, a 4 x 4 matrix digest, point-only native/direct fixture status, and
  an unavailable R-via-Julia status.
- Extended the mission-control validator and dashboard contract tests so the q2
  payload rows must keep `matrix_digest`, q4-payload exclusion, and the q2 REML
  "not HSquared AI-REML" boundary explicit.

## Checks

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
```

Result: the focused R tests passed with 160 assertions, 0 failures, 0 warnings,
and 0 skips. Mission-control validation passed with 5 q2 payload-contract rows.

## Boundary

This banks q2 payload shape, coefficient ordering, and negative bridge evidence
only. It does not promote q2 R-via-Julia support, q2 REML, q2-plus-q2, q4,
interval coverage, public bridge support, a commit, a PR, or an Ayumi-facing
reply.

## Update 2026-06-23

The phylo q2 payload row is now experimental rather than an intentional-error
row because one complete-response exact-Gaussian ML `mu1`/`mu2` phylo bridge
fixture is implemented and tested. The boundary remains narrow: q2 REML,
q2-plus-q2, q4, interval coverage, one-axis or three-axis partial phylo
payloads, and spatial/animal/relmat q2 bridge rows remain unsupported or
planned.
