# Same-target REML receipt: `gaussian_phylo_mean`

Cell: `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)`, `gaussian()`,
`REML = TRUE`. drmTMB #1142 / DRM.jl #624 item (c). docs/design/261 row
`gaussian_phylo_mean`.

Reader: someone deciding whether `engine = "julia"` can be trusted to fit this
cell by restricted maximum likelihood in place of native TMB. The short answer
is yes for the estimates and the restricted log-likelihood, with one standard
error convention difference that is quantified below rather than smoothed over.

## Builds

- drmTMB: worktree `/Users/z3437171/local-scratch/parity-joint/wt-reml-phylo-mean`,
  branch `claude/parity-reml-phylo-mean`, off `origin/main` `80252238467b11991b0214a7ba9ea68ca302ff91`,
  loaded with `devtools::load_all()` (never `library(drmTMB)`).
- DRM.jl: worktree `/Users/z3437171/local-scratch/parity-joint/wt-reml-phylo-mean-drmjl`,
  branch `claude/parity-reml-phylo-mean-drmjl`, commit
  `3e77aa7eb` (see the PR head for the full sha) (off DRM.jl `origin/main`
  `292067b0f`).
- Environment for every `engine = "julia"` run: `OPENBLAS_NUM_THREADS=1`,
  `JULIA_NUM_THREADS=1`, `DRMTMB_JULIA_TESTS=true`, `DRM_JL_PATH` and
  `DRM_JL_PHYLO_PATH` both pointing at the DRM.jl worktree above. Julia 1.10.0.
- Measured 2026-09-05. Every number below was produced in that run.

## Fixture

`reml_phylo_location_fixture(n_tip = 30, n_each = 3, seed = 7, true_sd_phylo = 0.6)`
from `tests/testthat/test-reml-phylo-location.R` -- the builder the existing
phylo-mean REML suite already uses. n = 90 rows, 30 tips, 3 observations per
species; true mean `0.4 + 0.7 x`, true phylogenetic SD 0.6, true residual SD 0.5.
`tests/testthat/test-julia-reml-phylo-mean.R` repeats the same construction and
seed inline so the test file runs standalone.

## What each engine restricts, and on which convention

This matters more than the numbers, because a REML log-likelihood is only
comparable across engines if both integrate out the same set with the same
constant.

- **Native drmTMB (`engine = "tmb"`).** `drm_apply_estimator_spec()`
  (R/drmTMB.R) moves `beta_mu` into TMB's `random=` vector, next to the phylo
  field `u_phylo` that was already there. TMB's Laplace approximation over a
  negative log-density that is jointly quadratic in both is EXACT, so the
  objective is the Patterson-Thompson restricted likelihood, and the Laplace
  constant contributes `+0.5 * p_mu * log(2*pi)`. No REML-specific C++ exists in
  `src/drmTMB.cpp`; the estimator is realised entirely by reclassifying which
  parameters are integrated out.
- **DRM.jl (`method = :REML`).** `_fit_structured_gaussian_sparse_lbfgs`
  profiles `beta_mu` out EXACTLY by GLS at every `(log sigma_e, log sigma_phylo)`
  and adds `0.5 * logdet(Xmu' V^-1 Xmu) - 0.5 * p_mu * log(2*pi)` to the ML
  objective (`_loconly_reml_components`, src/location_only.jl).

Same integrated-out set `{u_phylo, beta_mu}`, same additive
`+0.5 * p_mu * log(2*pi)`. **There is no offset to remove**: the comparison
below is a direct one, not a comparison after subtracting a constant.

## Estimator honesty

Read off the fitted objects, not inferred from the absence of an error:

```
fit_tmb$estimator            "REML"
fit_julia$estimator          "REML"
fit_julia$bridge$estim_method "REML"     # DRM.jl's own report (#625 oracle)
fit_julia$effective_REML     TRUE
```

The bridge aborts if DRM.jl reports `ML` while drmTMB believed the cell
supported REML, so this is a checked claim rather than a label.

## Same-target numbers

Coefficient names are identical once the separator is normalised the way
`tools/parity_se.R` does (native `mu:(Intercept)` vs bridge `mu_(Intercept)`):
`mu_(Intercept) | mu_x | sigma_(Intercept)` on both engines.

