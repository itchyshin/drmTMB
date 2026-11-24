# After-task: parallel thread policy documentation guard (#1249)

## Purpose

Close the remaining documentation gap on #1249 without touching `drm_control()`
or fit-level thread provenance (code half stays on the perf lane).

## Change

- Regression test locks the nested-parallel pin list in `R/parallel-docs.R`.
- Julia-engine vignette cross-links the pkgdown `drmTMB-parallel` topic.

## Evidence

`tests/testthat/test-parallel-thread-policy.R`.