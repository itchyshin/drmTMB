# Phase 18 Overnight Validation Slices 579-605

Reader: `drmTMB` contributors checking the overnight validation evidence for
the requested Slices 579-605 list.

This note records a current-state validation pass after the shared-runner
revalidation in `docs/design/80-phase-18-shared-runner-migration-audit.md`.
Older Phase 18 ledgers already used some of these slice numbers for May 19
work; this note is therefore a revalidation of the requested overnight slice
list, not a renumbering of the historical ledger.

## Validation Scope

The pass checked three layers:

1. Focused artifact/schema helpers for migrated Phase 18 surfaces.
2. The full `^phase18-` focused test suite.
3. Full package tests, pkgdown topic checks, and `R CMD check`.

No likelihood, formula grammar, public API, roxygen topic, or pkgdown
navigation changed in this validation slice.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 579-585 | Focused artifact and grid-writer validation for migrated surfaces | Grid-writer, aggregate, uncertainty, and interval-evidence tests passed |
| 586-593 | Higher-level report, Actions, and first-wave artifact validation | Report/status, table-bundle, first-wave, interval-heavy, and Actions tests passed |
| 594-599 | Broad Phase 18 focused validation | `devtools::test(filter = '^phase18-')` passed |
| 600 | Full package test suite | `devtools::test()` passed |
| 601-602 | pkgdown topic validation | `pkgdown::check_pkgdown()` reported no problems; no site rebuild was required because no pkgdown page or navigation changed |
| 603-605 | Package-level check and closeout | `devtools::check(error_on = 'never')` completed with 0 errors, 0 warnings, and 0 notes |

## Commands

```sh
Rscript -e "devtools::test(filter = 'phase18-(gaussian-ls-grid-writer|meta-v-grid-writer|count-mu-random-effect-grid-writer|nbinom2-sigma-random-effect|nbinom2-phylo-q1|sim-aggregate|sim-uncertainty|sim-interval-evidence)', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'phase18-(first-wave-artifact-status|first-wave-table-bundle|first-wave-summary-report|first-wave-summary-render-helper|first-wave-summary-smoke-runner|interval-heavy-summary-smoke-runner|actions-runner)', reporter = 'summary')"
Rscript -e "devtools::test(filter = '^phase18-', reporter = 'summary')"
Rscript -e "devtools::test(reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check(error_on = 'never')"
git diff --check
```

## Result

All listed checks passed. The package-level check completed in about 5 minutes
and 12 seconds with:

```text
0 errors | 0 warnings | 0 notes
```

The validation supports the execution and artifact infrastructure. It does not
turn smoke evidence into formal recovery evidence, and it does not promote any
NB2 structured-count neighbour beyond the boundaries recorded in the Slices
541-555 formal audit.