| Quantity | engine = "tmb" | engine = "julia" | difference |
|---|---|---|---|
| logLik (REML) | -76.000977125761 | -76.000977125105 | 6.556604e-10 abs |
| logLik (ML, separate ML fits) | -73.759926588604 | -73.759926588164 | 4.40e-10 abs |
| `mu_(Intercept)` | 0.294399629899 | 0.294399628202 | 1.697e-09 abs |
| `mu_x` | 0.659142608214 | 0.659142609904 | 1.690e-09 abs |
| `sigma_(Intercept)` | -0.660244350880 | -0.660244313745 | 3.714e-08 abs |
| phylogenetic SD | 0.480176234530 | 0.480176374690 | 2.919e-07 rel |
| nobs | 90 | 90 | -- |
| df | 4 | 4 | -- |

Max scaled coefficient difference (absolute, or relative where `|value| > 1`):
**3.713560e-08**, against a 1e-4 bar. logLik difference **6.556604e-10**,
against a 1e-4 bar. Both pass.

DRM.jl also reports `ml_loglik = -73.856756070621`, the plain ML value at the
REML optimum (not a second maximisation), and `reml_loglik = -76.000977125105`.
The 2.14-unit gap between the REML and ML log-likelihoods is the restriction
doing real work: it is not an ML fit relabelled.

## Objective and gradient honesty

`fit$bridge$gradient` is ABSENT on the Julia REML fit and present on the Julia
ML fit of the same cell (max |gradient| there: `6.46e-06`). That is deliberate.
The route's analytic score belongs to the ML marginal; evaluated at the REML
optimum it is

```
mu_(Intercept)  -7.50e-15
mu_x            -3.30e-14
sigma_(Intercept) 1.01247
resd_species      0.987535
```

which reads as "not converged" for a fit that is converged. DRM.jl therefore
attaches the RESTRICTED objective to `fit.nll` on a REML fit and no
`fit.nllgrad`, so the bridge reports no gradient rather than a misleading one.
There is no analytic score for the log-determinant term on this sparse spine,
and passing off a finite-difference one as exact would be its own small lie.
This was a real defect found in the second (domain-expert) read of the change,
not a hypothetical: the numbers above were measured before the fix.

## Standard errors -- the one documented difference

| Coefficient | engine = "tmb" | engine = "julia" | relative gap |
|---|---|---|---|
| `mu_(Intercept)` | 0.322764663471 | 0.322749055566 | 4.835692e-05 |
| `mu_x` | 0.057873224739 | 0.057786358729 | 1.500971e-03 |
| `sigma_(Intercept)` | 0.081104007507 | 0.081103996010 | 1.417555e-07 |

Two of three are inside `tools/parity_se.R`'s 1e-3 relative bar; `mu_x` is at
**1.500971e-03**, past it. That is not a defect in either engine, and it is
recorded rather than tolerated away. The bar this leaf actually asserts and
defends for the mean block is not a bare cross-engine rtol-1e-3 match (which
`mu_x` does not meet): it is DRM.jl's agreement with an independent GLS oracle
at rtol ~5e-7, plus a cross-engine bound of rtol 2.5e-3 that a further
widening of the by-construction gap below would fail (both asserted in
`tests/testthat/test-julia-reml-phylo-mean.R`).

The cause was established with an independent oracle: the textbook REML
fixed-effect covariance `(Xmu' Vhat^-1 Xmu)^-1`, assembled by hand in R from
`ape::vcv(tree, corr = TRUE)` at the TMB fit's OWN variance estimates
(`sd_phylo = 0.480176234530`, residual SD from `exp(fit$par$sigma)`):

```
hand GLS SE:  (Intercept) = 0.322748964926     x = 0.057786356132
julia   SE :  rel diff 2.808e-07               rel diff 4.494e-08
tmb     SE :  rel diff 4.864e-05               rel diff 1.503e-03
```

DRM.jl reproduces the canonical REML covariance to 1e-7. drmTMB's REML SEs are
slightly LARGER because, under drmTMB's REML construction, `beta_mu` lives in
TMB's random set, and `sdreport` propagates variance-parameter uncertainty into
that block. Both are defensible conventions on the same fit; they differ by less
than 0.2% here. `tests/testthat/test-julia-reml-phylo-mean.R` asserts the strict
oracle agreement (rtol 1e-5) and bounds the cross-engine gap at 2.5e-3 so a
future widening is caught.

