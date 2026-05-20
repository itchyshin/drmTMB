# Slices 809-818: Phase 18 First-Wave Real Summary Smoke

## Goal

Ada ran the first tiny end-to-end first-wave report smoke using actual
grid-writer outputs instead of synthetic test fixtures.

## Run

The local ignored output folder is:

`inst/sim/results/slice-809-first-wave-summary-smoke/`

The smoke ran:

- Gaussian location-scale grid writer with one replicate;
- `meta_V(V = V)` grid writer with vector and dense known-`V` cells;
- first-wave artifact-status writer;
- first-wave table-bundle writer;
- first-wave summary-report renderer.

The rendered HTML is:

`inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/report/phase18-first-wave-summary.html`

## Evidence

The generated artifact-status table has two surfaces:

- `gaussian_ls_grid`
- `meta_v_grid`

The generated bundled aggregate table has 13 rows. The report HTML contains the
slice note, both surface names, the aggregate section, and the interval
diagnostics section.

## Checks Run

```sh
Rscript - <<'RS'
# Local smoke sources inst/sim helpers, writes ignored results, and renders HTML.
RS
test -f inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/report/phase18-first-wave-summary.html
rg -n "Slice 809|gaussian_ls_grid|meta_v_grid|Aggregate Operating Characteristics|Interval Diagnostics" inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/report/phase18-first-wave-summary.html
find inst/sim/results/slice-809-first-wave-summary-smoke -maxdepth 3 -type f | sort
wc -l inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/status/phase18-first-wave-artifact-status.csv
wc -l inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv
```

Result:

- The report rendered successfully.
- Artifact status: 2 data rows plus header.
- Bundled aggregate: 13 data rows plus header.

## What Did Not Go Smoothly

The first attempt used `system.file()` from a plain `Rscript`, which could not
see the newly added uninstalled `inst/sim/run` helper files. Ada reran with
`devtools::load_all()` and local `inst/` source paths, which is the correct
local-development route before installation.

## Team Learning

- Ada: the report-staging helpers work against real grid-writer outputs, not
  only fake fixtures.
- Curie: this is still a tiny smoke, so it verifies plumbing rather than
  operating-characteristic stability.
- Fisher: Gaussian and known-`V` rows can coexist in the first-wave aggregate
  bundle while retaining source-surface provenance.
- Pat: the rendered HTML is now a concrete page a reader can inspect.
- Grace: generated outputs live under ignored `inst/sim/results/`, keeping the
  git diff light.
- Rose: the first end-to-end report pipeline has both test evidence and a real
  local artifact.

## Known Limitations

- This run is not a formal Phase 18 grid or coverage claim.
- It used only Gaussian location-scale and `meta_V(V = V)` surfaces.
- The rendered report is table-first and does not yet include Florence-facing
  figures.

## Next Actions

1. Add a small figure/table polish pass for the first-wave summary report, or
   run the same report smoke with one count surface added.
2. Keep the generated result folder ignored unless a deliberate artifact
   snapshot is needed later.
