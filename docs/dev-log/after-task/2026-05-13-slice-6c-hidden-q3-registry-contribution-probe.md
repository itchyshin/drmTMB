# After Task: Slice 6C Hidden q=3 Registry Contribution Probe

## Goal

Check that the labelled covariance-block registry can drive a production-shaped
q=3 non-centered contribution map, while keeping q > 2 models unavailable to
users and outside ordinary fitted likelihoods.

## Implemented

`labelled_covariance_block_tmb_data()` now has an explicit internal
`allow_unimplemented` override. The default remains `FALSE`, so the existing
q > 2 export guard still blocks normal use. Tests can set the override to
export a guarded q=3 scaffold into TMB data.

The hidden `model_type == 97` branch reads the exported registry block/member
metadata. For each group in each q=3 block, it takes a group-major standardized
latent vector from `re_cov_probe_z`, maps it through
`VECSCALE(UNSTRUCTURED_CORR(theta), s).sqrt_cov_scale(z)`, and writes the
design-scaled member contributions into `re_cov_probe_contribution`.

## Mathematical Contract

For group `g`, block size `q = 3`, and member design value `x_im`, the hidden
probe computes:

```text
u_g = s * L_R z_g
contribution_im = x_im * u_gm
```

Here `R = L_R L_R'` is the positive-definite q=3 correlation matrix implied by
TMB's `UNSTRUCTURED_CORR_t`. This is the shape the production likelihood needs
before adding actual q=3 random-effect parameters and response-specific linear
predictor updates.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-6c-hidden-q3-registry-contribution-probe.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed with 37 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils")'`: passed with 895 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Tests Of The Tests

The test keeps the normal q > 2 export guard in place, then calls the exporter
with `allow_unimplemented = TRUE` only inside the hidden probe test. It checks
that unimplemented q=3 pair metadata is exported with inert `-1` TMB parameter
codes, and that the reported contribution matrix equals the R reconstruction
from group-specific latent vectors.

## Consistency Audit

`ROADMAP.md`, `docs/design/28-double-hierarchical-endpoint.md`, and
`docs/design/30-labelled-covariance-block-assembler.md` now say that the q=3
path has hidden algebra and registry-shaped contribution probes only. They
still reserve fitted q > 2 likelihoods, simulation recovery, `corpairs()` rows,
and public syntax for later slices.

No roxygen, examples, vignettes, NEWS entry, or pkgdown navigation changed
because this is not a user-facing model.

## Known Limitations

The probe uses data-supplied standardized vectors rather than production TMB
random-effect parameters. It does not add q=3 likelihood terms to `mu`,
`sigma`, `mu1`, `mu2`, `sigma1`, or `sigma2`, and it does not recover simulated
parameters.

## Next Actions

1. Replace the data-supplied q=3 standardized vectors with hidden production
   TMB random-effect parameters for one guarded registry scaffold.
2. Add likelihood contributions to one narrow fitted path only after that
   parameter plumbing is stable.
3. Add simulation recovery before any q > 2 block is reported by `corpairs()`
   or accepted through formula syntax.
