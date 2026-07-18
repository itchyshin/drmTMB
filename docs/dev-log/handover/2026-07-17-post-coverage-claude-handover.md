# Handover → next Claude (2026-07-17, post Beta-phylo coverage + capability-surface session)

You are the next **Claude** session picking up drmTMB. This session closed one capability
arc (a promotion, PR open) and one tooling lane (live on the mission-control board), and left
a small set of clean, explicit loose ends. Read this, then the two after-task reports it links.

---

## Goals / mission

- drmTMB = fast univariate/bivariate distributional regression on TMB, marching toward a v1.0
  capability surface. The live program is turning `point_fit_recovery` cells into
  **`inference_ready_with_caveats`** with honest, pre-registered coverage evidence, one cell at
  a time (D-57 Beta-phylo location-scale-scale lane; the broader coverage layer is the v1.0 gate).
- This session's goal (COMPLETE): give the Beta phylogenetic q1 **direct latent-SD regression**
  cell `mc-0017` its interval+coverage evidence and promote it if it cleared a pre-registered
  gate under D-43 — or return a documented non-promotion. **Outcome: promoted, PR #789 (not merged).**
- Mid-session the user also asked to fix + enrich the **capability surface** (it wasn't rendering)
  and add an **AGHQ column** + **R↔Julia parity** — all done, live on the board.

## Plans / roadmap (the next big arc)

The user wants to **start a new big arc** next session. Ranked candidates:
1. **Gamma σ-random-intercept interval + coverage → promote `mc-0242`** — the direct sibling of
   this arc and of Arc 4a's lognormal `mc-0382`. Reuses this exact methodology (Wald+profile
   coverage, the pre-registered gate, D-43). Ordinary iid σ-RE (no 1024-tip phylo covariance) →
   cheap + fast. **Recommended first next arc.**
2. Extend coverage to the other Arc-4a-style `point_fit_recovery` σ/μ-RE cells.
3. A bivariate capability arc (different model class; higher risk).
Whatever the arc: **ultra-plan it, plan-review the gate BEFORE compute, get explicit approval.**

---

## Critical context

