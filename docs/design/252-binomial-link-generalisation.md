# Binomial link generalisation — probit and cloglog

> Companion notes: `250-mspl-binomial-logit-alignment.md` (the frozen MSPL contract, and its
> Phase 4 amendment) and `251-mspl-wald-covariance-alignment.md` (the standard-error estimand).

> **Merge note (2026-08-10).** This file was an add/add conflict when
> `claude/mspl-binomial-inference-promotion` merged `origin/main`: both branches independently wrote
> a design doc for the same arc. The `main`-side copy (landed via PR #973,
> `feat(binomial): admit probit and cloglog links`, commit `d88901699`) is the more evolved
> revision — it carries the 2026-08-09/2026-08-10 corrections to §4, §5, §7, and §9 below. The
> `claude/mspl-binomial-inference-promotion`-side copy was an earlier snapshot of the same document
> that had not yet picked up those corrections; its own load-bearing MSPL-specific addenda live in
> the companion file `253-mspl-nonlogit-links-derivation.md` (Addenda 1-3), which did not conflict
> and is unchanged by this merge. This merged version keeps the `main`-side body (it is a strict
> superset of the pre-correction snapshot — see the `<details>` block in §7, which already preserves
> the superseded text verbatim) plus this branch's companion-notes pointer above.

Status: **BUILT, TESTED, AND TARGETED AT 0.7.0 — owner decision, Shinichi, 2026-08-09:
*"I want 0.7 - we can do it."*** This SUPERSEDES the original 0.7.1 target below.

What that decision does and does not do:

- **Does:** put `binomial(link = "probit")` and `binomial(link = "cloglog")` in 0.7.0's scope.
  `--as-cran` green is now a **release-blocking gate**, not a routine check, and Emmy's §5 review
  becomes **go/no-go** rather than a recommendation.
- **Does NOT:** authorize candidate preparation. `AGENTS.md`'s standing fence still holds —
  *"NO-GO for exact-candidate work until Shinichi separately authorizes candidate preparation;
  no upload and no release-rung advance."* No `DESCRIPTION` bump, no candidate freeze.
- **Does NOT** change the claim boundary. §9 stands: the links inherit binomial's evidence cells,
  the census is unchanged, and the ceiling remains `point_fit_recovery`. Shipping a fitting
  capability in 0.7.0 is not an interval or coverage claim about it.
- **Does NOT** open MSPL to other links. §7 stands.

Original 2026-08-09 owner decision (superseded, kept for the record): target 0.7.1, deliberately
NOT 0.7.0, on Emmy's "demonstrably under-scoped" objection. That objection's two specific gaps —
the missing `drm_inverse_link()` cases and the Julia bridge — are both now closed and tested,
which is the evidence the reversal rests on.

This note exists so the arc is not rediscovered from scratch; every finding below was verified by
inspection and is cited.

**Line numbers in §2 and §5 below were written before the engine commit `5b6c13197` and had
drifted.** They are corrected in place; the original ranges are noted where the drift was
large enough to mislead a reader searching for them.

## 1. The goal, and the reason it is not the stated reason

Admit `binomial(link = "probit")` and `binomial(link = "cloglog")` to drmTMB, and generalise the
MSPL fixed-effect Jeffreys penalty across links.

The original motivation offered was "so we can extend MSPL to multinomial later." **That motivation
does not hold and should not be cited.** Multinomial logit is the softmax / baseline-category
extension of *logit*, and sits beside the existing `cumulative_logit` family. **Multinomial probit is
a different model, not a link swap** — correlated latent normals requiring high-dimensional
integration, which is precisely what TMB's Laplace machinery handles poorly. Multinomial is parked.

**The reason that does hold:** link generality is worth having on its own merits. Separation bites in
*every* binary link, including the `zi` and `hu` logistic submodels, and gllvmTMB — the sister
package — already offers all three. This is a parity and completeness gap.

## 2. Current state, measured

*(State as at scoping. Line numbers corrected 2026-08-09 after commit `5b6c13197`; the
"After" column records what the implementation actually did.)*

drmTMB was **logit-only, everywhere**, not merely in MSPL:

