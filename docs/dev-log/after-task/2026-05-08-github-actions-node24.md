# After Task: GitHub Actions Node 24 Opt-In

## Goal

Remove the GitHub Actions Node.js 20 deprecation warning from the current CI
path before it becomes a failure risk.

## Implemented

- Added `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` to the R-CMD-check workflow.
- Added `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` to the pkgdown workflow.

## Mathematical Contract

Not applicable. This task changed CI runtime configuration only.

## Files Changed

- `.github/workflows/R-CMD-check.yaml`
- `.github/workflows/pkgdown.yaml`
- `docs/dev-log/check-log.md`

## Checks Run

- `git diff --check`: passed.

## Tests Of The Tests

The next push will exercise both workflows on GitHub. No package tests were
rerun locally because no R, C++, package metadata, likelihood, or documentation
source changed.

## Consistency Audit

The change matches the GitHub Actions annotation emitted after the previous
push. It does not alter the package API or modelling behaviour.

## What Did Not Go Smoothly

The warning came from the CI platform rather than package code. It is easy to
miss because all checks still passed.

## Team Learning

Grace-style CI maintenance should stay close to feature work; green checks with
warnings are still useful signals.

## Known Limitations

If an upstream action has a Node.js 24 compatibility bug, CI will reveal it on
the next run and the workflow can be pinned or adjusted.

## Next Actions

Watch the next GitHub Actions run and keep the workflow note if both jobs pass.
