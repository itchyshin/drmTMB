# Session review note — 2026-06-27 (for Shinichi to review later)

A plain-language record of what this session achieved and what it did **not**, so
you can review the decisions without re-reading the transcript.

## Achieved (shipped + verified + banked)

1. **t-based confidence intervals — shipped as an opt-in engine feature.**
   `confint(fit, method = "wald", small_sample_df = "group")` references a
   t-quantile with `df = g-1` for structured-RE SD targets. Default behaviour is
   byte-identical; parity to a post-hoc recompute is ~1e-16. Commit `34cece73`.
   - Validated by a paired g=8/16/32 recompute: t lifts the under-covering q2
     mu-slope SD lane **0.885 -> 0.931** at g=8 and converges to z by g=32.
   - **Key nuance (your insight, sharpened):** t is *not* uniformly better. The
     dispersion (`sigma`) SDs already over-cover under z, so a blanket t default
     would *harm* them. It is opt-in and scoped to location-axis components.

2. **Cross-team advisory to the GLLVM team.**
   [gllvmTMB#565](https://github.com/itchyshin/gllvmTMB/issues/565) — the verified
   "t is not always better" finding, mapped onto gllvmTMB's own parameter classes
   (Lambda/Psi/sd_B = location, t may help; NB2 phi / Gamma shape = dispersion,
   do not apply t). Adversarially checked before posting.

3. **Repo hygiene.** All **42 superseded stacked PRs closed** (content was already
   on `main`; branches kept, reopenable).

4. **Four cells promoted to `interval_feasible`** (the honest top-of-ladder for
   the certified cells) — phylo + relmat sigma and q2 slope-only.
   - Six sign-offs first: Fisher/Rose/Emmy, then Pat + Darwin
     (SIGN_OFF_WITH_CHANGES), then your maintainer approval.
   - A 96-guard coordinated edit; verified green; non-certified cells still
     rejected. `coverage_status` stays `planned` everywhere.

## NOT achieved (and the honest reason)

1. **`supported` was not reached, and is not honestly reachable this cycle.**
   `supported` requires nominal coverage at the *deployment default* group count
   (g=8), where the q2 cells under-cover (~0.91-0.93). Closing that needs either a
   future scale-side REML derivation or accepting g>=32 as the recommendation.

2. **REML is the wrong tool for the g=8 gap** (I initially recommended it; an
   adversarial scoping pass refuted me). drmTMB's REML is location-only; the bias
   sits on the `sigma`/`rho` submodels where the restricted likelihood is a
   different, *underived* objective; the relevant q4 Patterson-Thompson correction
   lives in DRM.jl, not drmTMB. See `after-task/2026-06-27-reml-unblock-scoping.md`.

3. **spatial + animal cells were NOT promoted** — they have no g=32 run and no
   interval-reliability rung. Only phylo + relmat are certified.

4. **The deployment-g=8 under-coverage remains** for q2 (a documented small-sample
   artifact, not an engine bug). Wald-t narrows it; full nominal needs larger g.

## Needs your review / decision

- **Is `interval_feasible` for these 4 cells the right call?** It is done and
  reversible. Pat and Darwin both said keeping them `planned` *under*-represented
  the evidence; both required the claim_boundary wording now in the TSV. If you
  disagree, it is one revert.
- **The path to `supported`:** (a) commission the scale-side REML research arc
  (large, partly upstream DRM.jl), or (b) adopt "profile channel + g>=32" as the
  public deployment recommendation and treat `supported` as a future milestone.

## Open items (not blocking)

- **4 pre-existing test failures** in `test-structured-re-conversion-contracts.R`
  (artifact-path construction; present on clean `main`, unrelated to this work).
  Flagged as a background task chip.
- Genuine remaining walls, unchanged: scale-side q4 (sigma-SD lower bound),
  relmat-Q bridge (blocked upstream on DRM.jl #299/#300).

## Where it all landed

Commits on `main`: `34cece73` (t-Wald), `148329d1` (REML scoping), and the
interval_feasible promotion (this commit). Not pushed to the remote — say the word.
Durable records: design doc `218` (completion map), after-tasks under
`docs/dev-log/after-task/2026-06-27-*`, evidence under
`docs/dev-log/simulation-artifacts/2026-06-27-*`.
