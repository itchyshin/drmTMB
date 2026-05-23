# Large-Data Memory Strategy

## Purpose

`drmTMB` should be able to grow toward large ecology, evolution, and
environmental-science datasets: thousands to tens of thousands of species and
millions of observations. For those models, the main bottleneck is often not
the sparse phylogenetic precision matrix. The main bottleneck is duplicated
R-side data, dense model matrices, and large prediction/report objects.

The first target scenario is a univariate Gaussian phylogenetic location model
with about 10,000 species and millions of observation rows:

```r
drmTMB(
  drm_formula(
    y ~ x1 + x2 + phylo(1 | species, tree = tree),
    sigma ~ 1
  ),
  family = gaussian(),
  data = dat
)
```

The phylogenetic random-effect dimension is about the number of species. With
the augmented sparse A-inverse path, that part is feasible. The observation
likelihood still loops over every row, and R can easily create several copies
of 5 million-row objects before TMB starts optimizing.

## Design Principles

1. Never build dense phylogenetic covariance matrices for production large
   models. Use sparse precision forms from ultrametric branch-length trees.
2. Avoid storing full data frames, model frames, or redundant model matrices in
   fitted objects when the user requests a memory-light fit.
3. Keep fixed-effect design matrices sparse when their structure is sparse.
4. Use aggregation and likelihood weights when repeated rows can be collapsed
   without changing the statistical model.
5. Avoid automatic prediction, residual, and report objects at the full
   observation scale unless the user asks for them.
6. Benchmark scale-up explicitly; do not infer million-row performance from
   small simulation tests.
7. Treat dense known sampling covariance as a small-to-moderate path until
   sparse or block-sparse `V` storage has direct implementation and benchmark
   evidence.

## User Controls

The first public control is conservative and explicit. Users can keep ordinary
optimizer settings and fitted-object storage settings in one place:

```r
fit <- drmTMB(
  drm_formula(
    y ~ x1 + x2 + phylo(1 | species, tree = tree),
    sigma ~ 1
  ),
  family = gaussian(),
  data = dat,
  control = drm_control(
    se = FALSE,
    keep_data = FALSE,
    keep_model_frame = FALSE,
    keep_tmb_object = FALSE,
    optimizer = list(eval.max = 1000)
  )
)
```

The implemented first slice means:

- `se = FALSE`: skip `TMB::sdreport()` after optimization. The fit keeps
  coefficients, fitted values, residuals, prediction, simulation,
  log-likelihood, and profile-likelihood routes that only need `fit$obj`, but
  `vcov()`, Wald standard errors, and Wald confidence intervals are
  unavailable. `summary()` reports `NA` standard errors with
  `std_error.status = "sdreport_skipped"`, and `check_drm()` records the
  `sdreport_status`, Hessian, and standard-error rows as notes rather than
  warnings;
- `keep_data = FALSE`: do not store the full input data frame in the fit;
- `keep_model_frame = FALSE`: do not store model frames in the fit after TMB
  data has been built. Fitted-row prediction, new-data prediction, residuals,
  simulation, response names, and diagnostics use stored matrices, terms,
  offsets, response vectors, response-name metadata, random-effect scale
  metadata, correlation-regression design matrices, and diagnostic state;
- `keep_tmb_object = FALSE`: do not retain the TMB
  automatic-differentiation object after optimization; `check_drm()` then
  reports the fixed-gradient check as a note rather than re-evaluating it;
- `optimizer = list(...)`: pass optimizer controls to `stats::nlminb()`.

The first sparse fixed-effect fit path is also explicit and narrow:

```r
drmTMB(
  bf(y ~ habitat + x1, sigma ~ 1),
  family = gaussian(),
  data = dat,
  control = drm_control(sparse_fixed = TRUE)
)
```

This stores the univariate Gaussian `mu` design as a `Matrix` sparse matrix and
uses a sparse TMB multiply for the location predictor. It currently requires a
fixed-effect Gaussian location model with intercept-only `sigma`; random
effects, direct-SD models, phylogenetic/spatial effects, known covariance,
non-Gaussian families, bivariate models, and sparse scale formulas remain
planned.

