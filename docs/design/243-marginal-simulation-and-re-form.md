# Marginal Simulation and the `re.form` Contract

## Motivation

The Arc B C++/numerical audit (2026-07-25) found that `simulate.drmTMB()` was
simulating **conditionally** on the fitted random effects. Every family branch
called `predict(object, dpar = ...)` once, hoisted outside its `replicate()`
loop, and `predict.drmTMB()` adds the fitted MAP random effects `û` when
`newdata` is `NULL`. So every replicate reused the *same* `û`; only the residual
noise varied.

This is not a cosmetic defect. It was found by a score-consistency check, not by
reading the code: the first Bartlett identity `E[score(θ₀)] = 0` failed on the
random-effect variance component with `z = 5.36` at 60 replicates, growing to
`z = 10.59` at 200 — growth with replicate count rules out Monte Carlo noise.

Three independent signatures characterised it (25 groups × 8 observations,
200 simulations):

| Signature | Observed | Conditional predicts | Marginal predicts |
| --- | --- | --- | --- |
| correlation of the group-mean pattern across replicate pairs | 0.9852 | ≈ 1 | ≈ 0 |
| correlation of simulated group means with fitted `û` | 0.99996 | ≈ 1 | ≈ 0 |
| SD of the between-group SD across replicates | 0.0437 | ≪ expected | ≈ 0.2257 |

The elimination is what makes the diagnosis trustworthy. An analytic Gaussian
LMM score, evaluated on data drawn *correctly* from the marginal
`N(Xβ, σ²I + sd²ZZ')`, gives `z = −1.55` at 4000 replicates — the identity holds
when random effects are properly re-marginalised. The *same* analytic formula
evaluated on `simulate.drmTMB()`'s output reproduces TMB's `z ≈ 4.6`. And for a
Gaussian random intercept the Laplace approximation is analytically exact, so a
score-identity violation there cannot be a Laplace error. The simulator was the
odd one out, not the density and not the approximation.

## Why it mattered beyond `simulate()`

`drm_bootstrap_confint()` (`R/profile.R`) drives `confint(method = "bootstrap")`
from `stats::simulate()`. With random effects frozen, a parametric bootstrap
never resamples between-group variability, so its intervals are
**anticonservative** — too narrow — for every model with random effects. The
same inheritance reached the campaign runner `inst/sim/R/sim_bootstrap.R`.

**No certified capability-ledger cell was affected.** Checked before the claim
was made: `bootstrap_R = 0` in all 151 evidence artifacts carrying the column,
nonzero only in three `*-bootstrap-smoke-contract.tsv` files at `R = 2`
(plumbing smoke). `mc-0227` used profile intervals (`drm_o3_profile_ci()`),
`mc-0242` used Wald + profile, and the q4 structured-RE grids populated
`wald_coverage`/`profile_coverage` only.

## The contract

`simulate.drmTMB()` takes **`re.form`**, following the lme4/glmmTMB convention:

| Value | Behaviour |
| --- | --- |
| `NULL` (**default**) | **Marginal.** Random effects are redrawn fresh for every replicate. |
| `NA` | **Conditional.** Random effects held at the fitted MAP `û` — the pre-0.7 behaviour. |
| anything else | error |

`confint()` exposes the same choice for the parametric bootstrap as
`bootstrap_re_form`, defaulting to marginal.

**`predict()` is deliberately unchanged.** Conditional prediction at the
original data is correct and conventional — predicting at the observed groups
*should* use their BLUPs. The defect was `simulate()` inheriting that predictor,
not `predict()` producing it.

## What marginal simulation supports

| Structure | Marginal draw |
| --- | --- |
| ordinary grouped intercepts / slopes on `mu`, `sigma` (and bivariate dpars) | supported |
| intra-block correlation, `(1 + x \| g)` | supported |
| labelled cross-parameter correlation, `(1 \| p \| id)` | supported |
| `phylo()`, `spatial()`, `relmat()`, `animal()`, `phylo_interaction()` structured `mu`, `q == 1` | supported |
| structured `mu` correlated across traits, `q > 1` (including multi-endpoint `phylo_interaction()`) | **aborts** |
| correlated covariance-block REs (q4 / qgt2) | **aborts** |
| `corpair()` regression | **aborts** |
| modelled / heteroscedastic RE scale | **aborts** |

