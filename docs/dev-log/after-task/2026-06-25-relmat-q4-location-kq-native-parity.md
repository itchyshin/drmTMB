# After Task: Relmat q4 Location K/Q Native Parity

## 1. Goal

Bank the missing native R/TMB K/Q same-target evidence for the exact relmat q4
location one-slope `mu1+mu2` support cell, without moving any Q bridge,
interval, coverage, REML, or public-support boundary.

## 2. Implemented

The implemented claim is: the relmat q4 location one-slope cell now has native
R/TMB K/Q same-target runtime parity evidence, while Q precision bridge
marshalling remains unsupported.

- Added a K-matrix fit beside the existing Q-precision q4 location fit in
  `tests/testthat/test-animal-relmat-gaussian.R`.
- Added `docs/dev-log/dashboard/structured-re-relmat-q4-location-kq-native-parity.tsv`
  as a one-row runtime evidence sidecar.
- Updated `docs/dev-log/dashboard/structured-re-relmat-q-bridge-boundary.tsv`
  so the q4 location row moves from `planned_not_banked` to
  `runtime_kq_same_target_parity`.
- Added mission-control validation and a dashboard contract test for the new
  sidecar.
- Updated `docs/dev-log/dashboard/README.md`,
  `docs/design/218-structured-q-series-completion-map.md`, and
  `docs/dev-log/check-log.md`.

## 3. Mathematical Contract

The tested model cell is the bivariate Gaussian location block with
`relmat(1 + x | p | id, K = K)` and
`relmat(1 + x | p | id, Q = Q)` in both `mu1` and `mu2`, with `sigma1`,
`sigma2`, and `rho12` kept unstructured by relmat. The test checks the same
four endpoint members:

```text
mu1:(Intercept) + mu1:x + mu2:(Intercept) + mu2:x
```

The K route uses user covariance input; the Q route uses user precision input.
The acceptance evidence is runtime log-likelihood parity plus matched SD and
correlation member names. This is native R/TMB evidence only, not a DRM.jl
payload or R-via-Julia bridge result.

## 3a. Decisions and Rejected Alternatives

No likelihood, formula grammar, or TMB parameterization changed. The accepted
route was to add a native runtime sidecar for K/Q parity and keep the existing
q4 location fixture sidecar K-matrix scoped.

Rejected alternatives:

- Do not treat the new native Q evidence as Q bridge marshalling.
- Do not update direct DRM.jl export or R-via-Julia bridge status.
- Do not promote intervals, coverage, q4 REML, AI-REML, or public support.

## 4. Files Touched

- `tests/testthat/test-animal-relmat-gaussian.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-relmat-q4-location-kq-native-parity.tsv`
- `docs/dev-log/dashboard/structured-re-relmat-q-bridge-boundary.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `air format tests/testthat/test-animal-relmat-gaussian.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 1 relmat q4
  location K/Q native parity row.
- `Rscript --vanilla -e "devtools::test(filter = 'animal-relmat-gaussian|structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,699 assertions, 0 failures, 0 warnings, and 0 skips.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,936 assertions, 0 failures, 0 warnings, and 0 skips.
- `git diff --check` passed.

## 6. Tests of the Tests

The runtime test now fits both `K = K` and `Q = Q` for the same q4 location
cell, then compares their log-likelihoods and relmat extractor identities. The
dashboard tests check both the cross-cell relmat Q boundary row and the exact
new one-row sidecar. The bridge-fixture test pair was rerun to verify that the
existing K-matrix bridge fixture ledger remains K-scoped and does not absorb the
native-Q claim.

## 7a. Issue Ledger

Open issue searches used:

```sh
gh issue list --repo itchyshin/drmTMB --state open --search "relmat q4 location K Q parity" --limit 20
gh issue list --repo itchyshin/drmTMB --state open --search "structured random effect relmat Q" --limit 20
```

The first search returned no direct issue. The second returned the existing
structured-effect umbrella issues, including #147 and #33. I did not post a new
issue comment because this draft PR carries the narrow evidence row and does
not change public support.

## 8. Consistency Audit

Status-inventory and stale-wording scans used:

```sh
rg -n "planned_not_banked|q4 location one-slope row explicitly stays|q4 location row stays|Q precision native same-target evidence is not banked|native_q_status.*planned_not_banked" docs/dev-log/dashboard/README.md docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/structured-re-relmat-q-bridge-boundary.tsv docs/dev-log/dashboard/structured-re-relmat-q4-location-kq-native-parity.tsv tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py
rg -n "bridge_q_status.*supported|direct_drmjl_q_status.*supported|r_via_julia_q_status.*supported|Q bridge (support|supported)|relmat Q bridge (support|supported)|q4 interval (reliability|coverage).*supported|q4 REML.*supported|q4 AI-REML.*supported|HSquared AI-REML.*supported" README.md ROADMAP.md NEWS.md docs vignettes R tests
```

The first scan found only the design sentence saying the q4 row moved from
`planned_not_banked` to runtime parity. The second scan found existing
unsupported or historical guard text, including the NEWS boundary for the
route-specific Julia REML diagnostic; it did not reveal a new Q bridge,
interval, coverage, q4 REML, or AI-REML support claim from this slice.

## 9. What Did Not Go Smoothly

The slice was clean. The only care point was keeping three similar concepts
separate: K-matrix bridge fixture parity, native R/TMB K/Q runtime parity, and
future Q precision bridge marshalling.

## 10. Known Residuals

This task does not implement Q precision payload marshalling, direct DRM.jl Q
export, R-via-Julia Q transport, broad bridge support, partial location-scale
support, interval reliability, coverage, q4 REML, native-TMB q4 REML, q4
AI-REML, HSquared AI-REML, non-Gaussian REML, public support, DRAC/Totoro
execution, SR150 coverage readiness, PR undrafting/merging, or an Ayumi-facing
reply.

## 11. Team Learning

For relmat Q work, add the native K/Q runtime evidence as a separate sidecar
when the bridge fixture remains K-scoped. That keeps the support cell auditable
without smuggling Q precision through bridge wording.

## 12. Next Actions

Commit and push this stacked branch, open a draft PR, and run GitHub Actions.
After the stack is reviewed, the next runtime slice should move to sigma
one-slope coverage or the next relmat Q payload-marshalling design gate, not to
bridge promotion.
