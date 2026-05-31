# After Task: Non-Gaussian Mu-Slope Registry Cleanup

## Goal

Fix documentation-only #441 drift in the family registry. The reader is an
applied ecology or evolution user checking whether a non-Gaussian model admits
ordinary `mu` random effects before deciding whether Phase 18 artifacts support
slope-specific inference.

## Implemented

`docs/design/02-family-registry.md` now gives the same conservative support
claim in the lower family sections as in the registry table. Student-t,
lognormal, Gamma, beta, beta-binomial, and zero-truncated NB2 support fixed
effects plus ordinary unlabelled `mu` random intercepts and source-tested
independent numeric `mu` slopes.

## Mathematical Contract

No likelihood or model-fitting code changed. The cleanup only synchronized prose
and one zero-truncated NB2 display equation so the documented `mu` linear
predictor can include independent ordinary random-effect terms:

```text
log(mu_i) = X_mu[i, ] beta_mu + Z_mu[i, ] b_mu
b_mu ~ Normal(0, diag(sd_mu^2)) for independent mu random-effect terms
```

The Phase 18 evidence boundary stayed conservative. Current artifact lanes for
Student-t, lognormal/Gamma, beta/beta-binomial, and zero-truncated NB2 are
random-intercept focused, not slope-specific recovery, coverage, or power
evidence.

## Files Changed

- `docs/design/02-family-registry.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-nongaussian-mu-slope-registry-cleanup.md`

## Checks Run

```sh
rg -n 'Student-t.*fixed-effect only|student\(\).*fixed-effect only|Student-t.*Random effects.*later|The first robust continuous family is univariate and fixed-effect only|beta-binomial.*fixed-effect only|beta_binomial\(\).*fixed-effect only|The implemented model is univariate and fixed-effect only|zero-truncated NB2.*fixed-effect|truncated_nbinom2\(\).*fixed-effect|The implemented model is fixed-effect and univariate' docs/design/02-family-registry.md
```

Result: no matches.

```sh
rg -n 'source-tested, while the current Phase 18 .*artifact lane is random-intercept focused|ordinary unlabelled `mu` random intercepts and independent numeric `mu` slopes|Correlated Student-t slopes|Correlated zero-truncated slopes|Correlated beta slopes|Correlated slopes' docs/design/02-family-registry.md
```

Result: found the updated source-tested `mu` slope wording and planned-neighbour
guardrails in the registry table and lower family sections.

```sh
git diff --check
```

Result: passed.

## Tests Of The Tests

No R tests were run because this was a documentation-only cleanup and no
executable examples changed. The relevant executable evidence remains the local
source-test reference already named in the registry table:
`tests/testthat/test-nongaussian-mu-random-slopes.R`.

## Consistency Audit

The registry now separates three claims for the six selected families:
fixed-effect likelihoods are fitted, ordinary unlabelled `mu` intercepts and
independent numeric `mu` slopes are source-tested, and current Phase 18 artifact
lanes are random-intercept focused. The cleanup did not broaden support to
correlated slopes, labelled covariance, non-Gaussian `sigma` random effects
outside the narrow ordinary NB2 intercept gate, shape random effects, structured
effects, hurdle/inflation random effects, known covariance, or bivariate and
mixed non-Gaussian families.

## GitHub Issue Maintenance

No GitHub issue action was taken. The user supplied #441 as the bounded issue
context, and the allowed write scope was limited to the registry, check log, and
one after-task report.

## What Did Not Go Smoothly

The stale wording was not limited to the three named examples. Lognormal,
Gamma, and beta also needed lower-section wording to keep the six-family
boundary stable.

## Team Learning

Rose should scan both the upper registry table and lower family narrative after
any support-status change. Curie should keep source-tested slope admission
separate from Phase 18 recovery and coverage language.

## Known Limitations

This report does not claim slope-specific operating-characteristic evidence.
The current Phase 18 artifact lanes remain random-intercept focused for the
families touched here.

## Next Actions

Use #441 or #446 to decide whether any of these independent `mu` slope paths
should receive a dedicated Phase 18 recovery, coverage, or power lane.
