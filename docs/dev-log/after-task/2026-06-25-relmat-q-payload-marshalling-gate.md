# After Task: Relmat Q Payload-Marshalling Gate

## 1. Goal

Make the relmat `Q` precision bridge boundary actionable before any future
DRM.jl or R-via-Julia bridge implementation work. The goal was to turn the
phrase "review Q precision payload marshalling separately" into a checked
support-cell gate.

## 2. Implemented

The implemented claim is: relmat `Q` precision remains native R/TMB runtime
evidence only, and direct DRM.jl, R-via-Julia, and R bridge `Q` support are
blocked until an explicit payload contract is reviewed.

- Added `docs/dev-log/dashboard/structured-re-relmat-q-payload-marshalling-gate.tsv`
  with six rows matching the relmat `K/Q` bridge-boundary cells.
- Each row requires payload fields for matrix id, matrix digest, input scale,
  precision source, level alignment, missing-level policy, coefficient order,
  and provenance.
- Added mission-control validation and a dashboard contract test that align the
  gate against `structured-re-relmat-q-bridge-boundary.tsv` and the q-series
  support-cell table.
- Updated `docs/dev-log/dashboard/README.md`,
  `docs/design/218-structured-q-series-completion-map.md`, and
  `docs/dev-log/check-log.md`.

## 3. Mathematical Contract

No likelihood, TMB parameterization, formula grammar, or estimator behavior
changed. The contract is a payload identity contract for future relmat
precision transport:

```text
Q input -> explicit precision source + matrix digest + aligned levels
        -> endpoint/member coefficient order + provenance
```

The gate deliberately rejects an implicit `Q -> K` conversion as bridge
evidence. Native R/TMB K/Q same-target parity remains runtime evidence only.

## 3a. Decisions and Rejected Alternatives

The accepted route was to add a validation-backed acceptance gate without
changing runtime bridge behavior.

Rejected alternatives:

- Do not treat native `Q` point-fit parity as direct DRM.jl or R-via-Julia
  bridge evidence.
- Do not promote broad bridge support or public support.
- Do not promote interval reliability, interval coverage, REML, AI-REML, q4
  REML, native-TMB q4 REML, HSquared AI-REML, non-Gaussian REML, or broader q8
  support.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-relmat-q-payload-marshalling-gate.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `git diff --check` passed.
- `python3 tools/validate-mission-control.py` passed and reported 6 relmat `Q`
  payload-marshalling gate rows.
- `air format tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,269 assertions, 0 failures, 0 warnings, and 0 skips.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,985 assertions, 0 failures, 0 warnings, and 0 skips.

## 6. Tests of the Tests

The new dashboard test checks that the six gate rows exactly match the existing
relmat `K/Q` bridge-boundary rows for support cell, formula cell, dimension,
endpoint set, slope class, native `Q` status, and unsupported bridge statuses.
It also checks that the linked q-series rows stay at `fixture_parity` bridge
status with planned intervals and coverage.

The mission-control validator repeats the same contract and additionally locks
the required payload fields and checks. This makes the acceptance gate fail
closed if future edits try to move a relmat `Q` bridge status without the
payload contract review.

## 7a. Issue Ledger

Open issue searches used:

```sh
gh issue list --repo itchyshin/drmTMB --state open --search "relmat Q payload marshalling" --limit 20
gh issue list --repo itchyshin/drmTMB --state open --search "structured random effect relmat Q" --limit 20
```

The first search returned no direct issue. The second returned the existing
structured-effect umbrella issues, including #147 and #33. I did not post a
new issue comment because this draft PR is a local acceptance-gate slice and
does not change public support.

## 8. Consistency Audit

Status-inventory and stale-wording scan used:

```sh
rg -n "bridge_q_status.*supported|direct_drmjl_q_status.*supported|r_via_julia_q_status.*supported|Q bridge (support|supported)|relmat Q bridge (support|supported)|q4 interval (reliability|coverage).*supported|q4 REML.*supported|q4 AI-REML.*supported|HSquared AI-REML.*supported" README.md ROADMAP.md NEWS.md docs vignettes R tests
```

The scan found existing unsupported-boundary and historical check-log text,
including the NEWS q4 Patterson-Thompson REML boundary. It did not reveal a new
relmat `Q` bridge support, q4 interval, q4 REML, q4 AI-REML, or HSquared
AI-REML support claim from this slice.

## 9. What Did Not Go Smoothly

The implementation was straightforward. The main care point was avoiding a
false promotion path: the new gate uses the banked native K/Q runtime parity as
context, but it does not move any direct DRM.jl or R-via-Julia bridge status.

## 10. Known Residuals

This task does not implement relmat `Q` payload marshalling, direct DRM.jl `Q`
export, R-via-Julia `Q` transport, broad bridge support, public support,
interval reliability, interval coverage, q4 REML, native-TMB q4 REML, q4
AI-REML, HSquared AI-REML, non-Gaussian REML, broader q8 support, DRAC/Totoro
execution, SR150 coverage readiness, PR undrafting/merging, or an Ayumi-facing
reply.

## 11. Team Learning

When runtime parity and bridge transport can be confused, add a separate
acceptance-gate sidecar before coding the transport. The q-series cell remains
the unit of truth, but the gate names the exact schema evidence required for
future bridge work.

## 12. Next Actions

Commit and push this stacked branch, open a draft PR, and run GitHub Actions.
After this gate is banked, the next q-series runtime slice should return to the
sigma one-slope denominator/coverage ladder or to an explicit DRM.jl payload
contract branch, still keeping DRAC/Totoro execution behind review.
