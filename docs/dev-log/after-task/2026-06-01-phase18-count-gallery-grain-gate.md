# Phase 18 Count-Gallery Grain Gate

## Goal

Make the first figure-producing Phase 18 gallery require replicate-level grain
before it draws replicate-error points.

## Implemented

`phase18_count_gallery_has_replicates()` now returns `TRUE` only when the
candidate replicate table has the required plotting columns and
`artifact_grain = "replicate"` for every row. If a CSV has `error` columns but
is tagged as aggregate grain, the count gallery treats it as no replicate cloud
input and keeps the bias panel on aggregate mean errors plus MCSE bars.

## Files Changed

- `inst/sim/reports/phase18-count-mu-gallery.Rmd`
- `tests/testthat/test-phase18-count-gallery-template.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = '^phase18-count-gallery-(template|render-helper)$|^phase18-sim-plot-data$', reporter = 'summary')"
air format inst/sim/reports/phase18-count-mu-gallery.Rmd tests/testthat/test-phase18-count-gallery-template.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-phase18-count-gallery-grain-gate.md
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n "artifact_grain = \"replicate\"|artifact_grain|replicate-error clouds|fake.*cloud|pseudo-replicate|aggregate-only|Faint points are replicate-level errors" inst/sim README.md ROADMAP.md NEWS.md docs vignettes tests/testthat
rg -n "Slice 1829|Slice 1830|Slice 1831|136\\. Slice 1829|137\\. Slice 1830|138\\. Slice 1831|236\\. Slice 1829|237\\. Slice 1830|238\\. Slice 1831" docs/design/41-phase-18-simulation-programme.md
git diff --check
```

Outcome:

- The focused count-gallery template, count-gallery render-helper, and
  sim-plot-data tests passed together.
- `air format` completed with no output.
- `pkgdown::check_pkgdown()` returned `No problems found`.
- The artifact-grain stale-wording scan found the new count-gallery gate plus
  historical pseudo-replicate audit notes; the current count gallery requires
  `artifact_grain = "replicate"` before cloud-style bias points are drawn.
- The design-ledger ordering scan found Slice 1829, 1830, and 1831 only at the
  current ledger tail as rows 236-238.
- `git diff --check` passed.
- The prose pass checked that the README, design note, ROADMAP row, check-log,
  and this after-task note describe a display gate, not new simulation evidence.

## Tests Of The Tests

The template test now covers both paths:

- the normal rendered CSV fixture includes `artifact_grain = "replicate"`;
- a negative rendered smoke supplies `artifact_grain = "aggregate"` while still
  including `error`, `term`, `family`, and `parameter_class` columns.

The negative smoke verifies that a table with the right-looking error columns
does not become cloud input unless its grain is replicate-level.

## Consistency Audit

The README, Phase 18 design note, ROADMAP, and check log now state the same
rule: count-gallery replicate-error points require
`artifact_grain = "replicate"`. This change does not add simulation evidence,
dispatch a grid, alter likelihoods, or change formula grammar. The design note
also keeps the recent 1829-1831 ledger entries at the current tail rather than
duplicating ordinal labels before older first-wave entries.

## GitHub Issue Maintenance

This slice advances #255 and #59. The remaining #255 work is to apply the same
gate wherever later Phase 18 report or gallery code draws cloud-style
replicate displays.

## What Did Not Go Smoothly

The first rendered-test assertions looked for ggplot subtitle text in the HTML.
Those strings are embedded inside images rather than plain HTML text, so the
test now checks rendered success plus the source-level grain predicate.

## Team Learning

Figure templates should check artifact grain directly, not infer replicate
status from column names alone. This prevents future report code from creating
fake clouds from aggregate-shaped tables.

## Known Limitations

- This slice gates the count-pilot gallery only.
- The broader Phase 18 figure layer still needs a shared helper or convention
  for cloud eligibility across future report templates.

## Next Actions

Promote the count-gallery predicate into a shared helper if another Phase 18
gallery needs to draw replicate-error clouds.
