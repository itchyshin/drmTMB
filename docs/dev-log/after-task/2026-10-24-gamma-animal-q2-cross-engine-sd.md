# After Task: Gamma animal intercept and slope SD targets

## 1. Goal

Verify that a Gamma animal term can carry separate predictor-dependent SD formulas for its intercept and numeric slope, with the same synthetic data fitted by native TMB and Julia.

## 2. Implemented

Added truth-based recovery checks to the existing cross-engine fixture and recorded the route in the internal capability inventory. The fixture uses independent latent intercept and slope fields with the same labelled, unit-diagonal relatedness matrix. Each coefficient has its own group-level predictor and log-SD regression.

This is one finite synthetic recovery and output check. It does not establish general Gamma animal support across providers, kernels, datasets, or random coefficient correlations.

## 3. Mathematical Contract

For animal group `g`, the fixture generates `b0[g] = exp(alpha0[0] + alpha0[z0] * z0[g]) * u0[g]` and `b1[g] = exp(alpha1[0] + alpha1[z1] * z1[g]) * u1[g]`, where the independent latent fields `u0` and `u1` each have covariance `A`. The response mean is `exp(0.25 + 0.2*x + b0 + x*b1)`. This tests separate intercept and slope SD targets. It does not test a correlated intercept-slope block.

## 3a. Decisions and Rejected Alternatives

Kept the fixture and inventory wording specific to two independent coefficient fields. Rejected describing it as a correlated q2 block or as broad animal-provider support because the test does not fit coefficient covariance or vary the kernel provider and diagonal.

## 4. Files Touched

- `tests/testthat/test-gamma-animal-q2-cross-engine-sd.R`: added coefficient sign and truth-distance checks for the native estimates.
- `docs/dev-log/general-sd-regression/inventory.md`: recorded the combined-target fixture and its limits for both engines.
- `docs/dev-log/check-log.d/2026-10-24-gamma-animal-q2-cross-engine-sd.md`: exact focused-test result and source identities.
- `LOOP/lanes/general-sd-regression/checkpoint.md`: appended the verified result and next limitations.
- `docs/dev-log/after-task/2026-10-24-gamma-animal-q2-cross-engine-sd.md`: this report.

## 5. Checks Run

- `devtools::test(filter = "gamma-animal-q2-cross-engine-sd", reporter = "summary", stop_on_failure = TRUE)`: passed; 19 expectations, one live Julia bridge fit, exit code 0, 40.4 seconds.
- `git diff --check` on the R bridge, prediction helper, and focused test: passed before this report and inventory edit.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <report>`: structural check passed. It warned that the 13-file acceptance ledger is not runnable in this checkout because Node or `gate-check` is missing; gate state is therefore unknown from that validator.
- `python3 ~/shinichi-brain/tools/slop_check.py <report>`: passed, zero findings.
- Targeted status scan: `rg -n -i 'Gamma.*(animal|slope)|animal.*Gamma|gamma.*animal' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`. It found the existing native-route descriptions; no broad public support wording was added.
- R and Julia source pins: native `425bee81572c625a634b2b083050c5c57c1dc1f1`; paired Julia `70dbf564eb670144c63c08f61ea099084d95add2`.
- Test SHA-256: `1d676f4b12acc3f1e2d73ed3f79107433dba9189343d0615d457a4a510572458`.
- Bridge source SHA-256 values: `R/julia-bridge.R` `231b80e92bb5cf3963d4ce52267238ad9d16c483a2e612c7a1b75a46053c48e1`; `R/predict-parameters.R` `646bb79de06de281a9e522182465c1eb96f9b08489386abb1ed10ceb87b41014`; Julia `src/gamma.jl` `a3065b51bdaae48cd6862274145052c3700829cd1c4ae208dde91b95f88ace19`.

## 6. Tests of the Tests

The fixture uses a fixed seed and checks the native intercept and slope log-SD coefficients against independently specified DGP values, with maximum absolute error below `0.55`. It also checks their expected signs, then requires same-data Julia/TMB coefficient and log-likelihood agreement. This guards against a mean-only fit or dropped target passing solely because both engines agree. The bound applies to this fixture only; it is not a recovery tolerance for a broader domain.

## 7. Design and Documentation Updates

The internal capability inventory now records the exact tested combination. The formula-grammar vignette still describes the combined route as native-only. Its path-level preflight found 46 divergent refs, including active documentation PR #1511, so I left the vignette untouched pending coordination. No equations, public examples, or pkgdown navigation changed.

## 7a. Issue Ledger

Searched open issues with `gh issue list --search 'Gamma animal SD' --state open --limit 10`. No issue matched this combined-target fixture; the returned test-sweep issues were unrelated. No issue was opened, commented on, or closed.

## 8. Consistency Audit

The new inventory wording distinguishes two independent coefficient-specific SD targets from a single correlated q2 block. The model formula and DGP agree on two separate latent fields; no cross-coefficient correlation claim is made. The stale native-only phrase in the vignette is known and intentionally untouched because another active documentation lane owns divergent edits. This limited audit does not establish that all neighboring capability and formula rows are current.

## 9. What Did Not Go Smoothly

The first recorded attempt's process handle had already exited, so its result could not be recovered. The test was rerun; its assertions passed, but a zsh wrapper initially used the reserved variable name `status`, obscuring the shell exit code. A second run through a Bash wrapper completed with exit code 0. Julia's first-call setup consumed most of the 40-second runtime. A whole-worktree `git diff --check` also reported a blank line at EOF in the unrelated `tests/testthat/test-binomial-sd-integration.R`; I left that file untouched.

## 10. Known Residuals

The supplied relatedness matrix has unit diagonal, so this result says nothing about marginal-SD scaling for non-unit kernels. There is one seed and one recovery fixture, no calibrated interval assessment, and no independent likelihood oracle. It does not close a capability-universe row or any programme gate. The paired branches are dirty candidates and are not a release or main-branch claim. The formula-grammar vignette update remains pending a safe handoff or owned docs lane.

## 11. Team Learning

For shell wrappers that capture a command result in zsh, avoid `status`, which is reserved. A focused bridge result should bind the executed test file and both engine source pins; a passing assertion count alone is not enough to identify what was tested.

## 12. Cross-Product Coverage

The same synthetic observations and formulas were fitted through native TMB and the R-to-Julia bridge. Both fits converged. Cross-engine coefficient, likelihood, group-SD prediction, output identity, and save/reload checks passed. This covers one Gamma animal case only. It does NOT cover other families, effects, providers, non-unit kernels, correlated intercept-slope covariance, interval calibration, or the wider simulation/refit/profile workflow.

## Prose Assessment

Style 2/10, medium confidence; genre: internal engineering report; coverage: the complete report draft. The concrete test counts, source pins, and explicit limitations make the report easy to audit; no revision was needed. Science gate: pass for the stated DGP and bounded claim, checked against the test source. Facts gate: pass, checked against the live test output and source hashes. References gate: not applicable; no external references are cited. Provenance: self-review, draft `2026-10-24-gamma-animal-q2-cross-engine-sd.md`, 2026-10-24; prior implementation notes were seen, so this is not an independent review.

## Next Actions

Continue implementation against the frozen family/effect/backend inventory. Prioritize uncovered route combinations and preserve the distinction between independent coefficient-specific fields and correlated blocks. Coordinate ownership before editing the formula-grammar vignette. Keep calibrated uncertainty, NotebookLM methods review, Totoro/DRAC evidence, and the remaining programme gates open.
