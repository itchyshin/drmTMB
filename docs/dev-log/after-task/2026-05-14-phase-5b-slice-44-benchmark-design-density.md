# After Task: Phase 5b Slice 44 Benchmark Design Density

## Goal

Make the optional large-data benchmark record the same fixed-effect design
density signal that `check_drm()` now reports. The claim is: benchmark CSV rows
can now tell us which retained fixed-effect design block is largest and whether
that block is mostly zero.

## Implemented

- Added benchmark helpers that call `fixed_effect_design_summary()` when the
  local package namespace provides it.
- Added `model_matrix_largest`, `model_matrix_largest_cols`,
  `model_matrix_largest_nonzero`, and `model_matrix_largest_density` to
  `bench/large-phylo-location.R` output.
- Updated `bench/summarize-results.R` to show the largest block, column count,
  and density when those optional columns are present.
- Updated `bench/README.md`, the large-data vignette, roadmap, and NEWS.

## Mathematical Contract

No model fitting changed. The benchmark still fits the same Gaussian
phylogenetic location model. The new fields summarize retained fixed-effect
design matrices after fitting:

```text
density = nonzero_entries / (n_rows * n_cols)
```

## Files Changed

- `bench/large-phylo-location.R`
- `bench/summarize-results.R`
- `bench/README.md`
- `vignettes/large-data.Rmd`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript bench/large-phylo-location.R --rows 80 --species 8 --eval-max 60 --iter-max 60 --memory-light true --output "$tmp_csv" && Rscript bench/summarize-results.R --input "$tmp_csv"`:
  passed and printed the new largest-design fields.
- `Rscript bench/large-phylo-location.R --rows 120 --species 8 --factor-heavy true --eval-max 40 --iter-max 40 --memory-light true --output "$tmp_csv" && Rscript bench/summarize-results.R --input "$tmp_csv"`:
  passed as diagnostic-only with nonzero convergence and printed a low-density
  largest `mu` block.
- `PATH=/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_article("large-data")'`:
  passed.
- `PATH=/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The two benchmark smoke runs exercise both a compact fixed-effect design and a
factor-heavy design. The factor-heavy run intentionally used a small optimizer
budget; it is diagnostic-only, but it proves the new schema survives the
scenario where density matters.

## Consistency Audit

The benchmark README, large-data article source, rebuilt local large-data
article, roadmap, and NEWS all describe the same new benchmark fields. The
summarizer treats the fields as optional so old CSV files can still be read.

## What Did Not Go Smoothly

The tiny factor-heavy benchmark did not converge under the deliberately small
optimizer budget. That is acceptable for this schema smoke check and was
recorded as diagnostic-only, not timing evidence.

## Team Learning

- Ada should keep schema changes paired with the summary helper.
- Boole should keep benchmark column names explicit and stable.
- Gauss did not need to review likelihood code because no objective changed.
- Noether should keep density definitions simple and reproducible.
- Curie should continue using one converged smoke run and one diagnostic
  factor-heavy run for benchmark schema changes.
- Fisher should treat non-converged factor-heavy timing as a diagnostic row.
- Pat should see the large-data article pointing to practical benchmark output,
  not only internal design docs.
- Grace should require fresh CSV output paths when schema changes.
- Rose should keep old benchmark rows from being overinterpreted after schema
  updates.

## Known Limitations

- The benchmark still measures dense fitting.
- Existing CSV files with the old schema cannot be appended to with the new
  output schema.
- Peak resident memory still requires operating-system tools.

## Next Actions

The next Phase 5b slice should move from diagnostics to the first fitted sparse
implementation design: choose the exact TMB data fields and the first
univariate Gaussian path to test.
