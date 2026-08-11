# drmTMB 0.7.0 — rung report

Written 2026-08-10 against the 0.7.0 candidate. **Reported, not claimed:** advancing `status_claim`
is the owner's decision under D-49, and nothing here has been uploaded.

## The artifact every claim below refers to

| field | value |
| --- | --- |
| tarball | `drmTMB_0.7.0.tar.gz` |
| SHA-256 | `2176e4b81b887e8d944456e4a74fa581afda959d0d2a5468c89bc700d693cda9` |
| size | 9,925,713 bytes |
| commit | `a75c3c9013e1e7c4ab8e56aa13baf5e668b99c76` (cut from `main` `6065b90e5`) |
| inventory | 937 paths · forbidden-path scan **empty** |
| worktree at build | clean (verified before build) |
| installed size | 31 MB |

**The cut point was chosen, not stumbled into.** A freeze-readiness check had to pass three conditions
before the build: no shipped-file change on `main` for 60 minutes; no green *and* mergeable PR queued
to land; and `main`'s own CI green on that exact head (run `31432012280`). The third matters because a
quiet window alone is not enough — a green mergeable PR means `main` is one click from moving.

This cut therefore **includes `offset()` (#958) and the MSPL internals**, which a predecessor candidate
did not.

## Evidence, per class — all on this artifact

| class | verdict | applies to this candidate? |
| --- | --- | --- |
| local `R CMD check --as-cran --run-donttest` | **Status: 1 NOTE** (`New submission` only), 0 ERROR, 0 WARNING | **CURRENT** |
| 3-OS ubuntu-latest | **success** | **CURRENT** |
| 3-OS macos-latest | **success** | **CURRENT** |
| 3-OS windows-latest | **success** | **CURRENT** |
| R-hub clang-asan | **success** | **CURRENT** |
| R-hub clang-ubsan | **success** | **CURRENT** |
| R-hub gcc-asan | **success** | **CURRENT** |
| R-hub rchk | job failure → **adjudicated NOISE** | **CURRENT** |
| valgrind, 7-file subset (Totoro) | **0 errors, 0 bytes lost** | **CURRENT** |
| **win-builder** | **ABSENT** | — |

Runs: 3-OS `31435894784` · R-hub `31435909361` · valgrind on Totoro, `valgrind-3.22.0`, R 4.5.3.

### valgrind — clean, and the first verdict this package has ever had

**No valgrind verdict existed for drmTMB at any commit before today.** The R-hub attempt was cancelled
at GitHub's 6-hour ceiling; `rhub-matrix.md` still records it as `in_progress`, which is wrong. Actions
cannot host it and D-50 bars campaigns there, so it ran on **Totoro** against the frozen tarball, whose
SHA-256 was re-verified on the far side as byte-identical before installation.

```
ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
definitely lost:   0 bytes in 0 blocks
indirectly lost:   0 bytes in 0 blocks
core dumps: 0
```

1,653 assertions, 0 failures, across seven files: `family-dpq-batchC`, `gaussian-random-intercepts`,
`count-structured-mu`, `score-consistency`, `nbinom2-location-scale`, `adequacy`, `phylo-gaussian`.

**This is a named seven-file subset, not the full suite** — the full suite is what exceeded six hours.
Cite it as *"clean on a documented subset"*, never as *"valgrind clean"*.

**Why this subset excludes `test-binomial-response.R`:** that file initialises Julia, and Julia's
precompilation cache **SIGSEGVs under memcheck** (`ijl_throw` → `julia_unlink` →
`julia_compilecache`, `loading.jl:3306`). A predecessor run died there. Excluding Julia did not merely
avoid the crash — it removed **every** finding: the predecessor's 22 errors and 26,633 lost bytes were
entirely Julia's runtime, which this run demonstrates by construction rather than by inspection.

### rchk — adjudicated from this run's log

The job fails. Every protection finding is inside **TMB's own header**:
`[UP] attempt to unprotect more items than protected` and `[PB] possible protection stack imbalance` at
`TMB/include/tmb_core.hpp:1241/1243, 1512/1515, 2275/2277`.

Three further lines carry no file path — `[UP] ignoring variable … as it has address taken, results
will be incomplete`. Those are rchk describing **its own analyser limitation**, not defects.

**Zero protection findings attributable to `drmTMB.cpp`.**

## Check time — fixed, and one part still unmeasured

`checking tests` on the **CRAN lane**, same harness throughout:

| | predecessor freeze | this candidate |
| --- | --- | --- |
| local `R CMD check --as-cran` | `[9m/10m]` | **`[203s/227s]`** |

A **2.7x** reduction from PR #990's filter in `tests/testthat.R` — and it holds on a *larger* package,
since this candidate carries `offset()` and ~1,500 more lines of MSPL than the one measured at 193s.

**The GitHub Actions Windows figure does not measure this.** The workflow sets **`NOT_CRAN: true`**
(`R-CMD-check.yaml:56`), so CI runs the **full** suite including the seventeen files the CRAN filter
excludes. It is a different lane by design.

**Therefore Windows CRAN-lane time is UNMEASURED for this candidate.** Only win-builder runs
`NOT_CRAN=false` on Windows, and that class is absent. The projection —
`3.8 min x 2.9 ≈ 11 min`, using a like-for-like factor from the predecessor's own logs — **remains a
projection**.

> A superseded figure, recorded so it is not reused: an earlier estimate used **1.50x**, obtained by
> comparing a `testthat::test_local()` profiling run against win-builder's `R CMD check` — two
> different harnesses. It landed near the same answer by coincidence, not corroboration.

## NOTEs, and which lane produces them

| lane | Status | second NOTE |
| --- | --- | --- |
| local `--as-cran` (CRAN lane) | **1 NOTE** | — |
| 3-OS macOS | 1 NOTE | — |
| 3-OS windows | 1 NOTE | — |
| 3-OS ubuntu | **2 NOTEs** | `checking for detritus in the temp directory` |

- **`New submission`** appears on every lane and is unavoidable for a first submission.
- **The detritus NOTE is `jl_*` Julia temp directories**, and it appears **only on ubuntu**, where
  `NOT_CRAN=true` runs the full suite and initialises Julia. The **CRAN lane returned 1 NOTE**, so
  **CRAN would not see it.** It is a repository-CI artifact, not a submission blocker — and it is the
  only thing the long-proposed "Julia CI fix" would ever have addressed.
- Ubuntu additionally reports a large `installed size` as **INFO**, an unstripped GHA debug build. The
  real installed size from the local check is **31 MB**.

## Gate 1 — rights and product contract

**SHIP 4 · EXCLUDE 0 · UNRESOLVED 2.** No undocumented borrowing, no consent gap, no undocumented data
provenance. `License: GPL (>= 3)` linking TMB (`GPL-2`) follows `glmmTMB` (`AGPL-3`,
`LinkingTo: TMB`), which is on CRAN — verified by inspection, not asserted.

> A withdrawn finding: an earlier draft flagged `inst/COPYRIGHTS` for citing a "phantom" `R/crs.R`.
> **Wrong.** That citation names the *upstream gllvmTMB* baseline "at that exact commit", and gllvmTMB
> has both `R/mesh.R` and `R/crs.R`. The record is correct and must not be "fixed".

## The rung

**Highest proven: `tarball-clean`.** One identified artifact, clean-worktree build, forbidden-path scan
proven empty from the tarball itself, and a clean real-CRAN-lane check.

**Next unproven: `platform-clean`.**

What now supports it, all against **this** artifact: 3-OS green on all three platforms, all three
sanitizers green, rchk adjudicated to noise, and a **clean valgrind verdict** — the first this package
has ever had. Previously every platform log described `744b9fbe` or `25e38cc74`, both predecessors.

What still stands between here and a `platform-clean` claim:

1. **win-builder — ABSENT.** No run against this candidate. The agent upload path is classifier-blocked; this one is the owner's to run.
2. **valgrind is a documented subset**, not the full suite.
3. **Windows CRAN-lane timing — UNMEASURED**, per above.
4. **Owner authorisation.** D-49 reserves the rung claim, and the predecessor `FREEZE-NOTES.md` states the next rung requires explicit authorisation before any ledger write.

**Nothing has been uploaded, and no `status_claim` has been written.**

## Reproduce

```sh
git checkout a75c3c9013e1e7c4ab8e56aa13baf5e668b99c76
R CMD build --no-manual .
shasum -a 256 drmTMB_0.7.0.tar.gz     # 2176e4b8...cda9
_R_CHECK_CRAN_INCOMING_=true R CMD check --as-cran --run-donttest --no-manual drmTMB_0.7.0.tar.gz
```

`R CMD build` embeds timestamps, so a rebuild will not reproduce these bytes; content equivalence is
established by the source commit, not by re-deriving the hash.
