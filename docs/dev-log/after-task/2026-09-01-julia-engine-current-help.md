# Current Julia-engine help correction

## 1. Goal
Correct the stale exported `drmTMB()` help that described `engine = "julia"` as halted and deferred, while retaining the boundary that only documented routes are admitted.

## 2. Implemented
The engine parameter now states that Julia is an optional current fitting route powered by DRM.jl through JuliaCall, points users to the Julia-engine vignette, and identifies sparse phylogenetic Gaussian location-scale-scale models as one admitted use. The REML paragraph now limits Julia REML to documented Gaussian routes and sends native-control, penalty, model-selection, and unsupported work back to TMB.

## 3. Decisions and rejected alternatives
Do not describe the bridge as universal, equivalent to every native TMB control, or ready for unsupported families. Do not remove current limitations merely to make the documentation shorter. No fitting, likelihood, optimizer, Julia bridge, or public API behaviour changed.

## 4. Files touched
`R/drmTMB.R` and generated `man/drmTMB.Rd`, plus this report and its check-log entry. Documentation generation created unrelated help artefacts; they were restored or removed before commit.

## 5. Checks run
`devtools::document(quiet = TRUE)` completed successfully. `tools::Rd2txt("man/drmTMB.Rd")` confirmed the rendered optional/current Julia wording and documented-Gaussian REML limit. `git diff --check` passed.

## 6. Tests of the checks
The rendering check examined the generated `.Rd`, not only roxygen source. It would expose a failure to regenerate `man/drmTMB.Rd` or a broken roxygen link conversion.

## 7. Issue ledger
This is a bounded documentation correction for the Julia-engine status reported by Ayumi and does not close drmTMB #1108, DRM.jl #569, or the profile/bootstrap evidence work. No collaborator message or issue closure was sent.

## 8. Consistency audit
The new wording matches the current Julia-engine vignette boundary: optional bridge, documented admitted cells, and native TMB for unsupported options. It removes the contradictory claim that the bridge is only retained for inspection.

## 9. What did not go smoothly
The local documentation command regenerated unrelated `confint` and Julia-joint help files. They were tool-created by-products rather than part of this slice and were restored or deleted before the worktree was left clean apart from the intended files.

## 10. Known residuals
The current help cannot establish profile reliability, bootstrap calibration, control-surface parity, route-aware gradient diagnostics, whole-site deployment, or all native-R capability parity. Those remain open under the programme issues and CI gates.

## 11. Team learning
Public reference help is a live user-facing surface and must agree with articles and the working bridge. A future-support label is a factual regression once a documented engine is runnable; scope limits should replace it, not silence it.
