# After task: family and count reader guidance

## Goal

Help biology PhDs choose a response family and distinguish abundance,
overdispersion, and structural zeros without decoding development terminology.

## Implemented

Rewrote capability lists as model choices and concrete evidence limits. The
count tutorial leads with `mu`, `sigma`, and `zi`, then explains how grouped
or structured effects answer additional questions. The family guide connects
measurement type, model parameters, and the next tutorial.

## Mathematical contract

Executable R chunks and display equations in both pages are byte-identical to
base `ac886734c554d27c63e00388cfe5bb2b760905dc`. Point-estimate and interval
evidence remain distinct. Simulation design numbers were retained in plain
words. No likelihood, formula grammar, API, version, or release claim changed.

## Files changed

- `vignettes/distribution-families.Rmd`
- `vignettes/count-nbinom2.Rmd`
- `tools/tests/test_capability_ledger.py` (four reader-text tests only)
- `docs/dev-log/check-log.d/2026-09-20-reader-family-count.md`
- This report.

## Checks run

- `Rscript tools/check-reader-contracts.R`: PASS.
- `Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-public-surface.R", reporter="summary")'`: PASS, four expectations.
- `pkgdown::build_article()` for both pages, with destination
  `/private/tmp/drmtmb-reader-family-render`: PASS. Used installed drmTMB 0.7.1
  with `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=4`, and
  `VECLIB_MAXIMUM_THREADS=4`. No compilation was needed. This checks the
  tutorial against that installed package, not a new build of source.
- Both fits in rendered `count-nbinom2.html` report 16 checks OK,
  zero notes, zero warnings, and zero errors.
- Scratch `/private/tmp/check-family-count-reader.R`: PASS for unchanged
  executable chunks and display equations, expected new prose in `<main>`, and
  zero forbidden terminology matches in both Rmd sources and rendered HTML.
- `git diff --check`: PASS.
- Full `tools.tests.test_capability_ledger` suite: 80/80 PASS after updating
  four tests that required the removed process labels literally.
- The adjacent Python suites from the same CI step (profile reconcilers,
  target promotion, CI guard, CI C1, and profile truth): 47/47 PASS.
- `python3 tools/capability_ledger.py --check`: PASS, 31 generated outputs.

## Tests of the tests

The existing public-surface test rejects a synthetic page containing an issue
number and implementation-lane prose, and accepts ordinary scientific prose.
The four capability tests retain their scientific limits and exact route
checks in plain language, and reject the old internal labels on these pages.
In-memory negative controls confirmed that the updated check rejects both
restoring `diagnostic-only gate` and falsely saying the intervals have been
validated. The focused scratch scan checked these exact patterns:
`\bgates?\b`, `\bledger\b`, `recovery[ -]grade`, `diagnostic-only`,
`\bq\s*=?\s*[124]\b`, `mc-[0-9]+`, `inference[_ -]ready`, `docs/dev-log`,
and `\b(?:PR|issue)\s*#[0-9]+`.

## Consistency audit

The family guide's later skew-normal and Tweedie paragraphs said all random
effects remained planned, contradicting its own table. Both now describe
ordinary mean intercepts and independent slopes. Existing source tests confirm
these choices: `test-arc2a-mu-random-intercept.R:40`,
`test-arc2b-mu-random-slope.R:64`, and
`test-arc2b-mu-random-slope.R:85`. These tests were inspected, not rerun.
The relatedness hurdle paragraph now says fitting was checked but estimation
accuracy and intervals remain unvalidated, matching the count page's evidence.

## GitHub issue maintenance

Searched open issues for reader documentation. No issue matched this bounded
wording repair; no issue was closed or commented on. The PR records the scope.

## What did not go smoothly

The first render issued a sandbox warning when Sass tried to write its shared
cache. Both HTML files were written successfully. Subsequent family-page
renders completed without that warning. Automatic approval review rejected
editing the shared check log because of ownership concerns and requested an
isolated `check-log.d` entry; this report uses that alternative.

The first CI run (35523181977, head `922339d32`) failed four capability tests
that froze the removed wording. All four reproduced locally; substituting only
the two baseline page texts made all four pass. The explicitly authorized
repair updates only those four tests to check the same routes and limitations.

## Team learning

Keep simulation design detail beside the affected model. Introductory family
tables work better when they explain the response type and next modelling
choice. A working fit and validated uncertainty require different statements.

## Design and documentation updates

No design documents changed because behavior is unchanged. Rendered HTML is
local verification output; the normal pkgdown workflow will publish the Rmd
changes. Figures, assets, package tests under `tests/`, and workflow files
were untouched; the four documentation assertions in `tools/tests/` were updated.

## Known limitations and next actions

This is a two-page prose repair, not a whole-site audit or new statistical
validation. Full package checks and visual screenshot review were not run.
Review and merge the bounded PR, then confirm the deployed pages after the
normal site build. Other articles and generated capability tables retain their
separate owners.
