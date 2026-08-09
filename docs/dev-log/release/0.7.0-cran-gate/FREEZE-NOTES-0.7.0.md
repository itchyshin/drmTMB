# drmTMB 0.7.0 — exact candidate freeze

**Date:** 2026-08-09 · **Lane:** Claude, release slice (third candidate) · **Branch:** `claude/07-release-slice`
**Draft PR:** [#959](https://github.com/itchyshin/drmTMB/pull/959) — **must not merge** without the release decision.

> This supersedes the two predecessor candidates described below, and supersedes
> [`FREEZE-NOTES.md`](FREEZE-NOTES.md), which describes the **0.6.0** artifact at source
> `ad475cc39`. Those remain valid history and are quarantined by
> [`STALE-EVIDENCE-QUARANTINE.md`](STALE-EVIDENCE-QUARANTINE.md).

## Artifact identity

| Property | Value |
| --- | --- |
| Package / version | `drmTMB_0.7.0.tar.gz` |
| **SHA-256** | `d04d0e88d068e82eab64fbe710a01ed3302fd2d37f77901189cac8d7af84089e` |
| **Size** | 4,190,432 bytes |
| **Entries** | 904 |
| **Source commit (built at)** | `6d1fb0562` |
| Branch head at freeze | `9fc92e9f7` — see *Provenance delta* below |
| Base | `origin/main@8d441a32d` (PR #956, separation disposition **DEFER**) |
| Immutable copy | `scratchpad/frozen-d04d0e88d068/`, write-protected, **re-hashed from that final path and matching** |

Built with vignettes. Any installed-byte change from here creates a **new** candidate and
invalidates every artifact-bound result below.

### Provenance delta — read this before citing the source commit

The tarball was built at `6d1fb0562`. The branch head is `9fc92e9f7`, which adds exactly one
commit touching exactly one file: `_pkgdown.yml`. That path is `.Rbuildignore`d
(`^_pkgdown\.yml$`, line 13), and a grep of the built tarball's own listing for `pkgdown`
returns **0 hits**, so **no installed byte differs**. This is recorded, not glossed: a reviewer
who wants source-commit and branch-head to be literally identical should require a rebuild, which
would change only timestamps. The same situation was recorded for the predecessor candidate.

## What changed since the predecessor, and why the predecessor died

| Candidate | SHA-256 | Size | Entries | Fate |
| --- | --- | --- | --- | --- |
| `d35c0b9e` | — | — | — | **Invalidated (D-49)** — README told users to install the unsupported `v0.5.0` tag |
| `da9b2d76` | `da9b2d76badc…` | 9,853,648 | 924 | **Invalidated (D-49)** — boundary surfacing touches `R/` |
| **`d04d0e88` (this)** | `d04d0e88d068…` | **4,190,432** | **904** | **current** |

Two substantive changes landed since `da9b2d76`:

1. **Boundary surfacing merged** (PR [#961](https://github.com/itchyshin/drmTMB/pull/961) into the
   slice, not into `main`). `confint(method = "bootstrap")` now flags a variance-component or
   correlation boundary using the bootstrap's **own** signal — the share of retained resamples on
   the bound, computed on the **natural** scale — and `check_drm()` states that it does not assess
   interval reliability.
2. **The five heaviest vignettes moved to `vignettes/articles/`**, which `.Rbuildignore` excludes
   from the build. This is what closed the size question below.

## The documentation-size question is RESOLVED

The predecessor recorded this as an **open policy risk deliberately not blocking the rung**:
`inst/doc` was **11.11 MB** against CRAN's stated **5MB** documentation maximum, reported by
`R CMD check` only as an `INFO` line. It is now closed by measurement.

| | predecessor `da9b2d76` | **this candidate** |
| --- | --- | --- |
| `inst/doc` (uncompressed) | 11.105 MB, 111 files | **4.605 MB, 96 files** |
| installed `doc` sub-directory | 11.11 Mb | **4.8 Mb** |
| installed package size | 31.2 Mb | **24.7 Mb** |
| tarball | 9,853,648 bytes | **4,190,432 bytes** |

**What the bytes actually were.** Of the 11.105 MB, HTML was **9.92 MB**; the `.Rmd` sources were
only 0.920 MB and the `.R` files 0.261 MB. Measured directly, **87.9%** of `figure-gallery.html`
and **98.0%** of `function-map-cheatsheet.html` was embedded base64 plot images. So the lever was
never how the vignettes are written — it was which rendered vignettes ship.

**Why moving beat dropping.** Dropping the four largest stems reaches only 5.07 MB, still over the
limit; five are required. Moving those five to `vignettes/articles/` reaches 4.605 MB **and keeps
every one of them on the pkgdown website**. Owner decision, 2026-08-09.

**What this does cost the reader — stated plainly, not glossed.** These five no longer ship, so
for them `vignette("model-workflow")` fails, `browseVignettes("drmTMB")` does not list them, and a
reader with no network cannot reach them at all. The correct claim is therefore **"no reader loses
access *on the website*"**, not "no reader loses access". Fifteen in-vignette cross-links now point
at `https://itchyshin.github.io/…`, so following them from a shipped vignette requires a network
connection where it previously did not. This trade was put to the owner with that cost named before
the move was made.

Moved: `figure-gallery` (3.057 MB), `function-map-cheatsheet` (1.528 MB),
`simulation-plot-grammar` (0.767 MB), `model-workflow` (0.681 MB),
`distributional-outputs-and-adequacy` (0.483 MB). `function-map-cheatsheet.png` (1.17 MB) moved
with its vignette, because the `.Rmd` includes it by **relative** path.

**Reader access proved, not assumed.** `pkgdown::as_pkgdown(".")` still discovers **37** vignettes,
and all five resolve to `articles/…` outputs. `pkgdown::check_pkgdown()` reports **no problems**.
This needed a fix: an article's `_pkgdown.yml` contents entry is its path relative to `vignettes/`,
so the five became `articles/<stem>`. Without it `check_pkgdown()` aborted and the site build would
have failed — dropping all five from the website, the exact opposite of the intent.

**Fifteen cross-links repaired.** Fifteen relative links from *staying* vignettes to the five moved
ones would have pointed at files that no longer ship. They now use the absolute pkgdown URL,
matching what `README.md` already did. Links *between* moved vignettes were left alone: both ends
land in `articles/`.

## Forbidden-path scan — 0 hits

Proved by listing the **built tarball**, not by pointing at `.Rbuildignore`, which is what Gate 1
requires. Top-level entries are exactly `DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `R`, `README.md`,
`build`, `inst`, `man`, `src`, `tests`, `vignettes`.

Absent as intended: `docs/`, `tools/`, `scratchpad/`, `LOOP/`, `pkgdown-site/`, `.git`, `.github`,
`AGENTS.md`, `CLAUDE.md`, `cran-comments.md`, `_pkgdown.yml`, `*.Rproj`.

## Local CRAN-lane check — the claim-bearing run

`R CMD check --as-cran --run-donttest` on the exact frozen tarball, CRAN incoming **enabled**,
vignettes **built**, `_R_CHECK_FORCE_SUGGESTS_` **not** disabled.

### **Status: 1 NOTE**

```
* checking CRAN incoming feasibility ... [4s/26s] NOTE
Maintainer: ‘Shinichi Nakagawa <itchyshin@gmail.com>’

New submission
```

That is the whole NOTE. **0 errors, 0 warnings**, and the only note is the unavoidable
first-submission line.

Both predecessor incoming items stay cleared: a case-insensitive grep for
`misspelled|invalid.*URI` over this log returns **0**.

Log: `/tmp/drm-rc3b/as-cran.log`.

### Timings

| Stage | Time |
| --- | --- |
| install | 64s / 67s |
| examples (incl. `--run-donttest`) | 11s / 12s |
| tests (`testthat.R`) | **10m / 11m** |
| re-building vignette outputs | 67s / 78s |
| **total wall clock** | **~15m** |

```
* checking installed package size ... INFO
  installed size is 24.7Mb
  sub-directories of 1Mb or more:
    R      3.1Mb
    doc    4.8Mb
    libs  13.6Mb
    sim    1.9Mb
```

## Supporting checks

- **Capability-ledger fingerprint guard** — `tools/tests/test_capability_ledger.py`, the guard CI
  actually runs: **66 tests OK**, `C17 current-source compatibility PASS`. No re-pin was performed
  and none was needed: the C17 model-15 fingerprint covers `R/drmTMB.R` and `src/drmTMB.cpp`, and
  the boundary merge touched only `R/profile.R` and `R/check.R`.
- **Targeted suite** — `test-boundary-surfacing` (16) + `test-offset-families` (29) = **45 pass, 0
  failures**.

## Platform matrix — dispatched, NOT adjudicated

`platform-clean` is **not** claimed. These runs are recorded so the next session can read them;
their results are owner-gated.

| Workflow | Run | At commit | Note |
| --- | --- | --- | --- |
| `R-CMD-check` | [31332830272](https://github.com/itchyshin/drmTMB/actions/runs/31332830272) | `9fc92e9f7` | branch head; auto-triggered by push |
| `R-CMD-check` | [31332769740](https://github.com/itchyshin/drmTMB/actions/runs/31332769740) | `6d1fb0562` | manual dispatch, exact candidate source |
| `R-hub` | [31332770848](https://github.com/itchyshin/drmTMB/actions/runs/31332770848) | `6d1fb0562` | exact candidate source. Not re-dispatched at `9fc92e9f7`: the delta is `_pkgdown.yml` only, which does not ship, so a re-run would burn R-hub minutes for zero information |

Two earlier runs (`31332751892` at `6d1fb0562`, `31332230305` at `7a71d28e4`) show
`conclusion: cancelled`. **Each was superseded by a later push**, so these are concurrency
cancels, not timeout kills — checked against the 75-minute ceiling rather than trusting the
conclusion string.

`pkgdown` was **deliberately not dispatched**: its `workflow_dispatch` path uploads and deploys a
Pages artifact, so running it at this branch would publish the candidate's site over the live one.

## What this freeze does NOT claim

- **Not `platform-clean`.** Dispatched only; nothing adjudicated.
- **Not `submission-ready`.** The D-43 panel has not fired; the owner deferred it.
- **Not permission to publish.** Independently of this candidate's cleanliness,
  [D-117](../../../../..) holds 0.7.0: the 10-group gate was run, but its D-43 panel returned 2 of
  3 NOT-DONE and the **PASS is withheld**. D-89 also records that submission is far away by choice.
- **Not on CRAN.** A version number is a candidate identity, not evidence of acceptance.

## Repository guards repaired after the move (does NOT touch the candidate)

Moving the five vignettes broke three assertions in `tools/tests/test_capability_ledger.py`, the
guard CI actually runs. **CI caught this; the local run did not, because the guard was run before
the move rather than after** — recorded as a process lapse, not smoothed over.

| Failure | Cause | Repair |
| --- | --- | --- |
| `FileNotFoundError: vignettes/model-workflow.Rmd` | hard-coded path | point at `vignettes/articles/model-workflow.Rmd` |
| `getting_started_entries.count("function-map-cheatsheet") == 1` gave 0 | the entry is now `articles/function-map-cheatsheet`, and the regex disallowed `/` | accept an optional `articles/` prefix and capture the stem either way |
| `across 32 vignettes` not found in a heading saying 37 | the glob was non-recursive, so it stopped counting the five | make it recursive — the contract is about **reader** coverage, and all 37 remain reader-facing |

None of these re-pins a fingerprint to hide a change; each restores the assertion's original intent
under the new layout. The third is the substantive one: counting only shipped vignettes would have
silently redefined a reader-coverage contract as a packaging contract, and `docs/design/226`
correctly still says 37.

`tools/` is `.Rbuildignore`d and absent from the tarball listing, so **the frozen artifact
`d04d0e88` is unaffected and remains valid**. Full suite: `python3 -m unittest discover -s
tools/tests` → **122 tests, OK**.

## Independent verification

- **Mechanical re-verify** (fresh context, read-only, re-measured every number from the artifact
  rather than copying it): **20 claims checked, 20 match, 0 mismatch** — including a re-hash from
  the final frozen path, the forbidden-path scan, and the ledger's own fields.
