# After Task: Scale Phylo Diagnostic Grid

## Goal

Bank S025 by expanding the scale-side phylogenetic diagnostic surface without
turning clamp activity or identifiability notes into support, interval, or
coverage claims.

## Implemented

Updated `tests/testthat/test-scale-phylo-identifiability.R`:

- the helper can now take a `logsigma_clamp` band while preserving the default;
- a new focused test forces a narrow upper log-sigma clamp on a scale-side
  phylo fit;
- the test checks that `check_drm()` reports both
  `logsigma_clamp_active = warning` and
  `scale_phylo_identifiability = note` on the same fit.

Added `docs/dev-log/dashboard/scale-phylo-diagnostics.tsv` with four guarded
diagnostic rows for mean-only opt-out, scale-side phylo with `pdHess = TRUE`,
scale-side phylo with `pdHess = FALSE`, and scale-side phylo with a clamp-active
fit. The mission-control validator checks the table schema, expected statuses,
evidence paths, and AI-REML readiness guard.

## Checks Run

```sh
Rscript -e 'devtools::test(filter = "scale-phylo-identifiability", reporter = "summary")'
git diff --check
```

Result: focused `scale-phylo-identifiability` tests passed. `git diff --check`
was clean.

## Consistency Audit

This is a diagnostic grid slice. It does not change model behavior, formula
grammar, REML support, bridge support, q4 support, interval coverage,
non-Gaussian REML wording, HSquared AI-REML status, or Ayumi-facing text.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use S026 to compare log-likelihood and profile statuses target by target,
keeping profile rows diagnostic until interval coverage is evaluated.
