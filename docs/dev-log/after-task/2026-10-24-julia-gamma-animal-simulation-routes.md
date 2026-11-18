# After Task: Document Julia Gamma animal simulation routes

## 1. Goal

Document the existing Julia Gamma animal-intercept and intercept-plus-slope marginal simulation routes, including their covariance convention and limits.

## 2. Implemented

The public `simulate()` help and Julia-engine guide now name both complete-data Gamma animal routes, explain the fixed `sigma ~ 1` requirement and unavailable conditional simulation, and state that the supplied relationship matrix is normalized to the unit-diagonal correlation used by the Julia fitter. The guide now includes independent synthetic Gamma data and fit/simulation examples for an intercept and for separate intercept and numeric-slope SD formulas. The generated Rd page was refreshed.

## 3a. Decisions and Rejected Alternatives

Kept the documentation limited to the two routes exercised by current tests. Broader language implying all structured modelled scales are simulatable would be inaccurate. Assumption made without asking: the vignette can use `eval=FALSE` examples because the Julia bridge is development-candidate support and may not be available in documentation builds; running the focused live tests still verifies the described examples' routes.

## 4. Files Touched

- `R/methods.R`
- `R/julia-simulate.R`
- `man/simulate.drmTMB.Rd`
- `vignettes/julia-engine.Rmd`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/check-log.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `LOOP/lanes/general-sd-regression/arcs.md`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/evidence/gamma-animal-marginal-simulation-docs-20261024/source-manifest.md`
- `docs/dev-log/evidence/gamma-animal-marginal-simulation-docs-20261024/test-console.log`
- `docs/dev-log/after-task/2026-10-24-julia-gamma-animal-simulation-routes.md`
- `docs/dev-log/after-task/2026-10-24-julia-gamma-animal-simulation-routes.assessment.json`

The focused test source files were not changed in this documentation slice; they were rerun as behavior checks.

## 5. Checks Run

- `devtools::document()`: passed; regenerated `man/simulate.drmTMB.Rd`.
- `devtools::test(filter = "gamma-animal-(q2|intercept-simulation)", reporter = "summary", stop_on_failure = TRUE)`: passed; four live Julia tests ran, with no failed assertions or skipped bridge tests. Captured at `docs/dev-log/evidence/gamma-animal-marginal-simulation-docs-20261024/test-console.log`.
- `knitr::knit("vignettes/julia-engine.Rmd", ...)`: passed.
- `pkgdown::check_pkgdown()`: passed with no problems; Pandoc emitted existing `--mathml` deprecation warnings.
- `git diff --check` on changed source, generated help, guide, inventory and check log: passed.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <absolute report path>`: structure passed; the validator could not run the acceptance ledger because Node or `gate-check` is unavailable, so it reports ledger state UNKNOWN.
- `python3 ~/shinichi-brain/tools/slop_check.py <absolute report path>`: zero findings.
- Source hashes and both candidate HEADs are recorded in `docs/dev-log/evidence/gamma-animal-marginal-simulation-docs-20261024/source-manifest.md`.

## 6. Tests of the Tests

The q1 marginal simulator test reconstructs the seeded response from an independently normalized non-unit-diagonal `A` and public group-SD predictions. The q2 simulator test uses its corrected normalized-correlation oracle; the earlier raw-`A` oracle was shown to disagree with the fitted covariance and is retained as superseded historical evidence. The combined test run confirms both shapes still pass on the recorded current candidates.

## 7a. Issue Ledger

No external issue was searched, opened, or changed. This documentation slice adds no new issue.

## 8. Consistency Audit

The help, generated Rd page, Julia guide, implementation comments and inventory agree on the tested Gamma simulation shapes, Julia covariance normalization and fixed-dispersion restriction. A separate audit found that this Julia normalization conflicts with the programme's raw-kernel multiplier contract and native TMB behavior when `A` has a non-unit diagonal. Native TMB retains raw scale in `R/phylo-utils.R:997-1017`, `R/drmTMB.R:15874-15887`, and `src/drmTMB.cpp:4246-4288`. Julia normalizes in `../general-sd-julia/src/sparse_laplace_glmm.jl:501-521`, called by the Gamma routes in `../general-sd-julia/src/gamma.jl:183-220` and `594-603`; its exposed group SD is returned at `../general-sd-julia/src/gamma.jl:762-775`. The existing Julia constant-SD route also uses normalized `A`, so changing only the predictor-dependent route would violate constant-SD equivalence. The current non-unit parity test encodes the scale conversion in `tests/testthat/test-gamma-animal-q2-nonunit-kernel-parity.R:14-27,57-85`. The executable ledger records partial G4 evidence and leaves G4 open. No programme gate is closed.

## 9. What Did Not Go Smoothly

The brain-level closeout helper resolved a report path outside this package when first invoked. I removed that newly created template and wrote the package report in the repository. The shared structural validator accepts an absolute report path; it passed the document structure but could not determine the ledger state because the required local gate runner is unavailable. The evidence-promotion check also cannot run for this worktree because it has no `memory/evidence-registry.tsv`; no evidence was promoted.

## 10. Known Residuals

This evidence covers two Julia Gamma animal marginal-simulation shapes. It does not establish conditional simulation, other Gamma random-effect types, profile/bootstrap refit integrity for these routes, broad family support, or interval calibration. Non-unit-`A` cross-engine parity remains unresolved: Julia uses normalized correlation while native TMB retains raw kernel scale. Resolving that mismatch must also address the plan's constant-SD equivalence requirement. `pkgdown::check_pkgdown()` passed, but the full package check was not run.

## 11. Team Learning

Memory receipt: the supplied repository instructions and package-specific scope shaped the route limits. `route.py` returned no LOAD-FIRST manifest for this worktree; no additional brain note was loaded during this slice.

Golden Set: not checked; a focused documentation and simulator rerun did not exercise a known-mistake class requiring the Golden Set.

## 12. Cross-Product Coverage

Covers: user-facing R help and the Julia-engine guide for tested Julia Gamma animal q1 intercept and q2 intercept-plus-numeric-slope marginal simulation.

Does NOT cover: other response families, providers, endpoints, structured-effect combinations, native simulation parity, calibrated uncertainty, or overall programme completion.

## Prose Assessment

Style: 2/10, medium confidence; this is a short technical record with specific source and test evidence. Genre/coverage: internal engineering after-task report, read in full. Evidence/repair: Section 2 names the two supported routes and their limits; no change needed. Gates: science = pass for the stated scope against the source and tests; facts = pass against the recorded command output and hashes; references = not applicable because there are no external citations. Provenance: Codex self-review, draft v1, 2026-10-24; relevant source and test output were seen.
