# After Task: Slice 18 Direct-SD Family Boundary Guard

## Goal

Keep Family A all-four q=4 covariance blocks and Family B direct location-SD
models from being combined for the same bivariate grouping level.

## Implemented

- Added an explicit `biv_gaussian()` guard for same-group mixtures of
  `sd1(group)` / `sd2(group)` with the all-four q=4
  `mu1`/`mu2`/`sigma1`/`sigma2` covariance block.
- Added a bivariate negative test for the new Family A versus Family B error.
- Updated NEWS, formula grammar, likelihood notes, random-effect scale design,
  phylo/spatial common math, and known limitations.
- Recorded why `sd_phylo(species) ~ z` remains planned: predictor-dependent
  structured SDs imply a covariance such as `D(z) A D(z)` and need a precise
  tip/internal-node contract for the sparse augmented A-inverse path.

## Mathematical Contract

The implemented ordinary q=4 Family A block estimates one constant covariance
matrix for:

```text
u_j = [b_mu1_j, b_mu2_j, a_sigma1_j, a_sigma2_j]'
u_j ~ MVN(0, Sigma_id)
```

Direct-SD formulas such as `sd1(id) ~ z` and `sd2(id) ~ z` model the
location-effect SDs directly. Combining them with the same q=4 block would
turn selected entries of `Sigma_id` into group-varying functions without a
defined covariance parameterization, so the builder rejects that hybrid.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-biv-gaussian.R`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R`
- `Rscript -e 'devtools::test(filter = "biv-gaussian", reporter = "summary")'`
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`
- `git diff --check`
- `rg -n 'bivariate structured effects remain planned|only the intercept-only phylogenetic .* form is fitted|sd_phylo\\(species\\).*Implemented|sd1\\(id\\).*q=4.*Implemented' docs NEWS.md R tests`

## Tests Of The Tests

The new regression test exercises a malformed model that previously reached an
indirect missing-target path after q=4 pruning. It now fails before fitting
with the intended Family A versus Family B message.

## Consistency Audit

The docs now distinguish three boundaries:

- ordinary `sd1()` / `sd2()` location direct-SD models are implemented;
- same-group mixtures with all-four q=4 Family A blocks are rejected;
- structured direct-SD targets such as `sd_phylo()` remain planned until the
  covariance contract is explicit.

## What Did Not Go Smoothly

The first stale-wording scan used shell double quotes around a pattern
containing backticks, which made the shell try to execute `mu`. The scan was
rerun with single quotes and no stale matches were found.

## Team Learning

Boole's grammar boundary matters here: a friendly error is better than
allowing q=4 term pruning to produce a technically correct but misleading
missing-target message. Noether's math boundary is that structured direct-SD
models need their own covariance equation before they can be code.

## Known Limitations

- `sd_phylo()`, `sd_phylo1()`, `sd_phylo2()`, and spatial direct-SD names
  remain planned.
- Predictor-dependent q=4 covariance blocks remain planned.
- The guard is same-group: separate groups can still use implemented
  location-only direct-SD formulas if they have matching location random
  intercepts outside the q=4 block.

## Next Actions

Continue with safe hardening slices: either add more malformed-input tests for
structured direct-SD names, or move to a design-only slice for structured
random slopes and their covariance dimensions.
