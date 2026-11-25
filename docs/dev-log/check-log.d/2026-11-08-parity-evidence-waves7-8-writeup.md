# 2026-11-08: parity evidence write-up, waves 7 and 8 (DRModels.jl #1270)

Goal: update `docs/dev-log/parity-crosswalk-evidence-20261107/PROPOSED-verdict-flips.md` and `docs/dev-log/after-task/2026-11-07-julia-q2-sd-feature-work.md` with what landed in DRModels.jl draft PR #1270 (tip `479bbf963`).

Commands: `gh pr view 1270 --repo itchyshin/DRModels.jl`; `git show origin/claude/wave8-integration-20261108:<path>` for the spatial-kernel audit, the Tweedie structured-SD note, the structured-sigma REML design doc and `docs/src/capabilities.md`; `python3 ~/shinichi-brain/tools/slop_check.py` on both edited files.

Results: docs only. No R or Julia fit was run and no Julia branch was checked out; every number is copied from the PR description or those four files. Julia suite status is the PR's statement.

Claim boundary: all verdict flips stay PROPOSED and conditional on #1270 landing and the pin moving. No `R/`, `src/`, `NAMESPACE`, parity matrix, verdict file or test was edited.
