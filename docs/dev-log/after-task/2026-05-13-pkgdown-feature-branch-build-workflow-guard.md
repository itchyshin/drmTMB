# After Task: pkgdown Feature-Branch Build Workflow Guard

## Goal

Make pkgdown useful as a feature-branch check. The workflow should build the
site for a manually dispatched branch run, but it should deploy to GitHub Pages
only from the protected main/master path.

## Implemented

The pkgdown workflow now has two jobs. The `pkgdown` job builds the site and
uploads the Pages artifact without declaring the protected `github-pages`
environment. The new `deploy` job depends on that build and owns the protected
environment, so deployment remains restricted to main/master workflow runs or
manual main/master dispatches.

## Evidence

Manual pkgdown run `25817629476` failed before any build steps because GitHub
rejected deployment from `codex/labelled-covariance-block-design` under the
`github-pages` environment protection rules. This patch keeps feature branches
out of that environment while preserving the deploy path for the default branch.

## Team Roles

Grace diagnosed the GitHub Actions environment boundary. Ada kept the workflow
change narrow. Rose checked that this changes CI routing only, not package code
or website content.

## Scope Boundary

This slice changes the pkgdown workflow only. It does not change the package,
article content, reference index, or site deployment rules for main/master.

## Files Changed

- `.github/workflows/pkgdown.yaml`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-pkgdown-feature-branch-build-workflow-guard.md`

## Checks Run

- `air format .github/workflows/pkgdown.yaml docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-pkgdown-feature-branch-build-workflow-guard.md`:
  passed.
- `ruby -e 'require "yaml"; data = YAML.load_file(".github/workflows/pkgdown.yaml");
  abort("missing jobs") unless data["jobs"] || data[true] || data[:jobs]; puts
  "yaml parsed"'`: passed.
- `git diff --check`: passed.

## Next Actions

1. Commit and push the guard.
2. Dispatch pkgdown again on the feature branch and confirm it reaches the
   build job.
