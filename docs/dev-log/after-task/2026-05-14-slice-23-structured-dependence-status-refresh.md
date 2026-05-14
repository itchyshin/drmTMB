# After Task: Slice 23 Structured-Dependence Status Refresh

## Goal

Refresh the structured-dependence article so an applied ecology or evolution
reader can see which phylogenetic paths are fitted now and which paths remain
planned.

## Implemented

The article now states that univariate `phylo()` in `mu` is implemented, and
that matching bivariate `mu1`/`mu2` `phylo()` terms fit the first phylogenetic
mean-mean covariance slice. It adds a current-status table that keeps ordinary
q=4 grouped covariance, planned phylogenetic q=4, planned `sd_phylo()`, and
planned spatial effects in separate rows.

## Mathematical Contract

This was a documentation/status slice. It did not change the likelihood. The
article still separates residual `rho12` from latent phylogenetic and ordinary
group-level covariance rows.

## Files Changed

- `vignettes/phylogenetic-spatial.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-14-slice-23-structured-dependence-status-refresh.md`

The local generated article `pkgdown-site/articles/phylogenetic-spatial.html`
was rebuilt for review but remains a generated artifact.

## Checks Run

- `air format vignettes/phylogenetic-spatial.Rmd`: passed.
- `Rscript -e "pkgdown::build_article('phylogenetic-spatial')"`: passed.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|corpairs|summary|check-drm", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

No tests were added. The targeted test set exercises the fitted bivariate
phylogenetic mean-mean reporting path, `corpairs()`, summary covariance rows,
and `check_drm()` diagnostics that the article now tells users to inspect.

## Consistency Audit

The status inventory was checked with:

```sh
rg -n 'Current implementation status|full phylogenetic PLSM|sd_phylo\(species\)|Matching .*mu1.*mu2' vignettes/phylogenetic-spatial.Rmd pkgdown-site/articles/phylogenetic-spatial.html
rg -n 'first implemented path|bivariate structured covariance blocks remain planned|only.*univariate Gaussian location|full bivariate phylogenetic location-scale block|sd_phylo\(species\) ~ z|location-scale-coscale' README.md ROADMAP.md NEWS.md docs vignettes _pkgdown.yml pkgdown-site/articles/phylogenetic-spatial.html
rg -n 'phylo\(1 \| species, tree = tree\)|corpairs\(.*phylogenetic|rho12|spatial\(1 \| site|sd_phylo' README.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/phylogenetic-spatial.Rmd _pkgdown.yml
```

The first search confirmed the new source and generated article text. The
second search confirmed the stale article opening was gone; remaining matches
were current docs or historical dev-log entries. The third search checked that
README, roadmap, known limitations, formula grammar, and pkgdown navigation
still tell the same fitted-versus-planned story.

## What Did Not Go Smoothly

The first status scan had a shell-quoting mistake around backticks. It was
rerun with single-quoted patterns.

## Team Learning

Rose's status-inventory check is useful for these slices because generated
pkgdown and source vignettes can drift independently. Pat's reader question is
simple here: the first screen of the article should say what the package can
fit today.

## Known Limitations

This slice did not implement phylogenetic scale terms, full phylogenetic q=4
covariance, direct `sd_phylo()` regression, or spatial effects.

## Next Actions

Slice 24 should harden q=4 and `corpairs()` behaviour with focused tests or
guards before the phylogenetic q=4 design and implementation slices continue.
