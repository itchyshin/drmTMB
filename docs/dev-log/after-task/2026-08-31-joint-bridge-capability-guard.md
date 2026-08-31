# Joint bridge capability guard

## 1. Goal

Prevent the paired integration from exposing a raw missing-symbol failure when
drmTMB's new joint missing-predictor route is used with an older DRM.jl checkout.

## 2. Implemented

After Julia setup and before joint dispatch, the R bridge checks whether the
loaded DRM module defines `drm_bridge_joint`. An older checkout now produces an
actionable error naming the missing capability, `DRM_JL_PATH`, the required
update and the need to restart R.

## 3a. Decisions and Rejected Alternatives

The guard checks the required capability rather than a package version because
DRM.jl is currently used from source checkouts and a version string would not
identify the loaded implementation reliably. It does not silently fall back to
a different likelihood or imputation method.

## 4. Files Touched

`R/julia-joint-call.R`, one focused test file, this report and one check-log
entry. No likelihood, estimator, formula admission or returned result changed.

## 5. Checks Run

The focused guard passes four assertions. Joint dispatch and two-Gaussian joint
neighbours pass eight and twenty-four assertions respectively.

## 6. Tests of the Tests

Before implementation the focused test produced two missing-binding errors.
The repaired test verifies both the actionable refusal and the required order:
Julia setup, capability check, then dispatch.

## 7a. Issue Ledger

drmTMB PR #1104 depends on DRM.jl PR #565 and must merge second. Programme #563
and global parity gates remain open.

## 8. Consistency Audit

The checked symbol is the exact function called on the next line. The check runs
against the already-loaded DRM module, so it diagnoses the checkout actually in
use rather than a nearby filesystem path.

## 9. What Did Not Go Smoothly

The first lease attempt could not write the shared registry under sandboxing;
the exact-path lease was then recorded with permitted access. The RED test was
retained in command output before the helper existed.

## 10. Known Residuals

This guard does not ensure all paired capabilities exist in arbitrary mixed
checkout combinations. A broader negotiated bridge-capability contract remains
future work.

## 11. Team Learning

Paired repositories need capability negotiation at the call boundary. Merge
order alone cannot protect users who deliberately point at an older checkout.

## 12. Cross-Product Coverage

This slice covers only the joint missing-predictor entry point. It does NOT cover
bridge-wide version negotiation, joint-model numerical parity, inference
coverage, performance, release or global programme completion.

## 13. Next Action and Routing

Merge DRM.jl PR #565 after green CI, then drmTMB PR #1104 after its restarted
check is green. Continue the remaining Ayumi-facing controls, gradient and
large-tree profile work only after the paired base is coherent.
