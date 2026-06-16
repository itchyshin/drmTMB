# After Task: Julia Gate Generated Table

## Goal

Turn the `drmTMB#544` bridge-gate registry into a rendered, validated dashboard
artifact. The previous slice enriched the internal registry; this slice makes
that registry visible and keeps the static dashboard table synchronized with
the R-side source of truth.

## Implemented

- Added `tools/write-julia-gate-registry.R` to generate both
  `docs/dev-log/dashboard/julia-gates.tsv` and
  `inst/extdata/julia-gates.tsv` from
  `drm_julia_intentional_gates()`.
- Added the generated `julia-gates.tsv` artifacts with 15 intentional
  `engine = "julia"` gate rows. The dashboard copy serves the widget; the
  installed copy lets R CMD check compare the artifact inside `*.Rcheck`.
- Added a dashboard "Bridge gate registry" table that renders the generated
  gate rows.
- Extended `tools/validate-mission-control.py` so the mission-control validator
  checks the generated gate table schema, row IDs, issue/evidence links, and
  intentional-error status.
- Added a test that compares `julia-gates.tsv` with the internal R registry,
  field for field.
- Bumped the dashboard build to `r6` and updated status rows for the generated
  #544 table slice.

## Mathematical Contract

No model likelihood, formula grammar, estimator, or bridge support changed. All
rows remain intentional R-side `engine = "julia"` rejections. The generated
table is evidence governance, not support promotion.

## Files Changed

- `tools/write-julia-gate-registry.R`
- `docs/dev-log/dashboard/julia-gates.tsv`
- `inst/extdata/julia-gates.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-julia-gate-vs-engine.R`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-16-julia-gate-generated-table.md`

## Checks Run

- `Rscript tools/write-julia-gate-registry.R`
  - Result: wrote 15 rows to `docs/dev-log/dashboard/julia-gates.tsv` and
    `inst/extdata/julia-gates.tsv`.
- `air format tools/write-julia-gate-registry.R tests/testthat/test-julia-gate-vs-engine.R`
  - Result: completed without changes after formatting.
- `cmp -s docs/dev-log/dashboard/julia-gates.tsv inst/extdata/julia-gates.tsv`
  - Result: generated artifacts are byte-identical.
- `python3 -m json.tool docs/dev-log/dashboard/status.json`
  - Result: JSON parsed.
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json`
  - Result: JSON parsed.
- `python3 tools/validate-mission-control.py`
  - Result: `mission_control_ok: 19/68 banked_or_verified, 3 active, 17 matrix rows, 10 finish rows, 15 Julia gate rows`.
- `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R", reporter = "summary")'`
  - Result: all tests in `test-julia-gate-vs-engine.R` passed.
- `R CMD build --no-manual --no-build-vignettes /private/tmp/drmtmb-julia-gate-table`
  - Result: the source tarball includes
    `drmTMB/inst/extdata/julia-gates.tsv`.
- `sh tools/start-mission-control.sh --background`
  - Result: dashboard served at `http://127.0.0.1:8765/`.
- In-app browser DOM check at desktop and mobile widths
  - Result: bridge-gate heading present, 15 gate rows rendered, quoted syntax preserved, #544 card shows active/covered status, mobile document width matches viewport.
- `npx playwright screenshot --full-page --viewport-size=1440,1200 http://127.0.0.1:8765/ /tmp/drmtmb-julia-gates-desktop.png`
  - Result: screenshot captured.
- `npx playwright screenshot --full-page --viewport-size=390,1400 http://127.0.0.1:8765/ /tmp/drmtmb-julia-gates-mobile.png`
  - Result: screenshot captured.
- `git diff --check`
  - Result: clean.
- `rg -n '^(<<<<<<<|=======|>>>>>>>)' docs R tests tools inst`
  - Result: no conflict markers.

## Tests Of The Tests

The new test reads every generated TSV artifact available in the current
context and compares it directly to `drm_julia_intentional_gates()`. In a
development checkout it sees the dashboard copy; in R CMD check it sees the
installed `inst/extdata` copy. A registry edit that does not regenerate the
artifacts, or a hand-edited row that does not match the registry, fails the
test.

## Consistency Audit

The slice keeps `#544` active rather than closed. The generated table, validator,
and test cover the current registry artifact. The remaining `#544` work is a
documentation-drift guard and comparison against DRM.jl capability evidence.
The mission-control live copy now includes `julia-gates.tsv`;
`tools/start-mission-control.sh` was updated so future serves copy the generated
artifact.

## GitHub Issue Maintenance

This continues `drmTMB#544`. The PR should be linked back to #544 after it is
opened. No duplicate issue is needed.

## What Did Not Go Smoothly

The dashboard uses a static artifact rather than calling R from the browser.
That is deliberate: the dashboard remains a simple static page, while the R test
and generator command enforce synchronization.

## Team Learning

Emmy's useful rule is now codified: the registry is row-oriented data, not prose.
Grace's reproducibility rule is that generated dashboard data need a generator,
a validator, and a test that compares against the runtime source.

## Known Limitations

The validator checks the generated table itself, not every public documentation
claim. A later #544 slice should lint bridge docs against the registry and
compare R-gated rows with a DRM.jl capability evidence table.

## Next Actions

1. Add a documentation-drift guard for public `engine = "julia"` claims.
2. Add a DRM.jl capability evidence table so covered Julia cells and R-side
   gates can be reviewed together.
3. Keep binomial bridge support unsupported until #569 native R/TMB support and
   separate bridge parity evidence are both present.
