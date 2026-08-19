# Function map and cheat sheet restoration

## 1. Goal

Restore the missing reader-facing drmTMB function map and printable cheat sheet,
find neighbouring defects under the Rose principle, and make only conservative
cleanup changes around the shared checkout's roughly 100 displayed paths.

## 2. Implemented

- Added one reviewed six-route inventory for specification, fitting, fit-health
  checks, interpretation, prediction/assessment, and uncertainty/simulation.
- Generated two distinct one-page PDF products from that inventory: a 16:9
  workflow map and an A4 landscape task/function lookup sheet.
- Embedded a responsive, text-native HTML map in the existing pkgdown article,
  with 27 individual reference links and explicit download cards for both PDFs.
- Added source contracts for exports, S3 methods, compatibility-only functions,
  Rd topic targets, PDF presence, and continued absence of the obsolete PNG.
- Recorded first-party provenance in `inst/COPYRIGHTS` and kept the generator
  under build-excluded `tools/` and the outputs under build-excluded `pkgdown/`.
- Added `.worktrees/` to `.gitignore` and wrote an owner-aware disposition for
  the remaining dirty shared-checkout paths without deleting or moving them.

## 3a. Decisions and Rejected Alternatives

The HTML map is the accessible, linked source of truth. The PDFs are explicitly
labelled untagged print companions. The workflow map uses arrows plus headings,
numbers, and a written branch cue, so colour and arrows are not the only carriers
of meaning. The A4 sheet deliberately omits route prose to serve a different job:
fast task-to-function lookup at readable type size.

The implementation rejected the old unverified raster, third-party artwork,
AI-generated imagery, bundled fonts, and a manually duplicated function list.
It also rejected bulk deletion, reset, rebase, stash manipulation, or worktree
removal in the shared checkout because ownership is ambiguous and active work is
present. No model, likelihood, capability tier, release gate, or Julia route was
changed.

## 4. Files Touched

- `.gitignore`
- `inst/COPYRIGHTS`
- `tools/function-map-inventory.R`
- `tools/build-function-cheatsheets.R`
- `pkgdown/assets/cheatsheets/drmTMB-function-map.pdf`
- `pkgdown/assets/cheatsheets/drmTMB-function-cheatsheet.pdf`
- `vignettes/articles/function-map-cheatsheet.Rmd`
- `tests/testthat/test-function-map-cheatsheet.R`
- `tests/testthat/test-release-identity.R`
- `docs/dev-log/2026-08-19-dirty-checkout-disposition.md`
- `docs/dev-log/team-improvements.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-08-19-function-map-cheatsheet-restoration.md`

## 5. Checks Run

- `Rscript --vanilla tools/build-function-cheatsheets.R`: PASS; wrote both PDFs.
- `pkgdown::build_article(..., lazy = FALSE)`: PASS; executed the article and
  rebuilt `articles/function-map-cheatsheet.html`.
- `testthat::test_file("tests/testthat/test-function-map-cheatsheet.R")`: PASS,
  19 expectations.
- `testthat::test_file("tests/testthat/test-release-identity.R")`: PASS,
  13 expectations.
- Reader-navigation Python contract: PASS, 1 test.
- `pkgdown::check_pkgdown()`: PASS, no problems found.
- Source/site PDF byte comparison after refreshing ignored static assets: PASS.
- `pdfinfo`: PASS; both PDFs are one page, with the map at 1152 x 648 points and
  the lookup sheet at A4 landscape 841 x 595 points.
- Final 390-pixel browser audit: document/body/viewport widths all 390 pixels,
  all cards inside the viewport, one map column, 27 function links, and only the
  labelled route table horizontally scrollable (366-pixel client width,
  736-pixel scroll width, `overflow-x: auto`, keyboard focus enabled).
- `git diff --check`: PASS. The obsolete PNG is absent.
- Florence visual review: PASS. Pat applied-user review: PASS. Rose content
  audit: PASS; release integration: HOLD for the immutable candidate boundary.

