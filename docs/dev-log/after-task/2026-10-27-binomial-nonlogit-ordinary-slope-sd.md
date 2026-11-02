# After Task: Binomial non-logit ordinary random-slope SD

## 1. Goal

Verify and record predictor-dependent SD support for ordinary Binomial random slopes under probit and complementary-log-log links in native TMB and Julia.

## 2. Implemented

Added independent synthetic recovery tests for the ordinary random-slope route in both engines. Julia also checks the matching ordinary random-intercept route. The generated capability universe now admits Julia's non-logit ordinary intercept and slope rows as a narrowly scoped exception to the family-level blocked-link status.

## 3a. Decisions and Rejected Alternatives

The SD formula models the log SD of the random coefficient. The row-level contribution remains `x b_g`; each SD predictor is constant within its group. The ledger exception is limited to Julia Binomial `iid_intercept` and `iid_numeric_slope` rows for probit and cloglog.

## 4. Files Touched

- `tests/testthat/test-binomial-nonlogit-ordinary-slope-sd.R`
- `../general-sd-julia/test/test_binomial_nonlogit_ordinary_slope_sd.jl`
- `tools/general-sd-regression/universe.py`
- `tools/general-sd-regression/tests/test_universe.py`
- `docs/dev-log/general-sd-regression/required-rows.tsv`
- `docs/dev-log/general-sd-regression/required-universe.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/after-task/2026-10-27-binomial-nonlogit-ordinary-slope-sd.md`

## 5. Checks Run

- Julia 1.10.12, one thread: `test/test_binomial_nonlogit_ordinary_slope_sd.jl` passed 32/32 checks for ordinary intercept and slope fits under probit and cloglog.
- `NOT_CRAN=true Rscript -e 'devtools::test(filter = "binomial-nonlogit-ordinary-slope-sd", reporter = "summary", stop_on_failure = TRUE)'`: both native fits passed, with 14 expectations.
- `python3 tools/general-sd-regression/universe.py` regenerated the 19,230-row denominator; `python3 -m unittest discover -s tools/general-sd-regression/tests -p 'test_universe.py'` passed 19 tests.
- Scoped whitespace checks passed for the changed tracked files. The new Julia test has no trailing whitespace.

## 6. Tests of the Tests

Each DGP used the response probability implied by its fitted link. The tests check convergence, fitted link identity, direction and broad magnitude of the SD slope, predictor-to-group SD output, and binary marginal simulation. They do not estimate interval coverage.

## 7a. Issue Ledger

No issue was opened, changed, or closed.

## 8. Consistency Audit

The Julia direct route and native TMB route are covered separately. The tests do not establish same-data cross-engine likelihood parity. The Julia universe exception only covers the two tested ordinary effect forms. Other non-logit structured and crossed routes retain their prior statuses.

## 9. What Did Not Go Smoothly

The first Julia run found that the test used the wrong output key. The public SD output uses the fitted target block name, so the test now selects that block explicitly. No product-code change was needed.

## 10. Known Residuals

This is point-recovery evidence for Binomial ordinary intercepts and independent slopes under probit and cloglog. It does not calibrate uncertainty, validate difficult information regimes, establish broad cross-engine parity, or finish the remaining family and structured-effect universe. Full package checks and a rendered Julia documentation build were not run.

## 11. Team Learning

For Julia models with a uniquely identified SD target, recovery tests should use the target block returned by the fitted object when reading `predict_parameters()`; do not assume the legacy `:sd` key exists.

## 12. Cross-Product Coverage

- Covers native TMB ordinary Binomial numeric-slope SD recovery for probit and cloglog.
- Covers Julia ordinary Binomial intercept and numeric-slope SD recovery for probit and cloglog.
- Does NOT cover interval calibration, same-data native/Julia parity for these rows, or other structured non-logit effects.

## Next Actions

Continue with the next Bernoulli capability row after checking its test coverage and lane ownership. Keep interval coverage deferred and the general SD goal active.
