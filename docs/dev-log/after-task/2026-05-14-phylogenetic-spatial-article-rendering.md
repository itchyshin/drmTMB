# After Task: Phylogenetic-Spatial Article Rendering Polish

## Goal

Make the bivariate phylogenetic correlation section render cleanly in pkgdown
and make the planned phylogenetic `corpair()` formula syntax easier to find.

## Implemented

The article now avoids bracket-heavy matrix displays in the "model layer by
layer" section. It describes the residual covariance through
\(\Omega_{11,i}\), \(\Omega_{22,i}\), and \(\Omega_{12,i}\), and describes the
phylogenetic layer through scalar `Var()` and `Cov()` equations for
\(\mathbf{a}_1\), \(\mathbf{a}_2\), and q=4 endpoint effects.

The current implementation table now includes a planned phylogenetic
`corpair() ~ ecology` row, followed by a code block with
`corpair(species, level = "phylogenetic", block = "p", ...) ~ ecology`
examples. The prose says these formulae are not runnable today.

## Mathematical Contract

No model contract changed. Constant phylogenetic random-effect correlations are
still fitted by matching `phylo()` terms and extracted with
`corpairs(level = "phylogenetic")`. Predictor-dependent phylogenetic
`corpair()` formulas remain planned.

## Files Changed

- `vignettes/phylogenetic-spatial.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-14-phylogenetic-spatial-article-rendering.md`

## Checks Run

- `/opt/homebrew/bin/air format vignettes/phylogenetic-spatial.Rmd`: passed.
- `PATH=/opt/homebrew/bin:$PATH /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("phylogenetic-spatial", new_process = FALSE, quiet = TRUE)'`: passed.
- `PATH=/opt/homebrew/bin:$PATH /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `rg -n '\\begin\{p?matrix\}|\\begin\{bmatrix\}|\\left|\\right|\\begin\{array\}' vignettes/phylogenetic-spatial.Rmd pkgdown-site/articles/phylogenetic-spatial.html`: returned no matches.
- `git diff --check`: passed.

## Tests Of The Tests

This was article-only work, so no model tests were needed. The useful check was
the source/generated-site bracket scan, because the user-visible problem was
HTML math rendering rather than likelihood behavior.

## Consistency Audit

The article now separates three layers near the top:

- residual `rho12`, which is fitted today for observation-level correlation;
- constant phylogenetic correlations, fitted today and extracted by
  `corpairs(level = "phylogenetic")`;
- predictor-dependent phylogenetic `corpair()` syntax, shown as planned.

## What Did Not Go Smoothly

The first draft had the planned phylogenetic `corpair()` examples too far down
the page. Moving a compact planned syntax block near the status table makes the
roadmap visible without implying the likelihood exists.

## Team Learning

- Ada: treat article rendering feedback as a small cleanup lane, not a new
  modelling slice.
- Boole: long formula syntax belongs in code blocks, not table cells.
- Noether: scalar covariance equations can be clearer than full matrices when
  the reader needs to distinguish model layers.
- Pat: put planned-but-important syntax where applied readers first look.
- Grace: rebuild the exact pkgdown article after visual fixes.
- Rose: keep "planned, not fitted yet" attached to every future-facing syntax
  example.

## Known Limitations

This did not implement predictor-dependent phylogenetic `corpair()` models or
change profile interval support.

## Next Actions

Slice 14 should turn this roadmap wording into a clean design slice for
ordinary, phylogenetic, and spatial `corpair()` expansion boundaries.
