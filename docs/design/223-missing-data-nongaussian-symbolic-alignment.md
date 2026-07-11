# 223 — Missing-data → non-Gaussian: P0 symbolic-alignment gate

**Status:** P0 gate — **SIGNED & CLEARED 2026-07-10** via a 3-reviewer adversarial pass: Noether
(math↔engine) + Fisher (inference) **CLEARED**; Rose (completeness-critic) returned
**CHANGES_REQUIRED → resolved** (§7). Clearance followed a **§4 scope correction** the critic
surfaced — non-Gaussian *builders* do not construct the missing-response mask, so P1 is **four**
edits/family, not three. P1–P3 unblocked; next in plan order is P4a (loud per-family guardrails).
Blocks were: P1–P3 of the missing-data
non-Gaussian ultra-plan (`~/.claude/plans/crystalline-tinkering-fog.md`; handover
`docs/dev-log/handover/2026-07-10-claude-handover.md`).
**Branch:** `drmtmb/missing-data-nongaussian` (off `main` = `ceed999c`, v0.4.0 released).
**Author:** Fable (enumeration). **Sign-off required:** Noether (math↔engine contract),
Fisher (inference / recovery target). See §7.
**Ground-truthed:** 2026-07-10 against `src/drmTMB.cpp` (4143 lines),
`src/drm_count_kernels.h`, `R/drmTMB.R`, `R/missing-data.R`. Re-grep before editing —
the engine file churns.

Companion: `docs/design/149-missing-data-design.md` (MD-slice history).

---

## 1. Purpose

Pin, as the *recovery target* for every priority family, the exact mean-link and
dispersion parameterization as implemented — **before** any numeric code is written.
The bug this gate prevents: the recovery test simulates against one parameterization
while the engine uses another, so the test passes (or fails) against the wrong truth.
The nbinom2 dispersion (§3.4) is the live trap: the code stores the *reciprocal* of the
externally meaningful `size`.

Priority families (maintainer order): **Gaussian (done) → binary/binomial → count
(Poisson, nbinom2) → % (beta)**. All 18 families are censused in §5 for the
scaffold-and-warn matrix (P4).

---

## 2. Corrected family → model_type census (all 18)

Source: the `spec$model_type` string dispatch and the integer each block returns
(`R/drmTMB.R`, dispatch at ~15837–16985; verified line-by-line 2026-07-10).

| family (`spec$model_type`) | model_type | priority? | C++ density block (`src/drmTMB.cpp`) |
|---|---|---|---|
| gaussian            | **1**  | ✅ done (reference) | `== 1` @685 |
| biv_gaussian        | **2**  | (bivariate; already gates observed_y1/2) | `== 2` @3489 |
| student             | 3      | deferred | `== 3` @2334 |
| lognormal           | 4      | deferred | `== 4` @2464 |
| gamma               | 5      | deferred | `== 5` @2499 |
| poisson             | **6**  | ✅ P1/P3 | `== 6` @2937 |
| nbinom2             | **7**  | ✅ P1/P3 | `== 7` @3139 (+ `drm_count_kernels.h`) |
| zi_poisson          | 8      | deferred | `== 8` @3078 |
| zi_nbinom2          | 9      | deferred | `== 9` @3422 |
| beta                | **10** | ✅ P1/P3 | `== 10` @2611 |
| truncated_nbinom2   | 11     | deferred | `== 11` @3294 |
| hurdle_nbinom2      | 12     | deferred | `== 12` @3339 |
| cumulative_logit (ordinal) | 13 | deferred | `== 13` @2871 |
| beta_binomial       | 14     | deferred | `== 14` @2797 |
| zero_one_beta       | 15     | deferred | `== 15` @2722 |
| tweedie             | 16     | deferred | `== 16` @2584 |
| skew_normal         | 17     | deferred | `== 17` @2424 |
| binomial            | **18** | ✅ P1/P3 | `== 18` @2853 |

**Traps corrected from earlier notes:** binomial = **18** (not 13); nbinom2 = **7**
(not 9); **13 = ordinal (cumulative_logit)**, not binomial. Line numbers drift ±tens.

---

## 3. Symbolic-alignment table — priority families

Convention across all dispersion families: **the internal shape/precision =
`exp(-2·log_sigma)`**, so a larger public `sigma` always means more dispersion. For
Gaussian `sigma` is the residual SD; for beta it is `precision^(-1/2)`; for nbinom2 it is
`size^(-1/2)`. `log_sigma = X_sigma · beta_sigma` in every dispersion family.

### 3.0 Gaussian (model_type 1) — REFERENCE (shipped, validated)

