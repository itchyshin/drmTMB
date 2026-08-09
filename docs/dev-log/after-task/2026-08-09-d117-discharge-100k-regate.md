# After-task — D-117 discharge: the 10-group profile gate re-run at nrep = 100,000

**Date:** 2026-08-09 · **Platform:** Claude (Claude Code), solo — Claude ran the live R/TMB and
Totoro compute · **Lane:** `claude/d117-discharge` off `origin/main @ a2695a788` ·
**Foreign lanes:** PRs #959, #958, #957, #955, #937, #858 and ~24 `codex/`/`cursor/` branches —
all untouched.

> **Headline: the gate PASSES at 100,000 replicates, and my pre-registered prediction that it would
> not was WRONG.** Pooled coverage **0.924800** (SE 0.000417) over 400,000 attempts; every cell
> clears `ss_floor(10) = 0.918` on **raw** coverage, and the strict one-sided lower confidence bound
> passes too. The discharge decision remains the owner's.

## 1. Goal

Answer, defensibly and with the prediction fixed in advance, whether D-117 discharges — i.e.
whether the 2026-08-04 PASS was an artifact of the `coverage + 2×MCSE` margin rule at only 1,000
replicates. Resolve or explicitly refuse every open D-43 panel finding, and cost both the hold and
the document-and-ship paths so the owner chooses with both priced.

Secondary: defuse a documentation landmine pointing a fresh session at an **aborted** arc.

## 2. Implemented

Four cells × 100,000 replicates on Totoro (90 cores, ~20 min, all `rc=0`), scored by the
**byte-identical** frozen scorer.

| Cell | N | coverage | exact 95% CI | score | LCB | verdict |
|---|---:|---:|---|---:|---:|---|
| `g10_n04_sd05` | 40 | 0.922900 | (0.9212, 0.9245) | 0.924587 | 0.9215 | PASS |
| `g10_n04_sd10` | 40 | 0.925670 | (0.9240, 0.9273) | 0.927328 | 0.9243 | PASS |
| `g10_n10_sd05` | 100 | 0.925530 | (0.9239, 0.9271) | 0.927190 | 0.9242 | PASS |
| `g10_n10_sd10` | 100 | 0.925100 | (0.9235, 0.9267) | 0.926764 | 0.9237 | PASS |

**OVERALL: PASS.** 100,000/100,000 finite intervals, convergence 1.000, `pdHess` 1.000, every cell.

Also: a regression test locking the `confint()` boundary warning; a dated addendum closing
`VERDICT.md §4`; the roadmap landmine defused; a decision packet for the owner.

## 3a. Decisions and Rejected Alternatives

- **Pre-register before running, with a numeric falsification threshold.** Chosen over "run and
  interpret". The prediction (raw coverage ≥ 0.916227 ⇒ prediction wrong) was committed at
  `ab83638f5` before any 100k fit, and it *was* falsified. Without it the PASS would read as
  confirmation rather than as a refuted hypothesis.
- **`nrep = 100000`, not more.** Seeds are `20260727 + 100000·cell_i + r` with `cell_i ∈ {1,4,5,6}`;
  cells 4/5 and 5/6 abut exactly at 100,000 and **collide at 100,001**. Rejected: a larger run.
- **Copy the scorer byte-identical rather than parameterise it.** SHA-256 verified equal to the
  2026-08-04 original, so the frozen rule provably could not drift. Cross-checks went in a
  *separate* script.
- **Branch off `origin/main`, not `claude/07-release-slice`.** `warn_profile_boundary()` is already
  on main via `4b601a448`, so the release slice was unnecessary and would have entangled draft PR
  #959 with this evidence.
- **Rejected: re-specifying `ss_floor` to price within-group replication.** The floor is `g`-only
  and ignores `n_per`/`N` — recorded as a finding *before* results precisely so it could not later
  look like a rescue. It did not need to be one; the N = 40 cells cleared the bar.
- **Rejected: conditioning the gate on `profile.boundary`.** The owner decided pooled-as-gate,
  conditional-as-diagnostic. Changing the estimand mid-arc would be a goalpost move — here in the
  *permissive* direction, since conditioning would fail.
- **Rejected: committing the raw CSVs.** ~195 MB (~31 MB gzipped) is disproportionate; SHA-256s and
  the regeneration command are recorded instead, and the omission is stated rather than silent.

## 4. Files Touched

Eleven commits on `claude/d117-discharge`, **not pushed**. Only `docs/dev-log/**` and one new test
file — **no `R/`, `DESCRIPTION`, `NEWS.md`, or `_pkgdown.yml`**.

