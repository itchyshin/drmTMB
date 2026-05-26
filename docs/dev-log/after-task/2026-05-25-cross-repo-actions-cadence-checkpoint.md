# After Task: Cross-Repo Actions Cadence Checkpoint

## Goal

Resume after the stream failure, compare the current `drmTMB` branch with the
local `gllvmTMB` and `symbolizer` GitHub Actions habits, and turn the result
into a concrete next-step rule for Phase 18 work.

## Implemented

Ada treated this as process recovery, not model work. A recovery checkpoint was
written at
`docs/dev-log/recovery-checkpoints/2026-05-25-070721-codex-checkpoint.md`.
Jason compared the sister repositories, Grace checked the current Actions and
PR state, Curie kept simulation dispatch separate from package checks, and Rose
recorded the workflow lesson in the team-improvement ledger. No spawned
subagents were running.

Ada then pushed the two already committed branch changes onto a fresh remote
branch, opened draft PR #324, and manually dispatched `R-CMD-check` on that
pushed ref. The manual remote run
<https://github.com/itchyshin/drmTMB/actions/runs/26402265076> passed on
Ubuntu, macOS, and Windows.

The current `drmTMB` branch
`codex/non-gaussian-q1-planning-1-10` is ahead of its remote by two commits and
has a broad dirty tree. The latest local Phase 18 proportion artifact note says
focused tests and workflow-YAML parsing passed, but those uncommitted changes
cannot be checked by GitHub Actions until they are staged, committed, pushed,
and opened as a PR or manually dispatched from a pushed ref.

## Cross-Repo Evidence

`drmTMB` has the needed infrastructure. The repository has three workflows:
`R-CMD-check`, `pkgdown`, and `Phase 18 simulation grid`. The latest visible
`R-CMD-check` and `pkgdown` runs on `main` succeeded on 2026-05-24 after PR
#323. The latest visible manual Phase 18 simulation-grid runs also succeeded on
`main` on 2026-05-24. There was no open `drmTMB` PR at resume time, so the
current local branch was outside the PR-check loop until draft PR #324 and the
manual `R-CMD-check` dispatch were created.

`gllvmTMB` is currently using the healthier package-check rhythm. PR #257,
`Add identifiability diagnostics to check_gllvmTMB`, is open and has successful
Ubuntu, macOS, and Windows `R-CMD-check` jobs from 2026-05-25. Recent merged
work also shows the expected sequence: PR check, push to `main`, then `pkgdown`
through `workflow_run`.

`symbolizer` is using a lighter publication rhythm. It has no open PR, has a
dirty local `main`, and recent successful `pkgdown` plus Pages deployments on
2026-05-25. That is useful for small site-forward release work, but it is not
the right default for `drmTMB` implementation or simulation-infrastructure
slices because it does not put the current branch under multi-platform PR
checks.

## Team Decision

The transfer from `gllvmTMB` is behavioral, not architectural: split broad work
into reviewable branches or PRs early enough that GitHub Actions can fail in
public. The transfer from `symbolizer` is narrower: after a branch is green and
merged, keep pkgdown and Pages evidence visible rather than treating local
rendering as the only proof.

For the current Phase 18 lane, the next safe move is:

1. Split the broad dirty tree into the smallest reviewable lanes.
2. Stage and commit one lane at a time.
3. Push the branch and open or update a PR.
4. Wait for `R-CMD-check` on the PR.
5. Dispatch `phase18-simulation-grid.yaml` on the pushed ref only for lanes
   that change Phase 18 runner behavior or need remote artifact evidence.

Do not run more local-only implementation before putting the finished
proportion lane back into the Actions loop.

## Actions Follow-Through

- Created branch `codex/nb2-poisson-structured-gates-actions`.
- Pushed the branch to origin.
- Opened draft PR #324:
  <https://github.com/itchyshin/drmTMB/pull/324>.
- Manually dispatched `R-CMD-check` on the pushed ref:
  <https://github.com/itchyshin/drmTMB/actions/runs/26402265076>.
- Remote `R-CMD-check` passed on:
  - Ubuntu in 11m42s.
  - macOS in 12m23s.
  - Windows in 14m37s.

