# CRAN-readiness checklist — drmTMB

First CRAN submission. Audit date: 2026-06-10. Branch: `shannon/cran-audit`.

This is a **lightweight** audit (cran-extrachecks style). A full
`R CMD check --as-cran` has **not** been run and is the gating step before
submission. Items below are documentation/metadata checks plus static scans of
`R/` and `man/`.

## Status legend

- **DONE** — meets CRAN expectations as-is.
- **BLOCKING** — must be fixed before submission.
- **NICE-TO-HAVE** — improves the submission or pre-empts a reviewer note; not a hard blocker.

## Checklist

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | `Authors@R` well-formed, with ORCID | **DONE** | Single `person()`, roles `[aut, cre, cph]`, valid ORCID `0000-0002-7765-5182`. Evaluates and `format()`s cleanly. |
| 2 | `Title` in Title Case, no trailing period, does not start with package name | **DONE** | "Distributional Regression Models Using Template Model Builder". |
| 3 | `Description` well-formed (no "This package…", no leading package name) | **DONE** | Parses via `read.dcf` / `tools:::.read_description`. Long but valid; see item 17 for software-name quoting. |
| 4 | Mandatory DESCRIPTION fields present | **DONE** | Package, Version, License, Description, Title, Authors@R all present. |
| 5 | `Version` set for a release | **BLOCKING** | Currently `0.1.3.9000` — a development version (`.9000` suffix). CRAN rejects dev versions. Set a release version (task brief names **0.2.0**; last tag is v0.1.3) and add a matching `NEWS.md` heading. **Not auto-fixed — release decision for the maintainer.** |
| 6 | `cran-comments.md` present | **BLOCKING** | File does not exist. Required for submission: state R CMD check result, test environments, and (for a first submission) any expected NOTEs. **Not auto-created — needs real check output.** |
| 7 | Valid `URL` and `BugReports` | **DONE** | All three URLs return HTTP 200 (pkgdown site, GitHub repo, issues). |
| 8 | `Encoding: UTF-8` declared | **DONE** | Present. |
| 9 | `VignetteBuilder` declared | **DONE** | `knitr`; `knitr` + `rmarkdown` in Suggests. |
| 10 | No non-ASCII in `R/`, `DESCRIPTION`, `man/`, `vignettes/` | **DONE** | 0 non-ASCII lines found in all four locations. |
| 11 | `\value` present in exported `.Rd` | **DONE** | 54/55 Rd have `\value`; the only one without is `drmTMB-package.Rd` (the package doc page, which does not need it). |
| 12 | All `.Rd` pass `tools::checkRd()` | **DONE** | 0 warnings/notes across all 55 man pages. |
| 13 | `\dontrun` avoided in favour of `\donttest`/runnable | **DONE** | No `\dontrun` anywhere. (No `\donttest` either — see item 18.) |
| 14 | `T`/`F` not used for `TRUE`/`FALSE` in `R/` | **DONE** | 0 occurrences. |
| 15 | No stray `print()` / `cat()` debug in `R/` | **DONE** | 0 `cat()`. 5 `print()` calls, all inside `print.summary.drmTMB` (legitimate S3 method output). |
| 16 | Suggests-only packages guarded in examples | **DONE** | `ggplot2` used in 3 Rd, each guarded by `requireNamespace`. `JuliaCall` appears only in prose (the `engine` arg description), not in example code. |
| 17 | Software/package names single-quoted in Title/Description | **NICE-TO-HAVE** | "Template Model Builder" / `TMB` are unquoted. CRAN reviewers commonly ask for `'TMB'`. **Not auto-fixed** — wording change beyond field tidying; maintainer should decide phrasing. |
| 18 | Example run-time within CRAN limits | **NICE-TO-HAVE** | ~24 Rd run small (`n≈24`) `drmTMB()`/`biv_gaussian()`/`profile()` fits, all unwrapped. Individually fast; first TMB compile is at install, not per-example. If `--as-cran` flags total example time, wrap the heaviest in `\donttest`. Verify in the full check. |
| 19 | `LICENSE` file matches `License:` field | **NICE-TO-HAVE** | `License: GPL (>= 3)` but `LICENSE` is the full 674-line GPL-3 text. For a standard GPL licence CRAN expects **no** `LICENSE` file (it uses the bundled template); shipping the full text is unnecessary and can draw a note. `LICENSE` is already in `.Rbuildignore` so it is not in the tarball — low impact. Consider removing it or replacing with the `usethis::use_gpl_license()` stub. **Not auto-fixed.** |
| 20 | `inst/COPYRIGHTS` accurate | **NICE-TO-HAVE** | States "drmTMB is currently a clean package scaffold. No source code has been ported…". This is stale (the package now has substantial `R/` + `src/drmTMB.cpp`). The provenance claim (no GPL vendoring) is still true; only the "scaffold" framing is outdated. **Not auto-fixed** — wording. |
| 21 | Build hygiene: dev dirs in `.Rbuildignore` | **DONE (fixed)** | `tools/` (14 dev R scripts: benchmarks, prototypes, checkpoint helpers) was **not** ignored and would have shipped. **Added `^tools$` to `.Rbuildignore` in this pass.** `.github`, `data-raw`, `docs`, `pkgdown`, `bench`, `LICENSE`, `*.bib`, `CLAUDE.md`, `AGENTS.md`, `ROADMAP.md`, `CONTRIBUTING.md`, IDE files already ignored. |
| 22 | Tarball size reasonable | **NICE-TO-HAVE** | `inst/sim` is 1.5 MB and **intentionally shipped** (referenced by `vignettes/source-map.Rmd` and `model-selection.Rmd` via `system.file("sim", …)`); `inst/sim/results` already ignored. Whole-package size is well under CRAN's ~5 MB soft limit, but confirm the built tarball size in the full check. |
| 23 | `inst/CITATION` | **NICE-TO-HAVE** | Absent. Not required; nice for a methods package. |
| 24 | `NAMESPACE` consistency | **DONE** | roxygen-generated; 93 export/S3method entries; `useDynLib(drmTMB, .registration = TRUE)` present (matches compiled `src/`). |
| 25 | `data/` documented (if any) | **DONE (N/A)** | No `data/` dir; no `LazyData` field needed. |

