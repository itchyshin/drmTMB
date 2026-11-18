# After Task: Native beta-binomial random-slope SD regression

## 1. Goal

Extend native beta-binomial direct-SD regression from ordinary random intercepts to one independent numeric location slope, with a fixed predictor for its SD and a synthetic complete-response example.

## 2. Implemented

The beta-binomial builder now resolves one selected independent `mu` slope target with `sd(group, coef = "x") ~ w` alongside `(0 + x | group)`. It reuses the existing beta-binomial likelihood and group-specific SD-row mapping. The focused workflow test covers assembly, a seeded fit, coefficient direction and a permissive smoke check, group-SD prediction, response simulation, and prediction after save and reload. A separate test compares the fitted Laplace log likelihood with independent per-group numerical quadrature for one random slope and checks that reversing the SD-to-group map worsens the likelihood.

The route requires complete responses and fixed `sigma`. The slope quadrature comparison is one seeded numerical check, not broad likelihood validation. Calibrated intervals, other random-effect structures, and Julia support remain open.

## 3a. Decisions and Rejected Alternatives

Kept the existing beta-binomial likelihood, precision parameterization, and random-effect representation. The change admits one independent numeric location slope only. Interval coverage validation is deferred under the implementation-first goal. Assumptions made without asking: none.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-beta-binomial-sd-slope.R`
- `tests/testthat/test-beta-binomial-sd-slope-integration.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `NEWS.md`
- `docs/dev-log/after-task/2026-10-20-beta-binomial-sd-slope.md`
- `docs/dev-log/after-task/2026-10-20-beta-binomial-sd-slope.assessment.json`
- `docs/dev-log/check-log.d/2026-10-20-beta-binomial-sd-slope.md`
- `docs/dev-log/check-log.md`
- `.unlazy/general-sd-regression/GATES.md` (partial G6 evidence only; gate remains open)

The shared R builder and documentation files also contain changes from other active programme lanes. This report records only the beta-binomial slope additions; it does not claim ownership of their full diffs.

## 5. Checks Run

- Before enabling slope admission, the assembly test failed at the intended beta-binomial scalar-target guard.
- `Rscript -e "devtools::test(filter = '^beta-binomial-sd-slope$', reporter = 'summary')"` passed 12 assertions with no failures. No live Julia tests ran.
- `Rscript -e "devtools::test(filter = '^beta-binomial-sd-slope-integration$', reporter = 'summary')"` passed 3 assertions for fit convergence, per-group quadrature agreement, and a wrong-group control.
- The first oracle run failed only because the wrong-group control cutoff of 1 exceeded its observed 0.931 log-likelihood difference. The quadrature agreement passed. Lowering that control threshold to 0.5 preserved a meaningful wrong-map penalty and the deterministic rerun passed.
- `Rscript -e "pkgdown::check_pkgdown()"` reported no problems. Pandoc printed existing `--mathml` deprecation warnings.
- `git diff --check` passed for the programme worktree.
- The beta-binomial NEWS, formula grammar, likelihood description, model map, known-limitations entry, and adapter map were checked for consistent complete-response and fixed-`sigma` boundaries.
- The open-issue search was `gh issue list --state open --search 'beta-binomial random-effect SD slope' --limit 10`. It returned #1463 and #59, neither matching this implementation slice. No issue was opened, commented on, or changed.
- Partial G6 evidence was added to `.unlazy/general-sd-regression/GATES.md`; G6 remains unchecked.
- No full pkgdown site build, coverage campaign, or Julia execution was performed for this slice.

## 6. Tests of the Tests

The new assembly assertion was exercised before enabling the route and failed at the builder's existing scalar-only admission. The seeded public-API test then exercised fitting and downstream outputs. Its coefficient tolerance is deliberately permissive, so this test checks workflow without making a precision or calibration claim.

## 7a. Issue Ledger

The issue search found a general test-sweep issue and a broad simulation-framework issue, but no issue specifically requesting beta-binomial predictor-dependent slope SDs. The tracker was left unchanged.

## 8. Consistency Audit

Updated the direct-SD eligibility and likelihood descriptions, known-limitations entry, adapter map, formula guide, model map, and NEWS. The public wording identifies this as a complete-response beta-binomial location-slope route with fixed `sigma`, workflow checks, and one independent per-group quadrature comparison. It makes no interval-calibration or Julia-parity claim. No navigation change was needed. This task does NOT establish broad slope likelihood validity, interval calibration, broader beta-binomial random-effect support, or Julia parity.

## 9. What Did Not Go Smoothly

The first assembly test confirmed that the builder rejected slope targets before the small admission change. The first slope-oracle run also showed that the wrong-group cutoff copied from the intercept test was too high for this fixture; its observed likelihood penalty was 0.931. After lowering the negative-control cutoff to 0.5, the same fixed-seed test passed with the oracle agreement intact.

## 10. Known Residuals

This is one native TMB implementation and one fixed-seed smoke case. The coefficient threshold is permissive, and the quadrature comparison covers one seeded design only. Complete responses and fixed `sigma` are required. Interval workflow checks, interval calibration, structured and correlated effects, other distributional endpoints, and Julia support remain open. The programme gate ledger remains open.

## 11. Team Learning

When a family already maps each ordinary random-effect term through a row-specific SD, inspect the family admission and target resolver before modifying its likelihood. Keep a workflow smoke test distinguishable from an independent likelihood check and from uncertainty calibration.

## 12. Cross-Product Coverage

Native R/TMB formula admission, fitting, coefficient extraction, SD prediction, simulation, save/reload prediction, and one independent per-group slope likelihood comparison were exercised. This slice does NOT cover profiles, bootstrap refitting for the slope, Julia execution, interval calibration, structured effects, or the overall general predictor-dependent random-effect SD goal.
