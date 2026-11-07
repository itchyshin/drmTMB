# After Task: Julia selected SD target bridge

## 1. Goal

Carry one explicitly selected ordinary random-effect SD formula through the R-to-Julia bridge while retaining the same target for fitting, coefficient extraction, SD prediction, and native-engine comparison across Beta, Gamma, NB2, and Poisson.

## 2. Implemented

The R payload now labels a sole ordinary SD target with the stable `sd` block used by DRM.jl, while retaining hash-derived identities for multiple ordinary SD targets. The post-fit bridge resolves that stable block for both block-list and flat coefficient representations, and maps it back to the formula's canonical selected target for public extraction and prediction. The paired tests exercise selected intercept and slope targets and compare native TMB and Julia where both are available.

## 3a. Decisions and Rejected Alternatives

- Preserve the existing single-target `sd` block contract; do not add a second modelling interface or change multi-target hash identities.
- Use the parsed formula dpar label for public selection in tests instead of assuming every selected term is named `sd(id)`.
- Assumption: one ordinary SD formula is represented by `sd`, even when its target descriptor carries explicit `coef` metadata. If DRM.jl changes that public contract, the payload label and target resolver must be revised together.

## 4. Files Touched

- `../general-sd-julia/src/bridge.jl`
- `R/julia-bridge.R`
- `tests/testthat/test-julia-beta-sd.R`
- `tests/testthat/test-julia-gamma-sd.R`
- `tests/testthat/test-julia-negbinomial-sd.R`
- `tests/testthat/test-julia-poisson-sd.R`
- `docs/dev-log/check-log.d/2026-10-18-julia-selected-sd-bridge.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-18-julia-selected-sd-bridge.md`

## 5. Checks Run

`DRMTMB_JULIA_TESTS=true DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" JULIA_DEPOT_PATH="/private/tmp/drm-julia-depot:$HOME/.julia" OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=2 Rscript -e 'devtools::test(filter = "julia-(beta|gamma|negbinomial|poisson)-sd")'` passed 73 assertions across six live bridge tests. Two non-fatal warnings report existing deprecated `beta()` calls during bridge family-label discovery. The Poisson-only rerun passed 23 assertions with no warnings. `git diff --check` passed. The package's `tools/closeout.py` and `tools/check-after-task.R` are absent from this worktree, so automated report validation was unavailable.

## 6. Tests of the Tests

The first live attempt failed because the bridge sent an internal hashed target where DRM.jl exposed `sd`. After the block alias was corrected, the next attempt failed during R-side prediction because its resolver assumed a coefficient-list representation. The resolver now handles the flat coefficient vector too. The final combined run exercises both native/Julia agreement and public fit, prediction, extraction, and save/reload checks. Thus the tests observed both defects before the repairs.

## 7a. Issue Ledger

The read-only open-issue search for `selected SD Julia bridge` returned only an unrelated q4 Gaussian REML issue (#555). No issue was changed; no matching open issue was found.

## 8. Consistency Audit

Checked the R payload label builder, Julia formula-to-block mapping, coefficient label validation, post-fit SD prediction, canonical dpar aliases, and the four paired family tests. The one-target contract is consistent across these paths. No user-facing formula grammar or likelihood equation changed, so no design grammar or likelihood document changed. The project-wide status inventory was not updated by this bridge repair; this slice does not widen the advertised family/effect support.

Exact inventory search used: `rg -n -i 'beta.{0,40}sd|sd.{0,40}beta|Julia.*SD|SD.*Julia' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`.

## 9. What Did Not Go Smoothly

The first fix handled coefficient echo but not the R-side coefficient-label coverage check. The second revealed that post-fit prediction receives a flat named coefficient vector rather than the original block list. The separate Beta, Gamma, and NB2 cases passed before the combined rerun exposed the Poisson test's assumption that TMB coefficient names were available to derive its dpar label.

## 10. Known Residuals

The tests emit two deprecated `beta()` warnings from family-label discovery. The broader Julia test suite, full R suite, package check, documentation build, uncertainty calibration, and other family/effect combinations were not run here. The bridge tests establish selected-target workflow and point-estimate parity for the tested cells, not calibrated uncertainty or general support.

## 11. Team Learning

When a bridge accepts both block-list and flat coefficient representations, target resolution must be tested after object construction as well as during raw coefficient echo. A single-target public alias also needs matching payload labels, prediction lookup, and formula-level reverse mapping. The repository route helper reported that no LOAD-FIRST manifest exists for this checkout, so no routed brain notes were available; the Golden Set was not run because this slice did not exercise a known-mistake fixture.

## 12. Cross-Product Coverage

- Selected ordinary SD target, single target per formula: R-to-Julia fitting, coefficient extraction, group and row SD prediction, and RDS round-trip are covered for the tested Beta, Gamma, NB2, and Poisson cells.
- Native TMB versus Julia point-estimate comparison: covered for selected Beta, Gamma, NB2, and Poisson cells represented by the paired tests.
- Multiple SD targets in one formula: retains hash-derived block naming but does NOT cover the newly edited one-target alias path as a newly tested capability.
- Bernoulli, other response families, structured effects, cross-parameter blocks, bivariate routes, profiles, bootstrap calibration, and full package checks: does NOT cover these surfaces.

The next action is to continue the remaining family/effect matrix and its independent recovery and uncertainty evidence; this bridge slice does not complete the overarching SD-regression goal.
