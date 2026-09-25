# Covariate-Dependent Phylogenetic SD and the Shared-Shift Optimum

## Purpose

This note explains why a Gaussian model with a phylogenetic location effect whose
standard deviation depends on covariates can have more than one accepted optimum,
and what users and `check_drm()` should do about it. The readers are applied users
fitting `sd(species, level = "phylogenetic") ~ x` (or the soft-deprecated
`sd_phylo(species) ~ x`) and the next `drmTMB` contributor who touches the
phylogenetic direct-SD route. It records a diagnosis made on real data, the
evidence for it, and a new `check_drm()` row. The likelihood and its
parameterisation are unchanged; changing them is an open decision (last section).

## The model and the failure

The model that failed is a univariate Gaussian location-scale-scale fit:

```r
bf(
  y ~ 1 + temp + prec + phylo(1 | species, tree = tree),
  sigma = ~ temp + prec,
  sd(species, level = "phylogenetic") ~ temp + prec
)
```

In symbols, for species \(i\),

\[
y_i = \beta_0 + \beta_T t_i + \beta_P p_i + s_i\,u_i + \varepsilon_i,\qquad
\log s_i = \alpha_0 + \alpha_T t_i + \alpha_P p_i,
\]

with \(u \sim N(0, Q^{-1})\) a unit-scale Brownian-motion field on the tree and
\(\varepsilon_i \sim N(0, \sigma_i^2)\).

In a collaborator's whole-tree bird analysis (10,970-tip tree, 8,979 observed
responses; private repository, issue #35, 2026-09-24), multistart refits over 50
posterior trees found two families of accepted optima. Both passed all seven of
the project's numerical gates (convergence, positive-definite Hessian, gradient,
polish stability, conditioning, covariance agreement). Their log-likelihoods
differed by 0 to 13 units, which solution was higher changed from tree to tree,
and the location coefficients differed greatly: the intercept moved by about 31
response units and the precipitation slope roughly tripled. Pooling across trees
with Rubin's rules mixed the two, which inflated the pooled interval for the
precipitation slope about eightfold relative to a stable model.

## Mechanism

**Code.** In `src/drmTMB.cpp` (the `has_sd_phylo_model` branch, around lines
1003-1030) the phylogenetic contribution to the mean is the latent value at the
species' node multiplied by that species' fitted SD:

```cpp
Type field_effect = u_phylo(effect_index);
if (has_sd_phylo_model == 1) {
  field_effect *= sd_phylo_group(phylo_mu_sd_row(i));
}
mu(i) += phylo_mu_value(i, k) * field_effect;
```

With a direct-SD model the prior on `u_phylo` is unit scale,
\(\tfrac12 u^\top Q u\), with no SD term (the `has_sd_phylo_model == 1` branch
of the prior loop). `drm_phylo_augmented_precision()` in `R/phylo-utils.R`
builds \(Q\) over tips and internal nodes but drops the root
(`included_nodes <- setdiff(seq_len(n_total), info$root)`), so the root value is
fixed at 0, and the tree is scaled to unit height so each tip has prior variance 1.

**A shared shift.** Move every latent value by the same amount \(\delta\):
\(u \to u + \delta \mathbf{1}\). The prior charges

\[
\Delta\bigl(\tfrac12 u^\top Q u\bigr) = \delta\,\mathbf{1}^\top Q u + \tfrac12 \delta^2\,\mathbf{1}^\top Q \mathbf{1},
\]

and \(\mathbf{1}^\top Q \mathbf{1} = \sum_{c} 1/\ell_c\) over the edges \(c\)
leaving the root, because every other row of \(Q\) sums to zero. On a tree whose
root edges are long relative to its height the charge is small; on the bird tree
\(\mathbf{1}^\top Q \mathbf{1}\) was 7.6 and 12.4 on the two trees checked.

The mean receives \(\delta s_i = \delta \exp(\alpha_0 + \alpha_T t_i + \alpha_P p_i)\).
When the SD is constant (\(\alpha_T = \alpha_P = 0\)) this is a constant that the
location intercept absorbs exactly, so nothing changes. When the SD depends on
covariates it is a **curved** function of them. To first order the location
coefficients compensate for its straight-line part,

\[
(\Delta\beta_0, \Delta\beta_T, \Delta\beta_P) \approx -\delta e^{\alpha_0}\,(1, \alpha_T, \alpha_P),
\]

and what remains is curvature of size about
\(\delta e^{\alpha_0}(\alpha_T^2 t^2 + \alpha_P^2 p^2)/2 + \dots\). If the data
curve in \(t\) or \(p\) and the location formula is linear, that curvature
improves the fit. The gain grows with both \(\delta\) and \(|\alpha|\), while the
prior charges for \(\delta\). The likelihood therefore has two optima rather than
a ridge: a small shift with a nearly flat SD (solution A), or a large shift with
the SD rising steeply along the curved covariate (solution B), which pays roughly
7 to 10 log-likelihood units of prior cost for a better fit to the curvature.

## Evidence

All numbers are from the collaborator case described above.

1. **The shift ratios match the SD coefficients.** If the mechanism holds,
   \(\Delta\beta_T / \Delta\beta_0 \approx \alpha_T\) and
   \(\Delta\beta_P / \Delta\beta_0 \approx \alpha_P\), using the solution-B SD
   coefficients. Across the 23 trees with both solution A and solution B, the
   correlation between the observed ratio and the SD coefficient was 0.999 for
   temperature and 0.89 for precipitation (on a log-response scale, 0.99 and
   0.76). The precipitation ratio (median 0.10) exceeds \(\alpha_P\) (median
   0.086) because the exponential is convex and precipitation is right-skewed.
   Two trees showed a third solution type, so more than two optima can exist.
