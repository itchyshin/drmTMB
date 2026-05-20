# Slices 1059-1068: First-Wave n_rep 3 Report Audit

## Goal

Ada ran a small real first-wave Phase 18 staging grid across the six baseline
surfaces, then audited the rendered report before scaling the simulation.

## Run

Command shape:

```r
phase18_run_first_wave_summary_smoke(
  output_dir = "inst/sim/results/slice-1059-first-wave-six-surface-nrep3",
  n_rep = 3L,
  master_seed = 20260531L,
  cores = 10L,
  backend = "multicore",
  overwrite = TRUE,
  render = TRUE,
  require_complete = TRUE
)
```

Output root:

- `inst/sim/results/slice-1059-first-wave-six-surface-nrep3/`

Rendered report:

- `inst/sim/results/slice-1059-first-wave-six-surface-nrep3/first-wave-summary/report/phase18-first-wave-summary.html`

Summary:

- Aggregate rows: 43.
- Replicate rows: 129.
- Wald coverage rows: 19.
- Profile coverage rows: 4.
- Manifest rows: 27.
- Manifest statuses: all `ok`.
- Warning/error ledger rows: 2 warning rows, both
  `collapsing to unique 'x' values` from the NB2 random-effect profile path.
- Requested cores: 10 for every surface.
- Actual workers by surface: 3, 9, 3, 3, 3, 3, 3.

## Report Audit

Pat/Rose source and plain-text checks found that the expected sections were
present: artifact status, aggregate operating characteristics, aggregate bias
overview, interval coverage, manifest summary, manifest ledger, warning/error
summary, warning/error ledger, reader checks, and interpretation boundary.

Florence found that the first aggregate-bias plot was not acceptable. Long
parameter labels were clipped on both sides of the figure, and the visual was
too close to the earlier figure-gallery problem where a technically rendered
plot was hard to read.

Ada changed the report so the aggregate-bias plot uses compact row-rank labels
on the y-axis and prints the full parameter names in a table below the plot.
The extracted audit image is:

- `docs/dev-log/figure-audits/slice-1059-first-wave-six-surface-nrep3/report-image-01.png`

## Validation

Focused report validation:

```sh
Rscript -e "devtools::test(filter = '^phase18-(first-wave-summary-report|first-wave-summary-smoke-runner)$')"
```

Result:

- 48 expectations passed, 0 failures, 0 warnings, 0 skips.

Additional checks:

- The rendered report was converted to plain text with `pandoc -t plain` and
  inspected for section order and warning-ledger content.
- The embedded aggregate-bias PNG was extracted from the rendered HTML and
  visually inspected.

## Team Learning

- Ada: loading the package namespace is required before running private
  simulation scripts directly from `Rscript`; otherwise forked workers cannot
  resolve `drmTMB()`.
- Curie: the `n_rep = 3` run is now a useful staging artifact beyond the
  earlier smoke runs.
- Fisher: coverage and bias summaries are plumbing evidence only at
  `n_rep = 3`; they should not be interpreted as final operating
  characteristics.
- Florence: aggregate screening plots must not put full internal parameter
  names on axes when many surfaces are combined.
- Pat: the report now gives a readable plot plus a lookup table for full
  parameter names.
- Grace: focused report and runner tests pass after the visual/report change.
- Rose: keep the browser-policy limitation in mind; local `file://` report
  inspection had to use source, plain-text, and extracted-image checks instead.

## Known Limitations

- Browser inspection of the local `file://` HTML was blocked by the browser
  URL policy, so the audit used rendered HTML text, CSV tables, and extracted
  embedded images.
- The duplicate NB2 warning should be cleaned or de-duplicated before a larger
  reporting run.
- This is still a small staging grid; it is not a final simulation study.

## Next Actions

1. Fix or de-duplicate the NB2 `collapsing to unique 'x' values` warning.
2. Add the same rank-plus-lookup pattern to any future aggregate screening
   figures with long internal parameter labels.
3. Move the interval-heavy Student-t and `rho12` lane to a similarly small
   real grid before scaling the first-wave baseline further.
