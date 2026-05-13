# After Task: Slice 14 Phylogenetic q4 Status Wording Guard

## Goal

Keep public documentation aligned with the internal q4 phylogenetic scaffolds.
The package can now name and test the future state across `mu1`, `mu2`,
`sigma1`, and `sigma2`, but users should not read that as implemented
bivariate `phylo()` support.

## Implemented

The phylogenetic-spatial article now states that developer q4 scaffolds protect
algebra and endpoint names only. The article tells applied users to keep using
the implemented univariate phylogenetic Gaussian model, or the ordinary
non-phylogenetic bivariate Gaussian model, until a fitted bivariate
phylogenetic likelihood, recovery tests, and reporting rows are present.

The model-map article and known-limitations log now make the same boundary
visible: q4 phylogenetic scaffolds are internal contracts, not accepted formula
syntax, fitted output, or `corpairs()` support.

## Team Roles

Ada kept the slice scoped to status alignment. Pat checked that an applied user
would know what to fit next. Rose checked that the docs do not overclaim q4,
phylogenetic, or bivariate structured-correlation support.

## Scope Boundary

This slice changes prose and status logs only. It does not add formula syntax,
does not change likelihood code, does not expose bivariate `phylo()`, and does
not add phylogenetic rows to `corpairs()`.

## Files Changed

- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/model-map.Rmd`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-14-phylogenetic-q4-status-wording-guard.md`

## Checks Run

- `air format vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd
  docs/dev-log/known-limitations.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-14-phylogenetic-q4-status-wording-guard.md`:
  passed.
- `rg -n 'q=4|q4|bivariate \`phylo|fitted likelihood|corpairs\\(\\)|planned,
  not implemented|residual \`rho12' vignettes/phylogenetic-spatial.Rmd
  vignettes/model-map.Rmd docs/dev-log/known-limitations.md
  docs/dev-log/after-task/2026-05-13-slice-14-phylogenetic-q4-status-wording-guard.md`:
  passed and confirmed public wording says q4 phylogenetic scaffolds are
  internal only.
- `git diff --check`: passed.

## Next Actions

1. Commit and push Slice 14.
2. Move to Slice 15 content/tutorial alignment before running the next expensive
   package checks.
