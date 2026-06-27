# Small-sample bias-corrected intervals for structured-RE variance components

## Reader and purpose

For maintainers and statistically-literate users of `drmTMB`. It documents the
opt-in small-sample interval for structured random-effect SD targets — what it
does, why it works, its scope and caveats, the simulation evidence, and the
literature it rests on. The method makes Wald intervals on structured-RE
variance-component SDs reach nominal coverage at small group counts, including
the deployment default.

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

`confint(object, method = "wald", small_sample_df = "group", bias_correct = "group")`
applies two independent small-sample adjustments to each structured-RE SD target
with a resolvable group count `g`:

1. **Width** (`small_sample_df = "group"`): replace the normal quantile `z` with a
   t-quantile, `qt(p, df = g - 1)` — a between-group, Satterthwaite/Kenward-Roger
   style effective df (Satterthwaite 1946; Kenward & Roger 1997).
2. **Centre** (`bias_correct = "group"`): shift the log-scale point estimate up by
   `log(g / (g - 1))`, i.e. `sigma_corrected = sigma_ML * g/(g - 1)`, before
   back-transforming.

They compose to
`exp( (log(sigma_hat) + log(g/(g-1))) +/- qt(p, g-1) * se_log )`.

Both are **opt-in** and default to `"none"` (byte-identical to prior behaviour),
and both are **scoped to location-axis variance components**: dispersion (`sigma`)
SDs already over-cover under the normal quantile, so neither adjustment is applied
to them.

## Why `g/(g-1)` — it is REML's debiasing in closed form

The centre shift is not an ad-hoc fudge; it reproduces the **REML** leading-order
variance-component correction. The canonical illustration: estimating a variance
from `g` observations around an estimated mean,

- ML: `E[sigma^2_ML] = sigma^2 (g-1)/g` (biased low),
- REML / unbiased: `sigma^2_REML = sigma^2_ML * g/(g-1)`.

So **REML's variance debiasing _is_ the `g/(g-1)` factor** (Patterson & Thompson
1971; Harville 1977; Searle, Casella & McCulloch 1992). `bias_correct = "group"`
applies that same factor on the SD log scale, giving a structured-RE SD interval
the centre a REML fit would have produced — without needing the restricted
likelihood (which, for `drmTMB`'s scale axis, is not derived). It is the
additive-shift instance of the general first-order ML bias-correction framework
(Cox & Snell 1968; the penalized alternative is Firth 1993).

**This makes REML less _urgent_ for honest small-`g` intervals on these cells, but
not less important in general:** `g/(g-1)` is the *leading-order* term, exact only
in the balanced one-component case; REML is exact-by-construction for arbitrary
unbalanced designs and jointly debiases all components, their correlations, and
the fixed-effect SEs. The closed-form shift is a calibrated approximation,
validated per model class (below), in the spirit drmTMB's doctrine prescribes.

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
- **Location axis only.** Not applied to dispersion (`sigma`) SDs, which already
  over-cover; applying the upward shift there would push them further conservative.
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
