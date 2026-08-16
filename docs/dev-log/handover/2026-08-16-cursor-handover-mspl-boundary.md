# Session Handover: the MSPL boundary-penalty lane

Meta: 2026-08-16 · **refreshed by Cursor (park reconcile)** · target **Shinichi / next agent after 0.7** ·
lane branch `claude/mspl-boundary-s0-s1` @ `d2a7c45e3` · worktree `.worktrees/mspl-s0s1` ·
**local tip ahead of `origin/claude/mspl-boundary-s0-s1` by 2** (S1 sign-off `d57e75de1` + S2
`d2a7c45e3`; **not pushed**) · `origin/main` ≈ `4953fcc52` · **no merge-to-main PR** (park + 0.7
quiesce).

> **Disposition: PARKED.** MSPL A1 S0–S2 is **0.8 groundwork**, not a 0.7 deliverable. Grok panel
> consensus (2026-08-16): park; no multi-agent MSPL cascade; no S3 without **D-139**; no merge to
> `main` during 0.7 quiesce. Claim fences:
> [`docs/dev-log/research/2026-08-16-mspl-a1-boundary-park.md`](../research/2026-08-16-mspl-a1-boundary-park.md).
>
> **Trust the repo over this document**, including over this sentence. The Claude-era body below
> named tip `a61181624` and OWED S1 sign-off + S2 — that is **stale**. Live tip and classification
> are in **Rehydration reconcile (2026-08-16 Cursor)** at the top of the OWED section.

## Critical Context — read these, in this order

1. **Park note (read first if reopening).**  
   `docs/dev-log/research/2026-08-16-mspl-a1-boundary-park.md`
2. **The programme.** `docs/dev-log/research/2026-08-16-drmtmb-mspl-transfer-packet.md` — S0–S4 plan
   of record. Do not re-plan it under the park.
3. **S1 derivation.** `docs/design/256-mspl-boundary-penalty-derivation.md` (sign-off boxes **checked**).
4. **S1 sign-off receipt.** `docs/dev-log/research/2026-08-16-mspl-s1-signoff-recheck.md`
5. **S2 after-task.** `docs/dev-log/after-task/2026-08-16-mspl-s2-boundary-penalty-a1.md`
6. **S0 defect record.**  
   `docs/dev-log/simulation-artifacts/2026-08-16-mspl-s0-defect-gates/VERDICT.md`
7. **0.7 release quiesce.** `docs/dev-log/coordination-board.md` (on `origin/main`).

## The question this lane answers

drmTMB implements MSPL (maximum softly-penalized likelihood) for **binomial separation** only.
Should it generalise to **boundary conditions** — random-effect SDs collapsing to zero (and
correlations at ±1)? The measured motivation: after the 2026-08-15 REML arm, boundary pile-up is
the residual of the small-`g` coverage problem — REML moved pooled coverage 0.9248 → 0.9463 but
boundary incidence only 0.153 → 0.138, with conditional-on-boundary coverage still 0.83.

## What Was Accomplished (on the lane branch)

**S0 — two pre-registered defect gates, both CONFIRMED.** Totoro, ~5 min, zero failed fits.

- **A (scale equivariance, 200 reps, Gaussian A1):** the shipped penalized objective is **not**
  scale-equivariant — fitting `y` vs `100·y` and back-scaling disagree in **200/200** replicates
  (mean 0.0196, max 0.134), against an ML control equivariant to 1.2e-06.
- **B (anchor ladder, 1,500 paired fits, shipped `estimator="mspl"` binomial route):** monotone
  pull toward `sd = 1`; at `sd 0.25` it **overshoots through truth**. On RMSE, **MSPL beats ML at
  every cell** and eliminates boundary collapse at sd 0.25 (ML 42% ≈ 0; MSPL 0%). Defects are
  parameterisation bugs in an estimator that already outperforms ML on point estimation — not a
  case against MSPL. This does *not* transfer to interval coverage.

