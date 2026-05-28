# After-Task Report: Phase 18 Tweedie Low/High-Zero Comparator Cells

Date: 2026-05-28

## Purpose

Team A finished the remaining low-zero and high-zero comparator cells from the
1619-1628 Tweedie contract. The purpose was to test the fitted fixed-effect
`tweedie()` overlap against `glmmTMB::tweedie()` in two semicontinuous regimes
without opening predictor-dependent `nu`, random effects, structured effects,
bivariate Tweedie, zero-inflation aliases, or hurdle aliases.

## Implementation

`tests/testthat/test-tweedie-location-scale.R` now runs the optional
`glmmTMB` comparator over two deterministic cells. The low-zero cell checks a
positive exact-zero count and a zero fraction below 0.05. The high-zero cell
checks a zero fraction above 0.20 while keeping `nu = 1.55`, away from the 1
and 2 boundaries.

In both cells the test compares:

- `coef(fit, "mu")` against `glmmTMB::fixef(fit_glmmTMB)$cond`;
- `2 * coef(fit, "sigma")` against `glmmTMB::fixef(fit_glmmTMB)$disp`;
- intercept-only `predict(fit, dpar = "nu")` against
  `glmmTMB::family_params(fit_glmmTMB)`;
- direct log-likelihood values.

The comparator remains optional through `testthat::skip_if_not_installed("glmmTMB")`,
so `glmmTMB` stays a `Suggests`-level evidence tool, not a required runtime
dependency.

## Documents Updated

The evidence ledger in
`docs/design/126-phase-18-tweedie-comparator-contract-slices-1619-1628.md`
now marks Slices 1626-1628 done for both comparator cells. The Phase 18
simulation programme and `ROADMAP.md` now describe the low-zero and high-zero
coverage of the optional comparator.

## Validation

```sh
air format tests/testthat/test-tweedie-location-scale.R
Rscript --vanilla -e "devtools::test(filter = '^tweedie-location-scale$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^(tweedie-location-scale|skew-normal-boundary|family-link-contract)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
git diff --check
```

Result: `test-tweedie-location-scale` passed, including the optional
`glmmTMB` low-zero and high-zero comparator cells on this machine.
The combined focused gate also passed for Tweedie location-scale,
skew-normal-boundary, and family-link-contract tests. Full
`devtools::test(reporter = "summary")` passed. `pkgdown::check_pkgdown()`
reported no problems, and `git diff --check` was clean.

Team A's sidecar audit recorded a low-zero zero fraction of 0.002857 and a
high-zero zero fraction of 0.277143. The largest absolute comparator
differences were below the 5e-5 test tolerance for `mu`, log-dispersion,
`nu`, and log-likelihood.

## Review Notes

Curie and Fisher treat this as comparator hardening, not broad operating-
characteristics coverage. Gauss and Noether confirm that the public-scale
comparison stays on `sigma^2 = phi`, so the coefficient comparison remains
`2 * beta_sigma(drmTMB) ~= beta_disp(glmmTMB)`. Rose flags no new fitted
surface claims.

## GitHub Issue Maintenance

The Tweedie umbrella issue #2 is already closed after the fitted family landed.
No duplicate issue is needed for these comparator cells.

## Next Step

The next Team A slice can either add a small direct log-likelihood fixture for
the Tweedie density constants or move to rendered-reference and stale-claim
checks. Team B can continue the skew-normal first-test contract before any
constructor or TMB branch is added.
