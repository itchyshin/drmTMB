# C12 after-task — ZINB sigma-control corridor

## 1. Goal

Implement the exact complete-response ML ZINB2 IID `sigma` random-intercept
control, then reattempt `mc-0653` q1 `phylo_interaction()` scale route. The
maximum claim is local point-fit recovery.

## 2. Implemented

- Model type 9 now carries the guarded IID `sigma` field through validation,
  start/map/data, latent Normal penalty, reporting, extraction, and prediction.
- Its direct SD target is visible but `profile_ready = FALSE` with
  `point_fit_only_zi_nbinom2_sigma_q1`.
- Run 3 retained four IID controls then four structured attempts; both passed.
  Only `mc-0653` moved to point-fit recovery.

## 3a. Decisions and Rejected Alternatives

- `mc-0633` stays not implemented: its legacy `sigma ~ z + (1 | id)` cell is
  wider than C12's fixed-sigma-RHS contract.
- Endpoint code 1 stays attached to `log_sigma`, never `eta_mu` or `eta_zi`.
- No profile refit, interval, bootstrap, coverage, remote compute, or wider
  ZINB grammar was added.

## 4. Files Touched

- Model-9 R/C++ carrier, profile status, controlled Rd, focused tests, and C12
  runner.
- Formula grammar design/vignette, C12 run-1/2/3 retained receipts, ledger
  sources/generator/generated surface, and this closeout.

## 5. Checks Run

- Focused phylo-interaction and profile-target tests passed; `document()`
  regenerated controlled Rd.
- Run 3 passed IID 4/4 then integrated structured 4/4.
- After replay on PR #862's merged taxonomy baseline, the focused tests,
  terminal recovery, `capability_ledger.py --write`, and `--check` passed.

No full suite, `R CMD check`, profile refit, or remote campaign was a C12 gate.

## 6. Tests of the Tests

Independent full-mixture plus IID/Kronecker-prior oracles, AD versus central FD,
dependency and boundary sentinels, endpoint routing, extraction/prediction,
profile fences, and formula-neighbour rejections all exercise the new carrier.

## 7a. Issue Ledger

- Resolved: model type 9 had no full IID `sigma` carrier for C11's control.
- Resolved: run 1 tree-environment binding failure; run 1/2 remain retained and
  run 3 is terminal.
- Deferred: broader `mc-0633` needs its own approved contract.

## 8. Consistency Audit

Validator, start/map/data, C++ penalty, reporting/extraction, dispatch, grammar,
target status, runner, and generated ledger were traced together. PR #862's
taxonomy merged first; its generated source—not stale prose—sets the count.

## 9. What Did Not Go Smoothly

Run 1 initially did not bind tree expressions. The #862 overlap also required a
one-file check-log rebase that preserved both entries before C12 replay.

## 10. Known Residuals

The structured fixed `log_sigma` intercept mean error is close to, but within,
the 0.20 cutoff. This is point-fit evidence only, not interval or coverage work.

## 11. Team Learning

Noether confirmed the carrier/map; Fisher and Rose withheld `mc-0633` because
its legacy formula is wider, while supporting `mc-0653`. Reconcile the actual
ledger formula before using evidence to change a count.

## 12. Cross-Product Coverage

C12 covers ✓ complete-response ML NB2 with fixed-effect `mu`, `zi ~ 1`, and
the exact IID control or exact q1 phylo-interaction `sigma` endpoint. It does NOT cover ✗ sigma predictors/slopes, labels/covariance, other providers,
ordinary or structured `mu`/`zi` effects, missing response, REML, profiles,
intervals, bootstrap, coverage, calibration, or inference readiness.
