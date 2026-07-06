# Session Handoff — Claude → Claude (drmTMB)
Meta: 2026-07-06 · from Claude (Fable 5) · ~full context · addressed to the NEXT Claude session.

**You are the next Claude, picking up drmTMB right after the Q-Series closed at 104/104 and the
intervals/coverage arc was scoped + researched + just barely started.**

## Critical Context (read this or go wrong)
1. **The board is 104/104 on `main` (`6f3ca841`), clean.** Both this session's PRs are MERGED:
   **#736** (row 87 admission → 104/104) and **#737** (cell_id rename + closure-triage). All 4
   board validators exit 0; full `devtools::test()` = FAIL 0 / PASS 36380. Nothing is unpushed.
2. **104/104 is a FIT surface**, not "package done." The NEXT arc = **intervals + coverage +
   structured-covariance families**. It is APPROVED (ultra-plan) and RESEARCHED.
3. **Method DECIDED by Shinichi (2026-07-06):** *profile-likelihood CIs are the star* (primary
   interval route); *one plain parametric bootstrap is the only fallback* (NO BCa acceleration);
   ***`supported` is DEFERRED — the arc caps at `inference_ready`.*** BCa is banked for a future
   `supported` sub-project, not built now.
4. **Track A1 is the first slice and it is NOT started** — candidate cells identified, no branch,
   no spike yet. That is your entry point (Next Immediate Steps).

