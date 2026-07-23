# Plan vs actual — Arc 6.4 exact bivariate Student-t

**Lane:** `codex/arc6-4-biv-student`, based on landed Arc 6.3 commit
`0ccd85b9a3998ef1098cc018cf6b7cf85ae2df28`.
**Claim ceiling:** source-tested development slice only.

## Planned deliverables

1. Define an exact elliptical bivariate Student-t contract with fixed-effect
   `mu1` and `mu2`, intercept-only Student-t scales, one shared `nu > 2`, and
   intercept-only `rho12`.
2. Implement a distinct `biv_student()` TMB route, not `associate_pairs()`,
   with stable parameter transforms and complete-pair validation.
3. Supply an independent closed-form oracle, an `mvtnorm::dmvt()` comparator,
   an exact shared-mixture simulator, and marginal, response-swap, boundary,
   Gaussian-limit, and finite-`nu` zero-correlation dependence checks.
4. Expose bounded fitted-value, parameter, diagnostic, and joint-simulation
   methods.
5. Reject every deferred formula, data, fitting, and inference surface
   explicitly.
6. Synchronize family, formula, likelihood, limitation, and user-facing
   documentation without promoting a capability tier.
7. Run focused, neighbouring, ledger, documentation, and full-package
   verification.

## Actual

The implementation delivers the planned slice:

- `biv_student()` is exported as model type 20 with parameters `mu1`, `mu2`,
  `sigma1`, `sigma2`, shared `nu`, and `rho12`.
- The TMB route implements the exact two-dimensional Student-t density. Its
  dimension-two gamma ratio is simplified to `-log(2*pi)`, and an AD-safe
  non-negative `log1p` helper protects the large-`nu` Gaussian boundary.
- The builder admits predictors only in `mu1` and `mu2`. It rejects incomplete
  or non-finite pairs, weights, offsets, random or structured effects, `mi()`,
  `meta_V()`, penalties, REML, Julia, separate `nu1`/`nu2`, and predictors in
  `sigma1`, `sigma2`, `nu`, or `rho12`.
- The independent tests cover the closed-form density, `mvtnorm`, response
  swapping, Student margins, shared-`nu` identification, near-boundary
  behaviour, the Gaussian limit, and the essential fact that `rho12 = 0`
  remains non-product at finite `nu`.
- `fitted()`, parameter prediction, `sigma()`, `rho12()`, `corpairs()`,
  `check_drm()`, and shared-mixture `simulate()` follow the contract.
  Residual, distribution-output, confidence-interval, and profile surfaces
  reject or report themselves unavailable.
- The symbolic contract, research report, NEWS, roadmap, known limitations,
  registry, likelihood and grammar references, source map, vignettes, and
  roxygen output are synchronized. Capability-ledger outputs are unchanged.

## Drift from plan

No product, estimand, grammar, or evidence-ceiling drift occurred.

One bounded neighbouring repair arose during verification: the first full
check exposed that `profile_targets()` inspected `object$model$model_type`
before validating that `object` was a `drmTMB` object. The validation-order bug
was repaired, and the direct profile-target test is green. This is regression
hardening, not an Arc 6.4 scope expansion.

The implementation also adds a stable `drm_log1p_nonnegative()` numeric helper
and explicit neighbouring method guards. Both are required by the planned
boundary and error contract.

## Verification

- `devtools::document()`: PASS.
- Focused `test-biv-student.R`: PASS, 66 expectations.
- Adjacent bivariate-lognormal, family-link, and Student location-scale tests:
  PASS; one pre-existing singular-convergence warning.
- Direct bivariate-Gaussian tests: PASS; two pre-existing deprecation warnings.
- Direct profile-target tests after repair: PASS; two pre-existing warnings
  and one CRAN skip.
- Capability-ledger check: PASS, 30 outputs.
- `git diff --check`: PASS.
- The first full check reached 16,580 passes, 288 skips, and 62 warnings before
  the sole failure exposed the repaired `profile_targets(list())`
  validation-order bug.
- Final `devtools::check(error_on = "warning", document = FALSE, manual =
  FALSE)`: PASS in 15m57s with 0 errors, 0 warnings, and one benign macOS
  temporary-directory note for `xcrun_db`.
- After-task structure validator: PASS.

## Team reconciliation

Gauss returned GO after the stable large-`nu` density and strict
intercept-only gates were added. Fisher returned GO after `mi()`, residual,
summary-profile, and finite-`nu` dependence boundaries were made explicit.
Rose returned GO after the residual and weight-documentation neighbours were
reconciled. Melissa found the implementation plan-conformant; the
`profile_targets()` repair above was the only plan-to-actual drift.

## Deferred items

No smoke, recovery ledger, coverage, interval calibration, capability
promotion, random or structured effects, predictors outside `mu1`/`mu2`,
partial-pair support, weighted likelihood, `meta_V()`, `mi()`, REML, Julia,
CRAN, generic family-pair claim, or Arc 6.5+ work was attempted. Any simulation
campaign remains a separate owner-approved Totoro/DRAC gate.

## Disposition

**PLAN-CONFORMANT at the source-tested development ceiling.** The final
full-package gate is green, and no scope correction is indicated.
