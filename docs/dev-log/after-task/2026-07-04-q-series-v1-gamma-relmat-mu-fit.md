# After Task: Q-Series v1 Gamma Relmat Mu Fit

## 1. Goal

Move one more Q-Series v1.0 basic-distribution row from post-v1 design into
local fit-only recovery by admitting the narrow `Gamma(link = "log")`
`relmat(1 | id, K = K)` `mu` route, without opening coverage, interval,
support, bridge, q2/q4, REML, AI-REML, or public-support claims.

## 2. Implemented

- `drm_build_gamma_ls_spec()` now accepts exactly one unlabelled intercept-only
  `relmat()` structured term in `mu`.
- The Gamma TMB path now adds the structured `u_phylo` contribution to
  `eta_mu` and includes the known-precision Gaussian prior for
  `log_sd_phylo`.
- The first-four smoke now checks two local fit-only rows, beta animal and
  Gamma relmat, and two retained rejection rows, ordinal phylo and Student
  spatial.
- Mission Control and the v1.0 release ledger now classify
  `qseries_gamma_mu_relmat_rejected` as `point_fit`/`extractor_ready` with
  local-debug-only denominator policy.

## 3a. Decisions and Rejected Alternatives

Decision: admit only the q1 `mu` intercept-only relmat Gamma route:

```text
y_i ~ Gamma(mu_i, sigma)
log(mu_i) = X_i beta + u_id[i]
u ~ N(0, sigma_relmat^2 K)
```

The implementation uses the existing structured known-covariance machinery.
This is ML/Laplace point-fit recovery evidence only; it is not a retained
denominator, interval, coverage, `inference_ready`, `supported`, REML,
AI-REML, bridge, q2/q4, slope, scale-side, or public-support result.

Rejected alternatives: do not broaden to Gamma phylo/spatial/animal, structured
slopes, scale-side structured effects, q2/q4, or coverage before row-specific
contracts and Rose/Fisher/Grace review.

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
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "invisible(parse('R/drmTMB.R')); cat('parse_ok\n')"`: passed.
- `python3 -m py_compile tools/validate-mission-control.py tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py`: passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "pkgbuild::compile_dll(debug = FALSE, quiet = TRUE); cat('compile_dll_ok\n')"`: passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file tools/qseries-v1-first-four-rejection-smoke.R`: passed with two `expected_fit` rows and two `expected_rejection` rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'nongaussian-structured-boundary', reporter = 'summary')"`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts', reporter = 'summary')"`: passed.
- `git diff --check`: passed.

## 6. Tests of the Tests

- The first-four smoke now verifies a finite Gamma relmat fit, convergence 0,
  `relmat_mu` random effects, and a direct relmat SD label.
- The boundary test defines local `K`, `Q`, coordinates, and pedigree fixtures
  so structured formulas no longer depend on accidental early rejection from
  missing objects.
- The conversion-contract test checks the new 76/104 accounting, the reduced
  six-row non-Gaussian structured-family rejection contract, the two-row
  non-Gaussian point-only audit count, and the shifted first-four review queue.

## 7a. Issue Ledger

- Attempted `gh issue list -R itchyshin/drmTMB --search "Gamma relmat qseries"
  --limit 10`.
- The command was blocked because `gh` is not installed in this local shell.
  No GitHub issue was opened or updated from this slice.

## 8. Consistency Audit

- Stale-count/status scan:
  `rg -n "75/104|19/37|29/104|rows_to_75=3|candidate_review_rows=29|nongaussian_struct_reject_gamma_mu_relmat|Gamma\\(\\).*non_gaussian_rejected" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd docs/dev-log/dashboard docs/dev-log/release-audits tools tests || true`:
  no stale hits.
- The generated v1 release status reports 76/104 practical rows, 20/37
  basic-distribution recovery rows, 8/104 exact `inference_ready` anchors,
  0/104 `supported` authority rows, and 28/104 post-v1 rows.
- No README, NEWS, ROADMAP, known-limitations, formula grammar, vignette, or
  pkgdown navigation change was needed because this remains an internal
  local-debug fit gate, not public support wording.

## 9. What Did Not Go Smoothly

- The release-check generator assumed every first-four candidate came from the
  non-Gaussian structured-family rejection TSV. After Gamma moved, the queue
  correctly pulled in the count NB2 sigma-animal one-slope row, so the generator
  needed to merge the count-scale rejection contract too.

## 10. Known Residuals

- Gamma relmat is q1 `mu` intercept-only and local-debug-only.
- Gamma phylo/spatial/animal, structured slopes, scale-side structured effects,
  q2/q4, intervals, coverage, retained denominators, REML, AI-REML, bridge
  support, and public support remain deferred.

## 11. Team Learning

- Rose: keep the candidate queue generated from current ledger state; do not
  pin yesterday's first-four list after a row moves.
- Fisher: local point-fit recovery still needs the same no-denominator and
  no-coverage language as a rejection baseline.
- Grace: release-check generators should accept all rejection-contract sources
  that can enter the first-four queue, not only the first source encountered.

## Next Actions

- Two additional row movements are needed to hit the 75% practical v1.0
  row-accounting target.
- The current first-four queue is ordinal phylo `mu`, Student spatial `mu`,
  beta animal `sigma`, and NB2 animal `sigma` one-slope. Any movement from that
  queue still needs row-specific recovery evidence plus Rose/Fisher/Grace
  review before status edits.
