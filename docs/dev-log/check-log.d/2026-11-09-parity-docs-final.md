# 2026-11-09: parity documentation integration, handover and proposed flips

Goal: put the docs-only material of four DRModels.jl branches (gap map wave 10, gap map v2, wave-8 disagreements, non-Gaussian REML memo) into drmTMB, with a final-state handover and a note of proposed parity-matrix flips.

Commands: `git archive` of the tip commit file lists of `claude/gap-map-wave10-20261109`, `claude/gap-map-v2-20261109`, `claude/disagreements-wave8-20261109` and `claude/reml-nongauss-memo-20261109` from a DRModels.jl clone; `gh pr view` on DRModels.jl #1261 to #1287 and drmTMB #1684, #1687, #1688; `python3 ~/shinichi-brain/tools/slop_check.py` on the two new prose files (0 findings).

Results: docs only. No R or Julia code was run and nothing was run on Totoro. Copied files are unchanged from their tip commits.

Claim boundary: every flip in the proposed-flips note is PROPOSED and conditional on the Julia pull requests merging, the pin moving and a separate reviewed pull request. No `R/`, `src/`, `NAMESPACE`, parity matrix, verdict file or test was edited.
