# Freeze notes — the second 0.7.0 candidate (`302ac2579`)

**2026-08-15 (evening) · Claude, lane `claude/07-cran-ladder` → `claude/07-freeze-3-evidence` ·
authorised by Shinichi: "merge all three PRs and start the re-freeze", the same evening he lifted
both owner holds (D-93 Reading B; D-117 discharged).**

## Identity — one artifact

| | |
| --- | --- |
| Tarball | `drmTMB_0.7.0.tar.gz` |
| SHA-256 | `0d150ef38b8d3b8b2d3dca084a62f8242832048b01e60caa4b08c5388b95e075` |
| Size | **10,087,906** bytes · **957** entries |
| Source commit | `302ac2579969f7d5f949a73610468c9f73f938c8` (= `origin/main`, the #1043 merge) |
| Clean worktree | yes — `git status --porcelain` empty before build AND after (tarball only) |
| Immutable primary | `/Users/z3437171/drmTMB-release-artifacts/0.7.0-302ac2579/` (write-protected, hash-verified) |
| Off-machine | `snakagaw@totoro:~/drmTMB_0.7.0_cand3_302ac2579.tar.gz` (hash-verified) |
| Ledger | `docs/dev-log/release-audits/2026-08-15-070-cran-release-ledger-2.json` — **READY at `tarball-clean`**; `platform-clean` probe **NOT READY** (verified negative control) |

## What the cut contains

Everything merged tonight, deliberately: **#1041** (bootstrap boundary flag — TRAP 1 closed on the
last silent interval route), **#1042** (REML's measured position in the claim surfaces), **#1039**
(the decision records and release documentation), **#1040** (the interval-truth audit's demotions
in the *shipped* capability-ledger includes — overclaim removal), and **#1043** (version back to
`0.7.0` at the cut + the quiesce notice). The roxygen overlap of #1041/#1042 was verified coherent
before cutting: `devtools::document()` on merged `main` produced zero diff.

## Local CRAN-lane check — the exact bytes

`R CMD check --as-cran --run-donttest` on the tarball: **Status: 1 NOTE — "New submission" only**
(0 ERROR / 0 WARNING), matching the superseded candidate's profile. Tests `[207s/235s]` (the CRAN
lane: ~12k tests, heavy recovery suites CRAN-skipped by design), vignette rebuild `[84s/97s]`,
installed size 31.7 MB. R 4.6.0, aarch64-apple-darwin23. Log: `local-as-cran-check.log` here.

Quick gates on the cut: `pkgdown::check_pkgdown()` ✔ clean · `urlchecker` 1 hit — the T&F DOI
403 in `vignettes/figure-gallery.Rmd`, an evidenced non-blocker (the superseded candidate shipped
the same file through a clean CRAN-lane check; 403s even a browser UA — publisher bot-blocking).
Recorded as `known_evidence_gaps.urlchecker_doi_403` in the ledger.

## The discarded first build — recorded, not hidden

The first build of this cut was **discarded**: the pipeline wrote its build log inside the package
directory, `R CMD build` tarred it in, and the check caught it as a second NOTE ("Non-standard
file at top level: `build-0.7.0-freeze3.log`") — the same defect class as the earlier candidate's
stray `figure/` directory. The rebuild keeps all logs outside the tree, and the Gate 5
forbidden-path scan now explicitly covers `\.log$` (verified against the prior inventory to be
false-positive-free). Discarded tarball hash was never recorded anywhere as a candidate.

## Supersession

The 2026-08-11 candidate (`2176e4b8…cda9` / `a75c3c901`) and its ledger are **predecessor evidence
only** from this point. Its records remain untouched at
`docs/dev-log/release/0.7.0-cran-gate/` and `docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json`.

## What is NOT claimed — the next rung's work

**No platform evidence of any kind exists for these bytes**: win-builder, 3-OS matrix, R-hub
sanitizers, and valgrind are all unrun post-cut. `platform-clean` is mechanically blocked (probe
verified). The quiesce holds: **no shipped-file merges to `main` until the platform matrix
completes against this artifact**, per the coordination-board notice. Gate 7 (Grace/Rose/Pat panel)
and every rung above remain owed. Submission is Shinichi's call alone.
