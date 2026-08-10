# MSPL for non-logit links — derivation and the exact location of the gap

Status: **NEEDS EVIDENCE.** Derived 2026-08-09 (Noether). Transcribed by the orchestrator because
the reviewer's session had file writes disabled — **the derivation is hers, the transcription
errors would be mine.**

This note supplies the justification design 252 §7 asserted but never derived. Its conclusion
**agrees with** that section's guard (`R/mspl-estimator.R:179-184` keeps rejecting non-logit) and
localises *why* to a single determinant term.

## 1. The composite objective for a general link

For binomial data with link `g`, mean `h(η) = g⁻¹(η)`:

```
ℓ_MSPL(β, Σ)  =  ℓ_L(β, Σ)              Laplace-approximated log-likelihood
               +  c_n · ½ log det I_F(β)  Jeffreys, on the FIXED effects
               +  P_v(Σ)                  negative-Huber, on the covariance Cholesky
```

with `c_n = 2√(p/n_eff)`. **Link-dependent:** `ℓ_L` and `I_F`. **Link-free:** `P_v`, and the
`c_n` form itself.

## 2. The fixed-effect half — HOLDS for all three links

The working weight is `w(η) = h'(η)² / [h(η)(1 − h(η))]`. Tail orders, matching the closed forms
implemented at `R/mspl.R:58-68`:

| link | `η → +∞` | `η → −∞` | `sup w` |
|---|---|---|---|
| logit | `Θ(e^(−η))` | `Θ(e^η)` | `1/4` |
| probit | `Θ(η e^(−η²/2))` | `Θ(|η| e^(−η²/2))` | `2/π ≈ 0.6366` |
| cloglog | `Θ(e^(2η − e^η))` | `Θ(e^η)` | `≈ 0.6477` at `η = 0.4661` |

For cloglog, `w = x²/(eˣ − 1)` with `x = eη`; the maximum solves `2 − 2e^(−x) = x`, giving
`x* = 1.5936`.

All three satisfy `w → 0` in **both** tails, so by Cauchy–Binet `det XᵀWX → 0` along every ray when
`rank X = p`. **The fixed-effect finiteness argument therefore extends to probit and cloglog.**

**Asymmetry breaks nothing.** The condition (C0) is a *limit* condition, not a rate-equality one, so
cloglog's asymmetric tails are irrelevant to it.

## 3. The mixed-effects gap — where logit is special

Per-observation curvature decomposes as

```
−∂²_η ℓ_i  =  y_i κ₁  +  (m_i − y_i) κ₀,     κ₁ = −∂²_η log h,   κ₀ = −∂²_η log(1 − h)
```

**Logit is exactly the case `κ₁ = κ₀ = h(1−h) = w`.** Three consequences follow *simultaneously*,
and only for logit:

1. the Laplace Hessian `H = Zᵀ diag{m_i w} Z + Σ⁻¹` becomes **`y`-free**;
2. it is built from **the same `w`** as the Jeffreys term;
3. it admits the parameter-free sandwich `Σ⁻¹ ⪯ H ⪯ ¼ ZᵀMZ + Σ⁻¹`.

One ray bound then controls both the likelihood and the penalty at once. **For probit and cloglog
`κ₁ ≠ κ₀` and the bounds split.**

### Two candidate obstructions, both eliminated

- **Non-concavity — not the problem.** `κ₀, κ₁ > 0` for all three links (for cloglog,
  `∂_η log h = x/(eˣ − 1)` is strictly decreasing), so `H ≻ 0` and the mode is unique.
- **Unboundedness — not the problem.** `H ⪰ Σ⁻¹` gives `−½ log det H ≤ ½ log det Σ`, which cancels
  `log φ_Σ(û)`, so `ℓ_L ≤ ℓ(β, û) ≤ 0` link-generally.

### The real gap: COERCIVITY (attainment), not boundedness

And it bites **hardest for cloglog**: `κ₀(η) = e^η` is unbounded, so **no parameter-free `C`**
satisfies `H ⪯ C·ZᵀMZ + Σ⁻¹`.

**Probit is materially closer to admissible**: it retains a sandwich with `C = 1`, since
`κ₀ = λ(λ − η) ∈ (0, 1)`.

