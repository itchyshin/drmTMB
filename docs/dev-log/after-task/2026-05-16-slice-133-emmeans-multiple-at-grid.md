# After Task: Slice 133 emmeans multiple explicit at values

## Goal

Add explicit evidence that the first fixed-effect univariate `mu`
`emmeans()` bridge handles conditional reference grids with more than one
numeric `at` value.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a Gaussian fixed-effect `mu`
model and checks
`emmeans(fit, ~ habitat | x, at = list(x = c(-0.25, 0.75)))` against
`predict(dpar = "mu")` row-by-row on the returned conditional reference grid.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes now state this as
explicit conditioning on a reference grid. The wording keeps it separate from
averaged EMMs, slopes, and new marginalisation contracts.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-133-emmeans-multiple-at-grid.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-215616-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- No-edit scout:
  `emmeans(fit, ~ habitat | x, at = list(x = c(-0.25, 0.75)))` matched
  row-wise `predict(dpar = "mu")` on the returned grid.
- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 133 multiple-`at` wording and tests:
  found the expected entries.
- Stale-claim scan for multiple `at` values as unsupported, conditional grids
  as unsupported, or new slope/marginalisation support: no Slice 133
  contradictions; matches were unrelated planned spatial-slope wording.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-215616-codex-checkpoint.md`.

## Post-Rebase Checks

- PR #97 merged as `69e4383a6ff3487846193229cfaa8035f298beb7`.
- `git rebase --onto origin/main 182d6260fa7248991025f2bf30682b68dcca2998`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The test checks explicit conditioning on a finite `emmeans` reference grid. It
does not add a slope workflow, empirical averaging, or non-`mu` targets. Those
estimands need separate tests and documentation if they are added later.

## Known Limitations

- Only fixed-effect univariate `mu` models are covered.
- No slope, non-`mu`, transformed-response, random-effect, empirical
  marginalisation, or blocked-model workflow is added.

## Team Notes

Pat and Boole should keep examples explicit about whether a reported table is
conditioned on fixed `at` values, averaged over a reference grid, or averaged
over empirical rows.
