# After Phase: Student-t and random-effect SD bridge routing

## Goal

Reconcile the drmTMB prior-table feature to current main and route an admitted Student-t coefficient prior plus random-intercept SD prior through the Julia mixed-prior contract.

## Implemented

The isolated branch starts from current drmTMB main `55c3160800ef574ee87034d723ea8af0e8a1050e`. It contains the generalized prior-table feature, model-comparison diagnostics, article, ANOVA guard correction, and Student-t fixed-prior bridge validation. The local change selects v5 for a Student-t coefficient prior combined with a mean random-intercept SD prior. The admission check now receives the model formula so Student-t-only priors on random-effects models are refused before Julia setup.

## Mathematical Contract

This phase changes bridge routing only. It preserves the normalized Student-t coefficient density and the normalized Gamma density on natural SD, evaluated without a log-SD Jacobian. The optimizer and objective conventions are unchanged.

## Files Changed

`R/drmTMB.R`, `R/fixed-priors-workflow.R`, `R/julia-bridge.R`, and `tests/testthat/test-prior-table-v5-bridge.R` contain the local routing fix and regression coverage. `docs/dev-log/check-log.d/2026-11-24-student-t-sd-bridge-route.md` records the checks.

## Checks Run

The v5 bridge test filter passed 47 assertions, with one live-Julia test skipped. The combined prior-table, convergence, model-comparison, and LRT filter passed 1,013 assertions, with seven expected skips. `git diff --check` passed. Live R-to-Julia parity and the full package suite have not run on this source.

## Tests Of The Tests

The focused tests check the Student-t and SD target records emitted by the v5 serializer, confirm the natural-SD row has no Jacobian field, and retain a negative case for a Student-t-only random-effects model. The combined run first exposed that the negative case reached backend setup; the formula-aware admission check corrected that failure. Independent review then found missing packed-index checks; the serializer now includes expected fixed and random-intercept indices, and mock results reject missing, swapped, or mismatched indices and group identities. The live test verifies the DRModels.jl checkout is clean at the expected commit and asserts the current bivariate refusal. The opt-in live mixed fit is present but remains unrun.

## Consistency Audit

No formula grammar, likelihood, or public constructor changed. Existing article and help files were carried forward from the reviewed prior-table branch. No generated documentation required regeneration. A repository-wide status-inventory scan remains part of final integration review.

## GitHub Issue Maintenance

No issue was updated in this phase. The branch is not ready for final issue or PR maintenance while live bridge and package-suite validation remain open.

## What Did Not Go Smoothly

The first broad focused run showed that a prior-only admission helper lacked model-formula context. It consequently allowed an unsupported fixed-only bridge route to reach Julia initialization. The rerun passed after the guard accepted the formula.

## Team Learning

Bridge admission depends on both the selected prior rows and the model structure. A table-level type check alone can miss an unsupported interaction between a valid coefficient prior and a random-effects formula.

## Known Limitations

The mixed Student-t plus SD case has only serializer and mocked bridge coverage on this candidate. The live Julia fit, full test suite, other package twins, and final comparison warnings remain to be validated on frozen current-main sources.

## Next Actions

Freeze the R source, run the public mixed bridge against a current-main DRModels.jl source, reconcile any failures, then complete the authorized full package suite on the final integrated pin. Keep PR #1651 and all other lanes unchanged. Do not merge or release.
