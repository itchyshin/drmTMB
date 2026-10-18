# After-task: rebase open draft PRs onto current main

## Task goal

Rebase the listed open draft PRs in `itchyshin/drmTMB` onto current `main`
`d89db5097`, one at a time, independently (not stacked). Push only to the
existing PR branches. Keep drafts. Do not touch `main` or #1513.

## Files created or changed

Each PR branch was rebased in its own worktree under `/tmp/rebase-NNNN`.
Stale C17 receipt commits were skipped and recertified once per branch that
touches `R/drmTMB.R` or `R/methods.R`. NEWS and check-log conflicts kept both
sides. #1509 kept main's `bootstrap_re_form = NA` from #1487. #1528 kept
main's already-merged #1527 `anova.drmTMB()` and added only the missing NEWS
bullet. #1505's `test-predict-character-predictors.R` was updated so
`y ~ chr + I(x * nchar(chr))` is not rank-deficient.

## Checks run and exact outcomes

C17 recertify (`--tolerance 1e-10`) on every branch that needed it:
worst `|change|` 1.264e-12 on mc-0568 (same float noise as #1500).
`python3 tools/capability_ledger.py --check` passed after each recertify.

Local full `testthat::test_dir()` ran before each push. Later-session tallies
sat in the env-only band of about 81 fail / 213–226 error / 241 skip (Julia
and Suggests). #1505 CI run 39102666708 failed shard 1/4 on the aliased
`chr + nchar(chr)` fixture; the follow-up head is green.

## Consistency audit

- Syntax: `sigma`, `rho12`, `meta_V()`, `bf()` unchanged.
- #1500 still does not claim `Fixes #1484`.
- #1528 uses `Addresses #1240`: the behaviour already landed via #1527.
- #1509 has **no `src/` C++ changes** (C++ TMB reviewer: nothing to review).
- #1505 and #1529 still carry #1504 commits; #1504 itself was not rebased.
- #1513 was not touched.

`rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]"` was not re-run as a
product edit; this campaign only rebased existing branches.

## Tests of the tests

Existing test files were replayed, not rewritten, except #1505's character
predictor fixture (bare + transform without aliasing) and #1528 dropping
`test-anova-drmtmb.R` because it expected `Chi Df` and argument-order
refusal that contradict #1527.

## What did not go smoothly

GitHub `update_pr(draft=true)` is denied on this GitHub-source-of-truth
repo, so #1501, #1506, and #1528 stay non-draft. #1505 needed a second
push after CI caught the rank-deficient predict fixture.

## Team learning

Independent rebases onto `main` are the right shape: stacked #1504 commits
travel with #1505/#1529, and stale C17 commits must be skipped every time
because the hardcoded run-1 directory is on `main`. A character column used
bare and as `nchar(.)` is aliased and now trips the #1505 rank abort.

## Design-doc / pkgdown / GitHub issue maintenance

No design-doc or pkgdown edits beyond what each PR already carried. Issues
were not closed. Closes/Refs lines on recertify and tally commits match each
PR body.

## Known limitations and next actions

Watch remaining CI on the last heads. C++ TMB reviewer should see #1524
(`src/drmTMB.cpp` +60), #1525 (`src/drmTMB.cpp` +16/−4), #1505 via stacked
#1504 (`src/drm_numeric.h`, `src/drm_response_kernels.h`), and #1529
(`src/drmTMB.cpp`, `src/drm_mi_quadrature.h`, `src/drm_numeric.h`,
`src/drm_response_kernels.h`). #1509 has no `src/` diff.