| Symbol (prose) | Parameterization (code) | DGP draw | Recovery extractor | Truth value |
|---|---|---|---|---|
| mean `μ` | identity: `μ = Xβ_μ (+offset)` | `mu <- X %*% b_mu` | `coef` mu block | `β_μ` |
| scale `σ` | `σ = exp(log_sigma)`, `log_sigma = X β_σ` | `sigma <- exp(X %*% b_sig)` | `coef` sigma block | `β_σ` |
| response | `y ~ N(μ, σ²)` | `rnorm(n, mu, sigma)` | — | Var `= σ²` |

Missing-y guard **already implemented for Gaussian**: the per-row `observed_y(i)` density guards
live inside the `model_type == 1` block (`src/drmTMB.cpp:~1149–2253`), and the Gaussian *builder*
constructs the mask (`R/drmTMB.R:2968–2986`; the earlier `dnorm` at ~635 is a separate aggregation
path and is not itself masked). This **builder + C++ guard** pair — not the guard alone — is the
template P1 mirrors per family. See §4: non-Gaussian builders do **not** yet construct the mask.

### 3.1 Binomial (model_type 18) — `src/drmTMB.cpp:2853–2870`

| Symbol | Parameterization (code) | DGP draw | Recovery | Truth |
|---|---|---|---|---|
| mean `p` | **logit**: `η = offset + Xβ_μ`; `log p1 = -logspace_add(0,-η)`, `log p0 = -logspace_add(0,η)`; `μ = p = plogis(η)` | `p <- plogis(X %*% b_mu)` | `coef` mu | `β_μ` (logit scale) |
| dispersion | **none** (no `σ`) | — | — | — |
| response | `y ~ Binom(trials, p)`; density `log C(trials,y) + y·log p1 + (trials-y)·log p0` | `rbinom(n, trials, p)` | — | Var `= trials·p(1-p)` |

- **Trap (missing y):** density reads `trials(i)` (`DATA_VECTOR(trials)` @275). A row with
  missing `y` kept for its predictors **must carry a finite `trials`**. Binary case
  `trials ≡ 1`.
- Guard: wrap the per-`i` `nll -=` at 2864 in `if (observed_y(i) == 1) { … }`.

### 3.2 Poisson (model_type 6) — `src/drmTMB.cpp:2937–3077`

| Symbol | Parameterization (code) | DGP draw | Recovery | Truth |
|---|---|---|---|---|
| mean `λ` | **log**: `η = offset + Xβ_μ`; `μ = λ = exp(η)` | `lam <- exp(X %*% b_mu)` | `coef` mu | `β_μ` (log scale) |
| dispersion | **none** | — | — | — |
| response | `y ~ Pois(λ)`; density `dpois(y, μ)` @3072 | `rpois(n, lam)` | — | Var `= λ` |

- MD9a already lives here: the binary-predictor `mi()` exception (`3029–3068`) hardcodes
  `dpois` and already carries an `observed_y(i)` guard (3049–3052). This is the anti-pattern
  P2 refactors away, and the reference that missing-**response** Poisson (P1) must match.
- Guard: the plain-`y` density at 3072 is currently inside a `!(has_mi && …)` filter; P1
  adds the `observed_y(i)==1` condition for the no-mi missing-response path.
- **P3 forward-note (not P1):** a row that is *simultaneously* missing-predictor and
  missing-response is not yet handled — the MD9a `observed_y` guard (3049–3052) lives only inside
  the imputation branch. P3 must specify this interaction before loosening the predictor gate.

### 3.3 Beta (model_type 10) — `src/drmTMB.cpp:2611–2721`

| Symbol | Parameterization (code) | DGP draw | Recovery | Truth |
|---|---|---|---|---|
| mean `μ` | **logit** (nudged): `μ_raw = plogis(η)`; `μ = 1e-12 + (1-2e-12)·μ_raw` @2676–2678 | `mu <- plogis(X %*% b_mu)` | `coef` mu | `β_μ` (logit scale) |
| precision `φ` | `φ = exp(-2·log_sigma) = σ⁻²` @2690; `a = μφ`, `b = (1-μ)φ` (floor 1e-8) | set `phi`; `b_sig₀ = -½·log(phi)` | `coef` sigma | `β_σ`; `σ = φ^(-1/2)` |
| response | `y ~ Beta(a, b)` @2705–2710 | `rbeta(n, mu*phi, (1-mu)*phi)` | — | Var `= μ(1-μ)/(1+φ)` |

