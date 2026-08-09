# Binomial link generalisation — probit and cloglog

Status: **scoped, not started. Target 0.7.1, deliberately NOT 0.7.0.**
Owner decision 2026-08-09. This note exists so the arc is not rediscovered from scratch;
every finding below was verified by inspection and is cited.

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

drmTMB is **logit-only, everywhere**, not merely in MSPL:

| Site | What it does |
|---|---|
| `R/drmTMB.R:2924-2932` | `drm_family_type()` rejects any non-logit binomial |
| `R/methods.R:5680` | `drm_dpar_link()` maps binomial → `c(mu = "logit")`, one link per model_type |
| `R/methods.R:5633-5646` | `drm_inverse_link()` switch has **no probit/cloglog case** |
| `R/mspl-estimator.R:73-77` | MSPL request guard requires `binomial(link="logit")` exactly |
| `src/drmTMB.cpp` | `model_type == 18` **is** the family+link tag. No `link_code` exists anywhere |

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
  `stats::make.link()$mu.eta`.
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

This, plus the missing `drm_inverse_link()` cases, is why Emmy recommended against 0.7.0 and why the
arc moved to 0.7.1: both gaps were found *by direct inspection* in a bounded review of a decomposition
that looked complete, in a **first CRAN submission** already behind a fail-closed gate.

## 6. Deliberately untouched — say so, do not silently widen

- `R/associate-pairs.R:1199-1211` (`drm_pair_validate_bernoulli`) — stays logit-only.
- `R/missing-data.R:236-244` (imputation-model classifier) — stays logit-only.

## 7. MSPL stays logit-only, even in 0.7.1

Kosmidis & Firth's **fixed-effect** finiteness result generalises to probit, log-log, cloglog and
cauchit — any link with ω(η) → 0 as η → ±∞ (`ENGINEERING-NOTEBOOK.md:1055-1061`). Those ω(η) are just
the binomial working weight, so no paper lookup is needed, and the condition self-checks: the weight
does tend to 0 for both links.

But **Sterzinger & Kosmidis leave the probit and cloglog bounds for the *mixed-effects* case as future
work** (`docs/design/250-mspl-binomial-logit-alignment.md:76-78`). MSPL's guarantee comes from the
*composite* penalty — Jeffreys on β plus negative-Huber on the covariance Cholesky — and that
composite has published guarantees for logit only.

**Therefore `drm_validate_mspl_request()` keeps rejecting non-logit.** The link-general Jeffreys helper
is built and unit-tested as internal scaffolding; it is not reachable from the public API. Extending
MSPL itself to other links is a *research* arc requiring either derived bounds or our own evidence,
and must not be described as a port.

## 8. Test surface — update, do not delete

`tests/testthat/test-binomial-response.R:206-212` and `tests/testthat/test-mspl-estimator.R:412-418`
currently assert that non-logit links are **rejected**. When the links are admitted, the first flips to
positive assertions; **the second stays a rejection test**, because §7 keeps MSPL logit-only.

New evidence required: `glm()` parity for probit and cloglog fixed effects, recovery on a
random-intercept fixture, `predict(type = "link")` vs `type = "response"` round-tripping through the
new `drm_inverse_link()` cases, and extreme-η tail behaviour proving the log-scale forms beat the clamp.

## 9. Open question for the owner

Does a new **link** need its own capability-ledger evidence cells, or does it inherit binomial's?
`AGENTS.md` rule 1 covers a new *family*; a link variant is not obviously one. This must be settled
before any ledger movement, because it determines whether probit/cloglog need their own recovery and
coverage campaigns or ride on existing binomial evidence.
