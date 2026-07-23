# Arc 6 research report: two-response latent-normal and direct joint models

## Status and question

This is a **research and design report only**. No model code, smoke test,
recovery campaign, capability tier, Julia work, `meta_V()` work, or CRAN work
has started.

It is an evidence companion, not an implementation authority. The reviewed
authorities are the first-slice
[`Ultra Plan`](2026-07-23-arc6-margin-first-latent-normal-ultra-plan.md) and
the [`bivariate-series overview`](../design/230-arc6-bivariate-series-overview.md).

The design question is which of four distinct layers a two-trait analysis
needs: separate marginal models, correlated shared group effects, a
latent-normal within-row joint model, or a direct family-specific joint model.

## Established precedents

### MCMCglmm

Jarrod Hadfield's current notes explicitly cover multi-response models with
responses "possibly from different distributions". `MCMCglmm` turns
`cbind(y1, y2)` into a long response with a `trait` factor and asks for one
family per trait. Its Gaussian example uses `random = ~ us(trait):id` for a
trait-by-group covariance matrix and `rcov = ~ us(trait):units` for an
observation-level residual covariance matrix. These answer different
questions: stable between-group trait association versus within-unit association
after those effects.

For non-Gaussian traits, the notes explicitly say the covariances are formed
for underlying link-scale/latent parameters rather than directly for the
observed responses. That can be the right estimand, but it is not automatically
an observed-count or observed-binary correlation. The notes also warn that a
joint model has to model the *joint* distribution well, not only the two
margins. [Hadfield's multi-response notes](https://jarrodhadfield.github.io/MCMCglmm/course-notes/multi.html)

For threshold (Bernoulli/probit) traits, MCMCglmm must fix the corresponding
latent residual variance to identify the scale. Its `corg` covariance structure
fixes diagonal variances to one while estimating the off-diagonal correlation;
Hadfield's notes use a related residual structure in a Gaussian--threshold
example. This is standard liability-model identification. It is **not** a
free residual variance on the observed 0/1 scale. In a Gaussian--threshold
pair, only the threshold diagonal is fixed: the raw off-diagonal is a covariance
and must be standardized before it is called a correlation.
[MCMCglmm reference](https://ftp.gwdg.de/pub/misc/cran/web/packages/MCMCglmm/refman/MCMCglmm.html)

**Lesson for drmTMB:** borrow the separation of margin-specific formulas,
group-level covariance, and observation-level association. Do not collapse them
into one `rho`.

### brms

`brms` expresses a multivariate model as separate response formulas, with
potentially different predictors, and can correlate shared group-level effects
through a common ID in random-effect terms. Its official reference restricts
`rescor` to multivariate Gaussian and Student-t models; it does not claim a
universal residual correlation for mixed response families.
[brms multivariate reference](https://search.r-project.org/CRAN/refmans/brms/html/mvbrmsformula.html)

**Lesson for drmTMB:** a mixed-family model can be useful without a within-row
association parameter. Later `corpair()` can describe correlation among
compatible latent Gaussian group effects; it should not be labelled a residual
correlation of the observed mixed pair. In particular, brms does **not** solve
the mixed-family residual-correlation problem simply by leaving a binary
residual variance unfixed; that residual-correlation feature is unavailable
for its non-Gaussian mixed-family models.

### GLLVMs: the related many-response solution

GLLVMs do support heterogeneous response families and model residual
cross-response structure through shared latent factors. Conditional on those
factors the responses are independent, and the factor loadings imply a
low-rank covariance contribution \(\Lambda\Lambda^\top\). This is a powerful
strategy when there are many traits because it replaces a large covariance
matrix with a smaller factor representation. It requires likelihood integration
(typically Laplace or variational approximation) and loading-identification
constraints. [Niku et al. (2019)](https://doi.org/10.1371/journal.pone.0216129)

For exactly two traits, a factor model is a useful conceptual comparator but
not the smallest implementation: one latent residual correlation has no
factor-rotation or rank-selection problem, and an exact bivariate Gaussian
copula likelihood is available. The lesson is to retain trait-specific marginal
families and a distinct dependence layer, not to import the many-response
factor engine.

## Latent normal / Gaussian copula for exactly two traits

For marginal CDFs \(F_1(y_1\mid x_1)\) and \(F_2(y_2\mid x_2)\), introduce

\[
(Z_1,Z_2) \sim N\left[0,
  \begin{pmatrix}1 & \eta\\ \eta & 1\end{pmatrix}\right].
\]

Each coordinate is mapped through its own declared marginal distribution.
The fitted \(\eta\) is a **latent-normal correlation**. It is generally
neither the Pearson correlation of \(Y_1,Y_2\) nor a correlation among shared
random effects. Gaussian-copula regression separates marginal regression from
dependence while preserving the selected univariate marginal distributions.
[Masarotto and Varin (2017)](https://www.jstatsoft.org/article/view/v077i08/1107)

| Margin types | Pair likelihood | Exact two-trait computation |
| --- | --- | --- |
| continuous + continuous | Copula density times two marginal densities | Closed-form Gaussian-copula density |
| discrete + discrete | Latent-normal rectangle probability defined by two CDF jumps | Four bivariate-normal CDF corner terms |
| continuous + discrete | Continuous marginal density times a conditional-CDF difference | One-dimensional conditional-normal CDF difference |

The source gives the general discrete likelihood as a multivariate-normal
rectangle integral and explains why high-dimensional discrete data often need
importance sampling. The table is the **two-dimensional special case** of that
formula: exact up to numerical normal-CDF evaluation, not a high-dimensional
GLLVM integral or generic simulated-likelihood engine. This is an inference
from the source's likelihood expression, not a claim for a future many-response
extension. [Masarotto and Varin (2017)](https://www.jstatsoft.org/article/view/v077i08/1107)

Limits remain important. For discrete margins, the copula is a model-based
latent construction rather than a uniquely observable copula; documentation
must interpret \(\eta\) accordingly. Gaussian copulas also impose symmetric
dependence and no tail dependence, so they are not a universal ecological
co-occurrence model.

### Why this is not a silent MCMCglmm threshold model

Both a threshold model and a Gaussian copula use a standardized latent-normal
coordinate for a binary trait. The use of a unit-variance coordinate is an
identification convention, not a change to a declared marginal family. The
two constructions differ in what is held fixed:

| Construction | Binary margin | What is estimated |
| --- | --- | --- |
| MCMCglmm threshold model | Probit/liability margin | Latent GLMM covariance after fixing liability scale |
| `latent_normal()` Gaussian copula | The user-declared Bernoulli margin, including logit if selected | Copula correlation while preserving that margin's CDF exactly |

Thus drmTMB should not copy an MCMCglmm `units` effect merely to obtain a
mixed-pair association. It should use a Gaussian-copula construction when the
package promise is to retain the chosen distributional-regression margin. A
correct joint likelihood can change coefficient estimates relative to fitting
two independent models because it uses pair information; that is legitimate.
It must not silently change a logit margin into a probit liability margin.

## A standard alternative when marginal estimates must not move

The two-stage approach is established in copula modelling as **inference
functions for margins** (IFM), or two-stage maximum likelihood. It first fits
each parametric marginal model separately and then estimates copula dependence
conditional on those fitted margins. It is explicitly studied as an alternative
to full joint maximum likelihood in parametric copula models.
[Ko and Hjort (2019)](https://doi.org/10.1016/j.jmva.2019.01.004)

For drmTMB this would mean:

1. fit the two margin-specific drmTMB models and freeze every marginal
   coefficient, dispersion, and permitted random-effect estimate;
2. calculate the fitted marginal CDF ingredients at each paired observation;
3. estimate only the latent-normal association parameter(s); and
4. obtain uncertainty by a sandwich calculation or a bootstrap that repeats
   both stages.

The first-stage estimates are then exactly the estimates from the two separate
drmTMB marginal fits. The second stage cannot pull a binary slope, count
dispersion, or Gaussian scale toward a value that improves pairwise fit.
Association still uses the fitted margins and is therefore conditional on their
adequacy.

For continuous margins, fitted probability-integral-transform scores can enter
the second stage directly. For binary and count margins, do **not** treat a
single arbitrary residual/PIT value as data: the second-stage likelihood must
use the appropriate Gaussian-copula rectangle probabilities (or an explicitly
validated discrete-data estimating equation). This retains the exact discrete
observation rule while holding first-stage margins fixed. The two-stage idea is
well established; discrete implementation details and uncertainty accounting
remain a separate validation requirement.

This method sacrifices some joint-likelihood efficiency under a perfectly
specified joint model, in exchange for a strong and transparent marginal-model
contract. That trade-off matches an explicit requirement that adding
association must not alter the distributional-regression estimates.

## Direct joint models remain valuable

A direct construction specifies a pmf/density for the observed pair. A
shared-Gamma bivariate negative-binomial model, for example, can represent a
positive shared count intensity and yield a response-scale covariance with a
direct scientific reading. It is not a faster Gaussian copula: it is a
different model and may constrain admissible marginal dispersions. `bzinb`
is an established bivariate-negative-binomial comparator, but does not itself
prove compatibility with drmTMB's `nbinom2()` or a future NB1 parameterization.
[bzinb reference](https://search.r-project.org/CRAN/refmans/bzinb/html/bnb.html)

## Recommendation for the Arc 6 contract

Do **not** require a rho equivalent for every mixed pair, but do provide one
when the question is residual cross-trait association after phylogenetic,
site, individual, or other shared effects. The architecture must also permit
product margins:

```r
biv_pair(gaussian(), nbinom2(), joint = independence())
```

This is a valid joint model with two declared margins and no within-row
association claim. It is appropriate when the marginal regressions are the
question, or when later shared group effects account for the dependence of
interest.

If the scientific question is instead "do the two traits co-occur within an
observation after the declared phylogenetic and other effects?", the relevant
mixed-family model is a latent-normal residual construction. Conditional on
those effects, it estimates \(\eta_{12}=\operatorname{cor}(Z_1,Z_2)\), where
the \(Z\)'s are standard-normal latent residuals mapped into their respective
Gaussian, count, binary, or other declared margins. This is the appropriate
cross-family analogue of Gaussian residual `rho12`.

Keep three names with three meanings:

| Name | Meaning | Scope |
| --- | --- | --- |
| `rho12` | Residual correlation in the existing Gaussian likelihood | `biv_gaussian()` only |
| `corpair()` | Correlation among named latent Gaussian group effects | Later compatible random-effect models |
| `association` | Estimand of a named non-independent within-row construction | Only that pair's declared joint kernel |

Reserve a registered `latent_normal()` constructor, documented as a
Gaussian-copula construction. A future call might be:

```r
biv_pair(
  gaussian(), poisson(),
  joint = latent_normal(association = ~ 1)
)
```

Its public estimand is *latent-normal correlation*, never `rho12` or an
observed-scale residual correlation. Derived response-scale covariance may be
reported at specified covariates, but it is not the primary parameter.

`latent_normal()` is the general future route for Gaussian × count, Gaussian ×
binary, count × binary, and same-family pairs when residual association is the
target. Direct kernels should remain available where they encode a real
process, evaluate more simply, or have a better estimand.

## Bounded implementation choices still requiring owner approval

1. **Architecture first:** two margins with `independence()`, fixed effects
   only. This proves formula dispatch and output semantics, without an
   association claim.
2. **Latent-normal first:** one pair with exact two-response Gaussian-copula
   likelihood, a bivariate-normal-CDF oracle, and a latent-scale estimand.
3. **Direct-kernel first:** an overdispersed count pair after symbolic proof
   that its joint NB construction retains the selected drmTMB margins.

All three defer random/structured effects, partial response pairs, offsets,
weights, `mi()`, `meta_V()`, REML, intervals, capability promotion, and compute
campaigns.

## Bottom line

The user is right: drmTMB is not first in this space. MCMCglmm is the most
relevant ecological precedent for separate trait margins and distinct covariance
layers; brms independently confirms that a universal mixed-family residual
correlation is not standard practice; and Gaussian-copula regression provides a
general latent-normal route that is tractable at exactly two responses. The
best Arc 6 architecture is **composable margins plus an optional named joint
kernel**, with `latent_normal()` a core future kernel and direct kernels
retained when their estimands are stronger.
