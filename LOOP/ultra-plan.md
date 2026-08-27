# Ultra-plan — S6 A7 / drmTMB #962 first family

🎯 GOAL: Wire C++ `has_mi` for **Gamma** (`model_type` 5) with one
binary missing predictor, recover a known DGP, and add
`mp-gamma-bernoulli` on the existing `missing_predictor` axis.

## G0 mini-plan (locked this kickoff)

Shinichi said "start A7" and allowed "likely Poisson **or document the
choice**". Documented choice:

| Candidate | Why not first |
|---|---|
| Poisson | Already wired. `mp-poisson-bernoulli` exists. Binary `has_mi` in `model_type == 6`. Not a #962 family. |
| binomial / nbinom2 / beta | Same: already in `drm_missing_predictor_families()`. |
| **Gamma** | **First unwired row in #962.** `drm_build_gamma_ls_spec` never calls mi-setup. No `has_mi` in `model_type == 5`. No `case 5` in `drm_response_log_density`. |

**First cell:** Gamma response × Bernoulli predictor (one binary
`mi()`). Matches the existing non-Gaussian sibling pattern. Not
Gamma × Gaussian (later cell). Not k = 2.

**Ledger row:** `mp-gamma-bernoulli` (axis already exists; do not
invent a second axis). Evidence `ev-mp-gamma-bernoulli-g3`. Honest
tier: `point_fit_recovery` if MCAR recovery lands; do not claim G4/G5
or `"covered"`.

**Acceptance**

1. C++: Gamma leaf in `drm_response_log_density` + `has_mi &&
   mi_family == 1` in `model_type == 5`. Clamp `log_sigma` before the
   2-point sum (beta lesson).
2. R: `drm_build_gamma_ls_spec(..., impute =)` wires mi-setup;
   `"gamma"` added to `drm_missing_predictor_families()` **after** the
   C++ path exists.
3. Tests: logLik ≡ hand 2-point sum; MCAR recovery; MAR smoke;
   non-binary / RE / structured still fail loud; capability-gate
   `predictor_validated` includes `gamma`.
4. Ledger: one new row, one new evidence row. No rewrite of existing
   `mp-*` cells (foreign ledger lanes own promotions).
5. drmSEM: document the new engine cell; do **not** lift drmSEM `R/`
   until this PR is on an engine the SEM suite can see.

**Next family after this PR:** lognormal (`model_type` 4) — second
unwired row in #962, same log-link / location-scale shape.

## Compute

**Totoro or DRAC?** Default **laptop / local** for the logLik identity
and n ≈ 3e3 MCAR/MAR smoke. Ask before a replicated grid. Not GitHub
Actions.

## Reviewers (self-check)

- Gauss: C++ leaf matches the Gamma main-loop density.
- Curie: recovery-to-truth, not plumbing-only.
- Rose: no `"covered"`; Poisson is not claimed as new.
- Fisher: ledger tier matches the test that actually shipped.

## Pre-authorisation

Shinichi: start A7; push/PR allowed; merge if CI green and slice
coherent. Still stop: capability `"covered"`, whitelist-only, MAG
worktrees, dirty primary, FIML/`impute_joint` claims.