> **Clearing probit is NOT evidence for cloglog.** They fail differently and must be evidenced
> separately.

## 4. What would constitute sufficient evidence

**E1 — decisive.** Profile-ray descent: `R(t) = max_ψ ℓ_MSPL(β̂ + tδ, ψ)` for `t` out to `10⁴`, plus
the mirrored `log L₁₁` ray and the joint diagonal. **PASS** = strictly decreasing past `t₀`, drop
`< −50` nats on every fixture, tail slope matching the §2 predictions. **One non-decreasing fixture
falsifies.**

**E2 — secondary.** Bound-insensitivity across `(B,S) = (10,3), (10²,6), (10³,9)` with
`‖θ̂_B3 − θ̂_B2‖_∞ < 10⁻⁴`.

**Grid.** link ∈ {logit *as control*, probit, cloglog, **and cloglog with `y ↦ m − y`** — both
orientations mandatory, because cloglog is asymmetric} × q ∈ {1,2} × G ∈ {5,10,20,40} ×
`n_g` ∈ {2,5,10} × σ ∈ {0.25,1,2,4} × p ∈ {2,4} × separation ∈ {complete, quasi, incidental, none}.
**Adversarial corner required:** large `n_eff` / small `p`, so `c_n ≲ 0.05`.

**Merely suggestive, not sufficient:** a high "converged finite" rate at one bound. That measures
the optimiser, not the criterion.

## 5. Intermediates

- **(A) `q = 0` Jeffreys-penalised GLM** — sound and proved, but `P_v ≡ 0`, so it is a different
  estimator and **must not ship under the MSPL name**. Also already refused at
  `R/mspl-estimator.R:244-256`.
- **(D) RECOMMENDED.** Finish design 252 §§1-6 under `estimator = "ml"` and expose `P_f`, `c_n`, and
  `log det XᵀWX` as **reported diagnostics only — never in the objective.** This gives users the
  link-general machinery's *output* without asserting a guarantee that has not been derived.

**Rejected:** a bounded `Σ` (a binding box is a truncated estimate — worse than an honest reject);
a modified `c_n` (no rate argument exists: `P_f` diverges as `−Θ(t²)` for probit and `−Θ(t)` for
cloglog vs `−Θ(t)` for logit, so inflating `c_n` defines a *different estimator*).

## 6. Verdict, and what remains UNVERIFIED

**NEEDS EVIDENCE.** The guard stays. Order of work: read the actual proof → intermediate (D) →
E1/E2, **probit first**.

Four items could not be settled without the paper's proof text and are marked **UNVERIFIED**:

1. that the logit-specific step *is* the canonical identity — **AGENT-INFERRED** from structure,
   not read from the source;
2. whether the theorem imposes a threshold on `c_n` or holds for all `c_n > 0`;
3. **whether the theorem concerns the exact marginal or the Laplace criterion.** `src/drmTMB.cpp:5019`
   penalises the Laplace `nll`. **This is a live question for the SHIPPED LOGIT ROUTE, not only for
   new links** — the most consequential open item in this note;
4. uniformity over the direction sphere in §2.

## 7. Defect found while deriving

`mspl_penalty_components()` (`R/mspl.R:353`) took **no `link` argument** and called
`mspl_jeffreys()` with the logit default, so the composite reference stayed logit-only even after
the leaves were made link-general. **Fixed 2026-08-09** with a regression test asserting the
composite actually *changes* with the link — a test that only checked "probit runs" would have
passed against the broken version.

This is the same failure mode as the `link_code` incident earlier that day: **the caller named
nothing about links, so no search for "link" would have found it.**

## References

- Sterzinger, P. & Kosmidis, I. (2023). *Maximum softly-penalized likelihood for mixed effects
  logistic regression.* Statistics and Computing **33**:53. doi:10.1007/s11222-023-10217-3
- Kosmidis, I. & Firth, D. (2021). Jeffreys-prior penalty, finiteness and shrinkage in
  binomial-response GLMs. *Biometrika*.
- Sister-package prior art: gllvmTMB PR #952, branch `codex/lane-b-mspl-reconcile-951` — admits
  logit/probit/cloglog for LA-MSPL behind a point-estimation-only fence, and **also** records that
  its all-link evidence campaign remains outstanding.
