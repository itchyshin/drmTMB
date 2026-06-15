# After Task: Julia Bridge Gate-ID Coverage

## Goal

Tighten the first `drmTMB#544` guard slice after Rose's audit. The intentional
Julia bridge gate registry already named each R-side rejection, but the registry
test did not assert the complete expected `gate_id` set. A future edit could add
or rename a registry row without making that drift obvious.

## Implemented

- Added the exact expected `gate_id` vector to
  `tests/testthat/test-julia-gate-vs-engine.R`.
- The registry test now checks that `drm_julia_intentional_gates()` has exactly
  those 15 gate IDs, in addition to the existing uniqueness, action, evidence,
  and issue checks.

## Claim Boundary

This is a CI-guard hardening slice only. It does not relax any bridge gate, add
a new Julia-engine route, or complete the generated/audited comparison against a
future DRM.jl exported capability table.

## Files Changed

- `tests/testthat/test-julia-gate-vs-engine.R`

## Checks Run

- `air format tests/testthat/test-julia-gate-vs-engine.R`
- `Rscript -e "devtools::test(filter = 'julia-gate-vs-engine', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'julia-bridge', reporter = 'summary')"`
- `git diff --check`

## Result

The focused `julia-gate-vs-engine` suite passed locally after the added coverage
assertion. The broader `julia-bridge` suite and whitespace check also passed.

## Next Actions

1. Keep `drmTMB#544` open for the generated/audited gate-versus-engine matrix.
2. When DRM.jl gains or exports a bridge capability table, compare it against
   this R-side gate registry and promote stale gates with parity tests.
3. Do not promote public Julia bridge claims until the matching R bridge tests,
   docs, and issue evidence are present.
