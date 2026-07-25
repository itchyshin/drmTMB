# Arc 6 staged-eta candidate Godambe variance

## Status and boundary

This is a developer-only implementation contract for the fixed-effect,
complete-pair literal-Bernoulli × ordinary-NB2 `associate_pairs()` estimator.
It supplies neither a public standard error nor a Wald, profile, bootstrap,
`vcov()`, or `confint()` interface. A separately approved, small full-refit
comparison is required before any product decision about public uncertainty.

The direct `biv_lognormal()` `rho12` route is an exact joint likelihood and is
not evidence for this frozen-margin estimand.

## Estimating equations

Let \(\theta=(\beta_B,\beta_N,\gamma_N,\alpha)\), where the Bernoulli
margin has \(\operatorname{logit}(p_i)=X_{Bi}\beta_B\), the NB2 margin has
\(\log(\mu_i)=X_{Ni}\beta_N\) and
\(\log(\sigma_i)=Z_{Ni}\gamma_N\), and the association link is

\[
 a_i=X_{Ai}\alpha,\qquad \eta_i=0.999999\tanh(a_i).
\]

The stacked row score is

\[
u_i(\theta)=\{s_{Bi}(\beta_B)^\top,
s_{Ni}(\beta_N,\gamma_N)^\top,
s_{Ai}(\alpha;\beta_B,\beta_N,\gamma_N)^\top\}^\top.
\]

The first two components are the ordinary marginal likelihood scores. The
association component is the derivative of the Bernoulli × NB2 latent-normal
rectangle log probability with respect to \(a_i\), multiplied by \(X_{Ai}\).
It includes the derivative of the numerical `0.999999*tanh()` map.

With row averages,

\[
A=-n^{-1}\sum_i \partial u_i/\partial\theta^\top,\qquad
B=n^{-1}\sum_i u_i u_i^\top,\qquad
\widehat{\operatorname{Var}}(\hat\theta)=n^{-1}A^{-1}BA^{-\top}.
\]

The bread is lower block triangular: the marginal equations do not depend on
\(\alpha\), while the association equation retains derivatives with respect
to \(\beta_B,\beta_N,\gamma_N\). The empirical meat retains all paired-row
cross-score products. The existing conditional stage-2 curvature is not used.

For a fitted row, the candidate eta variance uses the delta method,

\[
\widehat{\operatorname{Var}}(\hat\eta_i)=
[0.999999\operatorname{sech}^2(a_i)]^2X_{Ai}^\top
\widehat{\operatorname{Var}}(\hat\alpha)X_{Ai}.
\]

## Numerical contract and failures

The private helper uses analytic marginal scores and a five-point link-scale
stencil for the rectangle score and its mixed derivatives in
\((a,\operatorname{logit}p,\log\mu,\log\sigma)\). It repeats this at half
the step and withholds the candidate variance if the derivative ladder is
unstable. It also withholds output for unresolved association fits, finite
`[-8, 8]` coefficient-bound hits, numerical rectangle failures, mismatched
frozen margins, non-finite matrices, or a bread reciprocal condition number no
larger than `1e-10`.

These diagnostics are development checks, not a confidence-interval method.

## Freeze gate

Before any full-refit resampling, freeze the code, fixtures, numerical
tolerances, design record, and failure semantics; then obtain independent
Noether, Fisher, and Rose review plus fresh owner approval. The former
24 × 200 × 399 bootstrap campaign remains stopped and its partial shards remain
provenance only.
