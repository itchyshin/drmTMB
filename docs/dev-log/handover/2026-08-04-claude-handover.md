# Session Handoff: the Prong B stack — fences opened, two defects surfaced, nothing promoted

**Meta:** 2026-08-04 · from Claude (Claude Code) · to a fresh **Claude** session · context ~85% used.
**Repo:** `drmTMB`, `origin/main = 25768833b`.

---

## Critical Context

Two things, or you will go wrong.

**1. This stack promotes NOTHING.** The capability census is unchanged at **182
`interval_feasible` / 60 `point_fit_recovery`**, and all 14 target cells remain
`point_fit_recovery`. Prong B makes profiles *reachable*; it earns no interval,
coverage, or inference claim. The `196/46` figure is the destination of Prong B
**plus** the interval campaign — not of this stack. If you find yourself about to
move a cell, stop: that needs campaign evidence.

**2. There are three stacked branches and none is merged.** They must merge in
order, spaced apart. `concurrency.cancel-in-progress` is ref-scoped against a
~45-minute check, so two merges inside an hour leave *neither* main run completed
— that already cost three cancelled main checks on 2026-08-03.

---

## What Was Accomplished

- **Prong B Tier 1**: deleted the four profile-fence predicates in `R/profile.R`
  (E1–E4), opening `confint(method = "profile")` for exactly 14 cells; flipped 12
  pinned test call-sites; added the package's first-ever `se = TRUE`
  profile-interval tests; shipped a CI-wired, red-tested fence-integrity guard.
- **Citation durability**: made evidence citations file-anchored and made the
  check reachable in CI.
- **mc-0653 unblocked**: diagnosed its degenerate fixture and measured the design
  that repairs it (below).
- **Repaired a red CI**: the C17/C14 source-blob binding, by re-running the
  compatibility receipt rather than re-stamping it.

---

## Current Working State

- **Working:** all three branches verified at the stack tip (`b9532f90f`):
  `R CMD check --as-cran` **0 errors / 0 warnings / 1 note** (benign
  `New submission`); fence guard 61 enumeration + 34 battery rows, **violations
  = 0**, red-tested; citation guard 37 rows / 7 rejections, **0 violations**;
  `capability_ledger.py --check` OK (30 outputs); **all six** `tools/tests/*.py`
  OK; phylo-interaction 14/14.
- **In progress:** PR **#915**'s check was still `pending` / `UNSTABLE` at
  writing. It was re-triggered after a *cancelled* (not failed) run.
- **Not working / blocked:** `predict()` drops the phylo-interaction random
  effect on the scale axis — real, characterised, deliberately unfixed (below).

---

## Key Decisions & Rationale

1. **No ledger promotion in this stack.** `interval_feasible` claims interval
   existence and truth-bracketing; this earns neither.
2. **Re-prove, never re-stamp.** When editing a file in `C17_C14_SOURCE_FILES`
   broke mc-0568's receipt, the fix was to re-run the runner via its
   `C17_COMPAT_RUN_ID` hook into a **new dated receipt**, preserving the prior
   one. Hand-editing the recorded blob would forge provenance.
3. **The structured-sigma caveat ships at computability, not only at promotion.**
   Those routes become `confint()`-callable the day this merges, so NEWS and
   `?confint.drmTMB` name the documented ML sigma-axis low bias and REML's
   unavailability now. The `claim_boundary` requirement at promotion is a
   **locked owner decision** — carry it, do not revisit it.
4. **Oracle tests pinned to the small design.** Raising mc-0653's fixture to 8×8
   would have grown two objective/gradient oracle tests 16× in covariance
   dimension for no extra mathematical coverage.

---

## Landing State

`handoff_gate.sh` output annotated. **My lane is fully landed.**

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `claude/prong-b-tier1` `d4e5268c5` | y | y | **#915 OPEN, check pending** | **LANDED** (branch); merge OWED |
| `claude/citation-durability` `5e675e0b3` | y | y | none | **LANDED** (branch); PR OWED |
| `claude/mc0653-fixture` `b9532f90f` | y | y | none | **LANDED** (branch); PR OWED |
| primary checkout `claude/handover-freshness-0718`, 88 uncommitted | n | n | — | **NOT THIS LANE'S** — pre-existing from earlier sessions on a branch 669 behind main. Do not claim, commit, or clean it. |
| ~435 unpushed on ~18 other branches (mostly `codex/*`, incl. `codex/lane-b-q1-preflight-admission` 226) | n | n | — | **NOT THIS LANE'S.** Listed by the gate, not owned here. |
| PR **#858** `codex/lane-b-e0-readiness` (draft, 2026-07-27) | — | — | #858 draft | **FOREIGN LANE (codex).** Verified no file overlap. Owner decision. |

**Multi-lane note:** a codex lane is active. Do **not** repoint `AGENTS.md`'s
single rehydrate pointer in a way that orphans it. This handover covers the
Claude lane only.

---

## Next Immediate Steps

Run `tools/lane_preflight.sh`, diff against current `git state`, and classify
every item below **OWED / DONE / RETRACTED / PROTECTED** before acting.

1. **Check PR #915.** If green, merge it. If red, that outranks everything.
2. **Open and merge PRs** for `claude/citation-durability`, then
   `claude/mc0653-fixture`, in that order, **spacing the merges** so their main
   checks do not cancel each other.
