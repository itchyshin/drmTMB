# Codex handover — 2026-06-28: small-sample interval arc → q2 at `inference_ready`

Meta: 2026-06-28 · from Claude Code (author) · to **Codex** (resumer) · cross-tool.
You are **Codex**, picking up the drmTMB Q-series structured-RE completion lane. You
never saw the Claude session that produced this; everything you need is below and in
the linked repo files. Read `AGENTS.md` first (native), then this doc.

---

## ‼ Critical Context (read these three first)

1. **THE ENTIRE SESSION IS UNPUSHED — the work will be lost if the branch is not pushed.**
   `origin/main` is at `c1e9d15a`; local `main` and the branch
   `claude/local-coverage-grids-sigma-q2` are **15 commits ahead at `9ae75bf1`**, on
   **no remote**. The handover commit (this doc + the `AGENTS.md` snapshot) lands on that
   same branch. **Pushing is the maintainer's call** (project rule + global "push only
   when asked"). If you/the maintainer do not push
   `claude/local-coverage-grids-sigma-q2`, a fresh checkout sees NONE of this. → **Ask
   the maintainer to `git push -u origin claude/local-coverage-grids-sigma-q2` before
   anything else.**

2. **Run R with the segfault-safe invocation.** The `.Rprofile` loads an R-4.5 library
   that **segfaults R 4.6**. Always:
   `R_PROFILE_USER=/dev/null Rscript --no-init-file <script>` (and the same env for
   `R CMD`/`devtools`). Every tool/ script in this arc assumes it.

3. **The bias correction is now the DEFAULT.** `confint(fit)` and
   `summary(fit, conf.int = TRUE)` now apply a t(g−1) width + a `+log(g/(g−1))` centre
   shift to **location-axis (`mu`/`mu1`/`mu2`) structured** (`phylo`/`spatial`/`animal`/
   `relmat`) SD targets — by default. Opt-out: `small_sample_df="none"` and/or
   `bias_correct="none"` (raw z, byte-identical to the old behaviour). Broader opt-in:
   `"group"` (both axes, labelled-covariance blocks too). `supported` is **withheld**
   (real defects — see below); the cells sit at `inference_ready`.

---

## Goals / mission (the durable "why")

`drmTMB` = fast univariate/bivariate distributional regression (TMB). The standing
mission this lane serves is the **Q-Series Structured Random-Effect Completion Plan**:
walk each support cell (`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`,
mapped in `docs/design/218-structured-q-series-completion-map.md`) up the ladder
`planned → … → interval_feasible → inference_ready → supported`. **Terminal tier =
`supported` at the deployment default (g=8).**

- **Covered this session:** the *small-sample interval* sub-arc. **q2 mu-slope cells
  (phylo, relmat) reached `inference_ready`** (interval + coverage).
- **NOT covered (and why):** `supported` (real defects, needs a REML/skew arc — below);
  **animal q2** (under-covers even at g=32: pedigree effective-df ≪ g); **q4/q8**
  (pdHess-blocked at small g); **non-Gaussian structured** (engine-*rejected* at the
  formula gate — implementation arc, not a promotion).

## Plans / roadmap (beyond the immediate next steps, by leverage)

1. **`supported` for q2** — the real arc, two honest routes: (a) **unblock REML for
   biv structured-location models** (principled: REML debiases the slope-SD by the exact
   df, removing both defects), or (b) a **skew-aware interval**. Both are real engine +
   simulation work; see Blockers.
2. **sigma → `inference_ready`** — achievable now via the profile channel (sigma reaches
   nominal at g=8 via `method="profile"`; the default z over-covers = safe). Needs its
   own bounded sign-off.
3. **spatial q2 → climb** — spatial q2 has g=32 profile-nominal (0.95–0.97) + g=8 bc+t
   nominal, but starts at `planned`; would need the full rung climb.
4. Effective-df refinement of the correction; animal-specific treatment; q4 Hessian work.

---

## What Was Accomplished (concrete, this session)

