# After Task: Codecov rollout for drmTMB

## Goal

Collect real test coverage for `itchyshin/drmTMB` and prepare a Codecov upload
path using GitHub OIDC, without merging, without a Codecov token, and without
changing scientific code or tests.

## Implemented

Coverage is measured with covr on a dedicated GitHub Actions workflow that
reuses `DRMTMB_TEST_SHARD="k/4"` so the four jobs partition the suite once, on
Ubuntu and R-release only. Upload uses the owner's pigauto pattern: the
producer never holds `id-token: write`; a separate `workflow_run` job on main
downloads the four `cobertura.xml` artifacts and uploads them with
`codecov-action` `use_oidc: true`. Pull-request runs keep the reports as
artifacts. No README badge was added.

## Files touched

`.github/workflows/test-coverage.yaml`, `.github/workflows/codecov-upload.yaml`,
`codecov.yml`, `.Rbuildignore`, `.github/workflows/R-CMD-check.yaml` (wire the
new guard), `tools/tests/test_codecov_workflow.py`, `CONTRIBUTING.md`, this
after-task note, and `docs/dev-log/check-log.d/2026-11-08-codecov-rollout.md`.

## Checks run

`python3 -m unittest tools/tests/test_codecov_workflow.py` and Codecov's public
`/validate` endpoint for `codecov.yml`. This cloud image has no R, so covr was
not run locally. GitHub Actions on the PR is the coverage runner. Live Codecov
publish is main-only by design.

## Limits and next checks

Status is `NOT_VERIFIED` for a live Codecov report. Owner block: grant the
Codecov GitHub App access to public repo `itchyshin/drmTMB` (it already tracks
pigauto). After merge, a successful main `test-coverage` run should fire
`codecov-upload` and attach the report to that commit SHA. No issue was opened;
none matched this CI slice.
