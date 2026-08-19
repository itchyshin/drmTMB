# Function map and cheat sheet restoration

## 1. Goal

Restore the reader-facing function-map article and both printable aids. After
the maintainer rejected a replacement design, recover and preserve the exact
historical article, audited Image 2.0 map, and original two-page cheat-sheet
design; update only wording, links, package version, and current function
coverage.

## 2. Implemented

- Restored `vignettes/articles/function-map-cheatsheet.Rmd` and the exact
  1536 x 1024 audited PNG from commit `cc4f5baee9128b3d9674f60b25af18f7ea0ae53b`.
- Restored the original two-page cheat-sheet design and ReportLab source from
  preserved Codex checkpoint ref
  `refs/codex/turn-diffs/captures/1786550471672/93d68566-a14b-4f95-98da-c3b71a620bc1/base`.
- Built a new one-page printable workflow map by embedding the audited PNG;
  the checkpoint's separate card-map PDF was not retained. The cheat-sheet
  generator preserves the historical two-page A4 landscape design.
- Updated the cheat sheet from its historical 0.5.0 label to the current
  `DESCRIPTION` version and added current families, mesh helpers,
  distributional assessment functions, and the staged paired-outcome
  association route.
- Added download cards and an accessible-alternative note to the restored HTML
  article.
- Replaced absence fences with positive regression tests for the historical
  PNG, its exact MD5, both printable assets, current exported-function
  coverage, and Image 2.0 provenance.
- Retained the conservative dirty-checkout disposition and `.worktrees/`
  ignore repair from the surrounding cleanup task.

## 3a. Decisions and Rejected Alternatives

The historical design is authoritative because the maintainer explicitly
asked for the original map and cheat sheet. The PNG is not treated as an
unverified orphan: its prompt, Image 2.0 base, deterministic SVG text overlay,
checksums, desktop/mobile renders, and Florence/Pat/Rose PASS verdicts are
retained under `docs/dev-log/figure-audits/2026-08-03-function-map/`.

The paired-outcome helpers remain in their own cheat-sheet card because they
create or consume `drm_pair_association`, not an ordinary fitted `drmTMB`
object. The public map therefore keeps `rho12()` and `corpairs()` in its
ordinary interpretation branch and leaves latent-normal association to the
qualified route table/card.

Rejected: the replacement HTML/CSS card map, replacement base-R PDF designs,
continued absence of the original PNG, a generic Interpret-card association
claim, bulk deletion of ambiguous shared-checkout work, and any merge that
would silently invalidate the immutable CRAN candidate.

## 4. Files Touched

- `.gitignore`
- `inst/COPYRIGHTS`
- `tools/build-function-pdfs.py`
- `tools/function-cheatsheet-source.Rmd`
- `pkgdown/assets/cheatsheets/drmTMB-function-map.pdf`
- `pkgdown/assets/cheatsheets/drmTMB-function-cheatsheet.pdf`
- `vignettes/articles/function-map-cheatsheet.Rmd`
- `vignettes/articles/function-map-cheatsheet.png`
- `tests/testthat/test-function-map-cheatsheet.R`
- `tests/testthat/test-release-identity.R`
- `docs/dev-log/2026-08-19-dirty-checkout-disposition.md`
- `docs/dev-log/team-improvements.md`
- `docs/dev-log/check-log.md`
- this report

The abandoned replacement generators
`tools/function-map-inventory.R` and
`tools/build-function-cheatsheets.R` are removed.

## 5. Checks Run

- Historical PNG SHA-256: PASS,
  `ad709c25d9942ed8e03b08d0e24ffece20f3161e81587e25b04dad12f287729d`.
- `tools/build-function-pdfs.py`: PASS with current-export coverage validation.
- `pdfinfo`: PASS; map is one 12 x 8 inch page and cheat sheet is two A4
  landscape pages.
- Fresh 150-dpi Poppler renders: PASS; all three pages were inspected after the
  final generation, with no clipping or footer overlap.
- `pkgdown::build_article("articles/function-map-cheatsheet", lazy = FALSE)`:
  PASS.
