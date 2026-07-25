# Arc 6.5 — frozen-margin Bernoulli × Bernoulli association contract

> **Implementation authority.** This contract admits exactly one Arc 6.5
> route: two independently fitted, literal Bernoulli `binomial(link = "logit")`
> margins on the same complete rows, followed by an intercept-only
> latent-normal association fit. It does not authorize any other discrete pair,
> a direct odds-ratio model, or two-stage uncertainty inference.

## Estimand and frozen margins

Let `fit_1` and `fit_2` be separately fitted fixed-effect ML Bernoulli-logit
models. Their fitted probabilities are frozen before the association stage:

\[
p_{ji} = \Pr(Y_{ji}=1\mid x_{ji}),\qquad
c_{ji}=\Phi^{-1}(1-p_{ji}),\qquad j\in\{1,2\}.
\]

Arc 6.5 defines binary observations with latent standard-normal variables:

\[
Y_{ji}=1\{Z_{ji}>c_{ji}\},\qquad
\begin{pmatrix}Z_{1i}\\Z_{2i}\end{pmatrix}\sim
N_2\!\left(0,\begin{pmatrix}1&\eta\\\eta&1\end{pmatrix}\right).
\]

The sole stage-2 parameter is the latent-normal association

\[
\eta=0.999999\tanh(\alpha),\qquad -8\leq\alpha\leq8.
\]

It is not `rho12`, an observed-scale binary correlation, an odds ratio, or a
correlation among random effects. The first-stage coefficients and fitted
probabilities are not refitted, updated, or changed.

## Observation likelihood and stable computation

For (a_{ji}=-\infty) when (y_{ji}=0) and (c_{ji}) otherwise, and
(b_{ji}=c_{ji}) when (y_{ji}=0) and (+\infty) otherwise,

\[
L_i(\eta)=\Pr\{a_{1i}<Z_{1i}\le b_{1i},\ a_{2i}<Z_{2i}\le b_{2i}\}.
\]

The mathematical rectangle identity is

\[
L_i=\Phi_2(b_{1i},b_{2i};\eta)-\Phi_2(a_{1i},b_{2i};\eta)
-\Phi_2(b_{1i},a_{2i};\eta)+\Phi_2(a_{1i},a_{2i};\eta).
\]

Production code must not evaluate this by subtracting nearly equal CDF
corners. It evaluates the observed state directly by deterministic
one-dimensional conditional-normal integration over the corresponding first
coordinate interval. `mvtnorm::pmvnorm()` is an independent test oracle only,
not a runtime dependency.

At η=0, the contribution must equal the product of the two frozen Bernoulli
probabilities. Every four-state probability must be positive and the four
state probabilities must sum to one within numerical tolerance.

## API and output contract

The existing call remains unchanged:

```r
associate_pairs(fit_1, fit_2, kernel = latent_normal(), association = ~ 1)
```

The pair class is `bernoulli_bernoulli`. `fitted()` returns the two frozen
probability vectors in the user-supplied input order. `simulate()` draws one
correlated latent-normal pair per analysis row and applies each margin's own
threshold. `association()` returns only interior or near-boundary `eta`;
`boundary_unresolved` withholds it.

Diagnostics record the observed 2×2 response table, both marginal minority
counts and prevalence ranges, minimum evaluated rectangle mass, optimizer
starts, score, curvature, and boundary status.

## Explicit fence

Both margins must be literal 0/1, logit-link Bernoulli fixed-effect ML fits
with unit weights, no offsets, no missingness, no `mi()`, no `meta_V()`, and
no random or structured effects. The route rejects non-literal/multi-trial
binomial data, unequal rows, same-response pairs, association slopes,
`rho12`, `corpair`, `newdata`, residuals, `vcov`, profiles, intervals, and
confidence limits.

## Symbolic alignment

| Symbol | API / implementation | DGP draw | Recovery extractor | Truth |
|---|---|---|---|---|
| (p_{1i}) | frozen `fit_1` `mu` response prediction | `plogis(beta10 + beta11*x)` | `fitted(assoc)[, 1]` | DGP probability 1 |
| (p_{2i}) | frozen `fit_2` `mu` response prediction | `plogis(beta20 + beta21*x)` | `fitted(assoc)[, 2]` | DGP probability 2 |
| (c_{1i},c_{2i}) | tail-stable `qnorm(p, lower.tail = FALSE)` thresholds | threshold latent draws | rectangle evaluator | derived from probabilities |
| (eta) | `0.999999*tanh(alpha)` | correlated normal pair | `association(assoc)$eta` | declared latent correlation |
| (Y_{1i},Y_{2i}) | observed rectangle state | thresholded latent pair | response-state diagnostics | threshold indicators |

## Evidence ceiling

The owner has authorized a Totoro recovery campaign in the approving Arc 6.5
thread. Before it starts, this source branch must contain a frozen S0 ledger
specifying its sample-size/prevalence/association grid, seeds, all-attempt
accounting, and point-recovery gates. The campaign evaluates point estimates
only. Rare or near-separation/boundary cells are retained as HOLD evidence,
never silently dropped. The stage-2 Hessian conditions on fitted margins, so
this Arc makes no standard-error, interval, coverage, or capability-tier claim.
