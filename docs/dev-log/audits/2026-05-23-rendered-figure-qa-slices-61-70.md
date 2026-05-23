# Rendered Figure QA: Slices 61-70

## Scope

Slices 61-70 continue the rendered-figure sweep after the convergence slice.
Ada chose the `large-data` article because the endpoint-profile work created a
real timing-evidence artifact, while the rendered article still had no figure.

This is a figure QA slice, not a new inference-engine slice. No package code,
likelihood, formula grammar, interval method, or benchmark harness changed.

## Figure Decisions

| Slice | Article | Figure chunk | Visual data grain | Uncertainty source | Verdict |
| --- | --- | --- | --- | --- | --- |
| 61 | `large-data` | audit target selected | article had interval-route prose but no rendered timing evidence | not applicable | improve |
| 62 | `large-data` | `large-data-profile-benchmark-timing` | elapsed seconds from `docs/dev-log/benchmarks/profile-scalar-endpoint-v2.csv` | none; single-run local timing measurements | keep point-only |
| 63 | `large-data` | `large-data-profile-benchmark-timing` | four successful direct scalar benchmark scenarios by engine | none; points are not confidence intervals | render |
| 64 | `large-data` | rendered PNG | log-scale timing comparison across `tmbprofile`, endpoint, and endpoint multicore | none | visually accepted |
| 65 | `large-data` | article checklist row | rendered HTML image count and next action | not applicable | updated |
| 66 | visualization grammar | benchmark-runtime rule | performance evidence contract | not applicable | updated |
| 67 | `large-data` | alt text | figure description names targets, engines, and direction of comparison | not applicable | present |
| 68 | `large-data` | caption/prose | caption says measurements are performance, not confidence intervals | not applicable | present |
| 69 | after-task/check-log | durable notes | validation evidence | not applicable | recorded |
| 70 | pull request | focused branch | one article figure plus visual-rule docs | not applicable | ready for PR after checks |

## Rendered Figure

Rendered image inspected directly:

`pkgdown-site/articles/large-data_files/figure-html/large-data-profile-benchmark-timing-1.png`

Florence accepted the rendered image because the comparison is visible at first
glance, the log axis prevents the long `TMB::tmbprofile()` rows from flattening
the endpoint rows, the palette is not one-note, and the legend fits without
covering the data. The figure is intentionally not a Confidence Eye.

Fisher accepted the data grain because the marks are elapsed seconds from a
single benchmark artifact. There are no interval bars, ribbons, or density
shapes because the benchmark table does not contain repeated timing uncertainty.

Pat accepted the article placement because the figure appears immediately after
the interval-route guidance and before the broader fit-diagnostic checklist.
The reader sees the operational consequence of choosing Wald, endpoint profile,
full profile, or bootstrap routes without reading the benchmark CSV.

Rose recorded the pattern: timing evidence needs its own visual grammar. It
should not inherit the estimate-uncertainty rules from Confidence Eyes.

## Remaining Limits

The figure is local development evidence from one machine and one benchmark
artifact. It supports cautious planning for direct scalar endpoint profiles
only. It does not prove general speedup for fixed effects, `newdata` profiles,
derived targets, non-Gaussian models, bivariate models, or 10,000-species
production fits.
