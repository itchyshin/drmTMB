# After Task: Current-source Julia Bernoulli SD bridge rerun

## Goal

Re-run the Bernoulli SD regression bridge suite against the paired dirty drmTMB and DRM.jl candidates to verify current fit and public-output plumbing.

## Implemented

No model code changed. The current candidate passed five live Julia bridge tests with the paired source worktrees.

## Mathematical Contract

This rerun does not alter the model. Bernoulli latent-effect SD predictors remain on the link scale; it does not add a Bernoulli residual SD or establish interval calibration.

## Files Changed

- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/check-log.d/2026-10-20-julia-binomial-sd-current-source-rerun.md`
- `docs/dev-log/after-task/2026-10-20-julia-binomial-sd-current-source-rerun.md`

## Checks Run

The command

`DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "julia-binomial-sd", reporter = "summary")'`

exited 0. Five live Julia tests ran; no tests failed or skipped. The run emitted two singular-Hessian warnings: `rcond=9.23265335367337e-10` with coordinate 7 flagged, and `rcond=3.879150990279055e-17` with no flat coordinate identified. Julia also reported that refits ran serially because its `threads` option defaults to false.

Candidate commits were drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`. Post-run SHA-256 values for `R/julia-bridge.R`, `src/drmTMB.cpp`, and the focused test file are recorded in the paired check-log entry.

`git diff --check` and the prose checker passed. The exact-draft assessment check recorded the report. The project’s `tools/check-after-task.R` is absent from this checkout, so its report-structure validator could not run.

## Tests Of The Tests

The test suite ran through the live Julia bridge rather than the mock-only path: the reporter confirmed five live Julia tests. The tests exercise Bernoulli SD target handling and public bridge outputs. They do not validate coverage.

## Consistency Audit

This was a verification-only rerun. No formula grammar, likelihood, documentation example, or advertised family/effect support changed. The singular-Hessian warnings are retained as a limitation; they prevent treating these fits' Wald standard errors as trustworthy.

## GitHub Issue Maintenance

Read open issues #59 (simulation reporting) and #682 (profile interval calibration). Both remain open and cover broader adjacent work. This bridge rerun resolves neither, so no issue or PR was changed.

## What Did Not Go Smoothly

Two initial attempts skipped because `DRM_JL_PATH` was unset and then pointed at the wrong directory. The worktree listing identified the paired Julia checkout under the drmTMB worktrees directory; the corrected command ran five live tests.

## Team Learning

For a live Julia bridge check, verify the paired checkout path before relying on `DRM_JL_PATH`; a green skip-only test command is not evidence that the Julia engine ran.

## Known Limitations

This run provides current-candidate fit and output evidence only. It does not establish Bernoulli recovery over seeds, calibrated uncertainty, or parity across the required response-family, effect, endpoint, and provider matrix. The Totoro profile qualification in the coordinating task remains in progress, so no new remote fit was started.

## Next Actions

After the coordinating Totoro profile reaches a terminal state and releases the host, continue the bounded source-bound adapter qualification. Keep the 9,000-fit second-look campaign behind its separate runtime and approval gate.