- `docs/dev-log/simulation-artifacts/2026-08-09-d117-100k-regate/` — `PREREGISTRATION.md`,
  `PREDICTION-OUTCOME.md`, `VERDICT-100K.md`, `PANEL-FINDINGS-2-3-4.md`, `CROSSCHECKS.csv`,
  `results/SUMMARY.csv`, `campaign100k.log`, `score_d117_gate.R`, `a1_profile_common.R`,
  `crosschecks_100k.R`, `prefix_check.R`
- `docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/VERDICT.md` — addendum only
- `docs/dev-log/release-audits/2026-08-09-d117-discharge-decision-packet.md`
- `docs/dev-log/internal-roadmap.md`, `docs/dev-log/check-log.md`
- `tests/testthat/test-d117-boundary-warning.R` (new)

## 5. Checks Run

| Check | Result |
|---|---|
| S0 smoke — cell 4, `--nrep=50`, one fit inspected past its guards | ✅ 50/50 converged, 0 NA, coverage 0.96 |
| Local ↔ Totoro parity, same seeds | ✅ identical to 7 s.f. (`estimate_sd = 0.1919612`) |
| Campaign, 4 × 100,000 | ✅ all `rc=0`, `CAMPAIGN_COMPLETE` |
| Frozen scorer (byte-identical, SHA-256 verified) | ✅ **OVERALL PASS** |
| Pre-registered cross-checks — one-sided LCB + exact `binom.test` | ✅ all 4 pass, p = 1 |
| **Prefix reproduction** vs banked 2026-08-04 | ✅ bit-exact, `max\|diff\| = 0.000e+00`, 0/1000 disagreements |
| Mechanical verify (S6) — 10 checks | ✅ ALL PASS |
| `test_dir(filter = "d117-boundary-warning\|profile-targets")` | ✅ **880 PASS, 0 fail, 0 error** |
| `check-after-task.R` on the 2026-08-04 report (finding #5) | ✅ passed — finding genuinely actioned |
| Fence audit — files touched vs `origin/main` | ✅ docs + 1 test only |

## 6. Tests of the Tests

The verification was itself verified, in four ways:

1. **The scorer was proved unable to drift** — SHA-256 compared against the 2026-08-04 original
   rather than assumed equal. S6 re-checked it independently.
2. **The cross-check script was smoke-tested against known data.** Run on the 2026-08-04 results
   first, where the right answers were already known; it reproduced 0.914 / 0.929 / 0.937 / 0.931
   and the conditional 0.856566 / 0.073171 / 0.253968 exactly. A bug found at the end would have
   been expensive.
3. **The prefix check is a test of the whole apparatus**, not of the result. It would have failed
   had the harness or package changed — and it mattered, because the package *was* rebuilt with
   `4b601a448` in between.
4. **The producer did not judge.** S6 (mechanical) and the D-43 panel are fresh contexts; the panel
   was dispatched **with Bash and git**, the exact capability whose absence invalidated the
   2026-08-04 Noether seat.

## 7a. Issue Ledger

| Finding (from `D43-PANEL.md`) | Status |
|---|---|
| #1 pooled PASS averages two regimes | **DECIDED** by owner — pooled is the gate, conditional a diagnostic |
| #2 unreported point-estimate bias | **RESOLVED** — it is ML bias; lme4 pairing settles attribution. Two sub-items newly surfaced (log-SD statistic unstable in the boundary-heavy cell; bias not a function of `g` alone) |
| #3 "not materially worse" at z ≈ 2.5 | **RESOLVED, and inverted** — against a like-for-like `g=10` comparator z = **−1.586, not significant**; only a comparator pooled across `g` makes it significant (z = −3.490) |
| #4 D-97 provenance | **RESOLVED for the premise**; surviving caveat — the corrected 0.9400 comparator is itself pooled across `g` |
| #5 after-task failed the hub validator | **VERIFIED actioned** — `check-after-task.R` passes |
| #6 no user-facing boundary warning | **CLOSED** — fires on the user path, silent otherwise; 9 PASS |

**D-43 panel (2026-08-09): 2 of 3 NOT-DONE → the composite claim is WITHHELD.**

| seat | lens | model | verdict |
|---|---|---|---|
| Noether | mathematical consistency | Sonnet | **DONE** — zero discrepancies across every recomputed claim |
| Grace | reproducibility / evidence chain | Sonnet | **NOT-DONE** — no environment fingerprint; provenance asserted not pinned; regeneration command broken |
| Rose | claims and scope (load-bearing) | Opus | **NOT-DONE** — the recovery half was never measured at 100k; no after-task shipped |

Panel-driven repairs, all made **after** the verdict and therefore **not re-adjudicated**:

| finding | severity | repair |
|---|---|---|
| Rose #1 — "all findings resolved" false; no after-task | BLOCKING | this report; §7a now covers all six |
| Rose #2 — recovery half unmeasured at 100k | BLOCKING | `VERDICT-100K.md §6b`, recomputed from the 400,000 rows |
| Rose #3 — packet's preconditions circular; log-SD caveat unfolded | MATERIAL | §6b; the log-SD statistic is shown to be *unusable* in the boundary-heavy cell |
| Rose #4 — brief stale; document edited mid-review | MATERIAL | recorded in §9 and §11; no repair possible retroactively |
| Rose #5 — roadmap commit off-scope for this lane | MINOR | accepted; content accurate, lane wrong |
| Grace #1 — no environment fingerprint | MATERIAL | `PROVENANCE.md` |
| Grace #2 — package provenance asserted | MATERIAL | `PROVENANCE.md` — source tree hash proven identical |
| Grace #3 — regeneration command broken | MINOR-MATERIAL | `VERDICT-100K.md §9` corrected |

## 8. Consistency Audit

- `VERDICT.md §4` (2026-08-04) claimed no boundary warning existed. True when written; overtaken by
  `4b601a448` one day later. Resolved by a **dated addendum**, leaving the original text intact.
- The lme4 parity claim was bounded to the data it rests on: the comparator ran at n = 1,000 and was
  **not** re-run at 100k, so 396,000 of 400,000 new attempts have no counterpart. Corrected
  proactively at `423b30ac6`.
- `internal-roadmap.md` presented the **aborted** Beta-phylo LSS arc as "current closeout"; two
  dependent queue items reclassified BLOCKED.
- Coverage claims are scoped to the **A1 scalar Gaussian corner** throughout.
- **Recovery figures now come from the 100k data, not the n = 1,000 data.** Anything citing
  −16.90 / −9.12 / −9.05 / −9.16% is stale; the current values are
  **−15.76 / −9.31 / −10.26 / −8.34%** (`VERDICT-100K.md §6b`). The decision packet
  (`2026-08-09-d117-discharge-decision-packet.md §1`) still cites the n = 1,000 figures and
  **should be read against §6b**; it was written before they were recomputed.
- The composite claim is **withheld** by the panel; the coverage result itself was independently
  reproduced by two of the three reviewers.

## 9. What Did Not Go Smoothly

- **The named handover did not exist at the given path.** `2026-08-09-claude-handover-d117-discharge.md`
  lives only on `claude/07-release-slice`, so a direct read failed. Found by scanning every branch.
- **The task I was asked to continue was already done.** The 2026-08-03 "Next Immediate Steps" were
  superseded: PRs #907/#908 merged, the Arc 7 truth gate landed (`e5413c98f` + `e62ffbc96`, in CI),
  Prong B's fences opened. Three recon agents were needed to establish this before any planning.
  Following the handover literally would have rebuilt finished work.
- **Semantic brain search missed D-117 entirely.** `search_notes` returned adjacent notes;
  deterministic `grep` over `DECISIONS.md` found it. The grep was load-bearing, exactly as the
  ultra-plan sweep receipt requires.
- **I nearly missed panel finding #5.** My inherited framing listed #1–#4 and #6; #5 existed and had
  to be found by reading `D43-PANEL.md` directly.
- **My central prediction was wrong** — see §11.
- **I measured half the gate.** D-117 says "recovery/coverage". I pursued the coverage question the
  handover framed and never asked whether the *recovery* half also needed re-measuring at 100k —
  even though the data was on disk and the computation took under a minute. The load-bearing panel
  seat found it. Inheriting a framing is not the same as checking it against the decision's own
  words.
- **I edited a document while reviewers were reading it.** The lme4 scope fix (`423b30ac6`) landed
  mid-panel; one reviewer observed HEAD advancing under them, and the dispatch brief said 9 commits
  when there were 11. The fix was correct and the timing was wrong.
- **A cross-platform hash comparison reported a false MISMATCH** on the package source, which for a
  few minutes looked like a provenance failure. Cause: macOS and GNU `sort` collate
  `associate-pairs.R` against `associate-pairs-sandwich-*.R` differently, so identical files rolled
  up in different orders. Per-file hashes matched throughout.
- Plan mode re-engaged mid-execution, briefly halting writes; the detached Totoro campaign was
  unaffected.

## 10. Known Residuals

- **The boundary sub-population remains the honest caveat.** Conditional coverage
  0.8683 / 0.1021 / 0.2387 / **0.0000**, contributing 85% / 45% / 78% / 1% of each cell's miss.
  `g10_n10_sd10`'s 0/89 is newly visible — n = 1,000 had zero boundary events there.
- **The lme4 comparator was not re-run at 100k.** Cheap, obvious, not done.
- **`package_commit` records `NA`** when the runner loads via `--repo`/`pkgload`. Provenance rests
  on prose plus the worktree HEAD, not on a field in the data.
- **`ss_floor` is `g`-only** — it ignores `n_per`/`N`, so N = 40 and N = 100 cells face the same
  bar. A question for a separate, separately pre-registered arc.
- Raw CSVs (~195 MB) are not committed; SHA-256s and a regeneration command stand in.
- The branch is **unpushed** and no PR is open. Nothing was merged, tagged, or released.

## 11. Team Learning

- **Pre-registration is worth most when it is wrong.** Predicting BORDERLINE and measuring PASS is
  the outcome that proves the process was not reverse-engineered. It only works because the
  threshold was numeric and committed first.
- **A control is only worth having if it could have fired.** The prefix check confirmed rather than
  overturned — but a package rebuild with `4b601a448` in between was a live rival explanation for
  the 0.9140 → 0.9229 shift, and without the check the interpretation would have been assumption.
- **Sampling noise deceives about shape, not just level.** At n = 1,000 the four cells spanned
  0.914–0.937 and invited a story about a distinctly worse corner. At 100k they span 0.0028. The
  heterogeneity was never there.
- **Check the comparator before believing the contrast.** Finding #3's "detectably below" survived
  months because a `g = 10` result was compared against a figure pooled across larger `g` — the very
  error D-117 exists to catch. The estimator was never the problem.
- **Dispatch capability is part of review validity.** The 2026-08-04 Noether seat returned NOT-DONE
  because it lacked Bash. Several standing review agents are defined Read/Grep/Glob-only, so a
  panel seat needing execution must be dispatched on an agent type that *has* those tools.
- **Semantic recall misses; deterministic grep does not.** D-117 — the single fact the whole session
  turned on — was found only by grep.
- **Check the inherited framing against the decision's own words.** The handover framed this as a
  coverage question and I executed that framing well. D-117 says "recovery/**coverage**". Reading
  the decision text I had already quoted, one more time, with the question *"does it ask for
  anything else?"*, would have caught it before the panel did.
- **Freeze the tree before dispatching reviewers.** Fixing a flaw mid-review is worse than fixing it
  after: it invalidates the brief, gives reviewers a moving target, and buys nothing a follow-up
  commit would not.
- **Repairs after a verdict do not overturn the verdict.** Every blocking finding here is now
  repaired, and the panel result still stands at 2 NOT-DONE. Re-adjudication requires a re-run, not
  an assertion that the objections were addressed — otherwise the producer is grading itself again.
- **A cross-platform tree hash must sort the hashes, not the filenames.** Locale collation
  manufactured a false provenance mismatch.

## 12. Cross-Product Coverage

**What this covers.** The **A1 scalar Gaussian 10-group corner** of the profile random-effect-SD
interval: `g = 10`, Gaussian family, ML, `TRUE_BETA = 0.5`, residual `sigma = 0.7`, one mean
formula, `n_per ∈ {4, 10}`, `sd_mu ∈ {0.5, 1.0}`, nominal 95%, all-attempt coverage.

**What this does NOT cover.** It does **not** cover any non-Gaussian family; other providers
(`phylo`, `spatial`, `animal`, `relmat`); random slopes; scale-side (`sigma`) random effects;
bivariate models; group counts other than `g = 10`; REML; AGHQ; other true SD values or residual
scales; other mean structures; bootstrap or Wald intervals; nominal levels other than 95%; and it
does **not** establish nominal-exact coverage — 0.9248 against nominal 0.95 is real
undercoverage, which is why the floor is `g`-tapered. It does **not** authorise candidate
preparation (issue #61 NO-GO), merging PR #959, a `platform-clean` claim, a tag, a GitHub release,
or a CRAN upload. And it does **not** by itself discharge D-117 — that is the owner's decision.
