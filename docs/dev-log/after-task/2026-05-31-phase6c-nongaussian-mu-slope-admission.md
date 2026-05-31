# After Task: Phase 6c Non-Gaussian `mu` Slope Admission

## Goal

Close #441 by deciding which tested non-Gaussian independent `mu` slope paths
can move into registry-backed support before the larger #446 simulation plan.

## Implemented

This slice records a family-specific admission decision without changing
likelihood code. Ordinary Poisson and NB2 independent `mu` slopes are admitted
as `ready_grid` rows. Student-t, lognormal, Gamma, beta, beta-binomial, and
zero-truncated NB2 independent `mu` slopes are admitted as `ready_source_test`
rows: they have source tests for the fitted route but still need #446
slope-specific recovery, coverage, power, and reporting grids.

## Mathematical Contract

For each admitted route, the independent random slope enters the location
predictor:

```text
eta_mu_i = X_mu[i, ] beta_mu + b_group[i] * x_i
b_g ~ Normal(0, sd_slope^2)
```

The response distribution and link remain family-specific. This is not a
correlated intercept-slope block, not a labelled covariance block, not a
structured effect, and not a random effect in `sigma`, `nu`, `zi`, `hu`, `zoi`,
`coi`, or ordinal cutpoints.

## Files Changed

- `ROADMAP.md`
- `docs/design/79-supported-nongaussian-evidence-goal.md`
- `docs/design/147-phase6c-nongaussian-mu-slope-ademp.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-phase6c-nongaussian-mu-slope-admission.md`

No parser, likelihood, TMB, extractor, simulation-runner, formula-grammar,
NEWS, pkgdown navigation, or missing-data files changed.

## Checks Run

```sh
air format ROADMAP.md docs/design/79-supported-nongaussian-evidence-goal.md docs/design/147-phase6c-nongaussian-mu-slope-ademp.md docs/dev-log/after-task/2026-05-31-phase6c-nongaussian-mu-slope-admission.md docs/dev-log/check-log.md
Rscript --vanilla -e "devtools::test(filter = 'nongaussian-mu-random-slopes|poisson-mean|nbinom2-location-scale|phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "pkgdown::build_site(lazy = TRUE, preview = FALSE)"
rg -n 'Non-Gaussian `mu` Slope Admission|ready_grid|ready_source_test|Student-t, lognormal, Gamma, beta, beta-binomial, and zero-truncated NB2|#441|#446' ROADMAP.md docs/design/79-supported-nongaussian-evidence-goal.md docs/design/147-phase6c-nongaussian-mu-slope-ademp.md docs/dev-log/after-task/2026-05-31-phase6c-nongaussian-mu-slope-admission.md tests/testthat inst/sim pkgdown-site --glob '!pkgdown-site/search.json'
rg -n 'non-Gaussian.*(has|with|provides|supports|proves).*coverage claim|non-Gaussian.*(has|with|provides|supports|proves).*power claim|ready_source_test.*(has|with|provides|supports|proves).*coverage|ready_source_test.*(has|with|provides|supports|proves).*power|source-tested.*(has|with|provides|supports|proves).*coverage|source-tested.*(has|with|provides|supports|proves).*power|Tweedie random effects (are )?(fitted|implemented)|zero-one beta random effects (are )?(fitted|implemented)|ordinal random effects (are )?(fitted|implemented)|correlated .*non-Gaussian.*slopes (are )?(fitted|implemented)|structured non-Gaussian slopes (are )?(fitted|implemented)|Student-t `nu` random effects (are )?(fitted|implemented)' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes tests/testthat inst/sim pkgdown-site --glob '!docs/dev-log/after-task/**' --glob '!pkgdown-site/search.json'
rg -n 'beta\(|beta_binomial\(|student\(|lognormal\(|nbinom2\(|truncated_nbinom2\(|check_drm|profile_targets' pkgdown-site/reference/index.html
git diff --check
```

All commands passed. The first stale scan pattern was too broad and caught two
unrelated structured-readiness rows where `source-test cells` and fixed-effect
Wald `coverage` appeared in the same sentence. The final recorded stale scan
targets actual #441 overclaims instead.

## Tests Of The Tests

The focused non-Gaussian slope test fits Student-t, lognormal, Gamma, beta,
beta-binomial, and zero-truncated NB2 models with `(0 + x | id)`, then checks
convergence, `pdHess`, random-effect design values, `sdpars$mu`, `ranef()`,
response-scale prediction, `profile_targets()`, and `check_drm()`.

Existing Poisson and NB2 tests cover the stronger count route with fitting,
prediction, random-effect extraction, profile targets, and diagnostics; the
registry tests keep `ready_grid` and `ready_source_test` vocabulary synchronized
with the Phase 18 workflow rows.

## Consistency Audit

The new gate keeps three levels separate:

- `ready_grid` count `mu` slopes for ordinary Poisson and NB2;
- `ready_source_test` independent `mu` slopes for Student-t, lognormal, Gamma,
  beta, beta-binomial, and zero-truncated NB2;
- blocked or planned neighbours: correlated slopes, labels, structured
  slopes, non-Gaussian `sigma` and shape random effects, inflation/hurdle
  random effects, ordinal mixed models, zero-one beta random effects, and
  mixed-response bivariate models.

## GitHub Issue Maintenance

#441 is the direct issue for this gate. No new extractor or parser issue is
needed. #446 remains open for the formal slope-specific recovery, coverage,
power, convergence, and reporting plan, and #59 remains open for the broader
Phase 18 simulation programme.

## What Did Not Go Smoothly

Earlier branch-side notes for #441 lived on a broad branch that did not land on
main. This slice re-records the admission decision on a small branch and keeps
the claim level at source-test or grid-readiness instead of turning it into a
broad non-Gaussian random-effect claim.

## Team Learning

Fisher: source-test readiness is evidence of a fitted route, not evidence of
coverage or power. Curie: the family-specific test should keep prediction,
extractor, profile-target, and diagnostic checks together. Rose: admission
tables need explicit blocked neighbours so future simulations do not inherit
ambiguous claims.

## Known Limitations

This gate does not fit Tweedie random effects, zero-one beta random effects,
ordinal random effects, hurdle or zero-inflated random effects, non-Gaussian
`sigma` random effects outside the narrow NB2 intercept gate, Student-t `nu`
random effects, correlated slopes, labelled non-Gaussian covariance,
structured non-Gaussian slopes, or mixed-response bivariate models.

## Next Actions

Use #446 to design the first slope-specific recovery and coverage grids for the
`ready_source_test` families before teaching them as simulation-supported
surfaces.
