# After Task: Slice 289 Extractor Provenance Contracts

## Goal

Make the post-fit extractor and plotting contract more consistent without
adding a new estimand, model family, interval method, or plotting helper.

## Implemented

`corpairs()` now returns `conf.status` and `interval_source` columns by
default. A plain `corpairs(fit)` table marks rows as
`conf.status = "not_requested"` and `interval_source = "not_available"`.
When `corpairs(conf.int = TRUE)` returns a profiled correlation-pair interval,
the row now records `interval_source = "profile"` beside
`conf.status = "profile"`.

`plot_corpairs()` now uses the same provenance rule as
`plot_parameter_surface()`: finite `conf.low` and `conf.high` values are not
enough to draw an interval. The table must also say that the bounds came from a
real interval source. Compatible point-only tables still work, but they receive
internal display defaults of `not_requested` and `not_available`.

## Mathematical Contract

No likelihood, parameter transformation, formula grammar, or interval
calculation changed. This slice changes table provenance. The correlation
estimate remains the fitted response-scale correlation reported by
`corpairs()`, and profile intervals remain available only for the direct
profile-ready targets that already existed.

## Files Changed

- `R/methods.R`
- `R/plot-corpairs.R`
- `tests/testthat/test-corpairs.R`
- `tests/testthat/test-plot-corpairs.R`
- `man/corpairs.Rd`
- `man/plot_corpairs.Rd`
- `docs/design/39-visualization-grammar.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `vignettes/model-map.Rmd`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-221022-codex-checkpoint.md`

## Checks Run

```sh
air format R/methods.R R/plot-corpairs.R tests/testthat/test-corpairs.R tests/testthat/test-plot-corpairs.R docs/design/39-visualization-grammar.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/model-map.Rmd NEWS.md ROADMAP.md
Rscript -e "devtools::test(filter = 'corpairs|plot-corpairs', reporter = 'summary')"
Rscript -e "devtools::document()"
git diff --check
Rscript -e "rmarkdown::render('vignettes/model-map.Rmd', quiet = TRUE)"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::test(reporter = 'summary')"
rg -n 'Slice 289|interval_source|plot_corpairs\(\)|plotting helpers remain planned|conf\.status|profile_ready|not_available|emmeans\(\)|vcov\(\)|post-fit extractor' NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/model-map.Rmd R/methods.R R/plot-corpairs.R tests/testthat/test-corpairs.R tests/testthat/test-plot-corpairs.R man/corpairs.Rd man/plot_corpairs.Rd
rg -n 'plotting helpers remain planned' vignettes docs README.md NEWS.md ROADMAP.md
git diff --check
Rscript tools/codex-checkpoint.R --goal "Slice 289 extractor provenance contracts" --next "stage, commit, push, and open draft PR"
```

All checks passed. The final stale-phrase scan intentionally returned no
matches.

## Tests Of The Tests

The `corpairs()` test would fail if default pair tables lost `conf.status` or
`interval_source`, if predictor-dependent residual `rho12` interval requests
stopped reporting `newdata_required`, or if empty pair tables lost the new
provenance columns. The `plot_corpairs()` test would fail if the helper drew
interval segments from finite numeric bounds whose `interval_source` was
`"not_available"`.

## Consistency Audit

The roadmap now marks Slice 289 done locally. The visualization grammar records
the shared rule across `predict_parameters()`, `corpairs()`,
`plot_parameter_surface()`, and `plot_corpairs()`. The readiness matrix names
`vcov()` as a covariance matrix with row and column-name provenance, not a
status table, and names the current `emmeans()` bridge as an external `emmGrid`
route limited to fixed-effect univariate `mu`.

## What Did Not Go Smoothly

The main design choice was whether to overload `conf.method` or add
`interval_source` to `corpairs()`. Keeping both is clearer: `conf.method`
records the interval method used by `corpairs(conf.int = TRUE)`, while
`interval_source` gives plotting and table consumers the same provenance column
used by prediction surfaces.

## Team Learning

Ada kept the slice focused on extractor provenance rather than a new plotting
API. Emmy checked the S3/object contract and kept `vcov()` out of status-table
shape. Boole checked that the new columns do not change formula grammar or
argument surfaces. Fisher checked that no unsupported interval method is implied.
Pat checked the user action: missing interval provenance means draw points only.
Florence checked that interval bars cannot appear from bare numeric bounds. Grace
confirmed roxygen, pkgdown, vignette rendering, and the full test suite. Rose
checked stale wording around planned plotting helpers. No spawned subagents were
used.

## Known Limitations

No bootstrap, derived-profile, slope, contrast, diagnostic-plot, or
simulation-plot data surface was added. `emmeans()` still covers only the narrow
fixed-effect univariate `mu` path, and `vcov()` remains a covariance matrix
rather than a data-frame extractor.

## Next Actions

Continue with the next roadmap slice only after preserving this extractor
contract in a small stacked PR. Good candidates are another narrow Phase 18
readiness row or a reader-facing example that uses the now-consistent
provenance columns without adding new model support.
