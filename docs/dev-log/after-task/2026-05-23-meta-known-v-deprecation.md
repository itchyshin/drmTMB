# After Task: Deprecate meta_known_V Formula Marker

## Goal

Deprecate `meta_known_V()` as a formula marker while preserving compatibility
for existing Gaussian known sampling variance or covariance models. New
examples, diagnostics, and documentation should teach `meta_V(V = V)`.

## Implemented

`meta_known_V()` now warns through the package's existing base-R lifecycle
pattern using `.Deprecated()`. This avoids adding a `lifecycle` dependency for a
small compatibility slice. Direct calls warn, and `drm_formula()` parsing also
warns when old formulas contain `meta_known_V()` because formula marker calls
are normally stored rather than evaluated.

`meta_known_V()` was split from the preferred `meta_V()` roxygen topic into its
own deprecated marker page. `_pkgdown.yml` now lists it with other deprecated
marker internals rather than alongside the current model-specification API.
Generated Rd pages were refreshed with `devtools::document()`.

Current examples, tests, snapshots, diagnostic messages, README rows, roadmap
entries, design docs, and vignettes now lead with `meta_V(V = V)`. The old
spelling remains in targeted compatibility tests and in docs that explicitly
describe the deprecated alias. The typo `meta_kown_V()` was not added as an
alias.

No spawned subagents were used. Ada coordinated the slice. Boole checked the
formula API and user-facing marker vocabulary. Fisher checked that additive
known sampling covariance still routes to the same likelihood path and that
known `V` remains outside interval targets. Pat checked reader-facing examples
for the preferred spelling. Grace checked generated documentation, pkgdown,
vignettes, and whitespace. Rose checked stale wording and typo drift. These
were role perspectives, not running agents.

## Mathematical Contract

No likelihood parameterization changed. `meta_V(V = V)` and deprecated
`meta_known_V(V = V)` still share the same additive known sampling covariance
route for Gaussian models. The change is lifecycle and documentation only, with
parser-level warning added so old formula objects alert users before fitting.

The slice does not add a misspelled `meta_kown_V()` alias, `meta_gaussian()`,
`tau ~`, proportional `meta_V(w = w, scale = "proportional")`, non-Gaussian
known covariance, or sparse/block-sparse known covariance.

## Files Changed

