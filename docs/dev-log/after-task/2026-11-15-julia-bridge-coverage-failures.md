# After task: Julia bridge coverage failures on PR #1691

Reader: a drmTMB contributor deciding whether the `julia-bridge-coverage` job can merge. The lane is the `ubuntu-24.04 (release) julia-bridge coverage` job in run 43747439251 (job 132913824133), head `9e35ed873`, DRModels.jl pin `5b005e0ffbc017e427f3c050f7ef45b38ff990ce` (`tools/ci-drmjl-ref`). That pin is the merge of DRModels.jl #1390 (Train 2, 2026-11-15). The job checked the checkout out to that sha. This note does not change the pin.

testthat reported `FAIL 24 | WARN 32 | SKIP 15 | PASS 3715`. The R-CMD-check shard 1/4 (75-minute timeout) and the coverage shard 1/4 (3-hour timeout) also failed. Those two are the known shard imbalance. They are not among the 24, and this change does not touch them.

## What was fixed

Group (a), one harness bug. `callr::r()` uses `user_profile = "project"`, so each child sources `tests/testthat/.Rprofile`. The coverage runner plants that file, and it `sys.source()`s `tools/ci-juliacall-coverage.Rprofile`. With `DRMTMB_JULIA_TESTS=true` and `DRMTMB_COVR_INSTALL_LIB` set, the profile did `assign(".drmtmb_covr_load_all_orig", orig, envir = asNamespace("pkgload"))`. A package namespace is locked, so that assign raises `cannot add bindings to a locked environment`. In a non-interactive child that error is `Execution halted` before callr writes a result file. callr then reports `could not start R, exited with non-zero status, has crashed or was killed`. The parent test process is `R CMD` with `--vanilla`, so it never sources the planted profile, and the in-process Julia tests still ran.

The originals of `pkgload::load_all` and `testthat::test_path` now live in `.drmtmb_covr_box` in the global environment. Replacing the existing `load_all` and `test_path` bindings is unchanged. Local check: a callr child under the planted profile returns `1L`, `testthat::test_path("..", "..")` is `DRMTMB_COVR_PKG_ROOT`, and `pkgload::load_all` on that root reaches `library(drmTMB)` instead of aborting at startup (`tools/tests/test_codecov_workflow.py`, `test_julia_profile_does_not_abort_callr_child`). This VM has no Julia 1.13 / DRModels checkout, so the live assertions inside those children were not re-run. A child that now starts can still fail for a group (b) or (c) reason that the crash was hiding.

`test-julia-workflow-g.R` also warns `sh: 1: Syntax error: "(" unexpected` (11 times, one per slug). `base::system2()` pastes arguments without quoting, so `julia -e print(Sys.BINDIR)` is illegal `sh` when `stderr = FALSE`. That probe runs only when `DRM_JL_JULIA_HOME` and `JULIA_HOME` are empty. The job leaves both empty on purpose and puts the Julia binary on `PATH`. The warning is not itself one of the 24 failures. The workflow-g failure row below was the callr crash. The probe stays in the test file; this change does not edit tests.

## Classification

