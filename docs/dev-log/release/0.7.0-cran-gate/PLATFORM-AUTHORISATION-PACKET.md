# drmTMB 0.7.0 — platform authorisation packet

**Written by:** Rose (systems auditor) · **Date:** 2026-08-09
**Reads:** `HASH-LEDGER.md` (Grace), S2b findings (scratchpad), `~/shinichi-brain/protocols/cran-release-gate.md`
Gate 6, `platform/PLATFORM-NOT-READY.md`.

> **No rung claim is made or implied by this document.** This packet prices options for
> one owner decision; it does not advance `status_claim`, merge anything, bump
> `DESCRIPTION`, or authorize upload.

---

## DECISION REQUESTED

**Spend GitHub Actions minutes on a fresh platform matrix for the current 0.7.0
candidate (`a8f7c47905b0…`, source `cc4f5baee`) now, or hold?**

**Recommended answer: hold, and take Option (a) win-builder-only now (0 billed
minutes) while fixing the #958 fingerprint and getting ubuntu-only CI green on the
release-slice chain — then revisit (b)/(c).** No time pressure forces a decision:
the CRAN portal is offline until ~2026-08-19 (`PLATFORM-NOT-READY.md` line 66) and
submission is a deliberate later step (D-89), so there is room to sequence cheap
before expensive.

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
at `604016a5d` — 904 entries, **zero** matching `docs/` or `AGENTS.md`.

So: the source tree GHA/R-hub actually built at `604016a5d` is **identical after
build exclusions** to the candidate's shippable content.

**What this does NOT establish.** `R CMD build` embeds build timestamps and file
mtimes, so rebuilding identical source content does not reproduce an identical
tarball byte-for-byte; there is no literal-hash match between what GHA/R-hub built
and the frozen `a8f7c47905b0…` tarball, and none is claimed. Gate 6 asks "which
hash did each service test" — the honest answer here is **strong content-equivalence
of a rebuild, not this literal tarball.** Accepting that as satisfying Gate 6 is a
judgement call for the owner, not a fact this document can assert on its own.

## 2. The genuine gap

**No win-builder submission exists for this candidate at any level.** Every
win-builder log under `docs/dev-log/release/0.7.0-cran-gate/platform/` belongs to
0.6.0 predecessor artifacts (`c787ee40…` unrepaired, `f9b9588e…` CondExp-fixed) —
confirmed in `HASH-LEDGER.md` rows for those hashes and in the ledger's own
`604016a5d` note ("No win-builder run exists for this candidate"). win-builder is
**free** (submitted by email, no Actions minutes) — the gap costs nothing to close
but has not been closed.

## 3. Costed options

Durations are measured from `platform/gha-3os-matrix.md`, run `31195187084` —
**a different run/commit (`744b9fbe`, the 0.6.0-era matrix) than the
content-equivalence run (`604016a5d`)**, used here only as the best available
timing evidence for this workflow's per-OS cost, not as evidence about the
candidate itself. GitHub Actions billing multiplies wall time by OS: macOS ×10,
Windows ×2, Ubuntu ×1.

| OS | measured wall time | multiplier | billed minutes |
| --- | --- | --- | --- |
| ubuntu-latest | 46.5 min | ×1 | 46.5 |
| macos-latest | 31.7 min | ×10 | 317.0 |
| windows-latest | 58.8 min | ×2 | 117.6 |
| **3-OS total** | | | **≈481** |

R-hub's per-run billed cost is not measured anywhere in this repo's evidence; the
~150-minute figure below is an **inference** (valgrind/rchk historically run long
on this package — `rhub-rchk-adjudication.md`, `PLATFORM-NOT-READY.md` matrix),
not a measurement.

| Option | Scope | Billed GHA minutes | Closes the win-builder gap? | Satisfies Gate 6 literally? |
| --- | --- | --- | --- | --- |
| **(a) win-builder only** | Submit `a8f7c47905b0…` to win-builder R-release + R-devel; accept the `604016a5d` GHA/R-hub runs as content-equivalent | **0** | yes | no — GHA/R-hub remain content-equivalence, not literal-hash |
| **(b) win-builder + fresh 3-OS at the exact candidate head** | (a) + a `workflow_dispatch` GHA 3-OS run dispatched at `cc4f5baee` (or current tip) | ~481 | yes | yes, for GHA; R-hub still content-equivalence unless also re-run |
| **(c) full re-run incl. R-hub** | (b) + R-hub (`clang-asan,clang-ubsan,gcc-asan,valgrind,rchk`) at the exact head | ~600–750 (481 + ~150 R-hub, inferred) | yes | yes, fully literal |

**Recommendation: (a) now.** It closes the only evidence gap that costs nothing to
close and does not foreclose (b)/(c) later. Spending on (b) or (c) before the
ordering problem in §4 is resolved would spend real money against a branch state
that is not yet the one the owner will actually ship.

## 4. Why any spend is premature right now — the ordering problem

From the S2b findings (`scratchpad/S2b-findings-for-S5.md`, established this
session): the candidate lineage that would need a fresh 3-OS/R-hub run is entangled
with unrelated, unmerged, uncertified work.

- **PR #959** (`claude/07-release-slice`) is **draft**, **CONFLICTING**, and has
  **never had CI run on any commit in its chain** (`gh pr checks` → "no checks
  reported"). It carries 63 changed files including a compiled C++ likelihood
  change (`offset_mu` added to ~10 model branches in `src/drmTMB.cpp`), new
  `offset()` admission logic, new bootstrap-boundary diagnostics
  (`R/profile.R`), and a new `check_drm()` diagnostic row (`R/check.R:895-928`).
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

**Consequence:** authorizing ~481–750 billed minutes now would spend it validating
platform behaviour for a head whose feature-ancestor's only CI signal is a
failure, and whose C++ likelihood changed with zero CI ever run on it. **Cheap
ordering:** re-run the C17/C14 fingerprint check on #958 → resolve the single
`check-log.md` conflict → get ubuntu-only CI green on the reconciled chain
(~46.5 min, ×1 rate) → *then* decide whether (b) or (c) is worth the larger spend,
on a head actually worth certifying.

## 5. What else the owner should know

- **Two CRAN NOTEs are already fixed, but on the wrong lineage to help.**
  `claude/07-cran-notes` (commit `a51481059`, branch parent `a2695a788` — **main**,
  not the candidate lineage) fixes the DESCRIPTION spelling NOTE
  (`mis-specification`→`misspecification`, a genuine typo; `centile`/`uncalibrated`
  added to `inst/WORDLIST`) and the vignette PNG file-URI NOTE
  (`vignettes/.install_extras` gains `\.png$` so `function-map-cheatsheet.png`
  installs next to its HTML). These fixes need to reach the candidate lineage
  before they help any actual submission — a merge-order question for the owner,
  not something this packet resolves.
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
  (b)/(c) ahead of the ordering fix in §4.

## What this packet does NOT authorize

This document prices options; it does not itself:

- advance ledger `status_claim` toward `platform-clean`, `submission-ready`, or
  any later rung;
- merge PR #958, #959, or `claude/07-cran-notes` into any release lineage;
- bump `DESCRIPTION` to 0.7.0;
- dispatch any GHA workflow, submit to win-builder, or upload to CRAN;
- resolve the #958 C17/C14 fingerprint or the `check-log.md` conflict (both are
  named as the recommended next cheap step, not executed here).

All of the above remain the owner's explicit calls.
