# drmTMB 0.7.0 — decision packet

**For:** Shinichi · **Date:** 2026-08-09 · **From:** Claude, release slice
**Branch:** `claude/07-release-slice` · **Draft PR:** [#959](https://github.com/itchyshin/drmTMB/pull/959) (**do not merge — merging it is the release action**)

## The one-line answer

**Highest rung PROVEN: `tarball-clean`.** Next rung, unproven: **`platform-clean`**.
Nothing above `tarball-clean` is claimed, and **0.7.0 cannot publish today regardless** — see §4.

## 1. What exists now

| | |
| --- | --- |
| Candidate | `drmTMB_0.7.0.tar.gz`, SHA-256 **`a8f7c47905b0…`**, 4,190,882 bytes, 904 entries |
| Built at | `cc4f5baee`, on `origin/main@8d441a32d` |
| Claim-bearing check | `R CMD check --as-cran --run-donttest`, incoming enabled → **Status: 1 NOTE** (`New submission` only), 0 errors, 0 warnings |
| Fail-closed gate | selftest **14/14** negative controls fail closed, then **READY FOR CLAIMED RUNG** |
| Packet | [`FREEZE-NOTES-0.7.0.md`](../release/0.7.0-cran-gate/FREEZE-NOTES-0.7.0.md) · evidence in [`CANDIDATE-EVIDENCE/`](../release/0.7.0-cran-gate/CANDIDATE-EVIDENCE/) |

**This is the fourth candidate. Three were deliberately invalidated under D-49** — the last one
*after* it had already passed the identical check, because an audit found a user-facing gap. That
is the discipline working, not churn.

## 2. The blocker you were carrying is gone

`inst/doc` was **11.11 MB** against CRAN's stated **5MB** maximum — the likeliest actual submission
blocker, and invisible to `R CMD check`, which reports it only as `INFO`.

**Now 4.605 MB.** Tarball 9.85 → 4.19 MB; installed 31.2 → 24.7 Mb.

Measured before acting: HTML was 9.92 MB of the 11.105 MB, and **88–98%** of the worst files was
embedded base64 plot images, not text. So the lever was which *rendered* vignettes ship. Dropping
the four largest still leaves 5.07 MB, so five had to go either way; you chose to move rather than
delete them, and they remain published on the website.

## 3. Three things this cost — decide whether you accept them

**a. Five vignettes no longer ship.** `figure-gallery`, `function-map-cheatsheet`,
`simulation-plot-grammar`, `model-workflow`, `distributional-outputs-and-adequacy`.
`vignette("model-workflow")` now returns "vignette not found", `browseVignettes()` shows 32 of 37,
the CRAN page will host 32, and offline readers lose them entirely. Recorded in `NEWS.md`.

**b. A correctness check was retired — the item most worth your attention.** `R CMD check` builds
`vignettes/*.Rmd` and **not** `vignettes/articles/*.Rmd`. The vignette re-build now covers 32
documents, so **the R code in the five most code-dense documents is executed by nothing in the
release gate** — not `R CMD check`, not the test suite, not any site build since the move.
`figure-gallery.Rmd` alone is ~92 KB of plotting code. This was invisible to every check that
passed: `--as-cran` said 1 NOTE before and after.

*Options if you want that coverage back:* have CI build the pkgdown site on PRs (cheapest, no
package-size cost), or add a test that knits the five. Neither is done.

**c. Rendering is unproved.** pkgdown *discovery* and config are verified (`as_pkgdown()` finds all
37; `check_pkgdown()` clean). No site has been built since the move. I did not dispatch the pkgdown
workflow because its `workflow_dispatch` path **deploys to Pages** and would publish this
candidate's site over your live one.

## 4. Why this still cannot be published — independent of the candidate

- **D-117** — the 10-group corner is a gate on publishing 0.7.0. The gate ran (Totoro, 2026-08-04)
  and all four cells clear the floor, but its D-43 panel returned **2 of 3 NOT-DONE** and the
  **PASS is withheld**, because conditional on `profile.boundary` coverage is 0.8566 / 0.0732 /
  0.2540. Not a drmTMB defect — `lme4` agrees on boundary incidence 4000/4000 on the same seeds.
  **Its one remaining open item was documentary, and this session closed all three surfaces it
  names** (`NEWS.md`, `man/`, and now the vignettes). Whether that discharges D-117 is your call,
  not mine.
- **D-89** — submission is far away by choice. There is no clock.
- The CRAN portal was noted offline until ~2026-08-19.

## 5. What needs you

1. **Accept or reject the three costs in §3**, particularly (b) — the retired vignette-code
   coverage. If you want it restored before the next rung, say which route.
2. **D-117.** All three documentary surfaces it names are now closed. Do you consider the withheld
   PASS dischargeable, or does the conditional-coverage finding still hold it?
3. **`platform-clean`** — owner-gated. Dispatched runs exist but **none at this candidate's source**;
   a run at `cc4f5baee` or later is required first.
4. **D-43 panel** — you deferred it until platform evidence exists. Still deferred.
5. **win-builder** — not submitted. It remains the only real Windows vignette-timing measurement.
6. **Installed size 24.7 Mb**, dominated by `libs 13.6Mb` (the TMB template), not documentation.
   Reported as `INFO` here, not `NOTE`; what CRAN's machines will say is not established. Also
   `inst/sim` (1.9 Mb) ships — a product question, raised not settled.

## 6. Untouched, as instructed

No D-43, no `platform-clean` write, no `cran-comments.md` finalisation, no tag, no GitHub release,
no upload, and PR #959 is **not** merged. Sibling lanes — #858, #937, #960, PRs #957/#958, the
stashes, the dirty primary checkout, and every foreign `codex/*` branch — are unmodified.
