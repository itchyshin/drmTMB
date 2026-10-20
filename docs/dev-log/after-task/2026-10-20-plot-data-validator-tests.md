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
