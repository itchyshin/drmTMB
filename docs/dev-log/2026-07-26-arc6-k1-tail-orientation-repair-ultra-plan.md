# Arc 6 K1 — Bernoulli × ordinary-NB2 tail-orientation repair ultra-plan

```text
🎯 GOAL

PLATFORM: Codex
DELIVERABLE: a private, independently adjudicated repair of the Bernoulli ×
ordinary-NB2 latent-normal rectangle kernel’s negative-tail orientation, with
a compact deterministic receipt.
HEADLINE: resolve the alpha = -4 production/oracle discrepancy before it can
contaminate the stopped F3 deterministic gate.
IN PARALLEL: freeze the conditional-normal oracle and fixture contract; audit
affected private call sites and failure propagation; independently review the
mathematical, inference, and scope contracts.
DEFER: F3 smoke/refits, F4 calibration or remote compute, public vcov(),
confint(), or profile support, public documentation, capability-ledger movement,
Arc D/F5, other pair classes, association slopes, and direct biv_lognormal()
rho12 inference.
DISCIPLINE: the independent one-dimensional oracle adjudicates every finite
kernel result; unresolved probabilities fail closed; no tolerance relaxation,
clipping, retry, or start-value change may turn a failure into ok. Close with a
retained repair receipt and fresh Noether/Fisher/Rose review before even
reopening F3’s deterministic matrix.
```

## Prior-work sweep receipt

| Surface | Evidence | Finding and forced call |
| --- | --- | --- |
| Repository | `git status --short --branch`; drift/worktree/stash sweep | Resume only the stopped private B×NB2 kernel gap; leave foreign lanes alone. |
| Arc 6 | F0–F2 plan, F1 stop receipt, B×NB2 helper, staged-sandwich test | At `alpha = -4`, production was `-323.376379095663` versus Genz `-323.285855234021`; repair the likelihood kernel before F3. |
| Independent adjudication | Separate one-dimensional conditional-normal calculation | `-323.285855233765`, agreeing with Genz and falsifying production orientation. |
| Sister repos | Targeted DRM.jl, GLLVM.jl, and gllvmTMB sweep | No reusable B×NB2 rectangle implementation; build this narrow gap. |
| Brain | Ask-brain retrieval ladder with raw-vault fallback | D-87 keeps association separate from Arc D/F5; staged eta is distinct from direct rho12. |

## Frozen numerical contract

For `u` in the NB2 CDF interval `[F_N(y - 1), F_N(y)]`, write
`z_N = qnorm(u)`, `t = qnorm(1 - p_B)`, and
`eta = 0.999999 * tanh(alpha)`. The private kernel uses

\[
P(B=1 \mid Z_N=z_N)=\Phi\left(\frac{\eta z_N-t}{\sqrt{1-\eta^2}}\right),
\qquad
P(B=0 \mid Z_N=z_N)=\Phi\left(\frac{t-\eta z_N}{\sqrt{1-\eta^2}}\right).
\]

The CDF-scale interval is bounded even for NB2 count zero. The conditional
probability is evaluated on the log scale and rescaled by its monotone endpoint
maximum before quadrature. The explicit `eta = 0` factorized branch remains
unchanged. Runtime failures remain fail closed; test-only oracle states do not
change the private runtime interface.

## Execution and acceptance

1. Add a test-only latent-interval conditional-normal oracle, deliberately
   oriented opposite the production CDF-scale integral, and pin an explicit
   `mvtnorm::GenzBretz()` rectangle comparator.
2. Replace only the private B×NB2 unbounded-Bernoulli integration orientation.
3. Test eta-zero factorization; both outcomes and signs; NB2 zero, ordinary,
   and high-count cases; `alpha = -4`, `+4`, and `±7`; and existing endpoint,
   quadrature-error, and swap behavior.
4. Require log-probability agreement with the one-dimensional oracle within
   `1e-10`. The defining `alpha = -4` fixture additionally requires a finite
   Genz comparator at the same tolerance; Genz underflow elsewhere is recorded
   as test-only `oracle_unresolved`, not treated as production validation.
5. Preserve the existing F1 derivative tolerances only for derivative-qualified
   cases. A non-finite independent Hessian blocks derivative certification even
   if the point probability is repaired.

## Approval fences

- This plan authorizes only the private kernel, focused tests, retained receipt,
  and review.
- Any finite production/oracle mismatch, unpinned oracle, tolerance change,
  clipping, or unexpected status stops K1 with a negative receipt.
- Only a passing K1 receipt plus fresh Noether/Fisher/Rose review may request a
  revised F3 deterministic-matrix decision.
- A separate written approval remains required for any F3 full-refit smoke.

> Related: [F1 tail-stop receipt](2026-07-26-arc6-f3-f1-tail-stop-receipt.md) ·
> [F0–F2 preparation receipt](2026-07-26-arc6-association-f0-f2-preparation-receipt.md) ·
> [public-inference ultra-plan](2026-07-26-arc6-association-public-inference-ultra-plan.md)
