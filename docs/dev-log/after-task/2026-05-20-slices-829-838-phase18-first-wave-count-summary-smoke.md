# Slices 829-838: Phase 18 First-Wave Count Summary Smoke

## Goal

Ada expanded the tiny real first-wave summary smoke so the rendered report
combines continuous, meta-analysis, and count mixed-model surfaces.

## Run

The local ignored output folder is:

`inst/sim/results/slice-829-first-wave-summary-count-smoke/`

The smoke ran:

- Gaussian location-scale grid writer with one replicate;
- `meta_V(V = V)` grid writer with vector and dense known-`V` cells;
- paired Poisson/NB2 `mu` random-effect grid writer with one replicate per
  family;
- first-wave artifact-status writer;
- first-wave table-bundle writer;
- first-wave summary-report renderer.

The rendered HTML is:

`inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/report/phase18-first-wave-summary.html`

## Evidence

The artifact-status table has three surfaces:

- `count_mu_random_effect_grid`
- `gaussian_ls_grid`
- `meta_v_grid`

The bundled aggregate table has 23 rows. The bundled profile-coverage table has
4 rows from the count surface. The rendered report shows all three surfaces in
the aggregate section.

## Checks Run

```sh
Rscript - <<'RS'
# Local smoke sources inst/sim helpers, writes ignored results, and renders HTML.
RS
test -f inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/report/phase18-first-wave-summary.html
rg -n "Slice 829|count_mu_random_effect_grid|gaussian_ls_grid|meta_v_grid|profile|Aggregate Operating Characteristics" inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/report/phase18-first-wave-summary.html
wc -l inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/status/phase18-first-wave-artifact-status.csv
wc -l inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv
wc -l inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/tables/phase18-first-wave-profile-coverage.csv
```

Result:

- The report rendered successfully.
- Artifact status: 3 data rows plus header.
- Bundled aggregate: 23 data rows plus header.
- Bundled profile coverage: 4 data rows plus header.

## Mathematical Contract

No new estimand or interval method was introduced. This smoke exercises the
existing count `mu` random-effect profile interval artifacts inside the
first-wave report-staging pipeline.

## Team Learning

- Ada: the first-wave report can now combine continuous, meta-analysis, and
  count mixed-model artifacts in one page.
- Curie: count profile artifacts stay visible after table bundling.
- Fisher: profile coverage rows remain separate from Wald coverage and
  aggregate metrics.
- Pat: the provenance-column polish makes the three-surface aggregate table
  readable.
- Grace: the generated result stays ignored and does not add bulky artifacts to
  git.
- Rose: this is still a smoke, but it is a better rehearsal of the real first
  wave than Gaussian/meta alone.

## Known Limitations

- This is a one-replicate smoke, not a formal operating-characteristic grid.
- The report remains table-first and still lacks Florence-facing figures.

## Next Actions

1. Add a small table-display polish to the report template, such as showing
   compact head rows or key columns first.
2. Decide whether to add a first simple figure to the first-wave report after
   the table display is less raw.
