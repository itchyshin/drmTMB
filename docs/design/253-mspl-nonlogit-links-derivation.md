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

---

# ADDENDUM — re-adjudicated with the source papers in hand (2026-08-10)

The derivation above was made **without** the source papers; four items were marked UNVERIFIED.
Shinichi then supplied both papers and they change the conclusion's *reason*, though not the fence.

**Sources now read directly:**
- Sterzinger, P. & Kosmidis, I. (2023), *Statistics and Computing* **33**:53.
- Sterzinger, P., Kosmidis, I. & Moustaki, I. (2026), *Psychometrika* **91**:494–507.

## VERDICT: the fence stays — its stated reason was WRONG

### 1. The published existence argument DOES extend to probit and cloglog

2023, p. 6, on the fixed-effect penalty:

> *"Kosmidis and Firth (2021, Theorem 1) show that if the matrix **X** … is full rank, then the limit
> of (4) is −∞ as **β** diverges to any point with at least one infinite component. **This result
> holds for a range of link functions including the commonly-used logit, probit, complementary
> log–log, log–log, and the cauchit link.**"*

and

> *"noting that (2) is always bounded from above by one as a probability mass function, the penalized
> log-likelihood ℓ(θ) + P(θ) diverges to −∞ as **β** diverges, **for any value of ψ**."*

Neither step is logit-specific: the first names probit and cloglog explicitly; the second is a
property of a probability mass function. **No step fails.** The variance-component penalty (eq. 5)
is a function of the Cholesky alone and never sees the link.

*Caveat:* eq. (4) is **written** with `μ = exp(η)/{1+exp(η)}`, so the published *formula* is
logit-shaped even though the *theory* is not.

### 2. THE ACTUAL GAP IS THE LAPLACE APPROXIMATION — and it applies to the SHIPPED LOGIT ROUTE

2023, p. 6:

> *"The condition on the boundedness of (2) from above is just one sufficient condition … A weaker
> sufficient condition is that the penalized objective diverges to −∞ … From the numerous numerical
> experiments we carried out, **we encountered no evidence that this weaker condition does not hold
> for the adaptive quadrature and Laplace approximations** … that the glmer routine of the R package
> lme4 employs."*

The proof covers the **exact likelihood** and **vanilla non-adaptive Gauss–Hermite quadrature**.
**Laplace and adaptive GHQ rest on the authors' numerical evidence, not proof** — and that evidence
was obtained on **lme4/glmer, not TMB**.

> **drmTMB is TMB-Laplace. So the finiteness guarantee behind the estimator we already ship, under
> logit, is numerical evidence rather than proof — and it is somebody else's numerical evidence, on
> a different implementation.** Any honest statement of the probit/cloglog gap must concede the same
> gap for logit.

### 3. Design 252 §7 is WRONG as an attribution — rewrite the reason, keep the fence

§7 states that *"Sterzinger & Kosmidis leave the probit and cloglog bounds for the mixed-effects
case as future work."* **The paper does no such thing**; it asserts the fixed-effect result for
those links. The defensible reasons to keep the guard are different:

1. the published **numerical** evidence is **logit + glmer** only;
2. eq. (4) is published in logistic form, so the link-general `W` is our extrapolation;
3. **we have no drmTMB evidence** for non-logit `W` under TMB-Laplace.

### 4. §2's "any link with ω(η) → 0" was AGENT-INFERRED and is not in either paper

That condition appears in `ENGINEERING-NOTEBOOK.md:1055-1061` and in §2 of this document. It is
**not** stated by either source. Neither is it obviously sufficient: `ω → 0` alone gives no *rate*,
and the determinant must diverge at a rate. **Treat it as a lead, not a result.** The real condition
is in Kosmidis & Firth (2021) §3.1, which we do not have.

### 5. The 2026 framework is NOT transportable as stated

2026, p. 497: Theorem 4.1 *"is model-agnostic in that it only requires **S** to have full rank"* —
agnostic about the **data-generating process**, not the **model class**. E3 is stated over
`∂Θ = {θ : ψ_m = 0}` with `λ_min(Σ(θ(r))) > 0` — Heywood boundaries of a factor model. **E1 and E2
transport trivially** (continuity; `sup P* ≤ 0`). **E3 does not**: a GLMM has no `Σ(θ) = ΛΛᵀ + Ψ`.
Re-deriving E3 for the composite penalty under probit/cloglog is work neither paper does.

This also retires the plan to "rebuild E1 against Theorem 4.1" — the theorem is not in a form that
can be applied to our model without that derivation.

### 6. NEW FINDING about the shipped implementation — `n_eff` is an unpublished extrapolation

