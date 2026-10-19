# Convergence budget table

## 1. Goal
Replace the confusing budget figure with a readable table and publish the revised guide for applied drmTMB users.

## 2. Implemented
A generated table compares the same Gaussian model and data under default and low budgets, with identical starts and Newton polishing disabled. It shows function evaluations, maximum absolute gradient, convergence code and gradient status. The explanation separates counts from gradient size and states what a small gradient cannot establish. The preceding status map uses neutral labels.

## 3a. Decisions and Rejected Alternatives
Use a table rather than another plot. Generate values from actual fits; do not hard-code outcomes or change fitting defaults. Keep the optimizer-selection section intact.

## 4. Files Touched
vignettes/convergence.Rmd and this task's check-log and after-task fragments.

## 5. Checks Run
The extracted table chunk passed finite-value, threshold, status and convergence-code checks against the existing isolated selector installation. Local HTML rendering passed. Final CI, deployment and live verification remain pending and will be recorded in the external closeout receipt.

## 6. Tests of the Tests
The initial candidate failed the intended gradient contrast: Newton polishing rescued the low-budget fit. With polishing disabled and shared explicit starts, default and low-budget gradients fall on opposite sides of 0.001 and report the expected statuses. No new package test was added for this presentation-only edit.

## 7a. Issue Ledger
Owner-requested documentation correction. Existing optimizer feature and collaborator analysis remain separate. No collaborator message is part of this task.

## 8. Consistency Audit
Scanned vignettes, README.md and _pkgdown.yml for convergence-gradient-budget and the old plot title; no remaining reader source reference. The guide retains direct optimizer examples and diagnostic limitations. No product behavior changed, so no family, grammar, roadmap or release update is needed. Memory receipt: prior publication practice informed the route; current source, CI and live files are the evidence. Golden Set: outside scope.

## 9. What Did Not Go Smoothly
The first fixture was rescued by polishing. CI caught internal fit-field access; the table now reads all diagnostics through public check_drm() output. Browser captures initially produced blank images; Chrome print rendering was inspected successfully and showed readable columns without clipping. Final visual and deployment evidence will be retained separately.

## 10. Known Residuals
Counts are for the selected attempt, not total retry cost. A small gradient does not establish a global optimum or reliable uncertainty. Local numerical checks use the existing selector installation; source CI and deployed-page checks remain separate.

## 11. Team Learning
When illustrating an optimizer budget, hold model, data and starts fixed and disable secondary polishing. Inspect both numerical outputs and rendered presentation.

## 12. Cross-Product Coverage
This correction covers the drmTMB convergence guide. It does NOT cover Ayumi's real-data fits, new optimizers, calibration, package releases or other package websites.
