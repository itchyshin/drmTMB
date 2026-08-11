# Session handoff — drmTMB 0.7.0: the candidate is frozen, evidenced, and waiting on you

Meta: 2026-08-10 · from Claude to a fresh Claude session · **the committed repository is authoritative;
the authoring chat is gone.**

> **Filename note.** Deliberately *not* `2026-08-10-claude-handover.md` — that path is already taken on
> `main` by the 0.7.0-readiness lane, and `2026-08-10-arcd-mspl-evidence-handover.md` by the MSPL lane.
> A third collision on the same date has already caused real ambiguity in this repo twice.

Read `AGENTS.md`, then this file, then
[`../release/0.7.0-cran-gate/RUNG-REPORT-0.7.0.md`](../release/0.7.0-cran-gate/RUNG-REPORT-0.7.0.md).
Classify every item below `OWED`, `DONE`, `RETRACTED`, or `PROTECTED` against live git and GitHub state
before acting.

## Goal

Produce drmTMB's **first CRAN release as 0.7.0** (D-86) under D-49's fail-closed rung ladder: never say
"CRAN ready" — always report the **highest proven rung and the next unproven one**. D-89 sets the pace:
submission is far away *by choice*, and the CRAN portal is offline until ~2026-08-19.

## Where this stands

**A 0.7.0 candidate now exists, with platform evidence that describes it.** Before today there was none:
`DESCRIPTION` was `0.6.0` and the only frozen artifact was `drmTMB_0.6.0.tar.gz` at `ad475cc39`, 47
commits stale, whose platform logs had quietly stopped describing anything real.

| field | value |
| --- | --- |
| tarball | `drmTMB_0.7.0.tar.gz` |
| SHA-256 | `2176e4b81b887e8d944456e4a74fa581afda959d0d2a5468c89bc700d693cda9` |
| size | 9,925,713 bytes |
| commit | `a75c3c9013e1e7c4ab8e56aa13baf5e668b99c76` (cut from `main` `6065b90e5`) |
| inventory | 937 paths · forbidden-path scan **empty** · worktree clean at build |
| PR | **#996 OPEN** |

**Still current as of writing.** `main` has advanced to `60459cfaa`, but every commit since the cut
touches **only `docs/dev-log/`** — `git diff --name-only 6065b90e5 origin/main | grep -v '^docs/dev-log/'`
returns **zero**. So the candidate still represents `main`'s shipped source exactly. **Re-verify this
before trusting it**; it is the first thing that will go stale.

### Evidence, every class against this artifact

| class | verdict |
| --- | --- |
| local `R CMD check --as-cran --run-donttest` | **1 NOTE** (`New submission`), 0 ERROR, 0 WARNING |
| 3-OS ubuntu / macOS / windows | **success ×3** (run `31435894784`) |
| clang-asan / clang-ubsan / gcc-asan | **success ×3** (run `31435909361`) |
| rchk | failure → **NOISE**; all findings in `TMB/include/tmb_core.hpp`, none in `drmTMB.cpp` |
| valgrind, 7-file subset (Totoro) | **0 errors from 0 contexts, 0 bytes lost**, 1,653 assertions |
| **win-builder** | **ABSENT — owner action** |

**Highest proven rung: `tarball-clean`. Next unproven: `platform-clean`.**

## Next immediate steps

1. **Confirm the candidate is still current** (above). If a shipped file has changed, **re-freeze** —
   do not patch the existing candidate. `scratchpad/freeze-ready.sh` gates the cut point; `freeze.sh`
   performs it.
2. **#996 needs review and a merge decision.** Do not auto-merge.
3. **#992** (`claude/pre-freeze-hygiene`) — one-line stray-conflict-marker fix, still open.
4. **win-builder — owner action.** The agent upload path is classifier-blocked. This is the only
   evidence class with no run against this candidate, and it is the one that would measure the
   **Windows CRAN-lane time**, which remains **unmeasured** (see below).
5. **`cran-comments.md` is stale** — it cites `8df6f2402` (77+ commits back) and says the package "is
   still on the `0.6.0` development cycle". It must be rewritten against `2176e4b8…cda9` before
   submission.

## Blockers / open questions — owner's, not the agent's

- **Advancing `status_claim` to `platform-clean`** — D-49, and the predecessor `FREEZE-NOTES.md` states
  the next rung requires explicit authorisation before any ledger write.
- **Submission timing** — D-89; portal offline until ~2026-08-19 regardless.
- **What ships in 0.7.0.** The cut includes `offset()` (#958) and the MSPL internals (which export **no**
  symbols — internal only). Anything merged after `6065b90e5` is 0.7.1 unless a re-freeze moves the line.

## Gotchas — each of these cost real time today

- **Windows `[48m]` in CI does NOT measure the CRAN lane.** `.github/workflows/R-CMD-check.yaml:56` sets
  `NOT_CRAN: true`, so CI runs the **full** suite including the 17 files PR #990 filters. Only
  win-builder runs `NOT_CRAN=false` on Windows. **Windows CRAN-lane time is UNMEASURED**; the ~11 min
  figure is a projection.
