# Sigma-Side Phylogenetic Conditioning and a log-sigma Soft-Clamp

## Purpose

This note records the root cause of the catastrophic optimizer failure on Ayumi's
beak sigma-phylogenetic model (`drmTMB#570`, and the q4 case behind `drmTMB#555`)
and proposes a minimal, reviewable numerical remedy. The reader is the next
`drmTMB` engine contributor (Gauss/Ada) and the maintainer deciding whether to
adopt the likelihood guard. The diagnosis below was produced by the Gauss
(TMB/numerical) review role from direct experiments on the real 10,440-tip data.

## The failure

The full-data univariate beak-culmen Gaussian location-scale model with phylo on
both `mu` and `sigma` at n = 10,440 tips does not fit. At every starting point
tried (cold default; off-diagonal `eta_cor_phylo`; warm-start from the converged
no-sigma-phylo model) the marginal objective is about 400,000-500,000 (a healthy
value is about -3,692, which the no-sigma-phylo model reaches), the maximum
absolute gradient is about 700,000-880,000, `nlminb` reports
"false convergence (8)", and the run emits about 47 "NA/NaN function evaluation"
warnings. No start escapes it, so it is not a start-basin problem.

## Root cause (evidence)

The data has **one observation per tip** (10,440 rows, 10,440 unique `tree_tip`).
A phylogenetic GMRF random field on `log_sigma` therefore gives each tip its own
scale random effect informed by a **single residual** -- a structural
near-degeneracy. Combined with the **unbounded log link** on `sigma`, this makes
the inner Laplace solve diverge:

- At random effects = 0 the surface is healthy (`log_sigma` in [-2.46, 1.47]),
  but the per-tip residuals are heavy-tailed: `z = (y-mu)/sigma` has `max z = 22.6`,
  `max z^2 = 512.85`; 776 tips have `|z| > 3`.
- The sigma-field gradient at a tip is exactly `z^2 - 1`, so the field is yanked
  to absorb single extreme residuals (`max sigma-half random gradient = 511.85 =
  max(z^2) - 1`).
- The first inner Newton step overshoots `log_sigma` to about +26 (`sigma`
  about 1.9e11), the joint Hessian over the 41,756 random effects becomes
  indefinite (CHOLMOD "not positive definite"), and the inner solve never
  converges (at the iterate TMB lands on, 9,767 of 10,440 tips have
  `sigma < 1e-8`, down to about 9e-60). Hence `obj` is about 5e5 and the NaN
  warnings.
- The **no-sigma-phylo model uses the identical phylo precision and converges
  cleanly** (`max|random gradient| = 2.5e-10`). Branch-length conditioning is
  therefore ruled out: `R/phylo-utils.R` builds a well-formed precision
  (min edge 1.24e-4, ultrametric, `log_det_precision` about 86,212). The only
  difference is the sigma-side field.

Relevant code: the cross-dpar phylo GMRF accumulates `log_sigma` unbounded
(`src/drmTMB.cpp` around lines 663-720, `log_sigma(i) += contribution`), and the
Gaussian data term exponentiates it with no clamp (`src/drmTMB.cpp:1880`,
`sigma = exp(log_sigma)`; density at `:1900`). The same shape exists in the
bivariate Gaussian density (`src/drmTMB.cpp:352-353`, `sigma1/sigma2 =
exp(...)`), which is Ayumi's q4 "Model E".

It is scale-aggravated, not scale-created: even a 600-tip subtree fails unclamped;
a genuinely well-posed sigma-phylo design (80 tips, 5 observations per tip, so the
scale field is identifiable) converges cleanly with no clamp.

## Proposed remedy (a smooth log-sigma soft-clamp)

Apply a smooth, two-sided soft-clamp to `log_sigma` (and `log_sigma1`,
`log_sigma2`) immediately before exponentiation in the Gaussian density, scoped to
the Gaussian likelihood branches:

> **Update (2026-06-16, Wave 2 ML robustness).** The same guard now wraps every
> scale-bearing family branch (Student, skew-normal, lognormal, gamma, Tweedie,
> beta, zero-one-beta, beta-binomial, and the negative-binomial family: NB2,
> truncated, hurdle, zero-inflated) plus the Gaussian row-aggregation path,
> gated by the same `use_logsigma_clamp` switch. It stays bit-identical in band
> for every family (verified per family in `test-clamp-extension.R`), so the
> only behavioural change is on a runaway scale, where it converts an overflow
> into an assessable, clamp-flagged fit (see the clamp-active warning, Wave 1
> Guard 4). The missing-predictor imputation sub-models (`*_mi`) and the
> covariance-block prelude (`model_type == 96`) are not yet wrapped.

```cpp
// EXACTLY identity inside [lo, hi]; C1-smooth tanh saturation within a margin
// beyond each bound (overall range (lo - margin, hi + margin)).
template<class Type>
void drm_softclamp_log_sigma(vector<Type>& v, Type lo, Type hi, Type margin) {
  for (int i = 0; i < v.size(); ++i) {
    Type x = v(i);
    Type above = hi + margin * tanh((x - hi) / margin); // used only when x > hi
    Type below = lo - margin * tanh((lo - x) / margin); // used only when x < lo
    Type y = CppAD::CondExpGt(x, hi, above, x);
    y = CppAD::CondExpLt(x, lo, below, y);
    v(i) = y;
  }
}
```

The clamp saturates the data term's gradient with respect to a runaway scale
random effect, so the inner Hessian stays recoverable and the inner Newton solve
converges.