## Prioritized "to submit" list

**Blocking (do first):**

1. **Set a release version.** Change `Version: 0.1.3.9000` → the intended release (e.g. `0.2.0`) and add a dated `# drmTMB 0.2.0` heading to `NEWS.md` summarizing the release. (Maintainer decision — not auto-applied.)
2. **Write `cran-comments.md`.** Run `R CMD check --as-cran` locally, then record the result, the test environments, and (first submission) any expected NOTEs.
3. **Run a full `R CMD check --as-cran` (and `devtools::check()`)** until clean — this is the real gate and surfaces anything this lightweight pass cannot (compiled-code warnings, example timing, vignette build, undeclared imports).

**Strongly recommended before/at submission:**

4. Single-quote `'TMB'` (and optionally `Template Model Builder ('TMB')`) in Title + Description (item 17) — pre-empts a near-certain reviewer note.
5. Decide on the `LICENSE` file (item 19): for plain `GPL (>= 3)`, dropping it or using the standard stub is cleaner.
6. Refresh the stale "clean scaffold" wording in `inst/COPYRIGHTS` (item 20).

**Optional:**

7. Add `inst/CITATION`.
8. If `--as-cran` flags example time, wrap the heaviest model-fitting examples in `\donttest` (item 18).

## What was auto-fixed in this pass

- Added `^tools$` to `.Rbuildignore` so the 14 development-only R scripts in `tools/` are excluded from the build (item 21).

No risky changes (version bump, Title/Description rewording, LICENSE removal, NEWS edits) were made — those are flagged above for the maintainer.
