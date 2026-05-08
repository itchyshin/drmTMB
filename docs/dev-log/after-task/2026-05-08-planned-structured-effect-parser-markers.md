# After Task: Planned Structured-Effect Parser Markers

## Goal

Lock the public planned grammar for phylogenetic and spatial structured effects
without pretending that the TMB likelihood can fit those effects yet.

## Implemented

`drm_formula()` now parses `phylo()` and `spatial()` marker calls as structured
metadata and validates their planned grammar. `drmTMB()` still rejects these
terms before fitting, but now reports that the syntax is planned rather than
falling through to a generic unsupported-term error.

## Mathematical Contract

No likelihood math was added in this task. The parser now reserves syntax for
the future structured Gaussian effect

```text
eta_d,i = X_d,i beta_d + Z_d,i z
z ~ Normal(0, sigma_z^2 K)
```

where `K` will be a phylogenetic covariance induced by an ultrametric
branch-length tree, or a spatial covariance represented through an SPDE/GMRF
precision. This task only records the user's intended `Z_d` source and grouping
structure; it does not construct `K`, `K^{-1}`, or evaluate a prior density.

Reserved R syntax:

```r
phylo(1 | species, tree = tree)
phylo(1 + x | species, tree = tree)
spatial(1 | site, coords = coords)
spatial(1 | site, mesh = mesh)
```

## Files Changed

- `R/parse-formula.R`: parses and validates structured marker calls.
- `R/drmTMB.R`: gives planned-feature errors for recognized structured terms.
- `R/formula-markers.R`: adds examples for planned marker signatures.
- `tests/testthat/test-package-skeleton.R`: checks parser metadata and
  malformed marker calls.
- `tests/testthat/test-gaussian-location-scale.R`: checks univariate planned
  marker rejection.
- `tests/testthat/test-biv-gaussian.R`: checks bivariate planned marker
  rejection.
- `docs/design/01-formula-grammar.md`: documents parser-recognized but
  unimplemented structured markers.
- `vignettes/formula-grammar.Rmd`: adds the planned marker examples.
- `NEWS.md`, `docs/dev-log/known-limitations.md`, `man/phylo.Rd`, and
  `man/spatial.Rd`: synchronized user-facing status.
- `docs/dev-log/check-log.md`: records verification.

## Checks Run

- `Rscript -e 'devtools::load_all(quiet = TRUE); ...'`
- `Rscript -e "devtools::test(filter = 'package-skeleton')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- stale-wording `rg` scan for old bare `phylo(species)`, `Cphy`,
  `spatial(x, y)`, and generic public unsupported-status wording;
- `git diff --check`

Results:

- focused parser test: 35 passed, 0 failed;
- full test suite: 420 passed, 0 failed;
- pkgdown check: no problems found;
- pkgdown site: built successfully;
- R CMD check: 0 errors, 0 warnings, 0 notes;
- stale-wording scan found only expected historical after-task notes, parser
  failure tests, and still-valid generic unsupported-term tests for unrelated
  syntax;
- whitespace check: passed.

## Tests Of The Tests

The new tests include malformed inputs that must fail:

- old shorthand `phylo(species)`;
- missing `tree`;
- oversized structured slope terms;
- `spatial()` with neither `coords` nor `mesh`;
- `spatial()` with both `coords` and `mesh`;
- nested marker calls such as `log(phylo(...))`;
- structured markers in currently unsupported univariate and bivariate fits.

The positive tests also check that both `coords = coords` and `mesh = mesh`
spatial forms are captured as structured metadata.

These tests protect the planned API while keeping the likelihood boundary
explicit.

## Consistency Audit

The code, docs, tests, NEWS, known limitations, and generated Rd files now agree
on these points:

- `phylo(1 | species, tree = tree)` is the canonical public phylogenetic syntax;
- public `phylo()` should use an ultrametric tree with branch lengths;
- `spatial(1 | site, coords = coords)` and
  `spatial(1 | site, mesh = mesh)` are the canonical spatial forms;
- these markers are parsed but not fitted;
- residual `rho12` remains distinct from phylogenetic or spatial covariance.

## What Did Not Go Smoothly

The first test expected `phylo(species)` to fail because `tree` was missing, but
the parser correctly rejected it earlier for not using random-effect syntax.
The test was adjusted to assert the actual, more fundamental grammar error.

`air` is still unavailable locally, so formatting was checked with
`git diff --check` and package checks rather than the preferred formatter.

Rose's audit also noticed that the documented `mesh = mesh` spatial path had a
no-op marker test but no positive metadata assertion. That gap was closed before
commit.

## Team Learning

The staggered workflow worked well here: Curie proposed compact parser tests,
Jason identified the need for planned-feature errors before TMB spec
construction, and Rose's after-task protocol forced the generated docs and
known limitations to be updated with the code. Boole's formula-review lens
should be brought in explicitly before the first fitted structured-effect
implementation.

The useful pattern is to stabilize public syntax one step before numerical
implementation, but to make the unsupported boundary impossible to miss.

## Known Limitations

No A-inverse construction, tree validation, mesh construction, SPDE precision,
TMB structured-effect prior, prediction, extraction, or simulation recovery was
implemented. Structured effects remain unavailable for fitting.

## Next Actions

1. Implement tree validation for the future `phylo()` path: branch lengths,
   ultrametricity, unique tip labels, and data/tree label matching.
2. Add a tiny dense tree comparator before introducing sparse A-inverse code.
3. Add the first univariate Gaussian `mu` structured random intercept likelihood
   using the Hadfield and Nakagawa sparse precision route.
4. Only after that, add simulation recovery for phylogenetic SD and compare the
   sparse route against an independent dense likelihood on a tiny tree.
