# DECISION — drmTMB will NOT implement the GVA; Design 160 stays design-only

**Date:** 2026-08-03 · **Decided by:** Shinichi · **Status:** CLOSED, not deferred.

`docs/design/160-gaussian-variational-approximation-gate.md` remains a **pre-code design gate
that is not being taken up**. No inference code, no engine switch, no fitted GVA support. TMB's
Laplace approximation (plus the AGHQ work already in flight) remains drmTMB's inference path.

This note exists so the decision is on the record with its evidence, rather than the gate
sitting open indefinitely and being re-scoped by a future session that does not know it was
considered and declined.

## Why this came up

A gllvmTMB session on 2026-08-03 was redirected here by the maintainer. gllvmTMB has spent
roughly three weeks building and measuring a variational engine (its Design 108 programme), and
that evidence was carried over to inform a drmTMB GVA implementation. On reading it, the
maintainer declined the work.

## The evidence, and why it points the same way

All numbers below are **measured on gllvmTMB's engine**, not drmTMB's, and are cited as such.
Full detail: `2026-08-03-claude-handover-gva-implementation.md` (companion note).

1. **The accuracy gain did not materialise where it was expected.** gllvmTMB's Design 72
   (Phase 1, PR #431) found that wherever the model was identifiable (n ≥ 30), **VA matched
   Laplace point estimates to ~2 significant figures**. VA was a genuinely convergence-robust
   fallback, but carried no accuracy edge. That programme was **PARKED** by the same reasoning
   being applied here.

2. **The small-n failure was under-identification, not a mean-field artefact.** This matters
   because Design 160 targets exactly the little-information-per-group regime. gllvmTMB
   explicitly found the inference *"a richer variational covariance will cure the collapse"*
   was **not** supported by the evidence. A GVA aimed at that regime risks fixing the wrong
   thing.

3. **The architecture in the gate has a known wall.** Design 160's Standing Review specifies
   variational parameters as ordinary TMB `PARAMETER`s. gllvmTMB's Design 106 §4.3 had already
   analysed *this repo's* route: a dense quasi-Newton stores an O(P²) approximation — ~23 GB at
   P = 53,970, ~52 GB at P = 80,950. drmTMB's first slice is scalar-latent-per-group, so
   P ≈ 2 × n_groups; ~25,000 groups reaches that first row. Solvable (gllvmTMB proved a
   profiling route works), but it is real engineering cost on top of an unproven benefit.

4. **Bound tightness does not imply better recovery.** gllvmTMB's Design 109 proves this on the
   engine's own objective, with a constructive counterexample: bias depends on the *gradient* of
   the ELBO gap, not its *level*. Empirically the looser bound recovered the target better on
   20 of 20 paired seeds. So the most natural "is it working?" diagnostic for a variational
   method does not license an accuracy claim.

5. **Premises of this kind erode under measurement.** gllvmTMB justified a 17–26 day programme
   partly on Laplace silently diverging; when measured, the rate decayed from 18.1% at n ≤ 150
   to **0.6% at n ≥ 1600**, and a ridge drove it to ~0. Related and worth keeping regardless of
   this decision: **83.2% of degenerate fits reported `convergence = 0` AND `pdHess = TRUE`** —
   optimiser flags are not a health signal in any drmTMB campaign either.

The literature motivating Design 160 (Ormerod & Wand 2012; the PQL bias line) is not in dispute.
What the sister-package evidence shows is that the gain is **smaller and harder to attribute**
in practice than the motivation suggests, while the implementation cost is concrete.

## The alternative: AGHQ, not GVA (maintainer, same session)

The decision is not "no better integration than Laplace" — it is that **adaptive Gauss-Hermite
quadrature is the better place to spend the effort**, and drmTMB already has AGHQ work in
flight (`R/aghq-coxreid.R`, `docs/design/224-aghq-coxreid-nongaussian-reml-alignment.md`).

This is coherent with the evidence above, because AGHQ dissolves most of what makes GVA
awkward rather than merely trading it:

- **No O(P²) outer problem (§3 above).** AGHQ refines the *same* marginal likelihood Laplace
  targets, with the latent variables still integrated out via TMB's `random=`. The outer
  optimiser keeps carrying only the fixed and structural parameters. GVA's wall exists
  precisely because variational coordinates become outer parameters; AGHQ never creates them.
- **No bound, therefore no gap (§4 above).** AGHQ is a deterministic quadrature rule that
  converges to the exact integral as nodes increase, so Design 109's result — that tightness of
  a bound does not imply better recovery — simply does not apply. Accuracy is controlled by a
  knob you can raise and check for stability, which is a far better epistemic position than a
  bound whose gap you cannot audit.
- **Ordinary standard errors.** SEs come from the usual `sdreport()` path rather than a
  variational surrogate, so the "variational SEs must be labelled as such" caveat disappears.
  gllvmTMB never resolved that caveat for its own profiled route.
- **It was already the gold standard.** Design 160's own Validation Plan names *"high-order
  adaptive GH or `tmbstan`/MCMC"* as the accuracy reference against which GVA would have been
  judged. Building the reference directly is strictly more useful than building an
  approximation that then has to be validated against it.
- **It already fixed the stability problem VA was partly proposed for.** gllvmTMB measured
  `aghq_ridge = 2` driving the silent-divergence rate to ~0 across its whole n-ladder.

**Honest boundary.** AGHQ's cost grows exponentially in the *dimension of the latent block per
group* — excellent for scalar random intercepts (exactly Design 160's first slice), and
progressively unattractive for high-dimensional or strongly correlated latent blocks, which is
the regime where variational methods keep their genuine advantage. So this decision is scoped
to drmTMB's current model classes, not a general verdict on VA.

One caution carried over rather than asserted about drmTMB: a 2026-07-30 audit in the sister
package concluded *"AGHQ integrator correct; AGHQ estimator not established."* That was
gllvmTMB's AGHQ, not this repo's, and drmTMB's own AGHQ state has **not** been audited in this
session. Treat it as a question to ask of the drmTMB implementation, not as a finding about it.

## What is NOT being claimed

This is a scope decision, not a refutation. It does not claim GVA is useless, that Laplace is
unbiased in the target regime, or that gllvmTMB's results transfer wholesale to drmTMB's model
classes — they were measured on a different engine and different families. If GVA is ever
revisited, points 1–5 are the questions to answer first, not obstacles that were settled here.

## If it is ever revisited

Read the companion note's §0 (the profiled outer-problem route) and §1 (the one-afternoon
Laplace-only bias sweep that would settle the premise cheaply) before any code. The cheap
measurement in §1 is the natural entry point: it either revives the case or closes it properly.

## Disposition of Design 160

Leave the gate in place, unchanged, as a record of the design work. It should now be read as
**considered and declined on 2026-08-03**, not as pending implementation. Any capability
worklist or handoff issue that lists GVA as upcoming should be updated to match.
