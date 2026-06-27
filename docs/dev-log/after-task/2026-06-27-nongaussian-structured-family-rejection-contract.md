## 1. Goal

Record the exact pre-optimization rejection contract for structured-effect
routes the engine already rejects across non-Gaussian families and endpoints.
This completes the exact-cell boundary coverage so that structured support for
one family, endpoint, or provider is never read as implying it for another. The
eight cells span `student()`, `beta()`, `Gamma()`, `cumulative_logit()`,
`poisson()`, and `truncated_nbinom2()` on `mu`, `sigma`, `nu`, `zi`, or `hu`
with `spatial()`, `animal()`, `relmat()`, or `phylo()`. Keep every status
`unsupported` and promote no capability, bridge, interval, coverage, REML,
AI-REML, or public-support claim.

## 2. Implemented

- Added
  `docs/dev-log/dashboard/structured-re-nongaussian-structured-family-rejection-contract.tsv`,
  one `unsupported` row per family/endpoint/provider cell, each citing the
  `Structured non-Gaussian paths` formula-gate rejection and pointing at the
  engine boundary test.
- Added eight `qseries_*_rejected` rows to
  `structured-re-q-series-support-cells.tsv`, all `unsupported`,
  `family_class=non_gaussian`, linked to the new rejection-contract sidecar.
- Added a focused dashboard contract test,
  `non-Gaussian structured-family rejection contract stays explicit`, to
  `tests/testthat/test-structured-re-conversion-contracts.R`.
- Extended the mission-control validator with a path constant, fields tuple,
  reader, validation block, and success-count print for the new sidecar.
- Updated the dashboard README and the q-series completion map.

## 3a. Decisions and Rejected Alternatives

- I documented the rejection rather than attempting to implement structured
  non-Gaussian routes. The engine gate (`R/drmTMB.R`, `drm_reject_phase1_terms`)
  defers structured non-Gaussian paths by design, so the honest exact-cell
  evidence is a rejection contract, not a point-fit micro-shard.
- I did not add new engine assertions. The eight cells are already asserted in
  `tests/testthat/test-nongaussian-structured-boundary.R` with the expected
  `Structured non-Gaussian paths` pattern, so I cite that file as the evidence
  URL instead of duplicating the assertions.
- I keyed the validator's expected dictionary by `rejection_id`, not by
  provider, because several providers appear more than once across endpoints
  (spatial three times, animal twice, relmat twice, phylo twice). Keying by
  provider, as the count-sigma block does, would not have been unique here.
- I mirrored the existing count-sigma one-slope rejection sidecar/validator/test
  shape, including the claim_boundary phrase set, so the new contract is enforced
  the same way and cannot drift into a capability claim.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-27-nongaussian-structured-family-rejection-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-nongaussian-structured-family-rejection-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `air format tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 8 structured RE non-Gaussian structured-family rejection rows and 98 q-series cells.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-27-nongaussian-structured-family-rejection-contract.md')"` passed.
- `Rscript --vanilla -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R')); cat('parse_ok\n')"` passed.
- `Rscript --vanilla -e "testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R', stop_on_failure = TRUE)"` could not run because `testthat` is absent from the local R library; the dashboard contract test runs on CI.

## 6. Tests of the Tests

- The dashboard contract test pins the sidecar field set, all eight
  `unsupported` statuses, the single family-level `Structured non-Gaussian
  paths` pattern, the eight `rejection_id` slugs, the family/provider/endpoint
  sets, and the linked q-series rows. It would fail if a future edit promoted any
  status or changed a family, endpoint, or provider.
- The test asserts `intercept_only` slope class and `q1` dimension for all eight
  rows, so a future slope or higher-dimension promotion cannot slip in silently.
- The mission-control validator cross-checks the sidecar against the linked
  q-series cells (family, provider, endpoint, statuses, evidence URL,
  claim_boundary phrase), so a status change in either file is caught.
- The validator's per-row expected dictionary requires the exact eight cells, so
  adding, dropping, or renaming a cell fails the validator.

## 7a. Issue Ledger

- Fixed: the eight non-Gaussian structured cells now have explicit `unsupported`
  rejection evidence instead of being silently absent, which could be misread as
  "not yet recorded" rather than "rejected".
- Deferred: a supported structured non-Gaussian route (engine likelihood,
  extractor, interval, and recovery evidence) remains future work behind the
  named formula gate.
- Deferred: bridge parity, intervals, coverage, REML, AI-REML, and public
  support remain outside this slice for these cells.

## 8. Consistency Audit

- Checked that the new sidecar links back to q-series cells that exist and carry
  the matching `unsupported` statuses, family, provider, dimension, and endpoint.
- Confirmed the engine rejection message cited in the contract
  (`Structured non-Gaussian paths`) matches the assertions already present in
  `tests/testthat/test-nongaussian-structured-boundary.R`.
- Kept the claim wording parallel to the count-sigma one-slope and q2-plus-q2
  scale-only rejection contracts so the rejection ledgers read consistently.
- Verified the new q-series rows pass the general q-series enum checks
  (`family_class`, `structure_provider`, `dimension_pattern`, `slope_class`,
  `route`, estimators, statuses, `authority_status`) in the validator.

## 9. What Did Not Go Smoothly

- The local R library lacks `devtools`/`testthat`, so the new contract test is
  verified by parse plus CI rather than a local test run. The engine assertions
  it mirrors already existed, so the only new executable artifact is the
  dashboard contract test, which CI exercises.

## 10. Known Residuals

- The contract documents non-support; it does not move any cell toward
  supported. It is ledger evidence, not capability.
- The eight cells are a representative boundary sample across families,
  endpoints, and providers; they are not the full Cartesian product of every
  non-Gaussian family by every structured endpoint and provider.
- A future structured non-Gaussian design would need its own point-fit,
  extractor, interval, and recovery evidence before any of these rows could move
  off `unsupported`.

## 11. Team Learning

Exact-cell honesty must span the family axis too, not only the endpoint axis.
A Gaussian structured cell, or a supported count `mu` cell, does not imply that
the same structured machinery works for `student()`, `beta()`, `Gamma()`,
ordinal, zero-inflation, or hurdle endpoints; here those routes are in fact
engine-rejected. Recording the rejection as a first-class, validator-pinned
contract is what stops a green campaign in one corner of the matrix from being
read as support in another.