- **Recovery truth:** to simulate at precision `φ`, the intercept-only truth is
  `log_sigma = -½ log φ`, i.e. `σ_true = φ^(-1/2)`.
- **Trap (missing y):** density evaluates `log(y)` and `log(1-y)` @2709–2710. Guard must
  wrap the **whole `log_density` block 2705–2711** (not just the `nll -=` at 2711 — otherwise
  `log(sentinel)` is still evaluated into a discarded local); sentinel outside `(0,1)` (default
  sentinel `0` → `log(0) = -Inf`) so any guard leak fails **loud**, not silently finite. See §4.
- **Non-blocking cautions (recovery design):** (i) a soft-clamp is applied to `log_sigma` *before*
  `φ` (`drm_softclamp_log_sigma` @2680–2683), **default-OFF** (`use_logsigma_clamp = 0L` unless
  `control$logsigma_clamp` set); if enabled it shifts the recovery target near the band edge — keep
  it off and keep `σ_true` inside the band. (ii) `beta_shape_floor = 1e-8` floors `a=μφ`, `b=(1-μ)φ`
  (2688–2704): an extreme cell (`μ` near 0/1 with small `φ`) can hit the floor and bias dispersion
  recovery — use moderate cells. (iii) beta uses `X_mu·β_μ` with **no `offset_mu`** (unlike
  binomial/poisson/nbinom2) — a shared offset-bearing harness silently no-ops the offset for beta.

### 3.4 nbinom2 (model_type 7) — `src/drmTMB.cpp:3139–3293` + `src/drm_count_kernels.h:31–41`

**LIVE TRAP.** The engine stores `alpha = exp(+2·log_sigma) = σ²` (`drm_count_kernels.h:33`),
and writes the NB2 log-density in terms of `alpha`. Matching term-by-term to the standard
NB2 form `Γ(y+size)/(Γ(size) y!)·(size/(size+μ))^size·(μ/(size+μ))^y`:

- `alpha = 1/size` ⟹ **`size = 1/alpha = exp(-2·log_sigma) = σ⁻²`**.
- `Var(y) = μ + alpha·μ² = μ + σ²·μ² = μ + μ²/size`. So **`σ²` is the quadratic
  overdispersion coefficient.**

| Symbol | Parameterization (code) | DGP draw | Recovery | Truth |
|---|---|---|---|---|
| mean `μ` | **log**: `μ = exp(η)` @3278 | `mu <- exp(X %*% b_mu)` | `coef` mu | `β_μ` (log scale) |
| dispersion `size` | `alpha = exp(2·log_sigma)`; `size = 1/alpha = exp(-2·log_sigma)` | set `size=θ`; `b_sig₀ = -½·log(θ)` | `coef` sigma | `β_σ`; `σ = θ^(-1/2)` |
| response | `y ~ NB2(μ, size)`; density `drm_nbinom2_log_density(y, η, log_sigma)` @3285 | `rnbinom(n, size=θ, mu=mu)` | — | Var `= μ + μ²/θ` |

- **Recovery truth:** simulate `rnbinom(size = θ, mu = μ)` ⟹ `σ_true = θ^(-1/2)`,
  `log_sigma_true = -½ log θ`. Using `size = exp(+2·log_sigma)` (the internal variable's
  form) inverts the truth: the fit lands at `-½ log θ` while a wrong-sign assertion expects
  `+½ log θ`. Under **point-near-truth** this fails **loud** for any `θ ≠ 1`; it slips through
  **only** at the degenerate `θ = 1` (`σ = 1`) cell, or under **truth-in-CI alone** when the
  `log_sigma` CI is wide enough to cover both `±½ log θ` — precisely the low-information regime
  nbinom2 lives in (Fisher). **Recovery design therefore MUST include a `θ ≠ 1` dispersion cell
  and keep point-near-truth non-optional**; that conjunction is what this gate enforces. (Same
  `φ ≠ 1` requirement for beta, §3.3.)
- Guard: wrap the density call at 3285–3286 in `if (observed_y(i) == 1) { … }`.
- **Non-blocking caution:** a soft-clamp is applied to `log_sigma` before `size`
  (`drm_softclamp_log_sigma` @3279–3282), **default-OFF** — same guidance as beta (§3.3): keep it
  off for recovery so the truth is the raw `-½ log θ`.

---

## 4. Sentinel + response-mask guard contract (P1 implementation gate)

