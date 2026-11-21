# After Task: R-Julia parity lane, documentation close-out, 2026-11-10

Reader: Shinichi, or the next session that continues the parity lane. This is the lane's report as written for the drmTMB record (draft PR #1690). It covers the Julia side only as far as the R-side documents need. The lane's own files (STATUS, decision cards, sublane reports) live outside this repository, in `~/grokbot-lanes/parity-drm-1110/`.

## 1. Goal

Bring the R-side record of the Julia parity work up to date on the #1690 branch: say what is on DRModels.jl main, what is still draft, which gap-map numbers are settled and from which tree, and keep every parity verdict flip marked PROPOSED.

## 2. Implemented

Documentation only. No `R/`, `src/`, `tests/`, `man/` or `NAMESPACE` file was touched.

- The handover `docs/dev-log/handover/2026-11-09-julia-parity-final-state.md` now opens with the state on 10 November: the merged PRs with merge commits, one line per remaining draft with the owner question it waits on, the gap-map numbers by tree, and a "What is not verified" section. The 9 November text below it is kept and marked historical.
- `docs/dev-log/2026-11-09-parity-matrix-proposed-flips.md` has a rewritten numbers section. The old "integrated tip" figures are marked superseded.
- Facts read on 10 November with `gh pr view` (DRModels.jl main `e7d5ddee1b5d`): #1294 merged at 19:27 CST as `e7d5ddee1`; the wave stack #1261 to #1272 is merged; #1290 is closed; #1299 is open but contained in main; #1293 is a draft retargeted to main; lane drafts #1305 to #1321 (except #1310 and #1315, which are stacked on #1293 work) are open drafts that target the integration branch.

## 3a. Decisions and Rejected Alternatives

- Gap-map numbers are given by tree (A: `78b571496`, the #1294 branch before main was merged in; B: all lane drafts merged together, not on main). No number is presented as "main", because no map was run on `e7d5ddee1`. Rejected: quoting the 9 November coordinator figure (357 agree, 17 R-only), because the original #1294 description says 10 R-only for the same tree and I could not reconcile them.
- The 9 November text was kept and marked historical instead of deleted, so the review order stays auditable. Rejected: rewriting the whole handover.
- Assumptions made without asking:
  - The question each draft waits on is my reading of the lane's `DECISIONS-PENDING.md`. For #1305, #1309 and #1312 the file names no question of their own; the handover says so. If that is wrong, the "Question" column changes.
  - Per-PR merge commits are the ones GitHub reports. The lane STATUS file names fewer commits for the inner stack PRs (`f600e090e`, `ed90ae2ea`) because it counts merges inside #1268 and #1272. Both are listed in the handover text.

## 4. Files Touched

- `docs/dev-log/handover/2026-11-09-julia-parity-final-state.md` (edited)
- `docs/dev-log/2026-11-09-parity-matrix-proposed-flips.md` (edited)
- `docs/dev-log/after-task/2026-11-10-r-julia-parity-lane.md` (new, this report)
- `docs/dev-log/check-log.d/2026-11-10-parity-docs-close-out.md` (new)

## 5. Checks Run

- `gh pr view` on DRModels.jl #1261 to #1321 (state, base, head, merge commit) and drmTMB #1684, #1687, #1688, #1690: all read as stated in the handover.
- `gh pr checks 1293` at 19:38 CST: `docs` failed, four test shards pending. The cause was not read.
- `python3 ~/shinichi-brain/tools/slop_check.py` on the handover, the flips note and this report: 0 findings reported (a few pattern hits in text that was already there or is quoted wording; the em-dash count is 0).
- `Rscript ~/shinichi-brain/tools/check-after-task.R` on this report: see the final line of this section.
- Nothing was run on Totoro. No R or Julia code was run. No R CMD check, test or pkgdown build was run (docs only; the repository's CI for docs-only changes was not reproduced locally beyond the checks above).

## 6. Tests of the Tests

Not applicable: no code or test changed. The only mechanical checks are the slop checker and the after-task validator. Their ability to catch a fault was not tested here.

## 7a. Issue Ledger

- Fixed: the handover and the flips note said the Julia stack was unmerged and #1294 was a draft.
- Found, deferred: the gap-map figure for R-only cells is 17 in one source and 10 in another (open).
- Found, deferred: the `docs` check on DRModels.jl #1293 failed at 19:38 CST (cause not read; the lane watches it).
- Open owner questions that gate this PR's content: P4 (verdict flips). Others are named per draft in the handover.

## 8. Consistency Audit

- Searched the PR's docs diff for "draft", "unmerged", "not merged" and "#1294". Only the two files above and the evidence copies (raw outputs, unchanged by design) matched; the evidence copies are not edited.
- Checked that no flip was applied: no verdict file, parity matrix or `tools/write-parity-matrix.R` is in the diff of this lane's commits.
- The PR #1690 body was rewritten separately (outside this repository) to match these facts.

## 9. What Did Not Go Smoothly

- GitHub and the lane STATUS file disagree on some merge commits because several PRs were folded in by merge rather than merged one at a time. GitHub still shows #1273 to #1283, #1291 and #1292 as open although their content is on main.
- The 17 versus 10 R-only discrepancy above.
- The clock in the brief (19:50 CST) was ahead of the machine (19:38 CST), so "as of" times in the documents use the time I actually read GitHub.

## 10. Known Residuals

Stated in full in "What is not verified" in the handover. In short:

- The full suite on Julia 1.10.12 was not run at the final head of several drafts.
- GitHub CI does not run on drafts that target the integration branch.
- The P10 boundary cell (`binomial|corr|lab0|q2|sd-last`) fails by 1.8e-4 on Julia 1.13.3 and decides whether #1293 can merge unchanged.
- No gap map exists for main at `e7d5ddee1`.
- The bridge (R calling Julia) was not exercised for any new route.

## 11. Team Learning

When a stack lands by merge-folding, GitHub keeps showing the folded PRs as open. Check the merge target for the content before writing "unmerged". When two sources give different counts for one tree, report both and say which one is used and why.

## 12. Cross-Product Coverage

This lane touched the engine pair (Julia DRModels.jl against R drmTMB 0.8.1) and the estimator flag REML.

- Covers: log-likelihood and point estimates at the optimum for cells where both engines fit, on Julia 1.10.12, in the gap maps.
- Engine pair does NOT cover: standard errors (compared only in some PRs), the R-to-Julia bridge, Julia 1.12.7 for the combined tree, and cells where R itself does not converge.
- REML does NOT cover non-Gaussian families beyond Poisson (Julia-only Cox-Reid) and Binomial (drmTMB-only, diagnostic). `meta_V` plus `(1 | g)` with weights under REML is not measured.
- Parity-matrix verdicts do NOT cover anything yet: no flip is applied until P4 is answered and the pin moves.