Known sampling covariance is a separate memory concern. Diagonal
`meta_V(V = vi)` inputs stay vector-like, but a full-matrix
`meta_V(V = V)` fit stores the retained `V` as a dense R matrix.
`check_drm()` reports that dense storage as a note with dimension, density,
size, rank, and conditioning. Low density in that row is a design signal for a
future sparse or block-sparse known-covariance path, not a current scalability
claim.

## Model-Frame Dependency Map

The `keep_model_frame = FALSE` storage path is a method-dependency change, not
a bulk deletion of `model$model_frame`.
The fitted object already stores the model matrices, terms, offsets, response
vectors, known covariance objects, and random-effect structures needed by most
post-fit methods.

| Surface | Main Stored Inputs | Model-Frame Role | Safe Before Dropping? |
| --- | --- | --- | --- |
| `predict(fit)` | `model$X`, `coefficients`, stored offsets, random-effect contributions | None for fitted rows | Yes, with tests. |
| `predict(fit, newdata = ...)` | `model$terms`, `coefficients`, `newdata` | None; offsets are recomputed from `newdata` with `model.frame()` | Yes, with offset tests. |
| `fitted(fit)` | `predict()`, family-specific response summaries | None beyond `predict()` | Yes, with family smoke tests. |
| `residuals(fit)` | stored response vectors, `predict()`, known covariance, trials for beta-binomial | None when response vectors remain stored | Yes, unless a later control drops responses too. |
| `simulate(fit)` | `predict()`, stored trials, ordinal levels, known covariance | None for current fitted-row simulation | Yes, with family smoke tests. |
| `sigma(fit)` and `rho12(fit)` | `predict()` | None | Yes. |
| `corpairs(fit)` | fitted correlations, `predict()`, response-name metadata | Previously used `model_frame`; now should prefer stored response names | Yes, once response-name fallback tests pass. |
| `check_drm(fit)` | optimizer result, `sdr`, `obj`, stored row filter, `sigma()`, `rho12()`, known covariance, random structures | None for current checks | Yes, except fixed-gradient already needs `obj`. |
| Printing and summaries | coefficients, `vcov()` when `se = TRUE`, log-likelihood, random-effect summaries, uncertainty state | None | Yes; `se = FALSE` reports unavailable standard errors explicitly. |

The implemented storage path stores response names separately from model frames
and updates response-label extractors to prefer that metadata. It then drops
top-level model frames after fitting when requested. Regression tests currently
cover Gaussian, Poisson offset prediction, beta-binomial trial storage,
cumulative-logit ordinal metadata, and bivariate Gaussian two-response output
after model frames are removed.

The Phase 5b storage hardening extends that deletion to the nested model-frame
caches created by direct random-effect SD models and latent-correlation
regression models. In practice, `keep_model_frame = FALSE` now removes
`sd(group)`, the current implemented phylogenetic direct-SD spellings
`sd_phylo(group)`, `sd_phylo1(group)`, `sd_phylo2(group)`, and fitted q=2
`corpair()` model-frame caches after their model matrices and group metadata
have been stored. These phylogenetic names are transitional public syntax, not
a naming pattern to copy as `sd_spatial*()`, `sd_animal*()`, or
`sd_relmat*()` when those direct-SD routes are designed. Tests cover an
`sd_phylo(species) ~ z_species` fit and an ordinary q=2
`corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ ecology`
fit with all memory-light flags enabled.

The standard-error control is separate from object storage. `se = FALSE` saves
the post-optimization `sdreport()` step and avoids storing its covariance
matrix, but it does not remove the TMB automatic-differentiation object unless
`keep_tmb_object = FALSE` is also supplied. If `sdreport()` is requested and
fails, `drmTMB()` still returns the optimized fit with
`fit$uncertainty$status = "failed"`; standard-error methods then fail clearly
instead of making the fit object unusable.

## Aggregation Path

For Gaussian location models, repeated rows can sometimes be collapsed. If a
set of observations has the same fixed-effect row, offset state, and
distributional-parameter row, the likelihood can be rewritten using sufficient
summaries. This is separate from sparse fixed-effect matrices: sparse matrices
reduce column-storage pressure, while aggregation reduces repeated-row
likelihood pressure.

