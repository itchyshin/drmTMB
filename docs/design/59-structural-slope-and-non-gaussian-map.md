# Structural Slopes And Non-Gaussian Dependence Map

This note answers two user-facing status questions after the post-0.1.3
structural-parity slices:

1. Do all random-effect types have at least one fitted random-slope route?
2. Does structural dependence work in non-Gaussian settings?

The short answers are closer now, but still bounded. `drmTMB` has at least one
fitted random-slope route for ordinary Gaussian `mu`, ordinary Gaussian
`sigma`, the first ordinary bivariate Gaussian slope-only `mu1`/`mu2`
covariance route, coordinate spatial Gaussian `mu`, phylogenetic Gaussian
`mu`, animal-model Gaussian `mu`, `relmat()` Gaussian `mu`, and ordinary
Poisson/NB2 `mu`. Broader bivariate random slopes and most structured
non-Gaussian dependence remain planned. The only fitted structured
non-Gaussian route is the first ordinary Poisson q=1 phylogenetic `mu`
intercept; it is smoke-level, not broad count parity.

## Random-Slope Parity

| Random-effect layer | At least one fitted random slope? | Fitted route | Still planned or blocked |
| --- | --- | --- | --- |
| Ordinary Gaussian `mu` group effects | Yes | Independent numeric slopes such as `(0 + x | id)` and one correlated intercept-slope block such as `(1 + x | id)`; q > 2 ordinary `mu` blocks are fitted but advanced | Bivariate slope1-slope2 covariance and broader cross-parameter slope covariance |
| Ordinary Gaussian `sigma` group effects | Yes | Independent residual-scale slopes such as `sigma ~ z + (0 + w | id)` on the log-`sigma` predictor | Correlated residual-scale slope blocks and labelled `mu`/`sigma` slope covariance |
| Ordinary bivariate group covariance | Yes, first slice | Matching labelled random intercepts in `mu1`/`mu2`, `sigma1`/`sigma2`, constant q=4 intercept location-scale blocks, and matching slope-only `mu1`/`mu2` blocks are fitted | Intercept-plus-slope q=4 bivariate location blocks, residual-scale slope covariance, all-four p8/q8 slope location-scale blocks, and predictor-dependent slope `corpair()` regressions |
| Coordinate spatial Gaussian `mu` | Yes | `spatial(1 + x | site, coords = coords)` fits independent coordinate-spatial intercept and slope fields for univariate Gaussian `mu` | Multiple spatial slopes, spatial intercept-slope correlation, bivariate spatial slopes, spatial `sigma`, mesh/SPDE |
| Phylogenetic Gaussian effects | Yes | `phylo(1 + x | species, tree = tree)` fits independent phylogenetic intercept and slope fields for univariate Gaussian `mu`; intercept-only `mu`, matching bivariate `mu1`/`mu2`, selected q=4 location-scale, direct `sd_phylo*()`, and q=2 phylogenetic `corpair()` routes are also fitted | Multiple phylogenetic slopes, phylogenetic slope correlations, bivariate phylogenetic slopes, and phylogenetic non-Gaussian effects |
| `animal()` Gaussian effects | Yes | `animal(1 + x | id, pedigree/A/Ainv = ...)` fits independent animal-model intercept and slope fields for univariate Gaussian `mu`; matching bivariate q=2 location covariance and constant all-four q=4 location-scale blocks are fitted | Sparse large-pedigree construction, multiple animal slopes, animal slope correlations, standalone scale models, predictor-dependent `corpair()`, direct-SD grammar |
| `relmat()` Gaussian effects | Yes | `relmat(1 + x | id, K/Q = ...)` fits independent relatedness intercept and slope fields for univariate Gaussian `mu`; matching bivariate q=2 location covariance and constant all-four q=4 location-scale blocks are fitted | Multiple `relmat()` slopes, slope correlations, standalone scale models, predictor-dependent `corpair()`, direct-SD grammar |
| Ordinary Poisson `mu` group effects | Yes, first slice | Non-zero-inflated Poisson `mu` random intercepts and independent numeric slopes on the log-mean predictor; `phylo(1 | species, tree = tree)` fits the first q=1 structured log-mean intercept | Correlated Poisson slopes, labelled covariance blocks, zero-inflated Poisson random effects, Poisson structured slopes, and spatial/animal/`relmat()` count structure |
| Ordinary NB2 `mu` group effects | Yes, first slice | Non-zero-inflated NB2 `mu` random intercepts and independent numeric slopes on the log-mean predictor | Correlated NB2 slopes, NB2 `sigma` random effects, zero-inflated NB2 random effects, structured NB2 effects |
| `sd(group)` random-effect SD models | No slope-specific SD route | Fitted for unlabelled Gaussian `mu` random-intercept SD surfaces such as `sd(id) ~ x_group` | Coefficient-specific random-slope SD formulas such as `sd(id, coef = "x") ~ ...` |
| Meta-analysis known `V` | Not a random-slope layer | `meta_V(V = V)` treats sampling covariance as known input data | Variance-component meta-analysis and phylogenetic-plus-study extensions |

