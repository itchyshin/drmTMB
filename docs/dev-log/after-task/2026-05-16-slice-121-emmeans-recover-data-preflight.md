# After Task: Slice 121 emmeans recover-data preflight

## Goal

Add a private recover-data preflight for the same first eligible `emmeans`
target used by Slice 120, so future `recover_data.drmTMB()` work has a tested
source for retained model metadata.

## Implemented

`drm_emmeans_recover_data()` now checks the private `mu` eligibility gate and
then returns the retained `mu` model frame, terms, predictor names, response
name, factor levels, and row names. `drm_emmeans_model_frame()` gives a focused
error when model frames were dropped by memory-light fitted-object controls.

This remains private preflight code. It does not add `emmeans`, register S3
methods, implement public `recover_data.drmTMB()` or `emm_basis.drmTMB()`, or
advertise estimated marginal means.

## Mathematical Contract

The recovered data are tied to the same first eligible target as Slice 120:

```text
mu ~ predictors
```

The helper recovers metadata needed to rebuild a fixed-effect `mu` reference
grid. It does not define averaging weights, contrasts, slopes, fitted response
means, or degrees of freedom.

## Files Changed

- `R/emmeans-preflight.R`
- `tests/testthat/test-emmeans-recover-data.R`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-191740-codex-checkpoint.md`

## Checks Run

- `air format R/emmeans-preflight.R tests/testthat/test-emmeans-recover-data.R ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md`
- `Rscript -e "devtools::test(filter = 'emmeans-recover-data|emmeans-preflight', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'emmeans-recover-data|emmeans-preflight|fixed-effect-basis', reporter = 'summary')"`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `rg -n 'Slice 121|drm_emmeans_recover_data|recover-data preflight|retained `mu` model frame|memory-light|keep_model_frame' ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md pkgdown-site/ROADMAP.html`
- `rg -n 'exported `emmeans` method|implemented `emmeans`|emmeans support is implemented|public `emmeans` support|recover_data\\.drmTMB\\(\\).*implemented|emm_basis\\.drmTMB\\(\\).*implemented|return an `emmGrid`.*implemented|contrast workflow|contrast API.*implemented|slope.*implemented' DESCRIPTION NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`
- `Rscript tools/codex-checkpoint.R --goal "Slice 121 emmeans recover-data preflight" --next "open Slice 120 PR after rebasing onto merged main; then rebase Slice 121 after Slice 120 lands"`

All checks passed. The stale-claim scan found only intentional boundary wording
and unrelated existing slope-status text.

## Tests Of The Tests

The accepted-path test checks the exact metadata future recovery work needs:
model frame, terms, predictors, response name, factor levels, and row names. The
failure-path test fits with `keep_model_frame = FALSE` and confirms that the
helper asks for a refit with retained model frames.

## Consistency Audit

`ROADMAP.md`, `docs/design/39-visualization-grammar.md`, and
`docs/design/40-emmeans-interface-contract.md` describe Slice 121 as private
recover-data preflight code. The rendered roadmap contains the same claim after
`pkgdown::build_site()`.

No public reference topic, NEWS entry, or `_pkgdown.yml` change was added
because there is still no user-facing `emmeans` method.

## What Did Not Go Smoothly

The source-map search was noisy because many tests and docs mention `data` and
model frames. The useful evidence came from the fitted-spec construction in
`R/drmTMB.R`, existing memory-light tests, and the design contract rather than a
broad `rg` output.

## Team Learning

Ada should keep the recovery side separate from the basis side. Boole should
ask whether each future method has retained enough fitted-row metadata before
the team starts building public method glue. Grace should continue testing the
memory-light failure mode because `keep_model_frame = FALSE` is a valid user
choice.

## Known Limitations

- No public `recover_data.drmTMB()` or `emm_basis.drmTMB()` method exists yet.
- No `emmeans` dependency or conditional registration hook was added.
- The helper only covers retained model-frame metadata for fixed-effect
  univariate `mu`.

## Next Actions

Open Slice 120 after rebasing it onto merged `main`; after Slice 120 lands,
rebase Slice 121 and open a focused PR. The next implementation slice can
combine the private recovery and basis preflights in a direct
`emmeans::ref_grid()` comparison if the dependency decision is ready.
