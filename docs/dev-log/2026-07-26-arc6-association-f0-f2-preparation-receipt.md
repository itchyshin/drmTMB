# Arc 6 association F0–F2 preparation receipt

**Status:** F0–F2 planning evidence only (2026-07-26). This receipt records
the preparation for one candidate only: fixed-effect ML, complete-pair,
literal Bernoulli × ordinary-NB2, `association = ~ 1`. It neither authorizes
F3, F4, F5, a capability claim, nor public inference.

> **Later deterministic update (2026-07-26).** The initial F1D `alpha = -4`
> stop was retained as negative evidence. The subsequent independent-oracle
> F1E/F1M work repaired the private tail orientation and completed the full
> deterministic matrix as `F1_PASS`; see
> `docs/dev-log/2026-07-26-arc6-f1m-deterministic-qualification-receipt.md`.
> No F3 smoke has run. This original F0–F2 receipt remains the preparation
> record, while the F1M receipt is the authoritative deterministic disposition.

## F0 — frozen method contract

The estimand is the single staged association coefficient `alpha` on the
unconstrained link scale, with derived latent-normal association

\[
  \eta = 0.999999\tanh(\alpha).
\]

It is not `rho12`, observed-scale correlation, a joint-MLE parameter, or a
conditional-stage-two estimand. The two margin parameter blocks are

\[
  \psi_B = \beta_B,\qquad
  \psi_N = (\beta_N, \gamma_N),\qquad
  \theta=(\psi_B,\psi_N,\alpha),
\]

where the Bernoulli margin is literal logit Bernoulli and the ordinary-NB2
margin has `log(mu) = X_N beta_N`, `log(sigma) = Z_N gamma_N`, and
`size = sigma^(-2)`. The frozen estimating equations are the row score
`u_i = (s_Bi, s_Ni, s_Ai)` and

\[
 A=-n^{-1}\sum_i \partial u_i/\partial\theta^\top,\qquad
 B=n^{-1}\sum_i u_i u_i^\top,\qquad
 \widehat{\mathrm{Var}}(\hat\theta)=n^{-1}A^{-1}BA^{-\top}.
\]

`A` is lower block triangular, while `B` retains all uncentred paired-row
cross-score products. In particular, the association row retains its mixed
derivatives with both margin blocks. The delta map may be audited only as
`d eta / d alpha = 0.999999 sech(alpha)^2`; it is not a public standard error.

### Immutable source and fixture record

