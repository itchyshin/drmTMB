# After Task: Gaussian Variational Approximation Pre-Code Gate

## Goal

The project owner asked to add a variational approximation. Scoped with them:
**purpose = accuracy where Laplace is biased**; **flavor = recommend**.

## Recommendation And Why

Recommended a **Gaussian variational approximation (GVA)** over the random
effects as the first slice. The best-documented place Laplace is *biased* (not
just imprecise) is non-Gaussian random-intercept models with small clusters
(Bernoulli / low-count Poisson), where it underestimates the random-effect
variance. GVA maximizes an ELBO with a Gaussian `q(u) = N(m, S)` (KL-minimizing,
not mode-based), which is provably closer there and is the natural extension of
the existing TMB joint-likelihood objective. A Gaussian `q` still cannot capture
genuine skewness; a skew/expansion `q` is a documented Tier-2 follow-up.

## Implemented

- `docs/design/160-gaussian-variational-approximation-gate.md`: the design gate
  (objective, TMB plug-in point via an `inference_method` flag, `S`
  parameterization, `drm_control(inference = "gva")` API, first-slice scope,
  ADEMP validation against a gold standard, standing review).
- Tier G + a parallel working-order item in
  `docs/design/157-capability-completion-worklist.md`.

## Honest Constraints

- This is **design-only**. No inference-engine code exists; Laplace remains the
  sole implemented path. The implementation needs a local TMB build/test loop
  and so is Codex/local-R work (Phase A category), not doable in this sandbox.
- It is architecturally significant: it adds a second integration method to a
  package whose identity is fast TMB Laplace. The gate keeps Laplace the default
  and defines a deliberately small first slice with a gold-standard validation
  requirement.

## Next

Local-R session implements the first slice per doc 160 and validates GVA reduces
the Laplace variance-component bias against a gold standard before any accuracy
claim. Tracked in the GVA implementation issue and the local-R handoff #491.
