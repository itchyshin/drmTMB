# After Task: Slice 13 Phylogenetic q4 Planned-Pair Scaffold

## Goal

Name the future phylogenetic q4 endpoint rows before exposing them in fitted
models. This makes the planned extractor contract explicit while preserving the
current public boundary.

## Implemented

`R/phylo-utils.R` now has an internal `drm_phylo_q4_endpoint_pairs()` helper.
It returns the six planned phylogenetic endpoint pairs across `mu1`, `mu2`,
`sigma1`, and `sigma2`: one `mean-mean`, four `mean-scale`, and one
`scale-scale` row. The rows use `level = "phylogenetic"`, keep response labels
separate, mark `modelled = FALSE`, and carry
`status = "planned"` plus `support_note = "planned_bivariate_phylogenetic_q4"`.

`tests/testthat/test-phylo-utils.R` checks the row order, classes,
distributional parameters, response labels, planned status, and the absence of
residual `rho12` from the planned parameter names.

## Team Roles

Ada kept this as a scaffold. Boole checked the row names and labels. Noether
checked that the six rows match the q=4 endpoint state. Darwin checked that
response names such as body mass and litter size can carry through. Rose
guarded the support boundary: these rows are planned and not emitted from
`corpairs()` yet.

## Scope Boundary

This slice does not change accepted formulas, TMB likelihoods, `corpairs()`,
`summary()`, `profile_targets()`, or examples. It only records the future row
contract for later fitted phylogenetic support.

## Files Changed

- `R/phylo-utils.R`
- `tests/testthat/test-phylo-utils.R`
- `ROADMAP.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/15-location-coscale-phylogenetic-extension.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-13-phylogenetic-q4-planned-pair-scaffold.md`

## Checks Run

- `air format R/phylo-utils.R tests/testthat/test-phylo-utils.R ROADMAP.md
  docs/design/09-phylogenetic-and-spatial-speed.md
  docs/design/15-location-coscale-phylogenetic-extension.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-13-phylogenetic-q4-planned-pair-scaffold.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "phylo-utils")'`: passed with 67
  expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Next Actions

1. Run focused phylogenetic utility tests.
2. Commit and push this planned-pair scaffold.
3. Next slice: align active limitations/tutorial wording with the hidden
   phylogenetic q4 scaffolds without claiming fitted support.
