# After Task: phylo_coef_profile_bridge — mu multi-coefficient profile batching (stronger partial)

**Date:** 2026-06-21 (autonomous; Ada orchestrating, session 6)
**Worktrees:** drmTMB `/Users/z3437171/.codex/worktrees/540b/drmTMB` (branch
`shannon/overnight-audit-gaps-20260619`); DRM.jl
`/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main` (branch
`shannon/overnight-audit-verify-20260619`).
**Lane:** Julia-via-R bridge only. Engine-vs-engine PROFILE parity, NOT interval
coverage, NOT a native-TMB-standalone or direct-DRM.jl claim, NOT release/CRAN.

## Goal

Land the do-now slice the session-5→6 handover nominated (§4): batch the
`phylo_coef_profile_bridge` mu fixed-effect coefficient profiles so a single
`confint(parm = <all mu coefs>, method = "profile")` makes ONE bridge round-trip
instead of one call per coefficient. Lands a STRONGER PARTIAL — multi-coefficient
batching was the headline item in the cell's `next_action`; `covered` stays out of
reach (sigma-boundary + warm-start prereqs remain).

## Key finding: multi-row infra existed but was bivariate-only, and a target-count gate blocked coef batching

The bivariate q4 path already had a multi-row bridge payload (`result$multi`) and an
R multi-row builder (`drm_julia_inference_confint_multi`) — but both joined rows by
*dpar*, which is wrong for mu coefficients (they all share `dpar == "mu"`). And the
profile router ran every request through `drm_julia_validate_inference_targets`,
which admitted exactly ONE target (univariate) or FOUR axes (bivariate) and rejected
2+ coefficient targets outright. So batching needed FIVE coordinated edits, not the
three the handover sketched: the validator gate and the `call_inference`
option-merge were the two non-obvious ones, and both were caught by the test failing
(not by reading) — the option-merge silently dropped `profile_param` when
`profile_coef` was NULL, and the validator rejected the 2-coef request before the new
routing ran.

## What was done

- **DRM.jl `src/bridge.jl`** — new profile branch for `profile_param` set with
  `profile_coef` absent → `profile_result(fit; parm = block)` once, adapt each row
  with `bounded = isfinite(lower) && isfinite(upper)` (profile rows carry no
  `bounded` field, which the multi-flatten reads), emit via the existing
  `_bridge_inference_flatten_multi_profile` (`multi = true`). Single-coef path
  unchanged.
- **drmTMB `R/julia-bridge.R`**:
  - `drm_julia_call_inference`: inject `profile_param` whenever non-NULL (was: only
    when BOTH param and coef were non-NULL); add `profile_coef` only for a single
    coefficient — so the param-only "whole block" signal reaches the bridge.
  - `confint.drmTMB_julia`: `is_multi_coef` (profile + >1 fixed-effect targets) ⇒
    `prof_coef <- NULL`. Single-coef and bootstrap paths unchanged.
  - `drm_julia_validate_inference_targets(targets, method)`: new method-aware case
    admitting ≥2 same-block fixed-effect coefficient targets for PROFILE only;
    bootstrap multi-coef still falls through to the existing error (single-coef
    contract preserved).
  - `drm_julia_inference_confint_multi`: per-target join — fixed-effect rows match by
    coefficient name (`result$coef`); SD rows keep the dpar join. Endpoints used on
    the link scale (identity transform), no exp.
  - Registry `drm_julia_capability_comparison()` `phylo_coef_profile_bridge` row:
    refreshed `syntax`, `drmjl_status`, `claim_boundary` (multi-coef parity evidence
    + fit-route caveat), `next_action` (batching banked; sigma + warm-start remain).
    `claim_status` stays `partial`. Regenerated both capability TSVs.
