# REML same-target receipt: `biv_gaussian_residual`

drmTMB #1142 / DRM.jl #624 - `docs/design/261-reml-by-route.md` row `biv_gaussian_residual`.
Measured 2026-09-05. Every number below was produced in this run; nothing is
carried over from a prior receipt.

## The cell

```r
bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)
family = biv_gaussian(), REML = TRUE
```

## Builds under test

| side | identity |
|---|---|
| drmTMB | worktree `/Users/z3437171/local-scratch/parity-joint/wt-reml-biv-residual`, branch `claude/parity-reml-biv-residual` off `origin/main` 802522384, loaded with `devtools::load_all()` |
| DRM.jl | worktree `/Users/z3437171/local-scratch/parity-joint/wt-reml-biv-residual-drmjl`, branch `claude/parity-reml-biv-residual-drmjl`, sha `3a87fe385666aadaa869acfe9b6f4db1bc4a33bc` (PR itchyshin/DRM.jl#652), off DRM.jl `origin/main` 292067b0f |
| environment | `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH=<DRM.jl worktree> DRM_JL_PHYLO_PATH=<DRM.jl worktree>` |

## The committed fixture

Reproduces the RNG stream of
`docs/dev-log/evidence/julia-r-parity/reml-by-route/native_reml_probe.R` exactly
(its row-1 draws are consumed first), so the `logLik` recorded in design 261
stays the same number it was:

```r
set.seed(1)
n  <- 60
x  <- rnorm(n)
y  <- 0.5 + 0.8 * x + rnorm(n, sd = 0.6)          # row-1 draws (stream position)
y1 <- 0.4 + 0.6 * x + rnorm(n, sd = 0.5)
y2 <- -0.2 + 0.3 * x + 0.4 * y1 + rnorm(n, sd = 0.5)
d_biv <- data.frame(y1 = y1, y2 = y2, x = x)
```

The same fixture is built by `drm_reml_biv_residual_fixture()` in
`tests/testthat/test-julia-reml-biv-residual.R`.

## What "REML" means on each side - the convention, stated on both

Both engines integrate out **exactly `{beta_mu1, beta_mu2}`** and nothing else.

* **Native TMB.** `src/drmTMB.cpp` has no REML branch at all; REML is a generic
  R-side mechanism. `drm_apply_estimator_spec()` (`R/drmTMB.R:1254-1286`) sets
  `tmb_random_names <- c(spec$random_names, "beta_mu1", "beta_mu2")` for a
  `biv_gaussian` model with no sigma-side random effect, and that vector is
  handed to `TMB::MakeADFun(random = ...)`. TMB's Laplace approximation is
  **exact** when the negative log-likelihood is quadratic in the integrated
  block, which it is here (the mean enters linearly through a Gaussian
  likelihood). `stats::logLik()` returns the restricted value.
* **DRM.jl.** `_fit_bivariate_residual_reml()` (`src/gaussian_bivariate.jl`)
  profiles `beta_mu1`/`beta_mu2` by GLS and evaluates the closed form
  `l_R(phi) = l_ML(beta_hat(phi), phi) - 0.5*logdet(sum_i Z_i' S_i^-1 Z_i) + (p_beta/2)*log(2*pi)`,
  optimising over `phi = (beta_sigma1, beta_sigma2, beta_rho)` alone.

**Constants match; there is no offset to remove before comparing.** TMB's
Laplace step contributes `+0.5*logdet(H) - (p_beta/2)*log(2*pi)` to the
marginal negative log-likelihood, which is term for term the DRM.jl correction
above. DRM.jl standardised every REML route on this normalised
Patterson-Thompson form in DRM.jl #477 (see the `reml_loglik` docstring in
`src/gaussian_core.jl`). The measured difference of **0.0** below is the
evidence, not the derivation.

## Same-target numbers

`engine = "tmb"` vs `engine = "julia"`, both with `REML = TRUE`, same fixture,
same call.

