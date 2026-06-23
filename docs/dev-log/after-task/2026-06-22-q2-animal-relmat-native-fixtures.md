# 2026-06-22 - SR123-SR124 q2 animal and relmat native fixtures

## Goal

Bank animal-model and `relmat()` q2 location evidence as native R/TMB point-only
fixtures without promoting R-via-Julia bridge parity.

## Changes

- Repointed the q2 animal and relmat native-evidence ledger rows from generic
  matrix status to the focused animal/relmat q2 smoke test and this after-task
  report.
- Moved SR123 and SR124 from queued to banked as native point-only evidence. The
  R-via-Julia bridge status remains planned because no q2-specific bridge route
  exists.

## Checks

```sh
Rscript --vanilla -e "devtools::test(filter = 'phase18-animal-relmat-q2-smoke')"
```

Result: the focused animal/relmat q2 smoke test passed with 43 assertions, 0
failures, 0 warnings, and 0 skips.

## Boundary

This banks animal and relmat q2 native ML point evidence only. It does not
promote R-via-Julia bridge parity, pedigree/Ainv bridge marshalling, Q/precision
bridge marshalling, q2 REML, q2-plus-q2, q4, interval coverage, public bridge
support, a commit, a PR, or an Ayumi-facing reply.
