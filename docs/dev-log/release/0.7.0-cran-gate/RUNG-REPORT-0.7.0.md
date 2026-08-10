# drmTMB 0.7.0 — rung report

Written 2026-08-10 against the first 0.7.0 candidate. **Reported, not claimed:** advancing
`status_claim` is the owner's decision under D-49, and nothing here is a submission.

## The artifact every claim below refers to

| field | value |
| --- | --- |
| tarball | `drmTMB_0.7.0.tar.gz` |
| SHA-256 | `d1c7b4f0ef819512a6c9470958f9168579404cbf72f5edbe173cc95cdb06bc2b` |
| size | 9,873,999 bytes |
| build commit | `9490576466bfce4cb2bb952bd15993f6aff48d4b` |
| evidence commit | `6b4307254fa4847bfef2ccfdedc2d9a9c3f9d0b5` |
| inventory | 929 paths · forbidden-path scan **empty** |
| worktree at build | clean (verified) |

**Why two commits.** The tarball was built at `9490576466`; CI evidence ran at `6b4307254`. The diff
between them is **five `docs/dev-log/` files only** — the freeze receipts — and `docs/dev-log` is
proven absent from the tarball by the forbidden-path scan. The two commits are therefore
package-identical, and evidence at `6b4307254` describes the shipped bytes of `d1c7b4f0…bc2b`.

**This is the first drmTMB 0.7.0 artifact that has ever existed.** The previous freeze was
`drmTMB_0.6.0.tar.gz` at `ad475cc39` — 47 commits and 2,210 changed lines behind current `main`.

## Evidence, per class

| class | verdict | describes this candidate? |
| --- | --- | --- |
| local `R CMD check --as-cran --run-donttest` | **Status: 1 NOTE** (`New submission` only), 0 ERROR, 0 WARNING | **CURRENT** |
| 3-OS ubuntu-latest | **success** — 2 NOTEs | **CURRENT** |
| 3-OS macos-latest | **success** — 1 NOTE | **CURRENT** |
| 3-OS windows-latest | **success** — 1 NOTE | **CURRENT** |
| R-hub clang-asan | **success** | **CURRENT** |
| R-hub clang-ubsan | **success** | **CURRENT** |
| R-hub gcc-asan | **success** | **CURRENT** |
| R-hub rchk | job failure → **adjudicated NOISE** | **CURRENT** |
| valgrind (Totoro) | **PARTIAL** — 4 of 6 files, 0 drmTMB findings | **CURRENT**, incomplete |
| **win-builder** | **ABSENT** | — |

Runs: 3-OS `31409204450`; R-hub `31409243076`; valgrind on Totoro, `valgrind-3.22.0`.

### rchk — adjudicated, not inherited

The job fails, and every finding is inside **TMB's own header**:
`[UP] attempt to unprotect more items than protected` and `[PB] possible protection stack imbalance`
at `TMB/include/tmb_core.hpp:1241/1243, 1512/1515, 2275/2277`. **Zero findings in `drmTMB.cpp`.**
A prior adjudication reached the same conclusion for an older commit; this one was re-derived from
this run's log rather than carried forward.

### valgrind — PARTIAL, and a first for this project

**No valgrind verdict has ever existed for drmTMB at any commit.** The previous attempt (R-hub job
`92921626041`) was **cancelled at GitHub's 6-hour ceiling**; `rhub-matrix.md` still records it as
`in_progress`, which is wrong. Actions structurally cannot host it, and D-50 bars campaigns there
anyway — so it was run on **Totoro** against the frozen tarball, whose SHA-256 was re-verified on the
far side as byte-identical before installation.

Complete so far — `memcheck`, `--track-origins=yes`, `--errors-for-leak-kinds=definite`:

| file | result |
| --- | --- |
| `test-family-dpq-batchC.R` | 122 pass, 0 fail |
| `test-gaussian-random-intercepts.R` | 429 pass, 0 fail |
| `test-count-structured-mu.R` | 533 pass, 0 fail |
| `test-score-consistency.R` | 17 pass, 0 fail |
| `test-binomial-response.R` | **in flight** |
| `test-nbinom2-location-scale.R` | **not started** |

**6 memcheck findings, and all 6 are Julia's runtime, not drmTMB** — 4 × conditional-jump-on-
uninitialised plus 2 invalid reads, every one tracing to `jl_gc_alloc_`, `jl_genericmemory_to_string`,
`gc-stock.c`, `loading.jl`. **Zero findings in drmTMB, TMB, CppAD or Eigen.** All six were checked
individually.

