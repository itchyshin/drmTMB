# After task: dedupe `drm_julia_rhs_is_intercept_only()` (#1583)

## What changed

- `R/julia-bridge.R` defined `drm_julia_rhs_is_intercept_only()` twice with
  identical bodies; the later definition shadowed the earlier one. The second
  copy is removed and its comment (the measured `sigma1 = ~ (1)` parity note)
  is folded into the single remaining comment, which now names both callers
  (dpar-scope fence and the biv_student constant-dpar check).
- New `tests/testthat/test-julia-rhs-intercept-only.R`: parses
  `R/julia-bridge.R` and asserts exactly one top-level definition (fails on
  main with 2), plus behaviour checks (`~ 1`, `~ (1)` TRUE; `~ 0 + z`, `~ x`,
  `~ 1 + offset(z)` FALSE). The source-parse test is a no-op when the source
  tree is absent (installed-package runs), without `skip_*`, so the env-skip
  census is unchanged.

## Behaviour

No runtime change: the two bodies were byte-identical.

## Verification

- New test fails on main (`sum(defs)` 2 vs 1), passes with the fix.
- Full testthat suite run per file (R 4.3 container, no live Julia). The
  `%||%` operator is base only from R 4.4, so a local shim was defined to run
  under 4.3. Remaining failures (`test-comparators`, `test-comparators-phase19`,
  `test-julia-bridge` x1, `test-missing-predictor-prediction` x1,
  `test-reader-vignette-contracts` x1) fail identically on unmodified main and
  are environmental/pre-existing.
- `roxygen2::roxygenise()` regenerates ~40 `man/*.Rd` files that differ from
  the committed ones on main already (pre-existing drift, unrelated to this
  change, no roxygen block touched); not committed here.
