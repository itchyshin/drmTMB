# 2026-11-08 Codecov coverage harness repair (PR #1686)

Repair pass on `cursor/codecov-rollout-c9a1` after producer run
[42517999771](https://github.com/itchyshin/drmTMB/actions/runs/42517999771).
No scientific `R/`, `src/`, or `tests/` edits. Source-path guards still run.

## Failure receipts (preserved)

Head `7acb393843a9162d5caec6381986399df3ac53a4`. Tests ran against GitHub PR
merge `e45d4241c6a21a534c957fff8d0d32452358ce20`, not that head.

- Shard 2: `test-guard-branch-continuity.R:204` cannot locate `src/drmTMB.cpp`
  under covr `install_path` (`drmTMB-tests/testthat`).
- Shard 3: `test-docs-audit-semantics.R` cannot locate `man/is_converged.Rd`,
  `man/`, `R/drmTMB.R` via `drm_pkg_path`.
- Shards 1/4: cancelled at 21:32:14Z (`The operation was canceled.`) after the
  90-minute job timeout, still in `Test coverage`. Shards 2/3 spent ~87 min
  (20:04Z–21:31Z) in that step then failed on paths.
- Artifacts: `coverage-test-failures-shard-2` (13635307244), shard-3
  (13634563513). No cobertura. Uploader not reached. No accepted Codecov
  report (`active=false`, commit APIs 404). This is not an auth failure.

R-CMD-check [42517999683](https://github.com/itchyshin/drmTMB/actions/runs/42517999683)
on the same head succeeded.

## Harness change

`tools/covr-source-tree-layout.sh` plants
`<install_path>/00_pkg_src/drmTMB -> $GITHUB_WORKSPACE` before
`covr::package_coverage()`. That is the Unix Rcheck layout
`drm_src_path` / `drm_pkg_path` already walk up to from
`<lib>/drmTMB/drmTMB-tests/testthat`. Assertions are not skipped.

Job timeout is 120 minutes, citing the 87-minute instrumented-shard duration
plus setup and cobertura. Whether 120 minutes is enough for shards 1/4 is
unknown: they had not finished tests at 88 minutes. Not a timeout-only fix.

Identity now prints `checkout_sha` / `coverage_commit`, `github_sha`, and
`branch_head`.

## Local checks

```
python3 -m unittest tools/tests/test_codecov_workflow.py -v
```

```
bash tools/covr-source-tree-layout.sh /tmp/covr-layout-probe .
```

```
curl -sS -X POST --data-binary @codecov.yml https://codecov.io/validate
```

Cloud image has no R; live covr remains GitHub Actions.

Status remains `NOT_VERIFIED`. Upload is still main-only after an
owner-authorized merge. No token or App grant requested.