- **Never check liveness with a pattern that can match its own command.** `pgrep -f vg-suite.R` over ssh
  matches the ssh wrapper carrying that string, and reported "alive" about a process that had SIGSEGV'd
  five hours earlier. **Use log mtime plus a real process check.**
- **Julia's precompilation cache SIGSEGVs under valgrind** (`ijl_throw` → `julia_unlink` →
  `julia_compilecache`, `loading.jl:3306`). Any valgrind subset must exclude Julia-initialising tests —
  `test-binomial-response.R` is the one in the C++-heavy set. Excluding Julia removed **every** finding.
- **Cite valgrind as "clean on a documented subset", never "valgrind clean."** The full suite is what
  exceeded six hours.
- **Ubuntu's second NOTE is `jl_*` temp detritus** and appears only under `NOT_CRAN=true`. The CRAN lane
  returns 1 NOTE; CRAN would not see it. Ubuntu's `105.2Mb` installed size is an unstripped GHA debug
  build reported as INFO — the real size is **31 MB**.
- **A superseded number:** an earlier local→Windows factor of **1.50×** was wrong — it compared a
  `testthat::test_local()` profiling run against win-builder's `R CMD check`, two different harnesses.
  Like-for-like it is **≈2.9×**. It landed near the same answer by coincidence.
- **A withdrawn finding:** `inst/COPYRIGHTS` citing `R/crs.R` is **not** a defect. That names the
  *upstream gllvmTMB* baseline "at that exact commit"; gllvmTMB has both `R/mesh.R` and `R/crs.R`.
  **Do not "fix" it.**
- **A freeze taken while lanes are merging is stale on arrival.** The first candidate (`d1c7b4f0…bc2b`,
  PR **#994, CLOSED/retired**) went stale in three hours when #986/#958/#991/#993 landed mid-measurement.
  Use `scratchpad/freeze-ready.sh` — three conditions, not one.
- **The C17 ledger gate fires on any change to five pinned files** (`R/drmTMB.R`, `R/methods.R`,
  `src/drmTMB.cpp`, `tests/testthat/test-zero-one-beta.R`, the model-15 runner). Re-certification is
  **owner-gated**; `claim_boundary` in the manifest is free text that **no automated check validates** —
  a human must read that column.

## Landing state

| artifact | committed | pushed | state |
| --- | --- | --- | --- |
| `claude/07-candidate-freeze-2` @ `c8c840e81` → **#996** | yes | yes | **ACTIVE** — the candidate |
| `claude/pre-freeze-hygiene` @ `e2478c5a2` → **#992** | yes | yes | **ACTIVE** — marker fix |
| `claude/cran-lane-test-budget` → **#990** | yes | yes | **MERGED** `c91d62b21` |
| `claude/07-candidate-freeze` @ `d30e58e16` → #994 | yes | yes | **RETIRED** — PR closed; branch kept for the record, do not revive |
| Tarball bytes | n/a | n/a | `/private/tmp/drmTMB-07-freeze2/` (local) and `~/drmTMB_0.7.0_cand2.tar.gz` on Totoro, hash re-verified |
| Candidate-1 valgrind log | n/a | n/a | archived on Totoro: `~/drm07/vg-suite-candidate1-FINAL.log` |
| **~12 foreign branches with unpushed commits** (`codex/lane-c-provider-cohort-20260729` **99**, …) | mixed | no | **CARRIED-OVER · PROTECTED FOREIGN** — pre-existing, not this session's. Do **not** push, clean, or reconcile |
| PRs #959, #955, #858 | — | — | **PROTECTED FOREIGN** |
| Stale `.git/index.lock` | — | — | **REPORT ONLY** — needs a human `rm`; the harness blocks `.git` deletions |

`tools/handoff_gate.sh` returns **GATE FAIL**, entirely from the foreign branches and the lock above.
Declared here per the protocol. **This session's own lanes are committed and pushed.**

## Live environment

Work in a fresh worktree off `origin/main`. **Never the primary checkout** —
`/Users/z3437171/Dropbox/Github Local/drmTMB` is on a stale July branch and is PROTECTED.

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e '...'   # the .Rprofile R-4.5 lib segfaults R 4.6
python3 -B tools/capability_ledger.py --check              # expect OK (31 generated outputs)
python3 -m unittest tools.tests.test_capability_ledger     # expect 66 tests OK
bash scratchpad/freeze-ready.sh                            # 3-condition freeze gate
```

Totoro reachable through its existing ControlMaster (`ls ~/.ssh/cm-*totoro*`); no Duo needed. Pin
`OPENBLAS_NUM_THREADS=1`. **Do not stage** anything under `scratchpad/` you did not create, or any
foreign branch's work. Never `git add -A`.

## How to resume

```sh
bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/drmTMB"
git fetch origin && git diff --name-only 6065b90e5 origin/main | grep -v '^docs/dev-log/'   # empty => candidate still current
gh pr checks 996; gh pr view 996
```

---

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-10-070-candidate-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
