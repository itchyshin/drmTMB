# After Task: Relmat Q Bridge-Boundary Audit

## 1. Goal

Keep relmat K/Q one-slope evidence honest before new runtime or bridge work by
separating native R/TMB Q precision evidence from direct DRM.jl export and
R-via-Julia bridge marshalling.

## 2. Implemented

The implemented claim is: relmat one-slope K-matrix bridge fixtures and native
K/Q point evidence are now tracked as separate support-cell boundary rows, with
Q bridge/direct export status explicitly unsupported.

- Added `docs/dev-log/dashboard/structured-re-relmat-q-bridge-boundary.tsv`.
- Registered the sidecar in `tools/validate-mission-control.py` with six
  expected boundary rows and support-cell cross-checks.
- Added a dashboard contract test in
  `tests/testthat/test-structured-re-conversion-contracts.R`.
- Updated `docs/dev-log/dashboard/README.md`,
  `docs/design/218-structured-q-series-completion-map.md`, and
  `docs/dev-log/check-log.md`.

## 3a. Decisions and Rejected Alternatives

No likelihood, formula grammar, or TMB parameterization changed. The contract is
an evidence-boundary contract: `relmat(..., K = K)` bridge fixtures stay
K-matrix scoped, `relmat(..., Q = Q)` remains native R/TMB precision evidence
where already banked, and Q precision is not direct DRM.jl or R-via-Julia bridge
evidence.

Rejected alternatives:

- Do not implement Q precision bridge marshalling in this slice, because that
  needs DRM.jl payload-contract review and route-specific parity tests.
- Do not mark q4 location K/Q parity as banked, because the current q4 location
  fixture is K-matrix scoped.
- Do not change runtime formula grammar or public support language.

The six rows cover exact q-series cells:

- q1 `mu` one-slope;
- q1 `sigma` one-slope;
- matched q1 `mu+sigma` one-slope;
- q2 `mu1+mu2` slope-only;
- q4 `mu1+mu2` intercept-plus-slope location cell;
- all-four one-slope q8-shaped cell.

The q4 location row intentionally stays `native_q_status =
planned_not_banked`; the other rows cite runtime K/Q same-target native evidence
only where prior evidence already exists.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-relmat-q-bridge-boundary.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `air format tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `python3 tools/validate-mission-control.py` passed and reported 6 relmat Q
  bridge-boundary rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,179 assertions, 0 failures, 0 warnings, and 0 skips.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,895 assertions, 0 failures, 0 warnings, and 0 skips.
- `git diff --check` passed.

## 6. Tests of the Tests

The new test checks a boundary rather than a happy-path model fit. It verifies
that all six rows point at real q-series support cells, that every support cell
is relmat-scoped, that dimensions and endpoint sets agree with the support-cell
table, and that Q bridge, direct DRM.jl Q export, and R-via-Julia Q transport
remain `unsupported`.

## 7a. Issue Ledger

Open issue searches used:

```sh
gh issue list --repo itchyshin/drmTMB --state open --search "relmat Q precision bridge" --limit 20
gh issue list --repo itchyshin/drmTMB --state open --search "structured random effect relmat" --limit 20
```

Issue #147 remains the umbrella for animal/relmat known-relatedness structured
effects, and issue #33 remains relevant to structured random slopes. I did not
post an issue comment in this slice because the draft PR will carry the exact
dashboard evidence and this audit did not change runtime support.

## 8. Consistency Audit

Status-inventory and stale-wording scans used:

```sh
rg -n "relmat Q|Q precision|bridge marshalling|relmat\(.*Q|K/Q same-target|structured-re-relmat-q-bridge-boundary" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-relmat-q-bridge-boundary.tsv
rg -n "Q bridge (support|supported)|relmat Q bridge (support|supported)|bridge_q_status.*supported|direct_drmjl_q_status.*supported|r_via_julia_q_status.*supported" README.md ROADMAP.md NEWS.md docs vignettes R tests
rg -n "relmat Q bridge marshalling|Q precision marshalling|Q bridge marshalling" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design docs/dev-log/dashboard
```

The first and third scans found the expected native-Q grammar and existing
planned/unsupported bridge-marshalling boundaries. The second scan found only
the new unsupported-status checks and prose, so no accidental Q bridge support
claim needed removal.

## 9. What Did Not Go Smoothly

The first combined patch used stale README context and applied nothing. I split
the work into smaller patches, then re-ran validation after the sidecar, test,
validator, and prose were all in place.

## 10. Known Residuals

This task does not implement relmat Q bridge marshalling, direct DRM.jl Q
export, R-via-Julia Q transport, broad bridge support, interval reliability,
coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML,
non-Gaussian REML, public support, DRAC/Totoro execution, or SR150 coverage
readiness.

## 11. Team Learning

For relmat, treat `K` bridge fixtures and native `Q` precision evidence as
separate columns, not as a single support phrase. That keeps the q-series cell
as the unit of truth and prevents runtime K/Q parity from being mistaken for
bridge marshalling.

## 12. Next Actions

Keep this branch stacked as a draft PR. The next runtime slice should start
from this boundary and choose between banking native Q evidence for the q4
location one-slope cell, moving to the next sigma one-slope interval/denominator
gate, or preparing a reviewed Totoro/DRAC dispatch only after race-safety
review.
