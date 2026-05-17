# After Task: Slice 126 emmeans contrast boundary

## Goal

Correct the `emmeans` support boundary now that direct checking showed generic
pairwise contrasts can be computed from the returned fixed-effect `mu` EMM grid.
The goal is to be honest about what works without turning that into a broad
drmTMB contrast or slope API claim.

## Implemented

`tests/testthat/test-emmeans-methods.R` now checks
`emmeans::emmeans(fit, pairwise ~ habitat, at = list(x = 0))` for the supported
fixed-effect Gaussian `mu` path. The test verifies that the contrast estimates
are exactly the differences among the returned EMMs, and that contrast standard
errors and asymptotic degrees of freedom are present.

NEWS, the Phase 17 roadmap, `docs/design/39-visualization-grammar.md`,
`docs/design/40-emmeans-interface-contract.md`, and the model-workflow article
now distinguish three ideas:

- fixed-effect univariate `mu` EMMs are the supported drmTMB bridge;
- generic `emmeans` pairwise contrasts can be computed from that returned grid;
- broader drmTMB-specific contrast helpers, slopes, non-`mu` contrasts, custom
  weighting contracts, and blocked model structures remain future work.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-126-emmeans-contrast-boundary.md`
- `tests/testthat/test-emmeans-methods.R`
- `vignettes/model-workflow.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md vignettes/model-workflow.Rmd tests/testthat/test-emmeans-methods.R docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-slice-126-emmeans-contrast-boundary.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 126 contrast wording, the
  `pairwise ~ habitat` test, and rendered model-workflow/NEWS/ROADMAP text:
  found the expected entries.
- Stale-claim scan for old pre-grid failure wording: no matches.
- `git diff --check`: passed.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-205211-codex-checkpoint.md`.

Post-rebase checks:

- PR #90 merged as `1e8d5cc5a71d8575b8d6ac5c9ca680233533539c`.
- `git rebase --onto origin/main bb62a6839e492a99932045a6f6ccdb70abd60499`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The edited prose no longer treats contrast itself as a pre-grid unsupported
target. It also does not claim a general contrast API: slopes, custom weights,
non-`mu` contrasts, bivariate, zero-inflated, hurdle, ordinal, random-effect,
and structured-effect models remain outside this boundary.

## Known Limitations

- Only ordinary pairwise differences among fixed-effect `mu` EMMs are tested.
- No drmTMB-specific contrast helper is added.
- No slope, ratio, custom-weight, non-`mu`, fitted-response, or blocked-model
  workflow is added.

## Team Notes

Boole should keep this distinction visible: an `emmGrid` enables some generic
`emmeans` operations, but drmTMB still needs explicit contracts before it
advertises a package-specific contrast or slope layer. Rose should keep scanning
for stale pre-grid failure wording whenever downstream generic methods can
operate after the grid is returned.
