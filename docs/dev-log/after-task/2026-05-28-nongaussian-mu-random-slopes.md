# After Task: Non-Gaussian Mu Random Slopes

## Goal

Promote the first Team B no-to-yes slope cells by fitting ordinary unlabelled
independent numeric `mu` random slopes for selected one-response non-Gaussian
families, without opening correlated slopes, labels, structured effects,
scale/shape random effects, zero-one beta random effects, or hurdle/inflation
random effects.

## Implemented

`student()`, `lognormal()`, `Gamma(link = "log")`, `beta()`,
`beta_binomial()`, and non-hurdle `truncated_nbinom2()` now accept ordinary
unlabelled `mu` terms of type `intercept` or `slope`. The supported slope
syntax is the independent form `(0 + x | id)`, optionally beside `(1 | id)`.
Malformed-neighbour tests now use correlated terms such as `(1 + x | id)` or
labelled blocks to keep the unsupported boundary explicit.

## Mathematical Contract

The new terms enter only the location linear predictor:

```text
eta_mu = X_mu beta_mu + Z_mu b_mu
b_mu ~ Normal(0, diag(sd_mu^2))
```

The link is family-specific: identity for Student-t location, log-response
location for lognormal, log mean for Gamma and zero-truncated NB2, and logit
mean or success probability for beta and beta-binomial. `sigma`, `nu`, `zi`,
`hu`, `zoi`, and `coi` remain fixed-effect-only or unsupported as documented.

## Files Changed

Core validation changed in `R/drmTMB.R`; family help text changed in
`R/family.R`; generated Rd files changed under `man/`. The new recovery test is
`tests/testthat/test-nongaussian-mu-random-slopes.R`, with nearby malformed
tests updated in the affected family files. Public status text was synchronized
across `README.md`, `NEWS.md`, `ROADMAP.md`, the formula grammar, family
registry, likelihood notes, readiness matrices, implementation/source/model-map
vignettes, the proportion tutorial, known limitations, and this check log.

## Checks Run

```sh
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::test(filter = '^nongaussian-mu-random-slopes$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^(student-location-scale|lognormal-location-scale|gamma-location-scale|beta-location-scale|beta-binomial|truncated-nbinom2-location-scale|nongaussian-mu-random-slopes)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^(phase18-truncated-nbinom2-mu-random-intercept|truncated-nbinom2-location-scale|nongaussian-mu-random-slopes)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
git diff --check
Rscript --vanilla -e "pkgdown::check_pkgdown(); pkgdown::build_site(preview = FALSE)"
Rscript --vanilla -e "devtools::check()"
```

`devtools::document()` passed. Focused tests passed. The first full
`devtools::test()` run found one stale Phase 18 truncated-NB2 artifact
expectation that still treated `(0 + x | id)` as unsupported; after changing
that negative test to `(1 + x | id)`, the affected focused set and full
`devtools::test()` passed. `git diff --check` was clean.
`pkgdown::check_pkgdown()` reported no problems, `pkgdown::build_site()` rendered
the updated site into `pkgdown-site/`, and the final `devtools::check()` passed
with 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

The new deterministic recovery test fits each promoted family with `(0 + x |
id)`, checks convergence and positive-definite Hessian status, confirms the
random-effect term is stored as a `mu` slope, verifies `sdpars$mu`, `ranef()`,
response-scale prediction consistency, direct `profile_targets()`, and
`check_drm()` diagnostics, and checks that recovered random effects are aligned
with the simulated latent slope effects. Existing family tests keep correlated,
labelled, `sigma`, shape, hurdle, and bounded-neighbour syntax rejected.

## Consistency Audit

Rose ran targeted stale-wording scans for old intercept-only wording, broad
random-slope rejections, and family-specific no-support claims across
`README.md`, `ROADMAP.md`, `NEWS.md`, `R`, `tests`, `docs`, `man`, and
`vignettes`, excluding historical after-task notes, check-log entries, and
recovery checkpoints where appropriate. The audit caught and fixed drift in the
formula grammar vignette, model map, implementation map, source map, proportion
tutorial, worked-example inventory, and known-limitations ledger. Remaining hits
are deliberate planned-neighbour language for correlated slopes, `sigma` or
shape random effects, structured effects, and inflation/hurdle paths.

## GitHub Issue Maintenance

Ada searched open issues for non-Gaussian random slopes, family-specific random
effects, and Phase 18 slope wording. Issue #128 matched this capacity-table
slice. Ada added
https://github.com/itchyshin/drmTMB/issues/128#issuecomment-4569804038 and kept
the issue open because correlated, scale, bivariate, and structured capacity
work remains.

## What Did Not Go Smoothly

The two remote scout agents disconnected during compaction, so Ada folded the
Team B slice back into the local branch. An early `air format .` touched
unrelated files and had to be unwound before validation. The first full test run
correctly exposed a stale negative test. The first issue-comment command used
shell backticks in a double-quoted body and failed; the successful command used
a quoted heredoc.

## Team Learning

For capability-table flips, Rose's status inventory must include pkgdown
vignettes, not just design Markdown and README/ROADMAP/NEWS. For GitHub issue
comments that contain R syntax, use `gh issue comment --body-file - <<'EOF'` so
formula backticks do not become shell command substitutions.

## Known Limitations

This is a source-tested first slice, not broad simulation admission. Correlated
non-Gaussian random slopes, labelled covariance blocks, non-Gaussian `sigma`
random effects beyond the ordinary NB2 intercept gate, Student-t `nu` random
effects, bounded-response exact-boundary random effects, zero-one beta random
effects, hurdle/inflation random effects, structured non-Gaussian effects, and
mixed or bivariate non-Gaussian families remain out of scope.

## Next Actions

Open the narrow PR from `codex/no-to-yes-wave1`, watch CI without auto-merge,
then start Team A's separate structured count branch for non-zero-inflated
Poisson/NB2 q1 `mu` structured intercepts.
