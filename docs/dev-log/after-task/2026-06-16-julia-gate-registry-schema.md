# After Task: Julia Gate Registry Schema

## Goal

Make the `drmTMB#544` bridge-gate ledger useful as governance data, not only as
a list of named failures. This slice keeps every current `engine = "julia"`
rejection intentional while adding the fields needed for a generated bridge
table and future dashboard checks.

## Implemented

- Extended `drm_julia_intentional_gates()` with row-oriented metadata:
  `family_type`, `syntax`, `r_bridge_status`, `drmjl_status`,
  `message_pattern`, `review_due`, and `evidence_url`.
- Kept all current rows as `r_bridge_status = "intentional_error"` and
  `action = "error"`; no bridge gate was relaxed.
- Moved the representative gate-test regex source into the registry so tests and
  governance data use the same message pattern.
- Cross-linked cross-family bridge rows to `gllvmTMB#488` because those rows are
  part of the shared R/Julia bridge-claim discipline.

## Mathematical Contract

No model likelihood, formula grammar, or estimator changed. This is a bridge
governance slice: it records why R-side Julia bridge calls are rejected today and
requires a representative test for each gate before a future PR can promote or
remove the gate.

## Files Changed

- `R/julia-bridge.R`
- `tests/testthat/test-julia-gate-vs-engine.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-16-julia-gate-registry-schema.md`

## Checks Run

- `air format R/julia-bridge.R tests/testthat/test-julia-gate-vs-engine.R`
  - Result: clean.
- `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R", reporter = "summary")'`
  - Result: all tests in `test-julia-gate-vs-engine.R` passed.
- `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R", reporter = "summary")'`
  - Result: all tests in `test-julia-bridge.R` passed.
- `git diff --check`
  - Result: clean.
- `rg "non-identified|nonidentified|flat/unbounded|Bayesian only reads back the prior|REML on scale" R tests docs README.md ROADMAP.md NEWS.md`
  - Result: only existing Ayumi reframe notes were found; this slice added no
    new forbidden framing.

## Tests Of The Tests

The helper now asserts that each explicit expected error regex matches the
registry's `message_pattern`, then uses the registry value for the actual
`expect_error()` call. If a future edit changes the user-facing gate text or
adds a new gate without updating the registry, the representative test fails.

## Consistency Audit

The code path checked here is `drmTMB_julia_bridge()` and its structured,
bivariate, and cross-family bridge guards. This slice did not change any
user-facing examples, pkgdown navigation, roxygen exports, `src/drmTMB.cpp`, or
the binomial family contract. The status inventory for new model support is not
applicable because no model capability was added.

## GitHub Issue Maintenance

This work belongs to the existing `drmTMB#544` bridge-gate epic. No duplicate
issue was opened. The PR and final status should be linked back to `#544`.

## What Did Not Go Smoothly

The main constraint was avoiding overlap with the finish-board PR, which already
documents the larger capability-matrix contract. This slice intentionally
avoids those dashboard and design-doc files so it can merge as a small bridge
test hardening PR.

## Team Learning

Rose's useful rule here is that "unsupported" needs both a user-facing error
and a ledger row. Emmy's rule is that the row should carry enough metadata for a
dashboard or generated table without parsing prose from test files.

## Known Limitations

The registry is still manually curated. It does not yet scan all bridge errors,
compare against a live DRM.jl capability table, or fail documentation that
claims more than the registry supports. Those remain the next `#544` slices.

## Next Actions

1. Generate or render the bridge gate table from this registry.
2. Add a CI guard that compares bridge docs and registry rows.
3. Promote individual gates only in PRs that add parity evidence and update the
   registry, tests, and dashboard row together.
