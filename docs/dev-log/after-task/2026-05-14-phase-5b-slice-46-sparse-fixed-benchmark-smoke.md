# After Task: Phase 5b Slice 46 Sparse Fixed Benchmark Smoke

## Goal

Add a benchmark route for the first sparse fixed-effect implementation without
claiming sparse phylogenetic fitting.

## Implemented

- Added `--structured phylo|none` to `bench/large-phylo-location.R`.
- Added `--sparse-fixed true`, guarded to require
  `--structured none --sigma-x false`.
- Recorded `structured` and `sparse_fixed` in benchmark CSV rows.
- Let `sd_phylo_hat` be `NA` for non-phylogenetic fixed-effect benchmark rows.
- Updated `bench/summarize-results.R` so scenario labels and summaries expose
  the structured route and sparse fixed-effect setting.
- Updated benchmark docs, the large-data vignette, the large-data memory design
  note, roadmap, NEWS, and check-log.

## Mathematical Contract

No fitted likelihood changed in this slice. The benchmark either fits the
existing phylogenetic Gaussian location model or the first sparse fixed-effect
Gaussian location model:

```text
structured = phylo: y ~ x1 + x2 + phylo(1 | species, tree = tree)
structured = none:  y ~ x1 + x2 [+ habitat]
```

The sparse smoke route is intentionally non-phylogenetic because the fitted
package path still rejects sparse fixed effects with structured random effects.

## Files Changed

- `bench/large-phylo-location.R`
- `bench/summarize-results.R`
- `bench/README.md`
- `vignettes/large-data.Rmd`
- `docs/design/23-large-data-memory.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- Default phylogenetic benchmark smoke with 80 rows and 8 species: passed.
- Sparse fixed-effect benchmark smoke with 100 rows, 8 species,
  `--structured none --factor-heavy true --sparse-fixed true`, and small
  optimizer budget: passed as diagnostic-only with nonzero convergence.
- Sparse fixed-effect benchmark smoke with larger optimizer budget: passed
  with convergence code 0.
- Incompatible `--sparse-fixed true` with default phylogenetic route: failed
  with the intended guard.
- `pkgdown::build_article("large-data", new_process = FALSE)`: passed.
- `pkgdown::check_pkgdown()`: passed.
- Scope scan for `--structured none`, `--sparse-fixed`, `sparse_fixed`, and
  sparse-phylogenetic wording: found the intended benchmark and documentation
  wording.
- `git diff --check`: passed.

## Tests Of The Tests

The smoke commands covered the old default route, the new sparse route, and one
intentional failure path. This is a benchmark-script check, not a CRAN test.

## Consistency Audit

The benchmark README, large-data vignette, design note, roadmap, and NEWS all
state that sparse benchmark rows with `sparse_fixed = TRUE` use
`structured = none`, not a phylogenetic model.

## What Did Not Go Smoothly

The first sparse smoke used a deliberately tiny optimizer budget and did not
converge. That row is useful schema evidence but not timing evidence. A second
run with a larger budget converged.

## Team Learning

- Ada should keep benchmark schema changes backward-readable through optional
  summary columns.
- Boole should keep CLI names explicit: `structured` and `sparse_fixed` say
  what changed.
- Gauss did not need to review likelihood code because only benchmark routing
  changed.
- Noether should keep sparse fixed-effect benchmarks separate from
  phylogenetic structured-effect benchmarks until the model supports both.
- Curie should keep one old-route smoke, one new-route smoke, and one failure
  guard for benchmark-script changes.
- Fisher should mark nonconverged benchmark rows as diagnostic-only.
- Pat should see the README command that can actually be copied for the sparse
  smoke route.
- Grace should require fresh CSV schemas when output columns change.
- Rose should watch for benchmark wording that accidentally implies sparse
  phylogenetic support.

## Known Limitations

- This is not a large-data timing claim.
- Sparse fixed-effect benchmarking currently covers only the fixed-effect
  univariate Gaussian `mu` path.
- Peak resident memory still needs operating-system tools.

## Next Actions

Commit Slice 46. The next Phase 5b slice should either collect local benchmark
evidence for the new sparse smoke command or move to Gaussian aggregation
design.
