# Session Handoff: R–Julia parity (post D-269 rename, post Dinnage Wave C)

Meta: 2026-09-24 · from Cursor (Ada integration review) · to **Claude** · TARGET = claude · AUTHOR = cursor · context: handover-only slice (no parity implementation in the authoring session).

You are **Claude**, picking up the **R–Julia parity** programme on drmTMB. You inherit **no chat**. Read `AGENTS.md` first, then this file, [`coordination-board.md`](../coordination-board.md) Active-Lane-Split, and the current git state before editing.

**Shinichi’s question (answered here):** **Yes** — a **new Claude session/lane** for R–Julia parity is possible and appropriate now that Dinnage arc3 Wave C ([#1380](https://github.com/itchyshin/drmTMB/pull/1380)) and the D-269 DRModels rename bridge ([#1381](https://github.com/itchyshin/drmTMB/pull/1381), receipt [#1388](https://github.com/itchyshin/drmTMB/pull/1388)) are on `origin/main`. Take a **dedicated parity lane**; do not bleed into reader-doc PRs (#1417–#1419) or reopen the closed Dinnage arc.

## Goals / mission

- **Programme:** every implemented native-R workflow should run in direct Julia **and** through `engine = "julia"`, with receipt-gated evidence (`docs/dev-log/plan-actual/2026-09-05-parity-joint.md`, `docs/design/parity-matrix.md`). R package name stays **drmTMB**; Julia twin is **DRModels** (GitHub repo still often cloned as `DRM.jl` on disk — D-269 in `~/shinichi-brain/memory/DECISIONS.md`).
- **This handover’s scope:** resume parity work only. **No CRAN submission**, no tags, no public speed claims.

## Plans / roadmap (beyond the next slice)

- Backlog from parity-joint closeout: [`handover/2026-09-07-claude-parity-joint-handover.md`](2026-09-07-claude-parity-joint-handover.md) §5 (open issues, stale pins, partial `claim_status` rows).
- Leaf queue: `.unlazy/parity/gates/leaf-*.md` (one leaf per PR; do not batch unrelated families).
- Open Codex parity-adjacent drafts: [#1304](https://github.com/itchyshin/drmTMB/pull/1304) ordinary-Laplace evidence (foreign lane — read before touching `R/julia-bridge.R`).
- Dinnage → DRModels follow-up map (coordination unless assigned): [`lanes/dinnage-arc3-cursor/LOOP/drm-jl-followups.md`](../lanes/dinnage-arc3-cursor/LOOP/drm-jl-followups.md).
- **Sibling repo (not this lane’s live tree):** GLLVM.jl Latte/s9cov under `~/local-scratch/lanes/GLLVM.jl-s9cov-20260921/` — only when cross-repo claims require it.

## Critical context

1. **Multi-lane:** Nine+ foreign lanes (reader rewrites, #1033, old parity branches). **Lane you own:** `claude/r-julia-parity-20260924`. Run `~/shinichi-brain/tools/lane_preflight.sh` on the repo path before claiming files (D-87/D-88).
2. **Dinnage arc3 Wave C is DONE** on `origin/main` @ `54df129fe` (includes #1380 @ `9c2c6a29`, receipt refresh @ `aec53a2bd`). Do **not** re-open `beta_family()` / nlme generic work unless a new issue says so.
3. **D-269 rename on main:** bridge resolves **DRModels** or legacy **DRM** from `DRM_JL_PATH` / `options(drmTMB.DRM.jl.path)`; module alias `drmTMB_backend` — `docs/dev-log/after-task/2026-09-18-d269-drmodels-bridge.md`.
4. **`source-pins.json` is stale** (DRM.jl `430ef64cc`, 2026-09-05). Generated parity docs may cite older DRModels SHAs — **OWED** refresh, not truth.
5. **`r_bridge_status` vs `claim_status`:** evidence vs governance; promoting `claim_status` is **maintainer-only** ([`handover/2026-09-07-codex-handover.md`](2026-09-07-codex-handover.md)).

## What was accomplished (before this handover)

- **Dinnage arc3 Wave C** merged #1380; tip-identity receipt refreshed (check-log 2026-09-17).
- **D-269 bridge compat** #1381 + phylo receipt recert #1388; `test-julia-module-compat.R` on main.
- **Parity-joint campaign** (2026-09-05–07): closure [#1298](https://github.com/itchyshin/drmTMB/pull/1298) merged; ledger on main (2026-09-24): **17 supported / 6 partial / 13 experimental / 1 unsupported** (`inst/extdata/julia-capabilities.tsv`).
- **DRModels.jl** `origin/main` @ `e9d50a110` (h2h reanchor [#807](https://github.com/itchyshin/DRModels.jl/pull/807), 2026-09-23) — **re-measure on pickup**.
- **Authoring session:** durable handover + board/split pointers only (Cursor wrote for Claude).

## Current working state

- **Working:** `origin/main` @ `54df129fe`; `bash tools/ci-receipt-staleness.sh` → **FRESH** (54/54 R hashes; Julia-side entries not verified when `DRM_JL_PATH` unset).
- **In progress:** nothing mid-run in parity lane.
- **Not working / blocked:** nothing external. Reader lanes and #1033 are **PROTECTED** foreign work.

## Key decisions and rationale

- **D-269:** env var **`DRM_JL_PATH` unchanged** — repo root with `Project.toml` (DRModels or legacy DRM).
- **D-277:** in-process relationship tests over machine-pinned constants on the next numeric gate.
- **D-276:** never `@`-mention agent personas on GitHub.
- **No CRAN / 0.7 submission** from this lane (separate board entry).
- **Live Julia:** `DRMTMB_JULIA_TESTS=true` and/or `NOT_CRAN=true`; CI without DRModels clone is **not** live parity evidence.

## Landing state

`~/shinichi-brain/tools/handoff_gate.sh` on drmTMB @ `54df129fe` (2026-09-24):

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` @ `54df129fe` | y | y | — | **LANDED** |
| This handover + board/split, branch `handover/2026-09-24-claude` | pending | pending | open after push | **CARRIED-OVER** until merged |
| Foreign local branches (parity-*, codex/*, claude/*, …) | mixed | mostly no | various | **PROTECTED FOREIGN** |
| `.unlazy/*/gates/*.md` with UNMET gates (gate-check) | n/a | n/a | — | **PROTECTED** — prior slices; not this handover’s scope; do not “fix” wholesale |
| Primary checkout untracked debris | n/a | n/a | — | **PROTECTED** — never `git add -A`; use `~/local-scratch/lanes/` worktree |
| #1033, `_julia_skip2_artifacts/` | n/a | n/a | open | **PROTECTED** |
| `source-pins.json` @ `430ef64cc` | y | y | — | **OWED** refresh |

FINDINGS-OF-RECORD: none

**Handoff gate note:** full-repo `handoff_gate.sh` also reports **38 UNMET** acceptance ledgers under `.unlazy/` (historical parity/night slices). That is **honest incomplete prior work**, not missing commits on this handover branch. This lane starts fresh at step 1 below; do not treat those ledgers as OWED unless you explicitly adopt a leaf.

## Classification snapshot (reconcile on pickup)

| Item | Class |
|---|---|
| Dinnage arc3 Waves A–C | **DONE** |
| D-269 bridge + module compat on main | **DONE** |
| Re-pin + regenerate parity-matrix / scoreboard / join at live DRModels SHA | **OWED** |
| Refresh `source-pins.json` | **OWED** |
| Promote `claim_status` for partial FE rows | **PROTECTED** (owner) |
| `cross_family_latent` partial by design (D-179) | **PROTECTED** |
| CRAN 0.7 submit | **RETRACTED** for this lane |
| #1033, reader #1417–#1419 | **PROTECTED** (foreign) |

## Next immediate steps

1. **OWED — Rehydrate (no product code yet):**

```sh
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/drmTMB"
# Prefer isolated worktree under ~/local-scratch/lanes/ from origin/main
export DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/DRM.jl"
export DRM_JL_PHYLO_PATH="$DRM_JL_PATH"
export DRMTMB_JULIA_TESTS=true NOT_CRAN=true
export JULIA_HOME="$HOME/.juliaup/bin"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
cd "<drmTMB-worktree>"
git fetch origin && git checkout -B claude/r-julia-parity-20260924 origin/main
bash tools/ci-receipt-staleness.sh
Rscript --no-init-file -e 'pkgload::load_all(compile=FALSE); testthat::test_file("tests/testthat/test-julia-module-compat.R", reporter="summary")'
```

   Classify every handover row **OWED / DONE / RETRACTED / PROTECTED** against live git. Launch **Rose** (systems auditor) before any public ledger or promotion claim (`.claude/agents/systems_auditor.toml`).

2. **OWED — First substantive slice:** Re-pin programme metadata and regenerate **generated** artefacts at measured DRModels `origin/main` (record SHA in commit message):

```sh
git -C "$DRM_JL_PATH" fetch origin && DRMODELS_SHA=$(git -C "$DRM_JL_PATH" rev-parse origin/main)
# Edit docs/dev-log/loop/parity-joint-20260905/source-pins.json (drmjl_base + note)
DRM_JL_PATH="$DRM_JL_PATH" Rscript tools/write-parity-matrix.R
DRM_JL_PATH="$DRM_JL_PATH" Rscript tools/write-parity-scoreboard.R
DRM_JL_PATH="$DRM_JL_PATH" Rscript tools/write-capability-status-join.R
Rscript --no-init-file -e 'testthat::test_file("tests/testthat/test-parity-matrix.R", reporter="summary")'
```

   Do **not** hand-edit `docs/design/parity-matrix.md`. If `R/julia-bridge.R` changes in the same PR, regenerate `lss-tip-identity/public-001.json` **LAST** (`docs/dev-log/after-task/2026-09-20-tip-receipt-refresh.md`).

3. **Then:** One `.unlazy/parity/gates/leaf-*.md` at a time, or [#1304](https://github.com/itchyshin/drmTMB/pull/1304) only if Shinichi assigns Codex overlap.

**Route heavy live verification to Codex when budget allows** (`R CMD check` with compilation, full Julia suite farms). Claude owns planning, bridge R glue, docs, and focused tests.

## Blockers / open questions

- None blocking bootstrap. Owner: `claim_status` promotion; `anova()` LRT refusal (both engines).
- Duplicate design-number IDs (17 slots) — claim by committing the slot.

## Gotchas and failed approaches

- **`git add -A`** forbidden; explicit paths only.
- Source truth: `git show origin/main:<path>`, not the shared Dropbox working tree.
- Green CI without live Julia ≠ bridge parity (#1081 teardown line).
- D-269: no silent LOAD_PATH fallback across checkouts.
- Parity-matrix generator fails closed on bad citation anchors.

## Files created / modified (handover commit)

- `docs/dev-log/handover/2026-09-24-claude-handover.md` (this file)
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/active-lane-split.md`

## Mission control

| repo | branch / main | CI / local | what matters now |
|---|---|---|---|
| drmTMB | `origin/main` @ `54df129fe` | receipt-staleness **FRESH** locally | D-269 on main; ledger 17/6/13/1; generated docs **OWED** re-pin |
| DRModels.jl | `origin/main` @ `e9d50a110` (re-measure) | branch CI on your edits | clone `~/Dropbox/Github Local/DRM.jl` |
| GLLVM.jl | separate lane | — | do not conflate unless cross-repo |

**Plan by leverage:** (1) pin + regenerate generated docs; (2) one leaf / one row; (3) DRModels follow-ups (Julia impl often Codex); (4) `claim_status` on owner word only.

## How to resume

**Working directory:** new worktree from `origin/main` under `~/local-scratch/lanes/` (not dirty primary checkout).

**Read order:** `AGENTS.md` → coordination board Active-Lane-Split → this file → [`2026-09-07-claude-parity-joint-handover.md`](2026-09-07-claude-parity-joint-handover.md) → [`plan-actual/2026-09-05-parity-joint.md`](../plan-actual/2026-09-05-parity-joint.md) → `git status` / `git log origin/main -5`.

**Human one-command start (authenticated terminal):**

```sh
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
claude "Rehydrate from docs/dev-log/handover/2026-09-24-claude-handover.md, AGENTS.md, and the coordination board Active-Lane-Split; classify handover items OWED/DONE/RETRACTED/PROTECTED; run Rose before public claims; then continue only the OWED Next Immediate Steps."
```

**Paste-ready prompt (end of doc):**

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-24-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

**Perspectives before public claims:** Rose (ledger wording), Fisher (promotion), Gauss (numerics), Boole (`engine = "julia"` docs).