For the simplest Gaussian case:

```text
y_i ~ N(mu_g, sigma^2), i in group g
```

the contribution can be represented by:

```text
n_g
sum_y_g
sum_y2_g
```

instead of all individual `y_i` values. This is more powerful than ordinary
`weights = n_g` when the within-group squared residual term matters. Ordinary
likelihood weights are still useful when one row is intended to represent
multiple identical observations, but sufficient-statistic aggregation is the
stronger special-case optimization.

`docs/design/31-gaussian-aggregation-sufficient-statistics.md` records the
aggregation contract, and `drm_control(aggregate_gaussian = TRUE)` now fits
the first opt-in univariate Gaussian fixed-effect path. Random effects,
direct-SD formulas, phylogenetic and spatial structured effects, known
sampling covariance, bivariate Gaussian models, non-Gaussian families,
non-unit likelihood weights, and combined sparse fixed-effect matrices still
error before optimization.

The first fitted path keeps original-row model matrices and response vectors
inside the fitted object while TMB receives aggregation cells for likelihood
evaluation. This means `predict(fit)`, `fitted(fit)`, and `residuals(fit)`
still return original-row outputs, even when data/model-frame/TMB-object
storage is dropped after optimization.

## Sparse Design Matrices

Large fixed-effect designs can become memory-heavy when factors are expanded
with dense `model.matrix()`. The first sparse path uses
`Matrix::sparse.model.matrix()` and passes the univariate Gaussian `mu` design
to TMB as a sparse matrix when `drm_control(sparse_fixed = TRUE)` is used.

Next sparse targets:

- large factor fixed effects;
- interaction terms with many empty combinations;
- model matrices for repeated ecological survey designs;
- bivariate models where both responses share many predictors.

The sparse path should have dense-versus-sparse parity tests on small datasets
before it is used for large fits.

See `docs/design/26-sparse-fixed-effect-matrices.md` for the proposed sparse
fixed-effect matrix contract.

## TMB-Side Computation

The C++ likelihood should avoid storing per-row intermediate vectors when a
loop can accumulate the objective directly. For very large independent-row
likelihoods, later phases can consider TMB's parallel accumulation tools to
reduce wall time.

Parallel likelihood accumulation improves runtime more than memory. It should
come after the memory-light R data path, because parallel workers can increase
temporary memory use if the data are copied or if large reports are built.

## Benchmark Plan

The repository includes a non-CRAN benchmark script, not a unit test:

```text
bench/large-phylo-location.R
```

The script generates synthetic data and records elapsed time, fitted-object
size, model-matrix size, TMB-data size, prediction time, residual time,
convergence code, optimizer diagnostics, package versions, Git state, the
reconstructed benchmark command, and fitted scale summaries. It accepts
command-line options for:

- 1,000, 5,000, and 10,000 species through `--species`;
- 100,000, 500,000, 1,000,000, and 5,000,000 rows through `--rows`;
- few fixed effects first, then factor-heavy fixed effects through
  `--factor-heavy`;
- the default phylogenetic route, or the first non-phylogenetic sparse
  fixed-effect route through `--structured none --sparse-fixed true`;
- `sigma ~ 1` first, then `sigma ~ x` through `--sigma-x`;
- intercept-only `phylo(1 | species, tree = tree)`.

For peak resident memory, run the script through an external operating-system
tool such as `/usr/bin/time -l` on macOS. Base R does not expose a portable
cross-platform peak-memory measure.

## Open Questions

- Should memory-light fits disable `residuals()` when both stored data and the
  stored response vector are absent?
- Should `predict()` ever require `newdata` for future storage modes that drop
  response vectors, offsets, or design matrices, rather than only stored model
  frames?
- Should weighted sufficient-statistic aggregation use the current
  `aggregate_gaussian` control with a second weight contract, or should it
  become a separate opt-in because weighted cells are easier to misuse?
- `weights =` is now an ordinary likelihood multiplier. Aggregation should
  still have a separate Gaussian-only sufficient-statistics path when the
  within-cell squared residual term matters.