Coefficient NAMES are identical and in the same order on both engines
(`identical(nm_julia, nm_tmb)` is `TRUE`):
`mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, `mu2:x`, `sigma1:(Intercept)`,
`sigma2:(Intercept)`, `rho12:(Intercept)`.

| coefficient | tmb estimate | julia estimate | abs diff / max(1,\|tmb\|) | tmb SE | julia SE | SE rel diff |
|---|---|---|---|---|---|---|
| `mu1:(Intercept)`    |  0.3753589962190 |  0.3753589962190 | 2.220e-16 | 0.0671684274349 | 0.0671684274365 | 2.435e-11 |
| `mu1:x`              |  0.6128674161248 |  0.6128674161248 | 3.331e-16 | 0.0785766852337 | 0.0785766852357 | 2.435e-11 |
| `mu2:(Intercept)`    | -0.0857610132594 | -0.0857610132594 | 1.249e-16 | 0.0740975421799 | 0.0740975421817 | 2.435e-11 |
| `mu2:x`              |  0.4811441580093 |  0.4811441580093 | 0.000e+00 | 0.0866826792112 | 0.0866826792134 | 2.435e-11 |
| `sigma1:(Intercept)` | -0.6613678806760 | -0.6613678806517 | 2.435e-11 | 0.0928476357214 | 0.0928476690889 | 3.594e-07 |
| `sigma2:(Intercept)` | -0.5631888251731 | -0.5631888251487 | 2.435e-11 | 0.0928476357214 | 0.0928476690889 | 3.594e-07 |
| `rho12:(Intercept)`  |  0.3949364684136 |  0.3949360354878 | 4.329e-07 | 0.1313065204850 | 0.1313064346045 | 6.540e-07 |

```
max_d_coef_scaled = 4.329257e-07      (bar: 1e-4)          PASS
max_d_se_abs      = 8.588051e-08
max_d_se_rel      = 6.540460e-07      (bar: 1e-3 rtol)     PASS
```

Log-likelihoods:

```
logLik_REML_tmb   = -97.021205818372
logLik_REML_julia = -97.021205818372
diff              =   0.000000e+00                          (bar: 1e-4)  PASS

logLik_ML_tmb     = -90.202703298791
logLik_ML_julia   = -90.202703298791
diff              =   4.831691e-13                 (ML route untouched)
```

`nobs` is 60 on both engines; `attr(logLik(fit), "df")` is 7 on both.
The restricted value is genuinely restricted rather than ML relabelled:
`|logLik_REML_tmb - logLik_ML_tmb| = 6.8185` and the REML value is the lower of
the two, as it must be.

## Estimator honesty (read off the objects)

```
fit_julia$estimator             = "REML"
fit_julia$bridge$estim_method   = "REML"
fit_julia$effective_REML        = TRUE
fit_julia$bridge$reml_loglik    = -97.021205818372
fit_julia$bridge$ml_loglik      = -90.236796399337   (plain ML at the REML estimate)
fit_julia$bridge$infocrit_basis = "reml"
fit_tmb$estimator               = "REML"

ML control: drmTMB(..., REML = FALSE, engine = "julia")
  fit$estimator = "ML",  fit$bridge$estim_method = "ML"
```

## What changed to make this fit

* **DRM.jl** (PR itchyshin/DRM.jl#652): `src/gaussian_bivariate.jl` - the
  unconditional `method === :REML` throw on the residual-only route is replaced
  by a dispatch to the new `_fit_bivariate_residual_reml`; the design/validation
  block is extracted to `_biv_residual_designs` so the ML and REML fitters share
  one design and one theta layout. `V` (`meta_V`) plus `:REML` keeps its
  permanent refusal.
* **drmTMB**: `R/julia-bridge.R` - `drm_julia_reml_supported()`'s `biv_gaussian`
  disjunct gains `drm_julia_biv_residual_reml_supported()` alongside the existing
  `q4` test. Nothing else in the bridge changed.

## RED CONTROLS

**A - the bridge gate.** `R/julia-bridge.R` sha256 before:
`6dffbaddf4e8061b2117d060a961946f7d34a3d8897d58791924cf300966db4a`.
The new disjunct was forced false (`isTRUE(FALSE && drm_julia_biv_residual_reml_supported(formula))`)
and the parity test file re-run:

```
RED_CONTROL_A failed=1 error=1 skipped=0 passed=5
  test 1 "the bridge REML gate admits this cell and nothing wider"  failed=1
  test 2 "engine='julia' REML matches engine='tmb' REML on this cell" error=TRUE
