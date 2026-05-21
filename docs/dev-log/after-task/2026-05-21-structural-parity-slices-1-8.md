# After Task: Structural Parity Slices 1-8

## Goal

Finish the next post-0.1.3 structural-dependence parity slices without blurring
what is fitted today. The implemented claim is narrow: bivariate Gaussian
models now fit constant all-four q=4 `animal()` and `relmat()` location-scale
blocks from the same known matrix, while spatial q=4, direct spatial/animal/
relmat SD grammar, structured slopes, standalone relatedness scale terms, and
combined phylo-plus-spatial layers remain planned.

## Implemented

| Slice | User-facing status |
| --- | --- |
| 1. Spatial direct-SD gate | Kept planned. No `sd_spatial()` syntax was added. |
| 2. Spatial q=4 admission audit | Kept planned with an explicit fit-time error for attempted spatial `sigma` q=4 blocks. |
| 3. Animal/relmat q=4 parity | Fitted for constant all-four `mu1`/`mu2`/`sigma1`/`sigma2` blocks. |
| 4. Animal/relmat direct-SD grammar | Kept planned. No `sd_animal()` or `sd_relmat()` syntax was added. |
| 5. Combined phylo plus spatial | Kept planned. Separate sensitivity models remain the user route. |
| 6. Implementation | Reused the existing structured q4 backend for `animal()` and `relmat()`. |
| 7. Focused smoke | Added a deterministic q4 known-matrix smoke test in the animal/relmat test file. |
| 8. Extractors and diagnostics | Hardened `corpairs()`, `summary()$covariance`, `profile_targets()`, and `check_drm()` status for the new rows. |

The pkgdown root was also fixed by changing `_pkgdown.yml` to root-mode site
deployment. The public base URL was returning GitHub Pages 404 because the
latest successful workflow uploaded only a `dev/` subtree while the advertised
URL stayed `https://itchyshin.github.io/drmTMB/`.

## Mathematical Contract

The fitted q=4 animal/relmat block uses one structured source, one grouping
factor, one matrix input, and one covariance-block label across `mu1`, `mu2`,
`sigma1`, and `sigma2`. It estimates four endpoint SDs and six latent
structured correlations. The residual correlation `rho12` remains a separate
within-observation residual coscale parameter.

Full q=4 correlations are derived from the unstructured covariance
parameterization and stay marked as derived interval targets rather than direct
profile-ready atanh targets.

## Files Changed

- Core code: `R/drmTMB.R`, `R/profile.R`, `R/check.R`, `R/methods.R`,
  `R/formula-markers.R`.
- Tests: `tests/testthat/test-animal-relmat-gaussian.R`,
  `tests/testthat/_snaps/animal-relmat-gaussian.md`.
- Public docs and ledgers: `README.md`, `ROADMAP.md`, `NEWS.md`,
  `_pkgdown.yml`, `docs/design/01-formula-grammar.md`,
  `docs/design/02-family-registry.md`, `docs/design/03-likelihoods.md`,
  `docs/design/16-phylo-spatial-common-math.md`,
  `docs/design/34-validation-debt-register.md`,
  `docs/design/37-worked-example-inventory.md`,
  `docs/design/39-visualization-grammar.md`,
  `docs/design/41-phase-18-simulation-programme.md`,
  `docs/design/45-cross-dpar-correlation-gate.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`,
  `docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md`,
  `docs/design/55-phase-18-animal-relmat-q2-interval-status.md`, and
  `docs/design/57-structural-parity-next-slices.md`.
- Articles: `vignettes/animal-models.Rmd`,
  `vignettes/relmat-known-matrices.Rmd`, `vignettes/model-map.Rmd`,
  `vignettes/formula-grammar.Rmd`, `vignettes/source-map.Rmd`,
  `vignettes/structural-dependence.Rmd`,
  `vignettes/phylogenetic-spatial.Rmd`, and
  `vignettes/figure-gallery.Rmd`.
- Generated docs: `man/animal.Rd`, `man/relmat.Rd`, `man/corpairs.Rd`, and
  `man/check_drm.Rd`.

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian')"
Rscript -e "devtools::test(filter = 'phylo-gaussian|profile-targets|check-drm|covariance-block-registry')"
Rscript -e "pkgdown::build_site(new_process = FALSE, install = TRUE)"
Rscript -e "pkgdown::build_home()"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