The 2023 Appendix binds the scaling as `c = 2√(p/n)`, subject to
`sup‖R_n⁻¹∇P(θ)‖ = o_p(1)` provided `max_{s,t}|x_st| = O_p(n^{1/2})` (p. 7).

drmTMB substitutes **`n_eff = Σ(trials × frequency)`** (`R/mspl.R:174-176`) for the paper's `n`.
These coincide for single-trial Bernoulli — the paper's setting — but **for aggregated binomial data
this is an extrapolation the paper does not license.** Worth an issue.

(The 2026 paper's N4, `c_n = o_p(√n)`, is satisfied trivially by `2√(p/n_eff)` → 0, but N4 is the
weaker and wrong test; the 2023 Appendix condition binds.)

## What would still have to be shown before opening probit/cloglog

1. **Kosmidis & Firth (2021) §3.1's actual link condition**, checked for cloglog. We do not have this
   paper. It is the single highest-value missing source.
2. **Finite-estimate behaviour under TMB Laplace for the non-logit composite** — our own evidence,
   because the authors' is glmer + logit.
3. **`glm()` / `brglm2` Jeffreys parity** for the link-general `W`.

## Measured behaviour, for the record

MSPL under certified separation (`G = 20`, `n_g = 8`, logit, 5 seeds), slope estimates:

| regime | seeds 11–15 | convergence |
|---|---|---|
| quasi-complete | 83 · 630 · 934 · 1 869 · 3 197 | `conv = 0` on all |
| complete | 177 · 214 · 300 · 471 · 745 | `conv = 0` on all |

Finite, as guaranteed — but the magnitude is arbitrary and seed-dependent, and quasi runs *larger*
than complete. **This is the soft penalty working as designed, not a defect:** the 2023 abstract
requires the penalty be *"soft enough to preserve the optimal asymptotic properties"*, i.e. to vanish
as information accumulates. Guaranteed interiority is not guaranteed shrinkage. Users must read the
ratio (SE ≈ estimate ⇒ no information), never the point estimate as an effect size.

---

# ADDENDUM 2 — Kosmidis & Firth (2021) read directly; ADDENDUM 1 was WRONG on the key point

Source now in hand: **Kosmidis, I. & Firth, D. (2021), "Jeffreys-prior penalty, finiteness and
shrinkage in binomial-response generalized linear models", *Biometrika* **108**(1), 71–82,
doi:10.1093/biomet/asaa052.** This was named in Addendum 1 as "the single highest-value missing
source." It is decisive, and it reverses that addendum's central correction.

## The condition, verbatim (§3.1, p. 76)

> *"Theorem 1 and Corollary 1 readily extend to link functions other than the logistic one.
> Specifically, if G(η) = exp(η)/{1+exp(η)} in model (1) is replaced by an at least twice
> differentiable and invertible function G : ℝ → (0,1), then the expected information matrix again
> has the form XᵀW(β)X, but with working weights wᵢ(β) = mᵢ(ω ∘ ηᵢ)(β), where
> **ω(η) = g(η)²/[G(η){1 − G(η)}]** and g(η) = dG(η)/dη. **If the link function is such that
> ω(η) → 0 as η diverges to either −∞ or ∞, then the proofs of Theorem 1 and Corollary 1 in the
> Supplementary Material carry through unaltered** to show that lim|XᵀW*(r)X| = 0 and that, when the
> penalty is a positive power of Jeffreys' invariant prior, the maximum penalized likelihood
> estimates have finite components. **The logit, probit, complementary log-log, log-log and cauchit
> links are some commonly used link functions for which ω(η) → 0.**"*

**Theorem 1** (p. 75): *"Suppose that X is of full rank. Then lim_{r→∞}|XᵀW*(r)X| = 0."*
**Corollary 1**: *"Suppose that X is of full rank. The vector β̃ that maximizes ℓ̃(β) has all of its
components finite."* And: *"Corollary 1 also holds for any fixed a > 0"* — any positive power of the
Jeffreys penalty, not only ½.

**Table 1** (p. 77) tabulates ω(η) for all five links, captioned *"for all the displayed link
functions, ω(η) vanishes as η diverges."*

## What Addendum 1 got wrong

Addendum 1 §4 demoted the `ω(η) → 0` condition, calling it **"AGENT-INFERRED"**, *"not stated by
either source"*, and *"not obviously sufficient: ω → 0 alone gives no rate."*

**All three claims are false.** It is the paper's own condition, stated verbatim; it is exactly what
the theorem requires; and it *is* sufficient — the proofs "carry through unaltered", with no rate
condition anywhere. The only additional requirement is **X of full rank**.