**S1 — derivation + independent sign-off (DONE).**

- Penalty form forced by Theorem 1; chosen form
  `P_v(θ) = c_g · Q_{κ−,κ+}(log σ_u − mean_i η_i^σ)` with `c_g = 2√(q_v/g)`.
- Noether + Fisher re-checks **ACCEPTED** (`d57e75de1`); design 256 sign-off boxes checked.
  One wording fix in §6.3 (displacement bound) landed with the receipt.

**S2 slice 1 — A1 soft-penalty (DONE on tip, unpushed).**

- `drm_boundary_penalty()` / `penalty=` MAP route (`d2a7c45e3`): R + C++ Gaussian leaf, confint/
  profile hard-abort, focused tests PASS 137. Claim ceiling: **experimental MAP only** — not
  `estimator = "mspl"`, not all-family, no interval/coverage claim.

## Rehydration reconcile (2026-08-16 Cursor) — DONE / OWED / PROTECTED

Live evidence: lane preflight (Cursor; 11 lanes live; this session took **MSPL park docs only**);
`git fetch --prune origin`; worktree `.worktrees/mspl-s0s1` @ `d2a7c45e3`;
`## claude/mspl-boundary-s0-s1...origin/claude/mspl-boundary-s0-s1 [ahead 2]`;
park note was **untracked** until this refresh stages it for commit (Shinichi must approve commit/
push).

