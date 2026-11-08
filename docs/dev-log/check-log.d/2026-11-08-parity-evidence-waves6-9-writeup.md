# 2026-11-08: parity evidence write-up, waves 6 to 9

Goal: bring `PROPOSED-verdict-flips.md` and the after-task report for the Julia q2 SD work up to date with waves 6 to 9, `fuzz-gap-map/`, `metamorphic/`, `red-team/` and DRModels.jl draft PR #1268 (stacked on #1266). Documentation only on PR #1684's branch.

Commands: read each folder's README; read the #1268 description with `gh pr view 1268 --repo itchyshin/DRModels.jl`; `python3 ~/shinichi-brain/tools/slop_check.py` on both edited files (0 findings, 0 em dashes).

Results: no R or Julia fit was re-run, no test was run, and `R/`, `src/`, `NAMESPACE` and the parity matrix were not touched. Numbers are copied from the folder READMEs. Two figures ("restarts 7 to 10 times slower" from the #1268 description, and "Binomial noise-floor change moves coefficients by up to 0.28" from the task brief) have no source file among the folders and are marked as such.

Claim boundary: all verdict flips stay PROPOSED, conditional on the #1268 stack landing in DRModels.jl main and the Julia pin moving. Agreement is at the optimum, ML, native engines; not calibration or coverage.