## What Was Accomplished (this session)
- **Row 87 → 104/104 (PR #736, merged).** Admitted three non-count family × provider structured
  `mu` ONE-SLOPE cells recovery-only — Gamma·relmat, Student·spatial, beta·animal — via a
  per-family validator relaxation only (**no `src/*.cpp` change**; shared
  `build_structured_mu_structure()` carries the slope; family enters only in the density).
  Crossed recovery ladder + null-slope control + non-identity AR(1) check. 4-lens gate all
  positive. See `docs/dev-log/after-task/2026-07-06-row87-noncount-structured-mu-slope.md`.
- **Cleanup (PR #737, merged).** Renamed the cell_id `..._planned → ..._recovery` lockstep
  (mirrors row-105 `_rejected→_recovery`); reconciled closure-triage (row 87 out of the
  `non_gaussian_planned` bucket → point-only-holding bucket; coupled validator closure-dict +
  queue-dict + queue sidecar; 16-bucket total stays 104). **Deferred (documented, not done):**
  the `rejected→point_only` bucket RELABEL — it's a pre-existing legacy misnomer (~18 cells) and
  a clean relabel cascades into the dual-purpose `intentional_rejections_hold` queue row + the
  dual-use `non_gaussian_rejected` widget_state.
- **Next-arc ULTRA-PLAN written + approved** → `docs/dev-log/2026-07-06-next-arc-ultraplan.md`
  (team, per-agent models, Totoro/DRAC runbook, ~3–6-month timeline, 3 tracks, C++ sizing S/M/L).
- **NotebookLM research done** → `docs/dev-log/2026-07-06-arc-interval-method-research-memo.md`
  (the design-221 seed; 48 cited refs from the *Fast & Accurate Algorithms* KB, id
  `3b3d2ec5-7779-41ee-b968-22623c80278b`, personal Google account, 240 sources). **UNVERIFIED /
  quarantine** — Fisher must verify the load-bearing citations before building on BCa.

## Current Working State
- **Working:** `main` 104/104; validators green; full suite green; both PRs merged; CI green.
- **In progress:** Track A1 (Gaussian profile-interval extension) — the ~33 Gaussian structured
  companion cells that are NOT `inference_ready` are identified (all `interval=planned` except
  `qseries_phylo_direct_sd_univariate` = `interval_feasible`). First exemplar not yet spiked.
- **Blocked:** nothing. (Compute is a *dependency*, not a block — see Blockers.)

## Key Decisions & Rationale
- **Profile-first / one bootstrap / defer `supported`** (Shinichi, 2026-07-06). Rationale: profile
  is drmTMB's hero CI method (asymmetry-respecting, transformation-equivariant, already the
  endpoint-profile solver in `R/profile.R`); the research showed the current bias-t (design 219)
  is Kenward-Roger-class, which the literature says is *ineffective for the variance parameter's
  skew* — hence the 6:1 miss-asymmetry. This makes the arc an **extension of existing profile +
  bootstrap infra**, not a new-method research project.
- **BCa banked** for the future `supported` sub-project (research says it's the #1 skew fix and is
  plausibly IN-PACKAGE via the existing `drm_bootstrap_confint`, not a DRM.jl/REML dependency).
- **Depth (one exemplar per track)** and **DRAC Nibi (certify) + Totoro (calibrate)** compute
  (ultra-plan defaults, unchanged).
- **Row 87 admission grain:** one board row, three family demonstrations — NOT board padding.

## Files Created / Modified (this handover)
- `docs/dev-log/handover/2026-07-06-claude-handover.md` (this doc)
- `docs/dev-log/2026-07-06-next-arc-ultraplan.md` (durable copy of the approved plan)
- `docs/dev-log/2026-07-06-arc-interval-method-research-memo.md` (durable copy of the research memo)
- `AGENTS.md` (snapshot pointer prepended)
(Everything else this session is already MERGED on `main` via PRs #736 + #737.)

## Next Immediate Steps (Track A1 — profile-first Gaussian extension)
1. **Fresh branch off `main`** (e.g. `drmtmb/a1-spatial-sigma-slope-interval`).
2. **First exemplar (recommended): `qseries_spatial_q1_sigma_one_slope`** — the spatial
   4th-provider companion to the already-`inference_ready` phylo/animal/relmat q1 sigma-one-slope
   anchors, so the profile route + `tools/run-structured-re-sigma-slope-coverage-grid.R` template
   apply most directly. (Alternates: `qseries_animal_q1_mu_intercept`, the q2 spatial/animal
   labelled-slope companions.)
3. **Spike (local Mac):** `R_PROFILE_USER=/dev/null Rscript --no-init-file -e '...'` —
   `devtools::load_all(".")`, simulate a Gaussian `bf(y ~ x, sigma ~ spatial(1 + x | site,
   coords = coords))`, fit, check `profile_targets()` lists the spatial sigma:x SD, and
   `confint(method = "profile")` returns a finite interval. If yes → coverage work; if the target
   isn't wired → an Emmy engine slice on `profile_targets()`/extractor.
4. **Coverage:** reuse the sigma-slope grid runner → **Totoro pilot** (n≈150, MCSE sane) → **write
   the DRAC-Nibi `.sbatch`/DEPLOY runbook** (you can't ssh — the human/Codex runs SR475, pastes
   back the result TSV) → gate: MCSE ≤ 0.01, pdHess/finite ≥ 0.95, miss-balance.
5. **Admit:** 4-lens (Curie/Noether/Fisher/Rose) + Fisher/Rose/Grace sign-off + ADEMP (design 217)
   → flip the board row to `inference_ready` (row-local; no propagation) → after-task → PR → **full
   suite + CI green before merge** → merge with Shinichi's OK.

## Blockers / Open Questions
- **Compute is human/Codex-run:** Claude cannot ssh/scp to Totoro/DRAC. You write the runbooks;
  Shinichi or Codex executes and pastes back the coverage TSVs. Plan the certify step around this.
- **Count-GLMM caveat (Track B, later):** the first-order Laplace approximation attenuation-biases
  count RE SDs downward — bounds which count cells reach `inference_ready` honestly. Not this slice.
- **Research is UNVERIFIED:** before any BCa/`supported` work, Fisher verifies the 3 load-bearing
  citations in the memo. Not needed for the profile-first A1 slice.

## Gotchas & Failed Approaches (do not retry)
- **Run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file`** (a stale `.Rprofile` libPath can
  segfault R 4.6). Mac R 4.6 + devtools/TMB/glmmTMB all present; live `devtools::test()` works.
- **ALWAYS run the FULL unfiltered `devtools::test()` before merge.** Board-state changes break
  hardcoded-count tests that targeted runs miss — this session `test-structured-re-conversion-contracts.R`
  hardcodes closure counts (line ~683) + candidate lists; it broke twice and had to be reconciled.
- **The board validators + `qseries_v1_release_check.py`/`validate-mission-control.py` HARDCODE
  counts** (widget_state, closure dict ~line 18951, queue dict ~19490, status phrases). Any board
  change means updating those in lockstep; the ledger + release-audits are GENERATED
  (`qseries_v1_release_ledger.py --write`, `qseries_v1_release_check.py --write-candidates --write-report`).
- **CI exit codes:** `gh pr checks <N> --watch; echo $?` with **no pipe** (a piped `| tail` masked
  a red check historically). Confirm with a fresh `gh pr checks <N>` too.
- **Do NOT run the full R suite concurrently with many CPU-heavy sub-agents** — contention stalled
  a run to a 2-min-stale log this session (looked hung, wasn't).
- **NotebookLM:** personal Google account only (never UAlberta); `source list` uses `--notebook`
  (not `-n`); the KB is rich (240 sources) so **`ask` it before adding** (near Pro's 300 cap).

## How to Resume
1. Rehydrate from repo state (trust files, not chat): `git -C <repo> log --oneline -6`,
   `git status`, then run the board guards: `R_PROFILE_USER=/dev/null python3
   tools/qseries_v1_claim_guard.py` and `tools/validate-mission-control.py` (both exit 0 = 104/104).
2. Read, in order: **this doc** → `docs/dev-log/2026-07-06-next-arc-ultraplan.md` (approved plan) →
   `docs/dev-log/2026-07-06-arc-interval-method-research-memo.md` (method decision + research) →
   `~/.claude/memory/memory_summary.md` (drmTMB section) → the 8-anchor template in
   `tools/run-structured-re-sigma-slope-coverage-grid.R`.
3. Spawn **Rose** (`systems_auditor`) before any status/board claim (standing rule).
4. Execute the Next Immediate Steps (start the Track A1 spike).

**One-command resume (paste in your authenticated terminal, from the repo root):**
```
claude "Rehydrate from docs/dev-log/handover/2026-07-06-claude-handover.md + the AGENTS.md snapshot, then start Track A1: spike the profile interval for qseries_spatial_q1_sigma_one_slope."
```

## Mission-control summary
| Item | State | Next by leverage |
| --- | --- | --- |
| drmTMB `main` `6f3ca841` · CI green | **104/104 board, both PRs merged, validators + full suite green** | — |
| Next-arc ultra-plan | approved (`…/2026-07-06-next-arc-ultraplan.md`) | execute Track A1 first |
| Interval method | **DECIDED: profile-first, one bootstrap, defer `supported`** | build on existing `R/profile.R` |
| Research memo (design-221 seed) | done, **UNVERIFIED** | Fisher verifies before any BCa work |
| **Track A1** (Gaussian profile extension) | candidate cells identified, **not spiked** | ← START HERE: spike `qseries_spatial_q1_sigma_one_slope` |
| Track B (non-Gaussian intervals) | scoped; count Laplace-attenuation caveat | after A1 |
| Track C (new C++ families: ZI, q2 cross-term) | sized S/M/L in the plan | parallel/later |
