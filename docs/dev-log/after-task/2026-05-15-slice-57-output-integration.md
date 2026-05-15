# Slice 57 output integration

Date: 2026-05-15

## Goal

Make confidence-interval output say clearly whether a row has an interval, can
be profiled, needs `newdata`, or remains unavailable.

## What changed

- Added `conf.status` to successful `confint()` output rows.
- Added `conf.status` to interval-aware `summary()` coefficient and parameter
  tables.
- Reused one profile-note-to-status helper for `summary()` and `corpairs()`.
- Added tests for Wald/profile statuses, ready-but-unselected rows,
  `newdata_required` fitted surfaces, and printed parameter-table status
  exposure.
- Updated `docs/design/12-profile-likelihood-cis.md`, `ROADMAP.md`, `NEWS.md`,
  and generated Rd files.

## Standing-review notes

- Ada: this is an output-contract slice, not a statistical-method slice.
- Boole: `conf.status` now has the same meaning in `confint()`, `summary()`,
  and `corpairs()` outputs.
- Fisher: the status column reduces the chance that users treat missing
  variance-component or correlation intervals as accidental omission.
- Emmy: the implementation keeps interval math in the existing `confint()`
  helpers and only annotates returned tables.
- Pat: printed parameter tables now show status when interval columns would
  otherwise contain only `NA`.
- Grace: focused profile, summary, covariance, bivariate, and phylogenetic tests
  are the local gate before full tests and pkgdown.
- Rose: derived intervals, q4 covariance-function intervals, and covariance
  product intervals remain deliberately unavailable.

## Checks

- `Rscript -e 'devtools::test(filter = "summary|profile-targets", reporter = "summary")'`:
  first run found test expectations that omitted the fitted `sigma`
  coefficient row.
- `Rscript -e 'devtools::test(filter = "summary|profile-targets", reporter = "summary")'`:
  passed after correcting the test expectations.
- `Rscript -e 'devtools::document()'`:
  passed and updated `man/confint.drmTMB.Rd` and `man/summary.drmTMB.Rd`.
- `Rscript -e 'devtools::test(filter = "summary|profile-targets|corpairs|covariance-block-registry|phylo-gaussian|biv-gaussian", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(reporter = "summary")'`:
  passed.
- `pkgdown::build_site()` and `pkgdown::check_pkgdown()`:
  passed.
- `git diff --check` and source/rendered wording scans:
  passed.

## Known limitations

- No new interval method was added.
- `conf.status` explains unsupported intervals but does not make derived
  intervals available.