| Item | Class | Live note |
| --- | --- | --- |
| S0 defect gates + RMSE | **DONE** | Artifacts on lane |
| S1 derivation (design 256) | **DONE** | Sign-off boxes checked |
| S1 Noether + Fisher re-check | **DONE** | `d57e75de1` + receipt |
| S2 A1 `drm_boundary_penalty()` | **DONE** | Tip `d2a7c45e3`; do **not** re-implement |
| Park note + claim fences | **OWED → in progress** | File exists; commit/push still owner call |
| Handover freshness (this file) | **OWED → DONE this session** | Supersedes Claude tip `a61181624` / “S2 blocked” OWED |
| Push tip (ahead 2) | **OWED (optional)** | Push when convenient; **still no merge-to-main PR** |
| S3 campaign | **PROTECTED** | Needs prereg + **D-139**; park forbids starting |
| S4 heritability | **PROTECTED** | Not started |
| Multi-agent MSPL cascade / ultra-plan | **PROTECTED / PARKED** | Grok panel: park |
| 0.7 freeze / quiesce / candidate `302ac2579` | **PROTECTED** | Do not merge shipped files to `main` |
| Missing-data (#1033) / `R/missing-data.R` | **PROTECTED FOREIGN** | Claude; do not edit |
| Primary checkout `claude/handover-freshness-0718` | **PROTECTED** | Dirty / stale; never work or stage there |
| Research notes “already on `origin/main`” (Claude text) | **RETRACTED claim** | Prior Cursor receipt: notes were on freeze lane; do not merge freeze to fetch |

### Claude-era OWED (historical — do not re-run)

1. ~~Lane preflight + reconcile~~ → **DONE** (this session + prior Cursor S1 session).
2. ~~S1 Noether/Fisher sign-off~~ → **DONE** (`d57e75de1`).
3. ~~S2 if both pass~~ → **DONE** (`d2a7c45e3`).
4. S3 → remains **PROTECTED** (unchanged).

## Key Decisions & Rationale (still binding)

- **Surface it as `penalty`, not `estimator`.** Extend `drm_phylo_penalty()`/MAP vocabulary.
- **Opt-in, never default.**
- **REML × penalty stays mutually exclusive.**
- **Knob-free if possible** — rate and anchor are derived.
- **0.8 groundwork** — park until 0.7 quiesce lifts; see park note reopen conditions.

## Files on the lane (tip `d2a7c45e3` + untracked park)

```
docs/design/256-mspl-boundary-penalty-derivation.md
docs/dev-log/research/2026-08-16-drmtmb-mspl-transfer-packet.md
docs/dev-log/research/2026-08-16-mspl-transfer-*.md
docs/dev-log/research/2026-08-16-mspl-s1-signoff-recheck.md
docs/dev-log/research/2026-08-16-mspl-a1-boundary-park.md   ← park fences (commit when approved)
docs/dev-log/simulation-artifacts/2026-08-16-mspl-s0-defect-gates/
docs/dev-log/after-task/2026-08-16-mspl-s2-boundary-penalty-a1.md
docs/dev-log/handover/2026-08-16-cursor-handover-mspl-boundary.md
R/penalty.R  R/drmTMB.R  R/methods.R  R/profile.R  src/drmTMB.cpp
man/drm_boundary_penalty.Rd  tests/testthat/test-boundary-penalty.R
```

## Landing State

| Item | State |
| --- | --- |
| `claude/mspl-boundary-s0-s1` @ `d2a7c45e3` | **LOCAL tip**; origin still at `f91751a41` (handover-only). Ahead 2 unpushed. |
| Park note | **Present, was untracked**; refreshed handover points at it. |
| Totoro `~/mspl-s0/` | **CARRIED-OVER** convenience only; CSVs are committed. |
| 0.7.0 freeze / platform matrix | **PROTECTED — not yours.** |
| Missing-data #1033 | **PROTECTED FOREIGN.** |
| Primary checkout dirty tree | **PROTECTED — do not stage.** |

## Next Immediate Steps — OWED only (park-compatible)

1. **Shinichi:** approve a **docs-only** commit on this worktree that adds
   `docs/dev-log/research/2026-08-16-mspl-a1-boundary-park.md` + this refreshed handover (+
   check-log line). Optionally `git push -u` the tip (ahead 2 + that docs commit). **Do not** open
   a merge-to-main PR.
2. **Resume 0.7 tidy / platform matrix** — MSPL stays parked.
3. **Do not** start S3, re-implement S2, touch `R/missing-data.R`, or run a multi-agent MSPL
   cascade until park reopen conditions are all met (see park note).

## Blockers / Open Questions (carry forward; do not rediscover)

1. Sign flip relocated, not removed (E2).
2. Penalty may be too soft to matter at g=40 (~0.04 SE) — large S3 “repair” ⇒ implementation error first.
3. F4 / boundary-flag deletion is structural; ML-defined-boundary scoring remains mandatory for any future campaign.
4. §11 q=1 degeneracy claim remains AGENT-INFERRED pending Košuta Web Appendix B.II.

## Gotchas / Failed Approaches (do not repeat)

- Do not validate on the D-117 grid alone (sd ∈ {0.5, 1.0} cannot separate bias correction from pull-to-1).
- Score bias **and** RMSE.
- Do not conflate equivariance (S0-A) with shrinkage target (S0-B).
- Never work in the primary checkout for this lane.

## How to Resume (after 0.7)

```sh
cd '/Users/z3437171/Dropbox/Github Local/drmTMB'
bash ~/shinichi-brain/tools/lane_preflight.sh .
git fetch --prune origin
# reuse existing worktree — do not create a second one on the same branch
cd .worktrees/mspl-s0s1
git status --short --branch
# read park note; then only if reopen conditions all hold → S3 prereg + D-139 ask
```

R: `R_PROFILE_USER=/dev/null Rscript --no-init-file`. Compute: Totoro ≤150 cores (D-143),
`OPENBLAS_NUM_THREADS=1`; DRAC only for arrays. **No campaign is authorised by this handover.**

**Paste-ready prompt (parked):**

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-16-cursor-handover-mspl-boundary.md plus
docs/dev-log/research/2026-08-16-mspl-a1-boundary-park.md. Confirm park still holds; do not
start S3. If asked only to commit/push the park docs + tip, do that and STOP.
```
