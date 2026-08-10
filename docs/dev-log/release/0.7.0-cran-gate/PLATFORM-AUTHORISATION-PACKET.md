# drmTMB 0.7.0 — platform authorisation packet

**Written by:** Rose (systems auditor) · **Date:** 2026-08-09 · **Revised:** 2026-08-09
**Reads:** `HASH-LEDGER.md` (Grace), S2b findings (scratchpad), `~/shinichi-brain/protocols/cran-release-gate.md`
Gate 6, `platform/PLATFORM-NOT-READY.md`.

> **No rung claim is made or implied by this document.** This packet prices options for
> one owner decision; it does not advance `status_claim`, merge anything, bump
> `DESCRIPTION`, or authorize upload. The owner has **already authorised** the
> platform matrix — the open question is *which* runs to dispatch and in what
> order, not whether to spend at all.

---

## CORRECTIONS (found by adversarial review, not by the original author)

The first draft of this packet made four errors, each verified independently in
this worktree before being fixed here. None of these were self-caught.

1. **The money axis was false.** `gh repo view itchyshin/drmTMB --json visibility`
   → `PUBLIC`. `gh api repos/itchyshin/drmTMB/actions/runs/31195187084/timing --jq
   .billable` and the same call on `31336312020` both return `total_ms: 0` for
   `UBUNTU`, `MACOS`, and `WINDOWS`. **GitHub Actions is free on this repository.**
   "≈481 billed minutes" and "~600–750 billed minutes" (the original §3 table)
   never existed as real cost. The axis that matters is **wall-clock / attention**,
   not dollars.
2. **"Never had CI" was false.** `gh run view 31333822332 --json
   headSha,conclusion,event` → `success` at `6dc48cd94`, a `pull_request` event.
   `604016a5d` (3-OS, run `31336312020`, success) and R-hub (`31336313176`,
   success) are both ancestors of the PR head. `git ls-tree` for `src` is
   **identical** (`a4a3138d80…`) at `cc4f5baee`, `604016a5d`, `6dc48cd94`,
   `9f0000877`, `bce9cfb6f` — six commits, same compiled-code tree, all CI-green.
   The true, narrower claim is: **no CI run exists pinned to the exact candidate
   head `cc4f5baee` itself** — every green run sits one or two commits away on
   docs/log-only diffs.
3. **The gap is bigger than win-builder alone.** `gh run view 31336313176 --json
   headSha,conclusion,jobs` lists only `linux (R-devel)`, `windows (R-devel)`,
   `macos (R-devel)` — **no `clang-asan`, `clang-ubsan`, `gcc-asan`, `valgrind`,
   or `rchk`.** The only run that ever exercised sanitizers, `31195195196`, is
   pinned to the pre-repair 0.6.0 head `744b9fbe` and **ended `failure`**
   (rchk failure, valgrind cancelled — `HASH-LEDGER.md` row `f9b9588e…`). No
   sanitizer coverage exists anywhere for the current `src/drmTMB.cpp`, and that
   file genuinely changed between hashes (`git diff --stat a2695a788 cc4f5baee --
   src/`). Win-builder is not "the" gap; it is the cheapest slice of a larger one.
4. **The merge instruction was backwards.** `git show cc4f5baee:DESCRIPTION`
   already reads `misspecification` (line 22) and `git show
   cc4f5baee:inst/WORDLIST` already exists with `centile`/`uncalibrated`-adjacent
   entries. `git merge-tree $(git merge-base cc4f5baee origin/claude/07-cran-notes)
   cc4f5baee origin/claude/07-cran-notes` shows **conflicts** in `DESCRIPTION`
   (both sides reworded the same sentence differently), plus divergent `NEWS.md`
   and `R/julia-bridge.R` content. `claude/07-cran-notes` does not need to reach
   the candidate lineage — **the candidate already fixes both NOTEs**, and the
   branch should be **withdrawn**, not merged. Caution for any future NOTE fix:
   `inst/WORDLIST` is **never read** by CRAN-incoming spell checking (zero hits
   for the literal string `"WORDLIST"` across the `tools`/`utils` namespaces;
   only `.aspell/defaults.R` overrides dictionaries), so adding words there does
   not silence the spelling NOTE — win-builder had already flagged `centile
   (23:43)` and `uncalibrated (24:6)` regardless.

