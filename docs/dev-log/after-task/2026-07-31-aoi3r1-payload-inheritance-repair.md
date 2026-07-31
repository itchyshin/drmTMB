# AOI-3R1 diagnostic payload-inheritance repair

## 1. Goal

Repair the AOI-3R1 diagnostic runner so every scheduled ineligible inner row
retains a valid outer diagnostic payload when one exists, while preserving the
AOI-2 HOLD and AOI-3 fail-closed boundary.

## 2. Implemented

Added an explicit payload-validity predicate and outer-to-inner payload
inheritance in the private full-refit runner. Ineligible inner rows now record
their payload origin and the outer status/sandwich reason that made them
ineligible. An eligible inner refit overwrites this with its own payload. The
focused runner test checks the ordering and the reducer's payload-completeness
gate. The revised smoke contract now states the inheritance rule.

## 3a. Decisions and Rejected Alternatives

The retained AOI-3R1 output was not modified, reclassified, or reduced again:
its invalid decision is correct under the former schema. The repair is
class-wide, rather than tailored to the observed additive case. Fabricating a
payload for an outer failure before a payload exists was rejected because it
would turn unknown execution state into an asserted diagnosis.

## 4. Files Touched

- `tools/run-aoi3-bernoulli-nb2-full-refit.R`
- `tests/testthat/test-aoi3-full-refit-runner.R`
- `docs/dev-log/2026-07-31-aoi3r-revised-smoke-contract.md`
- `docs/dev-log/after-task/2026-07-31-aoi3r1-payload-inheritance-repair.md`
- `docs/dev-log/simulation-artifacts/2026-07-31-aoi3r2-diagnostic-manifest/manifest.csv`
- `docs/dev-log/simulation-artifacts/2026-07-31-aoi3r2-diagnostic-manifest/README.md`

Retained local AOI-3R1 output and its invalid reducer analysis were inspected
but are intentionally untracked and unchanged.

## 5. Checks Run

- `Rscript -e 'testthat::test_file("tests/testthat/test-aoi3-full-refit-runner.R")'` — PASS, 26 expectations.
- `git diff --check` — PASS.
- Parsed the runner and both AOI-3 reducers through the focused test — PASS.
- AOI-3R2 manifest assertion — PASS: 60 rows, 60 unique seeds, 15 outer and
  45 inner attempts, and no seed overlap with AOI-3R1.

## 6. Tests of the Tests

The first version of the new reducer assertion expected a message the reducer
does not emit; the focused test failed. It was corrected to inspect the real
required-column and non-missing-version fail-closed conditions, then passed.
The runner test also asserts that inheritance occurs after the default inner
row exists and before the inner eligibility branch, so deleting or moving that
call fails the test.
The test also evaluates the two runner helpers from the parsed runner with a
valid unavailable outer sandwich and an outer failure without a payload; it
checks inheritance in the first case and refuses fabricated diagnostics in the
second.

## 7a. Issue Ledger

- AOI-3R1 diagnostic payload completeness — fixed in runner source; a fresh,
  separately authorized run is still required.
- AOI-2 point-recovery evidence — HOLD remains; not reassessed here.
- AOI-3 uncertainty calibration — deferred and not executable from this work.

## 8. Consistency Audit

Checked every inner-row path in the runner: eligible refits now own their
payload; ineligible rows inherit only a validated outer payload; early outer
failures retain missing payloads so the reducer invalidates the run. The
reducer still requires payload columns and non-missing diagnostic versions for
both outer and inner records. No other association pair, Lane B work, public
reader content, or capability ledger was touched.

## 9. What Did Not Go Smoothly

The original AOI-3R1 reducer completed fail-closed because a valid outer
payload was lost when an inner row was marked `not_eligible`. The initial test
also over-specified a nonexistent reducer message; that test defect was caught
before any claim or rerun.

## 10. Known Residuals

The source repair has not been exercised in a fresh run. The retained AOI-3R1
run remains `AOI3R1_DIAGNOSTIC_INVALID`; it is not scientific confirmation or
disconfirmation of a sandwich route. A fresh immutable seed manifest and an
explicit owner authorization are required before a replacement local smoke.
The AOI-3R2 replacement manifest is now frozen against the repaired runner,
but its result root must not be created before that separate authorization.

## 11. Team Learning

For staged two-stage diagnostics, payload capture is upstream provenance, not
an optional result field: every scheduled attempt must either retain the
earliest valid state that explains its eligibility or remain explicitly
unknown.

Memory receipt: `route.py` was run but has no LOAD-FIRST manifest for this
worktree; the repository AGENTS lane split and the AOI-3R contract shaped this
repair. No memory update is warranted because this is a local implementation
receipt.

Golden Set: not in scope; this is a private diagnostic-runner provenance repair,
not a public capability, release, or inference change.

## 12. Cross-Product Coverage

This repair covers ✓ private Bernoulli × ordinary-NB2 AOI-3 runner provenance
for fixed-effect association formulae and scheduled local inner attempts. It
does NOT cover ✗ a fresh smoke, DRAC, full-refit calibration, uncertainty
availability, `vcov()`, `confint()`, standard errors, profiles, point-recovery
promotion, public documentation, capability-ledger changes, other family
pairs, random/structured association effects, missingness, offsets, weights,
or REML.
