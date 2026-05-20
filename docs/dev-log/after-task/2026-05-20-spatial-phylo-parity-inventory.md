# After Task: Spatial Toward Phylogenetic Parity Inventory

## Goal

Name the next spatial implementation lane without letting "same as phylo" turn
into unsupported spatial claims.

## Implemented

This is a documentation and planning slice. It does not add a likelihood path.
The implemented claim is narrower: the next spatial parity gate is
coordinate-spatial q=2 bivariate `mu1`/`mu2` location covariance with
`corpairs(level = "spatial")`, direct profile-target labels, a small recovery
test, and a dense covariance comparator.

## Mathematical Contract

The fitted spatial surface remains univariate Gaussian `mu` only:

```text
eta_mu,i = X_i beta + z0_site[i] + x_i z1_site[i]
z0 ~ MVN(0, sd0^2 M)
z1 ~ MVN(0, sd1^2 M)
cov(z0, z1) = 0 in the first one-slope path
```

The next bivariate spatial target should mirror the fitted phylogenetic q=2
location-location layer, replacing the tree-derived relationship matrix with a
coordinate-spatial covariance or precision:

```text
[a_mu1, a_mu2] ~ MatrixNormal(0, M, Sigma_spatial)
mu1_i = X1_i beta1 + a_mu1[site_i]
mu2_i = X2_i beta2 + a_mu2[site_i]
```

That target is not spatial `sigma`, spatial q=4 location-scale covariance,
spatial direct-SD regression, or spatial `corpair()` regression.

## Files Changed

- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/forgotten-promises-status-2026-05-20.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = 'spatial-gaussian|phylo-gaussian', reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'phylo\(1 \+ x1 \| species, tree = tree\)|spatial q=4|bivariate spatial q=4|spatial direct-SD|spatial `corpair\(\)`|corpairs\(level = "spatial"\)|sd_spatial\*|sd_animal\*|sd_relmat\*' README.md ROADMAP.md docs/design docs/dev-log/forgotten-promises-status-2026-05-20.md
rg -n 'phylo\(1 \+ x1 \| species, tree = tree\).*Fitted|spatial q=2.*Admit|spatial q=4.*implemented|bivariate spatial.*implemented|corpairs\(level = "spatial"\).*fitted' README.md ROADMAP.md docs/design docs/dev-log/forgotten-promises-status-2026-05-20.md
git diff --check
```

Focused phylogenetic and spatial tests passed. `pkgdown::check_pkgdown()`
reported no problems. `git diff --check` was clean.

## Tests Of The Tests

No new test was added because this slice changes documentation only. The
focused test run rechecked the currently fitted phylogenetic and coordinate
spatial surfaces so the planning text stayed anchored to code that still
passes.

## Consistency Audit

The stale-wording scan confirmed that q=2 spatial covariance is described as a
next gate, not an admitted simulation surface. The second scan returned only
pre-simulation matrix rows that still admit univariate coordinate-spatial grids
and keep bivariate spatial covariance planned. Ada also fixed a reader-facing
trap in `docs/design/01-formula-grammar.md`: the planned
`phylo(1 + x1 | species, tree = tree)` spelling is now separated from the
fitted spatial one-slope syntax block.

## GitHub Issue Maintenance

Ada inspected open issues with spatial, phylogenetic, animal, `relmat()`,
simulation, profile, bootstrap, figure, and pkgdown keywords. No open PR was
present. Issue #5 was the best existing home for the bivariate spatial q=2
covariance checkpoint, so Ada added:

<https://github.com/itchyshin/drmTMB/issues/5#issuecomment-4503081661>

## What Did Not Go Smoothly

The internal implementation still reuses `phylo_mu` machinery for the first
coordinate-spatial path. That is acceptable in code, but it is easy for docs to
blur "shared sparse-precision machinery" into "same public capability." The
new parity ladder is meant to stop that drift before the next code slice.

Ada also tripped a shell quoting issue during one `rg` audit because backticks
inside a double-quoted pattern made zsh try to execute `corpair()`. The scan was
rerun with single quotes and recorded in `docs/dev-log/check-log.md`.

## Team Learning

Ada keeps the lane small. Boole and Noether keep syntax and equations aligned.
Fisher requires the next spatial q=2 slice to have simulation recovery and a
dense comparator before Phase 18 admission. Pat wants the first example framed
as a biological spatial question before covariance mechanics. Grace keeps
pkgdown and CI checks attached to documentation changes. Rose watches the
phrase "spatial parity" so it remains a staged target rather than a claim.

## Known Limitations

Coordinate spatial support remains univariate Gaussian `mu` intercept plus one
numeric independent slope. Mesh/SPDE, multiple slopes, spatial slope
correlations, spatial `sigma`, bivariate spatial covariance, spatial q=4,
spatial direct-SD surfaces, spatial `corpair()` regression, and simultaneous
phylo-plus-spatial fitted layers remain planned.

## Next Actions

1. Implement the q=2 bivariate coordinate-spatial `mu1`/`mu2` covariance path.
2. Add `corpairs(level = "spatial")` rows and direct profile targets for that
   q=2 path.
3. Add a small simulation recovery test and a dense covariance comparator.
4. Only then decide whether the spatial example belongs in the structural
   dependence article or should wait for the future article split.
