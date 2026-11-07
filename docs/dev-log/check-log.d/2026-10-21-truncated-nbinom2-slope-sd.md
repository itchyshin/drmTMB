# Native zero-truncated NB2 independent-slope SD regression

## Check result

- Assembly and unsupported-target checks: 20 assertions passed; 0 failures,
  warnings, or skips.
- Seeded integration and recovery: 16 assertions passed in 81.0 seconds; 0
  failures, warnings, or skips.
- The integration fixture checks a positive SD trend, group-indexed SD
  predictions, equivalence with the existing constant-SD model, and a separate
  groupwise quadrature calculation. Reversing the SD index is a negative
  control. The quadrature-to-Laplace tolerance is deliberately a broad
  implementation sanity threshold, not a precision comparison.
- No live Julia tests ran. The result is native TMB point-recovery evidence,
  not Julia parity or interval calibration.

## Commands

```sh
Rscript -e 'devtools::test(filter = "truncated-nbinom2-sd-regression")'
Rscript -e 'devtools::test(filter = "truncated-nbinom2-sd-integration")'
```

## Scope

Complete responses; one selected independent numeric `mu` slope; fixed
zero-truncated NB2 `sigma`; SD predictor constant within each group. Correlated
slopes, structured effects, random `sigma`, missing responses, interval
calibration, and Julia parity remain open.

## Consistency searches

```sh
rg -n -i 'truncated[_ -]nb2|zero[- ]truncated|truncated_nbinom2' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/34-validation-debt-register.md docs/design/59-structural-slope-and-non-gaussian-map.md vignettes/formula-grammar.Rmd
rg -n -i 'truncated.{0,90}(intercept-only|only.*intercept|slope.*planned|direct-SD)|direct-SD.{0,90}(zero-truncated|truncated_nbinom2)|zero-truncated.{0,100}(direct-SD|predictor-dependent SD)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/34-validation-debt-register.md docs/design/59-structural-slope-and-non-gaussian-map.md vignettes/formula-grammar.Rmd
```
