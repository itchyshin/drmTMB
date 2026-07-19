# 224 — AGHQ + non-Gaussian REML (Cox–Reid): symbolic ↔ implementation alignment

**Status:** design (math-first, pre-code). This is slice **S1** of the approved arc
(`~/.claude/plans/ticklish-exploring-meteor.md`). It fixes the symbolic decomposition the build
legs (S2–S6b) must match term-by-term, and records the corrections from an adversarial
plan-review (14-agent derive→verify→critique workflow, 2026-07-18).

**One-line purpose.** Give drmTMB two random-effect integration levers for non-Gaussian families —
Cox–Reid restricted likelihood (non-Gaussian REML) and adaptive Gauss–Hermite quadrature (AGHQ) —
so the small-cluster RE-SD downward bias can be removed and the coverage cells re-scored for
*nominal*. Cox–Reid is the bigger lever and (for binomial) the smaller build; do it first.

> **Adversarial-review verdict (this doc's warrant).** The four derivations each verified
> SOUND / SOUND-WITH-CAVEATS in isolation, but the completeness critic returned **NOT-READY-as-a-single-
> joint-fold**: the recombined objective was undefined at the seam. §2 resolves that seam (the
> recombination is **nested**, not a joint TMB fold). Every §5 mapping was re-read against the code; the
> corrections in §4 are the review's load-bearing catches.

---

## 1. Three distinct objects (do not conflate them)

The arc touches one scalar latent RE `u` (per cluster), the mean fixed effects `β = beta_mu`, and —
for cumulative_logit only — the cutpoints `θ = theta_ord`. The RE-SD `σ = exp(log_sd_mu)` stays an
**outer** optimized parameter throughout (it lives in `η`, not the random block). Three objectives:

| # | Object | u integrated by | β,θ treated by | = / ≈ | Cert. role |
|---|---|---|---|---|---|
| **O1** | **Laplace ML** (current drmTMB) | Laplace | outer (optimized) | — | baseline; the −7.3% point |
| **O2** | **Joint-Laplace REML** (un-gate the fold) | Laplace | folded into `random=` (joint Laplace) | **= `glmmTMB(REML=TRUE)`** | binomial nominal; ordinal *intermediate* |
| **O3** | **Nested AGHQ + Cox–Reid** (external) | **AGHQ** | Cox–Reid adjust `−½log|I|` on the AGHQ-marginal | ≈ rolled reference | **ordinal nominal object** |

- **O2 is what un-gating the existing fold produces.** `drm_apply_estimator_spec()` appends `beta_mu`
  to `tmb_random_names` → TMB does one joint Laplace over `(u, β)`. That is *exactly* how
  `glmmTMB(REML=TRUE)` builds its restricted likelihood → **O2 ≡ glmmTMB REML**, a tight (~1e-6)
  deterministic oracle. For **binomial** this removes ~42% of the ML variance bias and reaches nominal
  because binomial's AGHQ integral error is negligible (high information).
- **O3 is the ordinal nominal object, and it is NOT O2.** For cumulative_logit the Laplace integral
  error over `u` is *not* negligible (~2.3 pt at M=40); O2 (Laplace-u) leaves it in. Reaching nominal
  needs AGHQ over `u` **and** the Cox–Reid fixed-effect adjustment — the **nested** construction of §2.
  The 2026-07-18 scoping ladder (Laplace −7.3% → +AGHQ −5.0% → +Cox–Reid −0.9%) is the O1→O3 path;
  **O2-alone for ordinal lands around −3%, still under nominal at small M.**

**Consequence for the plan:** binomial certifies on **O2** (S2/S3, gate-relax + glmmTMB oracle);
ordinal certifies on **O3** (S4b/S5/S6/S6b), which is an external nested build, not a TMB `random=`
fold. The θ_ord TMB fold (O2-flavour ordinal) is at most a cheap *intermediate*, not the certified
object — see §4.6.

---

## 2. The recombination seam — RESOLVED as a nested construction

The critic's blocking finding: "AGHQ-over-u composed with Laplace-fold-of-β via `random=`" is
undefined, because the joint-determinant identity that licenses the β-fold assumes `u` is
Laplace-integrated. **Resolution — the two levers compose by nesting, not by a joint fold:**

```
Inner (AGHQ):   L_AGHQ(β, θ, σ) = ∏_m  Σ_k w_k · f(y_m | û_m + σ̂_m √2 z_k , β, θ)      (marginalize u_m)
Outer (Cox–Reid): ℓ_R(σ) = min_{β,θ} [ −log L_AGHQ(β,θ,σ) + ½ log|I_{(β,θ)}(β,θ,σ)| ]   (adjust fixed effects)
Certified:      σ̂ = argmin_σ ℓ_R(σ);  interval from the profile of ℓ_R in log σ (§4.7)
```

where `I_{(β,θ)}` is the observed information of the **AGHQ-marginal** negative log-likelihood w.r.t.
`(β, θ)` (Cox–Reid 1987 adjusted profile). This is precisely what `scratchpad/cumlogit_reml_scoping.R`
rolls (48-node AGHQ inner → `optimHess` for `I` → outer optimize), so the rolled reference **is** O3's
reference — but it is ~1e-2 reliable, a *scoping* check, not a 1e-6 gate.

**Why not the joint fold:** replacing the u-Laplace with GH breaks the `det H_joint = det H_uu · det S`
factorization that the β-fold rests on. So O3 must be an **external** construction that (a) uses the
drmTMB TMB object to get the per-cluster Laplace mode `û_m` and curvature `Ĥ_m = H_uu` for adaptive
node placement, (b) sums the conditional leaf over nodes, (c) applies the Cox–Reid adjustment over
`(β,θ)` externally. It does **not** go through `random=`.

**Notation unification (critic's unpaired terms):** `Ĥ_m ≡ H_uu` (same u-block second derivative at the
conditional mode — one symbol). AGHQ marginalizes the **unit-scaled** `u` (prior `N(0,1)`,
`src/drmTMB.cpp:3100/3185`); the SD `σ` enters through `η` (`:3095-3096/:3180-3181`), so the node
map is `u = û_m + Ĥ_m^{-1/2}√2 z_k` on the unit-`u` scale and `σ` is applied inside `η` — the variance
partner of `u` is `log_sd_mu`, unchanged and outer.

---

## 3. The gate topology — two gates, three sites (not one line)

Relaxing REML for a non-Gaussian family requires editing **all** of:

| Site | File:line | What it does |
|---|---|---|
| Gate A | `R/drmTMB.R:234` | `if (isTRUE(REML) && !family_type %in% c("gaussian","biv_gaussian")) cli_abort` |
| Gate B | `R/drmTMB.R:2140-2148` | `drm_validate_reml_spec()`: aborts unless `model_type=="gaussian"` (delegates biv) — **called from inside `drm_apply_estimator_spec()` at :860, before the fold builds** |
| Fold | `R/drmTMB.R:862-892` | `drm_apply_estimator_spec()`: folds `beta_mu`/`beta_sigma` only — **no `theta_ord` branch** |

The binomial "sole obstruction is :234" framing (an early derivation claim) is **false** — Gate B fires
first. S2/S4 must relax both gates for the target family and add the θ_ord fold branch for ordinal O2
(if built at all — see §4.6).

---

## 4. Corrections from the adversarial review (load-bearing)

**4.1 The Schur split ≠ exact Cox–Reid adjusted profile (UNSOUND catch, now fixed).** The exact block
identity `det H_joint = det H_uu · det S`, `S = H_ββ − H_βu H_uu⁻¹ H_uβ`, is correct, **but** `S` is
*not* the Hessian of the u-*profiled* objective: the profiled objective
`h(β) = g(β,û(β)) + ½log det H_uu(û(β),β)` carries an extra curvature term
`C(β) = ½ d²/dβ²[log det H_uu(û(β),β)]` whenever `H_uu` depends on β (true for binomial/ordinal). So
drmTMB's fold computes the **joint-Laplace restricted likelihood** (`−½log|H_joint|`), which
**equals `glmmTMB(REML=TRUE)`** (same construction) but is only an *approximation* to the textbook
Cox–Reid adjusted profile of the u-marginal (which the rolled O3 reference computes). **Honest framing:**
O2 is a Laplace-order restricted likelihood, validated against glmmTMB REML (its exact twin), *not*
against the rolled marginalize-first Cox–Reid. Do not claim "no extra error beyond `O(N⁻¹)`" as derived —
it is the same Laplace *order*, but the `C(β)` discrepancy is real and only higher-order.

**4.2 "Invariant" is the wrong word.** Cox–Reid is **not** reparameterization-invariant for non-Gaussian
families. The `θ₀ + log-gap` unconstrained scale (`src/drmTMB.cpp:3231-3236`) is a **pinned coordinate
choice**, and any oracle must fold/adjust on the *same* coordinate. Call it "the pinned fold scale," never
"the invariant." A change of coordinates `θ → c` shifts the adjustment by `−Σ_{j≥1} θ_j` (sign: minus).

**4.3 The intercept singularity is already resolved in code.** `ordinal_mu_model_matrix()`
(`R/drmTMB.R:15288-15294`) drops `(Intercept)` from `X_mu`, so cumulative_logit location is carried only
by the cutpoints. The folded `(β, θ)` set is therefore already identified — S4 must *verify this holds
under the fold*, not add a new guard.

**4.4 AGHQ formula needs the adaptive Jacobian/reweight.** The bare `Σ_k w_k f(û + √2 Σ^{1/2} z_k)` omits
the adaptive rescale factor `√2·σ̂_m` and the `exp(z_k²)·φ(node)` reweight. Use the standard adaptive-GH
form (Liu & Pierce 1994): `∫f(u)φ(u)du ≈ √2 σ̂_m Σ_k w_k exp(z_k²) φ(û+√2σ̂_m z_k) f(û+√2σ̂_m z_k)`.
`nq=1` collapses to Laplace **only** for the adaptive form (recentre at `û`, rescale by `σ̂`); the
non-adaptive `scratchpad/aghq_node_sweep.R` (fixed nodes at 0) is a valid *oracle for the marginal* but
not the `=Laplace-at-1-node` identity.

**4.5 AGHQ symbols are TARGET, not current code.** `aghq_nodes`/`nq`, `û_m`, `Ĥ_m`, the GH nodes/weights,
and a callable conditional leaf `f(y_m|u,θ)` have **no** code counterpart today (grep-clean; the leaf
accumulates only the joint `nll` at `:3162-3167/:3239-3253`). The §5 AGHQ rows are labelled **[TARGET]**;
S5 builds them. In particular the AGHQ wrapper needs a per-cluster conditional-density extractor that
does not exist yet.

**4.6 The θ_ord TMB fold is optional / at most an intermediate.** Since O3 (the certified ordinal object)
is external-nested, folding `theta_ord` into `random=` (O2-flavour ordinal) is *not required* for the
nominal claim. Build it only if a cheap Cox–Reid-via-Laplace ordinal intermediate is wanted for
cross-checks; otherwise S4 collapses into S4b/S5 (build the external nested estimator directly). **Design
decision to ratify in S2 kickoff:** prefer building O3 directly and skip the θ_ord `random=` fold, to
avoid maintaining a second ordinal restricted-likelihood path.

**4.7 Interval construction — firewall + boundary (Fisher's catch).** Every scoping number is a
*point-estimate bias* `E[σ̂]−σ`; the promotion tier is an **interval**. Rules:
- The exp back-transform **does** transfer (`transformation="exp"`, `R/profile.R` around :1303/:1359;
  `sd_mu_re = exp(log_sd_mu)`, `src/drmTMB.cpp:3091/3176`) → endpoints land strictly positive on the
  natural RE-SD scale. **The objective does NOT transfer:** the profiler evaluates `object$obj$fn`
  (`R/profile.R:3065`) = the compiled Laplace-ML NLL; O3's restricted NLL is a *new* code path.
- Two candidate CIs: **(a) profile** of the restricted deviance `D(σ)=2[ℓ_R(σ̂)−ℓ_R(σ)] ≤ χ²₁`,
  endpoints back-transformed; **(b) Wald** from the restricted-information Hessian on `log σ`. Prefer (a).
- **Boundary correction (pre-commit):** at `σ=0` the restricted deviance is asymptotically a 50:50
  `χ²₀:χ²₁` mixture, **not** `χ²₁` — the naive `χ²₁` pivot is wrong on the boundary. cumulative_logit
  (lowest information, no residual-variance channel) hits `σ̂=0` pile-up + non-finite endpoints
  (`near_sd_boundary` at `R/profile.R:3384`; `nonfinite_interval` at :3370) far more than gamma. S7's
  gate-spec must score these explicitly.

---

## 5. Alignment tables (symbol ↔ verified code)

### 5.1 Shared latent / likelihood structure (both families)

| Symbol | Meaning | Code mapping (verified) | Enters via | Recovery | Truth/note |
|---|---|---|---|---|---|
| `β` = `beta_mu` | mean fixed effects | `PARAMETER_VECTOR(beta_mu)` `cpp:388`; `η=X_mu*beta_mu` `cpp:3089`(binom)/`:3174`(ord) | `X_mu β` | `ADREPORT(beta_mu)` `cpp:3172`(binom)/`:3257`(ord) | folded in O2; profiled+adjusted in O3 |
| `u` = `u_mu` | unit-scaled scalar RE | `u_mu` block; prior `nll-=dnorm(u_mu(j),0,1,true)` `cpp:3100`(binom)/`:3185`(ord) | `η += z·σ·u` `cpp:3095-3096`/`:3180-3181` | `REPORT(u_mu)` | `N(0,1)` prior; SD lives in η |
| `σ` = `exp(log_sd_mu)` | **RE-SD (the estimand)** | `sd_mu_re=exp(log_sd_mu)` `cpp:3091`/`:3176`; `ADREPORT(sd_mu_re)` `cpp:3105-3106`/`:3190-3191` | multiplies `u` in η | `sdr$value["sd_mu_re"]`; profile on `log_sd_mu` | **outer** in all 3 objects; truth e.g. 0.5 |
| `Ĥ_m`=`H_uu` | u-block Hessian at mode | TMB inner Laplace (`MakeADFun random=`, `R/drmTMB.R:465/469`) | — | `obj$env` internals (no public extractor) | adaptive-node curvature = this |

### 5.2 Binomial (model_type 18) — object O2

| Symbol | Meaning | Code mapping | Note |
|---|---|---|---|
| `p_i` | success prob | `logp1=-logspace_add(0,-eta_mu(i))` `cpp:3154`; `mu(i)=exp(logp1)` `:3156` | logit link |
| binom leaf | `y·logp1+(n−y)·logp0` | `nll-=weights(i)*(...)` `cpp:3162-3167`; trials `:3161` | the conditional `f(y|u,β)` |
| fold(O2) | append β to random set | `mean_fixed<-"beta_mu"` `R/drmTMB.R:865`; `tmb_random_names<-c(random_names,mean_fixed,scale_fixed)` `:892` | `scale_fixed` empty (no dispersion) `:890` |
| `½log|S|` | Cox–Reid penalty | emergent from joint Laplace `−½log|H_joint|` | = glmmTMB REML; approximates exact Cox–Reid (§4.1) |
| oracle | glmmTMB(REML=TRUE) | `scratchpad/reml_binom_only.R` | tight ~1e-6 target (identical joint-Laplace fold) |

### 5.3 Cumulative_logit (model_type 13) — object O3 (nested)

| Symbol | Meaning | Code mapping | Note |
|---|---|---|---|
| `θ`=`theta_ord` | cutpoint params (unconstrained) | `PARAMETER_VECTOR(theta_ord)` `cpp:394` | **location** fixed effects (enter as `c_k−μ`) |
| `c_k` | ordered cutpoints | `cutpoints(0)=theta_ord(0)`; `cutpoints(j)=cutpoints(j-1)+exp(theta_ord(j))` `cpp:3231-3236` | pinned `θ₀+log-gap` scale (§4.2) |
| ord leaf | ordinal probs of `c_k−μ` | `drm_log_inv_logit`/`_diff`/`log1m` `cpp:3239-3253`; `ADREPORT(cutpoints)` `:3258` | no offset (contrast binom `:3089`) |
| intercept | dropped from `X_mu` | `ordinal_mu_model_matrix()` `R/drmTMB.R:15288-15294` | resolves the fold singularity (§4.3) |
| O3 inner | AGHQ marginal over `u` | **[TARGET]** external wrapper (S5) | rolled ref `cumlogit_reml_scoping.R:98-111` |
| O3 outer | Cox–Reid adjust over `(β,θ)` | **[TARGET]** `−½log|I_{(β,θ)}|` via `optimHess` | scale-matched to `θ₀+log-gap` |
| oracle | rolled O3 (~1e-2) + within-drmTMB objective identity | scoping-grade only | **no external tight oracle** (glmmTMB/glmer can't fit ordinal) |

### 5.4 AGHQ integrator — **[TARGET, unbuilt]** (both families)

| Symbol | Meaning | Code mapping | Note |
|---|---|---|---|
| `nq`/`aghq_nodes` | node count | **none** — add to `drmTMB()` sig `R/drmTMB.R:175-187` | grep-clean; proposed |
| `û_m` | per-cluster Laplace mode | **none** — from `obj$env` inner solve | adaptive recentre point |
| `z_k,w_k` | GH nodes/weights | **none** in DLL; Golub-Welsch in `scratchpad/aghq_node_sweep.R` | eigen of Jacobi matrix |
| adaptive sum | `√2σ̂ Σ w_k e^{z_k²}φ(node)f(node)` | **[TARGET]** external R wrapper | `nq=1`⇒Laplace (adaptive form only, §4.4) |
| node-conv | `nq∈{48,128,256}` check | **[TARGET]** S6 | converges to exact ML, cannot cross variance floor |

---

## 6. Consequences for the build legs (feeds S2–S6b)

1. **S2/S3 (binomial):** relax **both** gates (§3); the existing `beta_mu` fold gives **O2 = glmmTMB
   REML** → validate to ~1e-6 vs `glmmTMB(REML=TRUE)`. Correct, small, tight. No AGHQ needed for binomial.
2. **S4 (ordinal):** prefer **skip** the θ_ord `random=` fold (§4.6) and build **O3 directly**; verify the
   intercept is already dropped (§4.3). If an O2-flavour ordinal intermediate is wanted, add the θ_ord
   fold branch + start/map handling.
3. **S4b + S5 + S6 (the O3 core):** build the external **nested** estimator (§2) — AGHQ inner (S5) +
   Cox–Reid outer — with the adaptive Jacobian (§4.4). Validate: AGHQ(binomial) vs `glmer(nAGQ=k)`;
   AGHQ(ordinal) vs rolled GH marginal; node-convergence `nq∈{48,128,256}`; the recombined O3 vs the
   rolled reference (scoping ~1e-2) + a within-drmTMB objective-identity check (no external tight oracle).
4. **S6b (interval — the certified object):** implement the profile of `ℓ_R` in `log σ` with the
   **50:50 χ² boundary correction** (§4.7); prove endpoints on the `exp()` RE-SD scale; firewall — no
   coverage strength borrowed from the point-bias ladder.
5. **S7 (gate-spec):** carries the estimation↔inference firewall, the M-specific directional pre-commit
   (bias is non-monotone in M), SD=0 boundary scoring, ordinal-internally-validated label, and the
   two-gate ledger edits (new estimator values `REML`+`AGHQ`; `test_capability_ledger.py` count decrement).

## 7a. Validation log (spike-level, pre-package)

**Binomial O2 — BUILT + VALIDATED (2026-07-18).** Gates A+B relaxed to admit binomial
(`R/drmTMB.R:234`, :2144). Deterministic identity **drmTMB REML == `glmmTMB(REML=TRUE)`** RE-SD to
**7.3e-9**; REML debiases upward vs ML; vcov finite. Regression test
`tests/testthat/test-reml-binomial-coxreid.R` (8 assertions), conformance registry updated, full REML
suite 96 pass / 0 fail.

**AGHQ integrator — MATH PROVEN (2026-07-18), `scratchpad/aghq_spike_binomial.R`.** Adaptive-GH marginal
(with the §4.4 Jacobian/reweight): vs brute-force `integrate()` **2.8e-14** (nq=25); **nq=1 ⇒ Laplace
exact** (diff 0); full AGHQ MLE vs `glmer(nAGQ=25)` RE-SD **9.3e-6**. AGHQ lifts the RE-SD
(nq1 0.976 → nq25 1.025).

**Ordinal O3 (nested) — MATH PROVEN (2026-07-18), `scratchpad/aghq_coxreid_cumlogit_spike.R`.** In
drmTMB's exact cumulative-logit parameterization (θ₀+log-gap cutpoints, no mu intercept): (a) ordinal
AGHQ marginal vs brute-force `integrate()` **6.4e-9** (nq=15); (b) **nq=1 ⇒ Laplace 1.1e-13**; (c) the
bias-reduction ladder is **monotone up** — Laplace-ML −19.7% → AGHQ-ML −18.0% → **AGHQ+Cox–Reid −13.9%**
on one M=30 draw, reproducing the scoping direction and the "Cox–Reid > AGHQ" ordering. (Single-draw
residual is large at M=30; this is a direction/ordering proof, NOT a coverage claim — coverage is S10.)

**Status:** the math for BOTH levers on BOTH families is proven pre-package. Remaining is package
engineering (wire `aghq_nodes=`/O3 into `drmTMB()`), the interval path (S6b), the frozen gate-spec (S7),
smoke (S9), then the gated Totoro coverage campaign (S10).

## 7. Provenance

Derived + adversarially verified by the S1 workflow (`wf_523438af-908`, 4 derive → 9 skeptic-lens verify
→ 1 completeness critic, 2026-07-18). Supersedes the plan's initial "Cox–Reid = one-line gate-relaxation"
framing for the ordinal/recombined case; binomial gate-relaxation stands. Extends
`docs/design/221-native-reml-finish.md` (Gaussian REML) to the non-Gaussian, AGHQ-augmented case.
