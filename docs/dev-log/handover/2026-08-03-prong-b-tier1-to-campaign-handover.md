# Handover — Prong B Tier 1 complete (uncommitted); the 135-trace Totoro campaign is next

**To:** the next session (Claude, Codex, or Cursor). **From:** Rose (systems
auditor), 2026-08-03.
**Repo state at writing:** worktree `/private/tmp/drmtmb-prongb`, branch
`claude/prong-b-tier1`, based on `origin/main = 25768833b`. Nothing in this
arc is committed, staged, or pushed.

This is the **state** record for Prong B Tier 1's close. The **execution**
brief for what comes next — the campaign — is
`scratchpad/2026-08-03-prong-b-scoping-decision.md` (section 4, "THE
CAMPAIGN", onward; also sections 5-6 for risks and hard prohibitions),
written before this arc started and unchanged since. Read both, this one
first, for what actually happened and what state things are in now.

Do not confuse this with `docs/dev-log/handover/2026-08-03-arc7b-close-prong-b-handover.md`
(the PREVIOUS arc's handover, which briefed Prong B Tier 1 and is now spent
— this document supersedes its "Next Immediate Steps" item 2) or
`docs/dev-log/handover/2026-08-03-prong-b-next-lane-brief.md` (also spent).

## Critical Context

Prong B Tier 1 is **complete and verified, but uncommitted**. `R/profile.R`'s
four boolean fence predicates (E1-E4) are deleted; `confint(fit, method =
"profile")` is reachable for exactly the 14 named cells; the change is
guarded by a new CI-wired fence-integrity test; test call-sites are flipped;
the package's first `se = TRUE` profile-interval tests exist. It **promotes
nothing** — the `model_surface` census is unchanged at 182
`interval_feasible` / 60 `point_fit_recovery` (frozen 59). Full detail,
every verified number, and what did not go smoothly:
`docs/dev-log/after-task/2026-08-03-prong-b-tier1-profile-fences.md` (this
arc's after-task report) and the matching entry at the top of
`docs/dev-log/check-log.md`.

**The single most important thing for the next lane:** this work has not
been landed. Nothing is committed on `claude/prong-b-tier1`, nothing is
staged, nothing is pushed. Before doing anything else, decide whether to
commit/PR this work (it is verified and ready) or continue it further in
place — do not assume a fresh session inherits it silently just because the
worktree still exists on disk; a worktree at `/private/tmp/...` is not a
durable location.

## What Was Accomplished

- `R/profile.R` E1-E4: three fence predicates deleted outright
  (`count_labelled_q2_profile_restricted()`,
  `count_sigma_interaction_profile_restricted()`,
  `zero_one_beta_sigma_q1_profile_restricted()`, with their status/note
  branches), one narrowed (`count_point_fit_only_profile_restricted()`'s
  `zero_one_beta` `dpar` set drops `"sigma"`). `zi_nbinom2_sigma_q1_profile_restricted()`
  deliberately untouched (governs `zi_nbinom2` ordinary `sigma` q1, not one
  of the 14). The now-unreachable final branch of
  `count_point_fit_only_profile_restricted_status()` is a `cli_abort()`, not
  a silent fall-through.
- `tools/check-profile-fence-integrity.R` (+ `profile-fence-fixtures.R`,
  `profile-fence-worker.R`): a CI-wired guard, process-isolated per library,
  checking a 61-row predicate enumeration and a 24-route/34-check fitted
  battery against a hard-coded intended-outcome table. Wired into
  `.github/workflows/R-CMD-check.yaml` in the same change (the 2026-08-03
  b4-ci pin-drift lesson: ship the guard and its CI wiring together, not
  sequentially).
- 12 flipped test call-sites (3 files) + 5 new tests (4 `se = TRUE`
  profile-interval smoke tests, one per opened group, plus 1 internal
  `cli_abort()`-reachability test) + 1 pure-hygiene edit (4th file).
- Roxygen/vignette/`NEWS.md` updated with the structured-`sigma` ML
  low-bias caveat and the mc-0653 fixture-degeneracy disclosure.
- Six evidence-citation anchors re-pointed after the edit's own line-shift
  broke them; two stale "not profile-ready" user-facing claims corrected; a
  guard defect (silently discarded caller `R_LIBS_USER`) fixed; 29 fragile
  test-file line-number pins inside the guard's own fixture file replaced
  with file-name + cell-id citations.
- `R CMD check --as-cran`: 0 ERRORS / 0 WARNINGS / 1 NOTE on a completed run.
  `python3 tools/capability_ledger.py --check` and
  `Rscript --no-init-file tools/check-profile-fence-integrity.R` both
  re-verified live at closeout: OK / violations=0. Full numbers in the
  after-task report.

## Key Decisions & Rationale (carried forward, locked — do not re-derive)

1. **Every structured-`sigma` cell's eventual `claim_boundary` text must
   name the documented ML `sigma`-axis low bias and state that REML is
   unavailable for its family** (`drm_validate_reml_spec()` admits only
   Gaussian and binomial models). This is an **Arc 7b owner decision**,
   restated here so it is not lost a second time: `interval_feasible` is a
   claim about interval existence and truth-bracketing (what the campaign's
   truth gate checks), not about point-estimate bias — but the bias must be
   disclosed in the cell's own text regardless. Applies to mc-0593..0597 and
   mc-0425/mc-0653 (7 of the 14). Not yet written anywhere: Tier 1 changes no
   `claim_boundary` text, because it promotes nothing. **This is the first
   thing to write once a cell's campaign evidence supports promotion** — do
   not promote a structured-`sigma` cell without it.
2. **The census/ledger promotion itself is explicitly out of scope for the
   campaign's own compute step** — per the scoping memo's turnkey handoff,
   promotion follows a *human/agent review* of all ~135 traces against the
   ten-clause evidence contract (scoping memo section 4), not an automated
   pass/fail from the campaign runner. "Compute is not the constraint.
   Review is."
3. **Do not open any `coi` fence** (mc-0570, mc-0578, mc-0613, mc-0614,
   mc-0617) and **do not open the Tier-2 fences** (`zoi`; structured `mu`)
   "while you're in there." Both are deliberate, owner-approved exclusions
   from this programme, not oversights — see scoping memo sections 1 and 6
   for the full reasoning (a 2026-08-01 disposition that explicitly licenses
   `coi` for point-fit only, and a self-contradictory Tier-2 `zoi` spike).
4. **This campaign runs on Totoro, not GitHub Actions**, per repo-wide
   guardrail D-50: never run simulation/coverage/recovery/power campaigns on
   GitHub Actions, and never store their outputs as Actions artifacts.
   Totoro is ≤100 cores by policy; the scoping memo's own estimate is ≤30
   min wall-clock for the full 135-trace slate, well inside that budget.

## Landing State

| item | state | note |
| --- | --- | --- |
| Prong B Tier 1 code + tests + guard + docs (18 tracked-file diffs + 3 new `tools/` files) | **COMPLETE, VERIFIED, UNCOMMITTED** | worktree `/private/tmp/drmtmb-prongb`, branch `claude/prong-b-tier1`; not staged, not committed, not pushed |
| this after-task report + check-log entry + this handover | **WRITTEN, UNCOMMITTED** | same worktree |
| second `R CMD check --as-cran` confirming run | **PENDING AT WRITING** | `/private/tmp/prongb-ascran-final.log`; still inside the ~17-18 minute `testthat.R` step as of the last check before this handover was written; had not produced a summary |
| GitHub issue for the citation-rot / CI-invisibility finding | **NOT FILED / UNCONFIRMED** | searched (`gh issue list`, several term combinations, and issues created 2026-08-03..2026-08-04); no match found. Either it exists under different wording, is tracked only outside GitHub, or remains outstanding — after-task report section 10 |
| `claim_boundary` text for the 7 structured-`sigma` cells | **OWED, deliberately deferred** | decision 1 above; campaign-arc work, not Tier 1 |
| `tools/handoff_gate.sh` | **NOT FOUND** in this worktree, in `~/shinichi-brain`, or in `~/.claude` | referenced by the standing cross-tool handoff workflow and used with real output in the Arc 7b handover's own Landing State table; could not be run for this closeout. Flagging rather than silently skipping it |
| the 135-trace Totoro campaign | **NOT STARTED** | this is the next arc |
| `origin/main` post-Arc-7b-merge CI | not re-checked in this task | see the Arc 7b handover's own note that CI concurrency can leave `main` unverified after back-to-back merges; re-check before assuming `main` is green |

## Next Immediate Steps

1. **Decide whether to land Tier 1** (commit/PR to `main`) before or in
   parallel with starting the campaign. It is independently verified
   (after-task report section 3) and does not depend on the campaign to be
   correct on its own terms — but it has not been reviewed by a human, and
   nothing here overrides that.
2. **Confirm the second `R CMD check --as-cran` run finished clean.** It was
   mid-`testthat.R` at the time this handover was written; re-check
   `/private/tmp/prongb-ascran-final.log` for a `FINAL CHECK SUMMARY` (or
   re-run) before treating Tier 1 as check-clean on the fully settled tree.
3. **Run the campaign** per scoping-memo section 4: 14 cells x 5 seeds (8
   for the 3 `cor:` targets) ≈ 135 profile traces, one `se = TRUE` fit per
   `(cell, seed)` serving both the point-fit gate and the profile base, on
   Totoro, ≤100 cores, expect ≤30 min wall-clock. Apply the ten-clause
   evidence contract (scoping memo section 4) per cell; any single clause
   failure blocks that cell, and 4/5 truth-bracketing is a block, not an
   80% pass. The Fisher location review is a contract clause, not a
   courtesy — it has already caught two mechanically-passing, wrong-location
   cases in this programme (`mc-0423`, `mc-0409`; see
   `scratchpad/2026-08-03-interval-programme-handover.md`).
4. **Repair mc-0653's fixture** before it can be evaluated for promotion:
   its ML `sigma` estimate collapses to `4.95e-05` against a generating
   value of `0.60` (after-task report, Known Limitations). Do this before
   spending campaign seeds on it, not after a failed campaign discovers it
   again.
5. **Write the `claim_boundary` text** for the 7 structured-`sigma` cells
   per decision 1, once a cell's campaign evidence supports promotion.
6. **Change `FROZEN_CENSUS_POINT_FIT_RECOVERY = 59 -> 45`** at
   `tools/capability_ledger.py:218` only at the point of actual promotion,
   together with the `cells.tsv`/`evidence.tsv`/census edits — not before.
   Target after a fully successful campaign: 182/60 -> 196/46 whole-model
   (196/45 frozen).
7. **File or locate the GitHub issue** for the citation-rot / CI-invisibility
   finding (after-task report section 10) — not done in Tier 1, not
   confirmed to exist elsewhere.

## Blockers / Open Questions

- **Owner decision — land Tier 1 now or hold it until the campaign lands
  too?** Not this report's call. Both are defensible: Tier 1 is independently
  correct and verified, but shipping a profile-eligibility change with no
  interval evidence behind 7 of its 14 cells for an unknown period is a
  choice the repo owner should make explicitly, not one a closeout report
  should default.
- **`tools/handoff_gate.sh` is missing from this worktree.** If it is a
  deliberately local/untracked tool that lives only in a "primary checkout"
  distinct from throwaway worktrees like this one (the Arc 7b handover's own
  Landing State table refers to "the primary checkout" as a separate thing
  from the worktree it was written in), the next session should run it from
  wherever that primary checkout is, not skip it because this worktree lacks
  it.
- **The durable-citation-form recommendation from 2026-07-25 is now twice
  unactioned.** After-task report sections 6-7 document a second drift event
  in the same file nine days after the first repair explicitly asked for a
  sturdier citation mechanism. Whether to build that mechanism now, or
  accept a third repair is likely, is an open process decision, not
  something this handover resolves.

## Gotchas & Failed Approaches

- **The installed `drmTMB` can be stale.** This arc worked around it by
  building two dedicated libraries once (`/private/tmp/drmtmb-baseline-lib`,
  `/private/tmp/drmtmb-prongb-lib`) and never rebuilding them mid-task; every
  guard/battery/collateral run loaded one of those two explicitly rather
  than trusting whatever was on the default library path. Keep doing this
  for the campaign rather than re-installing per seed.
- **`R_LIBS_USER=` (empty) is not the same as "inherit the caller's
  library."** R's `Renviron` substitutes R's own default when the variable
  is empty, not unset — a subprocess launched with an explicitly empty
  `R_LIBS_USER` silently loses a non-default library. Verified and fixed in
  the fence-integrity guard (after-task report section 6, defect 3); if the
  campaign runner spawns its own subprocesses per seed, check this
  explicitly rather than assuming "it worked in CI" generalizes (it worked
  in CI only because of an unrelated coincidence — see the same section).
- **Citations by absolute line number rot on the very next unrelated edit to
  the cited file**, including the editor's own concurrent edits within the
  same commit. Prefer function/test names and file names over `:LINE` where
  the cited file is still being actively edited; this report deliberately
  avoids pinning fragile `R/profile.R` line numbers for exactly this reason.
- **Concurrent multi-worktree collaboration is fragile but was not
  destructive here.** This arc ran across at least three worktrees
  (`/private/tmp/drmtmb-prongb`, `/private/tmp/drmtmb-s3`) plus prebuilt
  library directories; one contributor (S2's guard report) had to actively
  investigate unexplained file changes mid-task to rule out its own tooling
  as the cause, rather than assuming they were benign. Do the same if
  anything changes underneath the campaign runner unexpectedly.
- **`git log -- <file>` hides entries that died in a merge** (a lesson
  carried from the Arc 7b handover, still applicable): use
  `git log --all -S'<string>'` when asking whether something ever existed,
  not plain `git log -- <file>`.

## How to Resume

Working directory: `/private/tmp/drmtmb-prongb` (this worktree) if continuing
in place, or a fresh worktree off `claude/prong-b-tier1` / `origin/main`
depending on the landing decision above. Toolchain: `python3` and `Rscript`
on PATH; `NOT_CRAN=true` for the full test suite.

Safe verification command for Tier 1's current state (re-run what this
report re-ran):

```bash
python3 tools/capability_ledger.py --check && Rscript --no-init-file tools/check-profile-fence-integrity.R
```

Do not run the campaign on GitHub Actions, and do not store its outputs as
Actions artifacts (D-50). Do not open any `coi` or Tier-2 fence "while
you're in there" (Key Decisions, item 3).

Resume prompt:

```text
Read AGENTS.md, scratchpad/2026-08-03-prong-b-scoping-decision.md (section 4
onward), docs/dev-log/after-task/2026-08-03-prong-b-tier1-profile-fences.md,
and this handover. Reconcile the Landing State table with the current git
state (has Tier 1 been committed/merged since this was written?), then
build and run the campaign per the scoping memo's turnkey handoff steps 3-6
on Totoro, applying the ten-clause evidence contract per cell.
```