The breakthrough chain (all committed, `c1e9d15a..9ae75bf1`):

- **`confint(..., method="wald")` small-sample machinery** (`R/profile.R`): opt-in
  `small_sample_df` (t(g−1) width) → opt-in `bias_correct` (centre shift `+log(g/(g−1))`)
  → **made DEFAULT** (`= c("location","none","group")`, default `"location"`) for
  location-axis structured SD. Helpers `wald_target_df`, `wald_target_log_bias`,
  `wald_sd_target_is_location_axis`, `structured_sd_group_count`. Group count `g` resolves
  from `object$model$structured$phylo_mu$group_levels` (NOT the empty covariance-block
  registry, NOT the augmented `n_re`). New test `tests/testthat/test-wald-small-sample-default.R`.
- **Engine-validated coverage** (fresh `confint` fits, not post-hoc): pooled **0.954
  (MCSE 0.005) at the deployment default g=8** across all 4 providers (0.94–0.97);
  g=16 0.954, g=32 0.953. Near-boundary (SD=0.35) conservative 0.96–0.97. Artifacts in
  `docs/dev-log/simulation-artifacts/2026-06-27-bias-corrected-*`.
- **Math honesty correction (Noether, blocking):** the `log(g/(g−1))` shift is **~2× the
  leading-order REML SD term `0.5·log(g/(g−1))`** — *simulation-calibrated*, NOT "REML in
  closed form." Corrected in `docs/design/219`, `218`, and the roxygen `@references`.
- **12 verified citations** in `REFERENCES.bib` + `@references` on `confint.drmTMB` +
  design doc `docs/design/219-structured-re-small-sample-bias-correction.md`.
- **Tier moves:** 4 cells → `interval_feasible` (commit `5c1008ec`, six sign-offs); then
  **phylo/relmat q2 → `inference_ready`** (commit `9ae75bf1`, interval + coverage), with
  documented-limitations claim_boundary.
- **Hygiene:** posted advisory **gllvmTMB#565** ("t is not always better"); closed **42
  superseded PRs**; fixed 4 pre-existing artifact-path test failures (`c5d1716c`).
- **Negative results banked (do not retry):** single-level parametric bootstrap does NOT
  recover the centre bias; REML is not a *quick* g=8 fix.

## Current Working State

- **Working:** default-corrected `confint`; **validator `mission_control_ok`**; full test
  suite **19588 PASS / 0 FAIL / 43 SKIP** (skips = `{JuliaCall}` absent); conversion test
  FAIL 0 / PASS 6209. Tree clean.
- **In progress:** none (clean working tree; all committed).
- **Withheld / not done:** `supported` (defects); `sigma → inference_ready` (offered, not
  executed); animal q2 (excluded); q4/q8; non-Gaussian.

## Key Decisions & Rationale

- **`supported` withheld — deliberately.** Two measured defects: a **~6:1 right-tail miss
  asymmetry** at SD≈0.9 (upper limit mildly anti-conservative), and **g-dependent
  under-correction** (relmat g=12 ≈0.93). The asymmetry persists even at the *oracle*
  centre-shift magnitude → it's a **sampling-distribution-shape** problem (the log-normal
  interval), not a centre-bias tweak. So `supported` is a real arc, not a label.
- **Correction is location-axis only.** Dispersion (`sigma`) SDs already over-cover; the
  shift would push them further conservative. Gauss found `sigma` structured SD *also*
  resolved a `g` (shared `log_sd_phylo` name) and explicitly excluded it.
- **Default-flip needed no fixture regen:** parity/fixture sidecars store *status strings*,
  not interval *values*. Only the default-interval-value path changed.
- **Validator guard design:** unified `_promoted_status_ok(qrow, field)` (cell-id + field +
  tier keyed) in `tools/validate-mission-control.py` admits `inference_ready` for exactly
  the 2 q2 cells on interval+coverage status; everything else still pinned `planned`.
  Rose-checked: a non-certified cell raises 60 errors, over-promotion to `supported`
  raises 29.

