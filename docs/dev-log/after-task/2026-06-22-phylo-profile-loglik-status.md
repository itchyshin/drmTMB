# After Task: Phylo Profile LogLik Status

## Goal

Bank S026 by separating finite log-likelihood status, profile-target readiness,
and interval status for selected phylogenetic Gaussian targets.

## Implemented

Updated `tests/testthat/test-phylo-gaussian.R` so the sigma-only native ML
`phylo()` test also checks:

- finite `logLik(fit)`;
- a direct `sd:sigma:phylo(1 | species)` profile target;
- `profile_ready = TRUE`;
- `profile_note = "ready"`.

Added `docs/dev-log/dashboard/phylo-profile-loglik-status.tsv` with six guarded
rows covering univariate `mu`, univariate `sigma`, univariate mean-scale
correlation, native q4 sigma-axis SD targets, native q4 derived correlations,
and the experimental Julia q4 phylocov profile-target inventory. The validator
checks schema, statuses, evidence paths, and AI-REML readiness wording.

## Checks Run

```sh
Rscript -e 'devtools::test(filter = "phylo-gaussian", reporter = "summary")'
git diff --check
```

Result: focused `phylo-gaussian` tests passed. `git diff --check` was clean.

## Consistency Audit

This is a status-parity slice. It does not change model behavior, formula
grammar, REML support, bridge support, q4 support, interval coverage,
non-Gaussian REML wording, HSquared AI-REML status, or Ayumi-facing text.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use S027 to standardize bootstrap refit-count and failure-reason accounting
without making a coverage claim.
