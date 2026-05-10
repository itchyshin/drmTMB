# After Task: GitHub Actions Node 24 Hygiene

## Goal

Remove the Node.js 20 deprecation annotations from otherwise green GitHub
Actions runs by moving first-party GitHub actions to current Node 24 releases.

## Implemented

- Updated `actions/checkout` from `v4` to `v6.0.2` in both workflows.
- Updated GitHub Pages actions in `pkgdown.yaml`:
  `actions/configure-pages@v6.0.0`,
  `actions/upload-pages-artifact@v5.0.0`, and
  `actions/deploy-pages@v5.0.0`.
- Removed `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` because the selected action
  versions already use Node 24 or composite actions.

## Mathematical Contract

No package code, statistical model, likelihood, documentation article, or R
interface changed.

## Files Changed

- `.github/workflows/R-CMD-check.yaml`
- `.github/workflows/pkgdown.yaml`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-github-actions-node24-hygiene.md`

## Checks Run

- GitHub API release checks confirmed latest tags:
  `actions/checkout@v6.0.2`, `actions/configure-pages@v6.0.0`,
  `actions/upload-pages-artifact@v5.0.0`, and
  `actions/deploy-pages@v5.0.0`.
- GitHub API action-file checks confirmed the selected first-party actions use
  Node 24 or composite actions.
- `ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "ok #{f}" }' .github/workflows/R-CMD-check.yaml .github/workflows/pkgdown.yaml`:
  passed.
- Workflow version scan:
  passed and found the updated action tags plus historical check-log mentions.
- `git diff --check`: passed.

## Tests Of The Tests

The meaningful test is the next pushed GitHub Actions run: R-CMD-check should
still run on macOS, Ubuntu, and Windows, and pkgdown should still deploy after a
successful check.

## Consistency Audit

The workflows still use the same triggers, permissions, concurrency groups, R
setup actions, package dependency actions, and pkgdown deploy steps. Only the
first-party GitHub action versions and the now-unneeded Node 24 forcing
environment variable changed.

## What Did Not Go Smoothly

The warning appeared on successful runs, so it was easy to ignore. Treating CI
annotations as quality feedback keeps the workflow healthier before warnings
become failures.

## Team Learning

Grace should audit green CI annotations, not only red jobs. A green run with
repeated deprecation annotations is still asking for maintenance.

## Known Limitations

This has to be validated by the next pushed GitHub Actions run.

## Next Actions

- Watch the next R-CMD-check and pkgdown runs.
- If a first-party action tag changes behaviour, revert that action alone and
  record the exact failure.