2. **Missing responses are not involved.** Refitting one tree after pruning the
   1,991 unobserved tips reproduced both solutions with identical
   log-likelihoods and coefficients (to about 1e-9).
3. **Removing either ingredient removes the second optimum.** On three trees,
   started from both an A-type and a B-type point, a constant phylogenetic SD and
   a quadratic location formula (`temp + I(temp^2) + prec + I(prec^2)`, SD
   formulas unchanged) each converged to a single solution. The quadratic mean
   also raised the log-likelihood by 68 to 74 units.
4. **The quadratic mean is stable at scale.** With the quadratic location formula,
   all 300 fits (50 trees, two response scales, three starts each) passed the
   gates and every tree gave one solution; starts agreed to 2e-9 log-likelihood
   units.
5. **Smaller clades were not affected.** The same linear structure fitted within
   12 families of 61 to 449 species, from four starts each including starts
   aimed at this shift, gave one solution per family. The failure needs curvature
   that is visible across a wide covariate range.

Adding curvature removes the second optimum in practice, not in principle.
The compensating direction also has components along the quadratic terms, so
curvature the formula still lacks (a cubic, or a `temp:prec` interaction) could
bring a second optimum back.

## When it bites

All three conditions are needed:

- a phylogenetic location effect with a direct-SD formula that has covariates;
- a location formula that misses curvature in those same covariates;
- enough covariate range for the missing curvature to be worth the prior cost.

It does not arise with a constant phylogenetic SD, and it did not arise with a
location formula that already carries the curvature. The same algebra applies to
any latent field that is scaled per observation and has a fixed reference point,
so future spatial, animal-model, or `relmat()` direct-SD routes should be checked
the same way when they are implemented.

## What users should do

1. Run `check_drm()` and read the `phylo_sd_shared_shift` row (below).
2. Before interpreting location coefficients, check the mean for curvature in the
   SD covariates, for example by adding quadratic terms and comparing
   log-likelihoods.
3. Probe for the shifted optimum with a targeted start. Only the location
   coefficients need seeding; `start` labels for the SD coefficients are not
   needed. With fitted values \(b_0, b_T, b_P\) and SD coefficients
   \(a_0, a_T, a_P\), try \(c = \pm 2\):

   ```r
   shift <- c * exp(a0)
   refit <- drmTMB(
     formula, data = dat,
     control = drm_control(start = list(
       "fixef:mu:(Intercept)" = b0 - shift,
       "fixef:mu:temp" = bT - shift * aT,
       "fixef:mu:prec" = bP - shift * aP
     ))
   )
   ```

   In the case study, seeding only the location coefficients at solution-B values
   reached solution B exactly. We have not tested whether the random
   perturbations of `drm_control(multi_start = )` reach it, so the targeted start
   is the recommended probe.
4. If two solutions have similar log-likelihoods, do not interpret the linear
   model's location coefficients on their own; report a model whose mean carries
   the curvature.

## What `check_drm()` does

`check_drm()` reports a `phylo_sd_shared_shift` row for each phylogenetic
direct-SD model that has covariates. It reads the stored conditional modes
(`fit$random_effects$phylo_mu$latent`) and the stored precision
(`fit$model$structured$phylo_mu$precision$precision`), so it needs no refit and
works when the TMB object is not kept. The statistic is

\[
z_{\text{shared}} = \frac{\mathbf{1}^\top Q \hat u}{\sqrt{\mathbf{1}^\top Q \mathbf{1}}},
\]

the precision-weighted shared shift of the latent field in prior-SD units. It is
standard normal under the prior, and \(z_{\text{shared}}^2/2\) is the prior cost
of the shift. The row also prints the latent shift
\(\hat\delta = \mathbf{1}^\top Q \hat u / \mathbf{1}^\top Q \mathbf{1}\) and the
range of \(\hat\delta s_i\) over species, the shift's effect on the mean in
response units. The row is `ok` below 2, a `note` from 2, and a `warning` from 3.
Intercept-only SD models get no row, because a constant SD cannot bend the mean.

Calibration on the case study (tree positions 1 and 14):

| Fit | \(z_{\text{shared}}\) |
|---|---|
| Linear mean, solution A | 0.47, 0.58 |
| Linear mean, solution B | 3.74, 4.37 |
| Linear mean, constant phylogenetic SD | about 0 |
| Quadratic mean | -0.10, -0.20 |

Run end to end through `check_drm()` on tree position 1, the default fit
(solution A) returned `ok`, the fit seeded at solution B returned `warning`, the
quadratic-mean fit returned `ok`, and the constant-SD fit had no row. The
thresholds are calibrated on one data set; treat a `note` as a prompt to run the
checks above rather than as a verdict.

## Open decision (not implemented)

The shared-shift direction is a property of this model class, not a coding
error: \(u_i = s_i z_i\) with a fixed root is the ordinary heteroscedastic
phylogenetic model. Two changes could remove the direction, and both change what
the model means, so neither is made without an explicit decision from Shinichi:

- constrain the latent field so its precision-weighted mean is zero
  (\(\mathbf{1}^\top Q u = 0\)), which removes the shift but also removes a
  degree of freedom the prior currently allows; or
- estimate a root value separately from the location intercept, which makes the
  shift explicit but leaves it weakly identified.

Until then the diagnostic and the advice above are the supported response.

## Related notes

- [35: optimizer, start, map, and multi-start contract](35-optimizer-start-map-multistart.md).
  Its "Future Multi-Start Contract" section predates the now-public
  `drm_control(multi_start = , start = )` arguments.
- [171: scale-side phylogenetic identifiability](171-scale-side-phylo-identifiability-model-a.md),
  a different weak-identification failure of phylogenetic fields placed on
  `sigma`.
