# Session Handoff: D-117 closed out by measurement; the 135-trace campaign is UNFENCED

**Meta:** 2026-08-05 (evening) · from **Claude** (Claude Code) · to a fresh **Claude** session ·
context high. **Repo:** `drmTMB`, `origin/main = 5c4fbe8d7`. **Census 182 / 60, unchanged all day.**

---

## Critical Context

**1. The next arc is the 135-trace interval campaign, and it is UNFENCED** (owner decision, this
session). It is the **first census move of the programme**: 182 → 196 and
`FROZEN_CENSUS_POINT_FIT_RECOVERY` 59 → 45. Everything else today was deliberately census-neutral;
this one promotes cells, so the truth gate and pre-registration discipline matter *more* here.

**2. Before planning it, read `docs/dev-log/after-task/2026-08-04-prong-b-stack-landing-and-ci-ceiling.md`
§9.** Two of the ten contract clauses are enforced by **code that cannot fail** — `clamp_limited` is
hard-coded `FALSE` in every arc1/arc2 runner, and the unimodality / two-sided LR-crossing check does
not exist in `tools/`. A guard that cannot fail will hand you a green light on a *promotion*. That
is the worst place to discover it.

**3. Two questions are settled by measurement — do NOT reopen them.**
- The **χ̄² boundary cutoff does not fix D-117** and makes it worse: 0.0732 → **0.0488**. Measured,
  4×1000 replicates, nesting held 4000/4000. See §10b of the warning arc report and
  `2026-08-05-d117-chibar-cutoff-arm/VERDICT.md`.
- **gllvmTMB's flagged `qchisq(level,1)` is NOT a defect** — 7 of 8 uses are CI inversion (χ²₁
  correct); the one hypothesis test is on *loadings*, an interior parameter.

**4. D-117: every *item* is closed. The DISCHARGE is still the owner's call, and the withheld PASS
stays withheld either way — do NOT reinstate it.** Discharge no longer blocks the campaign.

---

## What Was Accomplished

Four merges, `8086c3ee1 → 5c4fbe8d7`. **No `R/` change except #924.**

**#924 — the `profile.boundary` user warning.** The only item that had been gating a D-117
discharge. `confint(method = "profile")` now warns (class `drmTMB_profile_boundary_warning`) when it
returns a *usable* interval at a variance boundary. Predicate is deliberately narrower than
`profile.boundary == TRUE`: `profile_failed` and `clamp_limited` rows carry the same flag but return
NA endpoints and already report through `conf.status`. Also fixed `vignettes/convergence.Rmd`, which
recommended profile intervals as the boundary *remedy* — the exact steering the warning cautions
against. Full suite green: 308 files, 0 failures.

**#925 — the χ̄² cutoff, measured and rejected.** A prior-work sweep found the brain had documented
since 2026-07-22 that a VC at a boundary needs a chi-bar-square reference, and had flagged the
identical call as a defect in *gllvmTMB* — with drmTMB never connected to it. Measured rather than
argued. **The identity that made it cheap: the χ̄²-corrected 95% interval IS the ordinary 90%
interval** (both are the level set at `qchisq(0.90,1)/2`), so a planned prototype-plus-campaign
became two `confint()` calls. The χ²₁ arm reproduced D-117 *exactly* (boundary 495/41/63/0) as a
harness check.

**#926 — REML interval coverage. Claim WITHHELD.** 6 cells × 1000 paired replicates on
`sd:sigma:(1 | id)`. REML covered better in 5 of 6 cells, significantly in 4. **The pre-registered
rule returned NOT ADMITTED** — the `n_each = 3` falsifier fired in 2 cells where it was written to
fire in none. The investigation *cleared the harness* (it reproduces the repo's own 2026-07-08 probe
including its sign reversal). **The falsifier was mis-specified**: built from a *point-estimate*
ladder, applied to *interval coverage*. Those diverge — at low replication REML makes the estimate
worse and the interval better. **Not used to re-score**; routed to Rose/owner.

