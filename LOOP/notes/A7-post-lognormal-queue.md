# A7 — Post-lognormal queue (#962 remainder)

**Update 2026-08-27.** Shinichi authorized parallel
`mp-student-bernoulli`. The `nu` wait below is lifted **without**
extending the shared leaf ABI — see
`LOOP/notes/A7-student-nu-abi.md` on `cursor/lane-s6-student-mi`.
This scout file is otherwise historical.

**Status.** Read-only scout (2026-08-27). No C++. No whitelist edit.
**Lane.** `~/local-scratch/lanes/drmTMB-s6-family-gate` on
`cursor/lane-s6-family-gate`. Notes only.
**Sources.** drmTMB `origin/main` @ `b49619a7c` (includes #1088 Gamma
`6e5538797` / `mp-gamma-bernoulli`); this worktree is even with
`origin/main`; GitHub [#962](https://github.com/itchyshin/drmTMB/issues/962)
(open; next-family comment names **lognormal**);
`LOOP/notes/A7-family-matrix.md` (recon; **stale as a G0** — see
`A7-g0-gamma.md`); drmSEM consumer
`LOOP/notes/A7-consumer-contract.md` / `A7-claims-guardrails.md`.

**Locked order (do not re-open).** Gamma shipped → lognormal ×
Bernoulli in flight → then continue **#962 unwired responses**.
Expand-gated `nbinom2 × gaussian` is later unless Shinichi overrides.

`A7-family-matrix.md` still ranks `mp-nbinom2-gaussian` first. That
was pre-G0 recon. Live G0 overrode it: #962 greenfield first, not a
predictor-type expansion on an already-gated family.

---

## Verdict (read this first)

**After lognormal × Bernoulli lands, the next implementable #962
cell is `mp-beta-binomial-bernoulli` (C++ M).**

Student and zi-* stay on the #962 list but should **wait**.

| Rank | cell_id | Response × predictor × k | C++ | Action |
|---:|---|---|---|---|
| **1** | `mp-beta-binomial-bernoulli` | beta_binomial × bernoulli × 1 | **M** | **Do next** |
| **2** | `mp-student-bernoulli` | student × bernoulli × 1 | **L** | **Wait** (`nu`) |
| **3** | `mp-zi-poisson-bernoulli` | zi_poisson × bernoulli × 1 | **L** | **Wait** (`zi` + `mi` conflict) |

`mp-zi-nbinom2-bernoulli` is the same wait as rank 3, one extra
dispersion dpar. Not a separate third slot.

---

## 1. Who still lacks `has_mi` entirely

Checked on `origin/main` @ `b49619a7c` and this worktree (same tree).
`DATA_INTEGER(has_mi)` is global; wiring is per `model_type` block.
`drm_response_log_density` (`src/drm_response_kernels.h`) has leaves
only for cases **1, 5, 6, 7, 10, 18**. The `default` returns
`Type(0.0)` — admitting a family without a leaf would silently drop
the response density in the 2-point sum.

### Has `has_mi` today (not this queue)

| Response | `model_type` | Predictor support | Ledger |
|---|---:|---|---|
| gaussian | 1 | full catalogue + `has_mi2` | 13 + k=2 rows |
| poisson | 6 | Bernoulli only | `mp-poisson-bernoulli` (G2 only) |
| nbinom2 | 7 | Bernoulli only | `mp-nbinom2-bernoulli` (G3) |
| beta | 10 | Bernoulli only | `mp-beta-bernoulli` (G3) |
| binomial | 18 | Bernoulli only | `mp-binomial-bernoulli` (G3) |
| Gamma | 5 | Bernoulli only | `mp-gamma-bernoulli` (G3, #1088) |

Whitelist (`drm_missing_predictor_families()`):
`gaussian`, `poisson`, `binomial`, `nbinom2`, `beta`, `gamma`.
Lognormal is **not** on it yet (in flight).

### Still zero `has_mi` (response side)

| Response | `model_type` | Spec calls mi-setup? | #962? |
|---|---:|---|---|
| **lognormal** | 4 | **no** (`drm_build_lognormal_ls_spec` has no `impute`) | **in flight** |
| **student** | 3 | **no** | yes; `nu` |
| **beta_binomial** | 14 | **no** | yes |
| **zi_poisson** | 8 | n/a — Poisson spec **rejects** `mi()` + `zi` | yes; wait |
| **zi_nbinom2** | 9 | n/a — nbinom2 spec **rejects** `mi()` + `zi` | yes; wait |
| tweedie | 16 | no | not in #962 title (`nu` / power) |
| zero_one_beta | 15 | no | no |
| truncated_nbinom2 | 11 | no | no |
| hurdle_nbinom2 | 12 | no | no (extra `hu`) |
| cumulative_logit | 13 | no | no |
| skew_normal | 17 | no | no (`nu` / slant) |
| biv_* | 2 / 19 / 20 | `mi()` inside bivariate rejected | — |

Predictor-side `mi_family == 12` (beta_binomial **as a parent of a
Gaussian response**) is unrelated and already shipped
(`mp-gaussian-beta-binomial`). Same for lognormal/gamma/tweedie as
*predictors*.

No `missing_predictor` ledger row exists for any remaining #962
**response**.

---

## 2. Ranked queue of 3 (after lognormal × Bernoulli)

Clone template is #1088: C++ `has_mi && mi_family == 1` in the
response block, matching `drm_response_log_density` leaf, clamp
**before** the 2-point sum, skip mask on the observed-x loop, then
R `impute` on the spec builder, **then** allow-list, then recovery +
ledger. Do not flip the gate first.

### 1. `mp-beta-binomial-bernoulli` — **M — do next**

| | |
|---|---|
| **Why this** | Last remaining #962 family that is a clone, not a new derivation. drmSEM already treats `beta_binomial` as a first-class count node (cbind trials; V-49 / V-85). A SEM loses `mi()` the moment any node is beta-binomial. |
| **C++ M** | New `has_mi` in `model_type == 14` (~3381) + new `case 14` leaf. `trials_val` is already on the kernel signature (used by binomial). Density is already in the main loop (lgamma trials / phi / alpha / beta_shape). Clone the Gamma Bernoulli block onto `eta_mu` (logit), pass `trials(i)`. Spec today has **no** `impute` argument (`R/drmTMB.R` ~6315) and the dispatcher does not forward it (~490). Same R plumbing as Gamma/lognormal. |
| **Not S** | S is “clone `mi_family == 0` into an already-wired block.” This is greenfield `has_mi` + leaf + spec. Same bucket as Gamma / in-flight lognormal. |
| **Not L** | No third dpar. No mixture. No kernel ABI change. |
| **Refuse while shipping** | non-Bernoulli predictor; k=2; `mi()` + response mask; RE/structured on response `mu`. |
| **SEM** | Proportion-with-trials / survival-style cbind nodes. Consumer lift is a later drmSEM slice, V-80 locked to the engine list. |

### 2. `mp-student-bernoulli` — **L — wait (`nu`)**

| | |
|---|---|
| **Why listed** | #962 names student immediately after lognormal. Identity-location continuous response is SEM-useful (robust residual). |
| **Why wait** | `nu = 2 + exp(eta_nu)` is a live third linear predictor (`model_type == 3` ~2554–2564). The shared leaf has **no `nu` slot** (`eta_val, log_sigma_val, V_known_val, trials_val, link_code` only). Wiring student without extending that ABI (or inlining a one-off density) is a new derivation, not a clone. #962 already flagged this. |
| **C++ L** | Kernel signature change (touches every existing call site) **or** a student-only inline 2-point sum; clamp-before-sum vs `eta_nu`; identity-mean update (not log-`eta_mu`); spec has no `impute` (~3962). |
| **Do not** | Stuff `nu` through `V_known_val`. Do not admit `"student"` on the allow-list first. |

### 3. `mp-zi-poisson-bernoulli` — **L — wait (`zi` + `mi`)**

| | |
|---|---|
| **Why listed** | #962 last pair (`zi_poisson` / `zi_nbinom2`). |
| **Why wait** | Product already refuses the combination. Poisson spec (~7211–7215): “not implemented with zero inflation yet.” nbinom2 spec (~7747–7758) rejects `zi` on the first `mi()` slice. The locked emit is `mi()` in **`mu` only**; a zi mixture is `P(y=0) = zi + (1-zi) Pois(0 │ μ)`. The 2-point sum must use that mixture, and the leaf has no `eta_zi`. This is a composition decision, not a missing clone. |
| **C++ L** | New mixture leaf (cases 8 / 9); decide whether `mi()` may enter `zi` (today: no); lift a deliberate abort. |
| **zi_nbinom2** | Same wait + `sigma`. Do not start here to “get both zi families.” |

---

## 3. Cells that should wait (also not this queue)

| Cell | Why wait |
|---|---|
| `mp-nbinom2-gaussian` (and poisson/binomial/beta × gaussian) | Expand-gated. C++ is Bernoulli-only by design. Valuable SEM cell; **later unless Shinichi overrides.** |
| Any non-Gaussian × k=2 | `has_mi2` is Gaussian-shaped. After that family’s × gaussian × 1, not after lognormal. |
| `impute_joint` / FIML | A3 prior art. Not A7. |
| tweedie × bernoulli | Extra-#962. Power/`nu` hardness like student. |
| hurdle_nbinom2 × bernoulli | Extra `hu` dpar; same class as zi. |
| zero_one_beta / ordinal / skew / biv | Extra-#962. Inflation, cutpoints, slant, or explicit `mi()` reject. |
| truncated_nbinom2 × bernoulli | Cleanest *extra-#962* clone (nbinom2 leaf exists; trunc density is not that leaf). Only if Shinichi wants a third **implementable** cell after beta_binomial and still refuses student/zi. Not a #962 row. |

---

## 4. Scope key (same as the matrix)

| Mark | Meaning |
|---|---|
| **S** | 60–120 lines in an **already-wired** `model_type` + R abort exception + test + ledger. The expand-gated × gaussian cells. |
| **M** | S plus new `has_mi` + new kernel leaf + spec `impute` plumbing + allow-list **after** C++. Gamma shipped; lognormal in flight; **beta_binomial next**. |
| **L** | New derivation (kernel ABI, extra dpar, mixture). Student, zi-*, tweedie power, hurdle. |

---

## 5. What this scout did not do

- No C++. No allow-list edit. No ledger write. No push.
- Did not start lognormal (in flight elsewhere).
- Did not touch MAG worktrees or the dirty drmTMB primary checkout.
- Did not treat `A7-family-matrix.md` as live G0.
- drmSEM consumer gate is not this lane. Capability stays `partial`
  (`A7-claims-guardrails.md`).
