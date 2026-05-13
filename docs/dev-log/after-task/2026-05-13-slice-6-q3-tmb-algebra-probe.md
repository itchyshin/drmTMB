# After Task: Slice 6 q=3 TMB Algebra Probe

## Goal

Verify, inside the package template, that TMB can build and evaluate a
positive-definite q=3 correlation block before wiring any q > 2 block into a
fitted model.

## Implemented

The dormant covariance-block data contract now includes three internal probe
fields: `re_cov_probe_theta`, `re_cov_probe_sd`, and `re_cov_probe_x`. A hidden
`model_type == 98` branch in `src/drmTMB.cpp` constructs
`density::UNSTRUCTURED_CORR_t`, reports its correlation matrix, and evaluates
either the unscaled density or `density::VECSCALE()` for a supplied q=3 vector.

The new test builds a normal Gaussian fit only as a source of complete TMB
start, map, random, and data objects. It then swaps `model_type` to 98 and
passes q=3 probe values. The test checks that the reported correlation matrix is
symmetric, has unit diagonal, matches TMB's documented lower-triangle
normalization, has positive eigenvalues, and gives finite objective and gradient
values.

## Mathematical Contract

For unconstrained lower-triangle values `theta`, TMB constructs a lower
triangular matrix `L`, forms `L L'`, and normalizes it to a correlation matrix.
The probe checks:

```text
R = cov2cor(L L')
diag(R) = 1
eigen(R) > 0
```

With positive standard deviations `s`, `VECSCALE(UNSTRUCTURED_CORR(theta), s)`
evaluates the scaled multivariate normal density for a q=3 vector. This slice
does not yet use the non-centered transform needed for production random
effects.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-6-q3-tmb-algebra-probe.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-covariance-block-registry.R`: passed.
- `Rscript -e 'devtools::load_all()'`: passed and recompiled `drmTMB`; clang reported three existing Eigen/TMB header warnings and no new `drmTMB.cpp` warnings.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed with 30 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils")'`: passed with 888 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

After a Codex compaction crash, the recovery restart reran `git diff --check`,
the focused covariance-block-registry test, and the four-context targeted test
on the same checkout; all passed again.

## Tests Of The Tests

The test independently reconstructs TMB's documented correlation normalization
in R with `cov2cor(L %*% t(L))` and compares it to the C++ report. It also
checks finite objective and gradient values from the same `MakeADFun()` object,
so the probe exercises compiled TMB density code rather than only an R-side
matrix calculation.

## Consistency Audit

`ROADMAP.md`, `docs/design/28-double-hierarchical-endpoint.md`, and
`docs/design/30-labelled-covariance-block-assembler.md` now describe the q=3
TMB algebra probe as started, while still saying that the fitted q > 2
likelihood and simulation recovery remain future work.

No formula grammar, roxygen, examples, vignettes, NEWS entry, or pkgdown
navigation changed because this is a hidden algebra probe, not a supported
model.

## What Did Not Go Smoothly

The first implementation used `VECSCALE()` directly, which is enough to prove
positive-definite algebra but not enough for the non-centered random-effect
design. Gauss and Jason flagged that the production prototype should use
`sqrt_cov_scale()` on standardized q-vectors.

## Team Learning

The TMB helper should be treated as a correlation-matrix generator, not as
three pairwise Fisher-z links. Its theta values jointly determine all
correlations, so future `corpairs()` rows should report response-scale
correlations from the resulting matrix rather than pretending each optimizer
coordinate is one pairwise `atanh(r)`.

## Known Limitations

This is not a fitted q > 2 covariance model. The probe has a hidden
`model_type`, does not add user syntax, does not allocate production
random-effect parameters, does not transform predictor contributions, and does
not provide simulation recovery.

## Next Actions

1. Add an internal non-centered q=3 prototype using
   `VECSCALE(UNSTRUCTURED_CORR(theta), exp(log_sd)).sqrt_cov_scale(z)`.
2. Add an internal simulation recovery test after the non-centered predictor
   contribution exists.
3. Only after recovery is persuasive should q > 2 block rows appear in
   `corpairs()`, `profile_targets()`, or user-facing formula grammar.
