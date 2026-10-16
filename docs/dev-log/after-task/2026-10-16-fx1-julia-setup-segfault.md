# After Task: FX1 JuliaCall setup SIGSEGV (exit 139)

Reader: the next Engine A agent running a bridge sweep, and Shinichi when
scoring the 16 Oct 2026 DRM lane. Purpose: record why `engine = "julia"`
killed R on official Julia 1.12.x, what drmTMB now does before
`JuliaCall::julia_setup()`, and what a remaining host crash looks like.

## Goal

Stop the t5/t7 blocker: `drmTMB(..., engine = "julia")` exited 139 during
JuliaCall `install_dependency.jl` / first fit on official Julia 1.12.7
(t5) and 1.12.6 (t7). Standalone `julia --project=DRModels.jl` on the same
pin fitted.

## Implemented

`drm_julia_setup()` now prepares the host, then wraps `julia_setup()`:

1. Unset `JULIA_PROJECT`. JuliaCall's `install_dependency.jl` runs
   `Pkg.add("RCall")` in the active project. Sweep t5 exported
   `JULIA_PROJECT=/tmp/DRModels.jl`, so that helper compiled RCall into the
   checkout and crashed. The supported setting remains `DRMODELS_JL_PATH`;
   drmTMB still `Pkg.activate`s that path after JuliaCall starts.
