# After Task: Phylogenetic stable intercept plus independent OU closeout

## Goal

Close the approved P1 slice honestly after its interval-feasibility amendment: preserve the failed calibration result, make the public profile boundary explicit, strengthen the retained-artifact verifier, and leave a reproducible handoff.

## Implemented

The paired model remains an additive Gaussian ML covariance: a tree-correlated stable species intercept plus an independent within-species OU deviation. Fixed-mean profiles can be calculated for a fitted model, but the retained 3,500-fit campaign found intercept-profile undercoverage in P1, P2, and P3. `check_drm()` now exposes that result as a note, while public documentation calls the endpoints interval-feasibility diagnostics rather than inference-ready intervals.

## Mathematical Contract

For rows \(r,q\), with species \(i_r,i_q\) and elapsed times \(t_r,t_q\), the fitted covariance is

\[
V_{rq}=s_b^2 A_{i_r i_q}+I(i_r=i_q)s_a^2\exp\{-\lambda|t_r-t_q|\}+I(r=q)\sigma^2.
\]

The native likelihood and an independent dense oracle passed G3--G6. The model is additive: it is not a separable phylogeny-by-time field.

## Files Changed

`R/check.R`, `R/profile.R`, generated profile help pages, the phylogenetic-temporal vignette, the formula and likelihood design notes, G13's re-verifier, its focused tests, the P1 gate runner and ledger, the closeout evidence directory, and this report.

## Checks Run

The G13 re-verifier self-test passed. Its focused test file passed, including the missing-artifact negative control and checks for the locked campaign source, worker fingerprint, and SHA-256 archive verification. The paired phylogenetic-OU methods suite passed through `devtools::test(filter = "phylo-temporal-ou-methods")`. `devtools::document(quiet = TRUE)` regenerated the two profile help pages. G14 and G15 passed after the wording repair. The final `R CMD build` and `R CMD check --no-manual` completed with `Status: OK`; their retained log and receipt are in `simulation-artifacts/2026-09-11-phylo-temporal-ou-closeout/`.

## Tests Of The Tests

The verifier test deliberately invokes an incomplete archive directory and requires a nonzero exit while retaining an inventory. The new static checks require the exact G12 source commit, the SHA-256 verifier, and exact worker-MD5 comparison. The methods test checks the public diagnostic note and continues to reject covariance and `newdata` routes.

## Consistency Audit

The public vignette, formula grammar, likelihood design note, profile help, and diagnostic now use the same distinction: a profile endpoint is calculable, but the retained P1 calibration failure means it is not reportable as inference-ready. Historical campaign results and the red G13 gate remain unchanged.

## GitHub Issue Maintenance

Inspected open issue #1302, “Feature: phylogenetically correlated temporal OU series.” It already tracks this slice, so no duplicate issue was opened and no external comment was sent during local closeout. The P1 acceptance ledger remains the detailed retained-evidence record.

## What Did Not Go Smoothly

The first direct `testthat::test_file()` invocation did not load the package, so it reported `drmTMB()` missing. Re-running through `devtools::test()` passed. A source-package check was also started before the final documentation-only synchronization, so it is not used as final G16 evidence; the final check is run from the completed source tree.

## Team Learning

Noether found that the old G13 re-verifier accepted a syntactically valid checksum sidecar without recalculating the archive SHA-256 and accepted any 40-character source hash and any 32-character worker hash. The verifier now binds both to the immutable campaign source. Pat found public text that sounded more restrictive than the authorized interval-feasibility boundary. The repaired wording keeps the endpoint available for diagnostic work while preventing it from being presented as calibrated inference.

## Known Limitations

G9 remains failed. G13 remains failed: six of nine primary rows qualified, while intercept coverage was 0.870, 0.922, and 0.895 in P1--P3. This slice does not support Wald covariance, bootstrap or variance/decay intervals, forecasts, `newdata`, a separable phylogeny-by-OU field, or any next temporal structure. The strengthened verifier has passed its local self-test; its cryptographic archive check has not been rerun against the remote immutable archive collection in this closeout.

## Next Actions

Do not promote P1 to inference-ready. The next distinct arc is phylogenetic OU covariance (`phylo(..., model = "ou")`) after the temporal programme has its own handoff, rather than extending this additive phylogeny-plus-temporal OU route. Any future recalibration must retain the existing G13 result and use a newly authorized protocol.
