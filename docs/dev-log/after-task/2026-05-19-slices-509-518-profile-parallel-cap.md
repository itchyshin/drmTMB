# After-Task Report: Slices 509-518 Profile Parallel Cap

## Active Perspectives

Ada implemented the developer-helper change. Fisher checked that the profile
helper still treats profile intervals as target-specific diagnostics rather
than a blanket cure for weak Hessians. Grace watched portability boundaries.
Rose recorded the 10-core cap so it is not just a remembered command-line
habit.

## Goal

Make the developer-only Ayumi profile fallback helper follow the same bounded
worker rule as the parametric-bootstrap prototype.

## Changes Made

- Added bounded parallel execution to
  `tools/ayumi-profile-fallback-correlations.R`.
- Added `DRMTMB_PROFILE_CORES`, capped at 10 and at the number of selected
  profile targets.
- Added `DRMTMB_PROFILE_BACKEND`, with supported values `none` and
  `multicore`.
- Recorded backend, requested cores, and actual cores in `preflight.csv`.
- Kept PSOCK profiling unsupported because fitted `TMB` objects carry external
  pointers; cross-session workers would need a refit-or-rebuild contract first.
- Updated the optimizer/start design note with the profile-worker cap.

## Checks Run

```sh
air format docs/design/35-optimizer-start-map-multistart.md tools/ayumi-profile-fallback-correlations.R
Rscript -e "invisible(parse(file = 'tools/ayumi-profile-fallback-correlations.R')); cat('profile helper parse ok\n')"
Rscript -e "invisible(parse(file = 'tools/ayumi-parametric-bootstrap-prototype.R')); cat('bootstrap helper parse ok\n')"
```

## Known Limitations

This was a helper hardening slice, not a rerun of the expensive Ayumi profile.
The previous bounded profile attempt still failed for the weak fallback target;
this slice makes multiple target attempts easier and better recorded, but it
does not turn a bad profile into valid uncertainty.

## Next Actions

Use the bounded helper only on direct targets whose selected optimum is already
defensible, or use it as a diagnostic when documenting a weak target failure.
