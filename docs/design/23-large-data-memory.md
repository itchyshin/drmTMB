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
    keep_data = FALSE,
    keep_tmb_object = FALSE,
    optimizer = list(eval.max = 1000)
  )
)
```

The implemented first slice means:

- `keep_data = FALSE`: do not store the full input data frame in the fit;
- `keep_tmb_object = FALSE`: do not retain the TMB
  automatic-differentiation object after optimization; `check_drm()` then
  reports the fixed-gradient check as a note rather than re-evaluating it;
- `optimizer = list(...)`: pass optimizer controls to `stats::nlminb()`.

Two larger memory controls remain planned rather than implemented:

- `keep_model_frame = FALSE`: do not store the full model frame after TMB data
  has been built. This needs method fallbacks for prediction, offsets, response
  names, residuals, and user-facing diagnostics before it is safe;
- sparse fixed-effect matrices: use sparse design matrices when factors or
  high-dimensional terms would make dense matrices costly.

## Model-Frame Dependency Map

The next storage target is `keep_model_frame = FALSE`. This should be designed
as a method-dependency change, not as a bulk deletion of `model$model_frame`.
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
| Printing and summaries | coefficients, `vcov()`, log-likelihood, random-effect summaries | None | Yes. |

The first low-risk implementation step is to store response names separately
from model frames, then update response-label extractors to prefer that
metadata. After that, a guarded `keep_model_frame = FALSE` implementation can
drop only `model$model_frame` and run a family matrix of `predict()`,
`fitted()`, `residuals()`, `simulate()`, `sigma()`, `rho12()`, `corpairs()`,
and `check_drm()` tests.

## Aggregation Path

For Gaussian location models, repeated rows can sometimes be collapsed. If a
set of observations has the same species, same known covariance status, same
fixed-effect row, and same distributional-parameter row, the likelihood can be
rewritten using sufficient summaries.

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

This path should be added only after the ordinary row-likelihood path is
tested, because it changes internal data representation and needs independent
likelihood-comparison tests.

## Sparse Design Matrices

Large fixed-effect designs can become memory-heavy when factors are expanded
with dense `model.matrix()`. A future sparse path should use
`Matrix::sparse.model.matrix()` and pass sparse matrices to TMB where possible.

Candidate first targets:

- large factor fixed effects;
- interaction terms with many empty combinations;
- model matrices for repeated ecological survey designs;
- bivariate models where both responses share many predictors.

The sparse path should have dense-versus-sparse parity tests on small datasets
before it is used for large fits.

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
convergence code, and fitted scale summaries. It accepts command-line options
for:

- 1,000, 5,000, and 10,000 species through `--species`;
- 100,000, 500,000, 1,000,000, and 5,000,000 rows through `--rows`;
- few fixed effects first, then factor-heavy fixed effects through
  `--factor-heavy`;
- `sigma ~ 1` first, then `sigma ~ x` through `--sigma-x`;
- intercept-only `phylo(1 | species, tree = tree)`.

For peak resident memory, run the script through an external operating-system
tool such as `/usr/bin/time -l` on macOS. Base R does not expose a portable
cross-platform peak-memory measure.

## Open Questions

- Should memory-light fits disable `residuals()` when both stored data and the
  stored response vector are absent?
- Should `predict()` default to requiring `newdata` when a later
  `keep_model_frame = FALSE` path is implemented?
- Should sufficient-statistic aggregation be automatic or require an explicit
  argument such as `aggregate = TRUE`?
- `weights =` is now an ordinary likelihood multiplier. Aggregation should
  still have a separate Gaussian-only sufficient-statistics path when the
  within-cell squared residual term matters.
