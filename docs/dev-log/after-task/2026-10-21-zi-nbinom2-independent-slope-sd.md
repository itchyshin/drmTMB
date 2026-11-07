# After Task: Native ZI-NB2 independent-slope SD regression

## 1. Goal

Admit predictor-dependent SD regression for one ordinary independent numeric
location slope in complete-response zero-inflated NB2 models, with a seeded
recovery test, an independent likelihood check, and aligned support notes.

## 2. Implemented

The native NB2 builder now allows one unlabelled independent `mu` slope when a
zero-inflation formula is present and responses are complete. The selected SD
formula can use `sd(id, coef = "x") ~ w`. The slice keeps `sigma` and `zi` at
fixed intercepts and leaves correlated or structured effects outside support.

## 3a. Decisions and Rejected Alternatives

For group `g`, the selected random slope is `b_g ~ Normal(0, tau_g^2)` with
`log(tau_g) = W_g alpha`; its contribution to the log-mean predictor is
`x_ig b_g`. The recovery test uses fixed-intercept `sigma` and `zi` formulas;
this slice adds no random effect on those endpoints. The independent Laplace
check integrates one scalar group effect with slope loading `x_ig`. No coverage
claim is made.

## 4. Files Touched

`R/drmTMB.R`; `tests/testthat/test-zi-nbinom2-sd-regression.R`;
`tests/testthat/test-zi-nbinom2.R`; `NEWS.md`;
`docs/dev-log/known-limitations.md`; `docs/dev-log/internal-roadmap.md`;
`docs/design/01-formula-grammar.md`; `docs/design/02-family-registry.md`;
`docs/design/06-distribution-roadmap.md`;
`docs/design/34-validation-debt-register.md`;
`docs/design/59-structural-slope-and-non-gaussian-map.md`;
`vignettes/formula-grammar.Rmd`; this report and its assessment;
`docs/dev-log/check-log.d/2026-10-21-zi-nbinom2-independent-slope-sd.md`.

## 5. Checks Run

`devtools::test(filter = "zi-nbinom2")` passed 105 expectations with 0 failures,
2 existing log-sigma clamp warnings, and 0 skips in 29.3 seconds.
`devtools::test(filter = "zi-")` passed 234 expectations with 0 failures,
2 existing log-sigma clamp warnings, and 1 skipped live Julia test because no
Julia engine path was configured. The focused slope test includes synthetic
recovery, group-SD prediction, and the independent Laplace calculation.

The formula-grammar vignette rendered. Pandoc reported its existing deprecated
`--mathjax` option. `pkgdown::check_pkgdown()` reported no problems; it emitted
existing `--mathml` deprecation warnings. The scoped `git diff --check` passed.
A whole-worktree `git diff --check` still reports a pre-existing trailing blank
line in `tests/testthat/test-binomial-sd-integration.R`, outside this slice.

## 6. Tests of the Tests

Before the validator change, the new assembly test failed at the intercept-only
ZI-NB2 guard. The first post-change run exposed two incorrect expectations about
how parsed formula labels are stored; those assertions were corrected to match
the actual parsed metadata. A wider run then found an old test that still
expected independent ZI-NB2 slopes to be rejected. After updating that obsolete
assertion to check assembly of the selected-slope SD formula, both ZI-NB2 tests
and the broader `zi-` filter passed. A correlated slope rejection remains tested.

## 7a. Issue Ledger

The open-issue search for `sd random-effect standard deviation predictor
zero-inflated NB2 independent slope` in `itchyshin/drmTMB` returned no matching
open issue. No issue was opened, edited, or closed.

## 8. Consistency Audit

NEWS, the formula grammar, family registry, family roadmap, validation-debt
register, structural-slope map, known limitations, and formula-grammar vignette
now identify the native independent-slope route and its point-recovery boundary.
The status scan used this exact command:

`rg -n -i 'zero-inflated NB2 random slopes|zero-inflated route remains intercept-only|Random slopes, structured effects, other random-effect targets|random effects beyond the exact.*spatial.*diagnostic' README.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/06-distribution-roadmap.md docs/design/34-validation-debt-register.md docs/design/59-structural-slope-and-non-gaussian-map.md vignettes/formula-grammar.Rmd NEWS.md`

The remaining hits refer to correlated or structured routes beyond the new
narrow direct-SD gate. README content and pkgdown navigation needed no change.

## 9. What Did Not Go Smoothly

The broader test run correctly caught a stale negative test after the route was
admitted. The file preflight showed three remote refs with changes; I read the
ZI-hurdle branch diff before editing and retained its distinct ZI-side random
term check. The shared ownership registry did not return a grant for this
additional test path, so no commit or integration was attempted.

## 10. Known Residuals

This is native TMB point-recovery evidence for one ordinary independent slope
with complete responses and a numeric SD predictor constant within group. The
recovery test uses `sigma ~ 1` and `zi ~ 1`. It does not establish calibrated
intervals, Julia support, same-data engine parity, correlated blocks, structured
effects, missing-response support, or other combinations of random-effect
targets. Two existing tests warn that the fitted log-sigma clamp is active. The
broader programme remains open.

## 11. Team Learning

When broadening a family guard, search adjacent tests for negative assertions
that encoded the old boundary, then rerun the family filter rather than only
the new file. Keep exact warnings and skipped-engine evidence in the report.

Naturalness assessment: 2/10, medium confidence. Genre and coverage: the whole
12-section technical after-task report. Example: the opening of section 5 gives
the exact test result before describing documentation checks, helping readers
separate code evidence from documentation evidence. No prose repair was needed.
Science gate: pass, because the equation matches the implemented slope loading
and independent likelihood check. Factual gate: pass, because the support
boundary and outcomes were checked against source and captured test output.
References gate: not applicable because the report makes no literature claims.

## 12. Cross-Product Coverage

Only the native R/TMB zero-inflated NB2 route was changed and tested. The broad
filter skipped one live Julia test because its engine was unavailable. This
slice does NOT cover Julia implementation or parity, interval calibration,
correlated or structured random effects, random effects on `sigma` or `zi`, or
missing responses. It does not close the general predictor-dependent random-
effect SD programme.
