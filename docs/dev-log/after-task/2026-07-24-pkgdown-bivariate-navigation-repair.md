# After Task: Pkgdown bivariate navigation repair

## Goal

Show the bivariate non-Gaussian article in one navigation route rather than in
both Tutorials and Specialist Routes.

## Implemented

Removed the Tutorials-menu link. The article remains under Specialist Routes,
where the homepage article index already places it.

## Mathematical Contract

None. This is a reader-navigation correction; it changes neither syntax nor
model behaviour.

## Files Changed

- `_pkgdown.yml`
- `docs/dev-log/check-log.md`
- this report

## Checks Run

- `yaml::read_yaml()` parsed `_pkgdown.yml`.
- An explicit assertion found exactly one navbar URL and one article-index slug
  for `bivariate-nongaussian`.
- `pkgdown::check_pkgdown()`: PASS, no problems found.
- `git diff --check`: PASS.

## Tests Of The Tests

The assertion checks both reader surfaces affected by the defect: the top
navbar and the homepage article index. It would fail if either gained a second
copy or if the remaining Specialist Routes entry were removed.

## Consistency Audit

`_pkgdown.yml` now agrees with its canonical-order comment: the bivariate
non-Gaussian article belongs once in Specialist Routes. No model, formula,
README, NEWS, roadmap, or limitation wording changed.

## GitHub Issue Maintenance

An open-issue search for `pkgdown navigation bivariate` returned no matching
issue. The focused repair is tracked by PR #829.

## What Did Not Go Smoothly

The sandboxed local site build could not resolve CRAN metadata. A rerun with
network and cache access began normally, but the runner ended before rendering
the article page. The CI Pages build remains required before claiming the live
site is refreshed.

## Team Learning

When adding an article, update both navbar and `articles:` membership together,
then assert that each article URL occurs once across the navigation surface.

## Known Limitations

This does not change the article's beta status or any model capability. The
public page changes only after PR #829 is merged and its Pages workflow passes.

## Next Actions

Review and merge PR #829, then confirm the deployed article menu contains the
single Specialist Routes entry.