- `R/formula-markers.R`
- `R/parse-formula.R`
- `R/drmTMB.R`
- `R/check.R`
- `R/family.R`
- `R/gaussian-aggregation.R`
- `R/methods.R`
- `_pkgdown.yml`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/*.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `man/*.Rd`
- `tests/testthat/*.R`
- `tests/testthat/_snaps/gaussian-aggregation.md`
- `vignettes/*.Rmd`

## Checks Run

```sh
air format NEWS.md R/check.R R/drmTMB.R R/family.R R/formula-markers.R R/gaussian-aggregation.R R/methods.R R/parse-formula.R README.md ROADMAP.md _pkgdown.yml docs/design/00-vision.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/06-distribution-roadmap.md docs/design/07-collaboration-and-site.md docs/design/08-meta-analysis.md docs/design/10-after-task-protocol.md docs/design/11-reference-programme.md docs/design/13-gaussian-location-scale-math.md docs/design/16-phylo-spatial-common-math.md docs/design/21-tutorial-style.md docs/design/22-likelihood-weights.md docs/design/23-large-data-memory.md docs/design/25-ordinal-scale-discrimination.md docs/design/27-tweedie-family-plan.md docs/design/31-gaussian-aggregation-sufficient-statistics.md docs/design/34-validation-debt-register.md docs/design/37-worked-example-inventory.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/known-limitations.md tests/testthat/_snaps/gaussian-aggregation.md tests/testthat/test-beta-binomial.R tests/testthat/test-beta-location-scale.R tests/testthat/test-biv-gaussian.R tests/testthat/test-check-drm.R tests/testthat/test-comparators.R tests/testthat/test-control.R tests/testthat/test-cumulative-logit.R tests/testthat/test-gamma-location-scale.R tests/testthat/test-gaussian-aggregation.R tests/testthat/test-hurdle-nbinom2.R tests/testthat/test-lognormal-location-scale.R tests/testthat/test-meta-known-v.R tests/testthat/test-nbinom2-location-scale.R tests/testthat/test-package-skeleton.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-poisson-mean.R tests/testthat/test-student-location-scale.R tests/testthat/test-truncated-nbinom2-location-scale.R tests/testthat/test-zi-nbinom2.R tests/testthat/test-zi-poisson.R vignettes/adding-families.Rmd vignettes/bivariate-coscale.Rmd vignettes/count-nbinom2.Rmd vignettes/distribution-families.Rmd vignettes/drmTMB.Rmd vignettes/formula-grammar.Rmd vignettes/implementation-map.Rmd vignettes/large-data.Rmd vignettes/location-scale.Rmd vignettes/meta-analysis.Rmd vignettes/model-map.Rmd vignettes/model-workflow.Rmd vignettes/proportion-beta-binomial.Rmd vignettes/relmat-known-matrices.Rmd vignettes/source-map.Rmd vignettes/testing-likelihoods.Rmd vignettes/which-scale.Rmd
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'meta-known-v|package-skeleton|gaussian-aggregation|check-drm')"
Rscript -e "devtools::test(filter = 'biv-gaussian|control|comparators|student-location-scale|lognormal-location-scale|gamma-location-scale|beta-location-scale|beta-binomial|cumulative-logit|poisson-mean|nbinom2-location-scale|zi-poisson|zi-nbinom2|hurdle-nbinom2|truncated-nbinom2-location-scale|phylo-gaussian')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::build_vignettes()"
air format docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-23-meta-known-v-deprecation.md
git diff --check
Rscript tools/codex-checkpoint.R --goal "deprecate meta_known_V formula marker" --next "review current diff, then commit or open PR for the deprecation slice"
```

Outcomes:

- `devtools::document()` completed and generated `man/meta_known_V.Rd`.
- Targeted deprecation and covariance tests passed:
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 390`.
- The wider focused regression suite passed:
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 1877`.
- `pkgdown::check_pkgdown()` reported no problems.
- `devtools::build_vignettes()` completed successfully and rebuilt package
  vignettes.
- Final `git diff --check` was clean after report formatting.
- The local recovery checkpoint was written to
  `docs/dev-log/recovery-checkpoints/2026-05-23-161606-codex-checkpoint.md`.

## Consistency Audit

The typo and deprecation-spelling scan was:

```sh
rg -n "meta_kown_V|depriciate|depricat|depreciat" README.md ROADMAP.md NEWS.md R man tests/testthat vignettes docs/design docs/dev-log/known-limitations.md _pkgdown.yml -g '!*.html'
```

It returned no hits in current code, tests, vignettes, Rd, package config, or
current design/status docs. The misspelled `meta_kown_V()` was not introduced.

The test-surface scan was:

```sh
rg -n "meta_known_V" tests/testthat
```

Remaining hits are limited to `test-package-skeleton.R` and
`test-meta-known-v.R`, where they check that direct calls and old formulas warn
and still route to the additive known-`V` path.

The R user-facing-error scan was:

```sh
rg -n "\\{\\.fn meta_known_V\\}|meta_known_V\\(\\)" R -g '*.R'
```

Remaining hits are the deprecated roxygen topic and helper in
`R/formula-markers.R`. Formula parsing still detects the symbol
`meta_known_V` internally so it can warn.

The current-docs scan leaves only explicit deprecated-alias wording,
historical NEWS/roadmap entries, and source-map/design references where the
deprecated alias itself is under discussion.

## Tests Of The Tests

The deprecation tests cover both direct marker calls and old formula syntax.
The compatibility tests compare deprecated `meta_known_V()` fits against
preferred `meta_V()` fits for diagonal and full known sampling covariance.

The wider focused regression pass covers nearby Gaussian, bivariate Gaussian,
family, control, comparator, and phylogenetic paths that could be affected by a
broad formula-marker rename. Vignette rebuilding exercises the edited teaching
examples. Full `devtools::check()` was not run in this slice.

## Issue Maintenance

No GitHub issue was closed by this lifecycle change. The existing meta-analysis
and documentation trackers should remain open until their broader scoped work is
done.
