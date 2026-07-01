# After Task: Q-Series Tranche 3 q4 Admission-Review Synthesis

## 1. Goal

Complete the Tranche 3 q4 admission review before any coverage launch. The
review should make the current no-admission decision explicit from existing
evidence and keep Mission Control honest about q4, q8-shaped, and
derived-correlation boundaries.

## 2. Implemented

Added `structured-re-q4-admission-review-synthesis.tsv` with 14 rows, matching
the q4 admission-denominator contract scope. Each row records the evidence
class, retained denominator, `pdHess` count, finite direct-SD interval counts,
derived-correlation status, admission decision, coverage decision, promotion
decision, evidence link, claim boundary, and next gate.

Mission Control now shows a `Q4 admission review` summary card and a Structured
RE contracts table with the admission decision, coverage decision, claim
boundary, threshold status, and next gate visible. The validator and focused R
tests now check the TSV contract, exact row set, contract linkage, source-sidecar
counts, no-coverage/no-promotion decisions, `profile_targets()` gate wording,
and widget wiring.

No support-cell status changed. The review admits zero q4 rows.

## 3a. Decisions and Rejected Alternatives

I used existing evidence rather than launching a new q4 coverage grid. The q4
location SR475 rows have `pdHess`/finite-Wald survivor rates below 95%, the
all-four intercept rows fail denominator prechecks, and the q8-shaped all-four
one-slope rows are still Hessian/geometry design holds. A coverage launch from
that evidence would overstate the inference state.

I kept the ordinary q4 location comparator in the 14-row review, but did not
treat it as a structured admission target. Its derived-correlation boundary is
therefore `not_structured_admission_target`, while the structured rows record
`derived_correlation_unavailable`.

I did not route work to Totoro, Nibi/Rorqual, Fir, or DRAC. Those compute routes
remain available for future admission designs, but this slice found no q4 row
that authorizes coverage work.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-admission-review-synthesis.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche3-q4-admission-review-synthesis.md`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`:
  passed.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}' docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js && node --check /tmp/drmtmb-dashboard-index.js`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 Q-Series cells, 14 q4
  admission-denominator contract rows, and 14 q4 admission-review synthesis
  rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  first failed because the new test flattened the ordinary comparator's
  derived-correlation boundary into the structured-row boundary; after fixing
  that expectation, passed `10357 PASS / 0 FAIL / 0 WARN / 0 SKIP`.

## 6. Tests of the Tests

The focused R test failed once on the ordinary-comparator boundary. That showed
the new test block was executing and that it could catch an overbroad
structured-row assumption. The Mission Control validator also failed once when
the older denominator render-call check still expected the pre-review function
signature; after the check was updated, the validator proved both q4 admission
sidecars are wired into the widget.

## 7a. Issue Ledger

No GitHub issue was opened or closed. This was a local Mission Control and
admission-review artifact for the active Q-Series Tranche 3 lane.

## 8. Consistency Audit

The review rows match the denominator contract cell set and contract IDs. The
q4 location rows cross-check against `structured-re-slope-coverage-results.tsv`;
their minimum finite-Wald counts match the `pdHess` survivor counts and remain
below the 95% admission threshold. The all-four intercept rows cross-check
against `structured-re-q4-intercept-denominator-precheck.tsv`. The q8-shaped
non-animal rows cross-check against `structured-re-q4-slope-hessian-geometry.tsv`;
the animal q8-shaped row cross-checks against
`structured-re-q4-animal-all-four-admission-probe.tsv`.

The README, dashboard renderer, validator, focused R test, check-log, and this
report tell the same story: q4 admission has been reviewed, no q4 row is
admitted, and coverage remains unauthorized.

## 9. What Did Not Go Smoothly

The first test expectation treated the ordinary comparator like a structured
row for derived-correlation status. That was wrong; the comparator is not a
structured-admission target. Fixing the expectation kept the review boundary
more precise.

I also had to update an older validator string that still looked for the
pre-review Q-Series render signature. The dashboard code was correct, but the
guard needed to learn the new final arguments.

## 10. Known Residuals

This does not provide q4 admission evidence, interval reliability, coverage, or
support. Exact `profile_targets()` names are still required before any coverage
runner can be launched. Derived-correlation intervals remain unavailable. q4
REML, REML, AI-REML, q8 inference, broad bridge support, and public support
remain unclaimed.

The next scientific work is a q4 location retained-denominator admission
design, not a coverage grid.

## 11. Team Learning

Admission review artifacts need to separate three boundaries: structured q4
direct-SD targets, ordinary comparators, and q8-shaped rows. Keeping those
boundaries explicit prevents a useful dashboard summary from turning into a
status claim.