- **drmTMB `tests/testthat/test-julia-inference.R`** — new "Stage A multi-coef" test:
  one batched `confint(parm = c("mu:(Intercept)", "mu:x"), method = "profile")` vs
  native per-coefficient tmbprofile, swept seeds {42, 7, 13, 101} × n_tip {40, 80}.
  On every fit-agreeing cell it asserts batching returned both coefficients
  (`have_rows`, `j_nrow == 2`, profile-engine label) and endpoints match native ≤ 1e-4.
- **Artifact** `docs/dev-log/simulation-artifacts/2026-06-21-phylo-coef-profile-multi-batch/`
  (`parity.tsv` + `README.md` + seeded `generate.R`).

## Verification (live, this session, callr-isolated)

- Diagnostic (seed 42, n_tip 40): the batched call returns 2 rows, both
  `julia_profile_result`; endpoints vs native — (Intercept) max 2.3e-5, (x) ~1e-6.
- Artifact grid (16 cells): 10 well-fit, max |Δendpoint| 2.43e-5; every batched call
  `j_nrow == 2`. 6 cells excluded — the engine='julia' phylo-mean fit returns a
  garbage positive logLik there (+650 … +2.0e15 vs native −42 … −79), the tracked
  Route A fit bug, NOT a batching defect.
- `test-julia-inference.R` (widened 4-seed grid): FAIL 0, all green — Stage A single +
  Stage A multi-coef + Stage B + the rest; no regression.
- `test-julia-biv-q4-reml.R` 10/10 — the SD-axis dpar join is intact after the
  `confint_multi` change.
- DRM.jl #164 crossed/phylo hetero tests, capability gate (113/113), and
  `validate-mission-control.py` (`mission_control_ok`) all green (re-verified at
  session start and after the edits).

## Review

- **Fisher (inference): GO (conditional) → GO after fixes.** Caught that the
  `good_fit = fit_agree && have_rows` conflation let a batch-join regression on a
  WELL-FIT cell be silently excluded instead of failing the test (only the anchor
  cell's survival kept `expect_gt(nrow(good), 0)` passing). Fixed: the batching
  assertions now gate on `fit_agree` ONLY, so a valid fit that fails to batch fails
  the test. Also flagged the headline 2.43e-5 came from seed 101 (artifact-only) —
  widened the test grid to the artifact's 4 seeds so CI verifies it. Flagged the
  coef-name join's first-match assumption (unique design-matrix labels); added a
  guard comment for future factor-expansion blocks.
- **Rose (claim-boundary): GO with tightening.** Confirmed `claim_status` stays
  `partial` and the boundary lists every limitation. Caught the test-vs-prose
  evidence-scope drift (test ran 2 seeds, prose cited 4) — resolved by widening the
  test. Asked that the garbage-fit RATE be disclosed as a fit-route limitation, not
  deflected; added the explicit "10 of 16 valid; the batching does not repair the fit
  route" caveat to the claim_boundary and README.

Both verdicts re-verified locally (not trusted blind): re-ran the widened test and
the gate/validator after applying the fixes.

## Boundaries respected

Bridge lane only. Multi-coefficient PROFILE batching for the mu block; bootstrap stays
single-coefficient; sigma coefficient profiles still not offered; warm-start still not
reachable through the bridge. `claim_status` unchanged (`partial`); only the
`phylo_coef_profile_bridge` registry row's descriptive fields moved. No GPL code
referenced. The underlying Route A phylo-mean fit bug is pre-existing and untouched.

## Next (separate slices)

- Boundary-robust `parm = :sigma` profiling (diverges toward log-sigma → −∞) — the
  remaining blocker for a `covered` phylo_coef profile claim.
- Warm-start THROUGH the bridge (needs an RE-conditional `simulate` first), per
  design 179.
- A uniqueness guard on `julia_coef` if/when a batched block can produce repeated or
  empty coefficient labels (factor expansions).
- The tracked Route A garbage-logLik phylo-mean fit bug
  (`test-julia-tmb-parity.R:465`) — separate; it caps how much of the phylo-mean
  profile grid is usable.