## 6. Tests of the Tests

The checks caught real defects during development. The first test run rejected
an unsupported `expect_empty()` helper. Render inspection found roughly 5-point
PDF text and a compact-sheet overlap that source inspection missed. The first
full-page mobile evidence showed clipping, which prompted fresh width metrics
and viewport captures. Rose and Pat independently found that the initially
generated `bf()` link targeted nonexistent `bf.html`; the topic-target test now
guards the repaired `drm_formula.html` alias and every other generated target.
The old-PNG absence assertion was restored after Rose noticed its removal.

## 7a. Issue Ledger

No dedicated open issue describes the missing function map. Read-only issue
search found broad documentation/release issue #61, but this repair neither
changes its release status nor closes it. Fixed here: missing visual/downloads,
tiny and low-contrast print text, duplicated PDF jobs, broken `bf()` link,
duplicate route note, over-verbose first-fit output, lost PNG regression fence,
and incomplete mobile proof. Deferred: tagged PDF generation and the ambiguous
shared-checkout paths.

## 8. Consistency Audit

The inventory is shared by HTML and both PDFs. Every featured export exists in
`NAMESPACE`; every featured generic is registered for `drmTMB`; compatibility
aliases remain out of the primary map; every generated reference target maps to
an Rd topic. The article, `_pkgdown.yml` navigation, local pkgdown output, PDF
downloads, tests, provenance note, and public-language navigation contract agree.
The map states that fit success is not universal inference support and keeps the
Julia route optional/deferred.

## 9. What Did Not Go Smoothly

The first visual design passed file-existence and clipping checks but failed the
reader test: type was too small, contrast was weak, and the two PDFs did the same
job. Full-page mobile evidence was initially misleading, and pkgdown's focused
article build did not refresh already-present static PDF copies. The browser
connector could not launch in this runtime, so local Playwright/Chrome supplied
the same read-only viewport evidence. Finally, filename-equals-function-name was
a false assumption for the `bf()` Rd alias. Each failure was retained as a
specific test or team-improvement rule rather than hidden.

## 10. Known Residuals

The PDFs are untagged and use non-embedded base Helvetica fonts; the download
copy therefore points assistive-technology users to the selectable, linked HTML
map. The shared mission-control checkout remains intentionally dirty. Its 102
collapsed status rows require owner-aware subject cleanup; only the structural
`.worktrees/` noise has a safe repository-level remedy here. Three changed files
are build-included in the immutable `6170fbeee` release candidate, so merging
this repair before submission would invalidate its exact-byte evidence. The safe
default is a CI-checked hold PR for post-submission merge/deploy; reopening the
release gate requires explicit maintainer authority. Live URL verification is
therefore also withheld. PDF presence and size are automated, while source/site
byte equality remains a manual gate; a future generator `--check` mode could
make that drift check automatic.

## 11. Team Learning

Memory receipt: `/ask-brain`, the repo route manifest, WHAT-WORKS/guard context,
the figure-visual-audit discipline, and prior provenance history were applied.
No brain-vault write was made because the repository guard requires separate
explicit approval; the durable delta is recorded in this repository.

Golden Set: not in scope. This reader-navigation repair changes no likelihood,
estimator, formula grammar, simulation fixture, capability tier, or inference
claim, so model Golden Set fixtures were neither edited nor rerun.

## 12. Cross-Product Coverage

Covers: source inventory, article prose and HTML, both generated PDFs, direct
function links, desktop/mobile responsiveness, local pkgdown navigation,
provenance, source-only regression tests, and a conservative git disposition.

Does NOT cover: tagged/embedded-font PDF accessibility, package modelling
behaviour, CRAN readiness, Julia fitting, capability promotion, deletion of
ambiguous local work, or external live-site state before the post-submission
merge/deploy gate.