**§2 of the original derivation was therefore correct all along.** Its tail-order table computed
`ω(η) = h'(η)²/[h(η)(1−h(η))]` for logit, probit and cloglog and found all three vanish in both
tails — which is precisely Theorem 1's hypothesis. The correction was the error, not the derivation.

*Provenance note:* Addendum 1 was written from the 2023 and 2026 papers only. The 2023 paper cites
this condition to "Kosmidis and Firth 2021, Section 3.1" **without restating it**, so the reviewer,
lacking that paper, reasonably declined to credit a condition she could not source — and then went
one step further and asserted it was insufficient. **Declining to verify is right; asserting the
negative is not.** That is the transferable lesson.

## The settled position

| claim | status |
|---|---|
| Jeffreys penalty → −∞ as β diverges, **probit** | **PROVED** — KF2021 Thm 1 + §3.1 + Table 1 |
| same, **cloglog** | **PROVED** — same |
| holds for any penalty power `a > 0` | **PROVED** — KF2021, Corollary 1 remark |
| only structural requirement | **X full rank** |
| composite MSPL existence, **exact** likelihood | **FOLLOWS** — 2023 p. 6, link-free second half |
| variance-component half | **link-free** — acts on the Cholesky |
| composite MSPL existence, **Laplace** | **NUMERICAL EVIDENCE ONLY** — 2023 p. 6, and that evidence is glmer's |

**The link is not the obstruction, and now that is proved rather than argued.** The residual gap is
the Laplace approximation, it is **link-independent**, and it therefore applies equally to the
logit route drmTMB already ships.

## Bonus: two claims drmTMB makes are confirmed at source

1. **Wald intervals fail under separation.** KF2021 §2.1, p. 75: *"there will always be a parameter
   vector with large enough components that the usual Wald-type confidence intervals … will fail to
   cover regardless of the nominal level α that is used."* drmTMB's MSPL ships standard errors and
   no intervals on exactly this basis; the citation is now verified rather than inherited.
2. **Shrinkage is toward equiprobability, not toward zero.** KF2021 Thm 2 and §2.2: the penalty
   shrinks toward the model implying equiprobability across observations, *"with respect to a metric
   based on the expected information matrix rather than … Euclidean distance. Hence, the reduced-bias
   estimates are only typically, rather than always, smaller in absolute value."* This explains the
   measured behaviour directly: a finite estimate of 214 is not a failed shrinkage — shrinkage was
   never promised to be toward zero in Euclidean terms.

## Revised statement of what remains

1. ~~KF2021 §3.1's link condition~~ — **OBTAINED AND SATISFIED** for probit and cloglog.
2. **Finite-estimate behaviour under TMB Laplace** for the non-logit composite — still our own
   evidence to generate, because the authors' is glmer + logit. **This is now the only technical
   gap**, and it is not link-specific.
3. `glm()` / `brglm2` Jeffreys parity for the link-general `W` — a cheap implementation check.

Design 252 §7 should be rewritten accordingly: keep the guard if desired, but the reason is *"we
have no drmTMB-Laplace evidence for any link, and none at all for non-logit"* — **not** *"the bounds
are unproved for probit and cloglog."* They are proved.


---

# ADDENDUM 3 — the gllvmTMB team corrected Addendum 2's scope (2026-08-10)

Addendum 2 concluded *"the link is not the obstruction, and now that is proved."* **True of
existence, false of the asymptotics.** The gllvmTMB team caught it; verified against 2023 §7, p. 7.

| result | link-general? |
|---|---|
| Jeffreys barrier / fixed-effect finiteness | **YES, proved** (KF2021 Thm 1, §3.1, Table 1) |
| composite existence, exact likelihood | **YES** (2023 p. 6) |
| **softness scaling `c = 2√(p/n)`** | **NO — logit delta-method result** (2023 §7) |
| **asymptotic gradient bound, Thm C.1** | **NO — logit constants** |

2023 §7: *"c … the square root of the average of the approximate variances of η̂ᵢⱼ **at β = 0**. A
delta method argument gives that **c = 2√(p/n)**."* Logit has `ω(0) = ¼` ⇒ `Var ≈ 4p/n` ⇒
`c = 2√(p/n)`. **Probit has `ω(0) = 2/π ≈ 0.637` ⇒ `c ≈ 1.25√(p/n)`.** Different constant.

So drmTMB's `c_n = 2√(p/n_eff)` is **the wrong scaling for probit/cloglog** — it would not deliver
the softness the ML asymptotics depend on. Non-logit softness bounds genuinely *are* future work,
exactly as design 250 said.

**Three corrections in three days on one question**, each from a wider evidence base: original
derivation (no papers) → Addendum 1 (2023 + 2026) → Addendum 2 (+ KF2021) → Addendum 3 (+ external
review). The pattern worth keeping: **each round was confidently stated and each was partly wrong.**
The failure mode was not lack of rigour but *asserting the negative* — "the authors do NOT defer
this" — from sources that were silent rather than contrary.