**Ignorability (the inferential precondition, Fisher).** Masking a missing response — dropping
row `i`'s density factor from the joint — equals **marginalizing** that response out of the
likelihood (`∫ f(yᵢ|·) dyᵢ = 1`), which is valid **iff missingness is ignorable**: MAR (MCAR ⊂
MAR) **plus** a-priori distinctness of the missingness-mechanism and data-model parameters
(Rubin). MCAR is the special case the recovery sims draw. **MNAR is out of scope and must fail
loud, never silently.** (Biv already implements the correct specialization — it keeps the
observed marginal when one response is missing, `src/drmTMB.cpp:110–115`.)

**R side — the mask is built per-builder, and only Gaussian/biv build it today (BLOCKING for P1
scope; Rose).** The `observed_y <- !is.na(y_raw)` + sentinel-fill code at `R/drmTMB.R:2968–2986`
lives **inside `drm_build_gaussian_ls_spec` (@2655)** and is Gaussian-scoped (biv has its own at
6671–6690). **No non-Gaussian builder constructs a mask:** the Poisson builder hardcodes
`observed_y = rep(TRUE, length(y))` / `response_sentinel = NA_real_` (`R/drmTMB.R:5496–5497`), and
the beta (@4327), binomial (@4893), and nbinom2 (@5562) builders set neither, so the common
assembly defaults `observed_y = rep(TRUE)` (@13756). The sentinel is
`getOption("drmTMB.missing_response_sentinel", 0)` (`R/missing-data.R:310`, one finite numeric,
**default 0**); `observed_y` reaches C++ as `DATA_IVECTOR(observed_y)` (`src/drmTMB.cpp:252`).

⇒ **P1 per non-Gaussian family = FOUR edits, not three:** (a) **build the mask in the family
builder** — mirror Gaussian 2968–2986 (`observed_y <- !is.na(y_raw)` + sentinel substitution,
gated on `include_missing_response`); (b) the C++ per-row `if (observed_y(i)==1)` guard (below);
(c) loosen the R reject gate (§5); (d) the tests (below). **Skipping (a) is silent under-scoping:**
the C++ guard is present but `observed_y` stays all-TRUE and `y` is never sentinel-filled, so the
guard never fires and `NA` responses reach TMB.

**C++ side (P1, per family):** wrap the per-observation density contribution in

```cpp
if (observed_y(i) == 1) { /* accumulate nll for row i */ }
```

- **MUST be a plain data-`if`, NOT `CppAD::CondExp`.** `observed_y` is integer DATA, so a
  plain `if` is resolved at tape construction: the missing-row density — including
  `log(sentinel)` for beta — is **never taped**. A `CondExp` tapes both branches, so
  `log(0)` (beta) or `lgamma`/`dpois` at a sentinel would poison the gradient even though
  the value is discarded.
- Biv already uses this pattern (`observed_y1`/`observed_y2`, `src/drmTMB.cpp:97–114`) —
  the two-response template.

**Sentinel-invariance test (per slice; currently absent — add in P1):**
fit twice with `options(drmTMB.missing_response_sentinel = 0)` then `= 1e6` (and for beta,
also a value outside `(0,1)`); assert `logLik`, `coef`, and `sdreport` are **byte-identical**.
A correct guard makes the sentinel inert; any leak breaks byte-identity (and for beta, NaNs
loudly).

**Per-family sentinel notes:** binomial — keep `trials` finite on the masked row (§3.1);
beta — sentinel outside `(0,1)` (§3.3); poisson/nbinom2 — any finite sentinel is inert once
guarded (`lgamma(sentinel+1)`/`dpois` never taped).

---

## 5. Scaffold-and-warn census (P4 matrix seed)

The P4 capability matrix is 18 families × {missing-response, missing-predictor-response,
predictor-imputation-model, phylo, multivariate}. A cell is `✓` **only** with a passing
recovery **and** sentinel-invariance artifact; otherwise `⚠` (partial, documented), `✗`
(loud reject), or `—` (n/a). v1.0 validates rows: **gaussian, binomial, poisson, nbinom2,
beta** (+ biv_gaussian for missing-response). All other 12 families must **loudly
`cli_abort`** (P4a) — no silent partials. The current R reject gates:

- response `"include"` → `c("gaussian","biv_gaussian")` — `R/drmTMB.R:248–256`
- predictor `"model"` → `c("gaussian","poisson")` — `R/drmTMB.R:257–265`
- `impute` → `c("gaussian","poisson")` — `R/drmTMB.R:266–270`

P1 loosens the response gate one family per slice; P3 loosens the predictor/impute gates
(behind the P2 refactor). A parametrized test asserts every non-validated family still
rejects, so the matrix cannot drift.

---

## 6. Recovery-target summary (what P1/P3 tests assert)

