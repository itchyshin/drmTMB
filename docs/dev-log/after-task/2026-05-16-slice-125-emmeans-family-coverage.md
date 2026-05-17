# After Task: Slice 125 emmeans family coverage

## Goal

Strengthen the first public `emmeans()` method with direct tests for every
univariate model type already admitted by the fixed-effect `mu` gate. This is a
coverage slice, not an API expansion.

## Implemented

`tests/testthat/test-emmeans-methods.R` now has a shared
`expect_emmeans_mu_prediction_parity()` helper. The helper builds
`emmeans::emmeans(fit, ~habitat, at = list(x = 0))`, summarizes it on the link
and response scales, and compares those estimates to
`predict(fit, newdata = grid, dpar = "mu", type = ...)` on the same reference
grid.

The new test covers Student-t, lognormal, Gamma, beta-binomial, NB2, and
zero-truncated NB2 fits. Gaussian, Poisson, and beta coverage already existed
from Slice 122.

## Files Changed

- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-125-emmeans-family-coverage.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-202613-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- `air format tests/testthat/test-emmeans-methods.R`
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"`
- `air format ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-slice-125-emmeans-family-coverage.md tests/testthat/test-emmeans-methods.R`
- `git diff --check`
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n 'Slice 125|Student-t, lognormal, Gamma, beta-binomial, NB2|zero-truncated NB2|remaining univariate|already admitted|link-scale and response-scale EMMs|expect_emmeans_mu_prediction_parity|student_y|lognormal_y|gamma_y|positive_count|beta_binomial_fit' ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R pkgdown-site/ROADMAP.html`
- `rg -n 'sigma.*emmeans.*works|random-effect.*emmeans.*works|bivariate.*emmeans.*works|zero-inflated.*emmeans.*works|hurdle.*emmeans.*works|ordinal.*emmeans.*works|contrast.*emmeans.*implemented|slope.*emmeans.*implemented|all.*emmeans.*targets|fitted response.*emmeans.*works|widen.*emmeans.*gate' ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`: returned no matches.
- `Rscript tools/codex-checkpoint.R --goal "Slice 125 emmeans family coverage" --next "commit Slice 125, then wait for Slice 124 PR #89, merge it, rebase Slice 125, rerun focused checks, push, and open PR"`
- Post-rebase `git diff --check origin/main...HEAD`
- Post-rebase `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`

## Consistency Audit

The roadmap and design notes describe Slice 125 as family-coverage evidence for
the existing fixed-effect univariate `mu` gate. They do not claim support for
non-`mu`, bivariate, zero-inflated, hurdle, ordinal expected-score,
random-effect, structured-effect, fitted-response, contrast, slope, or
interval-specialized workflows.

## Known Limitations

- This does not change `recover_data.drmTMB()` or `emm_basis.drmTMB()`.
- It does not test custom weights, offsets, contrasts, slopes, or finite-sample
  degrees of freedom.
- It does not make zero-inflated, hurdle, ordinal, bivariate, or random-effect
  models eligible for `emmeans()`.

## Team Notes

Curie should keep `emmeans` expansion test-first and tied to explicit
prediction parity. Fisher should keep the estimand named as native `mu` until
another distributional parameter has its own reference-grid contract. Rose
should scan for accidental broad-support claims whenever a coverage slice makes
the first public bridge look more mature.
