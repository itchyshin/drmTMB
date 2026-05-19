# After Task: Slice 287 Ordinal Readiness

## Goal

Record the implementation and evidence status for the fitted ordinal surface
before broader simulation, mixed-model, or scale/discrimination claims.

## Implemented

The fixed-effect `cumulative_logit()` path now has an explicit `confint()`
test for the fitted ordinal location coefficient. The ordinal design note now
has a Slice 287 readiness ledger for likelihood and cutpoints, prediction and
summaries, intervals and targets, and unsupported neighbours. README, the
family registry, the distribution-family tutorial, and the pre-simulation
matrix now point to the same fitted-versus-planned ordinal boundary.

## Mathematical Contract

The likelihood is unchanged:

```text
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i)
mu_i = X_mu[i, ] beta_mu
theta_1 < theta_2 < ... < theta_{K-1}
```

The latent logistic scale remains fixed. `fitted()` returns the expected
ordered-category score, not a measured continuous response. `confint(fit)`
returns Wald intervals for fitted location coefficients on the latent `mu`
scale; internal ordered-cutpoint profile targets remain visible through
`profile_targets()`, but transformed cutpoint and category-probability
intervals are not a polished user-facing surface yet.

## Files Changed

- `tests/testthat/test-cumulative-logit.R`
- `docs/design/25-ordinal-scale-discrimination.md`
- `docs/design/02-family-registry.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `vignettes/distribution-families.Rmd`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-214435-codex-checkpoint.md`

## Checks Run

```sh
air format tests/testthat/test-cumulative-logit.R docs/design/25-ordinal-scale-discrimination.md docs/design/02-family-registry.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/distribution-families.Rmd README.md NEWS.md ROADMAP.md
Rscript -e "devtools::test(filter = 'cumulative-logit|profile-targets|summary|reference-grid-link-scale-contract|nongaussian-structured-boundary', reporter = 'summary')"
Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/distribution-families.Rmd", output_dir = tempfile("distribution-families-render-"), quiet = FALSE)'
rg -n 'Slice 287|ordinal readiness|cumulative_logit\(\)|fixed-effect Wald|internal cutpoint|ordinal random effects|scale/discrimination|expected ordered-category|confint\(fit\)|fixef:mu:x' NEWS.md ROADMAP.md README.md docs/design/02-family-registry.md docs/design/25-ordinal-scale-discrimination.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/distribution-families.Rmd tests/testthat/test-cumulative-logit.R
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
Rscript tools/codex-checkpoint.R --goal "Slice 287 ordinal readiness" --next "stage, commit, push, and open draft PR"
```

All commands passed.

## Tests Of The Tests

The new assertion would fail if `confint()` stopped exposing the fitted ordinal
location coefficient as `fixef:mu:x`, mapped it to a non-`beta_mu` parameter,
or returned a non-Wald status. Existing ordinal tests already cover independent
category-probability likelihoods, ordered cutpoints, weighted likelihoods,
prediction, expected scores, residuals, simulation, malformed responses,
missing categories, `sigma ~`, `sd(group) ~`, `meta_known_V(V = V)`, bivariate
syntax, and ordinal random-effect boundaries.

## Consistency Audit

The roadmap now marks Slice 287 done locally. The readiness matrix admits only
fixed-effect ordinal likelihoods as small-grid candidates and excludes ordinal
mixed-model grids. The distribution-family tutorial tells users that location
coefficient intervals are Wald intervals on the latent scale and that internal
cutpoint profile targets are not yet polished response-scale intervals.

## What Did Not Go Smoothly

No implementation issue emerged. The main audit work was avoiding overclaim:
ordinal cutpoint internals are profile-target rows, but they are not yet a
reader-facing transformed interval story.

## Team Learning

Ada kept the slice to evidence and status alignment. Boole checked that the
formula boundary still says location-only. Fisher and Curie tied ordinal
simulation admission to likelihood, prediction, interval, and malformed-input
evidence. Pat kept expected-score wording from sounding like a continuous
measurement. Grace confirmed pkgdown and the targeted test run. Rose kept
ordinal random effects, scale/discrimination, bivariate ordinal, and
mixed-response ordinal models out of fitted claims. No spawned subagents were
used.

## Known Limitations

No ordinal random effect, ordinal random slope, ordinal `sigma` scale model,
direct discrimination formula, structured ordinal path, bivariate ordinal
model, mixed-response ordinal model, transformed cutpoint interval, or
category-probability interval was added.

## Next Actions

Continue with Slice 288 by auditing bivariate mixed-family status without
leaving the one-response/two-response scope or treating mixed composed
families as fitted before likelihood, prediction, intervals, examples, and
tests exist.