**#927 — unfenced the 135-trace campaign**, and fixed a self-contradiction where `AGENTS.md` carried
two `NEXT =` blocks saying different things.

---

## Current Working State

- **Working:** `main` = `5c4fbe8d7`. Census **182 / 60** verified. `capability_ledger.py --check` OK.
  `check-evidence-citations.R` 0 violations. Full suite last green at `e430d408a` (308 files).
- **In progress:** a `main` CI run covering the merges. **Read its duration, not its conclusion** —
  see Gotchas.
- **Not working / blocked:** nothing of this lane's.

---

## Key Decisions & Rationale

1. **Measure, don't argue.** Both the χ̄² question and the REML question were settled with seeded
   runs rather than reasoning. The χ̄² one cost ~4 minutes because of the level-set identity.
2. **Withhold the REML claim** on the rule as written, even though the numbers look good and even
   though I believe the rule was wrong. The agent that writes both the rule and the objection to it
   must not adjudicate between them.
3. **Pre-register before fitting** (`041905883`, 07:16:39, before the campaign). The χ̄² arc had
   substituted a committed prediction instead; that deviation is recorded, and this arc did not
   repeat it.
4. **Local compute, not Totoro**, for both campaigns — 4 and 7 minutes respectively. Totoro was
   verified reachable (384 cores, load 2.69) and genuinely not needed. Nothing on GitHub Actions.
5. **Do NOT change the `REML` default** on this evidence. One narrow cell family, and the repo has a
   known counter-case at low replication.

---

## Landing State

`handoff_gate.sh` discipline applied. **This lane is fully landed. Nothing is carried over.**

| Artifact | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `profile.boundary` warning + docs + vignette fix | y | y | #924 merged | **LANDED** |
| χ̄² measurement + verdict + 4 result CSVs | y | y | #925 merged | **LANDED** |
| REML campaign + pre-registration + 6 result CSVs | y | y | #926 merged | **LANDED** |
| 135-trace unfence + pointer fix | y | y | #927 merged | **LANDED** |
| brain: 2 new notes + `WHAT-WORKS` links | y | n/a | n/a | **LANDED** (D-37; `5ca0245`) |
| PR **#858** `codex/lane-b-e0-readiness` | — | — | #858 draft | **FOREIGN (codex).** Verified: a fail-closed pre-flight builder, no overlap with any file touched today. |
| primary checkout `claude/handover-freshness-0718`, 88 uncommitted | n | n | — | **NOT THIS LANE'S** — pre-existing. Do not claim or clean. |

---

## Next Immediate Steps

1. **Run the 135-trace interval campaign.** Unfenced. Read `AGENTS.md` then
   `docs/dev-log/handover/2026-08-03-prong-b-next-lane-brief.md`. Pre-register the **promotion**
   rule before fitting; run `tools/profile_truth_gate.py`; promote no cell whose interval evidence
   fails its own contract. Totoro, ≤ 150 cores, D-50. **Read §9 of the CI-ceiling report first
   (see Critical Context 2).**
2. **Owner decisions — surface, do not assume.** (a) Is D-117 discharged? (b) Re-score #926 against
   a corrected falsifier? (c) Should the REML finding get a design doc — "REML improves interval
   calibration while worsening point bias at very low replication" is novel and cross-repo relevant,
   and currently lives only in `2026-08-05-reml-interval-coverage/VERDICT.md`.
3. **Smaller:** `drmSEM/.github/workflows/R-CMD-check.yaml:22` carries `timeout-minutes: 45`.
   Measured this session: **STILL LATENT, not at risk** — drmSEM's suite maxes at ~10 min and its six
   "cancelled" runs are genuine concurrency cancels at 1.6–6.7 min. Tightening is optional hygiene,
   not a fix; a ceiling bills nothing when jobs finish early.

**DEFER — fenced, do NOT start:** the full 7-method coverage-mapping grid (the 2026-07-06 maintainer
directive — this session ran *one* method contrast, not that); the `predict()` scale-axis defect (its
gate test **pins** current behaviour and must fail when `predict()` is fixed — update it then, never
relax it); the CI guard/check job split; the B4-CI `SOURCE_COMMIT` port; mc-0282's runner contract
(PROTECTED).