**Implementation note (identity-in-band).** A first attempt used a pure-softplus
clamp (`hi - softplus(hi - x)`, `lo + softplus(x - lo)`). It saturates smoothly
but is *not* exactly the identity in the central band: it leaks a small bias
(about `1e-4` near the bounds) into ordinary fits, which broke exact-equality and
cross-path tests (aggregate vs per-observation Gaussian, `engine = "julia"` vs
`"tmb"` parity, and manual-vs-fitted missing-predictor log-likelihoods) in the
full test suite. The adopted form above is **exactly the identity inside
`[lo, hi]`** (the `CondExp` selects the raw value there) and only saturates
within a `tanh` margin beyond the bounds, so every well-posed fit -- whose
`log(sigma)` lies in the band -- is unchanged to the bit. Band used:
`lo = -12`, `hi = 12`, `margin = 3` (identity in `[-12, 12]`, bounded to
`[-15, 15]`). Full-suite re-run with this form: 0 failures. Real-beak
revalidation: `logLik -499,839 -> -12,673` (finite), `max|grad| 881,785 ->
1,587`, with the lower bound binding (`log_sigma -> -14.96`) and
`convergence = 1` preserved as the weak-identifiability signal; the well-posed
smoke fit is unchanged (`-72.57`).

### Before/after -- exploratory [-7, 7] softplus band (SUPERSEDED)

The numbers below are Gauss's original exploration in a throwaway copy using the
**superseded pure-softplus clamp with band [-7, 7]**, not the shipped form. The
adopted identity-in-band [-12, 12] clamp's validation of record is in the
implementation note above (overflow removed; beak `-499,839 -> -12,673`; smoke
fit unchanged; full suite green). This block is kept only to show the mechanism's
effect on the inner solve:

- Full 10,440 cold-start `obj`: 499,839 -> about 9,915 (band [-7, 7]).
- Inner solve `max|random gradient|`: 7,810 (diverged) -> 7.1e-9 (converged).
- Full 10,440 fit objective: +499,839 -> about -5,175 (healthy regime; the
  no-sigma-phylo target is about -3,692).
- Fidelity on a well-posed fit (80 tips, 5 reps, where unclamped converges):
  logLik -338.6613 -> -338.6616; `mu` coefficients differ by <= 3e-6, `sigma`
  coefficients by <= 1.2e-3. The clamp does not change well-behaved fits.

## Design decisions for review

1. **The band is the key reviewable parameter.** It must be wide enough never to
   bind for legitimate Gaussian fits (recall `drmTMB` models `sigma` on the log
   scale and may see unstandardized data) and tight enough to catch the runaway
   (which overshoots to `log_sigma` about +26). The shipped band is [-12, 12]
   (identity region: `sigma` in [6e-6, 1.6e5]) with a `tanh` margin of 3, i.e. a
   hard saturation cap at [-15, 15] (`sigma` in [3e-7, 3.3e6] = `exp(+/-15)`); it
   is non-binding for essentially all realistic regression scales while still
   bounding the runaway. (Gauss's earlier exploration used [-7, 7]; the wider band
   is preferred so the guard does not silently regularize a legitimate
   large-variance fit.) The clamp is C1 but not C2 at the band edge; the saturated
   tail -- where a runaway iterate actually settles (the beak binds at
   `log_sigma -> -14.96`) -- is smooth, so the inner Newton solve crosses the C1
   knot only transiently. The band and margin are single named constants, easy to
   audit and change.
2. **It is formally a likelihood change** (a smooth truncation of the scale in the
   extreme tails), so `docs/design/03-likelihoods.md` is updated and a simulation
   test is added. It is consistent with existing numerical guards in the package
   (the beta/zero-one-beta `shape_floor = 1e-8` clamps and the `0.99999999`
   correlation bounds).
3. **It is necessary but not sufficient.** The clamp removes the numerical
   blow-up so the fit is assessable instead of returning -499,839/NaN; it does
   **not** create identifiability for a per-tip scale field estimated from one
   observation per tip. The honest user-facing recommendation is to model the
   scale side with fixed effects only -- phylogeny on the mean only ("Model A":
   `phylo(1 | pl | id)` on `mu1`/`mu2`, fixed-effect `sigma1`/`sigma2`) -- or to
   supply multiple observations per group. In tests at pruned sizes (n = 300-600)
   with the full four-covariate `sigma` specification, a separable "Model D"
   (distinct mean and scale labels) did **not** reliably converge either: the
   scale-side phylo SD hits its lower boundary whether the 4x4 block is coupled
   ("Model E") or block-diagonal ("Model D"), so the coupling is not the issue --
   the scale-side field itself is weakly identified. (Model D may still converge
   on specific full-size clean trees, per the data owner's across-tree results;
   the determining factor is whether the data support a non-zero scale-side phylo
   SD, not the block structure.)

## Accompanying measures (separate slices)

- An honest `check_drm()` / fit-time signal for the "false convergence (8) with a
  large gradient frozen near the start" pattern that points the user to the
  identifiability remedies above.
- A smaller / regularized default `sd_sigma_phylo` start.
- Documentation of Model A (phylogeny on the mean, fixed-effect scale) as the
  tractable q4 path, plus an honest `check_drm()` signal for the scale-side phylo
  SD hitting its boundary. (An off-diagonal `theta_phylo` start does NOT help in
  the R/TMB implementation: `theta_phylo = 0` already gives an identity
  correlation, so there is no removable singularity to escape -- that was a
  Julia-implementation-specific issue.)
- A clarification that the structural phylogenetic correlation
  (`fit$corpars$phylo`, derived from `theta_phylo`; identity at `theta = 0`) is
  distinct from empirical correlations among the fitted random effects: a large
  empirical random-effect correlation at `theta = 0` is not a structural
  boundary correlation.

## Status

The clamp in this branch is a proposal for review (draft PR, not merged). It is
validated on the real data and guarded by tests; the band value and the formal
likelihood change are the maintainer's decision.
