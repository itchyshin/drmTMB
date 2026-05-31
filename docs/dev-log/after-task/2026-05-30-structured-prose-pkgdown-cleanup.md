# After Task: Structured Prose and pkgdown Cleanup

## Goal

Fix reader-facing stale wording around Gaussian structured one-slope support,
animal/`relmat()` known-matrix readiness, spatial status, and pkgdown reference
navigation.

## Implemented

- Updated README structured-effect prose to split fitted syntax from artifact
  readiness.
- Updated `vignettes/phylogenetic-spatial.Rmd` so animal, `relmat()`,
  phylogenetic, and spatial status reflects fitted one numeric Gaussian `mu`
  slopes without implying multiple structured slopes or slope correlations.
- Updated `vignettes/formula-grammar.Rmd` so planned phylogenetic neighbours
  no longer conflict with implemented `sigma` intercept and matching
  covariance routes.
- Updated `_pkgdown.yml` reference-section prose to emphasize status-marked
  fitted and planned syntax.

## Mathematical Contract

No likelihood, formula grammar, extractor, registry row, Actions task,
simulation runner, artifact schema, recovery result, coverage result, or power
result changed. This was a reader-facing documentation consistency cleanup.

## Files Changed

- `README.md`
- `_pkgdown.yml`
- `vignettes/formula-grammar.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-structured-prose-pkgdown-cleanup.md`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

No R tests were needed because the change did not alter executable code or
formula parsing. The validation used stale-phrase scans, positive evidence
scans, targeted pkgdown rebuilds, and `git diff --check`.

## Consistency Audit

The cleanup keeps the current boundary visible: one numeric Gaussian `mu`
slope is fitted for `phylo()`, `spatial()`, `animal()`, and `relmat()`;
`spatial_mu_slope` is the current manual Actions task; `phylo()`, `animal()`,
and `relmat()` one-slope artifacts remain wrapper targets; q2/q4 covariance,
structured slope correlations, residual-scale structured slopes, structured
`rho12`, and non-Gaussian structured slopes remain separate routes.

## GitHub Issue Maintenance

This slice advances the reader-path cleanup for #442, #444, and the sprint
parent #436 after the commit is pushed.

## What Did Not Go Smoothly

Several old paragraphs used "planned" for broad phylogenetic or animal-model
families after the one-slope and known-matrix first slices had landed. The fix
was to name the exact fitted cell and the exact planned neighbours in the same
paragraph.

## Team Learning

Public prose needs the same status split as the support matrix: fitted source
support, artifact readiness, diagnostic-only covariance rows, and coverage or
power evidence should not collapse into one support claim.

## Known Limitations

This cleanup did not add missing wrapper artifacts, tutorial examples, DGPs,
or formal coverage/power grids.

## Next Actions

Use the same fitted-versus-artifact wording when the random-slope tutorial is
expanded under #444.