---

## DECISION REQUESTED

**Dispatch a fresh platform matrix pinned to the exact 0.7.0 candidate head
(`a8f7c47905b0…`, source `cc4f5baee`) now — and if so, how much of it?**

**Recommendation changed. New recommendation: run (b) now — win-builder +
fresh 3-OS CI at the exact candidate head — and treat (c) (adding the R-hub
sanitizer/rchk/valgrind jobs) as the very next step once (b) is green, not a
deferred "maybe later."** With Actions confirmed free (§ Corrections item 1)
and 3-OS wall time ~59 min in parallel (`platform/gha-3os-matrix.md`, run
`31195187084`: ubuntu 46.5 min, macOS 31.7 min, windows 58.8 min run
concurrently, not summed), the original "hold, win-builder only" recommendation
was over-correcting toward caution against a cost that did not exist. The one
real cost identified is R-hub sanitizers, which historically run long (the
0.6.0-era `31195195196` run took ~6 h) — that is worth sequencing *after* (b)
confirms the ordering problem in §4 is fixed, but it should not be deferred
indefinitely: it is the only source of sanitizer evidence for changed C++ that
this package has never had at any 0.7.0-era hash. No time pressure forces
either step: the CRAN portal is offline until ~2026-08-19
(`PLATFORM-NOT-READY.md` line 66) and submission is a deliberate later step
(D-89).

---

## 1. The content-equivalence argument — precise, not overclaimed

GHA 3-OS (`31336312020`) and R-hub (`31336313176`) ran `success` at commit
`604016a5d`, two commits ahead of the candidate's source `cc4f5baee`
(`HASH-LEDGER.md` row `a8f7c4790…`, `CURRENT`). I independently re-ran
`git diff --name-only cc4f5baee 604016a5d` in this worktree and confirmed the
changed paths are exactly:

```
AGENTS.md
docs/dev-log/after-task/2026-08-09-07-release-slice-third-candidate.md
docs/dev-log/check-log.md
docs/dev-log/handover/2026-08-09-claude-handover-d117-discharge.md
docs/dev-log/plan-actual/2026-08-09-07-release-slice.md
docs/dev-log/release-audits/2026-08-09-07-adversarial-freeze-audit.md
docs/dev-log/release-audits/2026-08-09-07-cran-release-ledger.json
docs/dev-log/release-audits/2026-08-09-07-decision-packet.md
docs/dev-log/release-audits/2026-08-09-07-mechanical-freeze-verify.md
docs/dev-log/release/0.7.0-cran-gate/CANDIDATE-EVIDENCE/as-cran-a8f7c47905b0.log
docs/dev-log/release/0.7.0-cran-gate/CANDIDATE-EVIDENCE/inventory-a8f7c47905b0.txt
docs/dev-log/release/0.7.0-cran-gate/CANDIDATE-EVIDENCE/tarball-a8f7c47905b0.sha256
docs/dev-log/release/0.7.0-cran-gate/FREEZE-NOTES-0.7.0.md
docs/dev-log/release/0.7.0-cran-gate/STALE-EVIDENCE-QUARANTINE.md
```

Every one of these is `AGENTS.md` or under `docs/`. `.Rbuildignore` (this
worktree) excludes both: line 10 `^docs$`, line 14 `^AGENTS\.md$`. I also
grep-verified the candidate's own build inventory directly —
`docs/dev-log/release/0.7.0-cran-gate/CANDIDATE-EVIDENCE/inventory-a8f7c47905b0.txt`
at `604016a5d` — 904 entries, **zero** matching `docs/` or `AGENTS.md`. And I
extended this to the compiled surface directly: `git ls-tree` of `src` returns
the **same tree object** (`a4a3138d808a394a4c3880f173373244e67d2247`) at all of
`cc4f5baee`, `604016a5d`, `6dc48cd94`, `9f0000877`, and `bce9cfb6f` — the C++
that GHA/R-hub compiled and checked at `604016a5d` and in PR run `31333822332`
(`6dc48cd94`) is byte-identical to the candidate's C++.

So: the source tree GHA/R-hub actually built at `604016a5d` (and, separately,
`6dc48cd94` via the `pull_request` run `31333822332`) is **identical after
build exclusions** to the candidate's shippable content, on six independent
commits.

