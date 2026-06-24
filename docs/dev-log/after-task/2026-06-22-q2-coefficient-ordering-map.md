# 2026-06-22 - SR127 q2 coefficient ordering map

## Goal

Bank the q2 coefficient ordering map for `phylo()`, `spatial()`, `animal()`,
and `relmat()` without promoting q2 R-via-Julia bridge support.

## Changes

- Added a deterministic q2 coefficient-order map helper that derives row order
  from the q2 payload fixture.
- Added `structured-re-q2-coefficient-order-map.tsv` with one row per
  structured type.
- Moved SR127 from queued to banked as a coefficient-map contract row.

## Checks

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts')"
```

Result: passed with 189 assertions, 0 failures, 0 warnings, and 0 skips.

## Boundary

This banks fixture-level coefficient-order evidence only. It does not promote
q2 R-via-Julia bridge support, pedigree/Ainv or Q precision marshalling, q2
REML, q2-plus-q2 support, q4, interval coverage, public optimizer controls, a
commit, a PR, or an Ayumi-facing reply.

## Update 2026-06-23

The phylo coefficient-order row is now attached to one narrow q2 ML
native/direct/bridge fixture. The ordering map remains fixture-level evidence;
it does not promote spatial/animal/relmat q2 bridge support, q2 REML, q4,
interval coverage, public optimizer controls, a commit, a PR, or an
Ayumi-facing reply.
