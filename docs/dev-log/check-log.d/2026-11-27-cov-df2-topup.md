# Check log — 2026-11-27 cov df2 topup

- Branch: `cursor/1127cov-drmTMB-df2`
- Scope: `tests/testthat/test-cov-1127-df2-topup.R` only (drmTMB.R, family.R, family-dpq.R guards).
- Local: `testthat::test_file("tests/testthat/test-cov-1127-df2-topup.R")` — 20 expectations, ~47s cold with `pkgload::load_all()`.
- Covr: `covr::file_coverage()` on each target file with `NOT_CRAN=true`; full-suite percentage unchanged on a curated six-file corpus (biv fit paths already exercise most instrumented lines in `R/drmTMB.R`); this slice adds explicit regression tests for Julia/temporal/biv_student gates, `drm_eval_family_arg()`, start-override validators, `drm_recycle_scalar_arg()`, and tweedie power validation.