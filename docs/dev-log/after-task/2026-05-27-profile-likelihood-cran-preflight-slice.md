# After Task: Profile-Likelihood CRAN-Style Preflight Slice

## Goal

Run the CRAN-style local gate before publishing the profile-likelihood curve
helper bundle.

## Implemented

This slice added the final preflight polish:

- a NEWS bullet naming the exported `profile()` and `plot()` profile-curve
  workflow;
- a profile-CI design-note paragraph that distinguishes `confint()` interval
  tables from `profile()` plus `plot()` curve diagnostics; and
- a `plot.profile.drmTMB()` CRAN NOTE fix using the ggplot data pronoun in
  aesthetic mappings, with `.data` registered via `utils::globalVariables()`.

## Mathematical Contract

No likelihood, transformation, or interval calculation changed. `confint()`
remains the interval-table interface. `profile(fit, parm = target)` computes
the full `TMB::tmbprofile()` curve for selected direct targets, and
`plot(profile_object)` displays likelihood-ratio distance with the fitted
estimate, confidence-level cutoff, and profile confidence endpoints.

## Files Changed

- `R/profile.R`
- `NEWS.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-27-profile-likelihood-cran-preflight-slice.md`

## Checks Run

```sh
air format NEWS.md docs/design/12-profile-likelihood-cis.md R/profile.R tests/testthat/test-profile-plots.R vignettes/model-workflow.Rmd
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n "99% profile|0\\.99|qchisq\\(0\\.99|Bayesian credible|posterior|credible interval|profile-likelihood.*99|profile.*posterior|profile.*Bayesian" NEWS.md README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes tests/testthat R man _pkgdown.yml -g '!*.html'
Rscript --vanilla -e "devtools::test(filter = '^profile-plots$', reporter = 'summary')"
Rscript --vanilla -e "devtools::load_all(quiet = TRUE); x <- data.frame(parm = 'sigma', level = 0.95, profile_value = c(0.7, 1, 1.3), delta_deviance = c(3.84, 0, 3.84), estimate = 1, profile_pass = 'profile', elapsed = 0.01, profile_controls = 'synthetic', profile_source = 'synthetic source', conf.low = 0.7, conf.high = 1.3, conf.status = 'profile'); class(x) <- c('profile.drmTMB', class(x)); p <- plot(x); stopifnot(inherits(p, 'ggplot')); cat('ok synthetic plot after .data patch\\n')"
Rscript --vanilla -e "devtools::check()"
git diff --check
```

- The first `devtools::check()` run completed with one visible-binding NOTE in
  `plot.profile.drmTMB()`.
- After the `.data` patch, focused profile-plot tests passed and synthetic plot
  dispatch succeeded.
- The second `devtools::check()` run passed with 0 errors, 0 warnings, and
  0 notes.
- `pkgdown::check_pkgdown()` reported no problems.
- The stale-wording scan found intended "not Bayesian credible" guidance, older
  posterior-boundary design notes, and numerical correlation guards, but no new
  99% profile default or posterior wording in the profile-curve material.
- `git diff --check` was clean.

## Tests Of The Tests

The first `devtools::check()` run caught a real CRAN NOTE caused by tidy-eval
column names in `ggplot2::aes()`. The focused profile-plot test and synthetic
plot dispatch were rerun after the fix to confirm that the plot path still
works.

## Consistency Audit

The public story is now synchronized: NEWS announces the new curve helpers,
the profile-CI design note explains their relationship to `confint()`, the
model-workflow article shows the 95% residual-`sigma` profile, and the test
suite mechanically checks that the sampled curve extends beyond the 95%
cutoff on both sides.

## GitHub Issue Maintenance

Release issue #342 remains the relevant issue ledger for this profile-
likelihood demonstration. This slice did not add an issue comment; the comment
should be added after the commit or PR exists so it can reference durable
GitHub objects.

## What Did Not Go Smoothly

`devtools::document()` initially rewrote several unrelated Rd links and added
`RoxygenNote`; those generated changes were manually trimmed from the staged
bundle so the PR stays focused. The first `devtools::check()` then found the
ggplot visible-binding NOTE, which was fixed with `.data` mappings.

## Team Learning

- Ada kept the preflight tied to the publish loop.
- Fisher checked the profile plot remains likelihood-ratio evidence.
- Gauss and Noether confirmed that no interval calculation changed.
- Pat checked the `confint()` versus `profile()` plus `plot()` distinction.
- Grace ran documentation, pkgdown, focused tests, synthetic plot dispatch,
  full `devtools::check()`, and diff hygiene.
- Rose recorded both the roxygen churn and ggplot NOTE patterns for future
  slices.
- No spawned subagents were running.

## Known Limitations

This preflight does not prove CI will pass on every GitHub Actions platform.
That remains the next publish-loop step after pushing the branch.

## Next Actions

Commit and push the staged profile bundle, create or update the PR, watch
GitHub Actions, and then update release issue #342 with the PR and validation
evidence.
