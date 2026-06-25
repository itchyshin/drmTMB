# After Task: q-series PR stack merge-readiness

## 1. Goal

Bank a reviewable merge-readiness snapshot for the current q-series draft PR
stack before adding more runtime coverage or compute slices.

## 2. Implemented

Added `structured-re-pr-stack-merge-readiness.tsv` as a 15-row dashboard ledger
for PR #639 through #653. The ledger records merge order, base/head refs, head
SHAs, draft state, merge-clean state, commit-level R-CMD-check run IDs, the
PR-rollup caveat for stacked branches, and the next merge gate.

Added `tools/plan-structured-re-pr-stack-merge-readiness.R`, which writes the
dashboard snapshot, an artifact copy, and a one-row run log. The script defaults
to dry-run and refuses non-dry-run modes.

Mission-control validation and the structured RE dashboard tests now check the
stack order, draft policy, check evidence, retargeting rule, and conservative
claim boundary.

## 3a. Decisions and Rejected Alternatives

The slice records commit-level check evidence instead of treating empty
`gh pr checks` output on stacked bases as failure. This matches GitHub's current
surface: PR #639 has attached green checks against `main`, while #640 through
#653 have green check runs on their head commits but need ordinary PR checks
after retargeting.

I did not merge, undraft, or retarget the stack. That remains a maintainer
approval gate because each layer changes the base of the next PR.

## 4. Files Touched

- `tools/plan-structured-re-pr-stack-merge-readiness.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-pr-stack-merge-readiness.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-pr-stack-merge-readiness/structured-re-pr-stack-merge-readiness-snapshot.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-pr-stack-merge-readiness/structured-re-pr-stack-merge-readiness-run-log.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-pr-stack-merge-readiness.md`

## 5. Checks Run

- `gh pr list --repo itchyshin/drmTMB --state open --json number,title,isDraft,headRefName,baseRefName,mergeStateStatus,headRefOid,url,statusCheckRollup --limit 40` showed PR #639 through #653 draft and `CLEAN`.
- `gh api repos/itchyshin/drmTMB/commits/<sha>/check-runs` for the 15 head SHAs found three successful platform R-CMD-check jobs per head.
- `Rscript --vanilla tools/plan-structured-re-pr-stack-merge-readiness.R --mode=execute` failed closed with `Only --mode=dry-run is supported by this stack-readiness planner.`
- `air format tools/plan-structured-re-pr-stack-merge-readiness.R tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `Rscript --vanilla tools/plan-structured-re-pr-stack-merge-readiness.R` wrote 15 PR stack merge-readiness rows and the artifact snapshot/run log.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 15 structured RE PR stack merge-readiness rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"` passed with 4,539 assertions, 0 failures, 0 warnings, and 0 skips.
- `git diff --check` passed.
- `gh issue list --repo itchyshin/drmTMB --search "q-series PR stack merge-readiness" --limit 20 --json number,title,state,url,labels` returned `[]`.
- The stale-wording scan for PR-stack merge, coverage, REML, AI-REML, Totoro/DRAC submission, and SR150 overclaims found only conservative boundary wording or historical/check-log records.

## 6. Tests of the Tests

The new test checks exact PR order, base/head chaining, draft status, merge-clean
status, the #639 PR-rollup exception, the stacked-branch PR-rollup caveat, the
three-platform check status, the retargeting rule, and overclaim guard phrases.
Changing a PR number, base ref, run ID, draft status, or claim boundary should
fail the focused dashboard test and mission-control validation.

## 7a. Issue Ledger

No GitHub issue was opened or updated. This is a narrow stack-control slice for
the existing draft q-series PR lane.

## 8. Consistency Audit

The dashboard README and q-series completion map now describe the same rule as
the validator: green commit-level checks on a stacked head do not replace normal
PR checks after retargeting to `main`.

The claim boundary keeps merge, undraft, Totoro, DRAC, denominator, coverage,
interval, REML, AI-REML, bridge, public support, and SR150 readiness unpromoted.

## 9. What Did Not Go Smoothly

`gh pr checks` reported no checks for the stacked branches even though the head
commits had successful R-CMD-check runs. The ledger now records this GitHub
surface explicitly so later agents do not misread empty PR rollups as either a
failure or a full normal-PR green state.

## 10. Known Residuals

The stack is still draft and unmerged. After maintainer approval, merge from
PR #639 upward, retarget the next PR to `main`, rerun ordinary PR checks, and
rerun mission-control validation after each layer lands.

No Totoro or DRAC execution was submitted, and no coverage-evaluable denominator
or MCSE-calibrated coverage evidence was created.

## 11. Team Learning

Long q-series stacks need their own support-control ledger. A clean merge state
and green head-commit checks are useful evidence, but they are not the same as
a landed stack with refreshed PR checks on `main`.
