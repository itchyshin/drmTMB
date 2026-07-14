# Q-Series v1.0 Release Status

Generated from `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
and `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv` by
`tools/qseries_v1_release_ledger.py`.

## Summary

This is a release-planning boundary, not a support promotion. The Q-Series board
currently has 104 support cells: 67 Gaussian rows
and 37 non-Gaussian rows. The pragmatic v1.0 surface has
104 row-level roles: 8 exact Gaussian
`inference_ready` anchors, 59 additional Gaussian
basic-working rows, 27 non-Gaussian recovery
rows, and 10 non-Gaussian diagnostic-only rows. The
remaining 0 rows stay in post-v1.0 validation or design.

There are 0 `supported` authority rows. This summary
does not authorize coverage, q4 coverage, support-cell promotion,
`inference_ready` promotion, `supported` wording, REML, AI-REML, or public
support.

## Progress Accounting

These percentages are row-accounting summaries, not package-release completion
claims.

| Measure | Rows | Percent | Meaning |
| --- | ---: | ---: | --- |
| Practical v1.0 row surface | 104/104 | 100.0% | Exact Gaussian anchors plus additional Gaussian basic-working rows and non-Gaussian recovery or diagnostic-only rows. |
| Gaussian v1.0 core | 67/67 | 100.0% | Gaussian rows inside the exact-anchor or basic-working v1.0 surface. |
| Basic-distribution recovery evidence | 27/37 | 73.0% | Non-Gaussian rows with point-fit recovery evidence. |
| Basic-distribution diagnostic only | 10/37 | 27.0% | Non-Gaussian rows with fit/extractor evidence that does not establish point-estimate recovery. |
| Exact `inference_ready` anchors | 8/104 | 7.7% | Row-local exact Gaussian inference anchors; no neighbour rows inherit this status. |
| `supported` authority | 0/104 | 0.0% | Structured rows with support authority; this remains zero. |
| Post-v1.0 validation/design | 0/104 | 0.0% | Rows deliberately left outside the v1.0 practical surface. |

## Release Tracks

| Track | Rows | v1.0 role | Boundary |
| --- | ---: | --- | --- |
| `gaussian_inference_anchor` | 8 | Exact row-local Gaussian inference anchors. | Keep row-local; no neighbour, q4/q8, `supported`, REML, AI-REML, new coverage, or public-support promotion. |
| `gaussian_basic_working` | 59 | Implemented/basic-working Gaussian rows for the v1.0 surface. | Basic-working is not interval evidence, coverage evidence, `inference_ready`, `supported`, REML, AI-REML, or public support. |
| `basic_distribution_recovery` | 37 | Legacy track ID containing 27 recovery rows and 10 diagnostic-only rows. | Diagnostic-only rows do not establish point-estimate recovery; neither tier supplies interval evidence, coverage evidence, `inference_ready`, `supported`, REML, AI-REML, or broad structured-covariance support. |
| `gaussian_post_v1_validation` | 0 | Gaussian rows outside the v1.0 basic-working surface. | Leave for post-v1.0 implementation, rejection, interval, or coverage review. |
| `basic_distribution_post_v1_design` | 0 | Non-Gaussian rows outside the v1.0 basic-distribution surface. | Leave for post-v1.0 family-specific implementation, rejection, or limitation design. |

## Recommended v1.0 Wording

`drmTMB` v1.0 can describe the Q-Series as having an audited
implemented/basic-working Gaussian structured-random-effect surface and a
non-Gaussian fitted surface with 27 recovery
rows and 10 diagnostic-only rows. Exactly
8 Gaussian rows are row-local `inference_ready`, and no
structured row is `supported`.

## Forbidden Wording

Do not describe the Q-Series as complete, broadly supported, fully
inference-ready, or coverage-ready. Do not claim q4/q8 coverage, derived
correlation intervals, non-Gaussian structured covariance support, broad bridge
support, REML, AI-REML, or public support from this release status.

## Next Gates

Before v1.0 release wording is final, keep `README.md`, `NEWS.md`,
`ROADMAP.md`, and `docs/dev-log/known-limitations.md` aligned with this file.
Post-v1.0 validation can reopen full `inference_ready` and `supported` work one
row at a time.