**What this does NOT establish.** `R CMD build` embeds build timestamps and file
mtimes, so rebuilding identical source content does not reproduce an identical
tarball byte-for-byte; there is no literal-hash match between what GHA/R-hub built
and the frozen `a8f7c47905b0…` tarball, and none is claimed. Gate 6 asks "which
hash did each service test" — the honest answer here is **strong content-equivalence
of a rebuild, not this literal tarball.** Accepting that as satisfying Gate 6 is a
judgement call for the owner, not a fact this document can assert on its own.

**Strengthened since the first draft:** a separate reviewer pass normalised the
876 non-`src` inventory entries (of the 904 total confirmed above at
`604016a5d`) against `git ls-tree -r cc4f5baee` and found every non-tracked
entry is build-generated (`build/partial.rdb`, `build/vignette.rds`,
`inst/doc/*`) — **zero stray untracked files, zero `src/*.o`.** I re-verified
the 904 total independently (`git show 604016a5d:.../inventory-a8f7c47905b0.txt
| wc -l`) but did not independently re-derive the 876/28 split reported by that
pass — flagged here as unverified-by-me rather than repeated as confirmed fact.
The tarball content is fully determined by the git tree, so a clean CI checkout
at any of the five equivalent commits above produces the same shippable
package.

## 2. The genuine gap — win-builder is the cheap slice, not the whole gap

**No win-builder submission exists for this candidate at any level.** Every
win-builder log under `docs/dev-log/release/0.7.0-cran-gate/platform/` belongs to
0.6.0 predecessor artifacts (`c787ee40…` unrepaired, `f9b9588e…` CondExp-fixed) —
confirmed in `HASH-LEDGER.md` rows for those hashes and in the ledger's own
`604016a5d` note ("No win-builder run exists for this candidate"). win-builder is
**free** (submitted by email, no Actions minutes) — the gap costs nothing to close
but has not been closed.

**But win-builder is not the only, or the largest, gap.** `gh run view
31336313176 --json headSha,conclusion,jobs` (the candidate-era R-hub run, at
`604016a5d`) lists jobs `linux (R-devel)`, `windows (R-devel)`, `macos
(R-devel)` **only** — no `clang-asan`, `clang-ubsan`, `gcc-asan`, or
`valgrind`/`rchk`. `git diff --stat a2695a788 cc4f5baee -- src/` confirms
`src/drmTMB.cpp` genuinely changed in this candidate's history, so this is not
a cosmetic gap: the compiled likelihood code that changed has **never** been
sanitizer-checked. The only run that ever ran sanitizers at all,
`31195195196`, is pinned to the superseded pre-repair 0.6.0 artifact
(`744b9fbe`) and **failed** (rchk failure, valgrind cancelled). Closing this
gap (Option (c) below) is not an incremental hash upgrade over win-builder —
it is the only source of sanitizer evidence this package has ever had for its
current compiled code.

## 3. Costed options

Durations are measured from `platform/gha-3os-matrix.md`, run `31195187084`
(the 0.6.0-era matrix, head `744b9fbe`) — used here only as the best available
timing evidence for this workflow's per-OS wall time, not as evidence about the
candidate itself. **Billing multipliers do not apply here**: `gh api
repos/itchyshin/drmTMB/actions/runs/31195187084/timing --jq .billable` and the
same call on the candidate-era run `31336312020` both return `total_ms: 0` for
every OS — this repository is public, so GHA minutes are free regardless of OS.
The relevant cost is **wall-clock time / attention**, not billed minutes, and
the three OS jobs run in parallel, so total wait is bounded by the slowest job
(~59 min), not the sum.

| OS | measured wall time | billed cost | notes |
| --- | --- | --- | --- |
| ubuntu-latest | 46.5 min | 0 (public repo) | |
| macos-latest | 31.7 min | 0 (public repo) | |
| windows-latest | 58.8 min | 0 (public repo) | |
| **3-OS matrix (parallel)** | **~59 min wall** | **0** | slowest job (windows) sets the wait |

