# Slices 87-88 PR Stack And Drift Scan

Date: 2026-05-16

## Scope

Slices 87 and 88 were release-flow and consistency slices, not modelling
slices.

- Slice 87 landed the prerequisite Phase 6 profile-inference gate and retargeted
  the Phase 10-13 closure pull request.
- Slice 88 scanned the retargeted branch for status drift across roadmap,
  tutorial, NEWS, reference, known-limitations, and rendered pkgdown surfaces.

## Actions

- Merged PR #45, "Close Phase 6 profile inference gate", into `main` with a
  merge commit so the Phase 6 gate commit remains an ancestor of the Phase
  10-13 branch.
- Retargeted PR #46, "Close Phase 10-13 foundations", from
  `codex/slice-60-phase-6-gate` to `main`.
- Marked PR #46 ready for review after the retarget because the branch was clean
  and the manual stacked-branch `R-CMD-check` had already passed on Ubuntu,
  macOS, and Windows.
- Ran drift scans for stale implementation/planned wording around coordinate
  spatial effects, phylogenetic slopes, q=4 derived intervals, mesh/SPDE,
  structured `rho12`, and richer spatial paths.

## Review Notes

- Ada: The PR stack is now in the intended order: #45 is merged, and #46 is a
  direct PR to `main`.
- Grace: The normal `main`-base PR check should be the remaining CI gate for
  #46. The earlier manual workflow-dispatch run remains useful supporting
  evidence but is not a substitute for the normal PR check.
- Noether: The drift scan did not find a status contradiction. The hits were
  expected planned-boundary text for mesh/SPDE, multiple spatial slopes,
  phylogenetic slopes, q=4 derived intervals, spatial `sigma`, bivariate spatial
  covariance, and structured `rho12`.
- Rose: The next work should not add more feature content to #46 unless CI or
  review finds a defect. After #46 lands, the next clean branch should start
  Slice 89 or the next tutorial-quality batch.

## Checks

- `gh pr view 45 --repo itchyshin/drmTMB --json number,state,closed,closedAt,mergedAt,mergedBy,mergeCommit,url,title`
- `gh pr edit 46 --repo itchyshin/drmTMB --base main`
- `gh pr ready 46 --repo itchyshin/drmTMB`
- `git fetch origin main --prune`
- `git merge-base --is-ancestor 1468cdc47efc16f108153fa2a602729b1b41dd6f origin/main`
- `gh pr diff 46 --repo itchyshin/drmTMB --name-only`
- targeted `rg` stale-status scans over `README.md`, `ROADMAP.md`, `NEWS.md`,
  `R`, `docs/design`, `docs/dev-log/known-limitations.md`, `vignettes`, `man`,
  and `pkgdown-site`
- `git diff --check origin/main...HEAD`

## Remaining Gate

PR #46 still needs the normal GitHub Actions `pull_request` check against
`main` after this trace commit synchronizes the branch.
