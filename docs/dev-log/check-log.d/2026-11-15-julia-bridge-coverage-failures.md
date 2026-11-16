# 2026-11-15 Julia bridge coverage failures (PR #1691)

Job 132913824133 on head `9e35ed873`, pin `5b005e0ffbc017e427f3c050f7ef45b38ff990ce`: 24 testthat failures. Classification and the one harness fix are in `docs/dev-log/after-task/2026-11-15-julia-bridge-coverage-failures.md`.

The planted `tests/testthat/.Rprofile` aborted callr children by assigning a new binding into the locked `pkgload` namespace. Originals now live in `.drmtmb_covr_box`. Pin unchanged. Tests, tolerances, skips, and `# nocov` unchanged.

```
python3 -m unittest tools.tests.test_codecov_workflow -v
```

13 tests, OK. Live Julia covr: not re-run (no Julia 1.13 / DRModels checkout on this VM). The lane stays red on the Gamma SD predict names (R), the pin's `recov` and `grad_source` payloads (DRModels.jl), the b31jb Laplace helper, and the module-compat 30s timeout.
