# After Task: Q-Series v1 First-Four Current-Candidate Debug Runner

## 1. Goal

Update the fast Q-Series v1.0 debug runner so it matches the current
post-75% candidate queue before any further implementation or compute work.

The purpose was tooling and boundary discipline only: make the next candidate
slice cheaper to check, while preserving the current support-cell truth.

## 2. Implemented

`tools/qseries-v1-first-four-rejection-smoke.R` now covers all four current
candidate gates:

- ordinal `mu ~ phylo(1 | id, tree = tree)`;
- truncated-NB2 `hu ~ relmat(1 | id, Q = Q)`;
- labelled count `mu ~ spatial(1 | p | id, coords = coords)`;
- simultaneous-provider count `mu ~ spatial(1 | id, coords = coords) +
  relmat(1 | id, Q = Q)`.

The runner now records ten local fit-only rows and four expected-rejection
rows. The rejection rows have per-case expected error patterns so the test can
distinguish the structured non-Gaussian boundary, the labelled q2 count gate,
and the one-structured-provider count gate.

`tests/testthat/test-nongaussian-structured-boundary.R` now checks the 14-row
output, row IDs, row classes, and expected error patterns. The dashboard README
and check-log now describe the current candidate queue instead of the older
first-four snapshot.

## 3a. Decisions and Rejected Alternatives

Decision: keep this as an executable debug fixture and not a support-cell edit.

Rationale: the candidate queue has moved since the first rejection-smoke report.
The cheapest safe move was to update the local tool to match the current queue
before changing any implementation route.

Rejected alternative: start implementing ordinal structured effects in this
slice. The current cumulative-logit path rejects structured effects in the R
builder and does not route structured random-effect contributions through the
TMB ordinal likelihood, so that is a real model-plumbing task rather than a
small gate flip.

Rejected alternative: run Totoro, DRAC, or a local denominator smoke. This
slice checks source-tree boundaries only; no compute denominator is authorized.

## 3b. Claim Boundary

This task does not move any support cell. It does not create a retained
denominator, recovery rate, interval evidence, coverage evidence,
`inference_ready` status, `supported` status, REML/AI-REML claim, q4/q8 claim,
bridge claim, or public support claim.

Rose-style audit: the runner asserts exact boundary classes and error patterns,
while Mission Control and the v1 release checker keep the global Q-Series
counts unchanged.

## 4. Files Touched

- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-04-q-series-v1-first-four-current-debug-runner.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "invisible(parse('tools/qseries-v1-first-four-rejection-smoke.R')); invisible(parse('tests/testthat/test-nongaussian-structured-boundary.R')); cat('r_parse_ok\n')"`:
  passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file tools/qseries-v1-first-four-rejection-smoke.R`:
  passed with ten `expected_fit` rows and four `expected_rejection` rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'nongaussian-structured-boundary', reporter = 'summary')"`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts', reporter = 'summary')"`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`:
  passed with practical v1.0 surface 84/104 (80.8%), exact
  `inference_ready` 8/104, supported authority 0/104, and post-v1.0 20/104.

## 6. Tests of the Tests

The focused boundary test failed once after the runner changed from 11 rows to
14 rows, which confirmed it was checking the executable output rather than only
parsing static text. Updating the expected row IDs and per-row error patterns
made the test pass against the new runner output.

## 7a. Issue Ledger

No GitHub issue or PR comment was opened for this local tooling slice.

No compute issue was opened because this task intentionally stops before any
Totoro, DRAC, local retained-denominator, or coverage run.

## 8. Consistency Audit

Mission Control remains green. The Q-Series support surface remains 104 cells,
with 84/104 practical v1.0 rows, 8/104 exact `inference_ready` rows, 0/104
`supported` authority rows, and 20/104 post-v1.0 rows.

The updated README wording matches the generated candidate queue: the first
four debug gates are ordinal phylo `mu`, truncated-NB2 relmat `hu`, labelled
spatial count `mu`, and simultaneous-provider count `mu`.

## 9. What Did Not Go Smoothly

The first focused test run still expected the older 11-row runner output. That
was useful friction: it forced the new row count, row classes, and expected
error patterns into the test instead of leaving the smoke under-specified.

## 10. Known Residuals

The runner still proves only current local source-tree behavior. It does not
implement ordinal structured effects, truncated-NB2 hurdle structured effects,
labelled count q2 structured effects, or simultaneous structured-provider
count fits.

The next row movement still requires a separate implementation slice, focused
tests, Mission Control update, Rose/Fisher review, and a clean no-overclaim
audit.

## 11. Team Learning

Ada: keep the candidate queue executable so each next slice starts from the
same source truth as the dashboard.

Rose: every tooling speedup needs its own claim boundary; faster checks are not
stronger evidence.

Fisher: row-level debug evidence is not a denominator and must not be promoted
into operating-characteristic language.

Grace: lightweight local tools are useful only when the validator and release
checker continue to agree with them.
