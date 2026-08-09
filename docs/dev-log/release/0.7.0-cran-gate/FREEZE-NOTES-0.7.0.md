# drmTMB 0.7.0 — exact candidate freeze

**Date:** 2026-08-09 · **Lane:** Claude task 1, Stage B · **Branch:** `claude/07-release-slice`
**Draft PR:** [#959](https://github.com/itchyshin/drmTMB/pull/959) — **must not merge** without the release decision.

> This supersedes [`FREEZE-NOTES.md`](FREEZE-NOTES.md), which describes the **0.6.0**
> predecessor artifact at source `ad475cc39`. That one remains valid history and is
> quarantined by [`STALE-EVIDENCE-QUARANTINE.md`](STALE-EVIDENCE-QUARANTINE.md).

## Artifact identity

| Property | Value |
| --- | --- |
| Package / version | `drmTMB_0.7.0.tar.gz` |
| **SHA-256** | `d35c0b9ef8d83f1fb3c703419c4d9ac7d4736783211f3a0541769790429a458f` |
| **Size** | 9,853,615 bytes |
| **Entries** | 924 |
| **Source commit** | `7fccac0b9138be467c33da415d37a21788f9c436` |
| Clean worktree at build | yes — `git status --porcelain` empty (0 paths) |
| Base | `origin/main@8d441a32d` (PR #956, separation disposition **DEFER**) |
| Immutable copy | `scratchpad/frozen-d35c0b9ef8d8/`, write-protected, re-hashed from that path and matching |

Built with vignettes. Any installed-byte change from here creates a **new** candidate and
invalidates every artifact-bound result below.

## Forbidden-path scan — 0 hits

Proved by listing the **built tarball**, not by pointing at `.Rbuildignore`, which is what
Gate 1 requires. Top-level entries are exactly `DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `R`,
`README.md`, `build`, `inst`, `man`, `src`, `tests`, `vignettes`.

Absent as intended: `docs/`, `tools/`, `scratchpad/`, `LOOP/`, `pkgdown-site/`, `.git`,
`.github`, `AGENTS.md`, `CLAUDE.md`, `cran-comments.md`, `*.Rproj`.

Worth noting: the separation merge added a large `scratchpad/` evidence set to `main` about
an hour before this build, and **none of it ships**.

## Local CRAN-lane check — the claim-bearing run

`R CMD check --as-cran --run-donttest` on the exact frozen tarball, CRAN incoming
**enabled**, vignettes **built**, manual built (`pdflatex` present),
`_R_CHECK_FORCE_SUGGESTS_` **not** disabled.

### **Status: 1 NOTE**

```
* checking CRAN incoming feasibility ... [4s/24s] NOTE
Maintainer: 'Shinichi Nakagawa <itchyshin@gmail.com>'

New submission
```

That is the whole NOTE. **0 errors, 0 warnings**, and the only note is the unavoidable
first-submission line.

### Both predecessor incoming items are cleared

The predecessor win-builder run reported, besides `New submission`, possible DESCRIPTION
spellings (`centile`, `mis`, `uncalibrated`) and a possibly-invalid file URI
(`function-map-cheatsheet.png`). Neither appears here — a grep for
`misspelled|invalid.*URI` over this log returns **0**.

The URI fix was verified **in the artifact**, not in source: `inst/doc/function-map-cheatsheet.html`
now carries `href="https://github.com/itchyshin/drmTMB/blob/main/vignettes/function-map-cheatsheet.png"`,
and **zero** PNGs ship into `inst/doc`.

### Timings and size

| Stage | Time |
| --- | --- |
| install | 62s / 68s |
| examples | 11s / 12s |
| examples with `--run-donttest` | included above |
| tests (`testthat.R`) | **10m / 11m** |
| **re-building vignette outputs** | **83s / 96s** |
| **total wall clock** | **15m 29s** |

```
* checking installed package size ... INFO
  installed size is 31.2Mb
  sub-directories of 1Mb or more:
    R      3.1Mb
    doc   11.4Mb
    libs  13.6Mb
    sim    1.9Mb
```

**On the Windows-threshold question.** The 37-vignette rebuild took **96s wall**, which is
comfortably inside CRAN's observed ~10-minute incoming signal. But this is Apple-silicon
macOS, and **macOS timing is not Windows timing** — that boundary is an observed incoming
behaviour on CRAN's own Windows machines, not a property of this run. Treat 96s as
*encouraging*, not as evidence. The real measurement comes from win-builder in the platform
matrix.

Compilers: Apple clang 21.0.0, SDK MacOSX26.5. Installed size is an `INFO`, not a NOTE, and
is intrinsic to a TMB package (`libs` 13.6Mb); `glmmTMB` on CRAN carries the same pattern.

## Rungs

**Highest proven: `tarball-clean`** — for hash `d35c0b9e…` only.

**Next unproven: `platform-clean`.** Dispatched on the exact source branch at the time of
writing, owner-authorized 2026-08-09:

- 3-OS `R-CMD-check` (`workflow_dispatch`) — run
  [31327046167](https://github.com/itchyshin/drmTMB/actions/runs/31327046167)
- `R-hub` sanitizers — run
  [31327047576](https://github.com/itchyshin/drmTMB/actions/runs/31327047576)

**The `platform-clean` rung itself still requires a separate explicit owner word**, per the
standing hold in [`platform/PLATFORM-NOT-READY.md`](platform/PLATFORM-NOT-READY.md).
Dispatching the runs does not write the rung.

When reading those results: **a timeout kill is logged as `conclusion: cancelled`**, the same
string as a concurrency cancel. Distinguish them by comparing job duration against the 75-min
ceiling, never by reading the conclusion.

## Not run, not claimed

D-43 panel (deferred by owner until platform evidence exists) · final `cran-comments.md` ·
author-role consent line · tag · GitHub release · CRAN upload · reverse-dependency checks
(not applicable, first submission).

## Owner decisions carried into this freeze

- **D-93 — DISCHARGED (2026-08-09).** Its premise was a fixable drmTMB defect. Measurement
  answered it: `lme4` reproduces the same conditional undercoverage on identical DGP and
  seeds, so the honest remedy was the user-facing boundary warning, which shipped
  2026-08-05. **D-117's PASS claim remains withheld** and is unaffected.
- **#870 — implemented**, not documented away: `offset()` now works for every univariate
  family (PR #958). Truncated/hurdle NB2 and bivariate families still reject it, with the
  reason recorded.
- **Separation lane — DEFER**, no demonstrated release-relevant defect (PR #956).