3. **The interval campaign** — 14 cells, ~135 profile traces, Totoro, the
   ten-clause evidence contract in
   `scratchpad/2026-08-03-prong-b-scoping-decision.md`. This is what moves
   182 → 196. Promotion also needs `FROZEN_CENSUS_POINT_FIT_RECOVERY = 59 → 45`
   at `tools/capability_ledger.py:218`.
4. **`predict()` on the scale axis** (Blockers).
5. **The durable-citation form** — recommended 2026-07-25, skipped, needed again
   2026-08-03. Do not let a third manual line-number refresh happen.
6. Smaller, still deferred: **B4-CI `SOURCE_COMMIT`** port; **mc-0282's runner
   contract** (**PROTECTED** — deliberately deferred; re-adding it asserts
   provenance and needs its own review).

---

## Blockers / Open Questions

- **D-117 — unanswered, and the only release-gating item.** It makes the
  fixed-seed 10-group profile-SD coverage gate a condition on 0.7.0. This stack
  widened the profile surface by 14 routes and nobody has decided whether that
  gate covers them. **Shinichi's call.** Cross-ref `memory/DECISIONS.md` D-117.
- **`predict(fit, dpar = "sigma", type = "link")` drops the phylo-interaction
  random effect.** `sd(predict − fixed) == 0` exactly, while
  `phylo_mu_contribution()` varies with `sd = 0.42`. Not fixed here — deciding
  which side is right needs its own evidence, and it may affect other providers
  and `fitted()`/`residuals()`. The gate test now **pins current behaviour** with
  a comment naming the expectation it violates, so it fails the moment `predict()`
  is corrected. That is the intended alarm: update it then, do **not** relax it.
- **mc-0653's fixture is repaired but its ledger evidence is not re-scoped.** The
  existing point-fit receipt was produced at 16 pairs; the fixture default is now
  8×8. Reconciling that is a campaign-arc decision with a ledger consequence.

---

## Gotchas & Failed Approaches

- **`capability_ledger.py --check` is NOT the ledger verification.** CI's same
  step also runs six `tools/tests/*.py` files, and the C17/C14 assertion lives in
  one of them. Running only the headline command is why #915 went red on a
  failure that reproduces locally in **0.6 s**.
- **Editing any of the five `C17_C14_SOURCE_FILES` fails the binding closed.**
  Fix by re-running via `C17_COMPAT_RUN_ID` into a new dated receipt. Never
  hand-edit the blob; never overwrite the prior receipt.
- **Starved fixtures make assertions pass vacuously.** mc-0653's gate test
  asserted the right thing for months and passed only because its random effect
  had collapsed to `4.95e-05`, making both sides equal `fixed_sigma`. Before
  trusting an RE-sensitive equality, check `sd(contribution) > 0`.
- **A fit can report `convergence = 0, pdHess = TRUE` with the variance
  component pinned to the boundary.** `pdHess` is a want, not a gate.
- **`/private/tmp` worktrees get cleaned up mid-session.** All three of mine
  vanished; the work survived only because it was committed and pushed. A failed
  `cd` then silently runs commands in the stale primary checkout and produces
  authoritative-looking nonsense — verify your working directory before believing
  a result.
- **Five times this session something read green for the wrong reason** (a guard
  blind to its own target; a `^Failure` grep matching a string testthat never
  emits; `--check` standing in for the CI step; a vacuous `expect_equal`; a `cd`
  into a deleted directory). Each was caught by something other than the check
  itself. **Before trusting a green, ask what it would look like if the thing
  were broken.**

---

## How to Resume

**Environment.** Working directory: a clean worktree off the branch you are
merging — the authoring worktrees are gone, so create one:
`git worktree add /private/tmp/<name> claude/mc0653-fixture`. Toolchain: `python3`
and `Rscript` on PATH. Set `NOT_CRAN=true` for the full suite. Run R as
`R_PROFILE_USER=/dev/null Rscript --no-init-file` (the `.Rprofile` R-4.5 lib
segfaults R 4.6). You do **not** inherit this session's terminal, credentials, or
chat.

**Safe verification command** (the exact CI validation step):

```bash
python3 tools/capability_ledger.py --check && for t in test_capability_ledger test_arc1_profile_reconcilers test_b3_q6_target_promotion test_b4_ci_guard test_b4_ci_c1 test_profile_truth_gate; do python3 -m unittest tools/tests/$t.py; done && Rscript --no-init-file tools/emit-profile-truth-manifest.R --check && Rscript --no-init-file tools/check-capability-runtime.R && Rscript --no-init-file tools/check-profile-fence-integrity.R && Rscript --no-init-file tools/check-evidence-citations.R
```

**Do not stage:** anything in the primary checkout's 88 uncommitted files; any
`codex/*` branch work; `tools/profile-truth-manifest.tsv.bak` if it reappears.

**Read in this order:** this file → `AGENTS.md` →
`docs/dev-log/handover/2026-08-04-prong-b-stack-handover.md` (the stack detail) →
`docs/dev-log/evidence/2026-08-04-mc0653-fixture-degeneracy-diagnosis.md` →
`scratchpad/2026-08-03-prong-b-scoping-decision.md` (the campaign's contract).

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-04-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
