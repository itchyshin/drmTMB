# drmTMB 0.2.0 Release-Readiness Checklist

This note consolidates the 0.2.0 release track (#342) and the Phase 20
CRAN/paper-preparation gate (#61) into one status checklist. The reader is the
project owner running the release from a local machine, and the contributor
preparing the prerequisites. Each item is marked **done**, **external**, or
**pending**.

Release type: minor, `0.1.3.9000 -> 0.2.0`, because `NEWS.md` records many new
user-facing features and validation lanes rather than a patch-only fix.

## 2026-06-07 Local CRAN-Readiness Update

Local CRAN hygiene is now in a submit-rehearsal state for `drmTMB 0.2.0`.
The source tree has CRAN install wording, release-candidate metadata,
`cran-comments.md`, `.Rbuildignore` coverage for `cran-comments.md`, regenerated
Rd examples for `gr()`, `meta_known_V()`, and `imputed()`, a URL-clean figure
gallery, and a rebuilt pkgdown site.

Local checks completed on macOS with R 4.5.2:

- `urlchecker::url_check()` passed.
- `tools::checkRd()` over all Rd files produced no output.
- The exported help-topic audit found 42 exports and no missing `\value` or
  `\examples` sections.
- `devtools::test()` passed with 10,139 expectations, 0 failures, 0 warnings,
  and 0 skips.
- `pkgdown::check_pkgdown()` found no problems.
- `pkgdown::build_site(preview = FALSE)` completed successfully; the site build
  emitted the known local `glmmTMB`/`TMB` version-mismatch warning during article
  rendering.
- `devtools::check(manual = TRUE, cran = TRUE, remote = TRUE, incoming = TRUE,
  force_suggests = TRUE, args = c("--timings", "--as-cran"),
  error_on = "never")` completed with 0 errors, 0 warnings, and 2 notes: the
  expected first-submission/tarball-size incoming note and a local old-HTML-Tidy
  validation skip.

The remaining external/release actions are `devtools::check_win_devel()`, actual
CRAN submission and email approval, and post-acceptance release steps.
The paper-preparation/profile-demonstration gate in Phase 20 remains a separate
owner decision, not a local CRAN-check failure.

## Scope Freeze Still Required

The earlier caution that release preparation should not start is superseded for
CRAN-hygiene work by the 2026-06-07 local checks above. A final release decision
still needs owner scope freeze: confirm that no pending capability slice is being
held for `0.2.0`, and keep fitted, first-slice, opt-in, planned, and unsupported
surfaces separated in the public docs.

## 2026-06-08 Capability Freeze

The working 0.2.0 capability freeze admits only three pre-CRAN additions beyond
the 2026-06-07 CRAN-hygiene sprint:

1. keep the release-candidate hygiene edits from the local check sprint;
2. add a focused profile-likelihood demonstration article that renders the
   likelihood-ratio curve, fitted estimate, cutoff, interval endpoints, and
   coarse-versus-dense profile distinction;
3. admit `skew_normal()` only as a univariate fixed-effect
   location-scale-shape first slice with `mu`, `sigma`, and `nu` formulas.

Everything else remains out of the 0.2.0 release target unless the owner
explicitly reopens the freeze. That includes q8 coverage or power promotion,
correlated non-Gaussian random slopes, structured slopes beyond the existing
first slices, skew-normal random or structured effects, bivariate skew-normal
models, random effects in `rho12`, large-data/GVA work, and mixed-response
bivariate families. These are capability or evidence projects, not CRAN
hygiene fixes.

The freeze is conditional on local verification after the new article and
`skew_normal()` docs are regenerated. If `devtools::document()`, focused
tests, pkgdown rendering, or a CRAN-style check exposes a release-risking
failure, the new slice should be parked rather than broadening the release at
the last minute.

## 2026-06-08 Completion Update

The three-item pre-CRAN capability slice is now implemented locally. The
release-candidate hygiene edits remain in place, the profile-likelihood article
renders with a likelihood-ratio curve and figure audit evidence, and
`skew_normal()` fits the fixed-effect univariate `mu`/`sigma`/`nu` first slice.
The fitted surface still excludes skew-normal random effects, structured
effects, known sampling covariance, bivariate skew-normal models, residual
`rho12`, and latent `skew(id)` syntax.

Checks completed after the slice:

- `devtools::document()` regenerated the new `skew_normal()` reference topic
  and touched the roxygen-linked help pages.
- Focused tests for skew-normal, family-link contracts, and profile plots
  passed.
- Full `devtools::test(reporter = "summary")` passed.
- `pkgdown::build_article("profile-likelihood")`,
  `pkgdown::check_pkgdown()`, and `pkgdown::build_site(preview = FALSE)`
  passed; the site build retained the known local `glmmTMB`/`TMB`
  version-mismatch warning during article rendering.
- `urlchecker::url_check()` passed.
- `tools::checkRd()` over all Rd files produced no output.
- The CRAN-style `devtools::check(..., cran = TRUE, remote = TRUE,
  incoming = TRUE, manual = TRUE, args = c("--timings", "--as-cran"))`
  completed with 0 errors, 0 warnings, and 3 notes: first-submission/tarball
  size, local future-timestamp verification, and local old-HTML-Tidy manual
  validation skip.

## First-Release CRAN Hygiene (#342)

| Item | Status | Note |
| --- | --- | --- |
| `usethis::use_cran_comments()` | done | `cran-comments.md` exists and is ignored from the built tarball |
| README install instructions match release channel | done | README and getting-started article now use `install.packages("drmTMB")` |
| `Title:` / `Description:` proofread | done | DESCRIPTION uses release version `0.2.0`, quotes `'TMB'`, avoids development wording, and keeps `cph` role present |
| Exported functions have `@return` and runnable/skipped `@examples` | done | Local audit found 42 exports with 0 missing `\value` and 0 missing `\examples`; `R CMD check` examples passed |
| `Authors@R` includes `cph` | done | Shinichi Nakagawa holds `aut`, `cre`, `cph` |
| Bundled-file licensing / `inst/COPYRIGHTS` | done | Current `inst/COPYRIGHTS` says no source code has been ported from other modelling packages |

## drmTMB Release Gates (#342)

| Item | Status | Note |
| --- | --- | --- |
| Reconcile any dirty worktree / parked artifact lanes | pending | Commit or PR the 2026-06-07 CRAN-readiness edits before submission |
| Every included feature has NEWS, tests, docs, examples, check-log, after-task | done locally | Maintained per slice; the 2026-06-07 CRAN sprint and 2026-06-08 capability slice both have check-log and after-task evidence |
| `devtools::document()` after roxygen settles | done | Regenerated `skew_normal.Rd` plus touched `drmTMB.Rd`, `sigma.drmTMB.Rd`, and `check_drm.Rd`; the earlier sprint regenerated `gr.Rd`, `meta_known_V.Rd`, and `imputed.Rd` |
| Focused tests for recently changed lanes | done | Skew-normal, family-link, and profile-plot focused tests passed |
| `devtools::test()` | done | Full summary reporter run passed |
| `devtools::check(remote = TRUE, manual = TRUE)` | done | 0 errors, 0 warnings, 3 notes under CRAN-style incoming/manual/remote settings |
| `pkgdown::check_pkgdown()` + review rendered HTML | done | `check_pkgdown()` passed; `build_article("profile-likelihood")` and `build_site()` completed; the rendered profile figure was inspected and recorded under `docs/dev-log/figure-audits/` |
| `urlchecker::url_check()` | done | All URLs correct after replacing the failing figure-gallery DOI hyperlink |
| `devtools::check_win_devel()` | external | Not run in this local sprint |
| `_pkgdown.yml`, README, ROADMAP, model/source maps agree on boundaries | done locally | The CRAN-install, release-candidate, profile-article, and fixed-effect skew-normal boundaries are synchronized; remaining capability debt stays explicitly planned or unsupported |

## Profile-Likelihood And Interval Demonstration Gate (#342)

This gate is done locally through `vignettes/profile-likelihood.Rmd`. The
article fits a small Gaussian location-scale model, shows `profile_targets()`,
profiles response-scale `sigma` with `compare = TRUE`, reports timing and
engine metadata, plots the likelihood-ratio curve with the fitted estimate,
95% cutoff, and profile endpoints, and then shows the endpoint-only
`confint()` result.

The figure audit is recorded under
`docs/dev-log/figure-audits/2026-06-08-profile-likelihood-article/`. Role
perspectives checked the rendered curve: Gauss/Noether for likelihood and scale
consistency, Fisher for interval interpretation, Florence for figure
legibility, Pat/Darwin for reader usefulness, Grace for pkgdown
reproducibility, and Rose for stale wording.

## Standard Release Sequence (#342)

Remaining external and submission-time steps: `git pull` only after the current
worktree is clean or intentionally parked, commit or PR this release-candidate
slice, run `devtools::check_win_devel()`, submit with `devtools::submit_cran()`
when intended, approve the CRAN email, then complete post-acceptance steps such
as `usethis::use_github_release()`, `usethis::use_dev_version()`, and the
release announcement.

## What Is Genuinely Ready Now

CRAN submission hygiene is locally ready enough for an owner submission
decision: metadata, README install path, NEWS version, exported examples, URLs,
Rd, tests, pkgdown, and CRAN-style local check have current evidence. The
release is still gated on (1) committing or PR-ing the release-candidate edits,
(2) running external Windows/devel checks, (3) actual CRAN submission and email
approval, and (4) any owner-retained paper/profile-demonstration gate.
