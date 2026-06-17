# Closing handover — Waves 1–5 (estimation-stack hardening) → Codex team

Date: 2026-06-17
Branch: `codex/honesty-guards`
Author: Claude Code
Status: **complete, full suite green, ready for Codex to integrate**

## TL;DR

A four-lane audit (ML / REML / optimizers / difficult-case controls) found that
the difficult-case guards were prose-only, not enforced in the runtime. The
five-wave plan that followed is now finished and validated:

- **Full suite green:** `FAIL=0, ERROR=0, PASS=11296, WARN=26, SKIP=5` on this
  branch. The 26 warnings are the *classed* convergence/clamp warnings the new
  guards intentionally raise on boundary fixtures; the 5 skips are pre-existing.
- **Not pushed, no PR** — merging is your lane. The branch is ready when you are.
- This note is the single read-me for picking it up.

## What landed (Waves 1–5)

**Wave 1 — honesty guards.** Fit-time non-convergence warning
(`drmTMB_convergence_warning`); `AIC()`/`BIC()` guarded against REML/MAP fits;
boundary-aware `confint(method = "wald")` (flags SD/rho intervals at the bound);
`log(sigma)` clamp-active warning. (`7ff4e232`, `258672e8`, `7dbf127e`,
`e2dc1f67`, `4fa74915`.)

**Wave 2 — ML robustness.** Soft-clamp extended to *all* scale-bearing families
(bit-identical in-band per family); non-finite-objective guard; an over-large
sigma-slope start is shrunk rather than discarded. (`e96cbe53`, `cb8d2430`,
`2a3cb493`, `9dcaf609`.)

**Wave 3 — optimizer escalation.** Preset ladder escalates on non-convergence
(C1); opt-in multi-start (C2, `drm_control(multi_start=)`); opt-in fallback
optimizer (C3, `drm_control(fallback_optimizer=)`). (`84fc213b`, `9f0eb043`,
`58c53782`, `34004cea`.)

**Wave 4 — REML completeness.** REML extended from the univariate-Gaussian
slice to mean-side phylogenetic location (4.0), heteroscedastic `sigma ~
predictors` (4.1), and bivariate fixed-effect location (4.2); plus an ML-vs-REML
variance-component bias simulation (4.3). Each validated against an exact or
hand-computed restricted-likelihood reference. Scale-side phylo REML is still
rejected **by design** (not a defined estimator). (`445d4634`, `eef270c9`,
`3f66a305`, `6e7b7dbf`, `8ca2f3ff`.)

**Wave 5 — controls polish + Hao Qin follow-ups.** `REML + penalty` rejected as
undefined; `check_drm()` gains a `logsigma_clamp_active` row; Student-t `nu > 2`
limitation documented; `drm_phylo_penalty()` + `drm_phylo_penalty_sweep()` (the
`cor_sd` sensitivity sweep); residual `rho12` guard standardized to six nines.
(`bb569cd8`, `adf3651e`, `24127df2`.)

## Integration guidance (please read before merging)

- Branch is **25 commits ahead, 18 behind** `origin/main` (merge-base
  `6944451e`, *"Add Julia capability comparison and docs drift guard (#587)"*).
  The raw `git diff origin/main..HEAD` shows ~26.7k deletions — that is **main
  moving ahead, not removals by this work**. The true footprint vs the
  merge-base is **54 files, +2783 / −121**.
- **One rebase hotspot:** `R/drmTMB.R` is the only one of the nine changed
  source files also touched on main since the merge-base (4 commits). Everything
  else (`R/check.R`, `control.R`, `family.R`, `methods.R`, `penalty.R`,
  `predict-parameters.R`, `profile.R`, `src/drmTMB.cpp`) is conflict-free.
  `R/drmTMB.R` holds the Wave 1 convergence warning + the Wave 3 optimizer
  escalation, so reconcile those against main's optimizer/fit-driver changes
  carefully (Gauss + Ada).
