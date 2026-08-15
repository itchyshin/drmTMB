# After-task — 0.7.0 CRAN ladder: rehydration and OWED steps

**2026-08-15 · Claude · lane `claude/07-cran-ladder` · `origin/main` = `e19cc0807`**

## 1. Goal

Rehydrate `docs/dev-log/handover/2026-08-15-070-cran-ladder-claude-handover.md`, reconcile every
claim in it against live git, and execute only the steps that reconciliation left `OWED`. No rung
advance, no submission, no campaign.

## 2. Implemented

Reconciled the handover claim-by-claim, ran the fail-closed CRAN gate, resolved the D-117 status
question the handover flagged as conflicted, and closed the two superseded release PRs.

**The gate.** `python3 ~/shinichi-brain/tools/cran_release_gate.py` on
`docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json` returns **READY FOR CLAIMED
RUNG** at `status_claim = tarball-clean`. A probe copy raised to `platform-clean` returns **NOT
READY** on `evidence.platform_matrix` and `evidence.external_logs` — the handover's "mechanically
blocked" claim is confirmed by execution, not by reading.

**The frozen artifact still verifies.** `/Users/z3437171/drmTMB-release-artifacts/0.7.0/drmTMB_0.7.0.tar.gz`
is present at 9,925,713 bytes with SHA-256
`2176e4b81b887e8d944456e4a74fa581afda959d0d2a5468c89bc700d693cda9` — recomputed, matching the ledger
exactly.

**D-117 is NOT conflicted.** See §3a; this is the substantive correction to the handover.

**Candidate drift is larger than any prior record.** The 2026-08-12 re-freeze notice measured 17
shipped files changed against `main` `98057133d`. Against `main` `e19cc0807` today it is **60**:
vignettes 23, tests 16, `R/` 9, `man/` 6, `inst/` 3, `src/` 1, `NEWS.md` 1, `DESCRIPTION` 1.
`DESCRIPTION` still reads `Version: 0.7.0`, so the notice's central hazard — *a different 0.7.0 with
no version-string signal* — has widened, not closed. `DESCRIPTION` gained three Suggests
(`metadat`, `nlme`, `ordinal`) after the freeze.

**PRs closed.** #959 and #955, each with a comment naming #996 as the superseding freeze.

## 3a. Decisions and Rejected Alternatives

**D-117: recorded as NOT DECIDED; the handover's "CONFLICTED" framing is RETRACTED.** The handover
asserted that the brain records a discharge on 2026-08-09 while the repo says "RECOMMENDED, NOT
DECIDED". Reading the brain's own text refutes this. `memory/DECISIONS.md:150` reads "discharge
**RECOMMENDED with four conditions — NOT DECIDED**, awaiting Shinichi", and the D-117 entry's
2026-08-09 block is explicit: *"**(e) NOT DECIDED — this is the operative status** … Shinichi
approved the recommendation being made; he has not recorded the decision. Do not treat D-117 as
discharged."* Repo `AGENTS.md:163` says "every *item* is closed; the DISCHARGE is still an open owner
call."

**Both sources agree.** What the 2026-08-09 record contains is a *re-run and a recommendation*, not a
discharge; the handover read the recommendation as the decision. Rejected: escalating a two-source
conflict to Shinichi, because there is no conflict to escalate. The operative status is unchanged and
unambiguous — **D-117 is not discharged, and its discharge is Shinichi's call.**

**Closed #959 and #955 rather than rebasing.** Both are superseded by #996's freeze lineage; #959 is
248 commits behind and carries four abandoned candidate freezes (`d35c0b9e`, `da9b2d76`, `d04d0e88`,
`a8f7c479`) plus edits to shipped `R/` files. Rebasing would have re-litigated an abandoned candidate
history for no release benefit.

**Did not close them blind.** Before closing, each unique commit was tested for ancestry against
`main`. This surfaced a finding the handover did not carry — see §7a.

**Did not touch `status_claim`, the ledger, or any release document.** Explicitly withheld by the
handover and by D-49; the gate would fail closed anyway.

## 4. Files Touched

- `docs/dev-log/after-task/2026-08-15-070-cran-ladder-rehydration.md` — created (this report).

