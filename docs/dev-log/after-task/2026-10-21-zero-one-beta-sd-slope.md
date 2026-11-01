# After Task: zero-one beta location slope SD regression

## Goal

Extend the existing zero-one beta direct-SD route to a single independent numeric location slope in native TMB, and document the supported scope.

## Implemented

`sd(id, coef = "x") ~ w` can target one ordinary zero-one beta `mu` slope. The existing constant-SD intercept and Julia intercept routes remain intact. A seeded example and tests exercise fitting, recovery, group-SD prediction, simulation, save/reload, and constant-SD equivalence.

## Mathematical Contract

For group `g`, `log(tau_g) = W_g alpha`. The selected slope contributes `x_ig tau_g u_g`, where `u_g` is standard normal. The scale model affects the interior beta location component on the link scale. It adds no observation-level residual parameter and does not change the zero-one boundary mixture.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-zero-one-beta-sd-slope.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`
- `docs/dev-log/check-log.md` and `docs/dev-log/check-log.d/2026-10-21-zero-one-beta-sd-slope.md`
- `NEWS.md`
- `vignettes/formula-grammar.Rmd` and `vignettes/predictor-dependent-random-sd.Rmd`

The goal checkpoint is also updated for continuation.

## Checks Run

The slope regression filter passed 17 tests with no failures, warnings, or skips in 14.7 seconds. The prior zero-one beta SD regression filter passed 14 tests. The predictor-dependent-SD vignette rendered successfully from the current source in the previous turn, and the current-source formula-grammar vignette rendered in 4.5 seconds. Both reported the existing Pandoc `--mathjax` warning. `pkgdown::check_pkgdown()` passed with existing `--mathml` warnings. The broader zero-one beta filter was interrupted after its independent quadrature test exceeded the brief run estimate; it is not a pass. The exact commands and outcomes are in the linked check-log receipt. Targeted `git diff --check` passed; full `git diff --check` reports an unrelated pre-existing extra blank line at EOF in `tests/testthat/test-binomial-sd-integration.R`.

## Tests Of The Tests

The new assembly regression failed before the change at the intercept-only admission guard. It passed after the builder admitted a single slope. The existing rejection tests continue to cover unsupported mixed designs and structured SD formulas. Recovery uses a seeded synthetic data generator with a nonzero SD predictor effect.

## Consistency Audit

The TMB implementation reuses the existing group-SD row mapping for the selected `mu` slope. Formula grammar, the adapter map, and the rendered example now agree: native TMB supports one intercept or one independent numeric slope; Julia currently supports the intercept route only. The direct SD is the scale of a latent coefficient on the interior beta location link. Interval calibration remains open.

The exact family/status inventory command was `rg -n -i 'zero.one beta|zero-one beta|zero_one_beta' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`. NEWS, the scale-status design page, the formula-grammar vignette, and the main check log now match the implementation. README, roadmap, known-limitations, and pkgdown navigation had no additional change needed for this slice.

## GitHub Issue Maintenance

Open issue search found no issue specifically tracking this direct-SD slope slice. The nearest results concerned broader family coverage and repeatability. No issue was changed.

## What Did Not Go Smoothly

The broad `zero-one-beta` test filter entered a computationally heavier quadrature check and outlasted the brief estimate. I stopped it and reran the two focused SD filters, which completed. The broad filter remains unresolved.

## Team Learning

For family suites containing quadrature tests, keep focused feature filters separate from all-family filters and record their runtime before launching broader work. Retain the first failing assertion as the test-first receipt.

## Known Limitations

Native TMB currently supports the location-slope route for complete responses and one ordinary `mu` target, with fixed `sigma`, `zoi`, and `coi`; additional or structured effects remain unsupported. Julia slope parity and interval calibration are not established. The scale-status design page, NEWS, formula-grammar vignette, and main check log were synchronized in this slice.

## Next Actions

Continue to the next ordinary-family SD adapter in the active goal. Continue the next ordinary-family SD adapter under the general goal. Keep Julia slope support and interval calibration listed as open work.
