# Pre-registration — the D-117 REML arm

**Written 2026-08-15 at 19:14 UTC, while the campaign was running and BEFORE any result
CSV existed.** The 400-replicate timing probe on cell 4 had been seen (it is quoted below);
nothing else had. This file is committed so the prediction cannot be adjusted after the fact.

## Why this run exists

The D-93 packet identifies REML as the one lever that is **implemented on this exact target**
(ledger `mc-0265`, gaussian / `mu` / `ordinary_re_intercept` / estimator REML, whose
`claim_boundary` records that *"coverage and calibration were not evaluated"*) and has never had
its coverage measured. D-93 holds 0.7.0 until the random-effect SD interval "actually covers".
This measures whether REML gets it there.

## Design

Paired. Each replicate generates one dataset from the A1 DGP — copied verbatim from
`../2026-08-04-d117-10group-profile-gate/d117_profile_gate.R`, same seed formula — and fits it
twice, `REML = FALSE` then `REML = TRUE`, each via its own `drmTMB()` call so the REML fit cannot
warm-start from the ML fit's inner optimisation. Profile intervals on `sd:mu:(1 | g)` both times.

Four cells, `g = 10` throughout: `n_per ∈ {4, 10}` × `sd_mu ∈ {0.5, 1.0}`. 100,000 replicates per
cell, matching the banked ML design exactly. `TRUE_BETA = 0.5`, residual `sigma = 0.7`.

**The ML arm is a control, not a courtesy.** It re-measures ML on the same package build and must
reproduce the banked per-cell values 0.9229 / 0.9257 / 0.9255 / 0.9251 (pooled 0.924800, SE
0.000417). If it does not, the harness is wrong and the REML number is not to be trusted.

## Primary estimand and decision rule

**Primary:** pooled all-attempt profile coverage under REML, over 400,000 replicates, with an exact
binomial 95% CI. An unavailable or non-finite interval counts as a miss, as in the ML gate.

**The question this answers, stated as a rule fixed in advance:**

- **REML CLOSES THE GAP** if the pooled REML coverage CI **contains 0.95**.
- **REML NARROWS BUT DOES NOT CLOSE** if the CI excludes 0.95 from below but pooled REML exceeds
  the ML 0.9248 by more than 2 paired SE.
- **REML DOES NOT HELP** if the paired difference CI contains zero, or is negative.

**Secondary:** per-cell paired difference Δ = coverage(REML) − coverage(ML) with a paired normal
CI; per-cell REML coverage against the `g`-tapered floor `ss_floor(10) = 0.918`; mean SD estimate
and its bias against truth under both estimators; boundary incidence and conditional-on-boundary
coverage under both.

## Prediction (committed before results)

**I predict REML NARROWS BUT DOES NOT CLOSE.** Specifically:

1. Δ > 0 in all four cells, pooled Δ in **+0.010 to +0.030**.
2. Pooled REML coverage in **0.935 to 0.950**, most likely below 0.95.
3. Recovery bias improves markedly — pooled ML ≈ −8% to −16%, REML roughly **half** that.
4. Conditional-on-boundary coverage stays **poor** under REML. REML corrects a degrees-of-freedom
   bias; it does not change the fact that a profile interval at a variance boundary is
   post-selection inference. I expect the boundary sub-population to remain the dominant miss
   contributor.

**Reasoning, and its weakness.** The one repository measurement of REML on profile-interval
coverage moved ML 0.9240 → REML 0.9510 at `g = 10`, `n_each = 10` — but on the **`sigma` axis**,
not this `mu` axis, and that campaign's own headline claim was NOT ADMITTED because its
pre-registered falsifier fired. The 400-replicate probe on cell 4 (the boundary-heaviest, 47%
boundary incidence) showed mean SD 0.4339 → 0.4745 against truth 0.5, i.e. bias −13.2% → −5.1%,
with a paired coverage Δ of only +0.0075 at n = 400 — a Δ far smaller than the sigma-axis
campaign's +0.0270, and the reason I predict narrowing rather than closure. That probe is 400
replicates and cannot settle anything; it is stated here as the basis of the prediction, not as
evidence.

## Falsifiers

- **The prediction fails** if pooled REML coverage reaches 0.95 (CI contains it), or if pooled Δ
  falls outside +0.010 to +0.030, or if any cell shows Δ ≤ 0.
- **The harness fails** — and no REML claim may be made from this run — if the ML control arm does
  not reproduce the banked pooled 0.9248 within about 3 SE, or if `reml_flag` does not read back
  `TRUE` on the REML arm, or if the REML and ML SD estimates are identical on any material share
  of replicates (which would mean `REML =` was silently ignored).

## What this run cannot establish

It measures **one cell of one family at one group count**: A1 scalar Gaussian, `g = 10`, ML vs
REML, `n_per ∈ {4, 10}`, `sd_mu ∈ {0.5, 1.0}`. It says nothing about other families, providers,
slopes, bivariate models, other group counts, or the `sigma` axis. It does not discharge D-93 or
D-117 — both remain Shinichi's decisions — and it advances no rung. A result in either direction
is evidence for that decision, not the decision.