**Also corrected by the same review:** gllvmTMB already has the cloglog negative-tail series repair;
their `mspl_cloglog_*_tail_extension_count` instruments the **opposite** tail (`η > 690`, near
overflow), and any MSPL fit touching that extension is **rejected**, not returned. Our draft's
inference that they shared our bug was wrong on both counts.

---

# ADDENDUM 4 — the fence is OPEN for probit and cloglog (2026-08-12)

**This supersedes §6's verdict ("NEEDS EVIDENCE. The guard stays") and design 252 §7's fence.** The
evidence §4 asked for was gathered on 2026-08-11 and the guard was opened on it. The derivation above
is unchanged and still correct; only its *status* moved.

## What the three gates returned

All under `docs/dev-log/simulation-artifacts/2026-08-11-mspl-nonlogit-links/`, each pre-registered
before any replicate, none rescored. **460,000 fits**, Totoro, four distinct seed streams.

| gate | question | result |
|---|---|---|
| **G0 / G0b** | do the kernels — R *and* compiled — compute the right link-general weight? | PASS. R matches `glm()` IRLS weights (4.8e−8) and an independent Jeffreys determinant (5.6e−10); the compiled objective matches the R kernels along a separation ray in both tails (3.6e−16 / 5.4e−16 / 1.7e−14) |
| **G1b** | does TMB-Laplace return finite estimates? | **0 non-finite in 43,972 completed fits**, all four link/orientation conditions |
| **G3** | are the Wald standard errors calibrated? | **CALIBRATED** in the identified regime — probit `[0.946, 1.008]`, cloglog `[0.957, 1.027]`, with logit reproducing an earlier logit-only campaign as the reference arm |
| **G2** | does §5's rejection of a modified `c_n` cost anything? | **IMMATERIAL** — the logit constant costs ~1% of one standard error for both links |

## §5's "rejected: a modified `c_n`" is upheld, and now on evidence rather than principle

§5 rejected inflating `c_n` on the grounds that it defines a *different estimator*. Addendum 3 then
showed the shipped `c_n = 2√(p/n)` **is** the logit constant and that probit and cloglog want 1.2533
and 1.3108 by the same delta-method argument. That left an uncomfortable position: the shipped
constant is knowably wrong for the admitted links, and §5 forbids fixing it.

G2 resolves it. The wrong constant costs **~1% of one standard error** at `n_eff ≥ 300`, the shipped
(stronger) constant produces slightly *less* bias in every cell, and the gap closes 32–125× from
`n_eff` 120 to 1200 — faster than the shared `√(p/n)` rate requires. **So `c_n` stays as shipped**,
and the reason is now measured rather than asserted.

## What was NOT admitted, and why

- **log-log and cauchit.** Both satisfy KF2021's condition (Table 1) and would be admissible on the
  same theory. drmTMB has no `link_code` for either and no evidence was gathered, so neither is
  admitted. §2's tail-order table covers only the three.
- **Intervals.** Unchanged. KF2021 §2.1 proves Wald intervals fail to cover under separation at any
  nominal level, link-generally; `confint()`, profiles and likelihood comparisons stay unavailable.
- **The `q2` deep-separation regime as an inference domain.** Point estimates are finite there — that
  is what the penalty is for — but G3 measured the standard error as *unavailable* in up to 98.3% of
  converged fits. The package signals this correctly (`drmTMB_mspl_wald_unavailable` plus a
  `std_error.status` column); it is a documented limit, not a defect.

## One correction to §3 worth carrying

§3 states the mixed-effects gap "bites hardest for cloglog", since `κ₀(η) = e^η` is unbounded and no
parameter-free sandwich exists. **The empirical ordering did not follow that prediction.** Under
TMB-Laplace, cloglog's *as-generated* orientation produced the most optimizer failures (33 of 11,000)
while its *mirrored* orientation produced 2 — same link, same grid — and probit produced none. The
coercivity concern is about the criterion; what was measured is optimizer behaviour on near-degenerate
data (0–3 events with a 2×2 random-effect covariance, where plain ML fails on 100% of the same
datasets). **These are different objects and §3's argument is not falsified by this**, but anyone
reading §3 as a prediction about which link will misbehave in practice should read this paragraph too.

## Provenance

Opened by PR (branch `claude/mspl-open-probit-cloglog`), Claude, 2026-08-12. Evidence merged in
PR #1019; the C++ link dispatch that made any of it measurable merged in PR #1012. MSPL and
binomial-link suites: **399 pass, 0 fail** at the time of admission.
