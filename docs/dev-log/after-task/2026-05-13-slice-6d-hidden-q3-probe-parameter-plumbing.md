# After Task: Slice 6D Hidden q=3 Probe Parameter Plumbing

## Goal

Move the hidden q=3 registry contribution probe from a data-supplied
standardized vector toward production-shaped TMB parameter plumbing, without
making q > 2 covariance blocks available to users.

## Implemented

The C++ template now declares a hidden `PARAMETER_VECTOR(u_re_cov_probe)`.
Ordinary `drmTMB()` fits receive `u_re_cov_probe = 0` in their start list, and
`add_covariance_probe_parameter()` maps that parameter off by default. This
keeps the ordinary optimizer surface unchanged.

Hidden `model_type == 97` now prefers values from `u_re_cov_probe` when they
are supplied. The older `re_cov_probe_z` data vector remains only as a fallback
for algebra probes. The hidden branch also adds the standard normal negative
log-density contribution for the supplied probe parameter, matching the
non-centered random-effect convention used elsewhere in the package.

The direct phylogenetic prior fixture now includes `u_re_cov_probe = 0` because
it calls `TMB::MakeADFun()` outside the ordinary `drmTMB()` spec builder.

## Mathematical Contract

For hidden q=3 groups, the standardized latent vector is now a TMB parameter:

```text
z_g = u_re_cov_probe[g, ]
u_g = s * L_R z_g
z_g ~ Normal(0, I)
```

The test checks that ordinary fits map `u_re_cov_probe` off, then explicitly
unmaps it for the hidden probe and verifies both the contribution matrix and
the standard normal objective contribution.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-covariance-block-registry.R`
- `tests/testthat/test-phylo-utils.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-6d-hidden-q3-probe-parameter-plumbing.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry|phylo-utils")'`: passed with 86 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`: passed with 939 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Tests Of The Tests

The new ordinary-fit assertion checks that `u_re_cov_probe` is present in
`fit$model$start`, mapped to `NA`, and absent from `fit$opt$par`. The hidden
probe test removes that map entry, supplies a q=3-by-group parameter vector,
and verifies that the C++ contribution report uses the parameter values.

## Consistency Audit

The roadmap and q > 2 covariance design notes now state that the hidden q=3
probe uses a dormant TMB parameter. They still reserve production likelihood
wiring, simulation recovery, `corpairs()` rows, and formula syntax for later
slices.

No roxygen, examples, vignettes, NEWS entry, or pkgdown navigation changed
because this is not a user-facing model.

## Known Limitations

`u_re_cov_probe` is not a fitted random-effect block. It is mapped off for
ordinary fits, and the hidden probe still does not add q=3 contributions to
`mu`, `sigma`, `mu1`, `mu2`, `sigma1`, or `sigma2`.

## Next Actions

1. Decide whether the next slice should turn the hidden q=3 probe parameter
   into an actual random effect in `random_names`, or first add a narrower
   no-op objective test around ordinary mapped-off fits.
2. Add production likelihood wiring only after the parameter/random-effect
   boundary is stable.
3. Add simulation recovery before claiming q > 2 covariance support.
