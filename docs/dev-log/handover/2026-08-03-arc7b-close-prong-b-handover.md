# Handover — Arc 7b closed, Prong B is next

**To:** Claude (fresh session). **From:** Claude, 2026-08-03.
**Repo state at writing:** `origin/main = b1b5ade3d`.

This is the **state** record. The **execution** brief for the next arc is
`docs/dev-log/handover/2026-08-03-prong-b-next-lane-brief.md`, refreshed in this
session and now accurate — read both, this one first.

Do not confuse this with `docs/dev-log/handover/2026-08-03-claude-handover.md`
(the *previous* lane's handover, which briefed Arc 7b and is now spent) or with
`2026-08-03-arc7b-truth-gate-brief.md` (the Arc 7b execution brief, also spent).

## Critical Context

Arc 7b is **merged** (PR #912, `b1b5ade3d`). The interval-feasibility programme
now has a machine-enforced truth gate: promotions are checked for interval
LOCATION, not just SHAPE. `model_surface interval_feasible` moved **184 → 182**
on `main` — two claims were withdrawn because their own retained intervals
excluded the true value. That is the gate working.

The single most important thing for the next lane: **the Prong B briefing docs
asserted three things that Arc 7b made false**, and they have been corrected in
place with dated `(CORRECTED 2026-08-03, Arc 7b: ...)` markers. If you find a
copy of those docs elsewhere (a stale worktree, an old branch), prefer `main`.

## What Was Accomplished

- `tools/profile_truth_gate.py` — the gate. Rule: a cell FAILS if any retained
  seed misses truth by more than 5% of scale, OR if more than one seed misses at
  any magnitude. Fails closed on missing/blank/unparseable/non-finite truth.
- `tools/emit-profile-truth-manifest.R` + `tools/profile-truth-manifest.tsv` —
  truth **derived** by sourcing the runner's own `cell_registry` and calling each
  fixture builder. 30 rows. `--check` mode exits 2 on drift.
- `tools/arc2_profile_reconcile.py` — all 26 contracts pin
  `(information_rung, seeds)`; the gate is called inside `reconcile()`; `--seeds`
  can no longer narrow the denominator.
- `tools/tests/test_profile_truth_gate.py` — 24 tests, wired into
  `.github/workflows/R-CMD-check.yaml` **in the same change** (the pin-drift
  lesson). CI runs 6 of 9 `tools/tests/` files.
- Demotions: `mc-0424` (seed 2026080301, [0.2567, 0.5156] excludes 0.55 by 6.3%)
  and `mc-0260m` (seed 2026080233, [0.2335, 0.4232] excludes 0.20 by 16.8%),
  both `interval_feasible → point_fit_recovery`, point evidence retained.
- `docs/dev-log/after-task/2026-08-03-nbinom2-structured-sigma-family-low-bias.md`
  — the family-level triage item, reframed against prior work (below).
- `docs/dev-log/plan-actual/2026-08-03-arc7b-truth-gate.md` — Melissa's reconcile.

## Key Decisions & Rationale

1. **Gate rule = magnitude AND count, not any-miss.** A 95% interval is supposed
   to miss ~5% of the time; with 3–5 seeds an any-miss rule demotes correct
   cells. Owner-approved.
2. **Cohorts pinned by `(information_rung, seeds)`, not seeds alone.** Load
   bearing: `mc-0409`'s superseded `each8` and repaired `each24` families reuse
   the *same seed numbers*, so a seed-only pin readmits the cohort the repair
   replaced.
3. **Prong B proceeds with all 14 cells, WITH a required caveat** (owner
   decision, this session). Every structured-sigma cell's `claim_boundary` must
   name the documented ML sigma-axis low bias and state that REML is unavailable
   for its family. `interval_feasible` claims interval existence and
   truth-bracketing; the point-estimate bias is a separate, disclosed fact.
4. **The low bias is NOT an open mystery — reuse, don't re-derive.** A brain
   sweep found it already measured (2026-07-06): the sigma-axis RE SD is biased
   low under ML, ML→REML bias g8 −0.092→−0.029, g16 −0.041→−0.008. The fix,
   native scale-side REML, **is on main** (`b9446fd7`) and covers phylo, spatial,
   animal and relmat (`R/drmTMB.R:2276-2291`, 400/400 debiasing, coverage
   ≥0.926). What blocks it here is the **family** gate at `R/drmTMB.R:2221`,
   which admits `gaussian`/`binomial` only. Do not spend compute rediscovering
   this.

## Landing State

`tools/handoff_gate.sh` output, annotated:

| item | state | note |
| --- | --- | --- |
| Arc 7b (6 commits) | **LANDED** | merged `b1b5ade3d` via PR #912; CI green on `ea5a11b0` (44m26s) |
| this handover | **LANDED** on merge | branch `claude/prong-b-handover` |
| `tools/profile-truth-manifest.tsv.bak` | **CARRIED-OVER** | scratch artifact, byte-identical to the live manifest. Harness blocks `rm`. **Needs a human `rm`. Do not stage it.** |
| 437 unpushed on ~20 other branches | **NOT THIS LANE'S** | pre-existing, other lanes. Listed by the gate, not owned here. Do not land them. |
| PR #858 (draft, `codex/lane-b-e0-readiness`) | **NOT THIS LANE'S** | 419 ahead / 56 behind, opened 2026-07-27. Owner decision. |
| `main` post-merge CI (`b1b5ade3`) | **PENDING AT WRITING** | run `30859538708`. **Verify before trusting `main` as checked** — the three commits before this one were all cancelled by concurrency, so the last *completed* main check before Arc 7b was `d82d2b53` (Arc 5). |
| stale `.git/index.lock` in the primary checkout | **CARRIED-OVER** | 0 bytes. Needs a human `rm`. |

## Next Immediate Steps

Classify each `OWED`/`DONE`/`RETRACTED`/`PROTECTED` against current git state first.

1. **Confirm `main`'s CI conclusion** for `b1b5ade3` (run `30859538708`). One
   command. If red, that outranks everything below.
2. **Prong B Tier 1 — the R/ change.** `R/profile.R` edits E1–E4, per
   `scratchpad/2026-08-03-prong-b-scoping-decision.md` (turnkey, line-level).
   Unfences `confint(method="profile")` for 14 cells. **Ship the code change and
   its tests as one arc; the 135-trace Totoro campaign is a separate arc.**
   Target: 182/60 → **196/46**.
3. **Apply decision 3 above** when those cells' `claim_boundary` text is written.

Smaller, independent, each ~20–40 min:

4. **Recover `mc-0282`'s runner contract.** Commit `0a7d3172c` added a complete
   `"mc-0282" = list(...)` entry; it is an ancestor of HEAD but did not survive
   the Arc 6 merge `324aed7c1`. Re-adding it empties the `UNGATED` set so all 31
   cells are gated. Deliberately deferred: re-adding a runner contract asserts
   *this is the code that produced those receipts*, which needs its own review.
5. **B4-CI `SOURCE_COMMIT`** (owner prefers the port). `574c1108e` is unreachable
   from CI because it lives only on the local branch
   `codex/lane-b-q1-preflight-admission` — **which has 226 unpushed commits**, so
   "publish the branch" is literally possible if preferred. Otherwise port c1's
   no-git `check_current()` pattern to c2/c3/c4 and wire them in.

## Blockers / Open Questions

- **Owner decision — the gate's tolerance units.** It is `0.05 × |truth|`.
  Expressed in interval half-widths that is 0.05–0.34, a 6.8× spread in
  strictness driven by each cell's accidental ratio of `|truth|` to precision. An
  identical absolute miss is FAIL at truth 0.2 and PASS at truth 0.7. Scaling by
  half-width fixes it in one line — but changes which cells pass, and therefore
  the published census. **Not a refactor. Owner's call.**
- **Owner decision — q12**, 16 cells behind a policy fence, not a capability
  limit. `mc-0124`, a q6 sibling, is already `interval_feasible`.
- **The 89 parked parity rationales** still assert no interval campaign while
  sitting at `interval_feasible` or above. Repair or delete the clause.

## Gotchas & Failed Approaches

- **The installed drmTMB is stale** (built 2026-07-27). Local `devtools::test()`
  / `test_dir()` runs produce **phantom failures** — internal functions like
  `drm_profile_trace_object` exist in `R/` but not in the installed namespace.
  Reinstall from source, or trust CI. This cost real time in this session.
- **`library(drmTMB)` does not expose internals.** Run tests the way `R CMD
  check` does (`tests/testthat.R` → `test_check`), not `test_file()` with
  `library()`, or healthy files read as all-errors.
- **CI concurrency cancels in-flight runs.** `cancel-in-progress: true` on a
  ref-scoped group + a ~43-minute check means merging two PRs inside an hour
  leaves *neither* main run completed. Space merges out, or accept that main goes
  unverified. This is why main had no completed check between Arc 5 and Arc 7b.
- **`git log -- <file>` hides entries that died in a merge.** This is how
  `mc-0282`'s contract was wrongly reported as "never committed". Use
  `git log --all -S'<string>'` when asking whether something ever existed.
- **A guard that cannot fail is not a guard.** Three times this session the
  *check* was broken rather than the thing checked. Red-test before trusting a
  green: mutate the thing the guard protects and confirm the guard fires.

## How to Resume

Working directory: any clean worktree off `origin/main`. Toolchain: `python3`
and `Rscript` (both on PATH); `NOT_CRAN=true` for the full test suite.

Safe verification command (the exact CI sequence):

```bash
python3 tools/capability_ledger.py --check && for t in test_capability_ledger test_arc1_profile_reconcilers test_b3_q6_target_promotion test_b4_ci_guard test_b4_ci_c1 test_profile_truth_gate; do python3 -m unittest tools/tests/$t.py; done && Rscript --no-init-file tools/emit-profile-truth-manifest.R --check && Rscript --no-init-file tools/check-capability-runtime.R
```

Do not stage: `tools/profile-truth-manifest.tsv.bak`.

Resume prompt:

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-03-arc7b-close-prong-b-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
