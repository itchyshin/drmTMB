# Structural Parity Slices 39-82

This ledger records the post-0.1.3 continuation after the first 38 structural
parity slices. The user-facing question is whether these changes help an
applied ecology or evolution user fit the model they meant to fit, while still
making unsupported neighbouring syntax obvious.

## Active Roles

Ada coordinates the code, tests, docs, and release ledger. Boole watches the
formula grammar. Gauss and Noether keep the likelihood and equations aligned:
the fitted one-slope paths are independent structured fields, not correlated
intercept-slope covariance blocks. Curie owns the focused recovery tests.
Fisher keeps Phase 18 admission limited to fitted surfaces. Pat asks whether a
new user can find the right route and interpret the SD names. Grace watches
pkgdown, documentation, and check readiness. Rose records stale-status and
team-learning risks. Darwin keeps the examples tied to biological questions
such as phylogenetic plasticity and additive genetic variation.

## Slice Table

| Slice | Lane | Status | User-facing result |
| --- | --- | --- | --- |
| 39 | Phylogenetic one-slope implementation | Completed | `phylo(1 + x | species, tree = tree)` fits univariate Gaussian `mu` as independent intercept and slope fields. |
| 40 | Phylogenetic one-slope extractors | Completed | `sdpars$mu`, `ranef("phylo_mu")`, and `profile_targets()` expose `phylo(1 | species)` and `phylo(0 + x | species)`. |
| 41 | Phylogenetic diagnostics | Completed | `check_drm()` adds `phylo_mu_diagnostics` with replication, SD, and SD-ratio text. |
| 42 | Phylogenetic recovery test | Completed | Focused test checks convergence, SD names, profile targets, prediction contribution, and diagnostics. |
| 43 | Animal one-slope implementation | Completed | `animal(1 + x | id, pedigree/A/Ainv = ...)` fits univariate Gaussian `mu` as independent intercept and slope fields. |
| 44 | `relmat()` one-slope implementation | Completed | `relmat(1 + x | id, K/Q = ...)` fits univariate Gaussian `mu` as independent intercept and slope fields. |
| 45 | Animal/relmat extractors and diagnostics | Completed | `sdpars$mu`, `ranef("animal_mu")`, `ranef("relmat_mu")`, `profile_targets()`, and `check_drm()` expose the fitted slope SDs. |
| 46 | Animal/relmat recovery tests | Completed | Focused tests check convergence, SD names, no slope correlation claim, direct profile targets, and diagnostics. |
| 47 | Formula grammar refresh | Completed | The formula grammar now marks the one-slope phylo, animal, and `relmat()` Gaussian `mu` routes as fitted. |
| 48 | Likelihood contract refresh | Completed | The documented equation keeps intercept and slope fields independent in the first structured-slope path. |
| 49 | Structured-slope parity gate refresh | Completed | The parity gate now says the first univariate Gaussian structured one-slope gap is closed. |
| 50 | Simulation readiness refresh | Completed | Phase 18 admits focused one-slope smoke cells for phylo, animal, and `relmat()` instead of leaving them in the failure ledger. |
| 51 | Spatial sibling consistency | Completed | Spatial remains the same fitted one-slope sibling, with multiple slopes and slope correlations still planned. |
| 52 | Phylo sibling consistency | Completed | Phylo now matches the spatial one-slope contract for univariate Gaussian `mu`. |
| 53 | Animal sibling consistency | Completed | Animal-model slopes are no longer described as parser-only; large sparse pedigrees remain planned. |
| 54 | Relmat sibling consistency | Completed | `relmat()` slopes are no longer described as parser-only; slope correlations remain planned. |
| 55 | Random-slope parity map refresh | Completed | The map now shows at least one fitted random-slope route for ordinary Gaussian, spatial, phylo, animal, `relmat()`, Poisson, and NB2 `mu`. |
| 56 | Non-Gaussian boundary refresh | Completed | Ordinary Poisson/NB2 `mu` slopes remain fitted; structured non-Gaussian dependence remains planned. |
| 57 | Bivariate slope boundary | Completed as guardrail | Bivariate random slopes remain planned; no q4 or q8 slope covariance is claimed. |
| 58 | Structured non-Gaussian boundary | Completed as guardrail | `phylo()`, `spatial()`, `animal()`, and `relmat()` still do not fit non-Gaussian likelihoods. |
| 59 | Multiple structured slope boundary | Completed as guardrail | Parser and docs keep multiple structured slopes outside the fitted surface. |
| 60 | Structured slope-correlation boundary | Completed as guardrail | No `corpairs()` row is reported for univariate structured intercept-slope paths. |
| 61 | Direct-SD boundary | Completed as guardrail | `sd(..., level = "phylogenetic")` support remains separate from structured slopes; spatial, animal, and `relmat()` `sd*()` siblings remain a future direct-SD unification lane, not part of this implementation slice. |
| 62 | Meta-analysis boundary | Completed as guardrail | Known sampling covariance `meta_V(V = V)` remains separate from latent relatedness. |
| 63 | Ordinary Gaussian slope inventory | Completed | Existing ordinary Gaussian `mu` and `sigma` slope support is kept in the fitted column. |
| 64 | Count slope inventory | Completed | Existing Poisson and NB2 ordinary `mu` random intercept/slope support remains fitted and tested. |
| 65 | Count slope hardening check | Completed | Focused count and NB2 slope tests were rerun with the parity changes. |
| 66 | Bivariate slope policy | Completed as design gate | The first future bivariate target stays slope-only `mu1`/`mu2`, not a broad all-endpoint slope block. |
| 67 | Non-Gaussian structural policy | Completed as design gate | Structured count or ordinal effects wait for likelihood code, diagnostics, profile targets, and recovery tests. |
| 68 | User route wording | Completed | Applied users are directed to fitted Gaussian structured slopes or ordinary count slopes, not planned neighbours. |
| 69 | Stale claim scan | Completed | Current docs no longer say phylo, animal, or `relmat()` one-slope Gaussian `mu` paths are parser-only. |
| 70 | Snapshot cleanup | Completed | Old unsupported-slope snapshots were replaced with direct malformed-input assertions. |
| 71 | Package documentation source | Completed | `drmTMB()`, `phylo()`, `animal()`, `relmat()`, and `check_drm()` roxygen sources describe the fitted one-slope contract. |
| 72 | Rd regeneration | Completed | `devtools::document()` regenerated the matching Rd files before release. |
| 73 | pkgdown readiness | Completed | `pkgdown::check_pkgdown()` passed after documentation regeneration. |
| 74 | Focused structural tests | Completed locally | `phylo-gaussian`, `animal-relmat-gaussian`, and broader Gaussian/count slope filters passed after fixes. |
| 75 | Release-safety scan | Completed | `git diff --check` passed and the stale-status scan found no old planned-only claim except intentional multiple-slope boundaries. |
| 76 | After-task protocol | Completed | Check-log and after-task notes record the implementation and validation evidence. |
| 77 | Non-Gaussian slope evidence | Completed as inventory | Existing Poisson/NB2 ordinary `mu` slope tests remain the fitted non-Gaussian random-slope evidence. |
| 78 | Non-Gaussian structural honesty | Completed as guardrail | No structured non-Gaussian support is claimed before slice 83+. |
| 79 | Bivariate slope honesty | Completed as guardrail | Bivariate slope support remains a future implementation lane. |
| 80 | Member growth loop | Completed | The roles learned to promote a planned path only after code, diagnostics, tests, docs, and user value align. |
| 81 | User usefulness check | Completed | The first new fitted value is practical: phylogenetic plasticity, additive genetic plasticity, and relatedness-driven plasticity can now be modelled for Gaussian `mu`. |
| 82 | Handoff boundary | Completed | Next work should start from bivariate slope-only covariance or non-Gaussian structured dependence, not from redoing the one-slope Gaussian parity closure. |

## Current Boundary

The fitted claim is intentionally narrow:

```r
phylo(1 + x | species, tree = tree)
animal(1 + x | id, pedigree = ped)
animal(1 + x | id, A = A)
animal(1 + x | id, Ainv = Ainv)
relmat(1 + x | id, K = K)
relmat(1 + x | id, Q = Q)
```

These are univariate Gaussian `mu` models with independent intercept and slope
fields. They do not add intercept-slope correlations, bivariate random slopes,
multiple structured slopes, structured `sigma` effects, structured `rho12`, or
non-Gaussian structured dependence.
