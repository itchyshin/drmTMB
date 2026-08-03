# Session Handoff: drmTMB interval-feasibility programme (Arcs 2–6 close)

Meta: 2026-08-03 · from Claude to a fresh Claude session · implementation handoff

You are Claude, continuing the drmTMB interval-feasibility programme. Read `AGENTS.md`, this handover,
and `scratchpad/2026-08-03-prong-b-scoping-decision.md` before acting. **You inherit no authority from
the authoring chat.** Classify every item below as `OWED`, `DONE`, `RETRACTED`, or `PROTECTED` against
current repository and GitHub state.

## Critical Context

Canonical `main` reads **172 interval_feasible / 70 point_fit_recovery** across 699 model-surface cells
(from 161/77 at the start of 2026-08-02). Verified directly against `origin/main`, not projected.

Merged over the two days: #869, #891, #893 (mesh/SPDE), #895, #897 (Arc 2, six cells), #900 (Arc 3, six
cells), #904 (`mc-0417`), #905 (`mc-0207` split **and demotion**).

**Fifteen cells promoted, four honest withholdings.** The withholdings matter more than the promotions.

## Next Immediate Steps

### 1. Fix the reconciler blind spot — before any more promotions

**This outranks every remaining cell.** `tools/arc2_profile_reconcile.py::reconcile()` has **no truth
field**, so it validates interval *shape* and is structurally blind to interval *location*. Three
promotions today reconciled **5/5 PASS** while containing an interval that missed the true value, and in
one case the build agent **printed the correct endpoints and then wrote "YES"**.

| Cell | Receipt | Truth | Failure |
|---|---|---|---|
| `mc-0423` | `[0.137, 0.479]` | 0.55 | truth above the upper endpoint |
| `mc-0409` | `[0.610, 0.902]` | 0.6 | truth below the lower endpoint |
| `mc-0292` | `[0.404, 0.694]` | 0.7 | upper endpoint 0.006 short of truth |

Making `true_value` and `brackets_truth` recorded receipt fields — **written by the runner, checked by
the reconciler** — turns a human-memory step into a machine gate. **Until that lands, this recurs.**

### 2. Prong B, Tier 1 — 14 cells, ~30 min compute

Fully scoped in `scratchpad/2026-08-03-prong-b-scoping-decision.md`: exact `R/profile.R` edits with line
numbers, per-cell evidence contract, and the mandatory pre-merge gate. It is the **first `R/` change of
the programme**, so it wants a fresh session with room for `R CMD check`, NEWS and docs.

**The gate matters:** the edits delete **predicates, not cells**, so routes with no ledger cell and no
evidence can silently become profile-ready. **Diff `profile_targets()` pre- and post-edit; anything
flipping TRUE outside the 14 gets re-fenced.**

Tier 1 cells: `mc-0568`, `mc-0576` (sigma ordinary) · `mc-0593`–`mc-0597` (sigma structured) ·
`mc-0418`, `mc-0436`, `mc-0446`, `mc-0450`, `mc-0454` (count mu labelled q2) · `mc-0425`, `mc-0653`
(count sigma phylo_interaction).

### 3. The `zoi` pilot — 11 cells, short

Their failures look like **fixture problems, not mechanism problems**. Rides along with the Prong B lane.
(`zoi` failed two different ways at two sample sizes: at n=288 the NLL was flat to
`log_sd_zoi = -1.5e22`; at n=1600 it profiled cleanly but with 46.4% point-fit error and truth *below*
the lower bound.)

### 4. A decision from Shinichi: q12

**Sixteen cells sitting behind a policy fence, not a capability limit** — and `mc-0124`, a q6 sibling, is
already `interval_feasible`. Shinichi was right to push on this; if he lifts the exclusion they become
candidates on the same footing as everything else. **That is his call, not the agent's.**

### 5. One cheap experiment worth doing early

Two independent lanes disagreed on whether labelled `provider(1 | p | group)` and the unlabelled
auto-linked spelling are the same fitted model — which decides whether `mc-0291`/`mc-0292` are **one
ledger block or two**. **A single toy fit comparing `profile_targets()` on both spellings settles it.**

## Do NOT

- **Reopen `coi` (5 cells: `mc-0570`, `mc-0578`, `mc-0613`, `mc-0614`, `mc-0617`).** Shinichi's own
  2026-08-01 disposition says the receipt stays `BLOCKED_POINT_RECOVERY` and is not rewritten.
- **Re-run the four diagnosed STOPs blind.** `mc-0289`/`mc-0292` failed in **two independent lanes on the
  same provider × dpar**, so spatial-on-sigma is a **real fragility**, not a fixture accident.