```

It **fails**, it does not skip. The refusal raised at the call site, quoted:

> `engine = "julia"` cannot fit bivariate Gaussian models by `REML = TRUE`.
> x Refusing rather than fitting by maximum likelihood instead: ML and REML differ precisely on the variance components REML exists to correct, so a silent downgrade would move heritability, repeatability and ICC without saying so.
> i The DRM.jl bridge supports REML only for documented Gaussian cells. Ask for maximum likelihood explicitly with `REML = FALSE`, or simplify to a documented Gaussian REML cell.
> i Native `engine = "tmb"` fits Gaussian cells by REML, and has a separate diagnostic-only binomial REML route for an ordinary unlabelled `mu` random intercept or independent slope. It does not offer a general REML fit for every cell this bridge refuses.

Restored; sha256 after: `6dffbaddf4e8061b2117d060a961946f7d34a3d8897d58791924cf300966db4a`
(byte-identical).

**B - the DRM.jl fitter.** `src/gaussian_bivariate.jl` sha256 before:
`bd1cef459b3868d25e5d28093777247eb9caeb2d1b932f2794f51d027c273c05`. With the
file reverted to `origin/main` content and the drmTMB gate left **widened**, the
same bridge call fails inside Julia:

> Error happens in Julia.
> ArgumentError: drm: method = :REML needs random effects to restrict, and the residual-only bivariate Gaussian model has no random effects - use method = :ML (the default). REML IS available on the structured bivariate routes: q=4 (shared `phylo`/`relmat`/`animal`/`spatial` on mu1, mu2, sigma1, sigma2) and q=2 (#470).
> Stacktrace: [1] drm(f::BivariateDrmFormula, fam::Gaussian; ... method::Symbol, V::Nothing) [2] _bridge_fit ... [3] drm_bridge ...

This proves the receipt above exercised the NEW DRM.jl code path rather than a
stale one. Restored; sha256 after:
`bd1cef459b3868d25e5d28093777247eb9caeb2d1b932f2794f51d027c273c05`
(byte-identical).

**C - the SE comparison is not vacuous.** The parity test itself carries a
negative control: perturbing one Julia SE by 10 per cent must break the same
`rtol = 1e-3` check, and does (`expect_gt(..., 1e-3)` passes at 0.0909).

**Incident during RED CONTROL B, recorded because it changes how these controls
should be run.** `git stash` is repository-global, not worktree-local: git
worktrees share one `refs/stash` stack. The `git stash push -- src/gaussian_bivariate.jl`
used for control B collided with a concurrent stash/pop in a sibling lane's
worktree on the same DRM.jl repository, which popped this lane's entry into its
tree. The control's *result* above is unaffected (it was measured before the
collision, and the quoted refusal is the real engine message), but the change
had to be re-applied from source and was verified byte-identical by the sha256
pair quoted above before anything was committed. Future revert-and-restore
controls in a shared repository should use `git diff > patch` +
`git checkout --`, never `git stash`.

## Test gate

```
cd /Users/z3437171/local-scratch/parity-joint/wt-reml-biv-residual
OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH=... DRM_JL_PHYLO_PATH=... \
  Rscript -e 'devtools::load_all("."); ... testthat::test_file("tests/testthat/test-julia-reml-biv-residual.R")'

REML_PARITY_TESTS failed=0 skipped=0 passed=19
```

## Boundary - what this receipt does NOT cover

* **One fixture, one seed** (n = 60, seed 1). Point estimates and standard
  errors only. **Not** interval coverage, not profile or bootstrap inference
  through the bridge.
* **Only the intercept-only shape.** DRM.jl's closed form is general in the
  `sigma1`/`sigma2`/`rho12` designs, but a covariate-carrying design has not
  been measured against a native comparator, so
  `drm_julia_biv_residual_reml_supported()` deliberately keeps refusing those -
  the gate is no wider than this receipt.
* **Structured markers and `meta_V` are excluded**, not merely untested: a
  `phylo`/`relmat`/`animal`/`spatial` marker routes to the q=2 / q=4 engines
  (q=2 still refuses REML through the bridge), and `meta_V` plus REML is a
  permanent DRM.jl refusal.
* Other bivariate families (LogNormal, Student) still refuse REML on the
  residual-only route; this leaf touched only `biv_gaussian`.