R-hub's per-run wall time is not measured anywhere in this repo's evidence at
the exact candidate head (its own jobs list omits sanitizers, § 2); the
~6-hour figure below is from the one run that *did* include them,
`31195195196` (0.6.0-era, failed) — a **measurement of that run**, not an
estimate for a hypothetical re-run, but not necessarily representative of a
clean pass either.

| Option | Scope | Billed GHA cost | Wall time | Closes the win-builder gap? | Closes the sanitizer gap? | Satisfies Gate 6 literally? |
| --- | --- | --- | --- | --- | --- | --- |
| **(a) win-builder only** | Submit `a8f7c47905b0…` to win-builder R-release + R-devel; accept the `604016a5d`/`6dc48cd94` GHA/R-hub runs as content-equivalent | 0 | 0 (async email) | yes | no | no — GHA/R-hub remain content-equivalence, not literal-hash |
| **(b) win-builder + fresh 3-OS at the exact candidate head** | (a) + a `workflow_dispatch` GHA 3-OS run dispatched at `cc4f5baee` (or current tip) | 0 (public repo) | ~59 min wall | yes | no | yes, for GHA; R-hub still content-equivalence unless also re-run |
| **(c) full re-run incl. R-hub sanitizers** | (b) + R-hub (`clang-asan,clang-ubsan,gcc-asan,valgrind,rchk`) at the exact head | 0 (public repo) | ~59 min (GHA) + up to ~6 h (R-hub, per `31195195196`, unmeasured for a clean pass) | yes | yes | yes, fully literal |

**Recommendation: (b) now, (c) as the immediate next step, not a deferred
option.** With cost at zero, the only real trade left is wall-clock wait
against the ordering problem in §4: dispatching (b)/(c) before that ordering
question is resolved would validate platform behaviour for a head that is not
yet what actually ships. So the sequencing constraint is unchanged in kind —
fix §4 first — but the *reason* to hold is now purely "don't certify the wrong
head," not "this would spend real money." Once §4 is resolved, there is no
remaining reason to stop at (a); (c) buys the only sanitizer evidence this
package has ever had for its current C++, for the same zero billed cost.

## 4. Why ordering still matters — same problem, different reason to fix it first

From the S2b findings (`scratchpad/S2b-findings-for-S5.md`, established this
session): the candidate lineage that would need a fresh 3-OS/R-hub run is entangled
with unrelated, unmerged, uncertified work.

- **PR #959** (`claude/07-release-slice`) is **draft** and **CONFLICTING**. It
  carries 63 changed files including a compiled C++ likelihood change
  (`offset_mu` added to ~10 model branches in `src/drmTMB.cpp`), new
  `offset()` admission logic, new bootstrap-boundary diagnostics
  (`R/profile.R`), and a new `check_drm()` diagnostic row (`R/check.R:895-928`).
  (Correction: the original claim that this chain "never had CI run on any
  commit" does not survive scrutiny at the repo level — see Corrections item 2
  — but no CI is specifically confirmed on PR #959's own chain; treat that
  narrower claim as unverified rather than repeating the broader false one.)
