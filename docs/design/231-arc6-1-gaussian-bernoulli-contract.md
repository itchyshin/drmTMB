# Arc 6.1 Gaussian × Bernoulli frozen-margin contract

Arc 6.1 adds one deliberately narrow post-fit association object. It does not
add a `biv_*()` family, change `drmTMB()` fitting, or broaden the established
meaning of `rho12`.

Two already fitted fixed-effect margins are supplied on exactly the same
complete rows. Their estimates and fitted response-scale values are frozen.
`associate_pairs()` then estimates a single latent-normal association parameter
only. Consequently, this is a conditional-on-margins point estimate, not a
joint re-estimation and not a marginal observed-scale correlation.

## Statistical contract

For each paired row, the Gaussian margin supplies frozen
\(\mu_i,\sigma_i>0\), and the literal-Bernoulli logit margin supplies frozen
\(0<p_i<1\). Let

\[
z_i = \frac{y_{Gi}-\mu_i}{\sigma_i},\qquad
c_i = \Phi^{-1}(1-p_i),\qquad
\eta = 0.999999\tanh(\alpha).
\]

The Gaussian residual and latent Bernoulli liability are standard normal with
correlation \(\eta\). The observed binary response is one when the liability
exceeds \(c_i\). Hence

\[
r_i = \Pr(Y_{Bi}=1\mid Z_{Gi}=z_i)
= 1-\Phi\!\left(\frac{c_i-\eta z_i}{\sqrt{1-\eta^2}}\right),
\]

and the exact frozen-margin joint log likelihood is

\[
\ell(\alpha)=\sum_i \left[
\log f_N(y_{Gi};\mu_i,\sigma_i)
+ y_{Bi}\log r_i+(1-y_{Bi})\log(1-r_i)
\right].
\]

The Gaussian-density contribution is constant in \(\alpha\), but is retained
in the evaluator and this contract so the joint density is explicit. The
bounded optimisation scale is \(\alpha\in[-8,8]\); the public `eta` is withheld
when the optimum is boundary-unresolved. `abs(eta) >= 0.995` is retained as a
near-boundary diagnostic, never an ordinary inference claim.

## Symbolic-to-implementation alignment

| Symbol in this contract | Package object / code | Generative draw used by `simulate()` | Extractor or diagnostic | Truth / ceiling |
| --- | --- | --- | --- | --- |
| \(Y_G\), \(\mu_i\), \(\sigma_i\) | Gaussian `drmTMB` margin; frozen `components$gaussian_y`, `gaussian_mu`, and `gaussian_sigma` | `y_g = mu + sigma * z_g` | `fitted()` returns frozen `mu`; stored margin snapshot records `sigma` | Fixed-effect standard Gaussian margin only |
| \(Y_B\), \(p_i\) | Literal 0/1 logit-binomial margin; frozen `components$binary_y` and `binary_p` | `y_b = 1(z_b > qnorm(1 - p))` | `fitted()` returns frozen `p`; response-pattern diagnostic retained | Bernoulli only; no `cbind()` trials |
| \(Z_G\) | Standardized Gaussian response `z = (y_g - mu) / sigma` | `z_g = rnorm(n)` | Used directly by the conditional likelihood | Exact under the declared Gaussian margin |
| \(Z_B\) and \(c_i\) | `threshold = qnorm(1 - binary_p)` | `z_b = eta * z_g + sqrt(1 - eta^2) * rnorm(n)` | Threshold is implicit in `drm_pair_gaussian_bernoulli_loglik()` | Latent liability is an association device, not a re-fitted Bernoulli model |
| \(\alpha\), \(\eta\) | `drm_pair_fit_eta()` with `eta_internal = 0.999999 * tanh(alpha)` | The same `eta_internal` couples the two normal draws | `association()` exposes `eta`; multistart, score, curvature, and boundary flags are retained | Intercept-only `association = ~ 1`; point estimate plus diagnostics |
| \(r_i\) | Stable normal tail / CDF evaluation in `drm_pair_gaussian_bernoulli_loglik()` | Implied by the normal-threshold draw | Normalisation and zero-association tests independently integrate the conditional probability | Continuous-discrete exact likelihood |
| \(\ell(\alpha)\) | `drm_pair_gaussian_bernoulli_loglik()` and `nlminb()` multistart optimisation | No recovery DGP is asserted | Stored `logLik`, convergence, score, curvature, and starts | No standard error, interval, profile, coverage, smoke, or recovery claim |

## Public API and exclusions

```r
assoc <- associate_pairs(
  gaussian_fit,
  binary_fit,
  kernel = latent_normal(),
  association = ~ 1
)
association(assoc)
```

Input order is retained for `fitted()`, `predict()` (frozen rows only), and
`simulate()`, while the Gaussian and Bernoulli roles are detected internally.
The object snapshots margin calls, formulas, coefficients, response values,
fitted values, original row identifiers, and fingerprints. It rejects non-ML
or REML fits, unequal or incomplete analysis rows, weights, offsets, known
covariance, random/structured effects, nonstandard Gaussian margins, and
nonliteral Bernoulli inputs.

`rho12()`, `corpairs()`, `sigma()`, `vcov()`, and `profile()` deliberately
error for this object. The `corpair()` formula marker is a separate interface.
These methods would imply an unsupported Gaussian-residual, random-effect, or
uncertainty interpretation. A future Arc must separately
validate any two-stage uncertainty method, association covariates, new-data
association prediction, or additional margin class.

## Validation boundary

The focused test file checks frozen-margin provenance, order symmetry, the
\(\eta=0\) product-margin case, numerical normalisation and Bernoulli
marginalisation, the near-boundary diagnostic, and clear rejection errors.
Those checks establish the package contract only. They do not constitute a
smoke, recovery campaign, capability promotion, interval/coverage result, or
claim for Gaussian × NB2 and later pair classes.

<!-- graph-footer -->
> Related: [Arc 6.1 ultra-plan](../dev-log/2026-07-23-arc6-margin-first-latent-normal-ultra-plan.md) · [Arc 6 series overview](230-arc6-bivariate-series-overview.md) · [Likelihoods](03-likelihoods.md)