## Files Created / Modified (session diff `c1e9d15a..9ae75bf1`)

Source/tests/docs:
`R/profile.R` · `REFERENCES.bib` · `man/confint.drmTMB.Rd` ·
`tests/testthat/test-wald-small-sample-default.R` ·
`tests/testthat/test-structured-re-conversion-contracts.R` ·
`tools/validate-mission-control.py` ·
`docs/design/218-structured-q-series-completion-map.md` ·
`docs/design/219-structured-re-small-sample-bias-correction.md` ·
`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`

Validation tooling (all run with the segfault-safe invocation):
`tools/validate-bias-corrected-coverage-g8.R` ·
`tools/validate-bias-corrected-coverage-g8-spatial-animal.R` ·
`tools/validate-bias-corrected-coverage-multi-g.R` ·
`tools/validate-bias-corrected-secondgrid.R` ·
`tools/validate-bias-corrected-q4-location.R`

After-task reports (link, don't re-read in full):
`docs/dev-log/after-task/2026-06-27-t-wald-confint-opt-in.md` ·
`…/2026-06-27-interval-feasible-promotion.md` · `…/2026-06-27-reml-unblock-scoping.md` ·
`…/2026-06-27-interval-reliability-rung.md` ·
`…/2026-06-27-gsweep-certification-and-q4-reframe.md`

Simulation artifacts: `docs/dev-log/simulation-artifacts/2026-06-27-{t-interval-recompute,
oracle-bias-correction, bootstrap-bias-prototype, bias-corrected-engine-coverage-g8,
bias-corrected-engine-coverage-g8-spatial-animal, bias-corrected-secondgrid,
q2-spatial-animal-g32, q4-location-bias-corrected, reml-unblock-scoping}/`

Plus this handover doc + the `AGENTS.md` snapshot edit.

## Next Immediate Steps (ordered; ⟶ marks LIVE-toolchain = your job, Codex)

1. **⟶ Confirm the branch is pushed** (ask the maintainer). Without it the work is lost.
2. **⟶ Full `R CMD check` with compilation** — Claude could not compile TMB; you can:
   `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::check()'`.
   Confirm the default-flip + `test-wald-small-sample-default.R` pass under a real check
   (the in-session run used `devtools::test`, not full `check`).
3. **Maintainer decision on the next arc** (the AskUserQuestion that was open when the
   session ended — three options): **(a)** `sigma → inference_ready` (achievable now,
   profile channel + bounded sign-off); **(b)** **start the REML-unblock arc** (the real
   path to `supported`); **(c)** consolidate.
4. **⟶ If (b):** the honest smallest step is to **derive the structured-mean bivariate
   restricted likelihood**, bank a *failing* reference in `tests/testthat/test-reml-bivariate.R`
   (this file already exists and pins the fixed-effect OLS/SUR reference; add the
   structured-mean piece), THEN narrow the abort at `R/drmTMB.R` (`drm_validate_reml_spec_biv`,
   the `length(spec$random_names) > 0L` gate ~line 2001) to permit mean-side phylo while
   still rejecting sigma/q4. The cpp already routes phylo to mu1/mu2 and builds the q=2
   correlated field (`src/drmTMB.cpp` ~3163–3176) — the gate is the validation reference,
   not a missing kernel. See `docs/dev-log/after-task/2026-06-27-reml-unblock-scoping.md`.
5. **⟶ Any new coverage claim:** validate by simulation **per cell class** (the doctrine),
   reporting one-sided (below/above) miss rates, not just total coverage.

## Blockers / Open Questions

- **`supported` is blocked on a real arc**, not a tweak: REML-unblock (large; mean-axis
  only — but q2 *is* the mean axis, so it applies) OR a skew-aware interval (research).
  Maintainer to choose direction.
- **Unrelated bug (flagged, not fixed — discipline):** `profile_sd_internal()` collapses
  both `mu` and `sigma` structured SD targets onto the single `log_sd_phylo`
  `tmb_parameter` name; the axis gate handles the *correction* consequence, but anything
  keying off `tmb_parameter` alone could be misled. Worth a separate fix.
- **animal q2** under-covers even at g=32 (pedigree effective-df ≪ g) — do not promote it
  on the back of its g=8 bc+t number (the correction over-compensated a different bias).

## Gotchas & Failed Approaches (do not retry)

- **R env:** `.Rprofile` segfaults R 4.6 → always `R_PROFILE_USER=/dev/null Rscript --no-init-file`.
- **Single-level parametric bootstrap** does NOT recover the centre bias (it measures bias
  *at* `theta_hat`, where log-SD ML is ~median-unbiased, not at the truth). Banked negative:
  `…/2026-06-27-bootstrap-bias-prototype/`.
- **Do NOT re-label the shift "REML in closed form"** — it is ~2× the REML SD term,
  calibrated. (Noether's blocking finding; already corrected in docs.)
- **phylo DGP needs power-of-2 tree tips** → g=6/12 fail for phylo (test artifact in
  `validate-bias-corrected-secondgrid.R`, not a method failure); use g∈{8,16,32} for phylo.
- **REML is not a *quick* g=8 fix** — but it IS the principled route for q2's mean-axis
  variance components if the biv structured-mean spec is unblocked.

## How to Resume (Codex)

```sh
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
# 0. CONFIRM the branch is pushed first (maintainer's call):
#    git push -u origin claude/local-coverage-grids-sigma-q2
git checkout claude/local-coverage-grids-sigma-q2     # == main, 9ae75bf1
# live-env (Codex runs the real toolchain):
export R_PROFILE_USER=/dev/null          # avoid the R-4.5-lib segfault
export NOT_CRAN=true
# read order: AGENTS.md (native) → THIS doc → docs/design/218 + 219 →
#   the linked after-task reports.
python3 tools/validate-mission-control.py | tail -1     # expect: mission_control_ok
```

**Paste to a fresh Codex session (run from repo root):**
> Rehydrate from `docs/dev-log/handover/2026-06-28-codex-handover.md` + the `AGENTS.md`
> snapshot, then continue with the Next Immediate Steps. Confirm the branch is pushed,
> run `devtools::check()` with `R_PROFILE_USER=/dev/null NOT_CRAN=true`, then take the
> maintainer's decision on (a) sigma→inference_ready / (b) the REML-unblock arc / (c)
> consolidate. Launch the `.codex/agents/` team for bounded reviews; **Rose
> (`systems-auditor.toml`) audit is mandatory before any tier/status claim.**

**Cross-tool routing.** *Codex (you):* the live toolchain — `R CMD check` with
compilation, real TMB fits, the REML derivation + engine implementation, simulation
grids, rendering. *Claude:* planning, prose/docs, validator/guard logic, pure-R analysis.
A good loop: maintainer decides direction → Codex implements + validates on the live
engine → Claude reviews the diff + writes the claim_boundary prose.

---

## Mission-control summary

| Item | State |
| --- | --- |
| Repo / branch | `drmTMB` · `claude/local-coverage-grids-sigma-q2` (== local `main`, `9ae75bf1`) |
| Remote / CI | **UNPUSHED** — `origin/main` at `c1e9d15a`, 15 commits behind; no CI run on this work |
| Local verification | validator `mission_control_ok`; full suite 19588 PASS / 0 FAIL / 43 SKIP; conversion FAIL 0 |
| What shipped | bias correction **default** for location-axis structured SD; q2 phylo/relmat → `inference_ready`; engine-validated 0.954 @ g=8; 12 citations + doc 219; gllvmTMB#565; 42 PRs closed |
| Plan by leverage | (1) `supported` via REML-unblock **or** skew-aware interval [large] · (2) sigma→`inference_ready` [small] · (3) spatial q2 climb · (4) effective-df refinement / animal / q4 Hessian |
| Withheld (no compromise) | `supported` (6:1 miss asymmetry + g-dependence); animal q2 (g=32 under-cover); q4/q8 (pdHess); non-Gaussian structured (engine-rejected) |
