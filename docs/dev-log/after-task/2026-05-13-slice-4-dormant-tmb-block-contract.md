# After Task: Slice 4 Dormant TMB Block Contract

## Goal

Add the first TMB-shaped labelled covariance block data contract behind the
current two-member covariance registry, without making C++ consume it yet.

## Implemented

`model$random$covariance_blocks$tmb_data` now stores a numeric/integer contract
for the implemented ordinary grouped covariance blocks. The contract records
block sizes, group counts, member starts, pair starts, component and
distributional-parameter codes, response indexes, source term and coefficient
positions, latent indexes, design values, pair member indexes, pair parameter
codes, and pair parameter indexes.

This is dormant data. It is not passed through `spec$tmb_data`, not consumed by
`src/drmTMB.cpp`, and does not change fitted behaviour. It is explicitly
two-member-only until the registry can generate all `q * (q - 1) / 2` pair rows
or a complete Cholesky parameter-index layout for `q > 2`.

## Mathematical Contract

The future block likelihood still targets:

```text
z_bj ~ Normal(0, I_q)
r_bj = diag(sd_b) L_corr_b z_bj
```

For this slice, every dormant TMB block has two members and maps back to the
existing pairwise correlation parameter.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `ROADMAP.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R
  tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e 'devtools::test(filter =
  "gaussian-random-intercepts|biv-gaussian")'`: passed with 768 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "gaussian-random-intercepts|biv-gaussian|corpairs|profile-targets|check-drm")'`:
  passed with 1128 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

`devtools::document()` was not needed because no roxygen comments changed.

## Tests Of The Tests

The existing registry tests now also assert the dormant TMB contract. They
check zero-based block/member starts, component codes, distributional-parameter
codes, response indexes, source term and coefficient positions, latent-index
matrix dimensions, design-value matrix dimensions, pair member indexes, pair
parameter codes, pair parameter indexes, and the invariant that the exported
pair arrays match the advertised two-member block pair counts.

## Consistency Audit

The design document now lists the actual dormant contract names. The roadmap
states that the TMB-shaped block contract exists but is not yet consumed by
C++ and does not enable larger shared labels.

## What Did Not Go Smoothly

The first version exposed pair starts as numeric because `cumsum()` returns a
double vector. The contract now coerces block starts and pair starts to
integers. Gauss-copy also caught a more important issue: the draft advertised
`choose(q, 2)` pairs but only generated pair rows for `q = 2`. The current
contract is therefore explicitly two-member-only.

## Team Learning

Ada kept the contract dormant. Gauss's earlier review set the boundary that
the contract must stay out of `spec$tmb_data`, `start`, `map`, and
`random_names` until the C++ path is ready. Gauss-copy kept the contract honest
about `q > 2`. Curie-style tests now lock down the integer/matrix contract
before that C++ work begins.

## Known Limitations

The C++ template still consumes the old pairwise covariance fields. The dormant
contract does not implement `q > 2`, `UNSTRUCTURED_CORR_t`, bivariate random
slopes, full shared `mu1`/`mu2`/`sigma1`/`sigma2` labels, or block-derived
extractor/check output.

## Next Actions

Have Gauss review the dormant contract, then either commit it or adjust the
field layout. The next coding slice is C++ consumption for current two-member
blocks behind the existing pairwise behaviour.
