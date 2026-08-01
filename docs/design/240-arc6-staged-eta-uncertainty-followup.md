# Arc 6 staged eta uncertainty

> **Supersession (2026-08-01).** The public two-stage Godambe covariance now
> supports alpha-scale Wald intervals for every admitted frozen-margin pair
> route whose fit-specific diagnostics pass. This note defines the derived
> eta-scale interface built from that covariance. The stopped full-refit
> bootstrap remains historical provenance, not the implemented method.

## Mathematical contract

For association design row \(x_i^\top\), coefficient vector
\(\boldsymbol\alpha\), and guard \(c = 0.999999\), define

\[
  a_i = x_i^\top\boldsymbol\alpha,
  \qquad
  \eta_i = g(a_i) = c\tanh(a_i).
\]

Let \(\widehat V_\alpha\) be the stored two-stage Godambe covariance. The
link-scale prediction variance and eta-scale delta-method variance are

\[
  \widehat{\mathrm{Var}}(\hat a_i)
    = x_i^\top\widehat V_\alpha x_i,
  \qquad
  \widehat{\mathrm{SE}}(\hat\eta_i)
    = c\{1-\tanh^2(\hat a_i)\}
      \sqrt{x_i^\top\widehat V_\alpha x_i}.
\]

For confidence level \(1-\gamma\), first construct the pointwise link-scale
Wald limits

\[
  L_{a,i}, U_{a,i}
    = \hat a_i \mathbin{\mp}
      z_{1-\gamma/2}\widehat{\mathrm{SE}}(\hat a_i),
\]

then return \(g(L_{a,i})\) and \(g(U_{a,i})\). Transforming the endpoints,
rather than forming a symmetric eta-scale interval, respects the bounded
association range and the monotonicity of \(g\).

## Symbolic-to-implementation alignment

| Symbol | Public syntax | Stored input | Implementation | Verification |
| --- | --- | --- | --- | --- |
| \(\boldsymbol\alpha\) | `confint(object, type = "alpha")` | `association_coefficients` | existing alpha Wald method | coefficient interval tests |
| \(\widehat V_\alpha\) | `vcov(object)` | `alpha_inference$covariance` | existing Godambe adapter | sandwich fixture and S3 tests |
| \(x_i\) | `predict(object, newdata = ...)` | fitted or rebuilt association design | fitted matrix or `drm_pair_association_newdata_design()` | fitted-row and new-data tests |
| \(a_i\) | `predict(..., type = "link")` | \(X_A\hat\alpha\) | matrix product | independent matrix calculation |
| \(\eta_i\) | `predict(..., type = "eta")` | \(c\tanh(a_i)\) | guarded inverse link | direct transform comparison |
| \(\mathrm{SE}(\hat\eta_i)\) | `predict(..., type = "eta", se.fit = TRUE)` | \(X_A\), \(\widehat V_\alpha\) | quadratic form plus delta derivative | independent delta calculation |
| eta confidence limits | `predict(..., type = "eta", interval = "confidence")` | link estimate and SE | transform link-Wald endpoints | bounds and endpoint-transform tests |
| constant eta interval | `confint(object, type = "eta")` | intercept-only design | same prediction kernel | equality with `predict()` interval |

## Public API boundary

`confint(object, type = "eta")` is defined for an intercept-only association,
where eta is a single fitted estimand. When association varies with predictors,
there is no single eta parameter: the method errors with a next step directing
the user to `predict(object, newdata = ..., type = "eta", se.fit = TRUE,
interval = "confidence")`.

`predict()` keeps its historical numeric return when neither `se.fit` nor an
interval is requested. With `se.fit = TRUE`, it returns a list containing
`fit` and `se.fit`; `fit` is a three-column matrix when
`interval = "confidence"`. New-data association prediction remains limited to
the admitted Bernoulli x ordinary-NB2 fixed-effect formula route. The other
four pair classes expose their constant fitted association and uncertainty but
do not admit new-data association formulas.

The eta results inherit the same capability tier, validation-domain warning,
and numerical fail-closed behaviour as the underlying alpha covariance. This
transformation does not create a new coverage claim, simultaneous band,
profile likelihood, or bootstrap interval.

## Historical bootstrap boundary

The stopped full-refit-bootstrap proposal and partial artifacts remain retained
as provenance. They are not used by `vcov()`, `confint()`, or `predict()`. Any
future bootstrap or profile implementation remains a separate method and
requires its own design, evidence, and compute approval.
