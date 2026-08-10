# Platform evidence at `bce9cfb6f` — 2026-08-09/10

**Dispatched** by Claude after Shinichi authorised the platform matrix (2026-08-09).
**No rung claim is made here.** This records what ran, at which SHA, and what it means. Advancing
`status_claim` to `platform-clean` remains the owner's, per D-49.

## Gate 6 — which hash each service tested

Both runs executed at **`bce9cfb6fd3707c90a31f1269ff4f915b8a092c4`** (tip of
`claude/07-release-slice`), **not** at the candidate's source `cc4f5baee`.

**Why this still covers the candidate's compiled code:** `git ls-tree <ref> src` returns the
identical tree hash **`a4a3138d808a394a4c3880f173373244e67d2247`** at `cc4f5baee`, `bce9cfb6f`, and
`origin/claude/07-release-slice`. The C++ that these runs compiled and exercised *is* the candidate's
C++. This is content-equivalence, **not** a literal tarball-hash match — `R CMD build` embeds
timestamps, so no rebuild reproduces the candidate's bytes.

## GitHub Actions 3-OS — run [31350779116](https://github.com/itchyshin/drmTMB/actions/runs/31350779116)

**`conclusion: success`.**

| job | result | wall |
| --- | --- | --- |
| `ubuntu-latest (release)` | **success** | 44m58s |
| `macos-latest (release)` | **success** | 31m53s |
| `windows-latest (release)` | **success** | 44m31s |

All three under the workflow's 75-minute ceiling. **Billed cost: zero** — the repository is public and
`/actions/runs/{id}/timing` returns `billable.{UBUNTU,WINDOWS,MACOS}.total_ms = 0`.

## R-hub sanitizer suite — run [31350780323](https://github.com/itchyshin/drmTMB/actions/runs/31350780323)

Dispatched precisely because **no sanitizer, valgrind or rchk coverage existed for this candidate at
any level** — the candidate-era R-hub run tested linux/windows/macos R-devel only.

| job | result | reading |
| --- | --- | --- |
| `clang-asan` | **success** | genuine clean pass on the candidate's `src` |
| `clang-ubsan` | **success** | genuine clean pass |
| `gcc-asan` | **success** | genuine clean pass |
| `valgrind` | **failure** | **infrastructural, not a memory defect** — see below |
| `rchk` | **failure** | **findings are in TMB's headers, not drmTMB** — see below |

### valgrind — the package never installed, so nothing was analysed

```
Error: .onLoad failed in loadNamespace() for 'TMB', details:
  error: unable to load shared object
  '/github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/libs/TMB.so'
ERROR: lazy loading failed for package 'drmTMB'
ERROR: package installation failed
##[error]Process completed with exit code 1.
```

`TMB.so` could not be loaded inside the R-hub valgrind container, so `drmTMB` never installed and
**valgrind never examined a single line of this package**. This is **not** evidence of a memory
defect — and equally, it is **not coverage**. The valgrind cell remains genuinely open, for the same
reason it has been open in every prior attempt (previously it was cancelled or left incomplete; this
is the first time it ran to a definite outcome, and the outcome is an environment failure).

### rchk — reproduces the prior noise adjudication, now at the candidate's `src`

Reported locations are inside **TMB's own framework headers**:

```
[UP] attempt to unprotect more items (4) than protected (3), results will be incomplete
     .../TMB/include/tmb_core.hpp:1512
[PB] has possible protection stack imbalance
     .../TMB/include/tmb_core.hpp:1515
ERROR: too many states (abstraction error?) in function strptime_internal
ERROR: too many states (abstraction error?) in function bcEval_loop
ERROR: too many states (abstraction error?) in function RunGenCollect
ERROR: too many states (abstraction error?) in function objective_function<double>::operator()()
```

`tmb_core.hpp` is **TMB's**, not drmTMB's; `strptime_internal`, `bcEval_loop` and `RunGenCollect` are
**R's own** internals. This independently reproduces `rhub-rchk-adjudication.md`'s earlier verdict of
TMB-framework noise — and does so **on the candidate's `src` tree**, which that adjudication never
had. It is stronger evidence for the same conclusion, not a new problem.

## What this does and does not establish

**Establishes.** The candidate's compiled code passes a full 3-OS `R CMD check` and **all three
memory sanitizers — clang-asan, clang-ubsan and gcc-asan.** The rchk signal is attributable to TMB and R internals rather than to this package, now
demonstrated at the candidate's own source state.

**Does not establish.** `platform-clean`. Three gaps remain:

1. **win-builder has no run for this candidate at any level.** Every win-builder log in this
   directory belongs to 0.6.0 predecessors. **Owner action** — the upload was blocked for the agent
   by a safety classifier.
2. **valgrind produced no coverage** (install failure, above).
3. **These runs are at `bce9cfb6f`, not at a frozen candidate tarball.** Content-equivalent on `src`,
   but Gate 6 asks which hash each service tested, and the honest answer is "a checkout, not the
   candidate tarball".

**Highest proven rung remains `tarball-clean`. Next unproven remains `platform-clean`.**
`DESCRIPTION` remains 0.6.0. Nothing here authorises a merge, tag, or upload.
