# Cursor Handover — drmTMB: run the 135-trace interval campaign

**You are Cursor**, picking up the drmTMB interval-evidence lane from a Claude Code session.
You inherit **no chat context**. This document plus `AGENTS.md` plus the current git state are the
authoritative record.

**Meta:** 2026-08-05 · from **Claude** (Claude Code) → to **Cursor** ·
`origin/main = b8d738fb4` · **census 182 `interval_feasible` / 60 `point_fit_recovery`**.

---

## 0. READ THIS FIRST — the working-directory trap

**The primary checkout is stale and will mislead you.**
`/Users/z3437171/Dropbox/Github Local/drmTMB` sits on branch `claude/handover-freshness-0718`,
**715 commits behind `origin/main`**, with **88 uncommitted files** belonging to earlier sessions.

- Files merged today **do not exist in that working tree.** A relative path to them resolves to nothing.
- `git log` there measures the *checkout*, not the repo — it reads as if the lane went quiet on 18 July.
- **Do not commit, clean, revert, or stage those 88 files.** They are not this lane's.

**Work in a fresh worktree:**

```bash
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
git fetch origin
git worktree add ~/local-scratch/worktrees/drmTMB-135trace -b cursor/135-trace-campaign origin/main
cd ~/local-scratch/worktrees/drmTMB-135trace
```

To read any current file without switching branches: `git show origin/main:<path>`.

---

## 1. Critical Context

