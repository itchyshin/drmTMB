# After-task — phylogenetic-temporal OU G10 timing and diagnostics pilot

## 1. Goal

Measure the frozen P1--P4 profile workflow before writing its calibration contract or proposing a campaign.

## 2. Implemented

Added a deterministic, non-overwriting G10 worker and immutable verifier. The worker generates five seeds in each frozen cell, retains two configured optimizer starts and three fixed-mean profile attempts per dataset, and records timing, peak R allocation, convergence, Hessian status, warnings, and profile availability. It checkpoints each completed dataset immediately.

## 3a. Decisions and Rejected Alternatives

The worker fits the approved additive Gaussian model: a phylogenetically correlated stable intercept, independent same-species OU deviations, and residual `sigma`. It profiles only the three fixed `mu` coefficients. It does not estimate coverage, validate a separable phylogeny-by-OU field, or change any public inference boundary. A profile campaign and its compute target remain G12 decisions.

## 4. Files Touched

- `tools/run-phylo-temporal-ou-g10-pilot.R`
- `tools/phylo-temporal-ou-gates.R`
- `tests/testthat/test-phylo-temporal-ou-gate-runner.R`
- the phylogenetic-temporal OU Unlazy ledger and check log
- retained G10 artifacts under `docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g10-pilot*`

## 5. Checks Run

The focused gate-runner test passed. The worker parser passed. The one-P1 preflight completed one fit plus three available profiles in 15.210 seconds. The full v2 worker retained 20 fits, 40 starts, 60 profiles, and 20 diagnostics; `Rscript --vanilla tools/phylo-temporal-ou-gates.R G10` returned `PHYLO_TEMPORAL_OU_G10_PASS`.

## 6. Tests of the Tests

Before evidence existed, G10 failed closed on its missing `manifest.csv`. The first preflight then exposed an incorrect optimizer-diagnostics slot and retained its manifest-only artifact. The corrected v2 worker writes `progress.csv` after every dataset, and the verifier requires all 20 progress records as well as all final denominator files.

## 7a. Issue Ledger

Open issue #1302, “Feature: phylogenetically correlated temporal OU series,” is the existing tracker. No issue comment or new issue was needed for this retained local pilot.

## 8. Consistency Audit

No user-facing model syntax, likelihood, documentation, or pkgdown capability changed. The exact status-inventory search over `README.md`, `docs/dev-log/internal-roadmap.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, `_pkgdown.yml`, and the phylogenetic-temporal plan found the expected historical coverage wording and the current G11 pending entry. The ledger, check log, worker, and verifier all label G10 as timing and diagnostics evidence only. Existing G9 failure and G9c's limited scope remain visible.

## 9. What Did Not Go Smoothly

The first preflight referenced `fit$fit` rather than the native `fit$opt` diagnostics. The first uncheckpointed full invocation was detached by the execution wrapper and retained only a manifest before it was stopped as redundant. Neither partial result was overwritten; v2 records per-dataset progress.

## 10. Known Residuals

This pilot is not interval-coverage evidence and does not make profile intervals publicly qualified. Wald covariance, variance and decay intervals, forecasts, `newdata`, the separable field, and the G12 campaign remain outside its scope. G11 must now freeze the 95% profile-calibration contract, its worker, denominator rules, and fail-closed assessment before any campaign is proposed.

## 11. Team Learning

Long R workers must checkpoint after each independent dataset. A parent-shell completion signal is not sufficient evidence that a detached child R process has stopped.

## 12. Cross-Product Coverage

This validates operational behaviour only for the additive phylogenetic-stable plus independent-OU Gaussian ML slice and fixed-mean profile workflow. It does not cover phylogenetic propagation through time, temporal effects in `sigma`, other temporal structures, non-Gaussian families, REML, missing-response handling, spatial effects, a Julia engine, or any public inference claim.