- `animal-relmat-gaussian`: 89 passed, 0 failed, 0 warnings, 0 skipped.
- `phylo-gaussian|profile-targets|check-drm|covariance-block-registry`: 1041
  passed, 0 failed, 0 warnings, 0 skipped.
- `pkgdown::build_site(new_process = FALSE, install = TRUE)` completed and
  wrote `pkgdown-site/index.html`.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.

## Tests Of The Tests

The q4 smoke test checks fitted `relmat()` and `animal()` all-four formulas,
finite objectives, SD labels, six `corpairs()` rows, class counts, summary
covariance rows, `profile_targets()` derived status, `check_drm()` q4
diagnostics, and broad fixed-effect recovery. Negative snapshots check partial
q4 blocks, unlabelled q4 blocks, and mismatched q2 labels. The new class-filter
expectation exposed a real duplicate-row bug in `corpairs()`, which was fixed by
excluding structured q4 rows from the generic labelled random-effect loop.

## Consistency Audit

The main stale-wording scan was:

```sh
rg -n 'animal.*q=4.*planned|q=4.*animal.*planned|relmat.*q=4.*planned|q=4.*relmat.*planned|q=4 location-scale blocks remain planned|q=4 blocks.*planned|q=2 routes' README.md ROADMAP.md NEWS.md docs/design vignettes R | head -120
```

Remaining matches are intentional spatial-q4, slope, standalone-scale,
ordinary/phylogenetic q4, broad-grid, or historical generated-news wording.
Current source docs no longer present animal/`relmat()` q4 as planned-only.

The pkgdown root check was:

```sh
test -f pkgdown-site/index.html && echo root-index-present || echo root-index-missing
test -f pkgdown-site/dev/index.html && echo dev-index-present || echo dev-index-missing
```

It returned `root-index-present` and `dev-index-missing`, matching the
single-site deployment intent.

## GitHub Issue Maintenance

Issue #147, "Implement animal() and relmat() known-relatedness structured
effects", was inspected and remains open. No issue comment was added from this
local branch because the branch has not been pushed or opened as a PR yet.

## What Did Not Go Smoothly

A first local `pkgdown::build_site(new_process = FALSE, install = FALSE)` run
failed in `vignettes/bivariate-coscale.Rmd` because it rendered against an older
installed local package that did not understand the current `corpair()` article
syntax. The same chunk fit after `devtools::load_all()`, and the full site build
passed with `install = TRUE`, which matches the working-tree install that the
GitHub Actions workflow gets through `local::.`.

## Team Learning

Ada kept the slice lane narrow and treated the pkgdown outage as a release
readiness blocker. Boole checked that syntax stays memorable: constant all-four
q4 is fitted, direct-SD grammar is not. Gauss and Noether kept the mathematical
claim tied to the existing structured q4 backend and derived interval status.
Pat and Darwin asked whether an applied user can tell what to fit now versus
what remains planned. Fisher and Curie focused on recovery and boundary tests.
Grace caught the Pages root/development-mode deployment trap. Rose closed the
stale-wording loop across README, ROADMAP, NEWS, design docs, vignettes, Rd, and
generated pkgdown pages.

## Known Limitations

- Spatial q4 blocks remain planned.
- Animal/`relmat()` structured slopes remain planned.
- Standalone animal/`relmat()` `sigma` structured effects outside the fitted
  all-four q4 block remain planned.
- `sd_animal()`, `sd_relmat()`, and `sd_spatial()` direct-SD grammar remain
  planned.
- Predictor-dependent animal/`relmat()`/spatial `corpair()` regressions remain
  planned.
- q4 correlation intervals remain derived-unavailable until a nonlinear
  interval or bootstrap route is implemented.
- Broad Phase 18 q4 animal/relmat grids need an ADEMP addendum before routine
  simulation claims.

## Next Actions

1. Push the branch and open a PR that links #147.
2. Let the pkgdown workflow redeploy from the root-mode configuration, then
   verify `https://itchyshin.github.io/drmTMB/` returns HTTP 200.
3. Add the Phase 18 q4 animal/relmat ADEMP addendum before broad simulation
   grids.
4. Continue post-0.1.3 parity with spatial q4 admission only after diagnostics
   and identifiability checks are explicit.