No source, ledger, release-audit, or `AGENTS.md` file was modified. Two GitHub PRs (#959, #955) were
commented and closed; no branch was deleted.

## 5. Checks Run

| Check | Result |
| --- | --- |
| `bash ~/shinichi-brain/tools/lane_preflight.sh .` | 12 lanes live; foreign codex lane direct-to-main; lane taken and named |
| `git fetch --prune origin` | `origin/main` = `e19cc0807`, matching the handover exactly — no drift |
| `cran_release_gate.py` on the 0.7.0 ledger | **READY FOR CLAIMED RUNG** (`tarball-clean`), exit 0 |
| Same ledger, `status_claim` probed to `platform-clean` | **NOT READY** — missing `platform_matrix`, `external_logs`, exit 1 |
| `shasum -a 256` on the frozen tarball | `2176e4b8…cda9`, 9,925,713 bytes — matches ledger |
| `git diff --stat a75c3c901 origin/main -- src/` | `src/drmTMB.cpp`, +23/−4, via `55fc08abc` (#1012) |
| `git rev-list --left-right --count` on both PR branches | #959 248 behind, #955 259 behind — matches handover |
| PR states via `gh` | #996/#1030/#1031/#1034/#1035/#1012 MERGED; #959/#955 now CLOSED |

No R package check was run: nothing in the package was changed, and no rung depends on one here.

## 6. Tests of the Tests

The gate was tested for its ability to say NO, not only YES. Running it on the unmodified ledger
returns READY at `tarball-clean`; running the *same* ledger with only `status_claim` raised to
`platform-clean` returns NOT READY and names both missing evidence keys. A gate that only ever
returned READY would have been indistinguishable from a broken one on the first call alone.

Ancestry claims were likewise tested both ways: `git merge-base --is-ancestor` returned YES for
`9c6a63223` and `e9f7118e1` (work that did land) and NO for `8245449f2`, `05a7b0914`, `c8d3fcb49` —
so the check discriminates rather than answering uniformly.

## 7a. Issue Ledger

**One unlanded feature was found inside #959 and is not on `main`.** Commit **`8245449f2`** —
*"feat(boundary): flag boundary intervals on the bootstrap route; scope check_drm()"* — is not an
ancestor of `main` by any path, and the tokens `bootstrap_at_boundary` and
`drmTMB_bootstrap_boundary_warning` appear **nowhere** in `main`'s `R/`, `man/`, `tests/`, or
`NEWS.md`.

It closes TRAP 1 from the pre-release reader review: the bootstrap route returns a clean-looking
interval at a variance boundary while both the Wald route (`wald_at_boundary`) and the profile route
(`profile.boundary` / `drmTMB_profile_boundary_warning`) warn. That is a user-facing honesty gap on
an interval method, and it is currently shipped-absent.

**It is not lost.** The commit is preserved on `origin/claude/boundary-surfacing`, a branch separate
from the closed PR, and the closing comment on #959 states this explicitly. **It must be re-landed on
a fresh branch cut from `main`, not through #959.** Not done here: it is interval-behaviour work, not
release-ladder work, and this lane was scoped to OWED ladder steps only.

## 8. Consistency Audit

- Handover ↔ git: `origin/main`, all six merged PR numbers, both staleness counts, the `src/`
  change, the artifact hash, and the two missing evidence keys all reconcile exactly. The handover is
  accurate on every mechanical claim.
- Handover ↔ brain: **one correction** — the D-117 "CONFLICTED" claim (§3a).
- Handover ↔ re-freeze notice: consistent, but the notice's file count is now stale (17 → 60).
- Repo `AGENTS.md` and brain `DECISIONS.md` agree on both D-93 (held) and D-117 (not discharged).

## 9. What Did Not Go Smoothly

The handover file does not exist on the branch its own paste-ready prompt is run from. The primary
checkout sits on `claude/handover-freshness-0718`, ~1,020 commits behind `main`; the document lives
in `.worktrees/handover-0815` on `claude/handover-2026-08-15` (PR #1037, open). Anyone following the
prompt literally gets "file does not exist" as their first result. Located it by searching all refs
and worktrees.

`lane_preflight.sh` threw a shell arithmetic error (`line 379: ( 1786811687 - ) / 86400`) mid-run on
an empty operand. It still produced its verdict and census, so it did not block, but a date field it
reads is empty somewhere.

## 10. Known Residuals

- **The re-freeze decision is now MADE and is no longer a residual.** Put to Shinichi with the
  notice's two options plus a third; he chose the third — **do not re-freeze yet**. Recorded in
  `docs/dev-log/release-audits/2026-08-15-070-refreeze-timing-decision.md`, which also lists the five
  conditions that must hold before the next freeze. The rung stays `tarball-clean`.
- **Step 6 of the handover is deliberately not started.** Planning platform evidence for a candidate
  that will not be cut yet would be wasted; the campaign runs once, against shipping bytes.
- **D-93 HELD**, undischarged. No engineering step in this repo can discharge it.
- **D-117 not discharged** — owner call, with the recommendation's four conditions attached.
- **`8245449f2` unlanded** (§7a).
- **⚠ Stale `.git/index.lock`** — 0 bytes, 2026-08-14 18:43, still present. `handoff_gate.sh` flags
  it; the harness blocks `.git` deletions. **Reported, not removed** — Shinichi's to clear.
- **`handoff_gate.sh` still FAILS** on foreign unpushed branches. Global coordination state, not this
  lane's debt.
- Ledger gaps `rights_and_consent_is_stale` and `gate1_unresolved_items` (2 unresolved Gate 1 items)
  remain open and must close before `submission-ready`, independent of the re-freeze choice.

## 11. Team Learning

**A handover's mechanical claims and its interpretive claims fail differently.** Every number in this
handover — hashes, commit counts, PR states, missing keys — verified exactly. The one claim that did
not survive was the one requiring judgement: reading a *recommendation with four conditions* as a
*discharge*. Reconciliation effort is better spent on the sentences that interpret a source than on
the ones that quote it.

**Closing a superseded PR deserves an ancestry check first.** #959 was correctly identified as an
abandoned candidate lineage, and closing it was right — but it also contained one commit of genuine
unlanded user-facing work. "Superseded" described 31 of its 32 commits. Checking ancestry per commit,
rather than trusting the branch-level verdict, is what surfaced it.

**Memory receipt:** loaded the repo LOAD-FIRST manifest in `AGENTS.md` and the hub CRAN rules; the
guards that actually shaped the work were **D-49** (fail-closed gate; ran the executable ledger rather
than reading the rung), **D-43** (completion adversary — did not accept the handover's own verdict),
**D-87/D-88** (lane boundaries; named this lane, left the 5 open foreign PRs untouched), and **D-37**
(brain read-only — the D-117 finding is recorded here in the repo, not written to the vault).

Golden Set: the `cran-readiness-partial-green` regression is directly in scope and held — no partial-green
evidence was promoted to a whole-release claim; the rung stayed at `tarball-clean`. Recalled the brain
before concluding on D-117 rather than re-deriving it from repo documents alone, which is what
produced the correction.

## 12. Cross-Product Coverage

Confined to drmTMB. No gllvmTMB, DRM.jl, or other sibling-repo state was read or written. No
sibling-project scouting was performed, so no cross-team note was owed.

**What this arc covers:** the release-ladder surface only — the rung claim, the ledger's evidence
keys, the frozen-artifact identity, the two superseded PRs, and the D-117/D-93 status questions.

**What this arc does NOT cover**, stated per flag it brushed against:

- **Intervals / boundary** — the `8245449f2` bootstrap-boundary gap (§7a) was *found*, not fixed. It
  does NOT cover re-landing it, and it does NOT cover the Wald or profile routes, which already warn.
- **Platform / engine** — no platform evidence was produced. `platform_matrix` and `external_logs`
  remain absent for every provider: 3-OS matrix, R-hub sanitizers, valgrind, and win-builder are all
  uncovered against the current bytes.
- **Compiled code** — the `src/drmTMB.cpp` drift was measured, not adjudicated; no sanitizer or
  valgrind run was performed against it.
- **REML, penalty, missing-data, aggregation** — untouched entirely; no claim in any of those
  surfaces is affected, advanced, or retracted by this arc.
- **Rights / Gate 1** — the two unresolved items and the stale rights skim were read from the ledger
  and are restated in §10; this arc does NOT close either.
