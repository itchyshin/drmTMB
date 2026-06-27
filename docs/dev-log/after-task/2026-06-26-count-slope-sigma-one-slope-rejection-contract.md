## 1. Goal

Record the exact pre-optimization rejection contract for count NB2 `sigma`
one-slope structured-scale cells across `phylo()`, fixed-covariance
`spatial()`, A-matrix `animal()`, and K/Q `relmat()`. This closes the count
half-cell question with engine evidence: the banked count `mu` one-slope cells
must not be read as implying count `sigma` one-slope support. Keep every status
`unsupported` and promote no capability, bridge, interval, coverage, REML,
AI-REML, structured count scale, or public-support claim.

## 2. Implemented

- Added
  `docs/dev-log/dashboard/structured-re-count-slope-sigma-one-slope-rejection-contract.tsv`,
  one `unsupported` row per structured provider (NB2), each citing the
  `Structured non-Gaussian paths` formula-gate rejection and pointing at the
  engine boundary test.
- Added four `qseries_{phylo,spatial,animal,relmat}_nbinom2_q1_sigma_one_slope_rejected`
  rows to `structured-re-q-series-support-cells.tsv`, all `unsupported`, linked
  to the new rejection-contract sidecar.
- Added four NB2 one-slope `sigma` rejection assertions to
  `tests/testthat/test-nongaussian-structured-boundary.R`, one per provider,
  each expecting `Structured non-Gaussian paths`.
- Added a focused dashboard contract test,
  `count sigma one-slope rejection contract stays explicit`, to
  `tests/testthat/test-structured-re-conversion-contracts.R`.
- Extended the mission-control validator with a path constant, fields tuple,
  reader, validation block, and success-count print for the new sidecar.
- Updated the dashboard README and the q-series completion map.

## 3a. Decisions and Rejected Alternatives

- I documented the rejection rather than attempting to implement structured
  count `sigma`. The engine gate (`R/drmTMB.R`, `drm_reject_phase1_terms`)
  defers structured count scale routes by design, so the honest exact-cell
  evidence is a rejection contract, not a point-fit micro-shard.
- I scoped the contract to NB2 only. Poisson has no `sigma` parameter, so a
  structured count scale cell does not exist for it; I stated this in the
  contract text instead of inventing a Poisson rejection row.
- I used `tests/testthat/test-nongaussian-structured-boundary.R` for the engine
  evidence because it already exercises structured non-Gaussian `sigma`
  rejection for other families with a self-contained setup; the one-slope NB2
  forms reuse that proven gate.
- I mirrored the existing `structured-re-q2-plus-q2-sigma-rejection-contract`
  sidecar/validator/test shape so the new contract is enforced the same way and
  cannot drift into a capability claim.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-26-count-slope-sigma-one-slope-rejection-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-sigma-one-slope-rejection-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `air format tests/testthat/test-nongaussian-structured-boundary.R tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 4 structured RE count-slope sigma one-slope rejection rows and 90 q-series cells.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-26-count-slope-sigma-one-slope-rejection-contract.md')"` passed.
- `Rscript --vanilla -e "invisible(parse('tests/testthat/test-nongaussian-structured-boundary.R')); invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R')); cat('parse_ok\n')"` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'nongaussian-structured-boundary', stop_on_failure = TRUE)"` could not run because `devtools` is absent from the local R library; the engine assertions run on CI.
- `Rscript --vanilla -e "testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R', stop_on_failure = TRUE)"` could not run because `testthat` is absent from the local R library.

## 6. Tests of the Tests

- The engine assertions place the structured marker only in `sigma`, with a
  plain `mu` (`y ~ x`), so a pass proves the rejection is triggered by the
  count scale route specifically, not by a structured `mu` term.
- The four assertions cover all four structured providers, so the contract is
  not inferred from a single provider.
- The dashboard contract test pins the sidecar field set, the four
  `unsupported` statuses, the single family-level `Structured non-Gaussian
  paths` pattern, the `nbinom2()` family, and the linked q-series rows. It would
  fail if a future edit promoted any status or changed the family.
- The mission-control validator cross-checks the sidecar against the linked
  q-series cells, so a status change in either file is caught.

## 7a. Issue Ledger

- Fixed: the count `sigma` one-slope cells now have explicit `unsupported`
  rejection evidence instead of being silently absent (which could be misread
  as "not yet recorded" rather than "rejected").
- Deferred: a supported structured count scale route (engine likelihood,
  extractor, interval, and recovery evidence) remains future work behind the
  named formula gate.
- Deferred: bridge parity, intervals, coverage, REML, AI-REML, and public
  support remain outside this slice for these cells.

## 8. Consistency Audit

- Checked that the count `mu` one-slope cells stay at their existing
  point-fit/extractor status; this slice adds only the `sigma` rejection cells
  and does not touch the `mu` rows.
- Verified the new sidecar links back to q-series cells that exist and carry the
  matching `unsupported` statuses, family, provider, dimension, and endpoint.
- Confirmed the engine rejection message cited in the contract
  (`Structured non-Gaussian paths`) matches the live gate text in
  `R/drmTMB.R` and the existing intercept-form rejection in
  `tests/testthat/test-count-structured-mu.R`.
- Kept the claim wording parallel to the q2-plus-q2 scale-only rejection
  contract so the two rejection ledgers read consistently.

## 9. What Did Not Go Smoothly

- The local R library lacks `devtools`/`testthat`, so the new engine assertions
  and the contract test are verified by parse plus CI rather than a local test
  run. The reasoning that the one-slope `sigma` form hits the same formula gate
  as the already-tested intercept form is grounded in the gate source, but CI is
  the first execution of the new assertions.

## 10. Known Residuals

- The contract documents non-support; it does not move any cell toward
  supported. It is ledger evidence, not capability.
- Poisson structured count scale is represented only in prose (no `sigma`
  parameter), not as its own rejection row.
- A future structured count scale design would need its own point-fit,
  extractor, interval, and recovery evidence before any of these rows could move
  off `unsupported`.

## 11. Team Learning

Exact-cell honesty cuts both ways. A completed neighbour (count `mu` one-slope)
does not imply the sibling (count `sigma` one-slope); here the sibling is in
fact engine-rejected. Recording the rejection as a first-class, validator-pinned
contract is what stops a green `mu` campaign from being read as scale-side
support.