| Item | Frozen value | Verification |
| --- | --- | --- |
| Private-engine merge | `1834734a` (PR #846) | Current preparation tip is documentation-only relative to the B×NB2 engine. |
| Engine source | `R/associate-pairs-sandwich.R` blob `d090f67b74bf5dfee6baa4396a8f45a3c977d6fd` | Identical at `1834734a` and `ae8d6f5b`. |
| B×NB2 deterministic fixture/oracle | `tests/testthat/test-associate-pairs-staged-sandwich.R` blob `b66ec96f520e8d5e815c77037a08afb2b4feb44e` | Identical at `1834734a` and `ae8d6f5b`. |
| Numeric derivative control | five-point link-scale stencil `h = 1e-2`, checked against `h/2`; relative/absolute tolerances `1e-3`/`1e-6` | Defined only by `drm_pair_sandwich_control()`. |
| Linear-system guard | `rcond(A) > 1e-10`; symmetry tolerance `1e-8` | Failure is unavailable, never a fallback covariance. |
| Independent-oracle runtime | R 4.6.0; `mvtnorm` 1.4.1; `numDeriv` 2016.8.1.1 | Read locally on 2026-07-26; freeze these versions for the approved deterministic audit. |

The fixture's independent **numerical** oracle is `mvtnorm::pmvnorm()` for the
Bernoulli × NB2 latent-normal rectangle, differentiated in the test through
`numDeriv::grad()` and `numDeriv::hessian()`. It is not an exact symbolic
oracle. The frozen audit calls `pmvnorm(..., sigma = ..., algorithm =
GenzBretz(), keepAttr = TRUE, seed = NULL)` and uses the documented
`numDeriv` Richardson defaults for `grad()` and `hessian()`; those oracle
settings are distinct from the production five-point `h`/`h/2` ladder. The
production kernel separately uses the tail-stable rectangle integration in the
B×NB2 contract. Neither numerical oracle licenses resampling or
sampling-validity claims.

## F1 — private-surface and deterministic-audit disposition

### Audit result — source surface passes; deterministic matrix is not yet run

The candidate is genuinely private. The only router is the unexported
`drm_pair_general_eta_sandwich()`; it selects the B×NB2 adapter but has no
call site in `associate_pairs()` or a public method. The public object continues
to abort for `vcov()`, `profile()`, and `confint()`. No public documentation,
NAMESPACE entry, capability-ledger row, or covariance attachment was found.

The existing B×NB2 test file verifies: analytic NB2 scores and bread against
independent numerical derivatives; a rectangle score and all mixed derivatives
against `mvtnorm`; complete assembly with full meat and lower-triangular bread;
input-order invariance; the private slope diagnostic; and fail-closed public
methods. It also forces representative provenance, frozen-margin, association
boundary, derivative-step, and bread-conditioning failures.

### Failure taxonomy to preserve and extend before F3

| Class | Current machine-readable outcome | F3/F4 interpretation |
| --- | --- | --- |
| Ineligible or unresolved association | `association_unresolved` | Outer attempt unavailable; retain the stage-two status. |
| Frozen-input mismatch | `provenance_mismatch`, `design_row_mismatch`, `coefficient_design_mismatch`, `frozen_margin_mismatch` | Protocol failure: exclude neither attempt nor cause; investigate/reject the run configuration. |
| Association edge | `association_boundary` | Unavailable, not a finite SE or interval endpoint. |
| Row-kernel/derivative failure | `association_nonfinite_derivative`, `association_step_unstable` | Unavailable; preserve row diagnostics and the failed step ladder. |
| Sandwich linear algebra | `bread_or_meat_unstable`, `bread_solve_failure`, `covariance_unstable`, `eta_delta_unstable` | Unavailable; count in all-attempt availability denominator. |
| Margin/refit failure (not yet exercised by a refit campaign) | predeclare a stable two-stage status record | Must be counted before association fitting; never backfilled with frozen fitted margins. |

Before any F3 smoke, Noether must confirm the displayed equations, parameter
order, scaling, and delta map against the pinned source; F1 must add no new
code merely to manufacture a pass. The required deterministic matrix has not
yet been executed: the existing fixture supplies a positive-interior check,
swap check, and boundary rejection, but does not pin separate zero, negative,
tail, and near-boundary numerical-oracle fixtures. Its test design must be
locked, and any test execution separately approved, before F1 can be called
passed.

### Predeclared deterministic-audit matrix (design only; not executed)

The approved F1 fixture addition must hold the existing finite Bernoulli and
ordinary-NB2 row parameters fixed and compare the production row log-probability,
gradient, and Hessian with the pinned numerical oracle. It must add exactly the
following cases before any F3 request:

| Case | Association link value | Required result |
| --- | --- | --- |
| Interior | `alpha = 0.22` | Existing positive-interior agreement remains the reference. |
| Zero | `alpha = 0` | Finite agreement at independence; no sign convention is inferred from the interior case. |
| Sign pair | `alpha = -0.35`, `+0.35` | Each finite result agrees with the oracle; the two cases are reported separately. |
| Tail | `alpha = -4`, `+4` | Each result either agrees at predeclared tolerance or returns the existing fail-closed derivative status; no clipping or tolerance relaxation. |
| Swap | Existing response/margin-order swap fixture | Log probability and derivative roles remain invariant under the documented exchange. |
| Near boundary | `alpha = -7`, `+7` | Record finite oracle agreement only if both derivative ladders are stable; otherwise require `association_step_unstable` or another existing unavailable status. |

The test change must pin its exact row outcomes and numerical tolerances in the
fixture itself. This table is a design lock, not evidence that any new fixture
has passed; implementation and test execution remain outside F0–F2 and require
the separate F3 approval fence.

Here, **intercept-only means the association design only**: `X_A = 1` and a
single `alpha`. The two fitted margin formulas may have their already-admitted
fixed effects; F3 must state their exact formulas and use the same frozen
domain. It does not silently reduce the margin models to intercept-only.

## F2 — literature and comparator design

### What the literature supports

The staged construction is an inference-functions-for-margins (IFM) / two-stage
copula estimator, not a joint likelihood. Joe's efficiency analysis and Ko and
Hjort's model-robust treatment support an asymptotic sandwich/Godambe
calculation for a two-stage copula estimator; they do not validate this
finite-sample discrete rectangle implementation. The `copula` package's IFM
documentation makes the same practical distinction: fitting a copula to
parametric pseudo-observations while using the usual ML variance omits the
unknown margin-estimation error and underestimates variance. That is a direct
negative comparator for conditional stage-two curvature, not a reusable
variance implementation for this mixed discrete pair.

Discrete margins are a distinct difficulty: the relevant likelihood is a
rectangle probability, not a continuous pseudo-observation density. The
current independent numerical rectangle oracle is therefore the correct numerical comparator;
continuous-only pseudo-observation tools must not be used as an inferential
oracle. The sources above establish the two-stage/Godambe principle, but none
directly validates this Bernoulli × ordinary-NB2 rectangle implementation;
that discrete-rectangle statement is a design argument grounded in the pinned
kernel and must be tested in F1/F3/F4, not presented as literature-derived
finite-sample evidence.

### Comparator and decision design

| Role | Comparator | Admissible use | Explicitly inadmissible use |
| --- | --- | --- | --- |
| Numerical oracle | `mvtnorm::pmvnorm()` independent numerical rectangle used by the frozen fixture | F1 row log-probability, score, and Hessian agreement | Sampling-validity, SE, or interval calibration. |
| Negative inferential comparator | `copula::fitCopula()` IFM-style parametric pseudo-observation workflow | Demonstrate why a conditional margin-ignored variance is not the target | Fit B×NB2 rectangles, validate this estimator, or supply public SEs. |
| F3 provenance comparator | None: F3 is one attempt and has no empirical sampling comparator | Verify only fresh-full-refit provenance and all-attempt status accounting | SE calibration, empirical SD, recovery, coverage, or any interval assessment. |
| Required F4 comparator | Outer-simulation empirical SD, then a separately named full-two-stage interval procedure | Calibrate the private Godambe `alpha` SE against outer empirical SD before assessing the chosen interval method | Conditional association-only refits, the stopped shards, or any `rho12` result. |

The first F3 protocol must be one small B×NB2 association-intercept-only
all-attempt prototype, with fixed covariates, explicitly named margin formulas,
generated margins and latent-normal rectangles, and a log containing every
margin and association status. Its purpose is to verify full-refit provenance
and availability accounting only. It may not report empirical SD, SE
calibration, recovery, coverage, or interval behaviour; outer empirical-SD
calibration is F4-only.

F4 must choose the public target and interval experiment before execution:
`alpha` is the primary estimand; `eta` is optional and derived by delta method.
It must separately record point-estimate, alpha-SE, eta-delta-SE, and
interval-construction availability. It must name whether the candidate is an
alpha Wald interval, a full-refit percentile interval, or two separately
calibrated methods; no generic “percentile behavior” label is sufficient.
Totoro or DRAC is the compute target for F4; GitHub Actions is prohibited.

The nested denominator contract is: (1) attempted outer datasets; (2)
valid-protocol outer datasets; (3) successful two-stage point fits; (4)
available Godambe quantities, separately for alpha and derived eta; and (5)
available intervals, with all inner refit attempts retained for each outer
dataset when a bootstrap interval is being studied. A DGP/harness or
frozen-provenance mismatch quarantines the campaign rather than entering a
method denominator. Primary coverage, if an interval is selected, is intervals
containing truth divided by all valid-protocol outer datasets; conditional
coverage among interval-available fits is secondary and availability is
reported separately. The status schema must use mutually exclusive precedence:
DGP/harness, Bernoulli margin, NB2 mean, NB2 dispersion, association
optimisation, rectangle/integration, sandwich, delta, then interval
construction. Do not reintroduce a “retained” denominator.

### Primary sources consulted

- Joe (2005), *Asymptotic efficiency of the two-stage estimation method for
  copula-based models*, Journal of Multivariate Analysis 94, 401–419,
  [bibliographic record](https://ideas.repec.org/a/eee/jmvana/v94y2005i2p401-419.html).
- Ko and Hjort (2019), *Model robust inference with two-stage maximum
  likelihood estimation for copulas*, Journal of Multivariate Analysis 171,
  362–381, [article record](https://doi.org/10.1016/j.jmva.2019.01.004).
- Shih and Louis (1995), *Inferences on the association parameter in copula
  models for bivariate survival data*, Biometrics 51, 1384–1399,
  [bibliographic record](https://pure.johnshopkins.edu/en/publications/inferences-on-the-association-parameter-in-copula-models-for-biva-3/).
- `copula` package, [`fitCopula()` documentation](https://rdrr.io/cran/copula/man/fitCopula.html),
  inspected specifically for its IFM and variance caveat.

No novelty or finite-sample-validity claim follows from this review.

## Exact approval fence

**F3 requires Shinichi's fresh written approval of all of the following:** the
SHA-pinned F0 contract; Noether's equation/derivative-order review; Fisher's
approval of this estimand, comparator, and failure taxonomy; Rose's agreement
that all public methods and claims remain unavailable; the completed F1M
deterministic receipt; and a one-cell, all-attempt local full-refit smoke
protocol that names its data-generating parameters, seed policy, status schema,
stopping rule, and retained output.

That approval authorizes only F3's local smoke. It does **not** authorize F4
simulation, bootstrap calibration, Totoro/DRAC work, a ledger change, or public
API work.

**F4 requires a second, separate approval** after F3 has shown non-empty,
provenance-correct full refits: a pre-registered grid, outer/inner counts,
all-attempt and availability denominators, coverage/MCSE criteria, a chosen
Totoro-or-DRAC runbook, and confirmation that the stopped `24 × 200 × 399`
shards remain excluded.

**F5 requires a third, separate public-product decision:** completed F4
evidence reviewed by Fisher, Noether, and Rose; a narrow claim that names only
B×NB2 intercept-only; a fail-closed public API/error design; explicit
non-transfer to slopes, other pairs, RE/missingness/weights/offsets/REML, and
`biv_lognormal()` `rho12`; and Shinichi's approval to expose it. No earlier
approval implies F5.

## Out of scope retained

Arc D's F5 clamp/profile-identifiability work remains Claude-owned and untouched. Direct
`biv_lognormal()` `rho12` inference remains a separate exact-likelihood route.
All other pair classes, association slopes, random/structured effects,
missingness, weights, offsets, REML, public `vcov()`/`confint()`/profile,
capability-ledger movement, simulation, full refits, and remote compute remain
deferred.