**Two honest limits.** This is a **documented six-file subset**, not the full suite — the full suite is
what exceeded six hours. And it is **incomplete**: two files remain. It should be cited as
"partial clean on a named subset", never as "valgrind clean".

## Check time — what was fixed, and what is still unmeasured

`checking tests` on the **CRAN lane**, measured on the same harness:

| | predecessor freeze | this candidate |
| --- | --- | --- |
| local `R CMD check --as-cran` | `[9m/10m]` | **`[193s/221s]`** |

A **2.7x** reduction, from PR #990's filter in `tests/testthat.R`.

**The GitHub Actions Windows figure does NOT measure this.** That job logs
`Running 'testthat.R' [48m]`, but the workflow sets **`NOT_CRAN: true`** (`R-CMD-check.yaml:56`), so CI
runs the **full** suite — including phase18 and the seventeen files the CRAN filter excludes. It is a
different lane, by design. It neither confirms nor refutes the CRAN budget.

**Therefore Windows CRAN-lane time is UNMEASURED for this candidate.** Only win-builder runs
`NOT_CRAN=false` on Windows, and that class is absent. The projection — `3.7 min × 2.9 ≈ 10.7 min`,
using a like-for-like factor from the predecessor's own logs — **remains a projection**.

> A superseded figure, recorded so it is not reused: an earlier estimate used **1.50x**, derived by
> comparing a `testthat::test_local()` profiling run against win-builder's `R CMD check` — two
> different harnesses. It landed near the same answer by coincidence, not corroboration.

## NOTEs, and which lane produces them

- **`New submission`** — on every lane. Unavoidable for a first submission.
- **`checking for detritus in the temp directory`** (`jl_4Jklt5`, `jl_RiRFxH`, …) — ubuntu's second
  NOTE. It appears **only under `NOT_CRAN=true`**, where the full suite initialises Julia. The local
  CRAN-lane check returned **1 NOTE**, so **CRAN would not see this**. It is a repository-CI artifact.
- Ubuntu also reports `installed size 105.2Mb` as **INFO** (libs 88.4Mb) — an unstripped GHA debug
  build. The real installed size from the local check is **31 MB**.

## Gate 1 — rights and product contract

**SHIP 4 · EXCLUDE 0 · UNRESOLVED 2.** No undocumented borrowing, no consent gap, no undocumented data
provenance. `License: GPL (>= 3)` linking TMB (`GPL-2`) follows `glmmTMB` (`AGPL-3`, `LinkingTo: TMB`),
which is on CRAN — verified by inspection.

> A withdrawn finding: an earlier draft flagged `inst/COPYRIGHTS` for citing a "phantom" `R/crs.R`.
> **Wrong.** That citation names the *upstream gllvmTMB* baseline "at that exact commit", and gllvmTMB
> has both `R/mesh.R` and `R/crs.R`. The record is correct and must not be "fixed".

## The rung

**Highest proven: `tarball-clean`** — one identified artifact, clean-worktree build, empty
forbidden-path scan proven from the tarball, and a clean real-CRAN-lane local check.

**Next unproven: `platform-clean`.**

What now supports it that did not exist this morning: 3-OS green on all three platforms, three
sanitizers green, rchk adjudicated, and a partial valgrind result — **all against this candidate**,
where previously every platform log described `744b9fbe` or `25e38cc74`, both predecessors.

What still blocks a `platform-clean` claim:

1. **win-builder — ABSENT.** No run against this candidate. The agent upload path is classifier-blocked; this is the owner's to run.
2. **valgrind — PARTIAL.** Two files outstanding, and the subset is documented rather than exhaustive.
3. **Windows CRAN-lane timing — UNMEASURED**, per above.
4. **Owner authorisation.** D-49 reserves the rung claim, and the predecessor `FREEZE-NOTES.md` states the next rung requires explicit authorisation before any ledger write.

**Nothing has been uploaded, and no `status_claim` has been written.**

## Reproduce

```sh
git checkout 9490576466bfce4cb2bb952bd15993f6aff48d4b
R CMD build --no-manual .
shasum -a 256 drmTMB_0.7.0.tar.gz     # d1c7b4f0...bc2b
_R_CHECK_CRAN_INCOMING_=true R CMD check --as-cran --run-donttest --no-manual drmTMB_0.7.0.tar.gz
```

`R CMD build` embeds timestamps, so a rebuild will not reproduce these bytes; content equivalence is
established by the source commit, not by re-deriving the hash.
