# After Task: Phase 5b Slice 41 Memory-Light Structured Surfaces

## Goal

Start Phase 5b by making the existing memory-light fitted-object controls match
the newer structured-effect features added during Phase 5. The concrete claim
is: when users set `keep_model_frame = FALSE`, `drmTMB` now drops nested
model-frame caches for direct random-effect SD models and fitted q=2
`corpair()` regression models after retaining the matrices and metadata needed
for post-fit methods.

## Implemented

- Updated `drm_drop_model_frames()` so it removes `model_frame` and
  `model_frame_list` from every `model$random_scale` component, including
  phylogenetic direct-SD structures.
- Updated the same storage cleanup for fitted q=2 latent-correlation models in
  `model$random$mu$cor_model`.
- Added tests for an `sd_phylo(species) ~ z_species` fit and an ordinary q=2
  `corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ ecology`
  fit with all memory-light flags enabled.
- Updated the large-data design note, large-data vignette, known limitations,
  `ROADMAP.md`, and `NEWS.md`.

## Mathematical Contract

No likelihood, parameterization, or formula grammar changed. This is a fitted
object storage change. The model matrices, terms, response vectors, group
levels, optimized parameters, and `sdreport` object remain available; the
discarded objects are R model frames that are no longer needed after TMB data
construction.

## Files Changed

- `R/control.R`
- `tests/testthat/test-control.R`
- `docs/design/23-large-data-memory.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/large-data.Rmd`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "control", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(filter = "control|biv-gaussian|phylo-gaussian", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `PATH=/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_article("large-data")'`:
  passed.
- `PATH=/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The new tests check the gap that existed before this slice: the old cleanup
only removed ordinary `random_scale$mu` model frames. The new `sd_phylo()` test
would have found a retained nested `random_scale$phylo$model_frame_list`, and
the new `corpair()` test would have found a retained
`random$mu$cor_model$model_frame_list`.

## Consistency Audit

The source docs and rebuilt local large-data article now say the same thing:
`keep_model_frame = FALSE` reduces fitted-object storage for the nested
structured-effect caches, but it does not avoid constructing R model frames or
dense fixed-effect matrices before optimization. Stale-wording scans did not
find current-source claims that large-data memory controls are unimplemented or
that the control only covers ordinary `sd()` model frames. Historical check-log
and after-task records were left unchanged.

## What Did Not Go Smoothly

The first Phase 5b audit found a small honesty gap rather than a new large-data
engine feature. That is still useful: storage controls should not leave behind
new nested caches while the docs tell users they requested a memory-light fit.

## Team Learning

- Ada should keep Phase 5b slices small and storage-specific before opening
  sparse-matrix or aggregation work.
- Boole should watch storage-control wording because it affects user
  expectations even when formula grammar does not change.
- Gauss and Noether did not need to re-review likelihood algebra for this
  slice, but they should stay involved before any sparse or aggregated
  likelihood path changes TMB inputs.
- Curie should keep combining memory-light controls with neighbouring features,
  not only with the simplest Gaussian model.
- Fisher should keep large-data readiness separate from fitted-object size
  reduction; this slice is not evidence for million-row inference.
- Pat should keep the large-data article practical: what can be dropped, what
  still gets constructed, and what users should benchmark.
- Grace should continue requiring pkgdown checks after public large-data prose
  changes.
- Rose should keep flagging stale "implemented versus planned" wording during
  Phase 5b, because scaling language can overpromise quickly.

## Known Limitations

- Sparse fixed-effect matrices remain planned.
- Gaussian sufficient-statistic aggregation remains planned.
- Memory-light modes that avoid initial model-frame or dense-matrix
  construction remain planned.
- Repeated million-row and 10,000-species benchmark evidence remains planned.

## Next Actions

The next Phase 5b slice should turn to the sparse fixed-effect matrix contract:
audit the current dense `model.matrix()` construction points, write the
dense-versus-sparse parity plan, and decide the first formula class that can
switch to a sparse matrix without changing fitted results.
