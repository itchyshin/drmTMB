# After Task: Native Gamma sigma random-slope SD

## 1. Goal

Add one native Gamma route where a fixed group-level predictor changes the
standard deviation of an independent random slope on the `sigma` predictor.
It adds one bounded case to the broader predictor-dependent random-effect SD
programme. Interval-coverage calibration is deferred by the current plan.

## 2. Implemented

The native builder admits one independent numeric random slope on Gamma
`sigma` when the coefficient has a matching formula such as
`sd(id, dpar = "sigma", coef = "x") ~ w`. It requires complete responses,
fixed-effect-only `mu`, and an SD predictor `w` that is constant within `id`.
The existing `sigma` random-effect contribution is retained in the fitted
link and reported `sigma` output. The test also checks that the matching SD
formula is required.

## 3. Mathematical Contract

For observation `i` in group `g`, the fitted scale predictor is
`eta_sigma,ig = X_sigma,ig gamma + x_ig u_g`, where
`u_g ~ Normal(0, tau_g^2)` and `log(tau_g) = W_g alpha`. Gamma `sigma` is the
coefficient of variation, so this effect changes variation in the log-CV
predictor. The Gamma likelihood and residual-parameter set are unchanged.
`W_g` contains fixed-effect terms only and must be constant
within the target group.

## 3a. Decisions and Rejected Alternatives

The builder reuses the existing scalar SD-target machinery and Gamma
`sigma` random-effect contribution. This admits only one independent numeric
slope paired with its selected SD formula and keeps the existing formula
grammar and covariance parameterization. The implementation needed no C++
likelihood change. Correlated and structured `sigma` effects stay outside
this slice.

## 4. Files Touched

- `R/drmTMB.R` and `tests/testthat/test-gamma-sigma-sd-regression.R`
- `docs/design/01-formula-grammar.md` and
  `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md` and
  `docs/dev-log/internal-roadmap.md`
- `vignettes/formula-grammar.Rmd`, `NEWS.md`, and `docs/dev-log/check-log.md`
- This report and `docs/dev-log/check-log.d/2026-10-25-gamma-sigma-slope-sd.md`

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "gamma-sigma-sd-regression", reporter = "summary", stop_on_failure = TRUE)'`: 22 expectations passed in about 15 seconds; no failures, warnings, or skips. The configured filter ran no live Julia bridge tests.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems. Existing Pandoc `--mathml` deprecation warnings were printed.
- `git diff --check` on the leased slice: passed.
- The rendered formula vignette, full package test suite, and `R CMD check` were not run.

## 6. Tests of the Tests

The test-first run failed before implementation at the Gamma builder's
intercept-only `sigma` restriction. The synthetic test checks recovery of the
SD-regression coefficient and group SDs, selected-target output, the identity
between the fitted `sigma` link and fixed plus random contributions, and
save/reload. Negative cases check a varying-within-group predictor and the
missing matching SD formula. The constant-SD equivalence check in this file
covers the pre-existing random-intercept route; it does not establish
constant-SD equivalence for the new slope route.

## 7a. Issue Ledger

The prior focused search identified no issue for this exact Gamma
`sigma`-slope direct-SD route. Issue #1551 tracks adjacent Julia Gamma
ordinary-mean bridge work. No issue was opened, edited, or closed.

## 8. Consistency Audit

The native implementation, formula example, design map, limitations, roadmap,
NEWS entry, and check log describe the same narrow admission and fixed-`mu` /
complete-data boundaries. The exact stale-wording search was:

```sh
rg -n -i --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/check-log.d/**' \
  'gamma.{0,40}sigma.{0,25}slope|sigma.{0,40}gamma.{0,25}slope|gamma sigma slopes|sigma slopes.*unsupported|sigma slopes.*remain outside' \
  README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md \
  docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md \
  vignettes R man
```

The remaining hits are affirmative or scoped descriptions in NEWS, the design
pages, and the roadmap. README had no matching statement. The row in
`docs/design/01-formula-grammar.md` now names the admitted Gamma/LogNormal/NB2
independent `sigma`-slope family while retaining other forms as later work.
The vignette row makes the new Gamma boundary and evidence level explicit.

## 9. What Did Not Go Smoothly

The first repository route lookup used the parent checkout and found no
worktree-specific LOAD-FIRST manifest. The `graft` command was also absent
from this shell. I used the repository's scoped lease and exact file searches
to continue; no unleased edits were made. The candidate contains many other
lanes' changes, so full-file diff volume is not attributable to this slice.

## 11. Team Learning

In a shared candidate checkout, treat a path lease as the edit boundary and
review targeted file hunks rather than interpreting full-file diff size as
one lane's contribution. If the configured source-graph command is unavailable,
record that and use narrow indexed alternatives before expanding source reads.

## 10. Known Residuals

This is one native TMB point-recovery/output slice. It does NOT cover Julia
parity, interval calibration, profile/bootstrap refit routing for this slope
target, constant-SD equivalence for the slope form, missing-response support,
or correlated/labelled Gamma `sigma` effects. No family-wide or programme-wide
gate is closed by this report.

## 12. Cross-Product Coverage

This slice covers only the native TMB ordinary independent numeric Gamma
`sigma` slope with a matching fixed-predictor SD formula, point recovery,
group-SD prediction, fitted-sigma output identity, and save/reload. It does NOT cover Julia
parity, interval calibration, profile/bootstrap refit routing for
this slope target, constant-SD equivalence for the slope form, missing-response
support, correlated or labelled Gamma `sigma` effects, or the other required
family/effect/provider/backend rows. Continue with the next highest-priority
unimplemented cell after checking its code path, required row, and lease.
Uncertainty calibration remains separate follow-up work.
