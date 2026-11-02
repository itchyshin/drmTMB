# Current-source manifest

Date: 2026-10-23

R candidate branch and HEAD: `codex/general-sd-regression`, `425bee81572c625a634b2b083050c5c57c1dc1f1`.

Julia candidate branch and HEAD: `codex/general-sd-regression`, `70dbf564eb670144c63c08f61ea099084d95add2`.

Command:

```sh
PATH='/Users/z3437171/.juliaup/bin':"$PATH" \
DRMTMB_JULIA_TESTS=true \
DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
JULIA_DEPOT_PATH='/private/tmp/drmtmb-julia-depot:/Users/z3437171/.julia' \
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
TMPDIR=/tmp/codex-gamma-phylo-scale \
Rscript -e "devtools::test(filter = 'julia-gamma-phylo-sd-scale', reporter = 'summary')"
```

Outcome: exit code 0; 6 assertions passed; 1 live Julia bridge test ran. The Julia model emitted its expected raw-branch-length-scale warning for maximum tree height 6.404475. Full output is retained in `test-console.log`.

SHA-256:

| File | SHA-256 |
|---|---|
| `R/drmTMB.R` | `2114394bb74528a003e5f699c515bfda12be1822401b4d066db6d19ef2f628cd` |
| `R/julia-bridge.R` | `fa20e95c7fa8fc615418aea90726f7414bd710385d24b312c69af7dee48dc0bc` |
| `src/drmTMB.cpp` | `bf4b30d9cb2774133b51b3f183d2b454933cbb9a47ae6450d187f8b08169fc19` |
| `tests/testthat/test-julia-gamma-phylo-sd-scale.R` | `4e88e294406edf184287023e66018d07e7c8bc63384f8fae640e9e3e3ab25796` |
| Julia `src/gamma.jl` | `a3065b51bdaae48cd6862274145052c3700829cd1c4ae208dde91b95f88ace19` |
| Julia `src/sparse_phy.jl` | `7baeea615092f57e9c0d28818eaab02003abebfaf59ae13630ac13db42fcdf48` |
| Julia `Project.toml` | `36b9455e8fcb093e848fe1286432b0ce1c6b9e4e4cafc64e5f460b3818ce1ef9` |
| `test-console.log` | `fec8f2b0572ad221b3060c8059d966c0ebea659987cdb8570dce878a97f54c06` |

This rerun replaces no earlier evidence. It records a new source pin because the previous receipt's R and Julia implementation hashes do not match the current candidates. No product source or test file was changed in this rerun.
