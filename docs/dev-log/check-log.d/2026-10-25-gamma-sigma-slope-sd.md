# 2026-10-25: Native Gamma sigma random-slope SD regression

## Implementation

The native Gamma builder now admits one complete-data independent numeric
random slope on `sigma` when it has a matching coefficient-selected SD formula,
for example `sd(id, dpar = "sigma", coef = "x") ~ w`. `mu` must be
fixed-effect-only, and `w` must be constant within `id`. The slope is a latent
effect on the log-CV predictor; its SD follows `log(tau_g) = W_g alpha`.

## Validation

- Test-first failure: before the adapter change, the new sigma-slope test hit
  the Gamma builder's existing intercept-only restriction.
- Focused recheck:
  `Rscript -e 'devtools::test(filter = "gamma-sigma-sd-regression", reporter = "summary", stop_on_failure = TRUE)'`
  passed 22 expectations in about 15 seconds, with no failures, warnings, or
  skips. It covers recovery, coefficient selection, group-SD prediction,
  fitted-sigma link/output identity, save/reload, and refusal without the
  matching SD formula.
- `pkgdown::check_pkgdown()` passed with no problems; it emitted the existing
  Pandoc `--mathml` deprecation warnings.
- Scoped `git diff --check` passed after the documentation updates.
- No Julia fit was attempted. The focused filter reported that zero live Julia
  bridge tests ran in this configuration.

## Documentation and Scope

Updated the Gamma `sigma` row in the formula-grammar vignette and clarified the
shared formula-design map: Gamma, LogNormal, and ordinary NB2 each have a
narrow direct-SD route for one independent numeric `sigma` slope. For this
Gamma slice, only native TMB point recovery and output behavior were checked.
Julia parity and interval calibration remain unverified. Correlated or
labelled Gamma `sigma` effects remain unsupported. No package-wide support
claim or programme gate advances.

Details: `docs/dev-log/after-task/2026-10-25-gamma-sigma-slope-sd.md`.
