# 2026-11-09: parity evidence write-up, wave-8 gap map, 54 disagreements, DRModels.jl #1271

Goal: update `docs/dev-log/parity-crosswalk-evidence-20261107/PROPOSED-verdict-flips.md` and `docs/dev-log/after-task/2026-11-07-julia-q2-sd-feature-work.md` with the wave-8 gap map, the classification of the 54 log-likelihood disagreements and DRModels.jl draft PR #1271.

Commands: `git show origin/claude/gap-map-wave8-20261108:<fuzz-gap-map-wave8>/README.md` and `maps/w8/summary.json` (drmTMB); `git show origin/claude/disagreements-wave8-20261109:docs/dev-log/2026-11-09-wave8-disagreements.md` (DRM.jl, read only); `gh pr view` on DRModels.jl #1261, #1263, #1264, #1266, #1267, #1268, #1270, #1271 for draft and open state and the #1271 description; `python3 ~/shinichi-brain/tools/slop_check.py` on the three prose files.

Results: docs only. No R or Julia fit was run and no branch was checked out or merged. Every number is copied from the files above. Julia suite status is the #1271 description's statement.

Claim boundary: every flip stays PROPOSED and conditional on the Julia stack landing and the pin moving. The Julia-behind count is the wave-8 value (145); wave 9 closed some and was not re-measured. No `R/`, `src/`, `NAMESPACE`, parity matrix, verdict file or test was edited.
