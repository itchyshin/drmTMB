# Check log: Gamma animal slope-only cross-engine parity

The focused same-data comparison passed on the current candidate source. It covers one Gamma location model with `animal(0 + x | id, A = A)`, a group-level SD formula, and a unit-diagonal supplied covariance. It does not cover animal intercept-plus-slope blocks or non-unit covariance scaling.

Command:

```sh
DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
DRM_JULIA_TESTS=true NOT_CRAN=true \
DRM_JL_JULIA_HOME='/Users/z3437171/.juliaup/bin' \
DRM_JL_JULIA_DEPOT='/private/tmp/general-sd-julia-depot-20261022-parity:/Users/z3437171/.julia' \
JULIA_DEPOT_PATH='/private/tmp/general-sd-julia-depot-20261022-parity:/Users/z3437171/.julia' \
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
Rscript --vanilla -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-julia-gamma-sd.R", desc = "live Julia Gamma animal slope SD estimates agree with native TMB", package = "drmTMB", reporter = "summary")'
```

Result: the selected live Julia bridge test completed successfully. Test output ended with `══ DONE ══` and `Julia bridge: 1 live test ran; bridge glue was exercised in this configuration.` The test compares convergence, coefficient names, positive SD slopes, coefficient estimates and group-level SD predictions across engines, then checks Julia rowwise SD predictions against fitted group SD values.

Source binding at completion:

| Source | SHA-256 |
|---|---|
| Native `R/julia-bridge.R` | `2979326696d6310fc48a289b21b54b84a7aefb1f7edd44aa4fc5aab14e129870` |
| Native `tests/testthat/test-julia-gamma-sd.R` | `ad061946d1ccaaf8e7e2a03db419e37c93eec2c866c0840a4b40c7529ee42c63` |
| Julia `src/bridge.jl` | `4e24fb1a352327108b4c435180a817ad97675fc9b11a5cf9be13a78ba592bbb2` |
| Julia `src/gamma.jl` | `405003bc6cdc0bb3c8826c14f5127c5f9964e92337d4024d9ce3c2a9f5838fea` |

Candidate commits were native `425bee81572c625a634b2b083050c5c57c1dc1f1` and Julia `70dbf564eb670144c63c08f61ea099084d95add2`; both worktrees also contain uncommitted changes. This is one slope-only parity fixture, not a capability-row promotion, likelihood or uncertainty parity claim, or general engine-parity result. The broad required row describes a structured intercept plus slope and remains open.

The refreshed 198-file source manifest and exact console-log hash are in `docs/dev-log/general-sd-regression/evidence/gamma-animal-slope-parity-20261022/source-manifest-animal-slope.json`. This manifest binds the native/Julia source set and the saved console log to the candidate HEADs above.
