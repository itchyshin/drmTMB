# MR-G5 Gaussian cohort calibration receipt

## Scope

This receipt records the first Rorqual G5 cohort for the frozen missing-response
Gaussian and bivariate-Gaussian routes. It is an evidence and policy receipt,
not a capability or inference-tier transition.

## Reconciled result

The reconciled artifact contains 54 route-by-target-by-information-rung cells
and 64,800 retained attempts: 1,200 deterministic attempts per cell. The
per-cell maximum Monte Carlo standard error is 0.00712, below the planned
0.01 precision ceiling. All retained records have a profile interval result,
including failures if any had occurred; no attempted fit or non-finite interval
was removed from a denominator.

The three Gaussian `fixef:mu:(Intercept)` cells are a calibration failure:
3,600 of 3,600 intervals contain the frozen truth (coverage 1.000 at each
information rung). This is not a missing-record or profile-failure artifact.
The frozen G3 Gaussian simulator centers its realized random intercepts,
whereas the fitted random-intercept model estimates a population intercept.
That finite-sample design mismatch makes the intervals systematically
conservative for this target.

## Decision and prospective policy

The frozen G3 DGP, targets, seeds, interval method, and existing G5 records are
preserved. The Gaussian fixed-intercept cells are retained with
`calibration_status = "fail"` and
`calibration_reason = "coverage_outside_policy_band"`; they cannot support a
G5 response-mask claim.

For future reconciliations, `mr-g5-calibration-v1` requires each exact
route-by-parameter-by-rung cell to retain all 1,200 attempts, have an available
unclamped interval for every attempt, have coverage MCSE at most 0.01, and fall
within the predeclared 0.925--0.975 band around nominal 0.95 coverage. The
policy is prospective: it does not turn any pre-policy artifact into a pass or
promote a test gate or model inference tier. Reconciliation now also hashes the
runner, frozen target manifest, G4 records, and every input receipt, and records
the command and R version.

## Boundary

No DGP revision, rerun, test-gate promotion, capability-ledger change,
inference-tier change, public missing-data claim, or Julia work occurs here.
Only G5 cells that pass this policy and have a complete provenance receipt may
enter the next review stage.