---

## Blockers / Open Questions

- **Issue #680 / D-12(b)** — the small-sample *width* recalibration (`qchisq(1−α,1) → qt(1−α,df)²`)
  is **OPEN with zero comments**, no decision, no blocker. It is a **larger** cutoff — the opposite
  direction from the rejected χ̄² — and a different problem. D-12 separates them deliberately;
  do not merge them.
- **design-219 is NOT contradicted.** The cross-repo map claims its per-axis rule is "empirically
  contradicted" for the sigma axis, citing profile 0.853 and DRM.jl bootstrap 0.53. That inference
  does not hold: design-219 governs the **Wald** channel, and the 2026-07-06 pilot's Wald numbers
  (0.9928 / 0.9931) *confirm* its rationale. Do not "fix" design-219 on that basis.

---

## Gotchas & Failed Approaches

- **`gh pr merge --auto` is NOT wait-for-green on this repo.** With no required status checks it
  merges *immediately*. I hit this on #924 — it landed while `R-CMD-check` was still running (it
  passed, but that was luck, not process). If you want a PR gated on the check, that needs a
  branch-protection rule.
- **A `cancelled` conclusion is ambiguous — measure the duration.** The `main` run for #924 read
  `cancelled`; it had run **39m45s against a 75-minute ceiling**, so it was a concurrency cancel
  caused by merging #925/#926 on top, not a timeout. The repo's own rule: compare duration to the
  limit, never read the conclusion string.
- **A background watcher must not be backgrounded twice.** I wrapped a wait-loop in `( … ) &` inside
  an already-backgrounded command; the outer shell exited immediately and took the loop with it, and
  I briefly reported a working watcher that had never run.
- **The primary checkout is a trap.** It sits on `claude/handover-freshness-0718`, ~700 commits
  behind `main`, with 88 uncommitted files. Its local `main` ref is stale too. Read current content
  with `git show origin/main:<path>` and work in a fresh worktree.
- **A flag is a lead, not a finding.** The gllvmTMB χ̄² concern sat unchecked for weeks and was
  wrong. Checking it cost one scout agent.

---

## A residual I found and did NOT fix — someone should decide

**The brain's after-task validator and this repo's after-task reports have drifted apart.**
`~/shinichi-brain/tools/check-after-task.R` requires a 12-section structure
(`## 2. Implemented`, `## 3a. Decisions and Rejected Alternatives`, `## 4. Files Touched`,
`## 5. Checks Run`, `## 6. Tests of the Tests`, `## 7a. Issue Ledger`, `## 8. Consistency Audit`,
`## 9. What Did Not Go Smoothly`, `## 10. Known Residuals`, `## 11. Team Learning`,
`## 12. Cross-Product Coverage`). Measured on three recent reports:

| Report | Validator |
|---|---|
| `2026-08-04-d117-10group-profile-gate.md` | **PASS** |
| `2026-08-04-prong-b-stack-landing-and-ci-ceiling.md` | **FAIL** |
| `2026-08-03-spatial-q2-confidence-eye.md` | **FAIL** |

**My three reports from this session also FAIL** — I wrote them to match the recent repo house style
rather than the validator, which I did not check until the end. That was my error.

I did not retrofit anyone's reports, and I did not rewrite mine, because the right fix depends on a
call that is not mine: **either the reports should conform, or the validator is stale and should be
relaxed.** A validator that most recent reports fail is either unenforced or wrong, and quietly
leaving it that way is how a gate rots. Surfacing it, not resolving it.

## Reusable lessons filed to the brain

- [[Two implementations agreeing is not exoneration when they share an assumption]] — a comparator
  only exonerates you if it **differs where it matters**; plus the look-for-the-identity move that
  turned a prototype-plus-campaign into two `confint()` calls.
- [[A falsifier must test the same estimand as the evidence it was derived from]] — and the
  procedural half: report that it fired rather than quietly re-scoring.
