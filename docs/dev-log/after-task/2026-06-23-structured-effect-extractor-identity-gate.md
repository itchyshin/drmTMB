# After Task: Structured-Effect Extractor Identity Gate

## Goal

Give structured-effect extractors neutral provider, matrix-source, endpoint,
member, and coefficient identity before adding new structured q-series runtime
cells.

## Implemented

- Extended `structured_effects()` with provider-neutral identity columns:
  `provider`, `matrix_id`, `matrix_slot`, `matrix_source`, `matrix_role`,
  `matrix_digest`, `block_label`, `covariance_layout`, `endpoint_set`,
  `coefficient_set`, `member_count`, `member_levels`, `endpoint_blocks`, and
  `endpoint_covariance_labels`.
- Added compact resolved-precision fingerprints from the fitted precision
  object. These are diagnostic fingerprints for provider contracts, not
  cryptographic hashes and not exported matrix payloads.
- Extended `tests/testthat/test-structured-effects.R` so `phylo()`,
  `spatial()`, `animal()`, `relmat()`, and `phylo_interaction()` all prove the
  new identity fields. The tests also distinguish covariance input (`A`, `K`)
  from precision input (`Ainv`, `Q`) while confirming that equivalent
  covariance/precision inputs can resolve to the same downstream precision.
- Updated `NEWS.md`, `man/structured_effects.Rd`, and
  `docs/design/218-structured-q-series-completion-map.md`.

## Mathematical Contract

This slice does not change the likelihood or TMB parameterization. It exposes
metadata already implied by fitted structured terms:

- provider: `phylo`, `spatial`, `animal`, `relmat`, or
  `phylo_interaction`;
- matrix source: symbolic source objects such as `tree`, `coords`, `A`, `Ainv`,
  `K`, `Q`, or `tree1:tree2`;
- matrix role: tree precision, coordinate covariance, covariance input,
  precision input, pedigree covariance, or tree-pair precision;
- endpoint identity: fitted distributional parameters and endpoint blocks;
- coefficient identity: fitted structured coefficient names;
- member identity: resolved structured-effect levels.

The compact `matrix_digest` summarizes the resolved precision dimension,
nonzero count, sums, diagonal sum, and log determinant. It is a reproducibility
fingerprint only; it is not an inference result.

## Files Changed

- `NEWS.md`
- `R/methods.R`
- `man/structured_effects.Rd`
- `tests/testthat/test-structured-effects.R`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-structured-effect-extractor-identity-gate.md`

This report sits on top of the already-dirty q2 helper and q-series
support-cell map stack in the same worktree. No files were staged or committed.

## Checks Run

- `Rscript --vanilla -e "devtools::document()"` passed; unrelated generated Rd
  churn from the local roxygen version was manually removed.
- `air format R/methods.R tests/testthat/test-structured-effects.R R/drmTMB.R tests/testthat/test-structured-re-conversion-contracts.R tests/testthat/test-structured-re-bridge-fixtures.R inst/sim/R/sim_structured_re_bridge_fixtures.R`
  passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-effects')"`
  passed with 178 assertions.
- `git diff --check` passed.

## Tests Of The Tests

The first new `phylo_interaction()` assertion assumed member count was the
observed tip-pair count. The extractor correctly reports precision-node pairs,
which include internal nodes, so the test was corrected to check resolved
member levels and require that the precision-node count exceeds the tip-pair
count. A second assertion assumed slope endpoint blocks collapsed to one
string; it was corrected to require one endpoint block per coefficient.

The provider contract test now checks a real covariance/precision distinction:
`animal(A = K)` versus `animal(Ainv = Q)` and `relmat(K = K)` versus
`relmat(Q = Q)` keep different source fields while resolving to the same
precision fingerprint when `Q = solve(K)`.

## Consistency Audit

The change implements step 2 and starts step 3 of
`docs/design/218-structured-q-series-completion-map.md`. It does not mark any
new support-cell row as runtime-ready. It gives future q-series work stable
extractor fields for provider contracts, bridge payload provenance, and
endpoint/coefficient identity.

## GitHub Issue Maintenance

No GitHub issue, PR body, PR comment, or Ayumi-facing reply was created or
updated. PR #638 remains draft.

## What Did Not Go Smoothly

`devtools::document()` refreshed unrelated Rd files because the local roxygen
version differs from the repo's generated-doc baseline. Those unrelated
changes were removed manually, leaving only `man/structured_effects.Rd`.

## Team Learning

Extractor identity is the right bridge between the support-cell map and future
runtime work. Provider contracts should assert source identity and resolved
precision identity separately, because different user inputs can legitimately
resolve to the same downstream precision.

## Known Limitations

This is not runtime q-series expansion. Residual-scale structured slopes,
structured q4 slope blocks, structured q6/q8, bridge parity widening, interval
coverage, q4 REML promotion, native-TMB q4 REML, AI-REML, and non-Gaussian
AI-REML remain outside the support boundary.

The compact `matrix_digest` is a diagnostic fingerprint, not a cryptographic
hash and not a public matrix serialization format.

## Next Actions

Continue provider contract tests around missing-level policy, coordinate input
scale, pedigree provenance, and bridge payload provenance. Then complete or
verify Gaussian one independent structured `mu` slope mapping across providers
before attempting residual-scale slope cells.
