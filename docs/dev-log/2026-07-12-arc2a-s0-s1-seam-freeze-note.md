# Arc 2a — S0 seam-map + S1 grammar-freeze note (pre-implementation)

Status: **read-only investigation complete, 2026-07-12.** Executes slices S0 and S1 of
`docs/dev-log/2026-07-12-arc2a-random-intercept-all-families-ultra-plan.md` so the live
toolchain session can start S2/S3 without re-deriving the seam. No package behaviour changed.

---

## S0 — Seam-map (change-map) + DRM.jl twin scan

### Per-family edit recipe (verified) — see the plan for full detail
Shared & family-agnostic (**no per-family edit**): `build_random_mu_structure`
(`R/drmTMB.R:11764`), the `map` (`factor(NA)` when empty, `:16363`), and all extractors
(`ranef`/`VarCorr`/BLUP via `transform_mu_random_effects` `:18991`). Per family: (1) rejection→
permissive validator, (2) call `build_random_mu_structure`, (3) real data block, (4) `u_mu`
start + `random_names`, (5) **one copied C++ `if(n_mu_re_terms>0){…}` block** from poisson
`src/drmTMB.cpp:3054-3105`.

### DRM.jl twin scan — result
- **binomial: reusable precedent EXISTS.** `DRM.jl/src/binomial.jl:80-125` (`_fit_binomial_ranef`)
  already fits a logistic `(1 | g)` random intercept via **GHQ/Laplace marginal**, supports
  crossed/nested `(1|g)+(1|h)`, and draws the boundary "phylo structured effects cannot be combined
  with ordinary random effects yet" (`:72`). Corroborates drmTMB's intended approach and — note —
  the twin's choice of **GHQ** aligns with the NotebookLM finding that AGHQ is the fix for
  small-cluster RE-SD bias (a *future* option; Arc 2a stays on TMB-Laplace).
- **skew_normal: no precedent.** `DRM.jl/src/skewnormal.jl:51` explicitly "supports fixed effects
  only (no random effect on the mean)" — mirrors drmTMB's current gap.
- **cumulative / others:** the twin's general RE marginalization (`gaussian_ranef.jl`) is an
  **analytic Gaussian-only Woodbury/matrix-determinant-lemma** path ("for a mean random effect the
  marginal is exactly Gaussian") that does **not** generalize to non-Gaussian families.
- **Net:** the twin offers a helpful binomial design cross-check but **no reusable non-Gaussian RE
  parameterisation**. The reuse anchors remain drmTMB's own working non-Gaussian TMB-Laplace
  branches (poisson, nbinom2, gamma, beta_binomial).

---

## S1 — Grammar freeze

### Parse-path uniformity (answers Boole's plan-review question)
`(1 | g)` bar terms are handled by the **shared, family-agnostic** `extract_random_mu_terms`
(`R/drmTMB.R:8076`). Of the 5 target families:

| Family | Builder calls `extract_random_mu_terms`? | Where it rejects today |
|---|---|---|
| binomial | **yes** (`R/drmTMB.R:5427`) | post-extract validator, `:5429` |
| skew_normal | **yes** (`:3728`) | `validate_skew_normal_random_terms`, `:8645` |
| tweedie | **yes** (`:4404`) | `validate_tweedie_random_terms`, `:8697` |
| zero_one_beta | **no** | `drm_reject_phase1_terms` loop, `:4991` (syntactic) |
| cumulative_logit | **no** | `formula_contains_call(rhs, "|")`, `:5704` (syntactic) |

**Finding:** 3/5 already parse the bar term and only need the *validator* relaxed. The 2 syntactic
rejecters (zero_one_beta, cumulative_logit) must additionally have `extract_random_mu_terms` +
`build_random_mu_structure` **inserted into their builders** — mirroring the poisson call site
(`:6147`), no bespoke parse branch. **cumulative_logit does NOT need special parsing** (Boole's
question, resolved): the family-agnostic extractor suffices, and the intercept-drop that makes the
RE identifiable is already handled downstream in `ordinal_mu_model_matrix` (`:14604`).

### The frozen grammar for Arc 2a
Accepted: **`(1 | g)`** on the `mu` formula only — one or more **crossed/nested intercept** terms
(`(1|g) + (1|h)`). Rejected (unchanged): random **slopes** `(1 + x | g)` / `(x | g)`; labelled
covariance `(1 | p | g)`; any bar on `sigma`/`nu`/`zi`/`hu`/`zoi`/`coi`; structured markers
`phylo()/relmat()/spatial()/animal()` combined with `(1|g)`. These keep their current rejection
messages.

### Freeze implication for S2/S3
- **zero_one_beta, cumulative_logit:** add the extract+build calls, then the permissive validator.
- **binomial, skew_normal, tweedie:** relax the validator only (parsing already in place).
- All 5: add the copied C++ accumulation block (S3) — the parsing change alone does nothing until
  the branch reads `u_mu`.

---

## Handoff pointer
Next: **S2 (R wiring) + S3 (TMB wiring + tweedie fix-`p`)** — a live-toolchain session (Codex or a
compiling Claude session), single shared-seam passes over `R/drmTMB.R` and `src/drmTMB.cpp`, then
recompile and run the per-family DG2 sentinels (S4). Evidence bar = DG2 + honest small-cluster
caveat; DG3 deferred. See the ultra-plan for the full spine and copy-from templates.
