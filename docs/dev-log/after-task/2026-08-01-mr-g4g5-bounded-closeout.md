# After Task: MR-G4/G5 bounded closeout

## 1. Goal

Make the R-only missing-response G4/G5 evidence framework ready for all 18 G3 routes, retain completed G5 calibration evidence, and stop the campaign at the user-approved bounded endpoint.

## 2. Implemented

The framework freezes each route's G3 MCAR DGP, records profile-interval feasibility by target and information rung, and allows only G4-feasible cells into G5. The closeout records seven reconciled artifacts covering eight cohorts, the cancelled Beta array, and the unrun remainder.

## 3a. Decisions and Rejected Alternatives

G4 requires a finite, ordered, unclamped interval with the correctly named target on its reporting scale and the known interior truth contained. G5 uses the same frozen target and profile method, 1,200 planned attempts per cell, and an unconditional denominator that retains failed fits and unusable intervals. The user chose a bounded stop rather than finishing the remaining route cohorts; no DGP, seed, target, denominator, or interval method was changed to manufacture a broader result.

## 4. Files Touched

The generated missing-response next-step text now describes the stopped, partial campaign; this report, the campaign closeout receipt, and the check log record the evidence and boundary.

## 5. Checks Run

`devtools::test(filter = "missing-response-g4g5-foundation")` passed. The remote manifest/ledger readback found 18 routes, 102 manifest targets, 306 G4 records, and 295 G4-feasible records. Rorqual job `18098606` was cancelled and its queue entry cleared; two Beta receipts remain durable. `python3 tools/capability_ledger.py --write`, `--check`, and all 41 generator unit tests passed; `pkgdown::check_pkgdown()` reported no problems; `check-after-task.R` and `git diff --check` passed. Fresh Fisher, Rose, and Grace review agreed that this is a bounded framework/cell-evidence closeout and that no route-level promotion is justified.

## 6. Tests of the Tests

The focused suite exercises frozen-manifest completeness, failure retention, clamp rejection, parameter naming and scale, and G5 all-attempt denominators. The G4/G5 runner itself permits only G4-feasible records, so an ineligible cell cannot enter the coverage campaign.

## 7a. Issue Ledger

No issue was closed and no new issue was opened. This is an evidence-framework and campaign-stop checkpoint rather than a public API change.

## 8. Consistency Audit

The generated dashboard, vignette include, and tranche pages previously said the campaign was active. The source generator now says that the framework is ready with partial calibration evidence retained and that every public route remains G3. Searches cover `G4/G5`, `campaign is active`, `inference-ready`, and `missing-response` in the generated reader surfaces.

## 9. What Did Not Go Smoothly

Profile intervals made several full G5 cells slow. Beta was stopped after two durable receipts at the user's direction; those partial receipts are retained but deliberately not reconciled into evidence.

## 10. Known Residuals

Only 8 of 18 route-level cohorts have reconciled G5 results; 32 of their 130 cells fail the prospective policy. The remaining routes, partial Beta, MAR/MNAR, response-plus-`mi()`, dense known covariance, other engines, and Julia remain outside this evidence boundary.

## 11. Team Learning

Campaign status must be generated from authoritative state rather than a hard-coded "active" phrase. Exact target-rung calibration results should not be rendered as route-wide G5 status.

## 12. Cross-Product Coverage

This arc covers R-only missing-response MCAR handling for the frozen univariate and bivariate-Gaussian G3 routes, their profile-interval feasibility records, and the completed target-rung G5 calibration cohorts. It does NOT cover route-wide G5 promotion, model inference tiers, the cancelled Beta cohort, the nine fully unrun routes, MAR/MNAR, response-plus-`mi()`, dense known covariance partial pairs, EM/profile engines, broad random or structured masking, Julia, REML, or aggregation changes. Do not restart G5 automatically. A future maintainer may define a new, prospective continuation campaign from the frozen manifest and durable receipts, then obtain a fresh D-43 review before any route-level promotion.
