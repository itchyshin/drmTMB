# After-Task Report: Slices 433-438 Phylo Reference Audit

## Active Perspectives

Ada ran the reference audit and regenerated documentation. Pat checked whether
the `phylo()` help page still described the syntax an applied user would try.
Grace ran the pkgdown reference check. Rose treated the stale help text as a
small but real consistency gap after the q4 fallback work.

## Goal

Make the `phylo()` reference documentation match the implemented bivariate
Gaussian location-scale phylogenetic paths.

## Implemented

- Updated the `phylo()` roxygen description in `R/formula-markers.R`.
- Regenerated `man/phylo.Rd` with `devtools::document()`.
- Updated `vignettes/formula-grammar.Rmd` so it shows the implemented all-four
  q4/block-diagonal `phylo()` syntax and reserves only standalone or partial
  scale terms as planned.
- Synchronized `README.md`, `NEWS.md`, `ROADMAP.md`,
  `vignettes/model-map.Rmd`, `docs/design/12-profile-likelihood-cis.md`, and
  `docs/design/34-validation-debt-register.md` so they distinguish full q4
  derived correlations from block-diagonal q4 fallback direct targets.
- Confirmed `_pkgdown.yml` still indexes the reference topics with
  `pkgdown::check_pkgdown()`.
- Built the local rendered pkgdown site and checked that the updated `phylo()`
  and roadmap/profile-ready wording reached `pkgdown-site/`.

## Evidence

The previous help text described univariate Gaussian `mu` and bivariate
`mu1`/`mu2` location terms, but not labelled all-four bivariate Gaussian
location-scale blocks. The updated text now distinguishes:

- univariate `mu` phylogenetic location effects;
- matching bivariate `mu1`/`mu2` phylogenetic location effects;
- full all-four q4 labelled blocks;
- block-diagonal q4 fallback with one `mu1`/`mu2` label and one
  `sigma1`/`sigma2` label;
- still-planned standalone univariate `sigma ~ phylo(...)` and phylogenetic
  slope paths.

The broader status-map audit also now says that full q4 phylogenetic
correlations remain derived-only for intervals, while the block-diagonal q4
fallback exposes direct constant block-correlation targets. The Ayumi fallback
profile result means these direct rows are still fit-specific diagnostics, not
guaranteed usable intervals.

## Checks Run

```sh
air format R/formula-markers.R
Rscript -e "devtools::document()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
Rscript -e "pkgdown::build_article('formula-grammar', quiet = FALSE)"
rg -n "block-diagonal fallback|profile-ready row can still fail|bounded profile|PV2_locphylo|scale-scale phylogenetic" pkgdown-site/reference/phylo.html pkgdown-site/articles/phylogenetic-spatial.html pkgdown-site/ROADMAP.html pkgdown-site/articles/model-workflow.html pkgdown-site/articles/model-map.html --glob '!pkgdown-site/search.json'
rg -n "block-diagonal fallback|standalone or partial phylogenetic scale|phylogenetic mean-mean and q=4" vignettes/formula-grammar.Rmd pkgdown-site/articles/formula-grammar.html
air format README.md NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/design/34-validation-debt-register.md vignettes/model-map.Rmd
Rscript -e "pkgdown::build_site()"
rg -n "block-diagonal q=4 fallback|direct fallback targets|direct targets but still need fit-specific|Full phylogenetic q=4 correlations|full q=4 correlations are derived-only" README.md NEWS.md ROADMAP.md vignettes/model-map.Rmd docs/design/12-profile-likelihood-cis.md docs/design/34-validation-debt-register.md pkgdown-site/index.html pkgdown-site/news/index.html pkgdown-site/ROADMAP.html pkgdown-site/articles/model-map.html --glob '!pkgdown-site/search.json'
rg -n "phylogenetic or spatial terms in sigma|Phylogenetic q=4 correlations are currently reported|q=4 phylogenetic correlations are derived-only for intervals|all six.*profile-ready|q4.*profile-ready atanh" README.md NEWS.md ROADMAP.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd vignettes/formula-grammar.Rmd docs/design pkgdown-site/index.html pkgdown-site/news/index.html pkgdown-site/ROADMAP.html pkgdown-site/articles/model-map.html --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'
git diff --check
```

`pkgdown::check_pkgdown()` reported no problems.
`pkgdown::build_site()` completed, and the rendered scan found the updated
`phylo()` reference, profile-ready caution, Ayumi bounded-profile note, and
positive-control `PV2_locphylo` wording. The follow-up formula-grammar render
confirmed the corrected q4/block-diagonal wording.

The follow-up rendered scan found the corrected README, NEWS, ROADMAP, and
model-map wording, and did not find the older broad
`phylogenetic or spatial terms in sigma` shorthand in current source/status
pages. `git diff --check` reported no whitespace problems.

## Known Limitations

This was a reference-page synchronization slice only. It did not add new
examples to the `phylo()` help page.

## Next Actions

Run a broader rendered-site or reference-index pass later, especially for
formula-only syntax that is easy to miss from exported-function navigation.