- Function-map focused tests: PASS, 70 expectations.
- Release-identity focused tests: PASS, 17 expectations.
- Reader-navigation Python contract: PASS, 1 test.
- `pkgdown::check_pkgdown()`: PASS, no problems found.
- Florence visual review: PASS. Pat applied-user review: PASS. Rose content and
  provenance review: PASS; release integration remains HOLD for the
  immutable-candidate boundary.

The in-app browser connector failed to initialize because its bundled runtime
attempted a prohibited Node import. No fresh browser-width claim is made from
that failed tool. The article retains the exact previously audited responsive
map and route-table implementation; the new download cards use an explicit
single-column rule below 540 pixels.

## 6. Tests of the Tests

The original-PNG test checks the recovered file's exact MD5 rather than file
presence alone. The source coverage test derives current exports from
`NAMESPACE`, excludes only the two deprecated compatibility markers, and
requires every remaining export to appear in the cheat-sheet source. The PDF
generator independently enforces the same open-ended export contract before
writing either asset. During render review, the new distributional-assessment
card initially crossed the footer; compacting that card and re-rendering
closed a defect that source tests could not see.

## 7a. Issue Ledger

Fixed here: missing historical article/map, missing printable downloads,
obsolete 0.5.0 PDF label, omitted current exports, a false no-AI provenance
statement, regression tests that forbade the intended original PNG, and stale
replacement-generator files. Deferred: tagged-PDF accessibility and ambiguous
user/foreign-agent changes in the shared checkout.

No model, likelihood, formula grammar, capability tier, simulation fixture, or
Julia fitting route changed.

## 8. Consistency Audit

The article, exact PNG, map PDF, cheat-sheet PDF, current-version label,
download links, source tables, NAMESPACE-derived tests, and provenance note
agree. The ordinary map and the staged association card preserve their object
boundary. The HTML article is named as the accessible version and the PDFs as
untagged print companions.

The article source and historical image match the audited August 3 reader
path. The PDF map uses that same image rather than a visually similar redraw.

## 9. What Did Not Go Smoothly

The first restoration attempt reconstructed the concept instead of recovering
the actual historical artifacts. Although that replacement was internally
reviewed, it did not satisfy the maintainer's request and was discarded. Git
history contained the exact article/PNG, while the two-page cheat-sheet design
and generator survived only in a preserved Codex checkpoint. That checkpoint's
map PDF was a separate rejected card design, so the restored Image 2.0 PNG is
embedded directly in the newly generated map PDF.

Adding current exports to the old two-page layout caused a footer overlap in
the first render. A second render still touched the footer. The final targeted
spacing adjustment affected only the new distributional-assessment block and
passed visual inspection.

## 10. Known Residuals

The PDFs are untagged print companions. The HTML article carries the detailed
alt text, route table, and function links for assistive-technology users.
ReportLab and the host font are not pinned, so byte-identical cross-host PDF
regeneration is not promised; pin that build environment if deterministic PDF
bytes become a future requirement.

Five build-included paths differ from immutable release candidate `6170fbeee`:
`inst/COPYRIGHTS`, both focused test files,
`vignettes/articles/function-map-cheatsheet.Rmd`, and the restored PNG. The
candidate's exact tarball hash is
`1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`.
Merge and deployment remain held until after submission unless the maintainer
explicitly reopens the exact-byte release gate. Therefore no live-site claim
is made here.

## 11. Team Learning

When a user asks to restore an artifact, search commit history, all refs, and
preserved task checkpoints before designing a substitute. Visual similarity is
not provenance. A replacement should be offered only after the original is
shown to be unrecoverable or the user chooses a redesign.

Golden Set: not in scope. This reader-navigation repair changes no estimator or
inference implementation.

## 12. Cross-Product Coverage

Covers: historical source recovery, exact raster identity, original printable
design, current exported-function coverage, article rendering, PDF rendering,
download paths, provenance, source-only regression tests, and a conservative
release/dirty-checkout boundary.

Does NOT cover: live deployment, CRAN submission, tagged-PDF production,
modelling behaviour, capability promotion, or deletion of ambiguous local
work.
