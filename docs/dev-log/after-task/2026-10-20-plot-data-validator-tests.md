# Fit-free tests for the plot data validators

## 1. Goal

Characterise the input validators and data helpers behind `plot_corpairs()` and
`plot_parameter_surface()` with hand-built tables, no fits and no drawing.

## 2. Implemented

New `tests/testthat/test-plot-data-validators.R` (124 expectations). It calls
`drmTMB:::` helpers in `R/plot-corpairs.R` and `R/plot-parameter-surface.R`:
the `validate_*_data/_column/_flag/_interval_style` validators,
`filter_plot_parameter_surface_data()`, the y-label and ribbon helpers, the
`add_*_columns()` helpers, `plot_corpairs_labels()` and the interval and eye
data helpers.

## 3a. Decisions and Rejected Alternatives

The `*_mapping()` helpers call `ggplot2::aes()`, so testing them needs
`skip_if_not_installed("ggplot2")`. A new file with a skip would add a row to
`inst/extdata/env-skip-census.tsv`, which this lane must not edit, so those
assertions were left to the existing plot test files.

## 4. Files Touched

The new test file and this note. No `R/`, NEWS, DESCRIPTION or census change.

## 5. Checks Run

The new file: 0 failures, 0 skips, 124 passes. `test-env-skip-census.R`: 5 passes.

## 6. Tests of the Tests

Characterisation only: the tests pass on main by design. No current behaviour
looked like a bug.

## 7. Post-review title correction (2026-10-22)

The original `plot_corpairs_eye_data()` test title claimed symmetry in `z`, but
the assertions checked empty input, row count, ordered bounds, requested eye
height, group and colour. The title now describes those checks; no assertion or
scientific scope changed. After this correction,
`Rscript -e 'devtools::test(filter="plot-data-validators", reporter="summary")'`
completed successfully on R 4.6.0. The focused run did not exercise the live
Julia engine. Current test-file SHA-256:
`da2a0b562c846510ef1679f4c3e3252c0deafba3a2bd3a169c9534a8ec46ad68`.