- After rebase: rebuild the cpp and re-run at least `test-optimizer-*`,
  `test-multi-start`, `test-check-drm`, `test-reml-*`, `test-*clamp*`, and the
  contract tests (`test-family-link-contract`, `test-predict-parameters`,
  `test-reference-grid-link-scale-contract`, `test-covariance-block-registry`).

## The final-suite fix — for whoever reviews the test changes

The complete suite first returned `FAIL=7`. All seven were **test-side drift
exposed by my own Wave 5 work**, not behaviour regressions, and are fixed in
`bf8a60bb`:

- **5** exact-contract tests still recomputed expectations with the old
  eight-nines rho12 cap after `24127df2` standardized the source to six nines.
  Updated to six nines. (Lesson: a guard-constant change must update its
  exact-contract tests in the *same* commit.)
- **2** were the bivariate mu RE-covariance `check_drm` fixture sitting at a
  benign ~1.4e-3 fixed gradient. Verified against origin/main: it is the **same
  optimum** (objective to 9 digits, parameters to 6); the gradient is pinned
  there even at `rel.tol = 1e-13`; the soft-clamp merely nudges nlminb's
  stopping point across the strict `1e-3` `fixed_gradient` default. The fixture
  tests covariance diagnostics, not gradient sharpness, so `gradient_tolerance`
  was widened for it (not the global default).

## New public surface (reviewer / pkgdown / documentation_writer)

- `drm_control()`: `multi_start`, `fallback_optimizer`, `logsigma_clamp` knob.
- `confint.drmTMB()`: `sd_boundary`, `rho_boundary` args.
- `AIC.drmTMB`/`BIC.drmTMB`: guarded for REML/MAP.
- `check_drm()`: `logsigma_clamp_active` row.
- Exported: `drm_phylo_penalty()`, `drm_phylo_penalty_sweep()` (both in
  `_pkgdown.yml`).
- Classed conditions: `drmTMB_convergence_warning`,
  `drmTMB_clamp_active_warning`, `drmTMB_nonfinite_objective_warning`,
  `drmTMB_wald_boundary_warning`, `drmTMB_ic_reml_warning`,
  `drmTMB_ic_map_warning`. `inst/sim/R/sim_runner.R` filters the first three so
  they are not miscounted as ledger failures.

## Ayumi thread (GitHub issue Ayumi-495/LS_ecogeographical-rules#2)

- Her brms/Stan cross-check **validated the approach**: climate fixed effects
  match drmTMB ML to ~3 digits; the μ–σ coupling is the prior/penalty-sensitive
  part (ML −0.78 vs regularised −0.52, sign robust across LKJ). She explicitly
  thanked the penalized/MAP estimator and the Wald-CI guidance.
- She **asked us to hold** ("no need to act further on this thread at this
  stage") and will open a **new issue** with full 10,440-tip bivariate results
  vs Model E + penalized. A short thank-you was posted (owner-approved).
- To be ready for that issue: Model E penalized + `cor_sd` sweep on the full
  data (tools shipped here), boundary-aware `confint`, and **verify the
  uncorrelated-univariate σ-phylo block is actually reachable before claiming
  it** — the earlier `shannon/RELEASE-drmtmb` 404 / `engine="julia"` over-promise
  (which she caught) is the cautionary tale.

## Deferred / open (documented, not delivered)

- Bivariate random-effect / phylo REML (full Ayumi Model A+/D): needs a
  bivariate restricted-likelihood reference to validate.
- `check_drm()` row for univariate `(1 + x | p | id)` mean-scale RE correlations
  at the tanh bound (boundary-aware `confint` already covers the inference side).
- The **scale-axis REML correction** is still open; Ayumi was told REML σ-phylo
  numbers are provisional until it lands.

## Standing constraints (unchanged)

- GPL-3 drmTMB code/patterns must **never** flow into MIT-licensed HSquared.jl;
  reuse needs `inst/COPYRIGHTS` provenance + tests.
- Do not edit DRM.jl unilaterally — the Julia mirror is twin-coordinated.

Pointers: per-wave after-task notes live alongside this file
(`docs/dev-log/after-task/2026-06-16-wave{1..5}-*.md`); clamp scope is recorded
in `docs/design/170` and `174`.
