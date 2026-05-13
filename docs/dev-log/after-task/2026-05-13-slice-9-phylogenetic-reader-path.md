# After Task: Slice 9 Phylogenetic Reader Path

## Goal

Make the user-facing phylogenetic docs show how to read the fitted bivariate
phylogenetic `mu1`/`mu2` mean-mean slice.

## Implemented

`vignettes/phylogenetic-spatial.Rmd` now assigns the bivariate example to
`fit_biv_phylo` and shows the reading path:

```r
corpairs(fit_biv_phylo, level = "phylogenetic")
summary(fit_biv_phylo)$covariance
confint(fit_biv_phylo, parm = phylo_target, method = "profile")
```

`vignettes/model-map.Rmd` now includes the same fitted slice in the practical
trait protocol and separates it from residual `rho12`, ordinary group-level
covariance, full q=4 phylogenetic location-scale covariance, and spatial
covariance.

## Mathematical Contract

The docs describe only the fitted phylogenetic mean-mean layer:

```text
cor_phylo = cor(u_mu1_species, u_mu2_species)
```

The row is a structured random-effect correlation and covariance summary. It is
not residual `rho12`, a phylogenetic scale correlation, or a spatial field
correlation.

## Files Changed

- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/model-map.Rmd`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format NEWS.md vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd`
- `Rscript -e 'for (f in c("vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`
- `Rscript -e 'pkgdown::check_pkgdown()'`
- `rg -n 'fit_biv_phylo|cor:phylo|summary\(fit_biv_phylo\)\$covariance|corpairs\(fit_biv_phylo|confint\(fit_biv_phylo|spatial.*implemented|spatial.*planned|rho12.*phylogenetic' vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd NEWS.md`
- `rg -n 'bivariate phylogenetic.*planned|corpairs\(\).*remain planned|q=4 endpoint|spatial likelihood is not implemented' vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd NEWS.md`
- `git diff --check`

The two touched vignettes rendered successfully. `pkgdown::check_pkgdown()`
reported no problems.

## Tests Of The Tests

This was a prose/documentation slice. The render check verifies the snippets and
tables parse as R Markdown, while the stale-wording scans verify that the docs
show the fitted `mu1`/`mu2` phylogenetic slice without implying spatial support
or full q=4 support.

## Consistency Audit

The local `prose-style-review` checklist was applied with applied ecology,
evolution, and environmental-science readers in mind. The revised prose names
the purpose before mechanics, uses stable terms (`phylo()`, `spatial()`,
`rho12`, `sigma`, `mu1`, `mu2`), and tells readers what to inspect before
interpreting the fitted phylogenetic correlation.

## What Did Not Go Smoothly

One paragraph initially said `corpairs()` rows for phylogenetic correlations were
planned, which was stale after slice 4. It now says reporting rows beyond the
fitted mean-mean pair remain planned.

## Team Learning

Pat should keep tutorials synced with extractor surfaces. Once a fitted model
has `corpairs()`, `summary()`, `check_drm()`, and `confint()` support, the
tutorial should show the reader sequence rather than only the model syntax.

## Known Limitations

No spatial code, phylogenetic scale model, phylogenetic slope model, q=4
location-scale covariance model, or derived covariance interval was added.

## Next Actions

Run the final audit for the phylo-only batch, update any remaining stale status
text, create a recovery checkpoint, and stop before starting the deferred
spatial lane.
