# After Task: Large-Data Diagnostic Docs

## Goal

Update the large-data article so users know what to do with the new
`fixed_effect_design_size` diagnostic.

## Implemented

- Added guidance to inspect `check_drm(fit)` for fixed-effect design-size
  notes.
- Clarified that high-cardinality factors and interactions point to sparse
  fixed-effect design work, not necessarily phylogenetic tree trouble.
- Updated the benchmark description to include optimizer messages and
  evaluation counts.
- Updated the practical checklist to use `keep_data = FALSE`,
  `keep_model_frame = FALSE`, and `keep_tmb_object = FALSE`.

## Mathematical Contract

No code or likelihood changed. This is documentation for the current diagnostic
and storage-control behaviour.

## Files Changed

- `vignettes/large-data.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-large-data-diagnostic-docs.md`

## Checks Run

- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n "keep_data = FALSE|keep_model_frame = FALSE|fixed_effect_design_size|optimizer message|sparse fixed-effect" vignettes/large-data.Rmd docs/dev-log/after-task/2026-05-10-large-data-diagnostic-docs.md docs/dev-log/check-log.md`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`

The pkgdown check and local site build completed cleanly.

## Known Limitations

Sparse fixed-effect matrices are still planned rather than implemented.
