# After Task: Release Start for 0.2.0

## Goal

Start the `drmTMB` release track with a concrete GitHub issue and record the
local evidence that shaped the checklist.

## Implemented

Opened release-start issue
[#342](https://github.com/itchyshin/drmTMB/issues/342) for target version
`0.2.0`, based on current package version `0.1.3.9000`.

## Mathematical Contract

No likelihood, formula grammar, or model contract changed. The release issue
keeps `rho12`, `sigma`, profile-likelihood, and interval wording as release
review gates rather than changing behaviour.

## Files Changed

- `docs/dev-log/after-task/2026-05-27-release-start-0-2-0.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
pwd && git status --short --branch
sed -n '1,80p' DESCRIPTION
sed -n '1,120p' NEWS.md
Rscript -e 'utils::packageVersion("usethis")'
gh repo view --json url,nameWithOwner,viewerPermission,hasIssuesEnabled
gh issue list --search "Release drmTMB in:title" --state open --limit 20 --json number,title,url,labels,createdAt,updatedAt
Rscript /Users/z3437171/.agents/skills/create-release-checklist/scripts/generate_checklist.R 0.2.0 https://github.com/itchyshin/drmTMB
git log --oneline --decorate -5
gh issue create --title "Release drmTMB 0.2.0" --body-file -
```

Outcomes:

- `DESCRIPTION` reports `Package: drmTMB` and `Version: 0.1.3.9000`.
- `usethis` is installed (`3.1.0`).
- GitHub issues are enabled for `itchyshin/drmTMB`, and the authenticated user
  has admin permission.
- No open issue with `Release drmTMB` in the title was found before creating
  the new issue.
- `NEWS.md` is feature-heavy, so the release issue targets a minor release:
  `0.1.3.9000` to `0.2.0`.
- Issue #342 records the dirty-worktree caveat: the current branch has an
  uncommitted Phase 18 truncated-NB2 artifact lane that must be committed,
  split, or parked before release commands such as `git pull`.

## Tests Of The Tests

No package tests were added or changed. This task created release coordination
evidence only, so the test-of-tests check is not applicable.

## Consistency Audit

The release issue includes explicit gates for README, ROADMAP, NEWS, pkgdown,
model-map/source-map pages, reference groups, and profile-likelihood
demonstration consistency. No package source, equations, examples, or generated
site files changed in this task.

## GitHub Issue Maintenance

Searched for existing open release issues before creating a new one. Opened
[#342](https://github.com/itchyshin/drmTMB/issues/342) because no matching
release issue existed.

## What Did Not Go Smoothly

The generated checklist is the generic first-release scaffold. I adapted the
issue body to include `drmTMB`-specific release gates, especially the dirty
worktree warning and the requested profile-likelihood demonstration with
coarse-versus-dense profile timing.

## Team Learning

For release-start tasks, Grace should check prerequisites and GitHub issue
state before any release command, and Rose should record whether the local
worktree is clean enough for release sequencing.

## Known Limitations

No release checks, package tests, `pkgdown`, or CRAN checks were run. The
release is not ready while the current worktree remains dirty.

## Next Actions

Reconcile the current Phase 18 truncated-NB2 artifact worktree, then work
through issue #342 from the top.
