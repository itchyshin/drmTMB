# After Task: phylogenetic OU covariance

## Goal

Add a clearly bounded evolutionary tree OU covariance choice to `phylo()`,
while keeping it separate from temporal and spatial OU work.

## Implemented

`phylo(1 | species, tree = tree, model = "ou")` now fits one univariate
Gaussian ML location intercept with stationary tree OU covariance. Brownian
motion remains the default when `model` is omitted. The fit exposes the positive
point estimate `fit$decaypars$phylo[["decay_phylo"]]`, conditional modes,
fitted values, residuals, diagnostics, and seeded simulation.

## Mathematical Contract

For tip distance \(d_{ij}\), the latent covariance is
\(s_{phylo}^2\exp(-\alpha d_{ij})\), with \(\alpha>0\). The native provider
uses a stationary root density and an edge transition with coefficient
\(\exp(-\alpha l)\) and variance factor \(1-\exp(-2\alpha l)\). This is not
a Brownian limit: small decay approaches an all-ones correlation and large
decay approaches independent tips.

## Files Changed

The parser, layout and simulation helper are in `R/formula-markers.R`,
`R/parse-formula.R`, `R/phylo-utils.R`, `R/drmTMB.R`, `R/methods.R`,
`R/profile.R`, `R/check.R`, and `src/drmTMB.cpp`. Parser, native, dense-oracle,
reduction, and public-interface tests are in
`tests/testthat/test-phylo-ou-covariance-parser.R` and
`tests/testthat/test-phylo-ou-covariance-native.R`. The plan, gates, retained
recovery fixtures, timing receipt, and rendered reader artifact live in
`docs/dev-log/plans/2026-09-11-phylo-ou-covariance/`.

## Checks Run

PO2 through PO9 passed through `tools/phylo-ou-covariance-gates.R`. These cover
formula parsing, native fitting, a dense `ape::corMartins` covariance oracle,
automatic score and observed-Hessian checks at two finite-difference steps,
named reductions and mutations, public methods, the retained recovery receipt,
timing receipt, and rendered reader material. `devtools::document()` and the
formula-grammar render both passed after the reader repair. The final source
package check, run with `--no-tests --no-manual --no-build-vignettes`, reported
0 errors, ran all examples and vignettes (including `formula-grammar.Rmd`), and
retained one pre-existing top-level warning (`checkbashisms` unavailable and
`tools-scratch`) plus two environment notes (clock and `xcrun_db`). The first
full test attempt was stopped after it ceased writing output in the unrelated
Julia test stage; the final focused PO3--PO6 suite passed instead.

## Tests Of The Tests

The native test uses an independent dense covariance rather than reproducing
the Markov-tree implementation. It verifies the root normalizer, every edge,
score and Hessian, and mutations that omit the root, use a wrong innovation
variance, compress branch lengths, substitute Brownian covariance, use a
row-order temporal kernel, or share independent tree states. Parser tests reject
malformed models and unsupported combinations.

## Consistency Audit

The recorded scans covered `README.md`, `NEWS.md`,
`docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`,
`docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
`vignettes/formula-grammar.Rmd`, `R`, `man`, and `tests`, using the patterns
`phylo(...model = "ou")|decay_phylo|phylogenetic OU|evolutionary OU` and
`temporal OU|Brownian.*OU|OU.*Brownian`. The reader material, NEWS, and the
limitations ledger now use the same point-estimate-only boundary.

## GitHub Issue Maintenance

The only matching open issue is #1302, for the distinct Brownian phylogenetic
intercept plus independent temporal OU series route. It was left unchanged:
this arc implements evolutionary tree OU covariance, not that paired model.

## What Did Not Go Smoothly

The first recovery runner supplied `tree = fixture$tree`, which correctly
failed because the public grammar requires a tree symbol. The failure receipt is
retained; the runner was repaired to bind `tree <- fixture$tree` without
changing fixtures, seeds, likelihood, or thresholds. The frozen 12-fixture
panel then found weak global-intercept versus tree-field separation in several
draws. Its failed every-fixture intercept threshold is retained.

## Team Learning

An evolutionary OU covariance needs its own reader language: decay is inverse
branch-length scale, and it cannot be explained as temporal persistence. The
independent dense covariance, derivatives, root-plus-edge simulation, and a
concrete reader example catch different mistakes and all remain necessary.

## Known Limitations

This initial route is univariate Gaussian ML with one phylogenetic location
intercept, fixed mean effects and offsets, constant residual `sigma`, and at
least three observed species. Slopes, `sigma`-side phylogenetic OU, ordinary or
other structured effects, temporal terms, REML, non-Gaussian families,
new-data prediction, forecasts, and decay intervals are unavailable. The
retained fixtures do not support point-recovery, interval, or coverage claims.

## Next Actions

Keep future scale-side phylogenetic OU as a separate child with its own decay,
identification analysis and evidence gates. Do not combine this provider with
the existing temporal, spatial, or phylogeny-by-time programmes without a
separate model contract.
