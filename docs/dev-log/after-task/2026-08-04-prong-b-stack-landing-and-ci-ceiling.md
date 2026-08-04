# After-task — landing the Prong B stack, and an evidence-backed CI ceiling

**Date:** 2026-08-04 · **Platform:** Claude (Claude Code), solo ·
**Lane:** drmTMB Prong B stack + CI ceiling ·
**Foreign lane:** codex, draft PR #858 — verified no file overlap, untouched.

## 1. Goal

Continue only the OWED Next Immediate Steps of
`docs/dev-log/handover/2026-08-04-claude-handover.md`: land the three stacked
Prong B branches on `main` in order, spaced so their main checks do not cancel
each other, then set an honest `timeout-minutes` from measured runs. Promote
nothing.

## 2. Outcome

`main` = `71ce9e544`. All three branches merged, in order:

| PR | Branch | Merge commit |
| --- | --- | --- |
| #915 | `claude/prong-b-tier1` | `12e94657f` |
| #916 | `claude/citation-durability` | `c976e7316` |
| #917 | `claude/mc0653-fixture` | `71ce9e544` |

**Capability census unchanged: 182 `interval_feasible` / 60
`point_fit_recovery`**, verified on merged `main` after every one of the three
merges. This stack promotes nothing; it makes profiles reachable, which earns no
interval or coverage claim.

## 3. Rehydration — two traps worth recording

**The handover was unreachable from a normal checkout.**
`docs/dev-log/handover/2026-08-04-claude-handover.md` did not exist on
`origin/main`; it lived only on `claude/mc0653-fixture`. The primary checkout sits
on `claude/handover-freshness-0718`, ~669 commits behind `main`, with 88
uncommitted files from earlier sessions — and its `AGENTS.md` still described
2026-07-19 work. Reading the repo's own instructions from that tree would have
produced a confidently stale picture. Everything was read via
`git show <ref>:<path>`.

**Step 1 was already done.** The predecessor session appended the blocker note
(`ad39bacbc`) and raised the timeout (`c1da21b7a`) minutes before this session
began, so run `30916793237` was already in flight. Reconciling before acting is
what stopped this from becoming a duplicate fix.

## 4. The headline finding — the 45-minute cap was a repo-wide latent failure

The handover and the fix commit both reasoned from *"main's last green run took
36m12s, and this arc adds slow `se = TRUE` profile tests."* That cites the
**fastest** recent run. Measuring every recent `ubuntu-latest (release)` **job** —
the unit `timeout-minutes` governs — the worst passing job was **44.9 min against
a 45-minute cap**, with four of ten successes ≥ 44.4.

