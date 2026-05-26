# After Task: Phase 18 First-Wave Summary Smoke Slices 809-818

## Goal

Validate and document the tiny first-wave summary smoke, including the saved
`slice-809` rendered artifact and the current smoke runner.

## Implemented

Added `docs/design/99-phase-18-first-wave-summary-smoke-slices-809-818.md` to
record the source, saved-artifact, and test evidence. No likelihood, formula
grammar, public API, roxygen topic, pkgdown navigation, or package site output
changed.

## Mathematical Contract

No model changed. The checked contract is smoke-scale staging. The saved
`slice-809` artifact contains Gaussian location-scale and `meta_V(V = V)`;
the current runner now stages the expanded first-wave set, but it still makes no
formal coverage, power, or operating-characteristic claim.

## Files Changed

- `docs/design/99-phase-18-first-wave-summary-smoke-slices-809-818.md`
- `docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-smoke-slices-809-818.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
find inst/sim/results -maxdepth 4 -path '*slice-809-first-wave-summary-smoke*' -type f | sort | head -n 80
test -f inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/report/phase18-first-wave-summary.html
rg -n "Slice 809|gaussian_ls_grid|meta_v_grid|Aggregate Operating Characteristics|Interval Diagnostics|Interpretation Boundary" inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/report/phase18-first-wave-summary.html
wc -l inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/status/phase18-first-wave-artifact-status.csv inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/tables/phase18-first-wave-wald-coverage.csv
nl -ba inst/sim/run/sim_run_first_wave_summary_smoke.R | sed -n '1,230p'
nl -ba tests/testthat/test-phase18-first-wave-summary-smoke-runner.R | sed -n '1,130p'
Rscript -e "devtools::test(filter = 'phase18-first-wave-summary-smoke-runner', reporter = 'summary')"
```

Results:

- The saved `slice-809` rendered HTML exists.
- Rendered HTML scans found `gaussian_ls_grid`, `meta_v_grid`, aggregate
  operating characteristics, interval diagnostics, and the interpretation
  boundary.
- The saved artifact-status CSV has 3 lines; aggregate and Wald-coverage bundle
  CSVs each have 14 lines.
- Source reads confirmed the current runner stages six grid-output groups and
  seven parallel-summary rows.
- The focused first-wave summary smoke-runner test completed with exit code 0.
- No files were staged or committed.

## Tests Of The Tests

The focused test runs the current smoke with `render = FALSE`, checks status and
table-bundle output paths, verifies seven parallel-summary rows and serial
fallback metadata, checks aggregate and interval table sizes, and exercises
malformed `output_dir`, `n_rep`, `master_seed`, and `notes` inputs.

## Consistency Audit

This report is smoke-scale staging only. It does not make formal coverage,
power, or operating-characteristic claims and does not add formula grammar,
likelihood code, roxygen topics, pkgdown navigation, or new user-facing API.

## GitHub Issue Maintenance

No GitHub issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

The roadmap entry for Slices 809-818 describes the historical saved artifact as
Gaussian location-scale plus `meta_V(V = V)`, while the current runner has
expanded to additional first-wave surfaces. This report records both facts
instead of flattening them into one claim.

## Team Learning

Saved smoke artifacts and current smoke runners can diverge as later slices add
surfaces. After-task reports should name the artifact actually on disk and the
current runner behavior separately.

## Known Limitations

The saved `slice-809` artifact is not a formal simulation run. The current
runner test uses `render = FALSE`; rendered expanded first-wave output belongs
to later smoke slices.

## Next Actions

Continue with Slices 819-828 by validating the polished summary smoke and
provenance-column expectations if the current dirty tree contains the matching
evidence.