| Site (corrected) | Was, at scoping | After |
|---|---|---|
| `R/drmTMB.R:2828-2837` *(scoped as `:2924-2932`)* | `drm_family_type()` rejects any non-logit binomial | widened to logit/probit/cloglog |
| `R/methods.R:5613` *(scoped as `:5680`)* | `drm_dpar_link()` maps binomial → `c(mu = "logit")` | returns the fit's actual link |
| `R/methods.R:5566-5579` *(scoped as `:5633-5646`)* | `drm_inverse_link()` has **no probit/cloglog case** | both added |
| **`R/predict-parameters.R:337-358`** | **not listed at scoping — the miss** | `probit`/`cloglog` derivative arms added |
| `R/mspl.R` (MSPL branch only) | MSPL request guard requires `binomial(link="logit")` exactly | **unchanged — still logit-only** (§7) |
| `src/drmTMB.cpp` | `model_type == 18` **is** the family+link tag; no `link_code` | `DATA_INTEGER(link_code)` at `:328`; `model_type` still 18 |

**The fourth row is the one this design doc missed.** `predict_parameters_inverse_link_derivative()`
switches on `drm_dpar_link()` output for delta-method standard errors and had no probit/cloglog arm,
so the moment `drm_dpar_link()` started returning `"probit"` every `predict(se.fit)`-equivalent call
on a probit fit would have aborted. It was caught by the pre-execution plan review, not by this
inventory — the lesson being that **an inventory of "who *sets* the link" is not the same as an
inventory of "who *reads* the link string"**. The complete read-side inventory is
`scratchpad/arcD-S0-recon.md`.

**No drmTMB family currently admits more than one link**, so there is no internal pattern to copy.
The logit inverse-link is inlined by hand in **four** places: `src/drmTMB.cpp:3363-3370` (the `mi()`
two-point predictor sum), `:3406-3410` (the main mean), `:4955-4968` (the MSPL Jeffreys weight), and
`src/drm_response_kernels.h:39-46` (`case 18`).

## 3. Sister-repo prior art — borrow the pattern, not the numerics

gllvmTMB **fully implements** binomial probit and cloglog at the likelihood level:

- R: `family_to_id()` at `R/fit-multi.R:441-450` — `switch(f$link, logit=0L, probit=1L, cloglog=2L, abort)`
- C++: `DATA_IVECTOR(link_id_vec)` at `src/gllvmTMB.cpp:380`, dispatched at `:2185-2196`

**But its numerics are weaker than drmTMB's existing logit path.** gllvmTMB computes `p`, then
`gll_clamp(p, 1e-12, 1-1e-12)` before `dbinom` — a *probability-scale* clamp. drmTMB's logit path uses
the stable log-scale `logspace_add` form. **A verbatim port would be a downgrade at extreme η.**

The good news: gllvmTMB *already has* the right machinery — `gll_log_pnorm` at
`src/gllvmTMB.cpp:113-146`, a tail-safe log-scale normal CDF — but it is wired only to ordinal probit,
not to the binomial branch. So:

> **Borrow the dispatch pattern from `fit-multi.R:441-450`, and the tail-safe `gll_log_pnorm` helper
> from `gllvmTMB.cpp:113-146`. Do not borrow the clamp.**

`AGENTS.md` requires an `inst/COPYRIGHTS` provenance note plus tests around ported behaviour. Same
author does not remove that requirement.

## 4. Design

- **`DATA_INTEGER(link_code)`** (0=logit, 1=probit, 2=cloglog); **keep `model_type = 18`**. Do not mint
  new model_type values — `model_type` is consumed throughout, including `drm_dpar_link` and the
  capability ledger, and new codes would duplicate the entire binomial C++ branch.
- **Two C++ primitives, not one.** The mean sites need `(log μ, log(1−μ))`. The Jeffreys-weight site
  cannot be served by the same helper: `R/mspl.R:111`'s `log(n) − softplus(η) − softplus(−η)` is the
  *logit-specific collapse* of the general weight `n·(dμ/dη)²/(μ(1−μ))`, so it needs a second stable
  primitive — a safe `log|mu.eta(η)|` per link.
- **R side:** widen the guard; make `drm_dpar_link()` return the fit's actual link rather than a
  constant; add probit/cloglog to `drm_inverse_link()`; generalise `R/mspl.R:111` using
  ~~`stats::make.link()$mu.eta`~~ **per-link closed forms on the log scale — see the correction
  below.**

