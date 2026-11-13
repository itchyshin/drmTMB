# Two targeted random-intercept SD priors: work in progress

## Goal and mathematical contract

Allow an applied user to regularize the SD for `site`, `observer`, or both in a Gaussian mean model with `(1 | site) + (1 | observer)`. Each selected SD receives a normalized Gamma(shape, rate) penalty once on the natural SD scale. The optimizer uses a log SD without an added Jacobian. This gives a penalized-ML estimate, not posterior samples.

## Implemented and files changed

At R commit `2a84bc0bbb4d2b81c14280e53efaa09fde620e16`, the prior resolver and fit workflow select targets by group and retain the objective components. `R/julia-bridge.R` supplies and validates the v3 target contract. Focused tests and frozen numerical fixtures are under `tests/testthat/`; help pages document the route and refusals. The paired Julia source is `4cf237b9e98d2314016447bc47a32b803e07ada7`.

The route admits two distinct unlabelled independent mean random intercepts for complete-data, unit-weight Gaussian ML fits. Fixed priors can be combined with one or two SD priors. It rejects unsupported or ambiguous targets and identical grouping partitions. Users needing slopes, structured effects, correlation priors, another family or REML must use an unpenalized fit until a supported prior route is available. Prior-fit interval and likelihood-comparison guards remain in place.

## Checks and tests of the tests

The independent dense-Gaussian oracle and review cover 150 interior points, 20 fitted cases, exact zero-SD likelihood limits and seven deliberately incorrect objective variants. Fixed-point checks include all gradient and Hessian components. The frozen fixtures are committed with their provenance. An independent R review reran `testthat::test_local()` with the `^two-ri-sd-priors$` filter and live Julia enabled at the paired commits; it passed with one live bridge test and no skips. The paired v2 contract and duplicate suites passed seven live tests without skips. See `docs/dev-log/check-log.d/2026-11-13-two-ri-sd-priors.md` for the command and its scope.

## Consistency, documentation and issues

The roxygen help and generated reference pages describe the selected group and supported route. No formula grammar or likelihood measure was changed; no design document or pkgdown navigation was edited. A task-specific search used `rg -n -i 'one (independent|unlabelled|ordinary)? ?random.intercept|exactly one.*random.intercept|random.effect SD priors|SD prior' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml R/fixed-effect-priors.R`. The `NEWS.md` fixed-prior entry records the earlier slice and says SD priors were outside that slice; it is historical, not a claim about this change. A complete status and generated-site audit remains open.

An open-issue search for `prior random SD in:title,body` returned tracker #1464. This work did not comment on, close or create an issue. Draft PR #1736 contains the R branch; no merge or release was authorized.

## What did not go smoothly and what remains

The first live v3 bridge smoke failed because JuliaCall returned a typed vector of dictionaries as an opaque object in R. A minimal conversion probe identified the boundary; the revised response and live tests passed. An independent review also found missing mixed-prior bridge coverage and implicit convergence reporting; both now have focused tests. Recording these boundaries made the test gaps visible before the full checks.

Four full R repository shards passed on Totoro against `c489e08cdf324073fe5bdbf5a8d07ffa13e8a6ef`, after fixes to the skip census and an obsolete refusal expectation. Each exited zero with one spelling-output NOTE. The four shards recorded 117 warnings and 708 skips in total; live Julia was covered separately, not by these shards. The initial `f90a7453` full run retained three failures in shard 2.

The hosted R checks on `f90a7453` stopped before package tests because the C17/C14 receipt pins an earlier `R/drmTMB.R` blob. Two isolated 12-fit reruns on `c489e08c` passed their fit checks and reproduced the historical summaries exactly. The protected receipt and manifest remain unchanged, so the hosted receipt gate remains unresolved. Coverage jobs were running at the last recorded check.

Julia's full suite, CI checks, final integrated-source reconciliation, and the complete claim-versus-evidence audit remain open. No calibrated interval coverage, general random-effect support or release readiness is claimed.
