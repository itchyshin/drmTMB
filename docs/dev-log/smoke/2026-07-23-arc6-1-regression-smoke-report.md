# Arc 6.1 regression smoke — 2026-07-23

## Purpose

This is a non-inferential regression check of the completed Gaussian ×
Bernoulli frozen-margin implementation. It checks that a fixed fixture still
constructs an interior association and that reversing the input fits preserves
the point estimate and joint log likelihood.

## Immutable evidence

The retained ledgers are:

- `2026-07-23-arc6-association-smoke-ledger-pre-tail-repair.csv` (initial
  shared-run receipt, retained as provenance);
- `2026-07-23-post-tail-repair/arc6-1-regression-smoke-ledger.csv`;
- `2026-07-23-no-clobber-verified/arc6-1-regression-smoke-ledger.csv`.
- `2026-07-23-final-tree/arc6-1-regression-smoke-ledger.csv`.

The final runner invocation used `R_PROFILE_USER=/dev/null Rscript
--no-init-file tools/run-arc6-association-smokes.R
--out-dir=docs/dev-log/smoke/2026-07-23-final-tree`. Its deliberate
second invocation against the separate no-clobber directory refused to
overwrite the ledger.
The final-tree source base was `d9dc3116`, with the Arc 6.2 implementation
worktree; the runner source SHA-256 was
`3ee95c92a4194d0cf89a2169fc0a9a97634de186819b0c8ceaf8fced831ebd8c`.

## Result

Every retained Arc 6.1 attempt reported `status = interior`,
`eta = 0.443475352249739`, `logLik = -244.708516941749`, and
`swapped_equal = TRUE`.

This smoke does not establish recovery, an interval, coverage, or a capability
tier. It is a regression receipt only.