| Failure | Group | Why |
| --- | --- | --- |
| `test-julia-inference.R:701`, `:811`, `:834`, `:919` | (a) fixed here | callr child aborted in the planted profile. The confint/bootstrap assertions never ran. |
| `test-julia-phylo-count.R:171` | (a) fixed here | Same callr startup abort (`drm_phylo_count_fit`). |
| `test-julia-phylo-nongaussian.R:295`, `:328` | (a) fixed here | Same callr startup abort (Gamma and Binomial phylo fits). |
| `test-julia-q2-phylo-point-export.R:75` | (a) fixed here | Same callr startup abort. |
| `test-julia-structured.R:507`, `:535` | (a) fixed here | Same callr startup abort (Poisson relmat and labelled-K Gaussian logLik). |
| `test-julia-workflow-g.R:402` | (a) fixed here | All 11 slugs are the same callr startup abort. The `julia -e print(Sys.BINDIR)` shell warning is separate and remains. |
| `test-julia-slope-nongaussian.R:118`–`:121` | (a) fixed here | `expect_s3_class(cnd, "error")` passed. The four `grepl` checks failed because the message was the callr crash, not `cannot fit a random slope` from `drm_julia_refuse_marker_slope_unsupported()`. The refusal itself was not reached. |
| `test-julia-binomial-animal-q2-oracle-b31ja.R:165` | (c) remains | Julia `_bridge_echo_coef_labels` (`DRModels.jl/src/bridge.jl:2486` at the pin): `coef_labels` names dpar `recov`, and the fitted model dpars are `mu` plus two `sdtarget_<hex>` blocks. R sends `recov` from `drm_julia_ordinary_binomial_recov_label()` for a Binomial animal intercept-plus-slope. The pin does not have that dpar. |
| `test-julia-diagnostics.R:233` | (c) remains | The fit ran. `fj$bridge$gradient` and `fj$diagnostics$gradient` were null (those `expect_null` lines did not fail). `drm_julia_gradient_source()` then aborted because the payload's gradient source was `forward` with no gradient vector. The test comment expected the older pin `430ef64c` behaviour: no gradient and no `grad_source`, reported as a route note. |
| `test-julia-gamma-animal-intercept-simulation.R:47`, `:63` | (b) remains | The Julia fit converged. `predict(fit, dpar = "sd_animal(id)")` returned names `animal_01` … `animal_28`. `drm_julia_predict_sd()` builds `sd_animal(id):animal_01`, then `predict.drmTMB_julia()` strips that prefix (`R/julia-bridge.R` around the `substring(output_names, ...)` block). `simulate()` requires the prefixed names and aborts with `Julia Gamma SD predictions do not align with animal groups for NA` (`target_coef` is missing on that component). This is the R predict/simulate contract, not the pin. |
| `test-julia-binomial-phylo-oracle-b31jb.R:81` | neither; remains | Stack is `b31jb_oracle()` in `tests/testthat/helper-b31jb-oracle.R`, on a sign-flipped alpha inside the bug-gap check: `b31jb Laplace mode exceeded 200 iterations`. Julia is not on the stack. Not the bridge, and not DRModels at the pin. The iteration cap is in the test helper. This task does not edit tests. |
| `test-julia-module-compat.R:117`, `:118`, `:120`, `:121` | neither; remains | `system2(julia, timeout = 30)` returned status 124. The Julia stderr is `signal 2: Interrupt` inside LLVM while printing a `LoadError` (`--compiled-modules=no`). Status 124 is R's timeout code. The fixtures are temporary `DRM` / `DRModels` projects, not the pinned checkout. The 30-second limit is in the test. |

Group (a) in the brief also includes "the pin being incompatible with what the tests expect". The checkout matches `tools/ci-drmjl-ref`; the job verified `HEAD == pin`. The `recov` and `forward` rows are what that sha does, so they are (c), not a mis-checked ref. The sha was not changed.

## The lane is still red

Fixing the profile does not make this job green. Still in the way:

- (b) Gamma animal SD `predict()` / `simulate()` names.
- (c) Binomial animal q2 `recov` labels, and the Gaussian `grad_source = "forward"` payload with no gradient, both at `5b005e0`.
- The b31jb Laplace helper iteration cap, and the module-compat 30-second Julia timeout.

Those need their own changes: an R predict/simulate name fix, a DRModels.jl change or a deliberate pin move, and test-helper edits. This task does not do those. Making the job `continue-on-error` / informational would hide that red result. That needs Shinichi's sign-off. It was not done.

A recommended split, if the lane should land before (b) and (c) are fixed:

1. Land the profile fix (this commit) so callr children start.
2. Leave the job required-red until (b) and (c) have owners, or Shinichi explicitly accepts `continue-on-error` for this job only.
3. Do not move `tools/ci-drmjl-ref` until someone names the sha the `recov` and gradient-source tests were written against and shows those two failures gone.

The 15 callr rows may still fail on the next run if the child, once started, hits a real Julia or bridge error. Only the startup abort is fixed here.

## Files

- `tools/ci-juliacall-coverage.Rprofile` — originals stored in `.drmtmb_covr_box`.
- `tools/tests/test_codecov_workflow.py` — `test_julia_profile_does_not_abort_callr_child`.
- `docs/dev-log/check-log.d/2026-11-15-julia-bridge-coverage-failures.md`.

No test, tolerance, skip, or `# nocov` edit. No design-doc or pkgdown change: formula grammar, likelihoods, and the public engine surface are unchanged. GitHub issue tracker: this note is the record for PR #1691; no new issue was opened. Overlapping product bugs (Gamma SD names, `recov` labels, gradient payload) stay on that PR until an owner splits them.

## Checks

```
python3 -m unittest tools.tests.test_codecov_workflow -v
```

13 tests, OK, including the new callr profile test (R 4.3.3, callr 3.7.5, pkgload 1.3.4, testthat 3.2.1 on this VM).

Live `julia-bridge-coverage` was not re-run locally. Julia 1.13 and the pinned DRModels.jl tree are not on this VM.

## Consistency

No user-facing name changes. `sigma`, `rho12`, `meta_V(V = V)`, and `phylo()` are unused in this diff. The pin file `tools/ci-drmjl-ref` is still `5b005e0ffbc017e427f3c050f7ef45b38ff990ce`.
