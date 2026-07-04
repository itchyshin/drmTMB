# After Task: Q-Series v1 First-Four Rejection Smoke Tool

## 1. Goal

Give the v1.0 Q-Series first-four candidate rows a fast, reproducible,
fail-closed baseline before any basic-distribution implementation work starts.

## 2. Implemented

Added `tools/qseries-v1-first-four-rejection-smoke.R`. The tool loads the local
source tree, builds minimal fixtures for beta/animal, Gamma/relmat,
ordinal/phylo, and Student/spatial `mu` structured-intercept candidates, runs
the current `drmTMB()` calls, and writes a TSV with one row per expected
`Structured non-Gaussian paths` rejection.

The generated v1 preflight report and dashboard README now point to this smoke.
`tests/testthat/test-nongaussian-structured-boundary.R` runs the tool and checks
the four row IDs, expected error pattern, observed error text, and no-claim
boundary.

## 3. Mathematical Contract

No model was admitted or fitted. The four fixture contracts remain design
targets only:

- beta `mu` animal: beta response in `(0, 1)` with an animal structured
  location intercept.
- Gamma `mu` relmat: positive response with a relmat structured location
  intercept.
- cumulative-logit ordinal `mu` phylo: ordered response with a phylogenetic
  structured location intercept.
- Student `mu` spatial: real-valued response with a spatial structured
  location intercept.

All four currently reject at the pre-optimization formula gate.

## 3a. Decisions and Rejected Alternatives

Decision: add a rejection smoke before adding any implementation route.

Rationale: the first-four candidates are v1.0 basic-distribution candidates, but
the current source truth is explicit rejection evidence. A fail-closed baseline
prevents a later debug fit from being mistaken for denominator, coverage, or
status evidence.

Rejected alternative: start with beta/animal or Gamma/relmat implementation.
That would skip Rose's current boundary audit and blur TMB/default route support
with separate Julia bridge capability notes.

## 4. Files Touched

- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `tools/qseries_v1_release_check.py`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-04-q-series-v1-first-four-rejection-smoke-tool.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file tools/qseries-v1-first-four-rejection-smoke.R`
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "invisible(parse('tools/qseries-v1-first-four-rejection-smoke.R')); invisible(parse('tests/testthat/test-nongaussian-structured-boundary.R')); invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R')); cat('parse_ok\n')"`
- `git diff --check`
- `python3 tools/qseries_v1_release_check.py --summary --write-report --write-candidates`
- `python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "nongaussian-structured-boundary", reporter = "summary")'`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`

## 6. Tests of the Tests

The new boundary test initially skipped because the tool path assumed the
package root. Rerunning after adding a `tests/testthat` relative fallback made
the test execute and pass with no skips. The direct tool run also prints four
`expected_rejection` rows, so the test is checking a real executable path rather
than only static TSV text.

## 7a. Issue Ledger

No GitHub issue was opened or commented on. This is a local v1.0 release-prep
baseline for existing Q-Series candidate rows.

## 8. Consistency Audit

The support-cell statuses remain unchanged: all four first-four rows are still
`basic_distribution_post_v1_design` with unsupported fit, interval, and
coverage. The preflight row accounting remains 74/104 practical v1.0 rows,
8/104 exact `inference_ready` anchors, and 0/104 `supported` authority. The
smoke explicitly denies fit denominator, coverage, q4/q8, REML, AI-REML,
bridge, and public-support claims.

## 9. What Did Not Go Smoothly

The first test run skipped because the subprocess looked for `tools/` relative
to the test working directory. The test now checks both package-root and
`tests/testthat` relative paths.

## 10. Known Residuals

This smoke reproduces current rejection evidence only. It does not implement
beta/animal, Gamma/relmat, ordinal/phylo, or Student/spatial structured routes;
does not create recovery evidence; and does not authorize any support-cell
movement.

## 11. Team Learning

Ada: a baseline executable smoke should come before implementation when the
candidate queue starts from explicit rejection contracts.

Rose: current failures are evidence too, but only if the boundary says exactly
what they do not prove.

Fisher: no denominator means no operating-characteristic claim.

Grace: use `R.home("bin")/Rscript` in tests rather than assuming shell PATH.

## 12. Next Actions

Use the rejection smoke before changing any of the first-four rows. The next
implementation slice should pick one row, change code behind review, and keep
the smoke or a successor debug fixture separate from any support-cell edit.
