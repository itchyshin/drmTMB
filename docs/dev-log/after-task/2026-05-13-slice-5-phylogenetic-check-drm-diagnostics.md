# After Task: Slice 5 Phylogenetic `check_drm()` Diagnostics

## Goal

Add a first-pass `check_drm()` diagnostic for the fitted bivariate
phylogenetic `mu1`/`mu2` mean-mean correlation without changing the likelihood.

## Implemented

`check_drm()` now adds a `biv_phylo_mu_covariance` row for bivariate Gaussian
fits with matching intercept-only `phylo(1 | species, tree = tree)` terms in
`mu1` and `mu2`. The row reports the structured-effect group, maximum absolute
`corpars$phylo` value, the active correlation boundary, observed species count,
minimum fitted observations per observed species, and the minimum fitted
phylogenetic-SD-to-residual-scale ratio.

The row returns:

- `warning` when `corpars$phylo` is non-finite or exceeds the requested
  `rho_boundary`;
- `note` when species replication is weak or a fitted phylogenetic location SD
  is tiny relative to the matching residual scale;
- `ok` when the fitted correlation is away from the boundary and both
  phylogenetic SDs are non-negligible on their interpretation scales.

## Mathematical Contract

This slice inspects the fitted bivariate phylogenetic location parameter:

```text
rho_phylo = cor(a_mu1, a_mu2)
```

It does not add a new likelihood term. It keeps the diagnostic story separate
from residual `rho12` and from planned spatial or full q=4 phylogenetic
location-scale covariance.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `man/check_drm.Rd`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/16-phylo-spatial-common-math.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/check_drm.Rd`.
- `Rscript -e 'devtools::test(filter = "check-drm|phylo-gaussian|corpairs")'`:
  passed with 228 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,703 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'for (f in c("vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'biv_phylo_mu_covariance|corpars\$phylo|phylogenetic.*diagnostic|near-boundary.*phylo|tiny phylogenetic|spatial.*implemented|spatial.*planned|rho12.*phylogenetic|rho12.*spatial' R/check.R tests/testthat/test-check-drm.R NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd man/check_drm.Rd`:
  confirmed the new diagnostic row, fitted phylogenetic wording, spatial
  planned boundary, and residual-`rho12` separation.
- `rg -n 'check_drm\(\).*phylo|phylo.*check_drm|bivariate phylogenetic.*check_drm|corpars\$phylo.*check_drm' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes man/check_drm.Rd`:
  confirmed the user-facing diagnostic references.
- `Rscript tools/codex-checkpoint.R --goal "slice 5 phylogenetic check_drm diagnostics closeout" --next "review diff, then preserve branch state or plan the spatial sibling lane"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-13-150118-codex-checkpoint.md`.
- `git diff --check`: passed.

## Tests Of The Tests

The new test fits the small bivariate phylogenetic Gaussian slice, then mutates
the fitted object to exercise three diagnostic branches deterministically:
`ok` for a moderate `corpars$phylo`, `warning` for a near-boundary phylogenetic
correlation, and `note` for a tiny phylogenetic location SD that remains above
the generic absolute SD-boundary warning threshold.

## Consistency Audit

NEWS, the roadmap, the common phylo-spatial math note, known limitations, the
model-map article, the phylogenetic-spatial article, and `man/check_drm.Rd` now
describe the same fitted diagnostic surface. The wording keeps residual
`rho12`, bivariate phylogenetic `corpars$phylo`, ordinary group covariance, and
planned spatial covariance separate.

## What Did Not Go Smoothly

The documentation patch needed a second, smaller pass because the target
paragraphs had shifted during the earlier slice-4 edits. No code change was
needed after the first focused test run.

## Team Learning

Ada kept this as a diagnostic slice. Fisher pushed the near-boundary correlation
warning to be stronger than the weak-SD note. Curie made the test deterministic
by mutating the fitted object after using a real bivariate phylogenetic fit for
structure. Rose kept spatial in the planned sibling lane instead of letting the
phylogenetic diagnostic imply spatial support.

## Known Limitations

`check_drm()` still does not diagnose spatial fields, non-phylogenetic species
covariance, full q=4 phylogenetic location-scale covariance, or separability
between phylogenetic and ordinary species-level effects. Those remain future
structured-effect diagnostics.

## Next Actions

1. Preserve this branch state before starting another likelihood or reporting
   slice.
2. Plan the spatial sibling lane from the same staged contract: syntax and
   rejection tests first, then a fitted intercept-only spatial `mu` effect,
   then `corpairs()` and `check_drm()` rows only after the likelihood and
   simulation recovery tests exist.
