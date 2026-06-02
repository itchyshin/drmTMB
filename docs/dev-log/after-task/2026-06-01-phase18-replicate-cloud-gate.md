# Phase 18 Replicate-Cloud Gate

## Goal

Make the first-wave summary report use the artifact-grain preflight from issue
#255 before any cloud-style simulation display can be interpreted as allowed.

## Implemented

The summary report now derives a per-surface `replicate_cloud_gate` from
`artifact_grain_status_csv`. Surfaces with a replicate-ready artifact are marked
`replicate_clouds_allowed`; aggregate-only surfaces are marked
`aggregate_only_no_clouds`; surfaces without any usable replicate artifact are
marked `no_replicate_artifact_ready`.

The aggregate-bias overview remains an aggregate screening figure. Its
underlying rows now carry `replicate_cloud_gate`, so later report consumers can
see whether a surface can proceed to replicate-error clouds or must remain on
points, bars, and MCSE intervals.

## Files Changed

- `inst/sim/reports/phase18-first-wave-summary-report.Rmd`
- `tests/testthat/test-phase18-first-wave-summary-report.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = '^phase18-first-wave-summary-report$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^phase18-first-wave-(summary-report|summary-render-helper|table-bundle)$', reporter = 'summary')"
air format inst/sim/reports/phase18-first-wave-summary-report.Rmd tests/testthat/test-phase18-first-wave-summary-report.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-phase18-replicate-cloud-gate.md
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n "replicate_cloud_gate|Replicate Cloud Gate|replicate_clouds_allowed|aggregate_only_no_clouds|replicate-error clouds|fake.*cloud|pseudo-replicate|aggregate-only" inst/sim README.md ROADMAP.md NEWS.md docs vignettes tests/testthat
git diff --check
```

Outcomes:

- The focused summary-report test passed.
- The adjacent summary-report, summary-render-helper, and table-bundle tests
  passed together.
- `air format` completed with no output.
- `pkgdown::check_pkgdown()` returned `No problems found`.
- The gate/stale-wording scan found the new gate wording plus historical
  pseudo-replicate audit notes; current first-wave report wording keeps
  aggregate-only surfaces out of replicate clouds.
- `git diff --check` passed.
- A direct attempt to `parse()` the Rmd file failed on Rmd/YAML syntax. The
  rendered summary-report test is the valid check for this file type.
- The prose pass checked that the README, design note, ROADMAP row, check-log,
  and this after-task note state the same concrete gate without claiming new
  simulation evidence.

## Tests Of The Tests

The rendered report test now supplies an aggregate-only
`artifact_grain_status_csv` and checks that the rendered HTML contains
`Replicate Cloud Gate` and `aggregate_only_no_clouds`. That verifies the report
does more than display the raw grain-status table; it derives the gate that
downstream figure code should consume.

## Consistency Audit

The report, README, Phase 18 design note, and ROADMAP all now state the same
rule: replicate-error clouds require a replicate-ready artifact, while
aggregate-only surfaces stay on points, bars, and MCSE intervals. This change
does not add a new simulation grid, dispatch an Actions job, alter likelihoods,
or change formula grammar.

## GitHub Issue Maintenance

This slice advances issue #255 and the Phase 18 reporting work in #59. The
issue should remain open until later figure/report consumers use
`replicate_cloud_gate = "replicate_clouds_allowed"` as an enforced input
contract for every replicate-error cloud.

## What Did Not Go Smoothly

The first validation command tried to parse an Rmd file as plain R and failed.
That check is not appropriate for a Quarto/R Markdown template. The rendered
test path passed and is the relevant validation.

## Team Learning

Report templates should convert raw artifact status into an explicit plotting
gate before figure code grows around it. That keeps Florence and Fisher's
review rule close to the data object that later plots will consume.

## Known Limitations

- The gate is visible in the first-wave summary report, but no new
  publication-style replicate-cloud figure was added.
- Later figure helpers still need to enforce the gate before drawing clouds.

## Next Actions

Use `replicate_cloud_gate` in the next figure-producing Phase 18 helper or
report slice before adding any cloud-style display from first-wave artifacts.
