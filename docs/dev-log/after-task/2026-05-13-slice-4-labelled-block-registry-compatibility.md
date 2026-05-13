# After Task: Slice 4 Labelled Block Registry Compatibility

## Goal

Start the slice-4 implementation by adding an R-side labelled covariance block
registry for the covariance paths that already fit, while preserving current
TMB inputs and fitted behaviour.

## Implemented

`drmTMB()` specs now store `model$random$covariance_blocks`. The registry has
three linked tables: `blocks`, `members`, and `pairs`. It records implemented
ordinary grouped two-member covariance bridges for ordinary labelled `mu`
intercept-slope blocks, univariate `mu`/`sigma`, bivariate `mu1`/`mu2`,
bivariate `sigma1`/`sigma2`, and same-response bivariate `mu`/`sigma`
random-intercept covariance.

This is a compatibility layer only. The existing pairwise fields still drive
`make_tmb_data()`, `start`, `map`, `random_names`, TMB likelihoods,
`corpairs()`, `profile_targets()`, and `check_drm()`.

## Mathematical Contract

No likelihood changed. The registry records the block abstraction that will
later support:

```text
z_bj ~ Normal(0, I_q)
r_bj = diag(sd_b) L_corr_b z_bj
```

For this compatibility slice, every registered fitted block has two members and
maps back to the existing direct pairwise correlation parameter.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `ROADMAP.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format R/drmTMB.R`: passed.
- `air format tests/testthat/test-biv-gaussian.R
  tests/testthat/test-gaussian-random-intercepts.R`: passed in Curie's lane.
- `Rscript -e 'devtools::test(filter =
  "gaussian-random-intercepts|biv-gaussian")'`: passed with 684 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "gaussian-random-intercepts|biv-gaussian|corpairs|profile-targets|check-drm")'`:
  passed with 1032 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

`devtools::document()` was not needed because no roxygen comments changed.

## Tests Of The Tests

The new expectations inspect fitted and spec-level registry metadata for
existing fitted two-member covariance cases. They check block rows, member
rows, pair rows, zero-based IDs, distributional parameters, response indexes,
coefficient names, latent indexes, and design values. They do not relax any
simulation recovery tolerances.

## Consistency Audit

Halley mapped the insertion points; Boole checked registry field names against
the formula grammar and future `corpairs()` table; Gauss checked that the
metadata stayed outside TMB inputs; Curie added focused tests; Rose identified
the needed roadmap and evidence updates.

The roadmap now says the R-side registry exists for implemented two-member
bridges, while larger shared labels still need a TMB block contract,
block-derived extractors, and simulation recovery before exposure.

## What Did Not Go Smoothly

The first smoke command used shell double quotes, so `$` expansion rewrote
temporary R data-frame assignments. Rerunning the same probes with single quotes
confirmed the registry shape for ordinary `mu` and bivariate `mu`/`sigma`
cases.

## Team Learning

Ada kept the implementation metadata-only. Halley confirmed the smallest safe
insertion point. Boole prevented overloaded field names such as `term_index`
and `response`. Gauss kept the TMB boundary clean. Curie made the compatibility
tests concrete. Rose kept the landing claim narrower than the final
double-hierarchical endpoint.

## Known Limitations

The registry does not yet feed TMB. It does not implement `q > 2` blocks,
bivariate random slopes, full shared `mu1`/`mu2`/`sigma1`/`sigma2` labels,
phylogenetic or spatial covariance blocks, residual `rho12` random effects, or
block-derived `corpairs()`, `profile_targets()`, and `check_drm()` rows.

## Next Actions

Implement the first TMB-facing block data contract behind the current
two-member cases, still without enabling larger shared labels. Keep the old
pairwise fields as a compatibility layer until block-derived `corpairs()`,
`profile_targets()`, and `check_drm()` are tested.
