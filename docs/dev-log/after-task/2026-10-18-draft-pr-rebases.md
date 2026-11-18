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
bullet.

## Checks run and exact outcomes

C17 recertify (`--tolerance 1e-10`) on every branch that needed it:
worst `|change|` 1.264e-12 on mc-0568 (same float noise as #1500).
`python3 tools/capability_ledger.py --check` passed after each recertify.
#1506 `capability_ledger.py --check` passed without recertify.

Local full `testthat::test_dir()` is required before each push. Results are
recorded per PR in `docs/dev-log/check-log.md` and in this campaign report.

## Consistency audit

- Syntax: `sigma`, `rho12`, `meta_V()`, `bf()` unchanged.
- #1500 still does not claim `Fixes #1484`.
- #1528 uses `Refs`/`Addresses` semantics: #1240 already landed via #1527.
- #1509 has **no `src/` C++ changes** (flag for the C++ TMB reviewer: none).
- #1505 and #1529 still carry #1504 commits; #1504 itself was not rebased.
- #1513 was not touched.

## Tests of the tests

Existing test files were replayed, not rewritten, except #1528 dropped
`test-anova-drmtmb.R` because it expected `Chi Df` and argument-order
refusal that contradict #1527.

## What did not go smoothly

GitHub `update_pull_request(draft=true)` was denied by the token, so #1501,
#1506, and #1528 could not be converted back to draft from here. #1500 CI
was still in progress when later rebases were prepared.

## Team learning

Independent rebases onto `main` are the right shape: stacked #1504 commits
travel with #1505/#1529, and stale C17 commits must be skipped every time
because the hardcoded run-1 directory is on `main`.

## Design-doc / pkgdown / GitHub issue maintenance

No design-doc or pkgdown edits beyond what each PR already carried. Issues
were not closed. Closes/Refs lines on recertify commits match each PR body.

## Known limitations and next actions

Watch CI on each force-pushed head. #1509 needs no C++ review. #1524,
#1525, #1505 (via #1504), and #1529 do change `src/` and should go to the
C++ TMB reviewer after CI.

## Additions carried from the #1530 branch copy

- #1505's `test-predict-character-predictors.R` was updated so
  `y ~ chr + I(x * nchar(chr))` is not rank-deficient. A character column used
  bare and as `nchar(.)` is aliased and now trips the #1505 rank abort.
- #1505 CI run 39102666708 failed shard 1/4 on the aliased
  `chr + nchar(chr)` fixture; the follow-up head is green.
- Later-session full-suite tallies sat in the env-only band of about 81 fail,
  213 to 226 error, 241 skip (Julia and Suggests).
- GitHub draft conversion was denied, so #1501, #1506, and #1528 stay
  non-draft; #1505 needed a second push after CI caught the fixture.
