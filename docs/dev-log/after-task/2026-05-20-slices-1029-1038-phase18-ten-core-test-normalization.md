# Slices 1029-1038: Phase 18 Ten-Core Test Normalization

## Goal

Ada aligned the active Phase 18 smoke, grid-writer, runner, and bootstrap tests
with the requested 10-core ceiling.

## Change

- Updated runner/grid/bootstrap test calls that did not need an oversized
  request so they now request `10L` cores.
- Kept cap-testing logic meaningful by using `11L` only in pure
  parallel-plan checks that verify clamping to 10 and do not launch workers.
- Confirmed that active test, `inst/sim`, design, check-log, and after-task
  paths no longer contain command-style oversized core requests.

## Validation

Command:

```sh
Rscript -e "devtools::test(filter = '^phase18-(gaussian-ls-grid-writer|meta-v-grid-writer|biv-rho12-grid-writer|student-shape-grid-writer|count-mu-random-effect|random-slope-grid-writers|sim-bootstrap|sim-runner|student-shape-summary-smoke|biv-rho12-summary-smoke|first-wave-summary-smoke-runner|interval-heavy-summary-smoke-runner)$')"
```

Result:

- 266 expectations passed, 0 failures, 0 warnings, 0 skips.
- Duration: 35.0 seconds.

## Team Learning

- Ada: the 10-core ceiling is now visible in active tests, not only in runtime
  behavior.
- Curie: the deterministic smoke tests still cover the same runner outputs
  after the requested-core cleanup.
- Grace: the focused rerun is clean and quick enough for routine validation.
- Rose: this removes a likely source of future confusion when reading the test
  suite against the user's 10-core instruction.

## Known Limitations

- Historical Ayumi convergence notes may still mention 20-core exploratory
  settings; those are archival records, not active runner defaults.
- A full-suite rerun is still useful after this test-only cleanup.

## Next Actions

1. Rerun the full package test suite on the current tree.
2. Run `git diff --check` and checkpoint before stopping.