No interval-coverage claim is made or implied.

## Red controls

1. **Bridge gate reverted.** With `drm_julia_reml_phylo_mean_only()`'s admission
   forced off in `drm_julia_reml_supported()`, `test-julia-reml-phylo-mean.R`
   FAILS rather than skipping: `failed=1 skipped=0 passed=7 errors=1`, with the
   gate assertion failing (`Expected ... to be TRUE`) and the live fit erroring
   with the bridge's own refusal, `engine = "julia" cannot fit mean-only
   phylogenetic Gaussian models by REML = TRUE`. Restored byte-identically:
   `sha256(R/julia-bridge.R)` was
   `03c5948304a6a2e6dc4d45e6ae7beffcc76ac948032e941fb424edab43d1d315` before and
   after.
2. **DRM.jl change reverted.** With the DRM.jl worktree stashed back to
   `origin/main` content and the bridge gate left widened, the same
   `engine = "julia"` call fails with DRM.jl's own refusal --
   `ArgumentError: drm: method = :REML is not implemented for this model on the
   generic univariate Gaussian route (... a structured mean marker --
   phylo/relmat/animal/spatial -- without a matching sd() submodel ...)` raised
   at `src/gaussian_core.jl:672` -- proving the receipt above exercised the new
   DRM.jl code and not a pre-existing path. Restored byte-identically:
   `src/gaussian_core.jl` `816991b01a486f2c86bb37b49d052fd645285ab0a806b605bcb2d37c947bc280`,
   `src/location_only.jl` `8d97eb1491282b9df0ca39465dccfc57ec540c0ab6c959a9ae94e7c7213818c9`,
   `test/runtests.jl` `7f7273419e843fbae21d66e2f04c4ae78b6577a11eaafd6b8591a75de60d14ba`,
   `test/test_reml_reml_phylo_mean.jl` `18b5a561e6a4c60cb473e1b4379a1607b68db7360a4bed4578a6be6cb6aa602a`,
   before and after.

## ML is untouched

DRM.jl's ML path for this route was not modified. On DRM.jl's own seeded Julia
fixture (`test/test_reml_reml_phylo_mean.jl`, `random_balanced_tree(16)`, seed
20260905), the ML log-likelihood is `-61.46784165162242` both before and after
the change; the test pins that literal. Through the bridge on the R fixture,
`engine = "julia"` ML gives `-73.759926588164` against native TMB's
`-73.759926588604`, unchanged by this work.

## docs/design/261 row

Re-measured on the row's own probe fixture (`native_reml_probe.R` row 6 /
`bridge_reml_probe.R` row 3 construction: `ape::rcoal(20)`, one observation per
species, `set.seed(1)` with the probe's preceding draws):

- native TMB REML: FITS, `logLik = -14.6046181690` (identical to the value the
  row already recorded).
- bridge REML: FITS, `estim_method = REML`, `logLik = -14.6046181684`
  (6.0e-10 from native).

The sibling row `gaussian_response_mask` (same cell with
`missing = miss_control(response = "include")` and one NA response) was
re-measured on the same build and did NOT flip: native TMB still refuses with
its missing-data-engine gate, and the bridge still refuses with drmTMB's
mean-only-phylo message, because the widened gate withdraws its admission
whenever a non-default response engine is requested. Without that withdrawal the
user would have received DRM.jl's raw `ArgumentError` and a JuliaCall trace --
a regression this receipt's probe caught and the change fixes.

## What this receipt does NOT cover

- Only `phylo()`. `relmat()` / `animal()` / `spatial()` mean-structured Gaussian
  cells are served by DRM.jl's DENSE structured fitter, which has no restricted
  objective; they still refuse, and the 261 row
  `general_covariance_structured` (gaussian) is unchanged.
- Only `sigma ~ 1`. A `sigma` predictor routes DRM.jl to the dense fitter and
  still refuses.
- One fixture, one draw. Point estimates, log-likelihood and Wald SEs only --
  no interval coverage, no recovery study, no timing claim.
- `algorithm = :em` and `algorithm = :sparse` on this cell keep refusing REML,
  as does `penalty` combined with `method = :REML`.
