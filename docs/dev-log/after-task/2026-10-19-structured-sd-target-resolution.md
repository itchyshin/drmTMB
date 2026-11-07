# After Task: Structured Random-Effect SD Target Identity

## 1. Goal

Allow the shared SD-target resolver to identify structured targets by level while retaining ordinary group-level targets and clear ambiguity errors.

## 2. Implemented

The resolver now uses provider and level metadata when filtering candidate SD targets. It supports an explicit structured level selector and includes provider and level in candidate descriptions. Tests use the package's actual `provider = "phylo", level = "phylogenetic"` metadata and cover ambiguity between two structured providers. Family and engine admission remain separate from identity resolution.

## 3a. Decisions and Rejected Alternatives

The resolver does not infer that a target can be fitted just because its identity can be selected. Likelihood builders still decide which combinations are implemented. This keeps target naming separate from model support.

## 4. Files Touched

- `R/random-effect-targets.R`
- `tests/testthat/test-structured-sd-targets.R`
- `docs/dev-log/check-log.d/2026-10-19-structured-sd-target-resolution.md`
- `docs/dev-log/after-task/2026-10-19-structured-sd-target-resolution.md`

## 5. Checks Run

- Focused parser and resolver tests passed with `devtools::test(filter = "random-effect-targets|structured-sd-targets|parse-formula", reporter = "summary")`, including four structured-target expectations.
- `git diff --check` passed on the changed code and test paths.
- Exact-path lane preflight found no missing foreign changes on the leased source file and no other-ref work on the new test path.

## 6. Tests of the Tests

Before the implementation, the four initial structured-target tests failed with the existing structured-resolver refusal. The independent review then caught a provider-name mismatch in the fixtures and requested a two-structured-candidate ambiguity case. The fixtures now use `provider = "phylo"`; the expanded tests pass for explicit level selection, ordinary-versus-structured ambiguity, phylo-versus-spatial ambiguity, and a no-match error with available candidates. Existing ordinary-target and formula-parser tests also pass in the same focused run.

## 7a. Issue Ledger

No issue was opened, updated, or closed. This internal target-identity slice does not establish a new model-support claim.

## 8. Consistency Audit

The existing formula grammar already documents structured selectors. This change aligns internal target resolution with that identity syntax and leaves the documented structured-fitting limitations intact. The independent architecture review found no structured-fitting admission path: current fitting candidates still come from the ordinary-member builder. No public reference page, vignette, NEWS entry, or package navigation changed.

## 9. What Did Not Go Smoothly

The shared lane-lease registry was initially inaccessible from the sandbox. I requested the narrow lease escalation and verified that both new report paths were registered before writing them.

The project slop checker found no flagged phrases. Formal writing-naturalness assessment: NOTASSESSED.

## 10. Known Residuals

This change does NOT implement structured SD likelihoods, structured-effect simulation, parameter recovery, calibrated uncertainty, cross-engine agreement, or public fit support. The full family/effect/backend programme remains active, and its acceptance gates remain open.

## 11. Team Learning

Keep target identity resolution separate from family and engine capability checks. Tests should demonstrate both successful identity selection and a useful failure when the requested structured level is absent.

## 12. Cross-Product Coverage

This slice covers only SD-target identity resolution and its R parser/resolver tests. It does NOT cover fitting, prediction from a structured fit, recovery, uncertainty calibration, Julia, other families, or any newly supported random-effect type.

## Next Actions

Continue with an independently owned model route; shared likelihood files remain under active cross-lane edits and need an explicit owner handoff before this lane changes them.
