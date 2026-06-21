# After Task: CRAN Readiness Sprint

## Goal

Move the current `drmTMB` source tree into a local CRAN submit-rehearsal state
for `0.2.0` by tomorrow, without widening model scope or hiding validation debt.

## Implemented

The package metadata now targets `0.2.0`, README and getting-started install
instructions use `install.packages("drmTMB")`, `cran-comments.md` records the
local check notes, and `.Rbuildignore` keeps `cran-comments.md` out of the
source tarball. Exported topics `gr()`, `meta_known_V()`, and `imputed()` now
have examples, and the figure gallery no longer links to the DOI URL that
returned 403 under `urlchecker::url_check()`.

## Mathematical Contract

No likelihood, formula grammar, optimizer, extractor, or simulation estimand
changed. This task changed release metadata, documentation, examples, and
submission hygiene only.

## Files Changed

- `.Rbuildignore`
- `DESCRIPTION`
- `NEWS.md`
- `R/formula-markers.R`
- `R/missing-data.R`
- `README.md`
- `_pkgdown.yml`
- `cran-comments.md`
- `docs/design/159-drmtmb-0-2-0-release-readiness.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`
- `man/gr.Rd`
- `man/imputed.Rd`
- `man/meta_known_V.Rd`
- `vignettes/drmTMB.Rmd`
- `vignettes/figure-gallery.Rmd`

## Checks Run

- `devtools::document()` regenerated the three touched Rd files.
- `air format` ran on the touched R files.
- `urlchecker::url_check()` passed.
- `tools::checkRd()` over all Rd files produced no output.
- Exported-topic audit found 42 exports, 0 missing `\value`, and 0 missing
  `\examples`.
- `devtools::test()` passed with 10,139 expectations, 0 failures, 0 warnings,
  and 0 skips.
- `pkgdown::check_pkgdown()` returned no problems.
- `pkgdown::build_site(preview = FALSE)` completed successfully and rebuilt
  `pkgdown-site/`, with the known local `glmmTMB`/`TMB` version-mismatch warning.
- Final `devtools::check(manual = TRUE, cran = TRUE, remote = TRUE,
  incoming = TRUE, force_suggests = TRUE, args = c("--timings", "--as-cran"),
  error_on = "never")` completed with 0 errors, 0 warnings, and 2 notes.
- Rendered-page scans found no stale pre-CRAN, `0.1.3.9000`, GitHub-tag install,
  or failing DOI-link text in the checked source and pkgdown pages.

## Tests Of The Tests

The first CRAN-style check caught a real package issue:
`cran-comments.md` was included as a non-standard top-level file. Adding
`^cran-comments\.md$` to `.Rbuildignore` removed that NOTE in the rerun. The
new `imputed()` example was also run directly and returned the expected
missing-predictor rows before full examples passed under `R CMD check`.

## Consistency Audit

`README.md`, `vignettes/drmTMB.Rmd`, `_pkgdown.yml`, `NEWS.md`,
`DESCRIPTION`, generated reference pages, and rendered pkgdown pages now agree
on the `0.2.0` release-candidate and CRAN-install wording. The current
release-readiness checklist records the two remaining local-check notes and
keeps external Windows/devel checks, CRAN submission, and paper-prep/profile
demonstration gates separate from local CRAN hygiene.

## GitHub Issue Maintenance

Issue #342 was inspected and updated with the detailed local CRAN-readiness
evidence:
<https://github.com/itchyshin/drmTMB/issues/342#issuecomment-4644488407>.
Issue #61 was inspected and updated with the Phase 20 split between CRAN
hygiene and remaining paper/release actions:
<https://github.com/itchyshin/drmTMB/issues/61#issuecomment-4644488932>.

## What Did Not Go Smoothly

The first check produced a fixable NOTE because `cran-comments.md` was created
before `.Rbuildignore` was updated. The local macOS machine also has Apple HTML
Tidy from 2006, so `R CMD check` skipped HTML manual validation and reported a
local-tooling NOTE.

## Team Learning

Create or update `.Rbuildignore` at the same time as `cran-comments.md`. For
deprecated exported helpers, use warning-suppressed examples so compatibility
syntax is documented without making example output noisy.

## Known Limitations

The local CRAN-style check has 2 notes: expected first-submission/tarball-size
incoming metadata and old local HTML Tidy. `devtools::check_win_devel()`, CRAN
submission, CRAN email approval, and post-acceptance release steps were not run.
The broader Phase 20 paper-preparation/profile-demonstration gate remains an
owner release-policy decision, not a local check failure.

## Next Actions

Commit or PR the release-candidate edits, run `devtools::check_win_devel()`,
then decide whether to submit to CRAN now or hold for any owner-retained
paper/profile-demonstration gate.
