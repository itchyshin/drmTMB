# After Task: Slice 4 C++ Block Contract Visibility

## Goal

Pass the dormant two-member labelled covariance block data contract through the
R-to-TMB boundary without changing fitted behaviour.

## Implemented

Every model spec now appends either the fitted covariance block `tmb_data` or
the empty covariance block contract before calling `TMB::MakeADFun()`. The C++
template declares the `re_cov_*` fields and casts them to `void`, so the
compiled objective requires and sees the contract but does not use it in the
likelihood.

The tests now check that fitted registry block data are present in
`fit$model$tmb_data` for univariate mean-slope, univariate mean-scale,
bivariate mean-mean, bivariate scale-scale, and combined bivariate mean plus
scale paths. One representative bivariate fit also rebuilds the objective after
scrambling the dormant `re_cov_*` data and confirms that the objective and
gradient are unchanged.

## Mathematical Contract

This patch is intentionally a no-op for the model:

```text
current fitted likelihood = existing pairwise random-effect fields
dormant block contract    = declared TMB data only
change in objective       = 0
change in gradient        = 0
```

The block contract is now visible to C++, but larger `q > 2` covariance blocks
still need a positive-definite parameterization before any likelihood code
should use those fields.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/helper-covariance-blocks.R`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `tests/testthat/test-phylo-utils.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-4-cpp-block-contract-visibility.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/helper-covariance-blocks.R tests/testthat/test-biv-gaussian.R tests/testthat/test-gaussian-random-intercepts.R tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e 'devtools::load_all()'`: passed and recompiled `drmTMB`; clang reported three existing Eigen/TMB header warnings and no new `drmTMB.cpp` warnings.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|gaussian-random-intercepts|phylo-utils")'`: passed with 857 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "corpairs|check-drm|profile-targets|biv-gaussian|gaussian-random-intercepts|phylo-utils")'`: passed with 1216 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "package-skeleton")'`: passed with 40 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Tests Of The Tests

`expect_covariance_block_tmb_data_exported()` checks the exact names and values
of the covariance block data copied into each fitted model's TMB data list. The
no-op helper scrambles every dormant `re_cov_*` field except the block count,
then compares the rebuilt objective and gradient with the original fit. That
would fail if the C++ template started using the dormant contract before the
likelihood implementation was ready.

The direct phylogenetic prior test fixture also includes the empty block
contract, so hand-built `TMB::MakeADFun()` calls exercise the same required data
surface as fitted `drmTMB()` models.

## Consistency Audit

`ROADMAP.md` and `docs/design/30-labelled-covariance-block-assembler.md` now say
that two-member block data cross the C++ boundary as a no-op. The
double-hierarchical endpoint note now points larger shared labels through a
guarded three-member scaffold and positive-definite `q > 2` parameterization
before the four-effect block.

I checked the status wording with:

```sh
rg -n 'not passed to `TMB::MakeADFun\(\)`|larger shared labels still need C\+\+|C\+\+ contract visibility|full shared block.*implemented|planned.*implemented' README.md ROADMAP.md NEWS.md docs vignettes
rg -n 'rho12|sigma1|sigma2|sd\(' README.md ROADMAP.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

The remaining `planned.*implemented` hits are historical check-log or
after-task entries, planned structured-effect wording, or formula/status
inventory rows that still correctly separate implemented two-member bridges
from planned larger blocks.

No roxygen, exported help topic, vignette example, or pkgdown navigation changed.
This is an internal architecture slice, so `NEWS.md` was not updated.

## What Did Not Go Smoothly

The direct phylogenetic prior fixture was an easy path to miss because it calls
`TMB::MakeADFun()` without going through `drmTMB()`. Updating that fixture kept
the new data contract universal.

The first test assertion only proved that one fitted object carried the new
data. Curie recommended the stronger helper plus no-op objective check, which
is now the acceptance test for this slice.

## Team Learning

Dormant TMB contracts should be tested in two ways: the data must be exported
into the fitted object, and changing the dormant data must not change the
objective or gradient. That gives Gauss a numerical guard and Emmy a stable
object-structure guard before likelihood work begins.

## Known Limitations

Slice 4 still does not fit a general labelled covariance block. Current fitted
support remains two-member pairwise bridges plus registry-backed reporting.
There is no `q > 2` positive-definite covariance parameterization, no bivariate
random-slope block, and no full shared `mu1`/`mu2`/`sigma1`/`sigma2` block yet.

## Next Actions

1. Add a guarded three-member simulation scaffold that stays disabled or
   internal until the likelihood path exists.
2. Prototype the positive-definite `q > 2` covariance parameterization.
3. Only then expose bivariate random slopes or a full shared
   `mu1`/`mu2`/`sigma1`/`sigma2` label pattern.
