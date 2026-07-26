# Arc 6 private staged-association sandwich contract

## Status and boundary

This is a developer-only implementation contract for a reusable, fixed-effect,
complete-pair `associate_pairs()` sandwich assembler and its five admitted
latent-normal pair adapters: Gaussian × Bernoulli, Gaussian × ordinary-NB2,
Bernoulli × Bernoulli, Bernoulli × ordinary-NB2, and ordinary-NB2 × ordinary-NB2.
It supplies neither a public standard error nor a Wald, profile, bootstrap,
`vcov()`, or `confint()` interface. The landed Bernoulli × ordinary-NB2 helper
is the regression reference; shared architecture is not shared validation.
The unexported `drm_pair_general_eta_sandwich()` router selects only these five
private adapters and is not called by `associate_pairs()` or any public method.
A separately approved, small full-refit comparison is required before any
product decision about public uncertainty.

The direct `biv_lognormal()` `rho12` route is an exact joint likelihood and is
not evidence for this frozen-margin estimand.

## Estimating equations

Let \(\theta=(\psi_1,\psi_2,\alpha)\), where \(\psi_j\) is the complete
link-scale parameter vector for margin \(j\), and let the association link be

\[
 a_i=X_{Ai}\alpha,\qquad \eta_i=0.999999\tanh(a_i).
\]

The stacked row score is

\[
u_i(\theta)=\{s_{1i}(\psi_1)^\top,
s_{2i}(\psi_2)^\top,
s_{Ai}(\alpha;\psi_1,\psi_2)^\top\}^\top.
\]

The first two components are the ordinary marginal likelihood scores. The
association component is the derivative of the pair-specific latent-normal
row log density or rectangle log probability with respect to \(a_i\),
multiplied by \(X_{Ai}\). It includes the derivative of the numerical
`0.999999*tanh()` map. The estimating-equation coordinate is \(\alpha\),
not \(\eta\): no change-of-variables Jacobian is added to the likelihood.

With row averages,

\[
A=-n^{-1}\sum_i \partial u_i/\partial\theta^\top,\qquad
B=n^{-1}\sum_i u_i u_i^\top,\qquad
\widehat{\operatorname{Var}}(\hat\theta)=n^{-1}A^{-1}BA^{-\top}.
\]

The bread is lower block triangular:

\[
A=\begin{pmatrix}H_1&0&0\\0&H_2&0\\C_1&C_2&H_A\end{pmatrix}.
\]

The marginal equations do not depend on \(\alpha\), while the association
equation retains derivatives with respect to both margin vectors. The empirical
meat retains all uncentred paired-row cross-score products. The existing
conditional stage-2 curvature is not used.

For a fitted row, the candidate eta variance uses the delta method,

\[
\widehat{\operatorname{Var}}(\hat\eta_i)=
[0.999999\operatorname{sech}^2(a_i)]^2X_{Ai}^\top
\widehat{\operatorname{Var}}(\hat\alpha)X_{Ai}.
\]

## Parameter, role, and provenance contract

Mixed-family adapters use a canonical family-role order, independent of caller
order: Gaussian before Bernoulli or NB2, and Bernoulli before NB2. Repeated
families use `L = fit_1` and `R = fit_2` exactly; a caller-side swap is a block
permutation, never a relabelling shortcut. All private covariance labels include
family, side where repeated, distributional parameter, and design-column name.

| Pair class | Canonical private parameter order |
| --- | --- |
| Gaussian × Bernoulli | \(\beta_{G\mu},\gamma_{G\sigma},\beta_B,\alpha\) |
| Gaussian × ordinary-NB2 | \(\beta_{G\mu},\gamma_{G\sigma},\beta_N,\gamma_{N\sigma},\alpha\) |
| Bernoulli × ordinary-NB2 | \(\beta_B,\beta_N,\gamma_{N\sigma},\alpha\) |
| Bernoulli × Bernoulli | \(\beta_{B,L},\beta_{B,R},\alpha\) |
| ordinary-NB2 × ordinary-NB2 | \(\beta_{N,L},\gamma_{N,L},\beta_{N,R},\gamma_{N,R},\alpha\) |

The local coordinates are Gaussian \(m=X_\mu\beta\) and
\(\tau=Z_\sigma\gamma=\log\sigma\); Bernoulli
\(\lambda=X_\mu\beta=\operatorname{logit}p\); and ordinary-NB2
\(\xi=X_\mu\beta=\log\mu\), \(\tau=Z_\sigma\gamma=\log\sigma\),
\(r=\sigma^{-2}\). Every adapter must verify the frozen response vector,
fitted values, coefficient/design alignment, data hash, original-row vector,
response names/types, association-design values and column order. It must
retain the existing fixed-effect ML, unit-weight, no-offset, complete-pair,
no-random-effect eligibility checks.

## Numerical contract and failures

The common service uses analytic marginal scores/bread and a five-point
link-scale stencil for association scores and mixed derivatives. It repeats the
stencil at half the step and withholds the private result if that ladder is
unstable. Each adapter owns an independent row-kernel oracle: normal density ×
conditional Bernoulli or NB2 interval for continuous pairs, and an independent
bivariate-normal rectangle for discrete pairs.

Invalid API inputs retain their existing informative errors. Eligible but
numerically unusable fits return `list(status = "unavailable", reason = ...)`
with stable reasons for unresolved association fits, finite `[-8, 8]`
coefficient-bound hits, frozen-margin/provenance mismatch, rectangle failure,
non-finite matrices, derivative instability, or insufficient bread conditioning.
No adapter silently substitutes conditional curvature or a different row order.

These diagnostics are development checks, not a confidence-interval method.

## Deterministic gate and freeze gate

Before validation, every adapter must pass deterministic margin-score/bread and
row-kernel gradient/Hessian oracle checks, including mixed derivatives; eta
negative/zero/positive interior checks; eta-zero factorization; intercepts for
every pair and the admitted Bernoulli × ordinary-NB2 slope; response swaps;
and repeated-family block-label permutations. The failure matrix must cover
malformed inputs, incomplete or mismatched frozen data, boundaries, derivative
instability, and rank deficiency while retaining public-inference absence.

Before any full-refit resampling, freeze the code SHA, fixtures, oracle source,
numerical tolerances, parameter/label order, and failure taxonomy; then obtain
independent Noether, Fisher, and Rose review plus fresh owner approval. The
former 24 × 200 × 399 bootstrap campaign remains stopped and its partial shards
remain provenance only. No ledger or capability status changes accompany this
engineering work.