The practical consequence is that the first structured one-slope parity gap is
closed for univariate Gaussian `mu`, and the first ordinary bivariate
slope-slope gap is now opened for matching `mu1`/`mu2` slopes. The next slope
gaps are intercept-plus-slope bivariate covariance, all-four p8/q8
location-scale covariance, multiple structured slopes, structured slope
correlations, and non-Gaussian structured effects.

## Non-Gaussian Structural Dependence

| Non-Gaussian surface | Implemented now? | What is fitted | What is not fitted |
| --- | --- | --- | --- |
| Fixed-effect non-Gaussian families | Yes | Poisson, NB2, zero-inflated counts, truncated/hurdle NB2, beta, beta-binomial, Gamma, lognormal, Student-t, and fixed-effect ordinal routes where listed in the family registry | This does not imply random effects or structural dependence |
| Ordinary Poisson mixed models | Yes, first slice | Non-zero-inflated `mu` random intercepts, independent numeric `mu` slopes, and q=1 `phylo(1 | species, tree = tree)` log-mean intercepts | `zi` random effects, correlated slopes, labelled covariance, phylogenetic slopes, and spatial/animal/relmat count structure |
| Ordinary NB2 mixed models | Yes, first slice | Non-zero-inflated `mu` random intercepts and independent numeric `mu` slopes, with fixed-effect `sigma` | NB2 `sigma` random effects, zero-inflation random effects, correlated slopes, structured dependence |
| Non-Gaussian `sigma`, shape, inflation, hurdle, zero-one, or one-inflation random effects | No | Fixed-effect formulas exist for selected families and parameters | Random effects in these distributional parameters are blocked or planned |
| Ordinal mixed models | No | Fixed-effect cumulative-logit ordinal location | Ordinal random effects, ordinal scale/discrimination, structured ordinal effects |
| Structured non-Gaussian dependence | First Poisson slice only | Ordinary Poisson fits `phylo(1 | species, tree = tree)` in `mu`, with `sdpars`, `ranef("phylo_mu")`, `profile_targets()`, and `check_drm()` evidence | NB2 phylogeny, zero-inflated phylogeny, phylogenetic count slopes, and all spatial/animal/`relmat()` non-Gaussian routes remain planned until matrix diagnostics, extractors, profile targets, and recovery tests exist |
| Mixed-response bivariate non-Gaussian models | No | All-Gaussian bivariate models are fitted | Gaussian-count, count-count, ordinal-mixed, and other mixed-response bivariate likelihoods remain planned |

For applied users, the current route is therefore:

- use Gaussian structural dependence when the response model is Gaussian and
  the fitted structured layer matches the question;
- use ordinary Poisson or NB2 `mu` random effects for count mixed models when
  a plain grouping factor is enough;
- use ordinary Poisson `phylo(1 | species, tree = tree)` only when the count
  question is a q=1 phylogenetic log-mean intercept;
- do not fit NB2, zero-inflated, spatial, animal, or `relmat()` structured
  non-Gaussian models yet.

That boundary is conservative, but useful. Non-Gaussian links, latent
structured matrices, zero inflation, and distributional scale or shape
parameters can all change identifiability. The package should not advertise
non-Gaussian structural dependence beyond the Poisson q=1 phylogenetic smoke
route until it has the same evidence standard as the Gaussian routes:
likelihood code, focused recovery tests, extractors, diagnostics,
interval-status rows, examples, check-log evidence, and an after-task report.
