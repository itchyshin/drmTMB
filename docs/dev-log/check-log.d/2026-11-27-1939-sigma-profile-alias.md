# Check log: #1939 sigma profile alias on location-scale fits

- **Branch:** `cursor/1127fx-1939`
- **Scope:** `profile_match_confint_targets()`, `profile_match_targets()`, `tests/testthat/test-profile-targets.R`
- **Cause:** Response-scale `sigma` inventory row is emitted only for constant `sigma ~ 1`; `parm = "sigma"` on `sigma ~ x` fell through to generic unknown-target errors.
- **Fix:** Classed `drmTMB_confint_scale_alias_error` pointing to `fixef:sigma:<term>` or `newdata` (documented contract in `?confint.drmTMB`).
- **Tests run (local):** `pkgload::load_all()` + isolated `testthat::test_file` for the #1939 test (5 assertions, pass). Manual repro from issue #1939 on loaded package.
- **Constant `sigma ~ 1` profile endpoints:** unchanged on toy `fit4` example (finite bounds only; no expectation edits).