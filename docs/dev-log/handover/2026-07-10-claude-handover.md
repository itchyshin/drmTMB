# drmTMB handover → Claude (2026-07-10)

_You are the next Claude session. This is a lossless handoff: read files, not the prior chat._
_Authoritative plan (machine-local, same Mac): `~/.claude/plans/crystalline-tinkering-fog.md` —
the full missing-data ultra-plan with a cold-start grep block. Essentials embedded below so this
doc stands alone in the repo._

## Mission

Extend drmTMB **missing-data** from Gaussian-only to the priority non-Gaussian families —
**binary/binomial, count (Poisson/nbinom2), % (beta)** — for BOTH missing responses and missing
predictors (`mi()`), and **scaffold + honestly warn ALL 18 families**. Priority: Gaussian(done) +
binary first, then counts, then %. Capability-honesty: a ✓ requires a recovery + sentinel-invariance
artifact. This is one instance of a systemic "Gaussian-first, non-Gaussian behind" pattern the
668-cell capability census documented.

## What was accomplished this session

- **drmTMB 0.4.0 RELEASED** (PR #746 merged to `origin/main` `5ee29c32`, tag `v0.4.0`,
  `R CMD check --as-cran` **0E/0W/0N**). Shipped: honest **668-cell capability census** + a
  mission-control map; a **corrected REML boundary** + 5→8 anchor fix in the ledgers; a
  **user-facing "capability-and-limits" vignette**; a coverage campaign that **validated
  unstructured non-Gaussian intervals** (binomial/poisson/beta/nbinom2 mean + nbinom2/beta scale);
  recovery-hardening for 5 recovery-only structured cells. Full detail:
  `docs/dev-log/after-task/2026-07-09-v0.4.0-capability-honest-release-prep.md`.
- **nbinom2 structured-sigma bug FIXED** — the census caught `sigma ~ phylo/spatial/animal/relmat`
  silently applying to the *mean* (`model_type 7` lacked the `phylo_mu_dpar==1` branch beta has).
  Fixed + recovery test + mis-wire regression guard.
