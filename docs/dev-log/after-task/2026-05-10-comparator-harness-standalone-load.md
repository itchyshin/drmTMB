# After Task: Comparator Harness Standalone Loading

## Goal

Make the optional Gaussian location-scale comparator harness work as a
standalone command from the package root.

## Implemented

- Changed `tools/replicate-location-scale-gaussian.R` so a package-root run
  uses `devtools::load_all()` before falling back to an installed `drmTMB`
  namespace.
- If the script is not run from the package root, it now attaches an installed
  `drmTMB` package before calling `drmTMB()` and `bf()`.

## Checks Run

- `air format tools/replicate-location-scale-gaussian.R docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-comparator-harness-standalone-load.md`:
  passed.
- `git diff --check`: passed.
- `Rscript tools/replicate-location-scale-gaussian.R`: passed. Both comparator
  rows reported `passed = TRUE`; the largest absolute coefficient difference
  was about `6.7e-06`.

## Known Limitations

The script remains an optional local comparator harness. It requires
`glmmTMB`, and it does not validate future covariance blocks.
