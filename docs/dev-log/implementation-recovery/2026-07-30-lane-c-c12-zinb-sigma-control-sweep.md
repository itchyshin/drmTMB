# C12 sweep receipt — ZINB sigma-control corridor

## Scope

Build only the complete-response ML control
`bf(count ~ x, sigma ~ 1 + (1 | group), zi ~ 1)` and then rerun the existing
`mc-0653` C11 fixture against that integrated source. No other ZINB random-
effect grammar is opened.

## Prior-work receipt

| Surface | Evidence run | Finding | Forced call |
|---|---|---|---|
| Lane safety | `bash /Users/z3437171/shinichi-brain/tools/lane_preflight.sh .` on 2026-07-30 | No Claude lane detected in the preceding 12 hours; this is weak evidence only. Preserved C3/C9/Z4 untracked material is present. | Lane C only; never stage preserved artifacts. |
| Repository | `git status --short`; `git rev-parse HEAD`; C11 receipts and `tools/run-lane-c-c11-zi-nbinom2-sigma-phylo-interaction-local-recovery.R` | C11's structured four-seed result passed, but the required IID `sigma ~ (1 | pair)` control aborted before fitting. | Build the missing ordinary model-9 sigma carrier, then rerun every structured seed. |
| Source map | `rg -n 'validate_nbinom2_sigma_random_terms|zi_nbinom2_start|make_tmb_data|model_type == 9' R/drmTMB.R src/drmTMB.cpp` | The R validator rejected every ZINB sigma RE; start/map/data discarded `re_sigma`; model type 9 had no IID sigma contribution or Gaussian prior. Generic extraction already used `spec$random$sigma`. | Implement the full carrier, not a validator-only exception. |
| Ledger | `rg -n -C 2 'mc-0633|mc-0653' docs/dev-log/dashboard/capability-ledger/{cells,evidence,transitions}.tsv`; `python3 tools/capability_ledger.py --check` (pre-promotion baseline) | `mc-0633` is rejected-by-design, `mc-0653` is not-implemented. The live source counts are 695 rows, 345 implemented, 330 rejected-by-design, 20 not-implemented, and 197 point-fit-recovery. | Any later transition must be cell-specific and generator-verified. |
| Twin and brain | C12 prior-work sweep: DRM.jl ZINB/phylo-interaction search; `search_notes("drmTMB C11 C12 capability ledger not_implemented", search_all_projects=TRUE)` | DRM.jl supplies no reusable ZINB sigma-RE fitter; no earlier C12 implementation exists. | Build the local R/TMB gap only. |

## Decision

**Build the gap.** The IID ZINB sigma q1 control is a distinct capability
prerequisite. It does not make `mc-0653` or any other structured route
point-fit recovered without fresh integrated evidence.
