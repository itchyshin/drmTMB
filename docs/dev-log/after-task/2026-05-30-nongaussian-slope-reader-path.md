# After Task: Non-Gaussian Slope Reader Path

## Goal

Fix small reader-path omissions around selected non-Gaussian independent `mu`
slopes and animal/`relmat()` one-slope support.

## Implemented

- README current-boundaries prose now mentions selected non-Gaussian `mu`
  independent numeric slopes, while keeping them at source-test status.
- `vignettes/model-map.Rmd` now has a direct question row for repeated groups
  with non-Gaussian mean random effects.
- The model-map structural-dependence prose now mentions the fitted one numeric
  Gaussian `mu` slope for animal and `relmat()` routes.

## Mathematical Contract

No likelihood, formula grammar, extractor, simulation runner, or status label
changed. This was a prose consistency patch.

## Files Changed

- `README.md`
- `vignettes/model-map.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

No R tests were needed because no executable behaviour changed. The targeted
render checks the edited vignette can still build.

## Consistency Audit

The wording keeps selected non-Gaussian slopes as focused source-test evidence,
not broad recovery, coverage, or structured-dependence support.

## GitHub Issue Maintenance

This slice advances #441 and #444 after the commit is pushed.

## What Did Not Go Smoothly

The status table already had the correct claim, while nearby prose lagged
behind it. The fix was to add the missing phrases without expanding scope.

## Team Learning

When a dense status table changes, Pat should scan the surrounding question
path so applied readers can find the same capability without decoding the
whole table.

## Known Limitations

The selected non-Gaussian independent `mu` slopes still need an artifact lane
before recovery, coverage, or power claims.

## Next Actions

Use the #441 operating-characteristic design to decide which source-tested
families should receive the first artifact lane.
