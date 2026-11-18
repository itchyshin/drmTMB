# Corrected Gamma animal simulation source manifest

Candidate drmTMB HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1` (dirty working tree).

Paired DRM.jl candidate HEAD: `70dbf564eb670144c63c08f61ea099084d95add2` (dirty working tree).

Focused command:

```sh
DRM_JL_PATH="$PWD/../general-sd-julia" \
DRM_JL_JULIA_HOME="/Users/z3437171/.juliaup/bin" \
PATH="/Users/z3437171/.juliaup/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
Rscript -e 'devtools::test(filter = "gamma-animal-q2", reporter = "summary", stop_on_failure = TRUE)'
```

The run passed three live Julia bridge tests. Hashes identify the tested working-tree files, not an immutable release artifact.

| File | SHA-256 |
|---|---|
| `R/julia-simulate.R` | `7dfd99c1defe409d6a96866e8a5f5b48247f182d6c2a5476be07e30a471510cd` |
| `tests/testthat/test-gamma-animal-q2-nonunit-kernel-simulation.R` | `ab2093f04490aae5db5c9839ff4698fff2e8643bc38d5e44065d6c22cfe1589c` |
| `tests/testthat/test-gamma-animal-q2-nonunit-kernel-parity.R` | `59c17ff0d6c544cb7691a4c1ed235a36c1bfc0b6b5016e6cb362f97bd21f9577` |
| paired `src/gamma.jl` | `a3065b51bdaae48cd6862274145052c3700829cd1c4ae208dde91b95f88ace19` |
| paired `src/sparse_laplace_glmm.jl` | `cc1d5354ad8758ef3fb5e3e9cba1ba14cc1bfaadde101ffb626e96b243bc325b` |
| `docs/dev-log/general-sd-regression/inventory.md` | `b5d14cbb9df80620f787a0ee787481747a4baa02abb6428af9cda8aa71afc72d` |
| `test-console.log` | `fe43ed0477c20df035602f3312fff5e8e895e8f7244980d82d287ed28d972f42` |
