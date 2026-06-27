# After-task: scoping the biv_gaussian structured-RE REML "unblock"

Meta: 2026-06-27 · Claude (ultracode) · adversarially-checked scoping workflow
(3 readers → inference_reviewer verdict → inference_reviewer challenge). READ-ONLY
analysis; promotes nothing; corrects a recommendation I made one turn earlier.

## Why

After shipping the opt-in t-Wald CI (commit 34cece73), I recommended "unblock
biv_gaussian structured-RE REML" as the next lever to close the residual q2
g=8 gap (~0.93 vs 0.95). Before doing engine work I scoped whether that is real.

## Verdict (adversarially confirmed)

**REML is the wrong tool for the g=8 coverage gap.** Evidence:

- drmTMB native REML is exact restricted ML marginalising only the mean **fixed**
  effects (`R/drmTMB.R:825-833`) — location-only by construction.
- The g=8 bias lives on the structured location-**scale** SD (`sigma`/`rho`
  submodels). `docs/design/199:50-60`: a scale-side field makes the conditional
  covariance depend nonlinearly on latent scale values, so the restricted
  likelihood there is a **different, underived** objective. Scope-gate rows fence
  `sigma`/q2/q4 REML as `unsupported_until_derived`.
- The only relevant correction (q4 Patterson–Thompson) lives in **DRM.jl**, not
  drmTMB (no `.jl` sources in this repo). HSquared AI-REML is explicitly barred
  from q4/scale-axis (`docs/design/178:185-187`, `179:3-5`).
- The sole banked REML un-shrinkage evidence (`test-reml-bias-simulation.R`) is an
  **ordinary** random intercept, location-only, n_id=18 — the wrong cell. There is
  **no in-repo evidence** REML moves a structured-SD centre at g=8; the g=8
  shortfall has not even been shown to be a centre-bias problem REML could touch.

The biv block (`drm_validate_reml_spec_biv`, `R/drmTMB.R:2000-2003`) rejecting
structured means is therefore an **honest** rejection, not a missing feature to
relax. (A separate, large estimation deliverable — derive the structured-mean
bivariate restricted likelihood, bank a failing reference, then narrow the guard
— is tractable but reaches only the mean axis, not where the bias sits.)

## Correction to the prior recommendation

My last-turn "REML is the honest path to the goal" was overclaimed; the
adversarial challenge refuted it (`verdict_overclaimed = true`,
`objection_survives = true`). The validated path is the **profile channel at
adequate g** (g-sweep capstone + interval-reliability rung: certified-nominal
0.948-0.958 at g=32; q4-location pdHess 48.6%→5.0% / 22.9%→0.0% by g=32). The
repo capstone already attributes the q2 fix to the profile channel and lists
"REML would also fix it" as untested conjecture.

## Implication for the goal

The Q-series technical ladder is complete via profile at adequate g. `supported`
at the deployment default is **not** honestly reachable this cycle by any engine
lever; the finish line is the named maintainer + Pat + Darwin design decision
(promote the g=32-certified phylo+relmat cells to `interval_feasible`, the
~185-guard HOLD-gated edit) or accept g>=32 as the deployment recommendation.
Recorded in `docs/design/218` (completion map) and the scoping artifact
`docs/dev-log/simulation-artifacts/2026-06-27-reml-unblock-scoping/`.

## Boundary

No cell promoted; `mission_control_ok` green; this is a feasibility finding, not
a capability change.
