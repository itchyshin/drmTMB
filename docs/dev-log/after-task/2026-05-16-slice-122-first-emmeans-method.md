# After Task: Slice 122 first emmeans method

## Goal

Expose the first narrow public `emmeans` bridge for `drmTMB`: fixed-effect
univariate `mu` estimated marginal means with retained model frames and
fixed-effect covariance available.

## Implemented

`emmeans` is now a suggested package. `.onLoad()` conditionally registers
`recover_data.drmTMB()` and `emm_basis.drmTMB()` with
`emmeans::.emm_register()` when `emmeans` is installed.

`recover_data.drmTMB()` uses the retained `mu` model frame and terms from the
Slice 121 preflight. `emm_basis.drmTMB()` uses the Slice 119 and 120 basis
preflight to return `X`, `bhat`, `V`, `nbasis`, asymptotic degrees of freedom,
and link metadata for the reference grid.

## Mathematical Contract

The supported estimand is an estimated marginal mean of the native
distributional parameter `mu`:

```text
eta_mu = X_mu beta_mu
mu = g^{-1}(eta_mu)
```

For identity-link Gaussian, Student-t, and lognormal `mu`, the link and response
summaries are identical. For log-link count or Gamma `mu`, response summaries
are back-transformed by `emmeans` using the same inverse link as
`predict(type = "response")`. Lognormal `mu` remains the mean of `log(y)`, not
the arithmetic response mean `E[y]`.

## Files Changed

- `DESCRIPTION`
- `NEWS.md`
- `R/emmeans-preflight.R`
- `R/zzz.R`
- `tests/testthat/test-emmeans-methods.R`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-193749-codex-checkpoint.md`

## Checks Run

- `air format DESCRIPTION NEWS.md R/emmeans-preflight.R R/zzz.R tests/testthat/test-emmeans-methods.R ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md`
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"` after adding the beta/logit response-scale parity test
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `rg -n 'Slice 122|emmeans::emmeans\\(\\)|recover_data\\.drmTMB|emm_basis\\.drmTMB|fixed-effect univariate `mu`|suggested package|conditional method registration|public `emmeans` bridge' DESCRIPTION NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`
- `rg -n 'bivariate.*emmeans.*works|zero-inflated.*emmeans.*works|hurdle.*emmeans.*works|ordinal.*emmeans.*works|random-effect.*emmGrid|structured.*emmGrid|contrast workflow.*implemented|slope.*emmeans.*implemented|all.*emmeans.*targets' DESCRIPTION NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`
- `Rscript -e "devtools::test(reporter = 'summary')"`
- `Rscript -e "devtools::check(error_on = 'never')"`: 0 errors, 0 warnings,
  2 notes. The notes were the local time-verification note and the pre-existing
  `plot_corpairs()` visible-binding note for `conf.low`, `conf.high`, and
  `.drmTMB_pair_label`.
- `Rscript tools/codex-checkpoint.R --goal "Slice 122 first emmeans method" --next "wait for Slice 121 PR, then rebase Slice 122 onto merged main, rerun post-rebase emmeans checks, push, open PR"`

All checks passed. The stale-claim scan found only intentional blocked-target
wording and unrelated existing slope-status text.

## Tests Of The Tests

The tests compare `emmeans::emmeans()` link-scale estimates to
`predict(type = "link")` for a fixed-effect Gaussian `mu` model. They also
compare response-scale Poisson and beta EMMs to `predict(type = "response")`,
confirming that log-link and logit-link back-transforms follow drmTMB's fitted
`mu` inverse link.

The blocked-path tests cover non-`mu` `dpar`, missing covariance,
memory-light fits without model frames, and ordinary random effects. The first
attempt threw errors inside `recover_data.drmTMB()`, but `emmeans::ref_grid()`
masks those as a generic data/params message. The method now returns the
preflight message as a character scalar on recovery failure, which `ref_grid()`
reports directly.

## Consistency Audit

`NEWS.md`, `ROADMAP.md`, `docs/design/39-visualization-grammar.md`, and
`docs/design/40-emmeans-interface-contract.md` all describe the support as a
first narrow bridge for fixed-effect univariate `mu`. The rendered NEWS and
roadmap contain the same scope after `pkgdown::build_site()`.

No `_pkgdown.yml` reference entry was added because there is no new exported
drmTMB function. The user-facing entry point is `emmeans::emmeans()` when the
suggested package is installed.

## What Did Not Go Smoothly

The main surprise was `emmeans::ref_grid()` masking errors thrown inside
`recover_data()`. Returning a character scalar from `recover_data.drmTMB()` is
the clearer failure path because `ref_grid()` reports that message directly.

## Team Learning

Boole should keep future `emmeans` expansion behind explicit unsupported-path
tests. Fisher should keep naming the estimand as `mu` rather than fitted
response means. Pat should keep checking error messages through
`emmeans::emmeans()` itself, not only through private helpers, because the
`emmeans` call stack can rewrite failures.

## Known Limitations

- Only fixed-effect univariate `mu` is supported.
- Fits must retain model frames and fixed-effect covariance.
- Bivariate, zero-inflated, hurdle, ordinal expected-score, random-effect,
  structured-effect, fitted-response, non-`mu`, contrast, slope, and
  interval-specialized targets remain blocked.

## Next Actions

After Slice 121 lands, rebase Slice 122 onto merged `main`, rerun post-rebase
`emmeans` checks, and open a focused PR. Later slices can add direct
`emmeans::ref_grid()` comparison coverage for additional supported univariate
families before considering wider target support.
