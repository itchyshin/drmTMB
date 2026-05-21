# After-Task Report: Structural Parity Slices 39-82

Date: 2026-05-21

## Task

Continue the post-0.1.3 structural-dependence parity lane through Slice 82,
keeping fitted-versus-planned claims honest and putting applied users first.

## Result

The first structured one-slope parity gap is closed for univariate Gaussian
`mu`. `drmTMB()` now fits:

```r
phylo(1 + x | species, tree = tree)
animal(1 + x | id, pedigree = ped)
animal(1 + x | id, A = A)
animal(1 + x | id, Ainv = Ainv)
relmat(1 + x | id, K = K)
relmat(1 + x | id, Q = Q)
```

Each path estimates independent intercept and slope fields with the same
structured precision and separate SDs. The implementation does not add
intercept-slope correlations, bivariate structured slopes, multiple structured
slopes, coefficient-specific `sd_phylo()` overlays, spatial/animal/relmat
`sd*()` direct-SD siblings in this slice, structured `sigma`, structured
`rho12`, or non-Gaussian structured dependence. The `sd*()` direct-SD direction
remains a future unification lane rather than a removed or rejected grammar.

## Evidence

Focused tests passed:

```sh
Rscript -e "devtools::test(filter = 'phylo-gaussian', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'gaussian-location-scale|nbinom2-location-scale|poisson-mean', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'profile-targets|check-drm|spatial-gaussian', reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::test(reporter = 'summary')"
git diff --check
```

`devtools::document()` regenerated the Rd files for the touched user-facing
surfaces. The stale-status scan no longer found old planned-only claims for the
first one-slope phylo, animal, or `relmat()` Gaussian `mu` paths. The final
full test suite passed after documentation regeneration and the clarified
`sd*()` boundary wording.

## User Usefulness

Applied users can now ask whether related species, related animals, or known
relatedness groups vary not only in baseline mean response but also in one
numeric response slope. This is useful for phylogenetic plasticity, additive
genetic plasticity, and relatedness-structured plasticity questions. The output
uses ordinary surfaces users already inspect: `sdpars$mu`, `ranef()`,
`profile_targets()`, and `check_drm()`.

## Standing Roles

Ada integrated code, docs, tests, and the slice ledger. Boole checked that the
syntax stayed consistent with the structured-marker grammar. Gauss and Noether
kept the fitted claim to independent intercept and slope fields. Curie added
the focused recovery tests. Fisher kept simulation admission narrow. Pat kept
the user-facing route concrete. Grace verified documentation, pkgdown, and
release readiness. Rose caught stale planned-only wording and recorded the
boundary. Darwin kept the biological value centered on plasticity questions.

## Remaining Boundaries

The next lanes are not completed by this task:

- bivariate random slopes;
- bivariate structured slope covariance;
- multiple structured slopes;
- structured slope correlations;
- spatial, animal, and `relmat()` `sd*()` direct-SD siblings;
- non-Gaussian `phylo()`, `spatial()`, `animal()`, or `relmat()` effects;
- structured `sigma` and structured `rho12`.

Those should start from the Slice 82 handoff boundary in
`docs/design/60-structural-parity-slices-39-82.md`.