> **CORRECTION (2026-08-09, Noether — this bullet was WRONG).** Do **not** generalise
> `R/mspl.R:111` via `stats::make.link()$mu.eta`. `make.link()`'s `linkinv`/`mu.eta` clamp to
> `[eps, 1−eps]`, and `cloglog$mu.eta` floors at `.Machine$double.eps`. Using them would change the
> penalty **value**, not merely its tail accuracy, and would break the exact logit reduction — a
> silent reparameterisation, and the same probability-scale downgrade §3 refuses when it declines
> gllvmTMB's clamp. This bullet prescribed for MSPL exactly what §3 forbids for the likelihood.
>
> The implemented forms are closed-form on the log scale:
> `probit: log n + 2·dnorm(η, log) − pnorm(η, log.p) − pnorm(η, lower=FALSE, log.p)` ·
> `cloglog: log n + 2η − exp(η) − log μ`, where `log μ` needs its **own** two-branch form —
> the direct `log(-expm1(-exp(η)))` is right as `η → +∞` but returns `+Inf` (wrong sign) below
> `η = −745.13`, where `exp(η)` underflows to 0. Use the series `η + log1p(−exp(η)/2)` there.
>
> Delivered on `claude/mspl-binomial-inference-promotion`, not on the Arc D branch — MSPL is on
> neither Arc D nor `main`. **The MSPL entry point remains logit-only regardless** (§7); the helper
> is internal scaffolding. The paired C++ weight at `src/drmTMB.cpp:4965-4968` is deliberately left
> logit-only and must be generalised in the same arc that opens the entry point.
- **Rename `mspl_logit_jeffreys()`** (`R/mspl.R:70`) — a link-specific name on a link-general function
  is a defect in waiting.

## 5. The hazard that moved this out of 0.7.0

**Widening the admissibility guard silently breaks the Julia bridge.**
`drm_julia_bridge_family_type()` (`R/julia-bridge.R:481-490`) special-cases `binomial(link="logit")`
and falls through to `drm_family_type()` for everything else. **Today that fallthrough errors on
non-logit binomial — so the guard is doubling as the bridge's safety net.** Widen it and the bridge
silently returns the plain `"binomial"` tag for probit and cloglog, while **DRM.jl implements logit
only**. That is a silent-mislabelling regression: a wrong model that runs and returns numbers, not a
loud failure.

**The Julia bridge must be explicitly re-gated in the same change**, not left to inherit the widened
guard. Audit all three sites: `R/julia-bridge.R:481-490`, `:3839-3843`, `:502-504`.

**RESOLVED (2026-08-09).** The re-gate landed in `5b6c13197` and all three sites were re-audited at
their *current* line numbers:

| Site today | What it is | Verdict |
|---|---|---|
| `R/julia-bridge.R:496-507` | `drm_julia_bridge_family_type()` | **GUARDED** — explicit local `cli_abort` on non-logit binomial, no longer deferring to `drm_family_type()` |
| `R/julia-bridge.R:3857-3861` | `drm_julia_xfam_family_tag()` | **GUARDED** — independently returns NULL for non-logit binomial |
| `R/julia-bridge.R:~521` | phylo-family name list | **N/A** — not link-resolution logic |

The hazard is closed and has a **live regression test that predates this arc**:
`tests/testthat/test-julia-phylo-nongaussian.R:54-64` asserts probit and cloglog are rejected with a
`DRM.jl` message. It passes unchanged after the guard was widened — which is the actual proof that
the bridge no longer leans on the native guard.

This, plus the missing `drm_inverse_link()` cases, is why Emmy first recommended against 0.7.0: both
gaps were found *by direct inspection* in a bounded review of a decomposition that looked complete,
in a **first CRAN submission** already behind a fail-closed gate. Both are now shut —
`drm_julia_bridge_family_type()` aborts on any non-logit binomial, and `drm_inverse_link()` carries
`probit = stats::pnorm(eta)` and `cloglog = -expm1(-exp(eta))` — which is what let the owner move the
arc back to 0.7.0.

## 6. Deliberately untouched — say so, do not silently widen

- `R/associate-pairs.R:1199-1211` (`drm_pair_validate_bernoulli`) — stays logit-only.
- `R/missing-data.R:236-244` (imputation-model classifier) — stays logit-only.

## 7. MSPL stays logit-only, even in 0.7.0

> **SUPERSEDED 2026-08-12 — the entry point now admits probit and cloglog.** This section's verdict
> stood until the evidence it implicitly asked for existed. It does now: four pre-registered
> campaigns, 460,000 fits, recorded in
> `docs/dev-log/simulation-artifacts/2026-08-11-mspl-nonlogit-links/` and adjudicated in
> **design 253, Addendum 4** — finiteness (0 non-finite in 43,972 completed fits), calibrated Wald
> standard errors in the identified regime, and a softness constant whose logit calibration costs
> ~1% of one standard error for the other two links.
>
> **What this section got right and is retained:** log-log and cauchit are *still not admitted*
> (drmTMB has no `link_code` for them and no evidence was gathered), the `c_n` scaling is *still*
> the logit constant, and intervals are *still* unavailable. The reasoning below is therefore
> correct as written — read it as the state of the question before 2026-08-11, not as current
> behaviour. §4's table row and the closing note in §6 about the rejection test are likewise
> superseded; the rejection test became a positive assertion in
> `tests/testthat/test-mspl-nonlogit-links.R`.

