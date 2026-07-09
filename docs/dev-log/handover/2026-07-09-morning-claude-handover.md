# Handover — drmTMB, 2026-07-09 morning → next Claude / Shinichi

Meta: 2026-07-08 night → 2026-07-09 · from Claude (Opus 4.8) · repo `drmTMB` ·
`main` = `bed29701` (unchanged; both night deliverables are on unmerged branches). This
covers the overnight run after the Ayumi-arc session (SUPERSEDES nothing — it is the
delta after `2026-07-08-night-claude-handover.md`).

**Two work streams landed tonight, both green, both awaiting your review. Neither is
merged.** The board's 8 `inference_ready` cells were not touched.

---

## Stream 1 — Ayumi arc (#16–20): PR is OPEN, ready to merge

**[PR #743](https://github.com/itchyshin/drmTMB/pull/743)** · branch
`drmtmb/fix-16-phylo-mu-diagnostics` (pushed) · 4 commits · `--as-cran` clean (0E/0W/2N) ·
full `devtools::test()` FAIL 0.

| # | what |
|---|---|
| #16 | `phylo_mu_diagnostics` no longer false-errors on `sd_phylo(...) ~ .` surfaces (summarizes the fitted surface). |
| #18/#19 | Point-6 diagnosed = genuine non-ID of the phylo cross-correlation; new `standard_errors_inflated` check + sharpened boundary warning. |
| #17 | Bivariate `sd_phylo1/2` REML ceiling regression test. |
| #20 | ML-vs-REML guidance in `convergence.Rmd` (+ weak-ID docs); corrected the prior handover's inaccurate "REML doesn't shift sd_phylo coefficients" claim. |

**Action for you:** review + merge #743. Then **post the point-6 reply to Ayumi** —
drafted at `scratchpad/ayumi-point6-followup-DRAFT.md` (body starts at the `@Ayumi-495`
line; strip the HTML-comment scaffold first). It offers to tag the new checks; do that
after #743 merges.

---

## Stream 2 — C1 REML scale-side provider unlock: committed LOCAL, needs your review

Branch `drmtmb/c1-reml-scale-structured` off `main` · commit `7b27e44a` · NOT pushed, NO
PR (per the overnight plan: capability change → leave for review). Full suite result
recorded below (§verification).

**What it does.** Relaxes the univariate REML provider gate so scale-side
(`sigma ~ spatial()/animal()/relmat()`) structured effects fit under REML. Mean-side and
mean+scale-spanning non-phylo effects stay rejected; the bivariate path is unchanged.
**R-side only** — the C++ already computes it; the gate was the sole barrier.

**Evidence (Totoro, 64 cores; archived under
`docs/dev-log/simulation-artifacts/2026-07-08-c1-reml-provider-unlock/`).**
- Recovery, N=400: REML debiases the scale-side intercept SD **400/400 in every cell**,
  bias→0 with g. Slope-SD REML<ML reversal is the documented no-fixed-`x` non-bug.
- Coverage, N=300: REML profile-CI coverage **≥ 0.926 every cell** (g=8 floor 0.91) →
  `inference_ready`. **`supported` not claimed** (deferred).
- **Noether: CONFIRMED** on all five points. Also flagged a pre-existing `drm_fit_df`
  scale-side df/AIC under-count — **spawned as a task (task_befac4a1), NOT bundled.**

**Actions for you:** (a) review `7b27e44a`; if good, push + open its PR (I left it local
per the plan). (b) The df under-count task is real and affects all scale-side REML fits'
AIC — worth doing. (c) These new cells are certified via the profile channel but are
**not yet wired into the board TSV / two-tier gate driver** — a follow-up if you want them
on the dashboard.

---

## Next by leverage (after the two reviews)

1. **Push/PR C1** (if the review is clean) + post Ayumi's point-6 reply.
2. **`drm_fit_df` scale-side df fix** (task_befac4a1) — small, real, own tests.
3. **Bivariate C1** — scale-side spatial/animal/relmat under REML for `biv_gaussian`.
   Same mechanism, no evidence yet; run the biv analogue of tonight's two campaigns, then
   relax `drm_validate_reml_spec_biv`. (Noether flagged the univariate/biv asymmetry to
   close.)
4. **Wire the C1 cells into the board** (`estimator-surface-conformance` already updated;
   the inference-gate TSV is separate).
5. **C2 location-scale-scale** (design 222) — still the hard C++ slice, off Ayumi's path.

## Gotchas / notes for the resume

- **Totoro is set up for drmTMB** (`~/drmtmb_work/drmTMB`, main `6c89fea`, R 4.5.3, TMB +
  drmTMB installed). Non-interactive key auth works (`ssh -o BatchMode=yes totoro`), no MFA
  prompt on the existing key. Keep usage ≤ ~64 cores (lab shares it; load was 50–225 tonight).
  The two campaign drivers are on Totoro at `~/drmtmb_work/drmTMB/scratchpad/` and in the
  repo's `simulation-artifacts/` dir.
- The C1 recovery/coverage drivers **bypass the provider gate** via
  `assignInNamespace("drm_validate_reml_spec", ...)` — that is how the mechanism was proven
  before the gate was touched. Reuse that pattern for the biv campaign.
- `confint(fit, method="profile")` returns `$lower`/`$upper` (NOT a matrix) — see
  `coverage-runner.R`.
- The conformance TSV (`estimator-surface-conformance.tsv`) enforces that every cited
  `file:line` still contains its rejection text — **any edit to `drm_validate_reml_spec`
  that shifts lines will fail `test-estimator-surface-conformance.R` until you update the
  evidence lines + detail strings** (bit me tonight; +15-line shift).
- **Do NOT demote the 8 `inference_ready` cells** (tier confusion; LEARNINGS top entry).
  `supported` stays deferred.
- Never-commit scratchpad files remain untracked.

## How to resume

1. Read this + `~/shinichi-brain/memory/LEARNINGS.md` (top two entries: tier confusion,
   weak-ID signature).
2. `git checkout main` is at `bed29701`. The two branches above hold the night's work.
3. Confirm board honesty unchanged: `Rscript tools/gate-inference-ready-driver.R` → all 8
   `inference_ready=PASS`.
4. Start by reviewing/merging #743, then reviewing C1 `7b27e44a`.
