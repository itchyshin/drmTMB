# Source manifest

Date: 2026-10-23

The test source was run in the R/TMB candidate worktree at commit `425bee81572c625a634b2b083050c5c57c1dc1f1`. The paired Julia source worktree was at commit `70dbf564eb670144c63c08f61ea099084d95add2`.

Command:

```sh
DRMTMB_JULIA_TESTS=true \
DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" \
JULIA_DEPOT_PATH="/private/tmp/drmtmb-julia-depot:/Users/z3437171/.julia" \
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
Rscript -e 'devtools::test(filter = "julia-gamma-phylo-sd-scale", reporter = "summary")'
```

The command exited 0. The filtered test reported 6 assertions and one live Julia bridge test. The full console output, including warnings, is `test-console.log`.

| File | SHA-256 |
|---|---|
| `tests/testthat/test-julia-gamma-phylo-sd-scale.R` | `4e88e294406edf184287023e66018d07e7c8bc63384f8fae640e9e3e3ab25796` |
| `test-console.log` | `1cbe1f2230798b2011c932031716d04e1b107d4006d38cda0f4e9dacb8ed8ae1` |
| R candidate `R/drmTMB.R` | `a8a99c9ea3bcc8af1e824f4a6e71cd62f5d294c9795f5ea88b4ef5713fa80e2b` |
| R candidate `R/julia-bridge.R` | `8330af9e9e53833ecb65f730fe83a859e3a937d55b1248e940a418c2fcfba324` |
| R candidate `src/drmTMB.cpp` | `e42e51c3050bf3c11e000df7966da9ca0db630e5f193ae35f20bc0b40edd8c79` |
| Julia candidate `src/gamma.jl` | `8860be04dae83eea2922d247834ec8fe115f2e0a6c855eb286b7a3169b4c9fd2` |
| Julia candidate `src/sparse_phy.jl` | `7baeea615092f57e9c0d28818eaab02003abebfaf59ae13630ac13db42fcdf48` |
| Julia candidate `Project.toml` | `36b9455e8fcb093e848fe1286432b0ce1c6b9e4e4cafc64e5f460b3818ce1ef9` |
