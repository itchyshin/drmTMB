# drmTMB 0.2.0 Release-Readiness Checklist

This note consolidates the 0.2.0 release track (#342) and the Phase 20
CRAN/paper-preparation gate (#61) into one status checklist. The reader is the
project owner running the release from a local machine, and the contributor
preparing the prerequisites. Each item is marked **done**, **local-R only**
(needs a machine with the package dependencies and CRAN tooling, which the cloud
sandbox cannot provide because its network policy blocks the R repositories), or
**pending**.

Release type: minor, `0.1.3.9000 -> 0.2.0`, because `NEWS.md` records many new
user-facing features and validation lanes rather than a patch-only fix.

## Release Should Not Begin Yet

Per Grace's and Rose's gates in `ROADMAP.md`, release preparation should not
*start* until the implemented surface, Phase 18 simulation evidence, and Phase 19
comparator evidence agree with the documentation. The capability worklist
(`docs/design/157-capability-completion-worklist.md`) shows Tier A–E slices are
still pending local implementation, and Phase 18 recovery/coverage and Phase 19
comparator runs are not yet executed. This checklist is the *preparation index*,
not the trigger. It records what is ready now and what each remaining gate needs.

## First-Release CRAN Hygiene (#342)

| Item | Status | Note |
| --- | --- | --- |
| `usethis::use_cran_comments()` | pending (submission-time) | Create `cran-comments.md` at actual submission; premature now |
| README install instructions match release channel | done | GitHub-install README is current |
| `Title:` / `Description:` proofread | done | DESCRIPTION text is accurate and CRAN-style; `cph` role present |
| Exported functions have `@return` and runnable/skipped `@examples` | local-R only | Verify with `R CMD check` and `tools::checkRd` on a local machine |
| `Authors@R` includes `cph` | done | Shinichi Nakagawa holds `aut`, `cre`, `cph` |
| Bundled-file licensing / `inst/COPYRIGHTS` | pending | Confirm before any ported code lands (none currently ported) |

## drmTMB Release Gates (#342)

| Item | Status | Note |
| --- | --- | --- |
| Reconcile any dirty worktree / parked artifact lanes | pending | Decide which pending capability slices belong in 0.2.0 vs a later minor |
| Every included feature has NEWS, tests, docs, examples, check-log, after-task | mostly done | Maintained per slice; final audit needed at freeze |
| `devtools::document()` after roxygen settles | local-R only | |
| Focused tests for recently changed lanes | local-R only | Phase 18 recovery lanes run on Actions; full local run still needed |
| `devtools::test()` | local-R only | |
| `devtools::check(remote = TRUE, manual = TRUE)` | local-R only | |
| `pkgdown::check_pkgdown()` + review rendered HTML | local-R only | |
| `urlchecker::url_check()` | local-R only | |
| `devtools::check_win_devel()` | local-R only | |
| `_pkgdown.yml`, README, ROADMAP, model/source maps agree on boundaries | mostly done | Doc 46 + doc 157 are the boundary sources of truth |

## Profile-Likelihood And Interval Demonstration Gate (#342)

This gate needs a dedicated article, currently missing (profile content is
scattered across existing vignettes but there is no focused demonstration). The
article should be turnkey for a local session. Required content:

- a fitted `drmTMB` example whose profile information is shown end to end:
  fitted estimate, likelihood / likelihood-ratio distance, interval endpoints,
  target name, and engine/source metadata (the provenance columns
  `profile_targets()` and `corpairs()` already expose);
- a coarse first-pass profile and a denser profile, **with timing**, so readers
  see what extra sampling changes and what it costs;
- the profile-likelihood (or likelihood-ratio) curve, not only endpoint
  intervals;
- publication-quality labels, readable scales, and a clear coarse-vs-dense
  distinction.

Review lenses before release (per #342): Gauss/Noether for likelihood and scale
consistency, Fisher for interval interpretation, Florence for the figure,
Pat/Darwin for reader usefulness, Grace for pkgdown/reproducibility, Rose for
stale wording. The article must use eval-on-build code (so `R CMD check` and
pkgdown exercise it), which means it is authored and tested in a local-R
session, not the sandbox.

## Standard Release Sequence (#342)

All local-R only and submission-time: `git pull` on a clean tree,
`usethis::use_version('minor')`, `git push`, draft release notes,
`devtools::submit_cran()`, approve the CRAN email, then the post-acceptance
steps (`use_github_release()`, `use_dev_version()`, announcement).

## What Is Genuinely Ready Now

DESCRIPTION metadata, README install path, NEWS discipline, and the
documentation boundary (docs 46/157/158) are in good shape. The release is
gated on (1) completing the pending capability slices the owner wants in 0.2.0,
(2) running the Phase 18 recovery/coverage and Phase 19 comparator evidence, and
(3) the local CRAN-check sequence and the profile-likelihood demonstration
article — all of which need a local-R machine.
