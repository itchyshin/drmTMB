# After Task: Julia Binomial Probit and Cloglog SD Intercept Bridge

**Status update:** this report records the initial intercept-only bridge slice. The later one-slope extension is documented in [the follow-up report](2026-10-24-julia-binomial-nonlogit-slope-sd-bridge.md); that report supersedes the capability boundary below while preserving this slice's original test evidence.

## 1. Goal

Extend the Julia bridge for predictor-dependent random-effect SDs to Binomial probit and complementary log-log links, using an independent synthetic recovery example and a deliberately narrow admission rule.

## 2. Implemented

The R bridge now emits link-specific family tags for Binomial probit and complementary log-log. DRM.jl maps those tags to the matching Binomial links. The bridge admits the non-logit route only for one ordinary mean random intercept and one matching `sd(group)` formula. Other probit/cloglog random-effect shapes remain refused. The Julia guide, formula grammar table, development NEWS, and capability inventory describe this boundary.

## 3a. Decisions and Rejected Alternatives

I kept the bridge exception limited to the shape tested here. This preserves fail-closed behavior for slopes, structured effects, multiple random terms, and unmatched SD targets. The implementation does not open fixed-only or general non-logit Binomial bridge routes.

## 3b. Mathematical Contract

For group `g`, the latent intercept SD is `exp(alpha_0 + alpha_1 * w_g)` on the probit or complementary log-log link scale. The Bernoulli response has no free residual `sigma`. The fixture generates this SD trend independently for each link and compares its point recovery and group-SD predictions across native TMB and DRM.jl. TMB uses Laplace integration and DRM.jl uses adaptive quadrature, so exact likelihood equality is not required.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-binomial-sd-links-bridge.R`
- Paired DRM.jl `src/bridge.jl`
- Paired DRM.jl `test/test_binomial_bridge_links.jl`
- `NEWS.md`
- `vignettes/julia-engine.Rmd`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-nonlogit-sd-bridge-20261024/`

## 5. Checks Run

- The focused opt-in R filter exited 0 with 26 passing expectations: six R-side family/route checks and 20 expectations after Julia startup, including both link-specific TMB/Julia recovery and group-SD prediction comparisons. The saved console is `docs/dev-log/general-sd-regression/evidence/julia-binomial-nonlogit-sd-bridge-20261024/console.log`.
- The direct DRM.jl link-tag test passed 4/4 assertions.
- R parsing, scoped `git diff --check`, and `pkgdown::check_pkgdown()` passed. Pkgdown reported only existing `--mathml` deprecation warnings.
- The exact commands and SHA-256 source snapshot are recorded in the evidence folder manifest.
- The after-task structure validator passed, but it reports the general acceptance ledger as NOT RUNNABLE with gate state UNKNOWN. No programme gate is counted as passed.

## 6. Tests of the Tests

Before implementation, the R helper tests failed because the bridge rejected probit and the route-admission helper did not exist. The Julia unit test also rejected both new family tags. During the live run, the first test draft incorrectly passed TMB-only `se = FALSE` to Julia; Julia refused it as designed. The next run exposed unsupported `info` arguments to this repository's `expect_gt()` helper. Both test-harness issues were fixed without relaxing the model assertions. The passing live test includes wrong-group and structured-route negative controls.

The test runner prints a generic footer that says no live Julia tests ran, although the same captured log records Julia startup and the 20 post-startup assertions. The footer counter is not a valid live-test count for this filtered test; the test output and command exit status are the evidence used here.

## 7a. Issue Ledger

The read-only open-issue search for “Binomial probit cloglog SD Julia bridge” returned no matching issue. No issue was created, changed, or closed.

## 8. Consistency Audit

The R admission helper, link-specific bridge tags, DRM.jl family mapping, synthetic fixtures, and docs all describe one complete-response ordinary mean intercept with a matching fixed-predictor SD formula. The vignettes state that these links use different integration approximations across engines and do not claim calibrated uncertainty. A targeted stale-wording search found the prior broad “non-logit Julia bridge routes remain unavailable” statement in `vignettes/formula-grammar.Rmd`; it now names the narrow exception and keeps other non-logit shapes unavailable. Historical NEWS for version 0.7.0 remains unchanged and is superseded by the current development entry.

## 9. What Did Not Go Smoothly

The Julia test footer undercounted live tests, so the saved output needed interpretation alongside the actual startup and expectation stream. The first live runs also caught test-only control and assertion compatibility mistakes before the successful run.

## 10. Known Residuals

This adds no non-logit random slopes, structured or correlated effects, multiple random terms, or other non-logit Binomial bridge shapes. The recovery evidence uses two fixed seeds and is not a broad recovery grid. Confidence-interval workflows and coverage calibration were not tested. No general-SD programme gate closes.

## 11. Team Learning

For opt-in bridge tests, keep the runner's generic live-test counter separate from direct evidence that Julia started and assertions ran. Use only Julia-supported controls in bridge fixtures; do not share TMB-only options across engines.

## 12. Cross-Product Coverage

**Covers:** native R/TMB and paired DRM.jl for complete-response Binomial probit and complementary log-log models with one ordinary mean random intercept and one matching predictor-dependent SD formula; fixed-seed point recovery, group-SD ordering/agreement, route admission, and negative route controls.

**Does NOT cover:** general non-logit bridge parity, structured or correlated effects, random slopes, missing responses, calibrated intervals, or broad recovery. The full goal remains in progress.
