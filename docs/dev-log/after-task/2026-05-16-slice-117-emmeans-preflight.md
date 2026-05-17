# After Task: Slice 117 emmeans preflight

## Goal

Test the existing reference-grid and link-scale contract before any exported
`emmeans` method, contrast helper, or weighting API is designed.

## Implemented

Slice 117 adds `tests/testthat/test-reference-grid-link-scale-contract.R`. The
new tests fit small fixed-effect models, build explicit `prediction_grid()`
objects, and verify that `predict_parameters(type = "response")` is the
documented inverse-link transform of `predict_parameters(type = "link")` for
the fitted distributional parameters.

## Mathematical Contract

The tested contract is table-level rather than likelihood-level:

- `identity`: `theta = eta`
- `log`: `theta = exp(eta)`
- `logit`: `theta = logit^{-1}(eta)`
- `logm2`: `theta = 2 + exp(eta)`
- `atanh_guarded`: `rho12 = 0.99999999 * tanh(eta)`

No new likelihood, formula grammar, interval method, or marginal-mean estimand
was added.

## Files Changed

- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-117-emmeans-preflight.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-183516-codex-checkpoint.md`
- `tests/testthat/test-reference-grid-link-scale-contract.R`

## Checks Run

- `air format ROADMAP.md docs/design/39-visualization-grammar.md tests/testthat/test-reference-grid-link-scale-contract.R`: passed.
- `Rscript -e "devtools::test(filter = 'reference-grid-link-scale-contract', reporter = 'summary')"`: passed.
- `Rscript -e "devtools::test(filter = 'reference-grid-link-scale-contract|prediction-grid|predict-parameters|marginal-parameters', reporter = 'summary')"`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rebuilt `pkgdown-site/ROADMAP.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n 'Slice 117|reference-grid and link-scale|predict_parameters\\(type = "link"\\)|predict_parameters\\(type = "response"\\)|emmeans dependency|contrast API' ROADMAP.md docs/design/39-visualization-grammar.md tests/testthat/test-reference-grid-link-scale-contract.R pkgdown-site/ROADMAP.html`: confirmed source and rendered roadmap wording.
- `rg -n 'emmeans method|exported `emmeans`|exported emmeans|EMM support|estimated marginal means.*implemented|contrast API|contrasts.*implemented|ggplot2.*Imports' DESCRIPTION NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md tests/testthat/test-reference-grid-link-scale-contract.R pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`: found only intentional design-boundary wording.
- `Rscript tools/codex-checkpoint.R --goal "Slice 117 emmeans preflight" --next "stage, commit, push branch, open PR, and monitor CI"`: passed and wrote `docs/dev-log/recovery-checkpoints/2026-05-16-183516-codex-checkpoint.md`.

## Tests Of The Tests

The new integration test covers fixed-effect Gaussian, Student-t, lognormal,
Gamma, beta, beta-binomial, cumulative-logit, Poisson, zero-inflated Poisson,
NB2, zero-truncated NB2, hurdle NB2, zero-inflated NB2, and bivariate Gaussian
fits. It would fail if `predict_parameters()` stopped forwarding the requested
`type`, if row order drifted between link and response tables, or if the grid
metadata stopped recording the number of grid rows.

## Consistency Audit

ROADMAP and the visualization grammar now say that Slice 117 is a preflight
test, not user-facing `emmeans` support. NEWS was intentionally left unchanged
because no user-facing function, argument, or article workflow changed.

## What Did Not Go Smoothly

The first local run exposed a test-helper mistake: `stats::scale()` is not the
right namespace on this R setup. The helper now calls `scale()` directly, and
the focused test passes.

## Team Learning

Ada kept the work to a validation slice before implementation. Fisher treated
link-versus-response scale as the estimand boundary for future EMM work. Boole
checked that no new syntax or exported method was implied. Grace owned focused
tests and pkgdown checks. Rose owned the stale-claim scan and the explicit
limitation. Pat and Darwin stayed watch-only because no tutorial path changed.
Gauss, Noether, Curie, Emmy, and Jason stayed watch-only because no likelihood,
symbolic equation, test framework, object structure, or landscape claim changed.

## Known Limitations

The preflight covers implemented fixed-effect family paths and bivariate
Gaussian fixed-effect predictions. It does not yet test structured-effect,
random-effect, conditional, weighted, interval-aware, slope, or contrast
reference grids. It also does not add or register an `emmeans` method.

## Next Actions

Decide whether the next EMM-adjacent slice should be a design-only S3 contract,
an internal reference-grid adapter, or another validation slice for
structured-effect and random-effect predictions.