| family | mean link | dispersion truth | intercept-only `σ` truth |
|---|---|---|---|
| binomial | logit | — | — |
| poisson | log | — | — |
| nbinom2 | log | `size = θ` | `σ = θ^(-1/2)`, `log_sigma = -½ log θ` |
| beta | logit | `precision = φ` | `σ = φ^(-1/2)`, `log_sigma = -½ log φ` |

**Per-fit recovery** is judged **truth-in-CI *and* point-near-truth** under MCAR — the
conjunction is required (point-near-truth catches the wide-CI dispersion sign-flip of §3.4).
This is an **estimation** sanity check, **not** a coverage claim: an honest **coverage/inference**
statement needs **many replicates** and a Monte-Carlo-SE'd hit-rate against nominal — a single-fit
truth-in-CI must never be reported as "coverage" (Fisher A). pdHess and any
flat-direction/identifiability flag rank **below** recovery for the verdict but must still be
**reported** alongside a passing recovery (recovery-over-pdHess ≠ ignore-pdHess; Fisher C).
Sample-size-first: non-Gaussian families carry less information per observation; run an n-ladder
before condemning any recovery. **Keep `logsigma_clamp` OFF and dispersion cells moderate** (truth
inside the clamp band; `a=μφ`/`b=(1-μ)φ` off the `1e-8` floor) so the recovery target is the raw
`-½ log θ` / `-½ log φ`, not a clamp/floor-shifted value (§3.3–3.4).

---

## 7. Sign-off (Noether + Fisher)

P0 is the gate. Before P1 code, two Opus-tier reviewers must sign the math contract, with a
completeness-critic pass alongside:

- **Noether (math↔engine contract):** confirm each §3 row's link and dispersion match the
  cited code lines exactly, and that `size = exp(-2·log_sigma)` (not `+2`) is the external
  NB2 truth.
- **Fisher (inference / recovery):** confirm the §6 truth values are what the DGP draws
  imply, and that the guard/sentinel contract (§4) yields a valid observed-data likelihood
  (masking = marginalizing missing responses out of the joint, i.e. MCAR/MAR-ignorable).

**Three** Opus reviewers ran an independent adversarial pass 2026-07-10 (against `src/drmTMB.cpp`,
`src/drm_count_kernels.h`, `R/drmTMB.R`, `R/missing-data.R`) — workflow `wf_5b0ddda3-922`. Noether
and Fisher **CLEARED**; Rose (completeness-critic) returned **CHANGES_REQUIRED** with one blocking
omission (now fixed in §4) plus non-blocking cautions (now folded into §3.2–3.4 and §6). Fisher's
sign-off carried four binding test-design conditions, folded into §3.4 (mandatory `θ≠1`/`φ≠1`
dispersion cell), §4 (ignorability), and §6 (single-fit recovery vs replicated coverage; pdHess
reported-not-ignored).

- **Noether: SIGNED (2026-07-10)** — verified §2 census (all 18 string→int + C++ blocks)
  correct; §3.1–3.4 links/dispersions match code exactly; nbinom2 external
  `size = exp(-2·log_sigma) = σ⁻²` (internal `alpha = exp(+2·log_sigma)` at
  `drm_count_kernels.h:33`); §4 plain-data-`if` guard is taping-correct and mirrors the biv
  template. No discrepancies.
- **Fisher: SIGNED (2026-07-10)** — verified the §6 recovery truths follow exactly from the
  stated DGP draws (nbinom2 `log_sigma_true = -½ log θ`; beta `log_sigma_true = -½ log φ`,
  `Var = μ(1-μ)/(1+φ)`; binomial/poisson mean-coef truths on logit/log with no σ), and that
  the plain data-`if(observed_y==1)` guard yields a valid observed-data likelihood (masking =
  exact marginalization, ignorable under MAR + parameter distinctness). Conditioned on the four
  §3.4/§4/§6 edits above (all applied).
- **Rose (completeness-critic): CHANGES_REQUIRED → RESOLVED (2026-07-10)** — core alignment claims
  independently reproduced, but flagged one **blocking** omission: §4 presented the Gaussian
  builder's mask code as generic when **non-Gaussian builders build no mask** (Poisson hardcodes
  `observed_y=rep(TRUE)` @5496–5497; beta/binomial/nbinom2 default via assembly @13756). **Fixed:**
  §4 now specifies the per-builder mask as edit (a) of a four-edit P1. Non-blocking cautions
  (soft-clamp, `beta_shape_floor`, beta guard span 2705–2711, beta offset asymmetry, P3
  missing-pred×missing-resp interaction) folded into §3.2–3.4 and §6.
