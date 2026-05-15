# After Task: Slice 17 q4 Profile-Target Status Guard

## Goal

Prevent ordinary q4 unstructured-correlation parameters from being advertised as
direct pairwise profile-likelihood targets.

## Implemented

`profile_targets()` still lists q4 latent correlation rows from the covariance
registry, but rows backed by `theta_re_cov` are now marked as:

```text
target_type = "derived"
profile_ready = FALSE
profile_note = "derived_unstructured_correlation"
transformation = "unstructured_corr"
```

This keeps the target inventory visible while preventing `confint()` from
profiling a q4 theta coordinate as though it were a simple atanh correlation.

## Mathematical Contract

Two-member covariance bridges use scalar transformed correlations, so their
profile target can map directly to an internal `eta_cor_*` parameter. The q4
ordinary block uses TMB's `UNSTRUCTURED_CORR_t`, where each optimized theta
coordinate contributes to the positive-definite correlation matrix. A reported
pairwise correlation is therefore a derived quantity, not one theta coordinate
on a Fisher-z scale.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "profile-targets|biv-gaussian|summary", reporter = "summary")'`:
  passed.
- `git diff --check`: passed.

## Tests Of The Tests

The q4 profile-target test now builds fitted-like q4 registry rows backed by
`theta_re_cov`, verifies that all six rows are listed but not profile-ready,
checks that `ready_only = TRUE` excludes them, and confirms `confint(...,
method = "profile")` rejects the q4 target as not ready.

## Consistency Audit

Synchronized NEWS, known limitations, the double-hierarchical endpoint note, and
the labelled covariance assembler note. The docs now say q4 point summaries and
target inventory exist, while direct profile intervals remain planned.

## What Did Not Go Smoothly

The audit exposed a genuine semantic risk from the hidden q4 scaffold: target
names were correct, but treating `theta_re_cov` as a direct `tanh` target would
have profiled the wrong quantity.

## Team Learning

For q > 2 covariance blocks, pairwise correlations should be treated as derived
functions of the internal correlation parameterization unless a dedicated
fix-and-refit or derived-profile method is implemented.

## Known Limitations

No q4 correlation confidence intervals are implemented. The covariance summary
still reports q4 point estimates only.

## Next Actions

Add Family B `sd_phylo()` planning or implementation scaffolding, or build a
small q4 summary example only after deciding whether q4 point estimates are
ready for reader-facing tutorials.
