# Small-sample bias-corrected intervals for structured-RE variance components

## Reader and purpose

For maintainers and statistically-literate users of `drmTMB`. It documents the
small-sample interval for structured random-effect SD targets — what it does, why
it works, its scope and caveats, the simulation evidence, and the literature it
rests on. The method makes Wald intervals on structured-RE variance-component SDs
reach nominal coverage at small group counts. As of 2026-06-27 the correction is
the **default** for location-axis structured SD targets (see "Default scope"
below); it remains opt-out via `"none"` and has a broader `"group"` opt-in.

## The problem

A structured random-effect SD (e.g. the between-species SD of a phylogenetic
random slope) is a variance component. Its maximum-likelihood estimate is biased
**low** at small group count `g`, and the symmetric Wald interval built around it
**under-covers**. Measured on the `drmTMB` q2 mu-slope SD cells: Wald-z coverage
is ~0.88 at g=8 against a 0.95 nominal target. Every interval method drmTMB
offers — Wald, profile, and the parametric percentile bootstrap — is centred on
the same biased estimate, so none reaches nominal at small `g` on its own. The
shortfall is a **centre** (point-estimate bias) problem, not a width problem.

## The correction (two independent pieces)

`confint(object, method = "wald")` applies two independent small-sample
adjustments to each structured-RE SD target with a resolvable group count `g`:

1. **Width** (`small_sample_df`): replace the normal quantile `z` with a
   t-quantile, `qt(p, df = g - 1)` — a between-group, Satterthwaite/Kenward-Roger
   style effective df (Satterthwaite 1946; Kenward & Roger 1997).
2. **Centre** (`bias_correct`): shift the log-scale point estimate up by
   `log(g / (g - 1))`, i.e. `sigma_corrected = sigma_ML * g/(g - 1)`, before
   back-transforming.

They compose to
`exp( (log(sigma_hat) + log(g/(g-1))) +/- qt(p, g-1) * se_log )`.

### Default scope (changed 2026-06-27)

Both adjustments now **default to `"location"`**: the correction is applied
**by the default `confint(fit)` / `summary(fit, conf.int = TRUE)` path** to the
location-axis (`mu`, `mu1`, `mu2`) **structured** (`phylo`/`spatial`/`animal`/
`relmat`) SD targets that resolve a `g`, and to nothing else. The default was
promoted from opt-in because a six-reviewer panel ruled the cells cannot reach a
public tier while nominal coverage hides behind a two-argument opt-in that the
default `confint(fit)` does not apply.

The default is deliberately narrow:

- **Location axis only.** Dispersion (`sigma`, `sigma1`, `sigma2`) structured SDs
  already over-cover under the normal quantile, so neither adjustment is applied
  to them by default — they keep the raw `z`-interval.
- **Structured blocks only.** A plain labelled covariance block such as
  `(1 + x | p | id)` resolves a registry `g`, but its correction magnitude is not
  yet simulation-calibrated, so the default leaves it at the raw `z`-interval too.
- **Opt-out.** `small_sample_df = "none"` and/or `bias_correct = "none"` force the
  raw `z`-interval for **every** target, byte-identical to the pre-default
  behaviour, so users can recover the previous numbers exactly.
- **Broader opt-in.** `small_sample_df = "group"` / `bias_correct = "group"`
  widen/shift **every** resolvable SD target — structured and labelled-covariance,
  location and dispersion axis alike — for users who deliberately want that scope.

Non-structured and fixed-effect targets are never adjusted in any mode.

## Why `log(g/(g-1))` — a simulation-calibrated shift, REML-*motivated* but ~2× the REML SD term

**The shift is calibrated to the measured shrinkage, not derived from REML.** Be
precise about the magnitude, because it is easy to overclaim (and an earlier draft
of this note did). The authority for the `log(g/(g-1))` shift is the empirical bias
table below — the mean log-scale ML shrinkage measured on these cells — not a
theorem.

REML supplies the *motivation and direction*, not the magnitude. The canonical
illustration — estimating a variance from `g` observations around an estimated
mean:

- ML: `E[sigma^2_ML] = sigma^2 (g-1)/g` (biased low),
- REML / unbiased: `sigma^2_REML = sigma^2_ML * g/(g-1)`.

REML debiases the **variance** by `g/(g-1)`. On the **SD** that is a factor
`sqrt(g/(g-1))`, i.e. a log-SD shift of **`0.5 * log(g/(g-1))`** (≈ +0.067 at g=8).
But `bias_correct = "group"` shifts the log-SD by the **full** `log(g/(g-1))`
(≈ +0.134 at g=8) — **about twice the leading-order REML SD correction**. So this
is *not* "REML on the SD in closed form"; applying the variance Bessel factor
directly to the SD scale would be a category error.

