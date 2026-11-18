# After-task report: Gamma phylogenetic SD parity at non-unit tree height

## 1. Goal

Add a source-bound synthetic test showing whether the current R/TMB and Julia candidates agree for one Gamma phylogenetic SD model when tree height is not one.

## 2. Implemented

- Added `tests/testthat/test-julia-gamma-phylo-sd-scale.R`.
- Added `docs/dev-log/evidence/gamma-phylo-nonunit-parity-20261023/README.md`, `source-manifest.md`, and `test-console.log`.
- Added `docs/dev-log/check-log.d/2026-10-23-gamma-phylo-nonunit-parity.md`.
- Added this report.
- No product implementation source was changed.

## 3a. Decisions and Rejected Alternatives

Kept this as a test and evidence slice. A broader implementation or public support claim would exceed what the single fixture establishes. Kept the Julia branch-scale warning visible rather than normalizing the tree in the bridge or test.

## 4. Files Touched

The created and changed files are listed in section 2. No existing shared product source was edited.

## 5. Checks Run

Ran the focused `devtools::test(filter = "julia-gamma-phylo-sd-scale", reporter = "summary")` command with the live Julia bridge, the candidate Julia worktree, a pinned local depot and one Julia/BLAS thread. It exited 0. The single test passed 6 assertions for convergence, coefficient names, coefficient agreement and tip-level SD prediction agreement, with tolerance 1e-3. The exact command, candidate revisions and file hashes are in the evidence manifest.

The run emitted two warnings. JuliaCall's dependency setup subprocess failed to load `LogExpFunctionsInverseFunctionsExt` because `loglogistic` was undefined. JuliaCall nevertheless loaded the bridge and the test completed. The Julia model also warned that a tree with maximum tip height 6.404475 places `sd_phylo` on the raw branch-length scale. These warnings are retained in the console log and are not suppressed.

## Consistency audit

The fixture uses a single formula and the same generated response, tree and SD predictor for both engines. It checks coefficient and predicted-SD agreement. Its claims are restricted to this fixture. It does not establish recovery of the generating parameters, calibrated uncertainty, non-ultrametric scaling, or general structured-provider parity. The fitted SD interpretation follows the Julia warning: raw branch-length scale is retained, with the ultrametric marginal scale differing from the correlation scale by the square root of tree height.

No broad capability inventory was edited because its current file is part of the shared dirty implementation lane. The test receipt should be reconciled into the capability inventory by its owner before broader claims are updated.

## 6. Tests of the Tests

The test fixes the random seed, checks tree height is greater than one, verifies both fits converged, checks exact coefficient names, and directly compares coefficient and tip-level prediction values. The tolerance was tightened from 0.2 to 1e-3 and the test was rerun successfully. No independent oracle for the Gamma likelihood or interval coverage is included.

## 7a. Issue Ledger

Searched open issues with `repo:itchyshin/drmTMB is:issue is:open "phylogenetic SD" Julia parity`. The search returned issue #555, which concerns the separate Ayumi q4 Gaussian workflow. No issue was changed because it does not track this synthetic Gamma fixture.

## 8. Consistency Audit

The fixture uses a single formula and the same generated response, tree and SD predictor for both engines. It checks coefficient and predicted-SD agreement. Its claims are restricted to this fixture. It does not establish recovery of the generating parameters, calibrated uncertainty, non-ultrametric scaling, or general structured-provider parity. The fitted SD interpretation follows the Julia warning: raw branch-length scale is retained, with the ultrametric marginal scale differing from the correlation scale by the square root of tree height.

No broad capability inventory was edited because its current file is part of the shared dirty implementation lane. The test receipt should be reconciled into the capability inventory by its owner before broader claims are updated.

## 9. What Did Not Go Smoothly

The first console capture attempt ran before the evidence directory existed. The directory was created, and the final rerun completed with its log saved. JuliaCall continued to show the extension-loading warning described above.

## 10. Known Residuals

This receipt establishes one same-data parity fixture for a Gamma phylogenetic SD regression on a non-unit-height ultrametric tree. It does not establish parameter recovery, uncertainty calibration, arbitrary tree scaling, non-ultrametric behavior, or parity for other families and providers. The JuliaCall extension-loading warning also remains unresolved.

## 11. Team Learning

Do not infer structured-scale parity from a unit-height tree alone. Record tree height and the scale convention in each structured parity fixture. Keep bridge setup warnings visible even when the intended fit test passes.

## 12. Cross-Product Coverage

This check covers the R-facing `drmTMB()` fit, SD coefficient extraction, and tip-level SD prediction for one Gamma phylogenetic-intercept model on native TMB and Julia. It does NOT cover standalone Julia calls, simulation, extraction beyond coefficients, save/reload, profile, bootstrap, other response families, other structured providers, non-ultrametric trees, or interval calibration. No user-facing guide or pkgdown navigation changed. Next, reconcile this fixture into the shared capability evidence inventory and continue the still-open family/provider/backend implementation rows. The overall programme remains active.
