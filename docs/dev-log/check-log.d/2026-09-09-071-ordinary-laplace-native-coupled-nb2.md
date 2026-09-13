# 0.7.1 ordinary-Laplace — native coupled-NB2 prerequisite

Date: 2026-09-09  
Branch: `codex/071-ordinary-laplace-bridge`  
Scope: one ordinary complete-data NB2 `mu`--`sigma` labelled random-intercept
pair, required before the R-to-Julia four-fixture parity bridge can be built.

## Checks

```sh
Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-nbinom2-location-scale.R", reporter = testthat::StopReporter$new())'
```

Passed after the final implementation: every test block in
`test-nbinom2-location-scale.R`, including the new labelled mean--scale pair,
all existing refusal controls, `profile_targets()`, `corpairs()`, the native
`rho_mu_sigma_re` report, and the R reconstruction of conditional sigma modes.

```sh
Rscript -e 'devtools::load_all(quiet = TRUE); files <- c("tests/testthat/test-nbinom2-location-scale.R", "tests/testthat/test-covariance-block-registry.R", "tests/testthat/test-profile-targets.R"); for (f in files) testthat::test_file(f, reporter = testthat::StopReporter$new())'
```

Passed: NB2, covariance-registry, and profile-target focused suites. The
combined local check completed in 34.2 seconds. Its Julia-bridge footer reports
zero live Julia tests: this command validates native R/TMB behavior only.

## Tests of the tests

The added test was run before implementation and failed at the established NB2
random-effect refusal. An initial implementation left
`eta_cor_mu_sigma` disconnected from NB2 because conditioning had been placed
in a neighbouring likelihood branch; the deterministic fixture then returned a
zero gradient and `pdHess = FALSE`. The final test asserts the fitted
correlation transform, TMB native report, and R-side conditional-mode transform,
so that misrouting cannot pass as a parser-only success.

## Boundary scan

The following inventory scan identified and synchronized stale NB2 wording in
the README, formula grammar, limitations ledger, and workflow registry:

```sh
rg -n -i 'labelled.*(nb2|nbinom2)|(nb2|nbinom2).*labelled|joint.*mu.?sigma.*random|cross.*(mu|mean).*(sigma|scale)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

The route remains limited to one matching labelled ordinary intercept pair in
complete, non-zero-inflated data. Slopes, multiple or unmatched blocks,
structured effects, missing-data integration, interval claims, coverage, and
general NB2 covariance claims are still excluded.