Kosmidis & Firth's **fixed-effect** finiteness result generalises to probit, log-log, cloglog and
cauchit — any link with ω(η) → 0 as η → ±∞ (`ENGINEERING-NOTEBOOK.md:1055-1061`). Those ω(η) are just
the binomial working weight, so no paper lookup is needed, and the condition self-checks: the weight
does tend to 0 for both links.

> **CORRECTED 2026-08-10, after reading all three source papers.** The paragraph that stood here was
> **factually wrong** and is preserved at the bottom of this section. It claimed *"Sterzinger &
> Kosmidis leave the probit and cloglog bounds for the mixed-effects case as future work"* and that
> *"that composite has published guarantees for logit only."* **Neither is true.**
>
> **The paragraph immediately above, however, was right all along** — and is now confirmed at source.
> **Kosmidis & Firth (2021), *Biometrika* 108(1):71–82, §3.1 p. 76:** *"If the link function is such
> that ω(η) → 0 as η diverges to either −∞ or ∞, then the proofs of Theorem 1 and Corollary 1 carry
> through **unaltered** … The logit, probit, complementary log-log, log-log and cauchit links are some
> commonly used link functions for which ω(η) → 0."* Their **Table 1** tabulates ω for all five.
> Theorem 1 requires **only that X be full rank**; Corollary 1 holds for **any** penalty power `a > 0`.
>
> The composite extends too. **Sterzinger & Kosmidis (2023), p. 6:** the penalised log-likelihood
> *"diverges to −∞ as β diverges, for any value of ψ"*, because the marginal likelihood is
> *"bounded from above by one as a probability mass function"* — **link-free**. And the
> variance-component penalty (their eq. 5) is a function of the Cholesky alone; it never sees the link.

### The real gap is the LAPLACE APPROXIMATION — and it is LINK-INDEPENDENT

**Sterzinger & Kosmidis (2023), p. 6**, on their own sufficient condition:

> *"A weaker sufficient condition is that the penalized objective diverges to −∞ … From the numerous
> numerical experiments we carried out, **we encountered no evidence that this weaker condition does
> not hold for the adaptive quadrature and Laplace approximations** … that the glmer routine of the R
> package lme4 employs."*

The proof runs through the **exact** marginal likelihood being ≤ 1. **The Laplace criterion is not so
bounded**, so for Laplace the authors offer numerical evidence rather than proof — and that evidence
is **glmer's, not TMB's**. drmTMB penalises the Laplace `nll` (`src/drmTMB.cpp:5019`).

> **So the finiteness guarantee behind the logit route we ALREADY SHIP rests on the same footing as
> probit and cloglog would.** The obstruction is the approximation, not the link.

### CORRECTION 2 (2026-08-10, from the gllvmTMB team) — the correction above was TOO BROAD

The rewrite above said the authors do not defer probit/cloglog. **That is right about EXISTENCE and
wrong about the ASYMPTOTICS**, and the distinction is the whole point:

| result | link-general? | source |
|---|---|---|
| Jeffreys barrier / finiteness of the fixed effects | **YES — proved** | KF2021 Thm 1 + §3.1 + Table 1 |
| composite existence, exact likelihood | **YES** | 2023 p. 6, link-free second half |
| **softness scaling `c = 2√(p/n)`** | **NO — derived for logit** | 2023 §7, p. 7 |
| **asymptotic gradient bound (Thm C.1)** | **NO — logit constants** | 2023 §7 / Appendix C |

2023 §7, p. 7: *"we propose using c₁ = c₂ = c to be the square root of the average of the approximate
variances of η̂ᵢⱼ **at β = 0**. **A delta method argument gives that c = 2√(p/n)**."* Under logit
`ω(0) = ¼`, so `Var(η̂) ≈ 4p/n` and `c = 2√(p/n)`. **Under probit `ω(0) = 2/π ≈ 0.637`, and the same
argument gives `c ≈ 1.25√(p/n)`.** Theorem C.1's bound `‖∇P₍f₎‖ ≤ p^{3/2} max|x_st|/2` carries the
same logit-derived constants.

