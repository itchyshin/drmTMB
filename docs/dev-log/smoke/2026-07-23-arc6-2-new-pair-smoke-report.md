# Arc 6.2 Gaussian × ordinary NB2 smoke — 2026-07-23

## Purpose

This is a non-inferential end-to-end smoke of the new fixed-effect Gaussian ×
ordinary-NB2 frozen-margin pair. The fixture has fixed covariates in both NB2
`mu` and `sigma`, then checks finite interior diagnostics and exact agreement
when the two margin fits are supplied in reverse order.

## Immutable evidence

The retained ledgers are:

- `2026-07-23-arc6-association-smoke-ledger-pre-tail-repair.csv` (initial
  shared-run receipt, retained as provenance);
- `2026-07-23-post-tail-repair/arc6-2-new-pair-smoke-ledger.csv`;
- `2026-07-23-no-clobber-verified/arc6-2-new-pair-smoke-ledger.csv`.
- `2026-07-23-final-tree/arc6-2-new-pair-smoke-ledger.csv`.

The final runner invocation used `R_PROFILE_USER=/dev/null Rscript
--no-init-file tools/run-arc6-association-smokes.R
--out-dir=docs/dev-log/smoke/2026-07-23-final-tree`. Its deliberate
second invocation against the separate no-clobber directory refused to
overwrite the ledger.
The final-tree source base was `d9dc3116`, with the Arc 6.2 implementation
worktree; the association source SHA-256 was
`23bf44a604c06777284d08cda5486575fe29bf4d00242539050c7d54cd48d500`.

## Result

Every retained Arc 6.2 attempt reported `status = interior`,
`eta = 0.427040872814566`, `logLik = -460.857278845882`, and
`swapped_equal = TRUE`.

This smoke does not establish parameter recovery, standard errors, profiles,
intervals, coverage, or capability promotion. It is a finite, order-symmetric
construction receipt for this exact fixed fixture only.
