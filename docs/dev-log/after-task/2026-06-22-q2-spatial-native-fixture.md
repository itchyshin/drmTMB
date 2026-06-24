# 2026-06-22 - SR122 q2 spatial native fixture

## Goal

Bank coordinate-spatial q2 location evidence as a native R/TMB point-only fixture
without promoting R-via-Julia bridge parity.

## Changes

- Repointed the q2 spatial native-evidence ledger from generic matrix status to
  the focused spatial q2 smoke test and this after-task report.
- Moved SR122 from queued to banked as native point-only evidence. The
  R-via-Julia bridge status remains planned because no q2-specific bridge route
  exists.

## Checks

```sh
Rscript --vanilla -e "devtools::test(filter = 'phase18-spatial-q2-smoke')"
```

Result: the focused spatial q2 smoke test passed with 20 assertions, 0
failures, 0 warnings, and 0 skips.

## Boundary

This banks coordinate-spatial q2 native ML point evidence only. It does not
promote R-via-Julia bridge parity, q2 REML, q2-plus-q2, q4, interval coverage,
mesh/SPDE support, public bridge support, a commit, a PR, or an Ayumi-facing
reply.
