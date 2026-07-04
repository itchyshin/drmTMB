# After Task: Q-Series v1 Student Spatial Mu Fit

## 1. Goal

Move one more Q-Series v1.0 basic-distribution row from post-v1 design into
local fit-only recovery by admitting the narrow `student()`
`spatial(1 | id, coords = coords)` `mu` route, without opening coverage,
interval, support, bridge, q2/q4, REML, AI-REML, or public-support claims.

## 2. Implemented

- `drm_build_student_ls_spec()` now accepts exactly one unlabelled
  intercept-only `spatial()` structured term in `mu`.
- The Student TMB path now adds the structured `u_phylo` contribution to `mu`
  and includes the known-precision Gaussian prior for `log_sd_phylo`.
- The first-four smoke now checks three local fit-only rows, beta animal,
  Gamma relmat, and Student spatial, plus the retained ordinal phylo rejection.
- Mission Control and the v1.0 release ledger now classify
  `qseries_student_mu_spatial_rejected` as `point_fit`/`extractor_ready` with
  local-debug-only denominator policy.

## 3a. Decisions and Rejected Alternatives

Decision: admit only the q1 `mu` intercept-only spatial Student route:

```text
y_i ~ Student(mu_i, sigma, nu)
mu_i = X_i beta + u_site[i]
u ~ N(0, sigma_spatial^2 C(distance))
```

The implementation uses the existing structured known-covariance machinery.
This is ML/Laplace point-fit recovery evidence only; it is not a retained
denominator, interval, coverage, `inference_ready`, `supported`, REML,
AI-REML, bridge, q2/q4, slope, scale-side, shape-side, or public-support
result.

Rejected alternatives: do not broaden to Student phylo/animal/relmat,
structured slopes, scale-side or `nu` structured effects, q2/q4, or coverage
before row-specific contracts and Rose/Fisher/Grace review.

## 4. Files Touched

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tools/qseries_v1_release_check.py`
- `tools/qseries_v1_claim_guard.py`
- `tools/validate-mission-control.py`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- Q-Series dashboard and generated release-audit TSV/Markdown files under
  `docs/dev-log/dashboard/` and `docs/dev-log/release-audits/`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`: passed with 77/104 practical rows, 21/37 basic-distribution recovery rows, 8/104 exact `inference_ready` anchors, and 0/104 `supported` authority rows.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "pkgbuild::compile_dll(debug = FALSE, quiet = TRUE); cat('compile_dll_ok\n')"`: passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file tools/qseries-v1-first-four-rejection-smoke.R`: passed with three `expected_fit` rows and one `expected_rejection` row.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'nongaussian-structured-boundary', reporter = 'summary')"`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts', reporter = 'summary')"`: passed.

## 6. Tests of the Tests

- The first-four smoke now verifies a finite Student spatial fit, convergence
  0, `spatial_mu` random effects, and a direct spatial SD label.
- The Student local fixture uses an independent deterministic seed and a
  slightly roomier within-site design so the smoke tests the route rather than
  an optimizer-edge data draw.
- The conversion-contract test checks the new 77/104 accounting, the reduced
  five-row non-Gaussian structured-family rejection contract, the three-row
  non-Gaussian point-only audit count, and the shifted first-four review queue.

## 7a. Issue Ledger

No GitHub issue was opened or updated from this slice. The local `gh` CLI is
not installed in this shell, and this change is a narrow branch checkpoint for
the active v1.0 row-surface lane.

## 8. Consistency Audit

- Mission Control still reports 104 Q-Series cells.
- The generated v1 release status reports 77/104 practical rows, 21/37
  basic-distribution recovery rows, 8/104 exact `inference_ready` anchors,
  0/104 `supported` authority rows, and 27/104 post-v1 rows.
- The first-four queue is now ordinal phylo `mu`, beta animal `sigma`, NB2
  animal `sigma` one-slope, and NB2 phylo `sigma` one-slope.
- No README, NEWS, ROADMAP, known-limitations, formula grammar, vignette, or
  pkgdown navigation change was needed because this remains an internal
  local-debug fit gate, not public support wording.

## 9. What Did Not Go Smoothly

- The first Student fixture inherited the RNG state after the Gamma fixture and
  produced a deterministic false-convergence warning in the focused test. The
  fixture now has its own seed and a gentler deterministic design.

## 10. Known Residuals

- Student spatial is q1 `mu` intercept-only and local-debug-only.
- Student phylo/animal/relmat, structured slopes, scale-side or `nu`
  structured effects, q2/q4, intervals, coverage, retained denominators, REML,
  AI-REML, bridge support, and public support remain deferred.

## 11. Team Learning

- Rose: a fit-only row still needs a deterministic smoke that fails closed on
  optimizer-code drift.
- Fisher: convergence 0 belongs in the local recovery smoke; finite objective
  alone is not enough for a recovered row.
- Grace: give each generated fixture its own seed when several family fixtures
  share a smoke runner.

## Next Actions

- One additional row movement is needed to hit the 75% practical v1.0
  row-accounting target.
- The cheapest next candidates are the generated first-four review rows; any
  movement still needs row-specific recovery evidence plus Rose/Fisher/Grace
  review before status edits.
