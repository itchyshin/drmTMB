# After Task: Structured random-effect SD target resolver

## 1. Goal

Make structured SD target metadata failures explicit and test coefficient and
block selection within one structured provider and level.

## 2. Implemented

`drm_resolve_sd_target()` now validates member identity fields before filtering
candidates. Structured members need a valid, explicit level; all members need
scalar provider, group, dpar, and coefficient strings plus a block string or
`NA_character_`. Tests cover same-level coefficient selection, same-coefficient
block selection, ambiguity messages, and malformed metadata.

## 3a. Decisions and Rejected Alternatives

No covariance or SD parameterization changed. The resolver requires structured
members to carry an explicit provider level. This slice adds no production
structured-model route. Assumptions made without asking: none.

## 4. Files Touched

- `R/random-effect-targets.R`
- `tests/testthat/test-structured-sd-targets.R`
- `docs/dev-log/check-log.d/2026-10-20-structured-sd-target-resolver.md`
- `docs/dev-log/after-task/2026-10-20-structured-sd-target-resolver.md`

## 5. Checks Run

- Red focused runs showed the intended failures before implementation: missing
  `level` metadata was reported as an empty target set; members with missing
  identity fields could resolve or produce an unhelpful no-match error.
- `Rscript -e 'devtools::test(filter = "structured-sd-targets", reporter = "summary", stop_on_failure = TRUE)'` passed the focused file.
- `git diff --check` passed for the source and test changes.
- The after-task structure validator passed. Its programme-closure phase
  returned status 1 because the parent ledger and ten leaf ledgers remain open.
- The focused tests make no fits. Full package and Julia checks were not run.

## 6. Tests of the Tests

Malformed level, provider, group, dpar, coefficient, and block cases failed
before the fix for their intended reasons, then passed after validation moved
ahead of filtering and error formatting. The coefficient and block checks
assert the selected object and its group, provider, level, coefficient, and
block values. The first `devtools::test()` run returned exit code zero while
printing a failure, so the green run used `stop_on_failure = TRUE`.

## 7a. Issue Ledger

`gh issue list --state open --search 'structured random-effect SD target resolver' --limit 10 --json number,title` returned no matching issue. No issue was opened or changed.

## 8. Consistency Audit

Public formula grammar, supported model routes, covariance equations, examples,
and pkgdown navigation did not change. Production structured-formula admission
remains incomplete; these resolver tests do not prove that model builders
supply valid metadata.

## 9. What Did Not Go Smoothly

The independent review caught that level validation alone left other identity
fields unchecked. The first `devtools::test()` red run also returned status
zero despite printing a failure. Later red/green runs used
`stop_on_failure = TRUE`.

## 10. Known Residuals

Structured formula parsing and production builder integration still need a
separate owner-coordinated implementation slice. This test covers manually
constructed resolver metadata, not public fitting, simulation, extraction,
prediction, save/reload, Julia parity, or interval coverage.

## 11. Team Learning

Set `stop_on_failure = TRUE` when a `devtools::test()` shell status will be used
as the verification result.

## 12. Cross-Product Coverage

This slice tested the shared R target resolver. It does NOT cover public
formula parsing, the TMB fitting engine, Julia, structured provider builders,
simulation, extraction, prediction, save/reload, or interval coverage. After
the shared builder owner releases the formula integration paths, add
end-to-end structured SD target admission and verify that production builders
populate provider, level, group, dpar, coefficient, and block consistently.
