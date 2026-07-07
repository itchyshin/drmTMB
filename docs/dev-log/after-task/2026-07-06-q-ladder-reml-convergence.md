# After-task — the q-ladder: REML + convergence across phylo location-scale models

**Date:** 2026-07-06 (overnight, autonomous)
**Branch:** `drmtmb/biv-scale-side-reml` (nothing merged; nothing pushed without review)
**Framing (Shinichi):** the phylo location-scale models form a *q-ladder* by covariance-block
dimension; the mission is to make **REML work and the fit converge across all rungs**, and where
even ML collapses, rescue it (hot-start / optimizer / penalty). "Some morphological-trait
combinations ran, some didn't" — this investigation pins down *why*.

## The q-ladder and current REML coverage

| q | model | phylo block | ML converges? | native-R REML |
|---|-------|-------------|---------------|---------------|
| q1 | univariate, phylo on one axis (mu **or** sigma) | 1×1 | ✅ healthy | ✅ (shipped; AVONET 9,993 @ 34s) |
| q2 | univariate, phylo on mu **and** sigma, correlated | 2×2 | ✅ healthy (N≥250) | ❌ mis-calibrated (see below) |
| q3 | biv, correlate means, scale-side phylo **uncorrelated** | reduced | — | ❌ **not expressible** (design gap) |
| q4 | biv, phylo on all four axes, full correlation | 4×4 | ⚠ weakly identified | ❌ (Julia PLSM only) |

## Findings

### 1. Convergence map (AVONET beak+tarsus, N=250, ML) — which lever rescues which rung
q1 and q2 are healthy under every strategy (`pd=TRUE`, no boundary collapse) — so **the mean side
and the univariate rungs are fine**. q4 is the problem child:

```
q4 baseline    pd=FALSE  minSD=0.0097  obj=417.20   sigma-phylo SD collapses to ~0
q4 robust      pd=FALSE  minSD=0.0097  obj=417.20   optimizer preset: no help
q4 multistart  pd=FALSE  minSD=0.0203  obj=416.34   finds a marginally better optimum
q4 penalty     pd=FALSE  minSD=0.1420  obj=421.04   pulls the SD 15× off the boundary
```

**Penalty is the strongest lever** (Shinichi's instinct confirmed): `drm_phylo_penalty()` lifts the
collapsing sigma-phylo SD from 0.0097 to a healthy 0.142. **But `pdHess=FALSE` persists under every
strategy** — the full q4 4×4 block is *weakly identified* at N=250 for this pair, not merely
mis-started. Penalty fixes the boundary; it does not manufacture identifiability.

### 2. q2 native REML — tested, rejected on evidence, reverted
Relaxed the REML gate to admit the matched mean-and-scale (q2) univariate 2×2 block, then ran a
known-truth recovery arbiter (N=120, R=30, truth sd_mu=0.60 / sd_sigma=0.40 / rho=0.40):

```
sd_mu    : ML bias -0.088  |  REML bias -0.233   ← REML DEGRADES the mean side
sd_sigma : ML bias -0.165  |  REML bias -0.111   ← REML debiases the scale side (as intended)
```

On the coupled block, pushing sd_sigma up drags sd_mu down through the correlation. The mean-side
degradation (24pp) exceeds the scale-side gain (13pp), ~8 SE — not noise. A variance-component
estimator that biases one component to fix another is **not correct**, so it does **not ship**.
Gate reverted; the finding + the fix path (a Cox-Reid adjustment for the coupled block) are recorded
in the gate comment. `test-reml-phylo-location.R` stays green (9/9).

### 3. q3 — the scale-preserving fallback is not expressible (design gap)
The reduced model you'd want when q4 won't identify — **correlate the means, keep scale-side
variance mapping, but drop the hard SD↔SD correlation** (`q3a`) — errors: drmTMB requires the biv
phylo location-scale to be one all-or-nothing q4 block. The means-only model (`q3b`: correlate
means, sigmas fixed) converges cleanly (`pd=TRUE`, minSD=1.14), confirming the mean side is
well-identified — but it **loses the variance mapping** that is the whole point. So today there is
**no reduced model that keeps scale-side phylo but sheds the unidentified correlations**. That gap
is precisely why some pairs "don't run": the only scale-side option is the full, fragile q4.

### 4. q4 at Ayumi's scale — identifiability does NOT arrive with N (Totoro)
```
N=250   baseline pd=FALSE minSD=0.0163 | penalty pd=FALSE minSD=0.3017
N=500   baseline pd=FALSE minSD=0.0111 | penalty pd=FALSE minSD=0.0460
N=1000  baseline pd=FALSE minSD=0.0158 | penalty pd=FALSE minSD=0.0272
```
`pdHess=FALSE` persists at every scale — more data does **not** fix it. And the penalty's
boundary-lift **weakens as N grows** (0.30→0.046→0.027): at small N the prior holds the SD up, but at
large N the data overrides and says the tarsus **scale-side phylo signal is genuinely ≈0**. So
"beak+tarsus didn't run" is **not a fitting failure — it is a near-zero variance component (a data
fact)** sitting on the boundary, tangled in the q4 correlations. Two consequences: (i) the
small-N penalty "rescue" risks **over-stating** a signal the data doesn't support — use it with care;
(ii) the honest handling is **profile inference** (report the near-zero with a proper one-sided
interval, not Wald) plus a **reduced model** (`q3a`) so weak-scale pairs aren't forced through the
fragile full q4. This reframes the whole "some pairs didn't run" problem: it is over-parameterization
for pairs with weak scale-side signal, not an optimizer defect.

## Evidence / artifacts
- `scratchpad/q-ladder-convergence.R` — the N=250 convergence map (q1/q2/q4 × 4 strategies).
- `scratchpad/q2-reml-recovery.R` — the known-truth recovery arbiter that rejected q2 REML.
- `scratchpad/q3-probe.R` — the q3a/q3b expressibility + identifiability probe.
- `scratchpad/q4-scale-penalty.R` — the Totoro scale-ladder (in progress).

## What shipped
**Nothing to main.** On the branch: a documented gate revert (q2 stays rejected, now with the
arbiter numbers + the Cox-Reid path in the comment). All exploration is reversible.

## Next (concrete, prioritized)
1. **Cox-Reid adjustment for the q2 coupled block** — the correction that would let matched
   mean-scale REML debias sigma *without* degrading mu. The one thing standing between us and q2 REML.
2. **A reduced biv block (`q3a`)** — correlate means, independent scale-side phylo. New capability;
   the scale-preserving fallback for weakly-identified q4. This is likely the highest-value feature
   for the "some pairs didn't run" problem.
3. **Relax the penalty⊕REML mutual exclusion** (drmTMB.R:244) — penalty stabilizes the boundary,
   REML debiases; the hard cases likely want *both*. Needs its own recovery validation.
4. **q4 profile inference** — since `pdHess=FALSE` persists, report q4 variance components via
   profile intervals (as q1 does with `se=FALSE`), not Wald, for the weakly-identified pairs.
