# drmTMB 0.7.0 — Stage A release-gate orientation (Gate -1 / Gate 0)

**Date:** 2026-08-09 · **Lane:** Claude task 1 (candidate preparation), Stage A
**Baseline:** `origin/main@ac363cadb605a2eda567de9027b873eebc4788c5`
**Working branch:** `claude/07-candidate-preparation-staged` (worktree
`/private/tmp/drmTMB-07-candidate-prep`, created from refreshed `origin/main`)

## Verdict

**NOT READY.** Highest proven rung for *current main*: **none**. `DESCRIPTION`
remains **`0.6.0`**.

The highest rung proven anywhere in this repository is **`tarball-clean`**, and it
belongs to a **predecessor artifact**, not to current `main`. See §3 — that
distinction is this document's main point.

## 1. Gate -1 — release profile

| Flag | Value | Evidence |
| --- | --- | --- |
| `release_type` | `first_submission` | drmTMB is not on CRAN; D-86 fixes the first number at `0.7.0` |
| `target_cran_version` | `0.7.0` | D-86; `cran-comments.md`; `README` |
| `compiled_code` | **true** | `src/drmTMB.cpp`, `src/init.c`, three headers; `LinkingTo: RcppEigen, TMB` |
| `reverse_dependencies` | **false** | first submission — nothing depends on it yet |
| `system_or_external_services` | **true** | optional `engine = "julia"` via `Suggests: JuliaCall`; must degrade cleanly when absent |
| `large_data_or_vignettes` | **true** | **37 vignettes**; installed size 31.2 MB (predecessor measurement) |
| Bioconductor coupling | false | no Bioconductor dependency |
| `data/*.rda` | **none** | `data/` is empty — materially reduces Gate 1 rights surface |

### Conditional gates that are therefore mandatory

- **Compiled code** → native registration/symbol checks; sanitizer / compiled-boundary
  diagnostics with findings adjudicated. Predecessor R-hub evidence exists
  (clang-asan / clang-ubsan / gcc-asan **OK**; rchk adjudicated noise; **valgrind
  incomplete**) — all against a predecessor hash, all requiring re-run.
- **Large vignettes** → per-stage timing budget. **This is the live risk.** 37
  vignettes against CRAN's observed ~10-minute Windows incoming threshold. Per the
  protocol, a Windows total near that boundary is a **blocker even when the check
  status is only a NOTE**. Predecessor win-builder runs passed, but the vignette set
  has changed since (7 vignettes among the 15 drifted files, §2).
- **Optional external service** → prove `JuliaCall`-absent behaviour is clean.
- **All packages** → clean temp-library install/load/examples.

## 2. Gate 0 — the product has moved since the last freeze

`git diff --name-only ad475cc39 ac363cadb` over build-included paths returns **15
files** (66 across all paths):

```
NEWS.md                                          README.md
R/drmTMB.R                                       R/julia-bridge.R
man/drmTMB.Rd
tests/testthat/test-julia-sigma-phylo-reml.R     tests/testthat/test-reml-binomial-coxreid.R
vignettes/capability-and-limits.Rmd              vignettes/convergence.Rmd
vignettes/drmTMB.Rmd                             vignettes/formula-grammar.Rmd
vignettes/model-map.Rmd                          vignettes/model-selection.Rmd
vignettes/includes/capability-ledger-family-map.md
vignettes/includes/capability-ledger-summary.md
```

These are the #952 / #953 / #954 capability-truth landings. They change **installed
bytes** (`R/`, `man/`, `vignettes/`), so under D-49 every artifact-bound result from
before them is predecessor evidence.

### The stale product contract

`docs/dev-log/release-audits/2026-08-07-07-product-contract.md` states the census as
**187 `interval_feasible` / 55 `point_fit_recovery` (frozen PFR 54)** at source
`8df6f2402`. That predates #953's capability-truth reconciliation, which changed the
public O2/O3 boundaries and the binomial REML dispositions. **It must not be reused
as the 0.7 contract.** Superseded by `2026-08-09-07-product-contract.md`.

## 3. The finding: valid predecessor evidence that reads as current

`docs/dev-log/release/0.7.0-cran-gate/` sits on `main` and records a **`tarball-clean`**
freeze. I re-verified the artifact today:

| Property | Recorded | Measured 2026-08-09 | Match |
| --- | --- | --- | --- |
| SHA-256 | `2e5234bd…c5ea` | `2e5234bd…c5ea` | **yes** |
| Size (bytes) | 9,831,204 | 9,831,204 | **yes** |
| Source commit | `ad475cc39` | — | — |
| Tarball still on disk | — | `/private/tmp/drmTMB-07-reader-boundaries-tarball/drmTMB_0.6.0.tar.gz` | **present** |

**The evidence is not corrupt and not wrong. It is stale.** It is a truthful
`tarball-clean` proof for `ad475cc39`, which is 15 build-included files behind
`ac363cadb`.

**And the gate does not catch it.** Running the on-main ledger through the fail-closed
checker today:

```
$ python3 ~/shinichi-brain/tools/cran_release_gate.py \
    docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json
READY FOR CLAIMED RUNG          (exit 0)
```

That is the checker behaving correctly — it validates *artifact against claim*, and
that pairing is sound. **It has no control for "is this artifact built from current
`main`?"** The selftest confirms the tool is otherwise healthy: all 14 planted
negative controls fail closed, including `predecessor-hash`.

So the hazard is not a broken tool. It is a **green result whose scope is easy to
misread**, sitting in the repository, with the matching tarball still on disk. That is
exactly the freqTLS failure class this protocol was written to prevent.

**Mitigation (A2):** a quarantine note written into
`docs/dev-log/release/0.7.0-cran-gate/` naming the drift explicitly, plus a fresh
ledger for this arc that claims **no artifact rung at all**.

**Recommended gate improvement — flagged, not implemented (not my lane):** add an
optional `source_commit_is_current` control that fails closed when the ledger's
`source_commit` is not an ancestor-equal of the named release branch tip. One line of
`git merge-base --is-ancestor` plus a tip comparison would have made today's green a
red. Owner's call, and it belongs to the brain's `tools/`, not this repo.

### A third identity in the same directory

`platform/PLATFORM-NOT-READY.md` reports win-builder R-release + R-devel at **1 NOTE,
0 ERROR** — on tarball **`f9b9588e…`, 9,818,425 bytes**. That is neither the
`tarball-clean` artifact nor current `main`. Three artifact identities coexist in this
directory:

| Identity | Hash | Bytes | Proves |
| --- | --- | --- | --- |
| tarball-clean freeze | `2e5234bd…` | 9,831,204 | local `--as-cran`, 1 NOTE, at `ad475cc39` |
| win-builder fixed | `f9b9588e…` | 9,818,425 | win-builder R-release + R-devel, 1 NOTE |
| **current `main`** | **does not exist** | — | **nothing** |

`platform-clean` is correctly **withheld** in the ledger (`status_claim` stays
`tarball-clean`) pending owner authorization. Stage A does not change that.

## 4. CRAN policy refresh — status

The protocol requires refreshing current CRAN Repository Policy and submission
guidance at release time, labelling each threshold as *current policy*, *observed
incoming behaviour*, or *conservative local margin*.

**Not refreshed in Stage A, deliberately.** A policy read taken today would be ~stale
by the time Stage B builds the real candidate after the separation disposition. It is
scheduled as the **first step of Stage B**, ahead of the freeze. The predecessor
refresh (`2026-08-07-07-cran-policy-refresh.md`) is retained as an instrument.

Thresholds carried forward, with their labels:

| Threshold | Label |
| --- | --- |
| ~10-min Windows vignette total | **observed incoming behaviour**, not immutable policy |
| Installed size NOTE ~31.2 MB (`libs` 13.6, `doc` 11.3) | **observed**; intrinsic to TMB, same pattern as CRAN `glmmTMB` |
| 75-min CI ceiling | **local margin**, measured 2026-08-04; not a CRAN concept |

## 5. Known incoming findings carried into Stage B

From `platform/winbuilder-release-fixed-00check.log:17-24` (predecessor — must be
re-read on the candidate):

1. **New submission** — expected and unavoidable for a first submission.
2. **Possibly misspelled words in DESCRIPTION** — `centile (23:43)`, `mis (22:40)`,
   `uncalibrated (24:6)`.
3. **Possibly invalid file URI** — `function-map-cheatsheet.png` from
   `inst/doc/function-map-cheatsheet.html`.

Items 2 and 3 are diagnosed with exact root causes and prepared diffs in
[`2026-08-09-07-stage-b-byte-fixes.md`](2026-08-09-07-stage-b-byte-fixes.md). Item 3's
cause is a plain markdown link at `vignettes/function-map-cheatsheet.Rmd:78`, not the
embedded image. A **fourth** item — a documentation overclaim about `offset()` support
for `truncated_nbinom2()` — was found in Stage A and is analysed in
[`2026-08-09-07-870-offset-analysis.md`](2026-08-09-07-870-offset-analysis.md).

## 6. Toolchain

Tested rather than assumed, per the handover's instruction:

```
R version 4.6.0 (2026-04-24) · TMB 1.9.21 · devtools 2.5.2
pkgbuild::has_build_tools() = TRUE
```

**A Stage B build is possible in this session.** It is fenced by *authorization*, not
by capability — Shinichi directed on 2026-08-09 that no tarball is built in Stage A.

## 7. Explicit non-goals of Stage A

No tarball · no `--as-cran` run · no `DESCRIPTION` bump · no `platform-clean` write ·
no D-43 panel · no final `cran-comments.md` · no tag · no GitHub release · no CRAN
upload · no D-117 rerun · no compute campaign · no #870 implementation · no edit to
`R/`, `src/`, `man/`, `vignettes/`, `tests/`, `NAMESPACE`, or `DESCRIPTION`.
