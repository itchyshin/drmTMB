# 2026-11-09 Julia bridge coverage lane (batch D7)

Branch `cursor/julia-coverage-lane-e4fe` from `origin/main` `1e0f545f3ca6a8e6f2198c2e39d435f54a4be614`.

Adds a separate `julia-bridge-coverage` job to `.github/workflows/test-coverage.yaml`:
Julia 1.13, DRModels.jl `main` checkout, `DRMTMB_JULIA_TESTS=true`, covr over
`test-julia-*.R` only via planted `tools/covr-julia-bridge-testthat.R`. Trusted
main artifact `main-coverage-julia-bridge` uploads under Codecov flag
`julia-bridge` (`codecov-upload.yaml`, `codecov.yml` carryforward).

The four R shards are unchanged (still `DRMTMB_TEST_SHARD=k/4`, 180 min each).

Local checks:

```
python3 -m unittest tools/tests/test_codecov_workflow.py -v
```

```
curl -sS -X POST --data-binary @codecov.yml https://codecov.io/validate
```

Live Julia covr on this cloud image: `NOT_RUN` (`Rscript` / Julia toolchain absent
on the agent VM).

Codecov project % before (main `1e0f545`, campaign plan v2): **89.76** overall
(R 89.19, C++ 95.83); Julia-gated lines in `R/julia-bridge.R` largely untested in
the four R-only shards. After: pending first green PR / main producer run.