**`main` itself had already timed out**: run `30847977891`, the post-merge check
at `95b8ea34e` (merge of PR #911, 2026-08-03), killed at **45.1 min**.

**Why it was misfiled.** GitHub records a timeout kill as
`conclusion: cancelled` — the same string as a concurrency cancel, which this repo
genuinely also suffers (`group: ${{ github.workflow }}-${{ github.ref }}`,
`cancel-in-progress: true`). Telling them apart requires comparing **job duration
against the limit**, not reading the conclusion. Concurrency cancels here landed at
9.6 / 18.3 / 28.6 / 34.8 / 37.8 min; the timeout landed at 45.1.

**The confirming evidence.** Six completed jobs today:

| Branch | Job duration |
| --- | ---: |
| `claude/prong-b-tier1` | 43m35s |
| `main` (post-#916) | 43m51s |
| `claude/mc0653-fixture` | 44m34s |
| `claude/citation-durability` (updated) | 44m36s |
| `claude/citation-durability` | 45m49s |
| `main` (post-#915) | 46m34s |

The suite does not exceed 45 minutes; it **straddles** it. The same branch died
twice at 45m06s and 45m27s, then passed at 43m35s — a coin flip. Two of these six
runs, including `main`'s own post-merge check, would have been **killed** under the
old cap: without the raise, `main` would now be permanently red on work unrelated
to this arc.

**Ceiling set to 75** (this PR), measured rather than guessed: ~28 min over the
observed maximum, leaving room for runner variance and suite growth, while still
killing a genuinely hung job in half the time the interim 120 allowed.

**Sibling instance:** `drmSEM/.github/workflows/R-CMD-check.yaml:22` carries the
identical `timeout-minutes: 45`. Same fault, not yet fired. Flagged, not fixed.

## 5. Decisions

1. **Merge at 120, tighten once at the end** (owner-approved), departing from the
   handover's "tighten, then merge." `timeout-minutes` is a **ceiling, not a
   reservation** — Actions bills consumed minutes, so a generous ceiling costs
   nothing when jobs finish early. Tightening first would have set the number from
   the lightest branch while `mc0653-fixture` had never completed a run.
2. **No rebase of the upper branches.** Verified with
   `git merge-tree --write-tree` that both merges yield `timeout-minutes: 120`,
   citation guard intact, **zero conflicts** — neither branch touched that line, so
   the three-way merge takes main's side.
3. **Promote nothing** — verified independently, not taken on trust:
   `tools/capability_ledger.py` and `capability-ledger/transitions.tsv` are
   byte-identical blobs across all four refs, and the per-cell `evidence_tier` diff
   is empty.

## 6. Pre-merge gates (both run before any merge)

- **Stack tip re-verified.** The recorded verification sat at `cab6c6faa`, three
  commits behind the tip. Re-running the full CI validation step at `ad39bacbc`
  gave **10/10 checks pass**, census 182/60. A green claimed for a different commit
  is not evidence for the tip.
- **R1 collateral-unlock gate.** The scoping memo requires a pre/post
  `profile_ready` diff before merge, because deleting fence predicates can open
  routes with no ledger cell. Result: **0 unbacked routes** — all 14 opened routes
  map to their Tier-1 cells, and `zi_nbinom2_sigma_q1_profile_restricted` plus both
  `zero_one_beta_{zoi,coi}_q1_profile_restricted` predicates remain retained.

## 7. A merge-mechanics finding worth keeping

`gh pr merge` on #916 failed with *"refusing to allow an OAuth App to create or
update workflow `.github/workflows/R-CMD-check.yaml` without `workflow` scope"*,
while #915 had merged fine minutes earlier.

The difference: **#915's merge result had workflow content identical to its head
commit** (already pushed over SSH), so no new workflow blob had to be synthesised.
#916's head still carried `timeout-minutes: 45`, so its merge result differed from
both parents and the API had to create a new workflow blob — which needs the scope
the token lacks (`admin:public_key, gist, read:org, repo`).

**The fix is the ordinary "update branch" operation**: merge `main` into the
feature branch first so its head already carries the final workflow content, push
the branch (SSH, unrestricted), then merge. Verified safe by confirming the updated
branch's tree hash was **byte-identical** to the merge result CI had already passed
on `refs/pull/916/merge`. Applied pre-emptively to #917.

## 8. Verification

The full CI validation step — `capability_ledger.py --check` **plus** all six
`tools/tests/*.py` plus the four R guards — never the headline command alone. The
C17/C14 assertion lives in one of those unittests. Run locally on the merged
`mc0653-fixture` tree before its CI finished: **all pass**, including an explicit
re-run of `test_capability_ledger` after its summary line proved ambiguous in a
loop that would not have halted on failure.

## 9. Deferred, explicitly

- The 135-trace interval campaign (182→196, `FROZEN_CENSUS` 59→45).
- The `predict()` scale-axis defect — its gate test **pins current behaviour** and
  must fail when `predict()` is corrected. Update it then; never relax it.
- The CI guard/check job split — recommended, own arc. Only the Python ledger block
  and `check-evidence-citations.R` are free of the compiled package; splitting
  anything else costs a second TMB compile unless `src/*.so` is cached.
- B4-CI `SOURCE_COMMIT` port; mc-0282's runner contract (PROTECTED).

## 10. Open for the owner

- **D-117** — does the 0.7.0 coverage gate cover the 14 newly-reachable profile
  routes? Unresolved; its own ledger note leaves lane ownership open.
- **The D-117 number already exists, and is unpushed.** 10-group profile coverage
  measured **0.937 (0.920, 0.951)**, n = 1000, from a cap-compliant clean rerun —
  i.e. the corner is *not* materially worse than D-97's pooled 0.9368. It lives
  only on `codex/sd-bootstrap-r999-diagnosis` (`4cc837a85`), which is **on no
  remote**. Two caveats: the predeclared directional-miss fence failed (53 upper vs
  10 lower misses; 63/1000 profiles at the zero boundary), and the design covers
  one cell (`n_per = 10`), leaving `n_per = 4` at 10 groups — the worst corner —
  unmeasured on the profile route.
- `claude/profile-coverage-remeasure-20260718`, cited in the brain's
  `DECISIONS.md:1628`, **does not exist**.
