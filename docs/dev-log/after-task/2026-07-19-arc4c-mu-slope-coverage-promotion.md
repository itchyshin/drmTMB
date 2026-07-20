# After Task: Arc 4c ordinary `mu` random-slope coverage

## 1. Goal

Determine independently for skew-normal `mc-0464`, Tweedie `mc-0539`, and
zero-one beta `mc-0575` whether drmTMB's standard ML-Laplace profile interval
for `sd:mu:(0 + x | id)` supports `inference_ready_with_caveats`. This arc does
not add a family, estimator, formula grammar, or public function and does not
claim `supported` calibration.

## 2. Implemented

- Ran the frozen Fir preflight, twelve-cell smoke, mechanical M selection,
  1,320-task certification array, and independent `afterok` aggregation.
- Retained 13,200 attempted-replicate rows across eleven smoke-approved cells.
- Replayed one shared seed for every promoted M=16, 32, and 64 cell.
- Convened fresh memo-blind Fisher, Rose, and Noether D-43 reviews.
- Promoted `mc-0464`, `mc-0539`, and `mc-0575` independently to
  `inference_ready_with_caveats`, retaining `estimator=ML` and certified floor
  M=16.
- Repaired future Arc 4c point-estimate/Wald extraction through the unique
  `par.fixed` target and `cov.fixed`; immutable campaign values remain `NA`.
- Corrected stale family help and likelihood-design prose that still described
  all random effects as unsupported for these families.

## 3a. Decisions and Rejected Alternatives

The primary all-attempt profile gate, not conditional coverage, point bias, or
Wald coverage, determined promotion. Missing point-estimate/Wald diagnostics
were disclosed rather than backfilled from changed code. A rerun was rejected
because Fisher and Grace independently confirmed that the defect did not alter
any fit, profile endpoint, status, hit, denominator, exact interval, or verdict.

Noether withheld zero-one beta because rare beta-labelled values rounded to
exactly one and slightly increased fitted boundary mass. Fisher and Rose
promoted it. The frozen D-43 rule requires at least two WITHHOLD verdicts to
block, and the frozen family-diagnostic rule forbids changing the gate after
seeing results. Zero-one beta therefore promotes with that objection preserved
as a claim caveat and future strictly-interior-sampler gate.

## 4. Files Touched

- Evidence packet:
  `docs/dev-log/simulation-artifacts/2026-07-19-arc4c-mu-slope-coverage/`.
- Ledger sources and generated census/surface/family-map outputs under
  `docs/dev-log/dashboard/` and `vignettes/includes/`.
- Prospective extractor and regression test:
  `tools/run-arc4c-mu-slope-coverage.R` and
  `tests/testthat/test-arc4c-mu-slope-coverage-runner.R`.
- Corrected family documentation: `R/family.R`, the three generated `.Rd`
  files, current family/formula/likelihood design maps, README, ROADMAP, NEWS,
  known limitations, and six prose-only vignette status surfaces.
- Reconciliation, this report, check log, and closeout handoff.

## 5. Checks Run

- Fir preflight job 49628010: completed, exit 0.
- Smoke array 49628496 and selector 49629086: completed, exit 0.
- Full array 49629827: 1,320/1,320 tasks completed, exit 0.
- Full aggregator 49640984: completed, exit 0; 13,200 exact rows.
- Arc 4c focused tests: 245 expectations passed.
- Capability ledger write/check and unittest: 30 generated outputs consistent;
  37/37 tests passed.
- `devtools::document()`: regenerated only the three intended family help files.
- Full `devtools::test()` receipt: 39,466 passed, 0 failed, 0 errors, 62
  pre-existing warnings, and 24 skips across 1,958 contexts.
- `devtools::check(document=FALSE, manual=FALSE)`: 0 errors, 0 warnings, and
  the repository's one known report-only spelling transcript NOTE; tests and
  vignette rebuild completed.
- An isolated temporary-library install loaded this branch's drmTMB build;
  `pkgdown::check_pkgdown()` reported no problems. A subsequent isolated-library
  `pkgdown::build_site()` rendered all 33 articles, the home/roadmap/NEWS,
  formula/source/model/distribution maps, and all three family reference pages;
  its final problem check passed.
- Capability runtime: 18/18 verified routes and G0=G1=G2=0. Mission Control
  returned `mission_control_ok`; `git diff --check` passed.

## 8. Consistency Audit

The row ledger, evidence ledger, transitions, family census, family-map include,
Markdown surface, HTML surface, family help, and likelihood design note agree
that only the ordinary independent `mu` slope profile interval is promoted.
All three ledger rows retain `estimator=ML`. `_pkgdown.yml` and the PR #799
33-article learning path are unchanged. The dirty root worktree was never used
for edits.