**An unsupported structure aborts; it never silently falls back to conditional.**
A silent fallback would recreate the exact defect this change exists to fix —
the user would believe they had marginal draws and receive frozen ones. The
abort names the structure and points at `re.form = NA`.

`phylo_interaction()` at `q == 1` is now supported: its Kronecker precision is
already fully assembled at fit time in the same
`object$model$structured$phylo_mu$precision$precision` slot the other
structured types use, so it takes the identical `drm_fresh_structured_mu_values()`
draw with no new plumbing. A multi-endpoint (`q > 1`) `phylo_interaction()` term
still aborts, for the same untested cross-trait-correlation reason as the other
structured types.

## How structured draws are constructed

For `q == 1`, `object$model$structured$phylo_mu$precision$precision` is the same
sparse `Q_phylo` handed to TMB's `DATA_SPARSE_MATRIX`. The C++ negative
log-likelihood for that case is exactly `u ~ N(0, sd² Q⁻¹)`, matched term by
term against
`0.5·(n·log 2π + 2n·log_sd − log_det_Q + exp(−2·log_sd)·quadratic)`.

The draw is `u = backsolve(R, z) · sd` where `chol(Q) = R` and `z ~ N(0, I)` —
a triangular solve, never an explicit inverse. Values are then mapped to
observations by the **existing** contribution helper (`phylo_mu_contribution()`)
applied to a shallow copy of the fit with fresh values substituted, so
conditional and marginal differ *only* in whether the values are the fitted
BLUPs or a fresh draw.

Covariance recovery was measured rather than assumed:

| Structure | relative Frobenius error (R = 20000) | Bartlett `z` at the optimum |
| --- | --- | --- |
| phylo | 0.0204 | −0.121 |
| spatial | 0.0113 | −0.014 |
| relmat | 0.0199 | −0.517 |
| animal | 0.0207 | −0.459 |
| phylo_interaction | 0.0225-0.0237 (two seeds) | not measured |

`phylo_interaction`'s relative Frobenius error is measured, not assumed, in
`tests/testthat/test-simulate-re-form-phylo-interaction.R` (asserted `< 0.05`
there for CI runtime; 0.0225-0.0237 across two independent seeds at
`R = 20000` in ad hoc verification is the same order of magnitude as the four
already-supported structures above).

## Verification

`tests/testthat/test-score-consistency.R` previously **pinned the defect** with
`expect_gt(abs(z_re), 3)` and a comment recording that a future fix would
require updating it. That expectation is now `expect_lt(abs(z_re), 3)`, and it
measures `z = −0.205`. The flip is the proof: a test written to assert the bug
exists now asserts it does not.

The suite guards against the mistake that produced a spurious `z = 19` during
scoping — the score must be evaluated at `fit$opt$par` (the optimum), not
`fit$obj$par` (the **start** vector) — with an explicit
`expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-3)`.

`tests/testthat/test-simulate-re-form.R` covers the contract itself: the default
is marginal; `re.form = NA` reproduces conditional; a fixed-effects-only model is
identical under both; unsupported structures abort with a matching message;
same-seed reproducibility holds.

`tests/testthat/test-simulate-re-form-phylo-interaction.R` covers
`phylo_interaction()` specifically: marginal simulation no longer aborts;
between-group (pair) variance across replicates is materially larger under
`re.form = NULL` than `re.form = NA`; and the covariance-recovery check above.

## Migration

Code that relied on the old behaviour needs `re.form = NA` — and should ask
whether it *wanted* frozen random effects. Legitimate uses exist (reproducing a
fitted dataset, plumbing smoke tests). Parametric bootstrap and posterior
predictive checks are **not** among them; those need the marginal draw, which is
why the default changed rather than the argument merely being added.

Three in-repo sites now pass `bootstrap_re_form = NA` because they exercise
bootstrap *plumbing* on structures whose marginal draw is not yet implemented.
Each carries a comment recording that the resulting intervals are
anticonservative and that this is not an endorsement.

## Open follow-ups

Marginal draws for the remaining aborting structures — cross-trait `q > 1`
(including a multi-endpoint `phylo_interaction`), covariance blocks, `corpair`,
and modelled RE scale — are a separate arc. Until then those models can be
simulated only with `re.form = NA`, and any bootstrap interval obtained that
way is anticonservative and must not be used as coverage evidence.
