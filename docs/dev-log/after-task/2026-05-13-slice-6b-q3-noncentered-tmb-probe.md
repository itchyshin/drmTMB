# After Task: Slice 6B q=3 Non-Centered TMB Probe

## Goal

Verify that the q=3 TMB correlation primitive can also produce the
non-centered latent transform needed for production random-effect blocks,
without wiring q > 2 blocks into any fitted likelihood.

## Implemented

The dormant covariance-block data contract now includes one additional
internal probe field, `re_cov_probe_z`. The hidden `model_type == 98` branch
still constructs `density::UNSTRUCTURED_CORR_t` and can evaluate
`density::VECSCALE()` for a supplied q=3 vector. It now also reports
`re_cov_probe_latent`, the result of
`VECSCALE(UNSTRUCTURED_CORR(theta), s).sqrt_cov_scale(z)` when matching
standard deviations are supplied.

The test still builds a simple Gaussian fit only to obtain complete TMB data,
start values, maps, and random-effect declarations. It then switches
`model_type` to 98 and supplies q=3 probe values.

## Mathematical Contract

For TMB's q=3 correlation matrix `R` and positive standard deviations `s`, the
non-centered transform is:

```text
u = s * L_R z
R = L_R L_R'
```

The R-side test reconstructs this as `s * t(chol(R)) %*% z` and compares it to
the C++ report. This is the algebra needed before replacing pairwise
conditional transforms with a full-block latent vector in the production path.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-6b-q3-noncentered-tmb-probe.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed with 31 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils")'`: passed with 889 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Tests Of The Tests

The test compares the C++ transform against an independent R reconstruction
from TMB's reported correlation matrix. It therefore checks the exact
orientation of the Cholesky square root used by `sqrt_cov_scale()`, not only
positive definiteness or finite gradients.

## Consistency Audit

`ROADMAP.md`, `docs/design/28-double-hierarchical-endpoint.md`, and
`docs/design/30-labelled-covariance-block-assembler.md` now describe the q=3
probe sequence as covering both the density evaluation and the non-centered
latent transform. They still say that the fitted q > 2 likelihood and
simulation recovery remain future work.

No formula grammar, roxygen, examples, vignettes, NEWS entry, or pkgdown
navigation changed because this is a hidden TMB probe, not a supported model.

## Known Limitations

This is not a fitted q > 2 covariance model. The probe does not use registry
blocks, does not allocate production q=3 random-effect parameters, does not
add `corpairs()` rows, and does not provide simulation recovery.

## Next Actions

1. Route one hidden q=3 registry scaffold through a production-shaped latent
   vector loop, still gated away from user syntax.
2. Add a small simulation recovery test only after the registry-backed
   production-shaped transform exists.
3. Keep q > 2 `corpairs()` and `profile_targets()` rows closed until fitted
   recovery is persuasive.