So the *softness* half — the thing that buys consistency, asymptotic normality and Cramér–Rao
efficiency — **is** logit-specific, and non-logit bounds **are** future work. The original §7 was
closer to right than the first correction; it simply conflated two results that need separating.

**Therefore `drm_validate_mspl_request()` keeps rejecting non-logit, for two honest reasons:**
1. **the softness scaling is unproved for non-logit** — `c = 2√(p/n)` is a logit delta-method
   result, so drmTMB's `c_n` is the wrong constant for probit/cloglog and the ML asymptotics the
   estimator is built to preserve are not established there;
2. **we have no drmTMB-Laplace evidence for any link**, and none at all for non-logit `W`.

Reason 1 is link-specific and is genuinely open research. Reason 2 is link-*independent* and applies
equally to the logit route we ship. The link-general Jeffreys helper stays internal scaffolding,
unreachable from the public API.

For the full derivation behind these two corrections — including a third correction from an
external (gllvmTMB-team) review that refined Correction 2's scope — see the companion file
`253-mspl-nonlogit-links-derivation.md`, Addenda 1-3.

<details><summary>Superseded paragraph, kept for the record</summary>

> But **Sterzinger & Kosmidis leave the probit and cloglog bounds for the *mixed-effects* case as
> future work** (`docs/design/250-mspl-binomial-logit-alignment.md:76-78`). MSPL's guarantee comes
> from the *composite* penalty — Jeffreys on β plus negative-Huber on the covariance Cholesky — and
> that composite has published guarantees for logit only.

Why it was wrong: the 2023 paper cites its link condition to "Kosmidis and Firth 2021, Section 3.1"
**without restating it**, so a reader without that paper sees a deferral where there is a citation.
Full account: `docs/design/253-mspl-nonlogit-links-derivation.md`, Addendum 2.

</details>

## 8. Test surface — update, do not delete

`tests/testthat/test-binomial-response.R:206-212` and `tests/testthat/test-mspl-estimator.R:412-418`
currently assert that non-logit links are **rejected**. When the links are admitted, the first flips to
positive assertions; **the second stays a rejection test**, because §7 keeps MSPL logit-only.

New evidence required: `glm()` parity for probit and cloglog fixed effects, recovery on a
random-intercept fixture, `predict(type = "link")` vs `type = "response"` round-tripping through the
new `drm_inverse_link()` cases, and extreme-η tail behaviour proving the log-scale forms beat the clamp.

## 9. SETTLED — a new link inherits binomial's evidence cells

*Owner decision, Shinichi, 2026-08-09. This section previously read as an open question.*

**Question.** Does a new **link** need its own capability-ledger evidence cells, or does it inherit
binomial's? `AGENTS.md` rule 1 covers a new *family*; a link variant is not obviously one.

**Decision: it INHERITS.** A link is not a new family — same likelihood, same distributional
parameters, same random-effect structure; only `g(mu)` changes. Consequences, all binding:

- **No new recovery or coverage campaign** for probit or cloglog. No Totoro, no DRAC, no
  pre-registration.
- **The capability ledger and the frozen census are UNCHANGED** by this arc. Nothing is promoted.
- **The claim ceiling stays `point_fit_recovery`.** The `glm()` parity, random-intercept recovery,
  round-trip, and tail tests in §8 establish that the links are *wired correctly*. They do **not**
  establish interval calibration or coverage for these links, and no such claim may be made.

The honest one-line statement of what this arc earns: *drmTMB fits binomial probit and cloglog, with
the same evidence standing behind them as binomial logit — no more.*

### §8 addendum — what was actually built

`tests/testthat/test-mspl-estimator.R` **does not exist on the Arc D branch**: MSPL lives on
`claude/mspl-binomial-inference-promotion` and is not on `main`. Its rejection test therefore stays
a rejection test *on that branch*, and §4/§5's MSPL Jeffreys generalisation is unreachable from Arc
D — it belongs to the MSPL lane. The correct range for the first file is `:206-213`, not `:206-212`.
(Both branches are merged together as of the 2026-08-10 merge note at the top of this file, so both
`test-mspl-estimator.R` and `test-binomial-links.R` now coexist on this tree; the "does not exist on
the Arc D branch" statement above is a historical record of the pre-merge state, not a description of
the current tree.)

Delivered in `tests/testthat/test-binomial-links.R`: `glm()` parity (both links), random-intercept
recovery (both links), the response/link round-trip, extreme-η tail accuracy against a naive
`1e-12` probability clamp, `cauchit` still rejected — plus one test §8 did not anticipate, standard
errors through `predict_parameters()`, guarding the §2 miss.
</content>
