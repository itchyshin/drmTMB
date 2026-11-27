# 2026-11-27 — cursor coverage slice R/[a-c]*

- Branch `cursor/1127cov-drmTMB-ac`; covr `package_coverage(type = "tests")` on the CRAN-lane filter (default under covr).
- Extended `test-package-skeleton.R`, `test-control.R`, and `test-family-dpq.R` with validators and helpers in `R/bf.R`, `R/control.R`, `R/binomial-q2-sd.R`, and `R/adequacy.R`.
- Local: `test_dir(..., filter = "package-skeleton")` passed; targeted new `test_that()` blocks passed via `pkgload::load_all()`.
- Issues filed: none.