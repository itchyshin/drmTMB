# Plan vs actual — live Workflow G engine=julia (#499)

Date: 2026-08-09  
Plan: Live WF-G Julia ultra-plan (Cursor)  
Reconciler: Melissa (light)

## Axes

| Axis | Planned | Actual | Tag |
|---|---|---|---|
| Scope | drmTMB-only live R WF-G 11-cell gate; clean WT; advance #499 no closes | Same + necessary FE family-tag unlock + cbind/meta_V marshalling fixes | adaptive |
| Evidence | local testthat on new file | 11/11 PASS (~193 s); gate/bridge suites green | — |
| Model routing | Composer/Grok scout; Cursor parent build | Cursor Agent executed linear slice in clean WT | adaptive |
| Safety gates | no dirty primary; no DRM.jl src; D-111 off | Held | — |
| Public claims | experimental 11-cell live parity only | NEWS + after-task claim fence match | — |
| Handoff | PR advances #499 | PR opened from `feat/499-wfg-live-julia` | — |

## Deviations

1. **FE family-tag unlock** — plan said avoid `R/julia-bridge.R` unless marshalling
   bug; existing intentional gates blocked 9/11 FE cells. Opening FE tags was
   required for the stated outcome (gate message already awaited coefficient-scale
   parity). **adaptive**.
2. **Marshalling fixes** (cbind columns; meta_V keyword/namespace rewrite) —
   surfaced by live gate; required for meta-analysis-V and binomial-trials.
   **adaptive**.

## Drift to Rose

None material. Do not inflate to “Julia is default” or “#499 closed”.
