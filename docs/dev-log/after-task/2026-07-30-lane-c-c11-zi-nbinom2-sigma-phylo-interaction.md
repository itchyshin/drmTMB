# After Task: Lane C C11 ZINB sigma phylo-interaction

## 1. Goal

Attempt the exact `mc-0653` ML zero-inflated NB2 sigma phylo-interaction route
and promote it only if its complete local point-recovery contract passed.

## 2. Implemented

The R validator now admits only intercept-only `zi ~ 1` alongside unlabelled
q1 `sigma ~ phylo_interaction(...)`. Model type 9 dispatches the structured
field to `log_sigma`, never `eta_mu` or `eta_zi`, and hard-errors unknown
endpoint codes. R extraction/prediction recognizes structured sigma for
`zi_nbinom2`; the direct target is visible but not profile-ready.

## 3a. Decisions and Rejected Alternatives

The ordinary ZINB sigma random-intercept control was not admitted. It is a
separate capability, not a test-only implementation detail. Its rejection is
the C11 blocker, rather than grounds to weaken the required IID control.

## 4. Files Touched

- R/drmTMB.R
- R/methods.R
- R/profile.R and man/profile_targets.Rd
- src/drmTMB.cpp
- tests/testthat/test-phylo-interaction.R
- tools/run-lane-c-c11-zi-nbinom2-sigma-phylo-interaction-local-recovery.R
- C11 receipts and this report

## 5. Checks Run

- Lane preflight reported no Claude lane (weak all-clear).
- Focused `test-phylo-interaction.R` passed: 109 assertions.
- `devtools::document()` regenerated profile_targets.Rd.
- The clean-source `run-2` retained all four structured and four IID-control
  attempts; only the structured fixture passed.

## 6. Tests of the Tests

The independent oracle evaluates the complete ZINB mixture, NB2 scale,
normalized Kronecker phylogenetic Gaussian prior, objective equality,
AD-versus-central-FD gradients, nonzero-SD dependency, and endpoint-specific
link predictions. The runner writes every attempt before summarizing it.

## 7a. Issue Ledger

No ledger row changed. `mc-0653` remains `not_implemented`; the board therefore
remains at 20 not implemented and 179 point-fit-recovery cells.

## 8. Consistency Audit

Model-9 endpoint dispatch is closed: code 0 is mu, code 1 is sigma, and all
other codes abort. The target remains direct but profile-fenced. No
Future-extension or Mission Control source changed.

## 9. What Did Not Go Smoothly

The first retained runner used overlapping resampling seeds and a dirty source;
it is preserved as `run-1` and superseded. The clean `run-2` structured result
passes, but the required IID formula is intentionally rejected before fitting.

## 10. Known Residuals

No point-fit promotion is supported. Ordinary ZINB sigma random effects, all
other structured providers, slopes, labels, q2+, profiles, intervals,
bootstrap, coverage, missing response, and inference remain outside C11.

## 11. Team Learning

Noether's pre-code review was correct: the endpoint needs an explicit model-9
dispatch, not a validator-only change. Fisher's requested ZINB IID control
prevented a structured-only recovery result from being overstated. Rose's
endpoint-prediction test ensures the field cannot silently affect mu or zi.
Fresh Noether, Fisher, and Rose completion reviews unanimously returned BLOCK:
the compulsory IID control cannot be waived, so no ledger transition follows.

## 12. Cross-Product Coverage

C11 covers the exact complete-response ML q1 phylo-interaction sigma route,
its extraction, target status, closed C++ endpoint dispatch, oracle, and
structured local recovery. It does not cover the required IID ordinary-RE
control, so it does not cover `mc-0653` at point-fit recovery.