- **Track A (CI-trio, Totoro):** **profile beats Wald for nbinom2 dispersion** (Wald widths explode
  at small n; profile sane — #682 confirmed). Surfaced a **beta location-scale large-n fit-stability
  limitation** (finite-rate 0.907 at n=800). Banked: `docs/dev-log/simulation-artifacts/2026-07-09-trackA-ci-trio/`.
- **Track B (comparators):** drmTMB matches established packages to **machine precision** —
  binomial vs `glm` (exact), Gaussian LMM vs `lme4` REML (Δ1e-5, llΔ4e-12), Poisson vs `glm`/`glmmTMB`
  (Δ2e-6), Gaussian loc-scale vs `glmmTMB` dispformula (Δ4e-6). **Strong Arc-6 (#60) evidence.**
  Results are UNCOLLECTED — in workflow journal `wf_c2e13cab-c99` (bank them). Also confirmed
  glmmTMB's Gaussian `dispformula` models `log(sigma)` (same as drmTMB), not `log(sigma^2)`.
- **Missing-data audit + ultra-plan** (this handover's mission).

## Current working state

- **`origin/main` = `5ee29c32`** (v0.4.0, released, clean). **Local `main` is 2 ahead + UNPUSHED**:
  `ceed999c` (Track A CI-trio evidence — mine) + `8c9efba8` (pre-existing "chore: bind Codex" — not
  mine). Working tree otherwise **clean**.
- **⚠ Track A (`ceed999c`) is unpushed.** Decide: push it (reconcile local main) or keep local.
  Pushing/PR/merge/tag are **maintainer-gated**.
- **Track C (issue #710 stability guards) DID NOT DELIVER** — the fix workflow (`wf_de573850-321`)
  produced no edits (clean tree, no `test-stability-guards-*.R`). **#710 remains OPEN.** No debris.
- **The missing-data work has NOT started** — this handover exists to start it fresh.

## Next immediate steps (in order)

1. **New branch off `main`** (never work on the default branch): `git checkout -b drmtmb/missing-data-nongaussian`.
2. **Run the cold-start grep block** (below) — the engine file drifts; re-verify line numbers.
3. **P0 (gate, no code):** symbolic-alignment table for beta `phi=exp(-2·log_sigma)`, nbinom2
   `size=exp(-2·log_sigma)`, binomial logit, Poisson log — as the *recovery target*. Fable enumerates;
   Opus (Noether/Fisher) signs. Then **P4a** (loud per-family guardrails), then **P1** (response-mask
   ×4, incremental, parallel), then **P2** (keystone refactor `drm_response_log_density()`, byte-identical
   Gaussian gate), then **P3** (predictor-mi ×3, behind P2), **P4b** (capability matrix), **P5** verify.
4. **Reconcile Track A** (push or note) and **bank Track B** comparator evidence (from journal).
5. **#710 stability guards** still open — re-run or defer (was low-severity; one CONFIRMED cpp
   MI-normalizer bug in the batch).

## Key decisions & rationale

- **Response-mask lane → INCREMENTAL** (plumbing already family-agnostic: `observed_y` populated for
  all families; only a one-line `if(observed_y(i)==1)` guard + builder plumbing + gate-loosen per family).
- **Predictor-mi lane → REFACTOR** (extract `drm_response_log_density()`; do NOT copy the ~1,650-line
  Gaussian quadrature block per family — the Poisson copy already proves the anti-pattern). **Gate P3 behind P2.**
- **Port reference:** gllvmTMB's pluggable `obs_loglik` closure (`src/gllvmTMB.cpp:1940-2159`) +
  design `../gllvmTMB/docs/design/59-missing-data-layer.md` (ACCEPTED). Both GPL-3, same author →
  reuse allowed **with provenance in `inst/COPYRIGHTS` in the same slice**.

## Gotchas / traps

- **model_type integers (source-verified; earlier notes were WRONG):** binomial=**18** (not 13),
  nbinom2=**7** (not 9), poisson=6, beta=10, gaussian=1, biv=2. 13 = ordinal.
- **Density anchors** (`src/drmTMB.cpp`, RE-GREP — file ~4143 lines, churns): binomial~2864,
  poisson~3072, nbinom2~3285, beta~2705. Builders: gaussian@2655, beta@4327, binomial@4893,
  poisson@5195, nbinom2@5562. R gates ~250-268.
- **beta sentinel** for missing y must be **outside (0,1)**; **binomial** missing y with `trials` present.
- **beta-LS large-n fit-stability** (Track A finding) — a real limitation, root-cause separately.
- The **plan file is machine-local** (`~/.claude/plans/crystalline-tinkering-fog.md`), not in the repo.

## Cold-start (paste at repo root)

```
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
git checkout main && git pull --ff-only origin main   # note: local main may be ahead (Track A unpushed)
git checkout -b drmtmb/missing-data-nongaussian
grep -n "model_type ==" src/drmTMB.cpp
grep -n "observed_y" src/drmTMB.cpp                    # only 1,2 gate today
grep -n "model_type = [0-9]*L" R/drmTMB.R              # authoritative family→model_type
grep -n 'response = "include"\|predictor = "model"' R/drmTMB.R   # 3 reject gates ~250-268
grep -rn "drm_response_log_density" src/               # confirm refactor still greenfield
```

## How to resume (rehydration recipe, TARGET = claude)

1. Read this doc + the AGENTS.md snapshot bullet + `~/.claude/plans/crystalline-tinkering-fog.md`
   (the full ultra-plan) + `docs/design/149-missing-data-design.md` (MD-slice history).
2. Spawn **Rose** (scope-honesty) before any capability claim; use **symbolic-alignment** skill
   before any numeric code (P0). Recovery-to-truth over pdHess.
3. Compute: build + narrow tests local Mac; recovery/sentinel-invariance on **Totoro** (`~/Rlib`,
   rebuild from branch); coverage sweeps on **DRAC**. Models: Fable=enumeration, Sonnet=engine
   (Gauss)+recovery (Curie), Opus=orchestration+honesty (Rose/Noether/Fisher).
4. Commit per slice; **push/PR/merge/tag are maintainer-gated**.

**One-command resume** (paste in your authenticated terminal, from the repo root):
```
claude "Rehydrate from docs/dev-log/handover/2026-07-10-claude-handover.md + the AGENTS.md snapshot + ~/.claude/plans/crystalline-tinkering-fog.md, then start the missing-data ultra-plan at P0 on a new branch off main."
```

## Files created / modified this session

- Released on `origin/main` (PR #746): `src/drmTMB.cpp` (nbinom2 fix), `README.md`, `NEWS.md`,
  `ROADMAP.md`, `DESCRIPTION`, `_pkgdown.yml`, `docs/dev-log/known-limitations.md`,
  `vignettes/capability-and-limits.Rmd` (new), `tests/testthat/test-nbinom2-sigma-structured-recovery.R`
  (new), `tests/testthat/test-nongaussian-structured-recovery.R` (new),
  `docs/dev-log/dashboard/capability-census/**` (new), `docs/dev-log/simulation-artifacts/2026-07-09-*`,
  `docs/dev-log/after-task/2026-07-09-v0.4.0-capability-honest-release-prep.md`.
- Local-main-only (unpushed): `docs/dev-log/simulation-artifacts/2026-07-09-trackA-ci-trio/**` (`ceed999c`).
- This handover: `docs/dev-log/handover/2026-07-10-claude-handover.md` + `AGENTS.md` snapshot edit.

## Mission control

| Item | State |
|---|---|
| drmTMB release | **v0.4.0 shipped** (origin/main `5ee29c32`, `--as-cran` 0/0/0) |
| Local main | **2 ahead of origin, UNPUSHED** (Track A `ceed999c` + pre-existing chore) |
| Next mission | **Missing-data → non-Gaussian** (plan: `~/.claude/plans/crystalline-tinkering-fog.md`) |
| Order | P0 gate → P4a guardrails → P1 response-mask ×4 → P2 refactor → P3 predictor-mi ×3 → P4b matrix → P5 |
| Track B comparators (#60) | **DONE, all match to machine precision** — uncollected in journal `wf_c2e13cab-c99` |
| Track C stability (#710) | **Did not deliver — OPEN** |
| Track A follow-up | beta-LS large-n fit-stability; vignette "prefer profile for nbinom2 dispersion" |
| Gate | push/PR/merge/tag maintainer-gated; commit per slice on a branch |
