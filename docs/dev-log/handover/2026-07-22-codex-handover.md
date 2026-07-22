# Handover — drmTMB 0.6 dev arc → Codex (2026-07-22)

**From** Claude Code · **To** Codex · **Date** 2026-07-22 · **Branch** `claude/0.6-dev-arc`
**Worktree** `/private/tmp/drmtmb-precran-review-7abdd7e9` · **Branch head** `77bcd959`
**Predecessor** [`2026-07-21-0.6-dev-arc-session2-handover.md`](2026-07-21-0.6-dev-arc-session2-handover.md)

You are Codex, picking up the drmTMB 0.6 dev arc. This session changed **no executable code**.
It was an adjudication session: it answered the question "can we commit and merge this branch?"
and the answer moved, so read §1 before you do anything else.

---

## 1. Critical context — two things, or you will go wrong

**(1) The predecessor handover's merge blocker is now STALE.** Its action item #10 says
*"Sequence the merges — pkgdown owner first, then this branch."* That precondition is
**already satisfied**. `main`'s tip commit `1a972b8e` **is** `docs: audit and repair pkgdown
reader surface (#816)` — the pkgdown owner went first and landed. The session-2 handover was
written before #816 merged, so it is describing a world that no longer exists. Do not re-block
the merge on that item.

**(2) The 22 q-series test failures are NOT introduced by this branch — `main` already has
them.** The predecessor reports the branch red at 22 failures and attributes them to
`tools/qseries_v1_claim_guard.py` correctly detecting a real defect (its §4.3). This session
ran that guard **on `main`** and it exits **1** with the identical two messages:

```
README.md: must link to docs/dev-log/release-audits/q-series-v1-release-status.md
README.md: 4 support-cell rows have dimension_pattern=q12 (e.g.
  'qseries_phylo_q12_all_four_two_slope') but no q12 capability mention was found;
  the public capability catalog has drifted behind the ledger
```

So the defect is live on `main` **today**, independent of this branch. Merging is **neutral**
with respect to that red — it neither introduces nor fixes it. Anyone who blocks the merge
"because the branch is red" has mis-attributed a `main` defect to the branch.

**Still true and still binding:** do **NOT** clear that guard by retargeting it. The red is
correct. The fix is the README repair (§5, item 4), which Shinichi said he would take.

---

## 2. What this session actually established

No code, no tests, no docs changed except this handover. Findings, each independently verified
against the repo rather than taken from the predecessor doc:

| Question | Finding | How verified |
|---|---|---|
| Anything to commit on the arc? | **No.** Working tree clean; branch exactly in sync with `origin/claude/0.6-dev-arc` | `git status -b --porcelain` — no dirty entries, no ahead/behind marker |
| Divergence from `main`? | `main` has **6** commits the arc lacks; arc has **15** `main` lacks | `git rev-list --left-right --count main...HEAD` → `6  15` |
| Would the merge conflict? | **No — clean.** | `git merge-tree --write-tree --name-only main claude/0.6-dev-arc` returned a bare tree OID with no conflict paths |
| Is a PR open? | **No open PRs at all.** This repo merges directly to `main` | `gh pr list --state open` → empty |
| Is the pkgdown lane still open? | **No.** Its worktree is on `main`, clean, in sync with `origin/main` | `git -C /private/tmp/drmtmb-site-audit-83d48549 status -b` |
| Is the q-series red branch-specific? | **No — `main` is red too** | guard run in the `main` worktree, exit 1 (§1) |

**The Codex `julia-bridge` lane appears CLOSED — evidence, with its limit.** The predecessor's §0
declared a Codex lane live "until ~tomorrow morning" (i.e. today), scoped to `R/julia-bridge.R`
roxygen, `man/`, and `_pkgdown.yml`, branched from `0b48b94b`. Two checks:

- `git branch --contains 0b48b94b` returns **only `claude/0.6-dev-arc`** — no other local branch
  was ever built on that fork point.
- `git log --all --since=2026-07-20 -- R/julia-bridge.R` returns **exactly one commit: `1a972b8e`**,
  which is #816, already merged to `main`.

#816's diff touches `R/julia-bridge.R`, `_pkgdown.yml`, and `man/` — precisely that lane's declared
scope. The reasonable reading is that the work landed with #816. **Limit of this evidence:** it
cannot see a lane living only in an unregistered worktree or an unpushed remote branch. If you know
that session is still running, confirm with Shinichi before merging; otherwise treat it as closed.

---

## 3. Landing State — the git ledger

Gate run: `bash ~/shinichi-brain/tools/handoff_gate.sh` from the repo root → **GATE FAIL**.
Every failure is declared below; none is left invisible.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `drmTMB` `claude/0.6-dev-arc` `77bcd959` (the 15-commit arc) | y | y | none | **CARRIED-OVER** — unmerged by design |
| `drmTMB` `claude/0.6-dev-arc` `d36e7609` (this handover + `AGENTS.md`) | y | **n — PUSH REFUSED** | none | **CARRIED-OVER — ⚠ NOT ON `origin`** |
| `drmTMB` `claude/handover-freshness-0718` | y | **n — 1 unpushed** | none | **CARRIED-OVER** |
| `drmTMB` main checkout — ~50 untracked files | **n** | n | — | **CARRIED-OVER — DO NOT COMMIT** |
| `drmTMB` ~60 legacy `codex/*`, `drmtmb/*` branches, 1–3 unpushed each | y | **n** | none | **CARRIED-OVER** — pre-existing estate debt |
| `drmTMB` `.git/index.lock` | — | — | — | **STALE LOCK — report, never remove** |

**Why each is carried over, and how to resume it:**

- **⚠ THIS HANDOVER IS COMMITTED BUT NOT PUSHED.** Commit `d36e7609` exists only in the local
  worktree `/private/tmp/drmtmb-precran-review-7abdd7e9`. Shinichi declined the push, so **to a
  Codex session that clones `origin`, this document does not exist.** If you are reading it from
  `origin`, someone has since pushed it. If you are reading it from disk, the branch head on
  `origin` is still `77bcd959`. Resume: `git push origin claude/0.6-dev-arc` — **maintainer's call.**
- **`claude/0.6-dev-arc` unmerged.** Not a defect — the merge is Shinichi's decision under the
  predecessor's §3b, whose header states every row "needs a human… a decision or an edit only the
  maintainer should make." He has not given it. Mechanically the merge is ready and conflict-free.
  Resume: `git checkout main && git merge --no-ff claude/0.6-dev-arc` — **only on his explicit go**,
  and confirm the Codex `julia-bridge` lane closed first (§2).
- **`claude/handover-freshness-0718` 1 unpushed.** A different lane (the AGHQ + non-Gaussian REML
  arc, per `AGENTS.md`). Not this session's work; not inspected. Resume:
  `git -C "<repo>" push origin claude/handover-freshness-0718` — but identify the author first.
- **~50 untracked files in the main checkout — deliberately NOT committed.** They were written by
  prior sessions, not this one (D-60: uncommitted files you did not create belong to a prior
  session; identify the writer, never assume). Two of them sit in `docs/dev-log/release-audits/`,
  a directory the predecessor's §0 explicitly fenced off as another lane's territory. Committing
  them from this lane would step on that lane. They also include clearly ephemeral `scratchpad/`
  spikes and `*-DRAFT.md` files that should probably never be committed at all. **Someone must
  attribute them before anything is staged.**
- **~60 legacy branches with unpushed commits.** Long-standing estate condition spanning months of
  `codex/*` work, not produced by this session. Flagged so it is visible, not fixed here — bulk
  pushing sixty unreviewed branches is not a handover-time action.
- **Stale `.git/index.lock`.** Reported, not removed — the protocol is explicit that removing it
  silently is how you corrupt someone else's in-flight operation. **Shinichi clears it.** It may
  block index operations in the *main checkout*; worktrees carry their own index, which is why
  this handover could still be committed on the arc branch.

---

## 4. Key decisions and rationale

- **Did not merge.** Two reasons, in order: the maintainer reserves the decision (above), and the
  Codex `julia-bridge` lane's status is unconfirmed. The *stated* blocker (pkgdown first) has
  cleared, so the merge is closer than the predecessor implies — say so when you ask him.
- **Did not commit the main checkout's untracked files.** D-60 plus the §0 lane fence.
- **Did not touch `vignettes/`, `README.md`, `NEWS.md`, `_pkgdown.yml`, `man/`, or
  `docs/dev-log/release-audits/`** — the predecessor's §0 fences these while the reader-surface
  epoch is open. Note #816 has since landed, so that fence may now be lifted; confirm with Shinichi
  rather than assuming.

---

## 5. Next immediate steps — ordered, and routed by tool

**Codex owns the live toolchain here** (real R/TMB fits, `R CMD check` with compilation, sims,
vignette rendering). Claude owns planning, prose, and pure-logic work.

1. **[Codex, cheap] Sanity-check the `julia-bridge` lane one last time.** The git evidence in §2 says
   it landed with #816; all that remains is Shinichi confirming no unregistered session is still live.
2. **[Shinichi] Get the merge decision — this is now the only real gate.** Present it as: precondition #10 has cleared, merge is
   conflict-free, branch red is a pre-existing `main` defect. If he says go:
   `git checkout main && git merge --no-ff claude/0.6-dev-arc && git push origin main`.
3. **[Codex, live] Re-measure the suite honestly.** A plain `devtools::test()` **lies** — see §7.
   Use `d <- as.data.frame(testthat::test_local(".", reporter = "silent")); sum(d$failed); sum(d$error)`.
   Expect 22 failures, all q-series, all correct.
4. **[Shinichi or Codex] The q-series README repair.** This is the highest-leverage item: it clears
   the guard on **both** `main` and the branch. Restore the link to
   `docs/dev-log/release-audits/q-series-v1-release-status.md`, restore a `q=12` statement covering
   `qseries_{phylo,spatial,animal,relmat}_q12_all_four_two_slope` **at their ledger tier**
   (point-fit/recovery only — intervals and coverage planned; `ROADMAP.md:588-590` has usable
   wording), and ensure any line containing "Q-Series" carries a boundary term or the guard's
   inflation check fires. Reportedly takes the cluster from 22 failures to 0.
5. **[Shinichi] The other 10 maintainer decisions.** Do not re-derive them — they are itemised with
   rationale in the predecessor's §3b and §4. The load-bearing ones are the `mc-0260m`
   `claim_boundary` text (#1), `mc-0262`'s unresolved M=64 threshold objection (#3), the rho12
   campaign (#4 — this session's predecessor recommends **do not fund it**; its own approved smoke
   argued against it, profile and Wald agreeing to 4.0e-4), and the false "certified" claim at four
   sites (#5).
6. **[Either] Only then plan the new arc.** Planning on top of an unmerged branch and a red `main`
   is how the lane count got to fourteen worktrees.

---

## 6. Mission control

| Repo | Branch | vs main | CI / suite | What shipped | Next by leverage |
|---|---|---|---|---|---|
| drmTMB | `claude/0.6-dev-arc` @ `77bcd959` | +15 / −6, **clean merge** | 22 failures, all q-series, **also red on main** | Track A verified: newcomer sweep 17/17, 264 files / 39,320 passing, zero added failures; `impute_model()` guard | README q-series repair → clears guard everywhere |
| drmTMB | `main` @ `1a972b8e` | — | guard exit 1 | #816 pkgdown reader-surface repair landed | merge decision |
| drmTMB | `claude/handover-freshness-0718` | 1 unpushed | not run | AGHQ + non-Gaussian REML arc | foreign lane — attribute before touching |

**CRAN status: PARKED, not failed.** Shinichi decided 2026-07-21 that 0.6 will **not** be submitted.
Tarball re-freeze, platform matrix, `cran-comments.md` rewrite, submission are **out of scope**.
Do not restart them.

---

## 7. Gotchas — do not re-learn these

Carried forward from the predecessor because they are still live, plus this session's own:

- **`devtools::test()` lies about failure counts.** testthat caps failure *display* at 10 and the
  cap **cannot** be lifted via `options(testthat.progress.max_fails=)` or `TESTTHAT_MAX_FAILS`.
  Use the `test_local(reporter = "silent")` recipe in §5.3.
- **Do not trust an exit code.** `devtools::test()` returned 0 while its log said "Maximum number of
  10 failures reached."
- **Squash merges break `git merge-base --is-ancestor`** — verify landed work by CONTENT, not ancestry.
- **Message-substring coupling.** Rewording one cli message broke 12 assertions across 9 files keying
  on `"only support"`. Grepping the full string proves nothing.
- **Classify a red test before fixing it**: stale assertion / correctly detecting a real defect /
  broken infrastructure. The q-series red is case two.
- **`supported` is a FIT-STATUS label, not an inference tier.** A coverage campaign cannot produce one.
- **Never quote "N of 694"** — about half is `rejected_by_design` at tier `none`. Use implemented
  cells as the denominator and say whether you mean FIT or INTERVAL evidence.
- **`handoff_gate.sh` false-passes on a bare repo name.** `handoff_gate.sh drmTMB` prints
  "not a git repo" then **"GATE PASS — 0 repo(s) fully landed. Safe to hand over."** It checked
  nothing. Pass a path, or run it from inside the repo. This is a real defect in the gate and worth
  fixing in `shinichi-brain`.
- **Environmental, this session:** Claude Code's Bash permission classifier
  (`claude-sonnet-5[1m]`) was intermittently unavailable, failing roughly half of all Bash calls with
  "cannot determine the safety of Bash right now." Read-only file tools were unaffected; `Grep` and
  `Glob` were entirely absent from the session. This is why the `julia-bridge` lane check is
  unfinished — retry it, it is not a repo problem.

---

## 8. How to resume

Codex reads `AGENTS.md` natively. Start Codex at the repo root and paste:

```
Rehydrate from docs/dev-log/handover/2026-07-22-codex-handover.md plus the AGENTS.md
snapshot, then continue with the Next Immediate Steps.
```

Read in this order: `AGENTS.md` (the "▶ Latest" block) → this doc → the predecessor
[`2026-07-21-0.6-dev-arc-session2-handover.md`](2026-07-21-0.6-dev-arc-session2-handover.md)
for the full 11-item maintainer list and the Track A/B evidence → the ultra-plan
[`docs/dev-log/2026-07-21-0.6-dev-arc-ultra-plan.md`](../2026-07-21-0.6-dev-arc-ultra-plan.md).

Working tree:

```sh
cd /private/tmp/drmtmb-precran-review-7abdd7e9 && git status && git log --oneline -10
```

Live toolchain environment (Codex runs these; Claude generally cannot):

```sh
export NOT_CRAN=true
# The repo .Rprofile's R-4.5 library segfaults R 4.6 — bypass it for scripted runs:
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test()'
```

Standard commands per `AGENTS.md`: `devtools::document()`, `devtools::test()`,
`devtools::check()`, `pkgdown::check_pkgdown()`.

Mandatory review lens before any public claim: **Rose** (`.codex/agents/systems_auditor.toml`).
For a completion or promotion claim, D-43 requires three genuinely fresh agents defaulting to
NOT-DONE; two NOT-DONE verdicts withhold the claim.
