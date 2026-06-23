# 2026-06-22 - SR126 q2 scale-only rejection boundary

## Goal

Bank scale-only q2 structured random-effect rejection evidence for
`spatial()`, `animal()`, and `relmat()` without promoting q2 bridge support.

## Changes

- Added a focused rejection test showing `sigma1`/`sigma2`-only q2 structured
  blocks reject before optimization for spatial, animal-model, and relmat
  routes.
- Added the `q2_scale_only_structured_rejections` bridge-boundary row.
- Moved SR126 from queued to banked as an intentional-error row.

## Checks

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-q2-rejections|structured-re-conversion-contracts')"
```

Result: passed with 125 assertions, 0 failures, 0 warnings, and 0 skips.

## Boundary

This banks negative evidence only. It does not promote q2 R-via-Julia bridge
support, balanced q2 location-scale support, q2 REML, q2-plus-q2 support, q4,
interval coverage, public optimizer controls, a commit, a PR, or an
Ayumi-facing reply.