The full `log(g/(g-1))` is used because that is what the data require: the measured
log-SD shrinkage of these *structured, bivariate, labelled-covariance* variance
components is ~`log(g/(g-1))` (g=8: −0.129 vs −0.134), roughly double the simple
balanced-one-component REML SD term. The excess is real: the bivariate correlated
structure, the fixed effects, and the integrated-out random effects together leave
an **effective df well below `g-1`**, so the shrinkage is larger than the textbook
Bessel factor predicts. At g=16 the measured bias (−0.081) even *exceeds*
`log(16/15)` (−0.065), which a clean closed-form `g/(g-1)` story cannot explain —
it is calibration, with the residual absorbed by the t-width.

So: the references (Patterson & Thompson 1971; Harville 1977; Searle, Casella &
McCulloch 1992) support the **variance** Bessel factor and the general first-order
ML bias-correction framework (Cox & Snell 1968; Firth 1993) — they motivate *a*
log-scale shift and its direction, but they do **not** derive this specific
magnitude. The magnitude is a **simulation-calibrated, per-model-class** quantity,
and must be re-validated by simulation before it is trusted on any other cell
class, truth, or design (see Scope and caveats). REML remains the principled,
exact, general tool; this is a calibrated approximation that reproduces REML's
*qualitative* small-`g` correction on the validated cells, at roughly twice the
naive SD-scale magnitude.

## Evidence

**Bias form tracks `log(g/(g-1))` across g** (banked q2 grids, post-hoc;
`docs/dev-log/simulation-artifacts/2026-06-27-oracle-bias-correction/`):

| g | measured mean log-bias | `log(g/(g-1))` |
|---|---|---|
| 8 | -0.129 | -0.134 |
| 16 | -0.081 | -0.065 |
| 32 | -0.029 | -0.032 |

(The g=16 row shows the approximation is not exact — the effective df is slightly
below `g-1` because fixed effects consume df — but the t-width absorbs the slack.)

**Engine-validated coverage at the deployment default g=8** (fresh SR475 fits
through `confint`, 4 certified cells;
`docs/dev-log/simulation-artifacts/2026-06-27-bias-corrected-engine-coverage-g8/`):

| cell | n | Wald-z | **bc + t** | MCSE |
|---|---|---|---|---|
| phylo mu1:x | 475 | 0.895 | 0.964 | 0.009 |
| relmat mu1:x | 475 | 0.893 | 0.964 | 0.009 |
| phylo mu2:x | 475 | 0.876 | 0.943 | 0.011 |
| relmat mu2:x | 475 | 0.874 | 0.945 | 0.010 |
| **pooled** | 1900 | 0.884 | **0.954** | 0.005 |

Post-hoc cross-g coverage (same correction): g=8 0.955, g=16 0.949, g=32 0.963 —
nominal at every g, no over-correction at large g.

## Why the cheaper alternatives do not substitute

- **Profile / Wald-t** fix the width only; centre stays biased → ~0.91-0.93 at g=8.
- **Single-level parametric bootstrap** cannot recover the centre bias: it measures
  the estimator's bias *at* `theta_hat` (where the log-SD ML estimator is nearly
  median-unbiased), ~-0.01, not the bias *at the true parameter*, -0.13
  (`.../2026-06-27-bootstrap-bias-prototype/`). This is the expected behaviour
  given the bootstrap's delicacy near a one-sided/boundary regime (Efron &
  Tibshirani 1993; Self & Liang 1987; Stram & Lee 1994; cf. Kubokawa & Nagashima
  2012 for parametric-bootstrap bias correction in LMMs).

## Scope and caveats

- **Calibrated per model class.** Validated for the q2 mu-slope SD cells
  (phylo/relmat) at g=8/16/32. Other cells/designs must be re-validated by
  simulation before relying on the correction (the doctrine's standing rule).
  This is exactly why the *default* (`"location"`) excludes plain labelled
  covariance blocks such as `(1 + x | p | id)`: they resolve a registry `g` but
  their correction magnitude is not yet simulation-calibrated, so the default
  leaves them at the raw `z`-interval (the `"group"` opt-in still corrects them).
- **Location axis only.** Not applied by default to dispersion (`sigma`) SDs,
  which already over-cover; applying the upward shift there would push them
  further conservative. The `"group"` opt-in does reach the dispersion axis.
- **Boundary regime.** When a true variance component is at or near zero, the
  sampling distribution is one-sided and neither the centre shift nor the t-width
  restores nominal coverage (Self & Liang 1987; Stram & Lee 1994). The covered
  cells have SD truth ~0.9-1.05, well away from the boundary.
- **Leading-order.** `g/(g-1)` is the first-order term; REML remains the exact,
  general tool.

## References

See the `@references` block of `confint.drmTMB` and `REFERENCES.bib`
(`PattersonThompson1971`, `Harville1977`, `SearleCasellaMcCulloch1992`,
`CoxSnell1968`, `Firth1993`, `Satterthwaite1946`, `KenwardRoger1997`,
`SelfLiang1987`, `StramLee1994`, `EfronTibshirani1993`, `KubokawaNagashima2012`,
`WolakFairbairnPaulsen2012`).
