# 2026-06-22 - SR125 q2-plus-q2 boundary contract

## Goal

Bank the q2-plus-q2 scale-block boundary as a target contract without treating
two q2 blocks as full q4 or as R-via-Julia bridge support.

## Changes

- Repointed the `q2_plus_q2_phylo_ml` target-contract and bridge-boundary rows
  to this after-task report.
- Moved SR125 from queued to banked as a q2-plus-q2 target-boundary row. The
  bridge status remains planned because no same-target native/direct/R-via-Julia
  q2-plus-q2 parity fixture exists.

## Checks

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts')"
```

Result: the q2 fixture and dashboard-contract tests passed earlier in this
tranche with the q2-plus-q2 row checked as separate from q2 and full q4.

## Boundary

This banks target vocabulary and negative boundary evidence only. It does not
promote q2-plus-q2 R-via-Julia support, q2 bridge parity, full q4 covariance,
q4 derived correlations, q2/q4 REML, interval coverage, public bridge support, a
commit, a PR, or an Ayumi-facing reply.
