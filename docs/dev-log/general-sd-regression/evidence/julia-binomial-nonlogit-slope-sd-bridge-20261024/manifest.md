# Julia Binomial non-logit SD slope evidence

The opt-in test command exited 0 with 27 passing expectations. It exercises
probit and complementary log-log slope models on the same independent seeded
datasets in native TMB and paired DRM.jl. The assertions cover convergence,
positive and near-truth SD-predictor slopes, agreement between engines, and
increasing predicted group SDs. The console's generic footer says no live
Julia tests ran, but the log records Julia startup and 20 post-startup
expectations; the runner's counter does not track this filtered test.

The preceding live failure is preserved as
`console-label-marshalling-failure.log`. DRM.jl reported target
`sdtarget_69647c6969647c6d757c787c6e6f6e65`, while R incorrectly sent labels
under `sd`. The pure payload test reproduces that mismatch before the fix.

The broader pure bridge filter exited 0. Three live checks were skipped
because the paired DRM.jl path was not supplied to that separate command; two
existing `beta()` deprecation warnings were emitted. The focused live run above
did use the paired path. `pkgdown::check_pkgdown()`, R parsing, and scoped
`git diff --check` exited 0.

Test command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
DRMTMB_JULIA_TESTS=true \
DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
PATH='/Users/z3437171/.juliaup/bin':$PATH \
Rscript -e 'devtools::test(filter = "julia-binomial-nonlogit-slope-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'
```

Source SHA-256 values:

| File | SHA-256 |
|---|---|
| `R/julia-bridge.R` | `69a22c5a056b40e8f57f5512f376841c8667b6e01dc533ac4129c95b2c705ca4` |
| `tests/testthat/test-julia-binomial-nonlogit-slope-sd-bridge.R` | `f7f180eda9c0ce9ed5de8241b47ca5103c06955d399874c704d7543c6405498b` |
| `NEWS.md` | `c369455a5026b5f56df5be228b8b11edad001c51a12eabad45303f50e87b45f0` |
| `vignettes/julia-engine.Rmd` | `a2949b335fe9821439e86efdfcb60c14bd92f4d731b4eeca9b891719263f627c` |
| `vignettes/formula-grammar.Rmd` | `d0a83a55ae730b54f27ce6c640e73fb38bae130ac2a692a0faca6ed7d9432931` |
| `docs/design/01-formula-grammar.md` | `2e0f46d4d2cf1e65d5637bf6a32b32db9c103a49d2b4bb57a8d5d3905488c58b` |

These are fixed-seed point-recovery checks. The engines use different
integration approximations. They do not establish general Binomial parity or
interval-coverage calibration.
