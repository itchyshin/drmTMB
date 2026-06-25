# After Task: PR stack merge-readiness extension

## 1. Goal

Extend the q-series merge-readiness ledger so the stack-control evidence covers
draft PR #654 and draft PR #655 after their three-platform R-CMD-check runs
turned green.

## 2. Implemented

Added PR #654 and PR #655 to
`docs/dev-log/dashboard/structured-re-pr-stack-merge-readiness.tsv` and to the
mirrored artifact snapshot under
`docs/dev-log/simulation-artifacts/2026-06-25-pr-stack-merge-readiness/`.

Updated the run log from 15 stack rows ending at PR #653 to 17 stack rows ending
at PR #655. Updated `tools/validate-mission-control.py` so validation now
expects the two additional draft PR rows, their head refs, head SHAs, run IDs,
stacked-base merge order, and conservative claim boundary.

Updated `tools/plan-structured-re-pr-stack-merge-readiness.R` so rerunning the
dry-run generator reproduces the 17-row dashboard and artifact files instead of
restoring the earlier 15-row snapshot.

## 3a. Decisions and Rejected Alternatives

I did not undraft, merge, retarget, or submit any compute job. The useful slice
was to keep the merge-readiness source of truth synchronized after two more
stacked draft PRs landed green.

I also did not convert commit-level stacked checks into ordinary PR-attached
checks. The ledger still requires each successor PR to retarget to `main` and
rerun normal PR checks after the previous layer lands.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-pr-stack-merge-readiness.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-pr-stack-merge-readiness/structured-re-pr-stack-merge-readiness-snapshot.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-pr-stack-merge-readiness/structured-re-pr-stack-merge-readiness-run-log.tsv`
- `tools/plan-structured-re-pr-stack-merge-readiness.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-pr-stack-merge-readiness-extension.md`

## 5. Checks Run

- `git status --short --branch` showed the active branch
  `codex/q2-plus-q2-sigma-rejection-contract`.
- `git diff --check` passed.
- `gh run view 28168795112 --repo itchyshin/drmTMB --json status,conclusion,url,jobs`
  returned `conclusion = success`.
- `gh run view 28170403815 --repo itchyshin/drmTMB --json status,conclusion,url,jobs`
  returned `conclusion = success`.
- `gh pr view 654 --repo itchyshin/drmTMB --json title,isDraft,headRefOid,mergeStateStatus,url,baseRefName,headRefName`
  showed draft, `CLEAN`, and head
  `f540fc711f558aeb2829f2d739d50401931ebcf0`.
- `gh pr view 655 --repo itchyshin/drmTMB --json title,isDraft,headRefOid,mergeStateStatus,url,baseRefName,headRefName`
  showed draft, `CLEAN`, and head
  `691bad99956bf593732395be88bc1269c76f37fc`.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `Rscript --vanilla tools/plan-structured-re-pr-stack-merge-readiness.R --mode=dry-run`
  passed and wrote 17 PR stack merge-readiness rows.
- `python3 tools/validate-mission-control.py` passed and reported 17
  structured RE PR stack merge-readiness rows.

## 6. Tests of the Tests

The mission-control validator now fails if PR #654 or #655 is missing from the
ledger, has the wrong base/head ref, wrong head SHA, wrong R-CMD-check run ID,
wrong merge order, non-draft status, non-clean merge state, or a weakened claim
boundary.

## 7a. Issue Ledger

No GitHub issue was opened or updated. This is stack bookkeeping for the
existing q-series completion lane, not a new user-facing feature.

## 8. Consistency Audit

The generator, dashboard TSV, artifact snapshot, run log, and validator all
agree on 17 rows with PR #655 as the last PR. The dashboard README, design
note, and check log no longer stop at PR #653.

## 9. What Did Not Go Smoothly

The first after-task report draft used generic section names from the skill
template. The local after-task checker requires numbered drmTMB section names,
so the report was rewritten to match the repository contract.

## 10. Known Residuals

The stack remains draft and unmerged. PR #640 through PR #655 still need to
retarget to `main` and rerun normal PR checks after their predecessors land.
This slice does not submit Totoro or DRAC jobs, create coverage-evaluable
denominator evidence, promote MCSE-calibrated coverage, interval reliability,
q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, non-Gaussian REML,
AI-REML, broad bridge support, public support, SR150 readiness, or an
Ayumi-facing reply.

## 11. Team Learning

If a stack-readiness PR is followed by more stacked slices, the readiness ledger
must be extended before the next merge/retarget pass. Otherwise the dashboard
truth lags behind the actual draft PR stack.
