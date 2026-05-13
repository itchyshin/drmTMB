# After Task: Slice 15 Staged Trait Protocol Guide

## Goal

Give applied comparative-trait users a clear path for the mammal and bird
protocol target without claiming that the combined bivariate phylogenetic
double-hierarchical model is already fitted.

## Implemented

The model-map article now includes a practical staged protocol. It shows the
implemented bivariate Gaussian path for two trait means, two residual SDs,
residual `rho12`, and an ordinary labelled species-level `mu1`/`mu2`
random-intercept covariance. It also shows the implemented univariate
phylogenetic path for one trait mean with `phylo(1 | species, tree = tree)`.

The same section tells readers how to interpret the pieces separately:
`rho12(fit_biv)` is within-observation residual coupling, `corpairs()` group
rows are ordinary species or individual random-effect correlations, and the
univariate `phylo()` fit is a one-trait shared-ancestry mean model.

The README now points comparative mammal, bird, and other trait workflows to
the staged model-map protocol until the combined phylogenetic
double-hierarchical endpoint is implemented.

## Team Roles

Ada integrated the user-facing workflow. Pat checked that the path tells an
applied reader what to fit next. Darwin checked that the example reads like a
real comparative-trait analysis. Rose checked that q4 and phylogenetic
covariance support are not overclaimed.

## Scope Boundary

This slice changes user-facing prose only. It does not add a fitted q4 model,
does not add bivariate `phylo()` syntax, does not add random slopes, and does
not change `corpairs()` output.

## Files Changed

- `vignettes/model-map.Rmd`
- `README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-15-staged-trait-protocol-guide.md`

## Checks Run

- `air format vignettes/model-map.Rmd README.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-15-staged-trait-protocol-guide.md`:
  passed.
- `Rscript -e 'rmarkdown::render("vignettes/model-map.Rmd", output_file =
  tempfile(fileext = ".html"), quiet = TRUE)'`: passed.
- `rg -n 'practical trait protocol|q=4|four distributional endpoints|six
  pairwise|mammal|bird|rho12\\(fit_biv\\)|phylo\\(1 \\| species|combined
  phylogenetic' vignettes/model-map.Rmd README.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-15-staged-trait-protocol-guide.md`:
  passed.
- `git diff --check`: passed.

## Next Actions

1. Commit and push Slice 15.
2. Trigger the slice-boundary GitHub Actions checks.