**1. Your task is the 135-trace interval campaign. It is UNFENCED** (owner decision, 2026-08-05,
landed in PR #927). It is the **first census move of this programme**: **182 → 196** and
`FROZEN_CENSUS_POINT_FIT_RECOVERY` **59 → 45**. Every arc on 2026-08-05 was deliberately
census-neutral; yours is not. **The truth gate matters more here, not less.**

**2. Before planning, read
[`docs/dev-log/after-task/2026-08-04-prong-b-stack-landing-and-ci-ceiling.md`](../after-task/2026-08-04-prong-b-stack-landing-and-ci-ceiling.md) §9.**
Two of the ten contract clauses are enforced by **code that cannot fail** — `clamp_limited` is
hard-coded `FALSE` in every arc1/arc2 runner, and the unimodality / two-sided LR-crossing check does
not exist in `tools/`. **A guard that cannot fail will hand you a green light on a promotion.**
Red-test every guard against the thing it protects before trusting its green.

**3. Two questions are CLOSED by measurement. Do NOT reopen either.**
- The **χ̄² (chi-bar-square) boundary cutoff does not fix D-117 and makes it worse**: conditional
  coverage 0.0732 → **0.0488**. Measured on 4×1000 replicates; interval nesting held 4000/4000.
  See [`2026-08-05-d117-chibar-cutoff-arm/VERDICT.md`](../simulation-artifacts/2026-08-05-d117-chibar-cutoff-arm/VERDICT.md).
- **gllvmTMB's flagged `qchisq(level, 1)` is NOT a defect** — 7 of 8 uses are CI inversion, where
  χ²₁ is correct; the one hypothesis test is on *loadings*, an interior parameter.

**4. D-117: every *item* is closed; the DISCHARGE is an open owner call.** The **withheld PASS stays
withheld either way — do NOT reinstate it.** Discharge does not block your campaign.

---

## 2. What Was Accomplished (the session you are inheriting from)

Five merges, `8086c3ee1 → b8d738fb4`. Only **one** touched `R/`.

| PR | What | `R/` change |
|---|---|---|
| **#924** | `profile.boundary` user warning + `NEWS.md` + `?confint.drmTMB` + `convergence.Rmd` fix | **yes** — `R/profile.R` |
| **#925** | χ̄² cutoff **measured and rejected** | no |
| **#926** | REML interval coverage — **claim WITHHELD** | no |
| **#927** | Unfenced the 135-trace campaign; fixed a self-contradicting `NEXT =` pointer | no |
| **#928** | Claude-lane handover | no |

Detail lives in the after-task reports; do not re-derive it.

---

## 3. Current Working State

- **Working:** `main` = `b8d738fb4`. Census **182 / 60** verified. `capability_ledger.py --check` OK.
  `check-evidence-citations.R` 0 violations. Full `devtools::test()` last green at `e430d408a`
  (308 files, 0 failures).
- **In progress:** nothing of this lane's.
- **Blocked:** nothing.

---

## 4. Landing gate — read this honestly

`tools/handoff_gate.sh` returns **XX (fail)** for this repo. **That failure is NOT this lane's.**
It reports the pre-existing debris in the primary checkout: 88 uncommitted files, 2 unpushed commits
on the stale `claude/handover-freshness-0718` HEAD, and **424 unpushed commits across ~18 other
branches** (a mix of `claude/…` and `codex/…` from earlier sessions).

**This lane is fully landed:** every branch merged and deleted, nothing carried over. The gate cannot
distinguish lanes, so it fails on someone else's debris. **Do not try to clean it** — that debris is
other lanes' state and is explicitly out of scope.

---

## 5. Files Created / Modified this session (every path)

`R/profile.R` · `NEWS.md` · `AGENTS.md` · `man/confint.drmTMB.Rd` ·
`tests/testthat/test-profile-targets.R` · `vignettes/convergence.Rmd` ·
`docs/dev-log/after-task/2026-08-05-d117-profile-boundary-warning.md` ·
`docs/dev-log/after-task/2026-08-05-d117-chibar-cutoff-measured.md` ·
`docs/dev-log/after-task/2026-08-05-reml-interval-coverage.md` ·
`docs/dev-log/plan-actual/2026-08-05-d117-chibar-cutoff.md` ·
`docs/dev-log/plan-actual/2026-08-05-reml-interval-coverage.md` ·
`docs/dev-log/handover/2026-08-05-claude-handover-evening.md` ·
`docs/dev-log/simulation-artifacts/2026-08-05-d117-chibar-cutoff-arm/{VERDICT.md, chibar_arm.R, results/chibar_cell{1,4,5,6}.csv}` ·
`docs/dev-log/simulation-artifacts/2026-08-05-reml-interval-coverage/{PREREGISTRATION.md, VERDICT.md, ADJUDICATION.txt, reml_interval_arc.R, adjudicate.R, results/cell{1..6}.csv}`
— **29 files.**

**NOT this lane's** (also in the `8086c3ee1..b8d738fb4` range, from PR #923):
`README.md`, `docs/dev-log/dashboard/2026-07-11-capability-surface.html`.

---

## 6. Environment Cursor needs

| Item | Value |
|---|---|
| Repo root | `/Users/z3437171/Dropbox/Github Local/drmTMB` |
| **Work in** | a **fresh worktree** off `origin/main` (see §0) — never the primary checkout |
| R | **4.6.0** (2026-04-24) · `devtools` **2.5.2** · `TMB` **1.9.21** |
| Compile | `devtools::load_all()` builds `src/drmTMB.cpp` (~4,900 lines) — **first load takes minutes** |
| Safe verification | `Rscript --no-init-file -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-profile-targets.R")'` |
| Guards | `python3 tools/capability_ledger.py --check` · `Rscript --no-init-file tools/check-evidence-citations.R` · `python3 tools/profile_truth_gate.py` |
| Compute | **Totoro** — 384 cores, cap **150**; ControlMaster socket `~/.ssh/cm-*totoro*` (verified live 2026-08-05, load 2.69). **Never GitHub Actions (D-50).** |
| **Never stage** | the 88 uncommitted files in the primary checkout · `.worktrees/` · anything under another lane's branch |

---

## 7. Next Immediate Steps (your OWED list)

Run lane preflight first (`bash ~/shinichi-brain/tools/lane_preflight.sh <repo>`), diff against
current git state, and classify every item below **OWED / DONE / RETRACTED / PROTECTED** before acting.

1. **Run the 135-trace interval campaign.** Read `AGENTS.md`, then
   [`docs/dev-log/handover/2026-08-03-prong-b-next-lane-brief.md`](2026-08-03-prong-b-next-lane-brief.md).
   **Pre-register the promotion rule BEFORE fitting** (the D-117 pattern — see
   [`2026-08-05-reml-interval-coverage/PREREGISTRATION.md`](../simulation-artifacts/2026-08-05-reml-interval-coverage/PREREGISTRATION.md)
   for a worked example, including how to write a falsifier that tests the *right estimand*).
   Run `tools/profile_truth_gate.py`. **Promote no cell whose interval evidence fails its own
   contract.** Totoro, ≤150 cores. Smoke 1 cell before the grid.
2. **Owner decisions — surface, do not assume.** (a) Is D-117 discharged? (b) Re-score PR #926
   against a corrected falsifier? (c) Should the REML finding get a design doc — *"REML improves
   interval calibration while worsening point bias at very low replication"* is novel and
   cross-repo relevant, and currently lives only in that arc's `VERDICT.md`.
3. **Smaller / optional:** `drmSEM/.github/workflows/R-CMD-check.yaml:22` has `timeout-minutes: 45`.
   Measured 2026-08-05: **STILL LATENT, not at risk** — that suite maxes at ~10 min and its six
   "cancelled" runs are genuine concurrency cancels at 1.6–6.7 min. Tightening is optional hygiene;
   a ceiling bills nothing when jobs finish early.

**DEFER — fenced, do NOT start:** the full 7-method coverage-mapping grid (the 2026-07-06 maintainer
directive — 2026-08-05 ran *one* method contrast, not that); the `predict()` scale-axis defect (its
gate test **pins** current behaviour and must fail when `predict()` is fixed — update it then, never
relax it); the CI guard/check job split; the B4-CI `SOURCE_COMMIT` port; mc-0282's runner contract
(PROTECTED).

---

## 8. Sibling lanes — do not orphan them

This repo runs multiple lanes. The board is
[`docs/dev-log/active-lane-split.md`](../active-lane-split.md). Carried forward so your pointer does
not narrow the repo to this arc:

| Lane | State | Boundary |
|---|---|---|
| **Lane B E0** | PR **#858** `codex/lane-b-e0-readiness` **OPEN** (draft, 2026-07-27) | **FOREIGN (codex).** Verified 2026-08-05: a fail-closed pre-flight builder; no file overlap with anything merged today. Preserve all Lane B evidence, manifests, classifications, branches. |
| **Mesh/SPDE** | PR #893 `codex/drmtmb-spatial-mesh` draft; #891 its docs companion | Owns mesh/SPDE design + broad `R/drmTMB.R` / `src/drmTMB.cpp` edits. **Rebase before editing `R/profile.R`.** |
| **Missing-data cross brief** | PR #869 open, docs-scoped | Preserve missing-response / missing-predictor scope. |
| **C18 structured ZOB atoms** | LANDED (PR #898) | `mc-0615` withheld; spatial `mc-0606`/`mc-0616` deferred **and refused in code**. |

**Sequential, never concurrent (D-87/D-88):** one platform at a time per repo. You (Cursor) now own
this lane; Claude has stopped. If lanes appear to overlap, **surface it to Shinichi** — ownership is
his call, not yours to resolve.

---

## 9. Mission control

| Repo | main / CI | What shipped 2026-08-05 | Next by leverage |
|---|---|---|---|
| **drmTMB** | `b8d738fb4` · suite green at `e430d408a` (308 files, 0 fail) | boundary warning (#924); χ̄² measured + rejected (#925); REML coverage, claim withheld (#926); campaign unfenced (#927) | **1.** 135-trace campaign (182→196) · **2.** D-117 discharge (owner) · **3.** REML design doc |
| drmSEM | — | — | `timeout-minutes: 45` latent, not at risk — optional |

---

## 10. Gotchas & Failed Approaches

- **`gh pr merge --auto` is NOT wait-for-green here.** No required status checks → it merges
  *immediately*. Hit on #924; the check passed, but that was luck, not process.
- **A `cancelled` CI conclusion is ambiguous — measure the duration.** The `main` run for #924 read
  `cancelled` after **39m45s against a 75-minute ceiling** → concurrency cancel, not a timeout.
  GitHub logs both identically. **Compare duration to the limit; never read the conclusion string.**
- **A flag is a lead, not a finding.** The gllvmTMB χ̄² concern sat unchecked for weeks and was wrong.
- **Look for the identity before building the flag.** The χ̄²-corrected 95% interval *is* the ordinary
  90% interval, so a planned prototype-plus-campaign collapsed into two `confint()` calls.
- **A falsifier inherits the estimand of the evidence it was built from.** PR #926's was built from a
  *point-estimate* ladder and applied to *interval coverage*; it fired on a real divergence, not a defect.
- **Known residual, unresolved:** the brain's `check-after-task.R` passes only 1 of 3 recent repo
  reports, and all three of 2026-08-05's fail it. Either the reports should conform or the validator
  is stale — **an owner call, deliberately not resolved.**

---

## 11. How to Resume

Start a **fresh Cursor agent** in the repository and paste:

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-05-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

Then, before any edit: create the fresh worktree (§0), run lane preflight, and classify §7's items
**OWED / DONE / RETRACTED / PROTECTED**.
