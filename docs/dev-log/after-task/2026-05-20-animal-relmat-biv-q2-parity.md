# After Task: Animal/Relmat Bivariate Q2 Known-Matrix Parity

## Goal

Start the post-`0.1.3` structural-dependence parity work by giving `animal()`
and `relmat()` the same first bivariate Gaussian q=2 known-matrix location
covariance surface already available for the coordinate-spatial sibling.

## Implemented

- Added matching bivariate `animal()` and `relmat()` extraction for labelled
  known-matrix `mu1`/`mu2` terms.
- Reused the existing known precision path so `A`/`K` covariance inputs and
  `Ainv`/`Q` precision inputs both feed the same TMB precision machinery.
- Exposed two structured location SDs and one mean-mean correlation through
  `sdpars$mu`, `corpars$animal` / `corpars$relmat`, `ranef()`, `corpairs()`,
  `summary()$covariance`, and `profile_targets()`.
- Extended `check_drm()` known-relatedness diagnostics so q=2 fitted terms
  report coefficient count, minimum structured SD, and minimum SD-to-residual
  ratio instead of trying to force vector values into a scalar row.
- Updated README, NEWS, ROADMAP, formula grammar, likelihood notes, readiness
  matrices, known limitations, and the structural-dependence article to say the
  q=2 known-matrix slice is fitted while broader parity remains planned.

## Mathematical Contract

For matching labelled terms such as
`mu1 = y1 ~ animal(1 | p | id, Ainv = Ainv)` and
`mu2 = y2 ~ animal(1 | p | id, Ainv = Ainv)`, the fitted latent location fields
share the same known precision over `id` and estimate a 2 x 2 endpoint
covariance for `mu1` and `mu2`. The same contract applies to
`relmat(1 | p | id, K = K)` or `relmat(1 | p | id, Q = Q)`. This is latent
structured mean-mean covariance, not residual `rho12` and not observation-level
known sampling covariance from `meta_V(V = V)`.

## Files Changed

- `R/drmTMB.R`, `R/check.R`, `R/formula-markers.R`
- `tests/testthat/test-animal-relmat-gaussian.R`
- `man/animal.Rd`, `man/relmat.Rd`, `man/check_drm.Rd`
- `DESCRIPTION`, `NEWS.md`, `README.md`, `_pkgdown.yml`, `ROADMAP.md`
- `vignettes/formula-grammar.Rmd`, `vignettes/model-map.Rmd`,
  `vignettes/phylogenetic-spatial.Rmd`
- `docs/design/01-formula-grammar.md`,
  `docs/design/02-family-registry.md`,
  `docs/design/03-likelihoods.md`,
  `docs/design/16-phylo-spatial-common-math.md`,
  `docs/design/34-validation-debt-register.md`,
  `docs/design/37-worked-example-inventory.md`,
  `docs/design/41-phase-18-simulation-programme.md`,
  `docs/design/45-cross-dpar-correlation-gate.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/forgotten-promises-status-2026-05-20.md`,
  `docs/dev-log/known-limitations.md`,
  `docs/dev-log/structural-dependence-parity-2026-05-20.md`

## Checks Run

```sh
air format R/check.R R/drmTMB.R R/formula-markers.R tests/testthat/test-animal-relmat-gaussian.R
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian|phylo-gaussian|spatial-gaussian|profile-targets|check-drm|corpairs', reporter = 'summary')"
Rscript -e "devtools::test(reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check()"
git diff --check
```

The focused `animal-relmat-gaussian` test passed after the final error-message
polish, the broader structured-covariance test set passed, the full
`devtools::test()` suite passed, `pkgdown::check_pkgdown()` reported no
problems, `git diff --check` was clean, and `devtools::check()` finished with 0
errors, 0 warnings, and 0 notes.

## Tests Of The Tests

The new q=2 test compares the fitted marginal objective against an independent
dense multivariate-normal likelihood calculation for the `relmat(Q = Q)` path.
It also checks covariance and precision equivalence through `K` versus `Q`,
both `animal()` and `relmat()` extractor labels, `corpairs()` rows,
`summary()$covariance`, direct profile-target names and TMB parameter indices,
and `check_drm()` q=2 diagnostic output.

## Consistency Audit

Rose scanned current status surfaces with:

```sh
rg -n 'univariate Gaussian `mu` only|bivariate relatedness covariance|bivariate covariance remain planned|corpair\(\) parity remain planned|first animal/`relmat\(\)` slice fits known-matrix Gaussian|bivariate covariance, and `corpair`' README.md NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md docs/dev-log/forgotten-promises-status-2026-05-20.md vignettes R tests
```

The remaining hits are either the historical `0.1.3` NEWS note, non-stale
generic wording about broader future structured covariance, or current
first-slice wording. I did not rewrite archival after-task records that were
true when written.

## GitHub Issue Maintenance

Issue #147, "Implement animal() and relmat() known-relatedness structured
effects", remains open and is still the right ledger. This slice satisfies the
known-matrix univariate and matching bivariate q=2 pieces, but does not close
pedigree construction, structured slopes, `sigma`, q=4 location-scale blocks,
predictor-dependent `corpair()` regression, examples, or generic direct-SD
grammar.

## What Did Not Go Smoothly

The first stale-wording scan had a shell-quoting mistake around backticks in an
`rg` pattern. I reran the scan with safer quoting and recorded the exact final
pattern in the check log.

## Team Learning

- Ada: after a release tag, start parity with the smallest fitted covariance
  slice that can be independently checked against a dense likelihood.
- Boole: matching labels are the right grammar gate for bivariate known-matrix
  terms; direct-SD naming still needs a separate generic design.
- Gauss and Noether: the shared known precision path keeps the model contract
  close to phylogenetic and spatial q=2 without adding a new TMB likelihood
  family.
- Curie and Fisher: extractor/profile/diagnostic evidence matters as much as
  convergence for claiming parity.
- Grace: full `devtools::check()` is affordable enough here to keep as the
  closeout gate for this slice.
- Pat and Darwin: the public docs should say exactly which relatedness input a
  reader already has to provide.
- Rose: historical release notes can stay historical; current status surfaces
  need the post-release truth.

These were role perspectives, not spawned agents.

## Known Limitations

This is not full animal/`relmat()` parity. Pedigree-to-Ainv construction,
structured slopes, `sigma` relatedness models, q=4 location-scale blocks,
predictor-dependent relatedness `corpair()` regression, generic direct-SD
grammar, runnable gallery examples, and ADEMP admission for bivariate grids
remain planned.

## Next Actions

1. Open the small runnable example slice for precomputed animal/`relmat()`
   matrices, covering one-response `mu` and q=2 bivariate covariance.
2. Decide the next fitted parity lane: pedigree-to-Ainv, structured slopes, or
   q=4 location-scale blocks.
3. Keep issue #147 open until the planned boundaries above have code, tests,
   docs, examples, and simulation evidence.
