# After Task: Map Slice 22 sd_phylo Recovery Diagnostics

## Goal

Harden the first univariate `sd_phylo(species) ~ x_species` implementation with
diagnostics and tests that make weak recovery visible before users interpret the
direct-SD surface.

## Implemented

- Added `check_phylo_direct_sd_model()` to `check_drm()`.
- The row appears only for univariate Gaussian fits with a Family B
  `sd_phylo()` direct-SD model.
- The diagnostic reports the direct-SD target, phylogenetic group, number of
  species, minimum fitted observations per species, fitted SD range, and maximum
  species-SD ratio.
- The row is `ok` for replicated species and finite positive fitted SD values,
  `note` when at least one species has fewer than two fitted observations, and
  `error` when the fitted SD surface is non-finite or non-positive.
- NEWS, roadmap, known limitations, the random-effect scale design note, and
  roxygen documentation now mention the diagnostic.

## Mathematical Contract

This slice does not change the likelihood. It checks the fitted Family B
contract from Slice 21:

```text
tau_l = exp(W_l alpha_phylo)
v_aug ~ MVN(0, A_aug)
a_l = tau_l v_tip,l
Cov(a_tip) = D_tip A_tip D_tip
```

The diagnostic treats `tau_l` as the species-level SD surface and checks whether
the observed species have enough replication for that surface to be read
cautiously.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`
- `man/check_drm.Rd`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md ROADMAP.md docs/design/18-random-effect-scale-models.md docs/dev-log/known-limitations.md`: passed.
- `Rscript -e 'devtools::document()'`: passed.
- `Rscript -e 'devtools::test(filter = "check-drm|phylo-gaussian", reporter = "summary")'`: passed after two test-only fixes.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `rg -n 'sd_phylo\(species\).*not implemented|sd_phylo\(species\).*unsupported|phylo_direct_sd_model.*planned|direct-SD surface diagnostics.*planned|check_drm\(\).*sd_phylo.*planned|univariate `sd_phylo\(\)`.*remain planned' README.md ROADMAP.md NEWS.md docs vignettes man pkgdown-site/articles/phylogenetic-spatial.html`: no hits.
- `git diff --check`: passed.

## Tests Of The Tests

The new test checks three branches:

- a normal fitted `sd_phylo()` model receives an `ok` diagnostic row;
- a mutated single-species replication surface receives a `note`;
- a mutated non-finite fitted SD receives an `error` and makes the diagnostic
  object fail its global ok flag.

The first version also failed when the test used `tree = sim$tree`, confirming
that the formula parser still enforces symbolic tree names.

## Consistency Audit

The support status is consistent across NEWS, roadmap, known limitations,
random-effect scale design notes, roxygen, generated Rd, and tests. The
stale-wording scan found no current text saying univariate `sd_phylo(species)`
diagnostics are planned, unsupported, or missing.

## What Did Not Go Smoothly

The test initially violated the public formula grammar by passing `sim$tree`
inside `phylo()`. After that was fixed, the singleton branch asserted the
global `check_drm()` ok flag rather than the new diagnostic row; that was too
broad because unrelated warning rows can make the global flag false. The final
test is narrower and more stable.

## Team Learning

- Ada: keep diagnostic slices narrow and resist adding new likelihood behavior
  while hardening recovery evidence.
- Boole: test formulas must use the same public grammar readers use, especially
  symbolic `tree = tree`.
- Gauss: no TMB change was needed; recovery hardening can happen at the
  extractor and diagnostic layer when the likelihood contract is unchanged.
- Noether: the diagnostic wording should continue to name `tau_l` as the
  tip-level SD surface, not an internal-node parameter.
- Curie: mutation tests are useful for branch coverage, but assertions should
  target the row under test rather than the whole diagnostic object when other
  checks may legitimately warn.
- Fisher: this row is a guardrail, not evidence from a broad recovery grid; the
  next validation should vary tree shape, species counts, and predictor
  strength.
- Pat: applied users now get a direct "look here first" diagnostic for
  `sd_phylo()` rather than inferring weak replication from raw output.
- Darwin: future examples should explain that species-level SD predictors need
  species-level ecological covariates and enough within-species replication.
- Emmy: the diagnostic uses the stored `random_scale$phylo` structure rather
  than reparsing formulas, keeping S3 methods and object internals aligned.
- Grace: full tests and pkgdown check are clean locally; GitHub Actions should
  be rechecked after the slice commit is pushed.
- Rose: record test-only failures because they reveal process lessons even when
  implementation code was not at fault.

## Known Limitations

- No broad recovery grid was added in this slice.
- Bivariate `sd_phylo1()` / `sd_phylo2()` and spatial direct-SD diagnostics
  remain planned.
- `check_drm()` cannot turn weak replication into identifiability; it only makes
  the weakness visible.

## Next Actions

- Slice 23: design bivariate `sd_phylo1()` / `sd_phylo2()` without mixing it
  with Family A q4 scale random effects.
- Keep predictor-dependent latent `corpair() ~ w` deferred until endpoint
  semantics are settled.