GitHub still marks draft PR #324 as merge-conflicted against `main`. A
temporary merge check found conflicts in:

- `.github/workflows/phase18-simulation-grid.yaml`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_write_poisson_phylo_q1_grid.R`
- `pkgdown/extra.css`
- `vignettes/source-map.Rmd`

Those conflicts were inspected in `/tmp/drmTMB-pr324-mergecheck`; the main
dirty worktree was not used for conflict resolution.

## Files Changed

- `docs/dev-log/after-task/2026-05-25-cross-repo-actions-cadence-checkpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`

## Checks Run

```sh
git status --short --branch
git diff --stat
tail -n 120 docs/dev-log/check-log.md
sed -n '1,160p' docs/dev-log/after-task/2026-05-25-phase18-proportion-fixed-effect-artifacts-slices-1289-1298.md
sed -n '1,220p' .github/workflows/phase18-simulation-grid.yaml
gh pr list --repo itchyshin/drmTMB --state open --json number,title,headRefName,baseRefName,url,statusCheckRollup
gh run list --repo itchyshin/drmTMB --limit 10 --json databaseId,displayTitle,event,headBranch,headSha,status,conclusion,workflowName,createdAt,url
gh run list --repo itchyshin/drmTMB --workflow R-CMD-check.yaml --limit 8 --json databaseId,displayTitle,event,headBranch,headSha,status,conclusion,workflowName,createdAt,url
gh run list --repo itchyshin/drmTMB --workflow pkgdown.yaml --limit 8 --json databaseId,displayTitle,event,headBranch,headSha,status,conclusion,workflowName,createdAt,url
git status --short --branch
rg --files .github/workflows
gh pr list --repo itchyshin/gllvmTMB --state open --json number,title,headRefName,baseRefName,url,statusCheckRollup
gh run list --repo itchyshin/gllvmTMB --limit 10 --json databaseId,displayTitle,event,headBranch,headSha,status,conclusion,workflowName,createdAt,url
gh pr list --repo itchyshin/symbolizer --state open --json number,title,headRefName,baseRefName,url,statusCheckRollup
gh run list --repo itchyshin/symbolizer --limit 10 --json databaseId,displayTitle,event,headBranch,headSha,status,conclusion,workflowName,createdAt,url
Rscript tools/codex-checkpoint.R --goal "resume Phase 18 proportion artifact lane and cross-repo Actions cadence" --next "record the cross-repo Actions cadence lesson, then split/stage the Phase 18 dirty tree into reviewable PRs"
git switch -c codex/nb2-poisson-structured-gates-actions
git push -u origin codex/nb2-poisson-structured-gates-actions
gh pr create --draft --repo itchyshin/drmTMB --base main --head codex/nb2-poisson-structured-gates-actions --title "Consolidate NB2 and Poisson structured gates"
gh workflow run R-CMD-check.yaml --repo itchyshin/drmTMB --ref codex/nb2-poisson-structured-gates-actions
gh run watch 26402265076 --repo itchyshin/drmTMB --exit-status --interval 20
git worktree add --detach /tmp/drmTMB-pr324-mergecheck origin/codex/nb2-poisson-structured-gates-actions
git merge --no-commit --no-ff origin/main
```

## Tests Of The Tests

No package test was needed for this process note. The current proportion
after-task report already records the focused local tests that passed for the
finished artifact lane. The new point is that local tests are not a substitute
for a pushed branch, PR checks, and targeted manual Phase 18 dispatch when the
runner surface changes.

## Known Limitations

Draft PR #324 is open and the manual remote `R-CMD-check` run passed, but the
PR is still draft and merge-conflicted against `main`. No manual Phase 18
simulation-grid run was started for the uncommitted proportion lane. The working
tree is still broad and must be split before staging the newer local work.

## Next Actions

Resolve or supersede the PR #324 merge conflicts before treating those committed
NB2/Poisson changes as merge-ready. Then start with the fixed-effect proportion
artifact lane because it already has a fresh after-task report, focused local
tests, a workflow-YAML parse, and stale wording scan. Stage that lane
deliberately, rerun the focused tests if any file changed since the report,
push the branch, open or update a PR, and let GitHub Actions remain the shared
gate.
