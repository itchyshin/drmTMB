# 2026-11-08 Codecov producer/OIDC uploader (drmTMB only)

Branched `cursor/codecov-rollout-c9a1` from current `origin/main`
`bfa7acf5bb85e298fe675c5713c34fa208abd860` (merge of #1685). No existing
`codecov.yml`, coverage workflow, or codecov-named branch was present.

Added a covr producer (`.github/workflows/test-coverage.yaml`) that shards
tests with `DRMTMB_TEST_SHARD="k/4"` on ubuntu-24.04 / R-release only, and a
separate main-only uploader (`.github/workflows/codecov-upload.yaml`) using
GitHub OIDC (`codecov/codecov-action@0fb7174895f61a3b6b78fc075e0cd60383518dac`,
CLI `v11.3.2`, `use_oidc: true`). The producer has `contents: read` and no
`id-token`. The uploader grants `id-token: write` only on a successful
same-repo main push of `test-coverage`. No `CODECOV_TOKEN` is read. Existing
R-CMD-check shards are unchanged.

Local R/covr is absent on this cloud image (`command -v Rscript` empty), so
no package coverage percentage was measured here.

Local checks, exact:

```
python3 -m unittest tools/tests/test_codecov_workflow.py -v
```

6 tests, 0.001s, OK.

```
curl -sS -X POST --data-binary @codecov.yml https://codecov.io/validate
```

Response starts `Valid!` and echoes informational project/patch status with
`comment: false`.

PyYAML parsed both workflow files (GitHub's `on:` key round-trips as YAML
`True`, which is the usual Actions quirk; the files on disk still say `on:`).
No actionlint binary.

Live Codecov upload remains `NOT_VERIFIED` until a successful main-branch
producer run after merge, and until Codecov GitHub App access includes
`itchyshin/drmTMB` (the public Codecov org page currently lists pigauto, not
drmTMB).
