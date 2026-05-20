# Slices 989-998: Phase 18 Focused Interval Validation

## Goal

Ada validated the first-wave staging, interval-heavy staging, Student-t shape,
and bivariate residual `rho12` lanes together after adding the new runners and
smokes.

## Validation

Command:

```sh
Rscript -e "devtools::test(filter = '^phase18-(first-wave|interval-heavy|student-shape|biv-rho12)')"
```

Result:

- 260 expectations passed, 0 failures, 0 warnings, 0 skips.

## Scope Covered

The focused bundle covered:

- first-wave artifact status, status report, table bundle, summary report, and
  six-surface smoke runner;
- interval-heavy summary smoke runner;
- Student-t shape grid writer, runner, and summary smoke;
- bivariate residual `rho12` grid writer, runner, and summary smoke.

## Team Learning

- Ada: the new report-staging runners are coherent with the existing
  Student-t and `rho12` simulation lanes.
- Curie: focused validation now covers both the baseline first-wave bundle and
  interval-heavy surfaces.
- Fisher: Wald, profile, and bootstrap evidence paths remain method-separated.
- Grace: no warnings appeared in the focused validation bundle.
- Pat: report and runner tests still pass through rendered-document paths.
- Rose: this gives a clean checkpoint before either larger grids or final
  overnight summary.

## Known Limitations

- This is not a full package test.
- It does not rerun pkgdown or `devtools::check()`.

## Next Actions

1. Run a final `git diff --check` and recovery checkpoint before 3:30.
2. If time remains, run a broader `^phase18-` focused validation.