## 6. Tests of the Tests

The existing Arc 4c contract tests deliberately exercise fit errors, bad
Hessians, nonfinite profiles, primary versus conditional denominators,
M=8-only exclusion, non-exploratory smoke failures, wrong cells/M values,
duplicate/missing/corrupt shards, deterministic resume, partitioning, and CLI
rejection. The new extractor regression gives `summary(fit$sdr)` duplicate
`log_sd_mu` report rows while providing one named fixed target and known
covariance; the old implementation returns `NA`, whereas the repaired
implementation recovers SD 0.50 and a covering Wald interval.

Nine live replays exercise the real fit/profile route, not a mock. Their profile
statuses match and the largest endpoint difference from Fir is `1.56e-10`.

## 9. What Did Not Go Smoothly

The first smoke attempt failed before fitting because the isolated R library
was exported after environment validation. Narrow PR #798 repaired all three
workers and added an ordering regression. The successful campaign used the
verified repair merge SHA.

The campaign then exposed the duplicate-report-row extractor defect and the
zero-one beta numerical endpoint leakage. Both were caught before ledger
mutation because the raw schema retained diagnostics and D-43 reviewers worked
from the immutable packet.

The first broad local test reporter detached before its final summary. The
process was allowed to finish without a duplicate concurrent run, then the
suite was rerun once with a compact structured pass/fail receipt.

## 11. Team Learning

Optional diagnostics need the same test realism as primary gates: a synthetic
one-row `summary()` mock did not reproduce TMB's duplicate report names. Future
coverage runners should extract named fixed parameters from `par.fixed` and
`cov.fixed`, and contract tests should mimic duplicated report surfaces.

Family-specific diagnostics also justified their cost. Zero-one beta's
`invalid_interior` columns exposed a small executed-DGP deviation that coverage
alone would not show. The next design should use a deterministic
strictly-interior sampler before compute, without rewriting this result.

## 12. Cross-Product Coverage

`docs/design/03-likelihoods.md` now matches the engine: skew-normal, Tweedie,
and zero-one beta admit ordinary unlabelled `mu` random intercepts or one
independent numeric slope, while correlated/labelled, scale-side, shape-side,
and structured random effects remain unsupported. Roxygen regenerated
`man/skew_normal.Rd`, `man/tweedie.Rd`, and `man/zero_one_beta.Rd`.

Prose-only status rows changed in `vignettes/formula-grammar.Rmd`,
`vignettes/source-map.Rmd`, `vignettes/model-map.Rmd`,
`vignettes/implementation-map.Rmd`, `vignettes/drmTMB.Rmd`, and
`vignettes/distribution-families.Rmd`; no R chunk changed. Article order,
navbar, and `_pkgdown.yml` are unchanged, so the reader taxonomy merged in PR
#799 remains the base for this branch. An isolated-library full site build and
rendered stale-text scan confirmed the new Arc 4c and mc-0227 tiers on the
reader pages.

Across product surfaces, this arc covers the R/TMB engine's ordinary
unlabelled `mu` slope under ML-Laplace, the retained-attempt aggregator, profile
intervals, capability ledger and generated family surfaces, family help, and
likelihood design prose for exactly the three named cells. It does NOT cover
the Julia engine, REML or Cox-Reid providers, AGHQ/O3, penalties or MAP,
missing-response combinations, structured/labelled/correlated random effects,
scale/shape random effects, or any other family or ledger cell.

## 7a. Issue Ledger

No open issue exactly represented this three-cell certification campaign.
Related broader issues remain broader than this narrow evidence slice, so the
arc does not close or repurpose them. PR A #797 and repair PR #798 are merged;
PR B carries evidence, promotion, documentation alignment, and closeout.

## 10. Known Residuals

The certified domain is true slope SD 0.50, the frozen family-specific DGPs,
and M>=16. It excludes other SDs, observation counts, group grids, fixtures,
families, random intercepts, correlated or labelled slopes, scale-side random
effects, structured effects, REML, AGHQ/O3, and `supported` claims.

Campaign point bias and Wald coverage are unknown. Skew-normal retains slant
identification risk; Tweedie retains small-M zero-boundary profiles; zero-one
beta needs a separately approved strictly-interior-generator rerun before an
exact observed-boundary claim. Full shards/logs stay on Fir `/project`; bounded
aggregate receipts are tracked in the repository and never uploaded through
GitHub Actions.
