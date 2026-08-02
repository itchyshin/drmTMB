# Arc 6 F1D — independent tail-derivative oracle ultra-plan

```text
🎯 GOAL

PLATFORM: Codex
DELIVERABLE: an independently parameterized deterministic derivative oracle for
the fixed-effect complete-pair Bernoulli × ordinary-NB2 staged-alpha rectangle
at the repaired negative tail, and an F1 requalification decision.
HEADLINE: determine whether alpha = -4 has a valid association score and full
association-bearing mixed Hessian, or must remain fail-closed for sandwich use.
IN PARALLEL: symbolic alignment; fixed-node quadrature derivative prototype;
step-refinement matrix; private status/call-site audit.
DEFER: F3 smoke/refits, F4/F5, remote compute, public vcov()/confint()/profile
surfaces, capability ledger, Arc D/F5, association slopes, other pair classes,
and direct biv_lognormal() rho12 inference.
DISCIPLINE: the production CDF-scale five-point ladder and an independently
parameterized latent-z fixed-quadrature central-difference ladder must agree.
No tolerance relaxation, clipping, or conditional-stage curvature fallback.
```

## Six-hour work budget

| Phase | Deliverable | Budget |
| --- | --- | ---: |
| F1D-0 | SHA-pinned symbolic and fixture freeze | 30 min |
| F1D-1 | Independent latent-z quadrature and derivative prototype | 90 min |
| F1D-2 | Three-row, five-step sensitivity matrix | 90 min |
| F1D-3 | Focused implementation and fail-closed classification | 75 min |
| F1D-4 | Noether/Fisher/Rose review, receipt, and after-task audit | 75 min |
| Contingency | One bounded diagnosis/remediation loop | 60 min |

## Symbolic alignment — frozen before implementation

For a row with `q = (a, lambda_B, xi_N, tau_N)`, define

\[
\eta=.999999\tanh(a),\quad s=\sqrt{1-\eta^2},\quad
t=\Phi^{-1}\{1-\operatorname{logit}^{-1}(\lambda_B)\},
\]

with `mu = exp(xi_N)`, `sigma = exp(tau_N)`, and latent-NB2 interval
`[L_N(q), U_N(q)]`. The independent oracle is

\[
\ell(q)=\log\int_{L_N(q)}^{U_N(q)}\phi(z)
\begin{cases}
\Phi\{(\eta z-t)/s\},& y_B=1\\
\Phi\{(t-\eta z)/s\},& y_B=0
\end{cases}dz.
\]

| Symbol | Production implementation | Independent F1D implementation | Required check |
| --- | --- | --- | --- |
| `a`, `eta` | CDF-scale rectangle helper and five-point `h/h/2` ladder | latent-z integrand and fixed-node quadrature | full gradient and every Hessian coordinate |
| `lambda_B`, `t` | Bernoulli threshold in CDF-scale helper | threshold inside latent-z integrand | full mixed Hessian row/column |
| `xi_N`, `tau_N` | NB2 CDF-scale endpoints | independent tail-stable latent endpoints and node transformation | all NB2 and cross-margin Hessian entries |
| `ell(q)` | private row log probability | local tail-stable NB2 endpoints plus 256/512/1024-node Gauss–Legendre quadrature | point agreement with Genz at `1e-10` |

There is no DGP, fit, recovery extractor, or public estimand in F1D: this is
a Tier-1 private numeric-kernel audit only.

## Oracle and fixture contract

- **Production route:** existing CDF-scale row kernel plus current five-point
  `h = 1e-2` and `h/2` stable derivative ladder.
- **Independent route:** a test-local log-CDF/log-survival NB2 endpoint calculation
  (not the production endpoint helper), then `statmod::gauss.quad()` over the
  finite latent interval at 256, 512, and 1024 nodes; a constant normal-density
  log bound for scaling; independently written centred gradient and Hessian stencils at
  `h = 1.25e-3` and `6.25e-4`. It must not call the production rectangle helper,
  `drm_pair_sandwich_derivatives()`, or production CDF-scale integration.
- **Node convergence:** each adjacent quadrature level must agree for the point,
  all four gradient coordinates, and all sixteen Hessian coordinates within
  `max(1e-8, 2e-10 * max(1, abs(compared values)))`. The small absolute floor
  is for central-difference subtraction at the benign interior row, not a
  tail-probability relaxation; otherwise the independent route is
  `independent_step_unstable`.
- **Point comparator:** explicit `mvtnorm::GenzBretz(maxpts = 250000L,
  abseps = 1e-12, releps = 1e-12)`, mandatory at `alpha = -4`.
- **Derivative acceptance:** for every gradient coordinate, use absolute/relative
  `1e-6 + 2e-3 * max(1, |D_P|, |D_O|)`; for every one of the sixteen Hessian
  coordinates, use `1e-6 + 3e-3 * max(1, |D_P|, |D_O|)`.
  The independent `h/h/2` ladder must itself agree at a stricter `2e-6`
  relative scale.

| Row | Role | Required outcome |
| --- | --- | --- |
| `a = 0.22`, `y_B = 1`, `y_N = 3` | retained interior anchor | all four gradient and sixteen Hessian coordinates agree |
| `a = -4`, `y_B = 1`, `y_N = 3` | K1 defect row | finite point, Genz, full gradient, and full Hessian agree |
| `a = +4`, `y_B = 0`, `y_N = 3` | sign/outcome mirror | same full derivative matrix agrees |
| `a = -7`, `y_B = 1`, `y_N = 3` | near-boundary negative control | existing unavailable result retained; never derivative-qualified |

## Test-only status precedence

`protocol_or_input_mismatch` → `endpoint_oracle_unresolved` →
`point_oracle_unresolved` → `production_nonfinite_derivative` →
`production_step_unstable` → `independent_derivative_unresolved` →
`independent_step_unstable` → `independent_route_disagreement` → `F1D_pass`.

Only the production derivative states map to existing runtime unavailable
reasons. All other states are evidence-gate outcomes, never user-facing API
statuses.

## Completion and approval fence

F1D may conclude only with a retained matrix/receipt and fresh
Noether/Fisher/Rose review. A pass permits only a fresh decision to reopen F1;
it does not authorize F3. A negative result preserves a derivative-unqualified
**test-only evidence state**: it does not mutate the production runtime status.
Neither result authorizes refits,
intervals, public inference, or a capability claim.

> Related: [K1 repair receipt](2026-07-26-arc6-k1-tail-orientation-repair-receipt.md) ·
> [F0–F2 preparation receipt](2026-07-26-arc6-association-f0-f2-preparation-receipt.md)
