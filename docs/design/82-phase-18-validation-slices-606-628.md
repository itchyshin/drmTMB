# Phase 18 Validation Slices 606-628

Reader: `drmTMB` contributors checking the remaining migrated-runner
validation after the requested overnight Slices 579-605 pass.

This note records a current-state validation pass over the parts of the
migrated Phase 18 runner surface that were not singled out in
`docs/design/81-phase-18-validation-slices-579-605.md`. Older Phase 18 ledgers
already used some nearby slice numbers for earlier work, so this file records
the requested May 24-25 follow-through rather than renumbering the historical
ledger.

## Validation Scope

Slices 606-628 check that the runner, artifact, interval, and report helpers
that sit around the migrated smoke surfaces still pass together. No likelihood,
formula grammar, public API, roxygen topic, or pkgdown navigation changed in
this block.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 606-611 | Runner and parallel-plan contract | `phase18-sim-runner` passed inside the focused bundle |
| 612-617 | Artifact, aggregate, uncertainty, and interval evidence helpers | Artifact-status, table-bundle, aggregate, uncertainty, interval-evidence, and interval-coverage tests passed |
| 618-623 | First-wave and rendered-report helper plumbing | First-wave summary report, render helper, smoke runner, and table-bundle tests passed |
| 624-628 | Actions and interval-heavy orchestration | Actions runner and interval-heavy summary runner tests passed |

## Commands

```sh
Rscript -e "devtools::test(filter = 'phase18-(actions-runner|first-wave-artifact-status|first-wave-table-bundle|first-wave-summary-report|first-wave-summary-render-helper|first-wave-summary-smoke-runner|interval-heavy-summary-smoke-runner|sim-runner|sim-aggregate|sim-interval-evidence|sim-uncertainty|interval-coverage-smoke|correlation-targets)', reporter = 'summary')"
```

## Result

The focused bundle completed with exit code 0. The passing test files were:

- `phase18-actions-runner`
- `phase18-correlation-targets`
- `phase18-first-wave-artifact-status`
- `phase18-first-wave-summary-render-helper`
- `phase18-first-wave-summary-report`
- `phase18-first-wave-summary-smoke-runner`
- `phase18-first-wave-table-bundle`
- `phase18-interval-coverage-smoke`
- `phase18-interval-heavy-summary-smoke-runner`
- `phase18-sim-aggregate`
- `phase18-sim-interval-evidence`
- `phase18-sim-runner`
- `phase18-sim-uncertainty`

The pass supports the simulation-infrastructure contract only. It does not
promote NB2 phylogenetic q1 smoke/formal evidence into broad structured-count
support, and it leaves NB2 `sigma` phylogeny, zero-inflated NB2 phylogeny, q4
count covariance, and higher-dimensional multivariate work out of scope.