- **Trust the Arc 0 manifest's remaining verdicts.** It is now defective in **four distinct ways** —
  signal-free fixtures; a cell id absent from the fixture registry; a named coefficient absent from the
  cited model; a cited fixture file (`tools/b2-q6-q12-admission-contracts.R`) that does not exist in the
  tree. **That insight produced twelve of today's fifteen promotions.**

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `main @ 0c0cf2726` | yes | yes | #905 merged | LANDED |
| `claude/arc2-interval-feasibility` | yes | yes | #897 merged | LANDED |
| `claude/arc3-fixture-construction` | yes | yes | #900 merged | LANDED |
| `claude/arc4-mc0417-bind` | yes | yes | #904 merged | LANDED |
| `claude/arc4b-taxonomy` | yes | yes | #905 merged | LANDED |
| `claude/arc5-final-three @ 8cf8841fe` | yes | yes | **#907 OPEN, CONFLICTING** | **CARRIED-OVER** — was CI-green; #905 conflicted it. Rebase onto current `main`, re-run CI, merge. |
| `claude/arc6-gaussian-nine @ 0a7d3172c` | yes | yes | **#908 OPEN, CONFLICTING** | **CARRIED-OVER** — same cause. Nine cells; `mc-0292` deliberately withheld — **do not re-add it**. |
| `#858` Lane B E0 | foreign | foreign | #858 open, draft, **red** | CARRIED-OVER — other lane |
| `claude/c18-structured-atoms-plan` | foreign | foreign | none | CARRIED-OVER — needs rebase over the Arc 2–6 guard changes |
| ~12 historical `codex/*` branches with unpushed commits | mixed | no | — | CARRIED-OVER — other lanes' estate; **never clean, force-push, or delete** |

**REPORT TO SHINICHI, do not remove:** a stale `.git/index.lock` (0 bytes, 2026-08-03 08:12) exists in
the primary checkout. The harness blocks `.git` deletions and the handoff gate flags it. It needs a human.

## The contract as it now stands

Tightened twice during the programme, both times because something got through:

- Endpoints from **ONE** `stats::profile()` call — never separate `profile()`/`confint()`.
- A **predeclared point-fit recovery gate** (mean relative error ≤ 0.35) runs **before** any profile.
- **Five seeds** minimum; the gate and the campaign must **share one seed family**. (`mc-0423`'s gate ran
  on seeds 423/523/623 while its campaign ran 2026080301-03 — its fragile seed was never gated at all.)
- **Per-seed truth-bracketing.** Any single seed with >0.35 relative error *or* an interval excluding the
  true value blocks promotion **even if the mean passes**.
- **Never profile a variance component whose true value is zero** — that hits the `[0, ∞)` boundary by
  construction and proves nothing about the software.

## Known DGP failure mechanisms — check before inventing new ones

1. **Ill-conditioned structure.** `ape::rcoal()` coalescent trees hit κ = 98,563, and **enlarging
   `n_tip` made it worse** (up to 540,883). Grafen branch lengths: κ = 183.
2. **Finite-sample correlation between independently drawn components** — |cor| 0.457 at `n_id`=40
   created an alternate local optimum mid-profile-sweep. `n_id` → 80 gave 0.135.
3. **NB2 dispersion/SD confounding** — `cor(sigma_hat, sd_hat) = −0.74`.
4. **Plain small-group-count recovery failure** — raise group counts, don't change structure.
5. **Signal-free fixture** — the manifest prescribed mean-only DGPs for scale-side targets.

## Open defects

- `tests/testthat/test-reml-ordinary-sigma.R:3-4,105-108` — stale comments claiming the cell "stays
  gated"/"stays rejected", contradicted by source since `1b3e852bb` (July).
- Receipt `source_sha` vs ledger `ARC*_SOURCE_SHA` diverge; flagged independently by three agents.
  Nothing is lost (raw receipts keep the true SHA) but the convention should be reconciled.

## Claude Environment and Routing

Primary checkout: `/Users/z3437171/Dropbox/Github Local/drmTMB` (use a fresh worktree off `origin/main`;
do not work in the primary checkout).

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "profile")'
python3 -B tools/capability_ledger.py --check
python3 -m unittest tools.tests.test_capability_ledger tools.tests.test_arc1_profile_reconcilers
```

- `capability_ledger.py --write` emits **30 outputs and not all live under `docs/dev-log/dashboard/`** —
  notably `vignettes/includes/capability-ledger-family-map.md`. **Stage whatever `--write` touches, never
  a fixed directory list.** That broke CI once.
- Campaign drivers must use `^` as field delimiter, **never `|`** — random-effect targets embed a literal
  `|`, which silently shifts every field. It killed three runs.
- Totoro: `R CMD INSTALL` **ignores `R_LIBS_USER`**; pass `-l <lib>`. drmTMB persists in `~/R/lib`;
  recreating the workspace is one `git worktree add` plus a few `scp`s. Connect only through the existing
  ControlMaster socket (`ls ~/.ssh/cm-*totoro*`) — a fresh login triggers Duo.
- Structured markers need their tree/matrix as a **bare local symbol**.
- After every batch, **adversarially flip one extra frozen cell and confirm `--check` fails.**
- Never `git add -A`; explicit paths only. Never stage the primary checkout or foreign worktrees.

## How to Resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-03-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
