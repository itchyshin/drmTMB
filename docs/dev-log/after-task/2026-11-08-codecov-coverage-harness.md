# After Task: Codecov coverage harness repair

## Goal

Repair the PR #1686 coverage producer so covr's installed-package test tree
can satisfy existing source-path guards, and so job timeout matches measured
instrumented-shard duration, without changing scientific code or tests.

## Implemented

The producer plants the Unix Rcheck layout `00_pkg_src/drmTMB` at the covr
library root (`tools/covr-source-tree-layout.sh`) so `drm_src_path` and
`drm_pkg_path` resolve `src/drmTMB.cpp`, `R/drmTMB.R`, and
`man/is_converged.Rd` from `<lib>/drmTMB/drmTMB-tests/testthat`. Those
assertions still run. Coverage identity records checkout SHA (the GitHub PR
merge on `pull_request` events), `GITHUB_SHA`, and branch head separately.
Job timeout is 120 minutes, citing run 42517999771 (~87 minutes of
instrumented tests in shards 2/3; shards 1/4 cancelled at 90 minutes). Upload
remains main-only; this PR cannot upload before an owner-authorized merge.

## Files created or changed

`.github/workflows/test-coverage.yaml`, `tools/covr-source-tree-layout.sh`,
`tools/tests/test_codecov_workflow.py`, `CONTRIBUTING.md`,
`docs/dev-log/check-log.d/2026-11-08-codecov-coverage-harness.md`, this
after-task note.

## Checks run and exact outcomes

Local `python3 -m unittest tools/tests/test_codecov_workflow.py` and a
filesystem plant of `00_pkg_src` against this checkout. Codecov YAML
`/validate`. No local R/covr. Live producer is GitHub Actions on this branch.

## Consistency audit

No formula-grammar, likelihood, family, or user-facing modelling change.
`CONTRIBUTING.md` now states the `00_pkg_src` plant, SHA fields, and
main-only upload. The earlier after-task
`2026-11-08-codecov-rollout.md` asked for a Codecov App grant; that request
is withdrawn here: drmTMB is already GitHub-linked on Codecov and inactive
because no report has been accepted, not because an uploader auth failure
was observed.

```
rg "CODECOV_TOKEN|skip_on_covr|pull_request_target" .github tools CONTRIBUTING.md
rg "00_pkg_src|checkout_sha|branch_head" .github/workflows/test-coverage.yaml tools CONTRIBUTING.md
```

## Tests of the tests

The new layout unittest plants the locator walk-up from a fake covr
`testthat` cwd and requires `src/drmTMB.cpp`, `R/drmTMB.R`, and
`man/is_converged.Rd`. The workflow guard still fails closed if OIDC or a
Codecov token appears in the producer.

## What did not go smoothly

Run 42517999771 was first described as testing head `7acb39384`; the
producer `git rev-parse HEAD` was merge `e45d4241`. Shards 1/4 duration is
still unknown. Raising timeout to 120 minutes is evidenced as necessary
versus 90 minutes, not proven sufficient.

## Team learning and process improvements

Record checkout SHA and branch head on every coverage run. Do not request
Codecov App or token access without an actual uploader authentication
failure. Do not treat a 90-minute cancellation as a hang when sibling shards
completed the suite.

## Design-doc updates

None. Coverage harness only.

## pkgdown/documentation updates

`CONTRIBUTING.md` Test coverage paragraph only. No badge.

## GitHub issue maintenance

No issue opened or commented. Work stays on PR #1686.

## Known limitations and next actions

Status is `NOT_VERIFIED`. Remaining blockers: live producer must emit
`cobertura.xml` on this repair SHA; shards 1/4 may still exceed 120 minutes;
Codecov accepts a report only after an owner-authorized merge puts
`codecov-upload.yaml` on default-branch main and a successful main producer
run fires OIDC upload. CI follow-up should report evidence only and request
the coordinator before further coding.