- `main` @ `a9b2633c` (PR #787). **PR #788** (handover-only) still OPEN, untouched. Stopped
  campaign `1c9bfd5f` immutable, untouched. The `shared_g256_m02` stress HOLD was never pooled.
- **mc-0017** is now `inference_ready_with_caveats` on branch `claude/beta-phylo-q1-interval-coverage`
  (**PR #789**, NOT merged). Beta family sigma (`phi=σ⁻²`) stays distinct from latent
  `tau = sd(spp_id, level="phylogenetic")`.

## What was accomplished

**A) Coverage arc → PR #789 (open, not merged).** Full detail:
`docs/dev-log/after-task/2026-07-17-beta-phylo-q1-coverage-promotion.md`.
- DRAC/fir SLURM campaign (12-cell grid, N=1200, profile+Wald, 0 failures; fir reproduced local
  to 1e-4). Promotion arms clear the pre-registered [0.925,0.975] gate: slope **nominal in both
  arms**, worst = shared intercept 0.9333 (mildly anti-conservative). Wald≈profile.
- Passed D-43 re-review (Fisher DONE, Rose DONE, Noether's hygiene defect fixed). Plan-review
  caught + fixed a gate error pre-compute.

**B) Capability-surface lane → live on the board, NOT yet PR'd.**
- Fixed the board: `mission-control/live/projects.json` `repo_root` was pointing at a **deleted**
  Codex worktree → "No capability surface yet." Repointed it (see Blockers).
- Re-added the **AGHQ estimator-axis** (ML|REML|AGHQ|priority) to `tools/capability_ledger.py`;
  AGHQ honestly = "planned" (0 AGHQ cells). Live at `/p/drmTMB/surface`.
- Wired **R↔Julia parity**: matching-name `docs/design/capability-status.md` on drmTMB AND DRM.jl
  (DRM.jl inventoried from real source — caught 3 stale DRM.jl doc entries). Live at `/p/drmTMB/parity`.
- This lives in worktree `drmTMB-wt-surface`, branch `claude/capability-surface-aghq-parity`,
  **UNCOMMITTED**; DRM.jl's new file is **uncommitted** in the DRM.jl repo.

## Current working state

- **Working / done:** coverage arc (PR #789); AGHQ + parity live on the board.
- **In-progress / needs a decision:** the surface lane is uncommitted — user hasn't decided
  whether to open its PR (drmTMB + DRM.jl) or leave it board-only.
- **Blocked:** durable board pointer (stale lock, below); brain DECISIONS/AGENT_LOG update owed.

## Key decisions & rationale

- **Venue DRAC/fir over Totoro** (reproducibility-gated) — ~1000 core-hrs is DRAC-shaped, fir 4×
  faster, spared the lab server. Reproducibility check kept evidence consistent with the point campaign.
- **Gate = [0.925,0.975] CI-overlap**, frozen pre-campaign — the plan-review caught that
  "overlap-0.95" contradicted the `inference_ready_with_caveats` precedent it invoked.
- **Draft the claim BEFORE the D-43 review** — round 1 correctly withheld an undrafted claim.

## Files created / modified (every path)

Coverage arc (branch `claude/beta-phylo-q1-interval-coverage`, PR #789):
- new `tools/run-beta-phylo-q1-sd-coverage.R`, `tests/testthat/test-beta-phylo-q1-sd-coverage-runner.R`,
  `docs/dev-log/2026-07-17-beta-phylo-q1-coverage-estimand-alignment.md`,
  `docs/dev-log/after-task/2026-07-17-beta-phylo-q1-coverage-promotion.md`,
  `docs/dev-log/simulation-artifacts/2026-07-17-beta-phylo-q1-coverage/` (S1 probe + fir-campaign; raw gzipped).
- modified `docs/dev-log/dashboard/capability-ledger/{cells.tsv,evidence.tsv,transitions.tsv}` +
  regenerated `capability-census/*`, `capability-surface.{md,html}`,
  `vignettes/includes/capability-ledger-family-map.md`, `tools/tests/test_capability_ledger.py`.
- **R/ NOT changed.**

Surface lane (branch `claude/capability-surface-aghq-parity`, UNCOMMITTED in `drmTMB-wt-surface`):
- modified `tools/capability_ledger.py` (+ regenerated surface), new `docs/design/capability-status.md`.
- in DRM.jl (uncommitted): new `docs/design/capability-status.md`.

This handover: this doc + the AGENTS.md snapshot bullet (branch `handover/2026-07-17-claude`).

Vault (mission-control, local-only): `mission-control/live/projects.json` (repo_root + capability.source
for drmTMB) — uncommitted; commit with scoped staging per the mission-control skill.

## Next immediate steps

1. **Decide the surface lane:** open a PR for `claude/capability-surface-aghq-parity` (drmTMB) + a
   DRM.jl PR for its `capability-status.md`, OR leave board-only. If PR'd, run the generator's
   37 unit tests + `--check` + `pkgdown::check_pkgdown()` first (they passed this session).
2. **Update the brain:** `~/shinichi-brain/memory/DECISIONS.md` + `AGENT_LOG.md` — record the
   mc-0017 promotion + the DRAC-fir-reproducible-coverage method + the FlexiBLAS thread-pinning finding.
3. **Start the next big arc** (recommend Gamma σ-RE coverage `mc-0242`) — ultra-plan it, plan-review
   the gate before compute, get explicit approval.
4. Optionally make the board pointer durable (see Blockers).

## Blockers / open questions

- **Stale `.git/index.lock`** in the canonical checkout `/Users/z3437171/Dropbox/Github Local/drmTMB`
  (Jul-13, 0 bytes) blocks branch-switching there; `rm` was permission-denied this session. The board
  therefore points at the temp worktree `drmTMB-wt-surface`. Durable fix: clear the lock
  (`rm "/Users/.../drmTMB/.git/index.lock"`), `git -C <canonical> checkout main`, then set the board's
  `repo_root` back to the canonical path.
- **`reviewed_by` on `ev-mc-0017-arc-coverage` = "pending"** until a maintainer ratifies PR #789.

## Gotchas / failed approaches

- **A Bash/Agent safety classifier ("claude-opus-4-8 temporarily unavailable") was intermittently
  down all session** — retry, don't abandon.
- **fir uses FlexiBLAS, not OpenBLAS** — `OPENBLAS_NUM_THREADS=1` is silently ignored; pin
  `OMP/FLEXIBLAS/BLIS_NUM_THREADS=1` + `--cpus-per-task=1` or fits oversubscribe threads and hang.
- **Sub-agents that offload a slow run to a background job and yield** (S1 probe, S5 checks) leave the
  result unwritten — check the actual process/output, don't trust the "waiting" reply.
- Three temporary worktrees exist: `drmTMB-wt-beta-coverage` (PR #789), `drmTMB-wt-surface` (surface),
  `drmTMB-wt-handover` (this doc). `git worktree prune`/remove when their branches are merged/abandoned.
- fir evidence lives at `~/projects/def-snakagaw/z3437171/drmTMB-cov/` on fir (persistent /project).

## How to resume (rehydration recipe — TARGET = claude)

1. `cd` to the repo; read the `AGENTS.md` "▶ Latest — start here" snapshot, then THIS doc, then the
   coverage after-task (`docs/dev-log/after-task/2026-07-17-beta-phylo-q1-coverage-promotion.md`).
2. Verify live state: `git fetch`, confirm PR #789 (coverage) + PR #788 (handover, untouched); the
   mc-0017 ledger row = `inference_ready_with_caveats`.
3. Before any new capability CLAIM, spawn the mandatory review lens (Rose / systems_auditor), default NOT-DONE.
4. Claude runs the live R/TMB toolchain here (this session did); DRAC fir + Totoro reachable via
   ControlMaster sockets (`SOCK=$(ls ~/.ssh/cm-*<host>* | head -1)`). Compute → DRAC/Totoro, never Actions (D-50).
5. Plan the next arc with `ultra-plan`; plan-review the coverage gate BEFORE compute.

**One-command resume (paste in your authenticated terminal, from the repo root):**
```
claude "Rehydrate from docs/dev-log/handover/2026-07-17-post-coverage-claude-handover.md + the AGENTS.md snapshot, then start the next big arc — Gamma sigma-RE coverage (mc-0242) — with ultra-plan and a pre-compute plan-review of the gate; stop for my approval before any compute."
```

## Mission-control summary

| Lane | Branch / PR | State | What shipped | Next by leverage |
|---|---|---|---|---|
| Beta-phylo q1 coverage | `claude/beta-phylo-q1-interval-coverage` / **PR #789** | Done, unmerged | mc-0017 → inference_ready_with_caveats; fir 12-cell N=1200 coverage; D-43 passed | Maintainer review/merge; then Gamma mc-0242 |
| Capability surface (AGHQ + parity) | `claude/capability-surface-aghq-parity` (uncommitted) | Live on board, no PR | AGHQ estimator-axis restored; R↔Julia parity (drmTMB + DRM.jl) | Decide: PR or board-only |
| Board pointer durability | vault `projects.json` | Working via temp worktree | Fixed the deleted-worktree pointer | Clear stale lock → canonical-on-main |
| Next big arc | — | Not started | — | **Gamma σ-RE coverage (mc-0242)** — ultra-plan + approval |