2. Default `JULIA_NUM_THREADS=1` when unset. Julia 1.12's default thread
   count has crashed other embeddings (PythonCall#748). A user who already
   set the variable keeps it (needed before the first Julia call for later
   threaded refits).
3. On Linux, locate official Julia's `lib/julia/libunwind.so*` and both
   `dyn.load` it (`local = FALSE`) and prepend it to `LD_PRELOAD`. CRAN
   JuliaCall 0.17.6 does not yet carry JuliaCall#238; master JuliaCall does.
   The apt R wrapper puts `/usr/lib/x86_64-linux-gnu` on `LD_LIBRARY_PATH`,
   so a child `julia install_dependency.jl` otherwise loads system
   libunwind 1.6.2 and SIGSEGVs (exit 139). conda-forge Julia on the same
   t5 host returned Gaussian bridge fits; the official tarball did not.
4. Rewrite a catchable 139 / `install_dependency.jl` error as classed
   `drmTMB_julia_host_setup_error` with the next step. An in-process
   SIGSEGV (t7's first-fit death after a successful setup) still cannot be
   caught; the preload is what prevents that one.

Joint, cross-family, and structured Julia routes all enter
`drm_julia_setup()`, so one host prep covers those sibling engines. Native
`engine = "tmb"` is unchanged. `R/drmTMB.R`, `R/methods.R`,
`R/mi-weights.R`, and `src/` were not edited; C17 was not recertified.

## Mathematical Contract

None. This is host-library loading, not a likelihood or formula change.

## Files Changed

- `R/julia-bridge.R` — `drm_julia_bindir()`, `drm_julia_libunwind_path()`,
  `drm_julia_prepare_host()`, `drm_julia_setup_failed()`, and the setup
  call site.
- `tests/testthat/test-julia-host-prepare.R` — red-proof plus libunwind
  `LD_PRELOAD` and classed-error tests.
- `tests/testthat/test-julia-tmb-parity.R` — treat the classed 139 as an
  absent-environment skip, not a code regression.
- `NEWS.md`, `vignettes/julia-engine.Rmd`,
  `docs/dev-log/known-limitations.md`, this report, and
  `docs/dev-log/check-log.md`.

## Checks Run

Red-proof on `pkgload::load_all()` against pin `ca3ddef` (test added, helpers
absent): `test-julia-host-prepare.R` FAIL 7 / PASS 1. The FX1 expectation
saw `JULIA_PROJECT=/tmp/DRModels.jl-pin` and empty `JULIA_NUM_THREADS` at
the mocked `julia_setup()` call.

After the helpers: the same file FAIL 0 / PASS 13.

Sibling setup paths, same load_all:

- `test-julia-module-compat.R` — all mock-driven assertions pass; live
  stacked-checkout test skipped (`DRMTMB_JULIA_TESTS` unset).
- `test-julia-batch-startup.R` — 7 pass.
- `test-julia-home-path.R` — 7 pass.
- `test-cran-lane-filter.R` — CRAN abort still fires before JuliaCall;
  one `drm_skip_live_julia()` row skipped (no DRModels.jl on this host).

Live official Julia 1.12.7 tarball on this same Ubuntu 24.04 / R 4.3.3 /
JuliaCall 0.17.6 host, with the apt R wrapper's
`LD_LIBRARY_PATH=/usr/lib/R/lib:/usr/lib/x86_64-linux-gnu`:

- `julia -e 'print(VERSION)'` exit 0 (isolated Julia is fine).
- `julia install_dependency.jl /usr/lib/R` without preload: **exit 139**
  (twice: default depot and `JULIA_PROJECT` empty project).
- Same helper with `LD_PRELOAD` on Julia's `libunwind.so.8`: passed
  `Pkg.add("RCall")` (timeout 90 s later during precompile, exit 124,
  not 139).
- `drm_julia_prepare_host()` then `JuliaCall::julia_setup()` with
  `JULIA_PROJECT` initially set to `/tmp/DRModels.jl`: project cleared,
  `libunwind` preloaded, `julia_eval("1+1")` is 2, R exit 0.

Same `pkgload::load_all()` core batch: host-prepare 13 pass; module-compat
57 pass / 1 skip; batch-startup 7 pass; home-path 7 pass; cran-lane 32
pass / 1 skip; native `test-gaussian-location-scale.R` 80 pass;
`test-release-identity.R` 20 pass. MASS on this R 4.3.3 is unavailable
from current CRAN (needs R >= 4.4).

## Tests Of The Tests

The FX1 test failed on the unfixed `drm_julia_setup()` with the exact
values the sweep would have handed JuliaCall (`JULIA_PROJECT` still set,
threads unset). After the fix those values are cleared at the
`julia_setup()` boundary. A second test builds a fake
`<prefix>/lib/julia/libunwind.so.8` and checks `LD_PRELOAD` without
needing a real `.so`. A third test feeds the t5 `status 139` string into
`drm_julia_setup_failed()` and checks the classed abort; a non-139 error
is rethrown unchanged.

## Consistency Audit

```sh
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]|meta_known_V\\(V = V\\).*(current|preferred|stable|default)" \
  R/julia-bridge.R tests/testthat/test-julia-host-prepare.R NEWS.md \
  vignettes/julia-engine.Rmd docs/dev-log/known-limitations.md
rg "JULIA_PROJECT|libunwind|install_dependency|status 139" \
  R/julia-bridge.R tests/testthat/test-julia-host-prepare.R NEWS.md \
  vignettes/julia-engine.Rmd docs/dev-log/known-limitations.md
```

No new `meta_gaussian` / `tau ~` / `rho ~` wording. `JULIA_PROJECT`,
`libunwind`, and exit 139 are described the same way in the bridge, the
test, NEWS, the vignette, and known limitations. Terms `sigma` and
`rho12` were not touched.

## GitHub Issue Maintenance

Sweep t5/t7 could not file the new segfault issue (GitHub writes 403).
This change Refs those receipts and JuliaCall#238. It is not #1157 (that
one prints a recovered Julia `ERROR` and continues). Related historical
context: N5 on Totoro abandoned `JuliaCall::julia_setup()` SIGSEGV
(`docs/dev-log/after-task/2026-09-03-true-parity-night.md`). No issue was
commented from this host.

## What Did Not Go Smoothly

This cloud snapshot had no R or Julia at boot. R 4.3.3 and TMB were
installed here to run the red-proof. Official Julia 1.12.7 was not
installed in time for a live `install_dependency.jl` replay; the
behavioral test is the recorded red/green pair. An in-process SIGSEGV
after a successful setup (t7) cannot be turned into a testthat failure
in the same R process.

## Team Learning

Sweep harnesses should set `DRMODELS_JL_PATH`, not `JULIA_PROJECT`. The
latter is Julia's project for every child `julia` that JuliaCall spawns,
including `install_dependency.jl`. Record that in the next sweep rules
so t5-style env blocks do not reappear.

## Known Limitations

The preload cannot replace `LD_PRELOAD` set before R starts if system
libunwind is already mapped into the R process. Users who still see 139
should start R with Julia's `libunwind.so.8` preloaded, or use
conda-forge Julia. This does not fix DRModels.jl missing-data or weights
gaps (#1089, #1450) that t5 also recorded.

## Next Actions

Re-run one unweighted `engine = "julia"` Gaussian fit on the t5/t7 host
(official 1.12.7, `DRMODELS_JL_PATH` set, `JULIA_PROJECT` unset) to
confirm the live 139 is gone. Then the blocked bridge cells can be
re-scored.