- Its ancestor, **PR #958** (`claude/offset-univariate-families`, byte-identical
  `R/drmTMB.R`, SHA-256 `d332fc8f81cf40c9…`), is the properly-scoped home for that
  work (NEWS, docs, vignette, tests) but its **only CI signal is a failure**
  (run `31326708435`, ubuntu-latest). The failure is two capability-ledger Python
  tests (`test_c14_receipt_equivalence_keeps_raw_sources_separate`,
  `test_c17_c14_bridge_is_current_source_and_fail_closed`) — diagnosed as a
  **stale C17/C14 fingerprint** on that branch (the same tests pass on
  `origin/main`), with a documented remedy already on `main`
  (`tools/run-lane-c-c17c1-c14-model15-compatibility.R`; "remedy a C17
  fingerprint break by **re-running**... never by re-pinning"). **This is a
  foreign lane — report, do not fix, here.**
- Rebase cost to reconcile is small: `git merge-tree` shows exactly one
  conflicting file, `docs/dev-log/check-log.md` (both sides append dated entries
  at the top — a textbook keep-both resolve), and main is only 2 commits ahead.
  That conflict count will grow by one when `claude/d117-discharge` (PR #974,
  also appends to `check-log.md`) lands.
- Five vignettes silently move to `vignettes/articles/` on this lineage and are
  now executed by **nothing** — not `R CMD check`, not a test, not any CI job
  (grep of `.github/`, `tests/`, `tools/` found zero references). `figure-gallery.Rmd`
  alone is ~92 KB of plotting code no longer run by anything.

**Consequence:** dispatching (b) or (c) now would validate platform behaviour
for a head whose feature-ancestor's only CI signal is a failure, and whose
draft descendant's own CI status is unverified. That is wasted *wait*, not
wasted money, but it is still the wrong order. **Cheap ordering:** re-run the
C17/C14 fingerprint check on #958 → resolve the single `check-log.md` conflict
→ get ubuntu-only CI green on the reconciled chain (~46.5 min wall, zero
billed cost either way) → *then* dispatch (b)/(c) at the head actually worth
certifying.

## 5. What else the owner should know

- **The two CRAN NOTEs are already fixed on the candidate lineage itself —
  `claude/07-cran-notes` is redundant, not a prerequisite.** `git show
  cc4f5baee:DESCRIPTION` (line 22) already reads `misspecification`, and `git
  show cc4f5baee:inst/WORDLIST` already exists. `git merge-tree
  $(git merge-base cc4f5baee origin/claude/07-cran-notes) cc4f5baee
  origin/claude/07-cran-notes` shows a genuine **conflict** in `DESCRIPTION`
  (both branches reworded the same sentence differently) plus divergent
  `NEWS.md` and `R/julia-bridge.R` content. Recommend **withdrawing**
  `claude/07-cran-notes` rather than merging it — merging would reintroduce a
  conflict against text the candidate already fixed. Separately, note for any
  future NOTE-fix attempt: `inst/WORDLIST` is **never read** by CRAN-incoming
  spell checking (zero hits for the literal string `"WORDLIST"` across the
  `tools`/`utils` namespaces; only `.aspell/defaults.R` overrides
  dictionaries) — win-builder had already flagged `centile (23:43)` and
  `uncalibrated (24:6)` regardless of the WORDLIST entry.
- **`PLATFORM-NOT-READY.md` misattributes its own evidence.** Its matrix table
  lists GHA run `31195187084` and R-hub run `31195195196` alongside the
  win-builder-**fixed** rows, but both GHA/R-hub runs are pinned to head
  `744b9fbeec22…`, which `git merge-base --is-ancestor` confirms is **strictly
  before** the CondExp repair commit `25e38cc74` (per `HASH-LEDGER.md` row
  `f9b9588e…`). The GHA/R-hub greens in that table belong to the **pre-repair**
  state, not the fixed tarball. Flagging this, not editing that file — it is
  historical evidence, and the misattribution is now on record here and in the
  ledger.
- **A local 1-NOTE pass has already been shown insufficient once.** The 3rd
  candidate `d04d0e88…` passed the identical local `--as-cran --run-donttest`
  check at 1 NOTE and was still invalidated: an adversarial audit found `NEWS.md`
  never disclosed that five vignettes stop shipping in the tarball
  (`HASH-LEDGER.md` row `d04d0e88…`, `SUPERSEDED`). A clean local check on the
  current candidate is not, by itself, grounds to skip independent review before
  spending on platform evidence.
- **No time pressure.** The CRAN submit UI is offline until ~2026-08-19
  (`PLATFORM-NOT-READY.md` line 66), and submission timing is a deliberate later
  decision (D-89), not a default-to-now one. There is no reason to rush option
  (b)/(c) ahead of the ordering fix in §4 — but there is also no cost reason
  left to hold once §4 is fixed, since Actions minutes on this repo are free.

## What this packet does NOT authorize

This document prices options; it does not itself:

- advance ledger `status_claim` toward `platform-clean`, `submission-ready`, or
  any later rung;
- merge PR #958, #959, or `claude/07-cran-notes` into any release lineage;
- bump `DESCRIPTION` to 0.7.0;
- dispatch any GHA workflow, submit to win-builder, or upload to CRAN;
- resolve the #958 C17/C14 fingerprint or the `check-log.md` conflict (both are
  named as the recommended next cheap step, not executed here).

All of the above remain the owner's explicit calls. The owner has already
authorised spending on the platform matrix in general; this packet's job is
sequencing and honesty about cost, not permission.
