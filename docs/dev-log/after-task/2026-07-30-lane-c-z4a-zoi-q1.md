# Lane C Z4a — zero-one-beta zoi q1 local point-fit recovery

## 1. Goal

Attempt only `mc-0569`: `bf(y ~ x, sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ 1)` under ML `zero_one_beta()`.

## 2. Implemented

The fit now has separate `u_zoi` and `log_sd_zoi` carriers. They affect only the logit-zoi predictor and carry an independent standard-normal latent penalty. The natural-scale SD and modes are extracted under `zoi`.

## 3a. Decisions and Rejected Alternatives

One unlabelled ordinary intercept only. Slopes, labels, covariance, simultaneous dpar effects, structured effects, missing responses, `coi` effects, profiles, intervals, coverage, and remote compute remain closed.

## 4. Files Touched

`R/drmTMB.R`, `R/profile.R`, `R/family.R`, `src/drmTMB.cpp`, `tests/testthat/test-zero-one-beta.R`, the committed local runner, and the retained run-1 receipt.

## 5. Checks Run

The model compiled. Focused zero-one-beta and profile-target tests passed. The ledger checker passed. The source-bound four-seed fixture at `38aeb1d22` passed all gates; its fixed-SD run is diagnostic-only.

## 6. Tests of the Tests

The independent oracle includes the full zero/one/interior mixture plus the normal penalty. It agrees with the TMB objective and central-FD gradient. A nonzero-SD sentinel changes the objective. Endpoint profiling is mocked and proven not to start.

## 7a. Issue Ledger

`mc-0569` is eligible only for `implemented / verified / point_fit_recovery`. `mc-0570` is unchanged.

## 8. Consistency Audit

The Future-extension audit and its 330 records are unchanged. The route remains direct-but-not-profile-ready and makes no interval claim.

## 9. What Did Not Go Smoothly

The first runner checked combined boundary support only. Its retained blocker run led to an enforced separate zero/one support DGP and a rerun. A structured-mu plus zoi combination was also found and rejected before promotion.

## 10. Known Residuals

This evidence does NOT cover `coi`, atom slopes, joint dpar effects, structured atom effects, missing response, profiles, intervals, coverage, calibration, or inference readiness.

## 11. Team Learning

For atom-mixture effects, record zero and one support separately by group; combined boundary totals are insufficient.

## 12. Cross-Product Coverage

This work does NOT cover Lane A association, Lane B scale/interval work, or the six representation-frontier cells.
