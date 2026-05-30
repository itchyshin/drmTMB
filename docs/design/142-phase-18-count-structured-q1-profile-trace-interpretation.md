# Phase 18 Count Structured q1 Profile Trace Interpretation

This note interprets the selected-example profile-trace artifacts for an R
package contributor or statistical-method reviewer. The purpose is to decide
what the trace diagnostic has ruled out before the `count_structured_q1` lane
gets another profile-setting change or a larger recovery grid.

## Inputs

The local selected-example trace writer smoke used the three examples selected
from GitHub Actions run `26669005577` and wrote:

- `/private/tmp/drmtmb-count-structured-q1-profile-trace-summary-writer-20260530/tables/count-structured-q1-profile-trace.csv`;
- `/private/tmp/drmtmb-count-structured-q1-profile-trace-summary-writer-20260530/tables/count-structured-q1-profile-trace-summary.csv`;
- `/private/tmp/drmtmb-count-structured-q1-profile-trace-plot-writer-20260530/figures/count-structured-q1-profile-trace.png`.

The trace plan crosses each selected example with the current `ystep = 0.50`
profile pass and a smaller `ystep = 0.25` pass. The target is the public direct
structured-SD profile label: `sd:mu:spatial(1 | site)` for the spatial
examples and `sd:mu:animal(1 | id)` for the animal example.

## What the Trace Shows

All six selected-example profile passes produced likelihood-ratio trace rows.
The trace status was `ok` for every selected cell and profile pass, with no
failed trace rows:

| Example role | Cell | Replicate | Profile pass | Trace rows | Failed trace rows |
| --- | --- | ---: | --- | ---: | ---: |
| Larger crossing estimate | `count_structured_q1_001` | 25 | `current` | 38 | 0 |
| Larger crossing estimate | `count_structured_q1_001` | 25 | `smaller_ystep` | 45 | 0 |
| Minimum crossing estimate | `count_structured_q1_003` | 33 | `current` | 39 | 0 |
| Minimum crossing estimate | `count_structured_q1_003` | 33 | `smaller_ystep` | 40 | 0 |
| Minimum nonfinite estimate | `count_structured_q1_006` | 45 | `current` | 39 | 0 |
| Minimum nonfinite estimate | `count_structured_q1_006` | 45 | `smaller_ystep` | 40 | 0 |

The smaller `ystep` pass added trace rows for the larger crossing example, but
it did not change endpoint availability. The two profile-crossing examples
still had missing lower and upper endpoints in both passes. The nonfinite
example still had a missing lower endpoint and the same finite upper endpoint,
0.01465116, in both passes.

| Failure class | Cell | Replicate | Profile pass | Lower endpoint | Upper endpoint | Missing lower rows | Missing upper rows |
| --- | --- | ---: | --- | ---: | ---: | ---: | ---: |
| `profile_crossing_failure` | `count_structured_q1_001` | 25 | `current` | `NA` | `NA` | 38 | 38 |
| `profile_crossing_failure` | `count_structured_q1_001` | 25 | `smaller_ystep` | `NA` | `NA` | 45 | 45 |
| `profile_crossing_failure` | `count_structured_q1_003` | 33 | `current` | `NA` | `NA` | 39 | 39 |
| `profile_crossing_failure` | `count_structured_q1_003` | 33 | `smaller_ystep` | `NA` | `NA` | 40 | 40 |
| `nonfinite_interval` | `count_structured_q1_006` | 45 | `current` | `NA` | 0.01465116 | 39 | 0 |
| `nonfinite_interval` | `count_structured_q1_006` | 45 | `smaller_ystep` | `NA` | 0.01465116 | 40 | 0 |

The likelihood-ratio curves do reach high values, especially for the minimum
crossing and nonfinite examples. Their maximum `delta_deviance` values were
69.446915 and 76.157859, far above the 70% one-degree cutoff used in the
profile call. That fact does not rescue the interval status because endpoint
availability is side-specific; the summary table still records whether the
stored profile interval found usable lower and upper endpoints.

## Interpretation

The selected trace diagnostic rules out one simple explanation: the formal
pilot did not fail merely because no profile curve could be generated. The
curves exist for all selected examples, and the smaller `ystep` pass produces
at least as many rows as the current pass.

The diagnostic also argues against treating smaller `ystep` alone as the next
fix. The smaller pass did not recover either missing endpoint for the two
profile-crossing examples, and it did not recover the lower endpoint for the
near-zero nonfinite example. A denser grid may still matter later, but the next
question should be side-specific support: which side of the estimate reaches
the cutoff, which side hits the lower boundary, and whether a wider profile
range changes endpoint availability for an interpretable reason.

This result keeps the `count_structured_q1` lane in
`hold_interval_diagnostic`. It does not support a larger recovery grid,
bootstrap interval work, a default profile-setting change, or a broad coverage
claim.

## Next Diagnostic

The next executable slice should summarize each trace by side of the fitted
estimate. The side table should report, for lower-side and upper-side profile
points separately:

- number of evaluated trace rows;
- minimum and maximum profile value on the response scale;
- minimum and maximum profile value on the link scale;
- maximum likelihood-ratio distance;
- whether the side reaches the 70% cutoff;
- whether the profile interval endpoint is present.

That side-specific table would let the team distinguish three cases that the
current summary table cannot separate: no lower-side support, lower-side support
that never reaches the cutoff, and lower-side support that reaches the cutoff
but still fails interval extraction. Only after that split should the team try a
wider `parm.range`, a lower-boundary-specific profile setting, or a larger
formal recovery design.

## Slice 1811 Addendum: Side-Specific Support

`phase18_count_structured_q1_profile_trace_side_summary()` now creates the
side-specific table requested above. It splits each selected example and profile
pass into lower-side and upper-side rows around the fitted estimate, then
reports row counts, profile-value ranges, maximum `delta_deviance`, whether the
side reaches the 70% cutoff, and whether the matching interval endpoint is
present.

On the real selected trace artifact, every lower side failed to reach the
cutoff. Every upper side reached the cutoff. The nonfinite example had a finite
upper endpoint, but the two profile-crossing examples still had missing upper
endpoints despite upper-side cutoff reach:

| Cell | Replicate | Profile pass | Side | Rows | Maximum `delta_deviance` | Reaches cutoff | Endpoint present |
| --- | ---: | --- | --- | ---: | ---: | --- | --- |
| `count_structured_q1_001` | 25 | `current` | lower | 22 | 0.8434117 | no | no |
| `count_structured_q1_001` | 25 | `current` | upper | 18 | 5.484692 | yes | no |
| `count_structured_q1_001` | 25 | `smaller_ystep` | lower | 26 | 0.8434117 | no | no |
| `count_structured_q1_001` | 25 | `smaller_ystep` | upper | 21 | 4.941597 | yes | no |
| `count_structured_q1_003` | 33 | `current` | lower | 22 | 3.232128e-08 | no | no |
| `count_structured_q1_003` | 33 | `current` | upper | 19 | 69.44691 | yes | no |
| `count_structured_q1_003` | 33 | `smaller_ystep` | lower | 23 | 3.232128e-08 | no | no |
| `count_structured_q1_003` | 33 | `smaller_ystep` | upper | 19 | 69.44691 | yes | no |
| `count_structured_q1_006` | 45 | `current` | lower | 22 | 3.669049e-08 | no | no |
| `count_structured_q1_006` | 45 | `current` | upper | 19 | 76.15786 | yes | yes |
| `count_structured_q1_006` | 45 | `smaller_ystep` | lower | 23 | 3.669049e-08 | no | no |
| `count_structured_q1_006` | 45 | `smaller_ystep` | upper | 19 | 76.15786 | yes | yes |

This result points to lower-side boundary support as the next diagnostic target.
It still does not justify a larger recovery grid or a default profile-setting
change. A wider range or lower-boundary-specific setting should first show that
the lower side can reach the cutoff for an interpretable reason.

## Slice 1812 Addendum: Saved Side Summary

`phase18_write_count_structured_q1_profile_trace_run()` now saves the
side-specific support table as
`tables/count-structured-q1-profile-trace-side-summary.csv`. The selected trace
artifact now contains four CSVs: the plan, raw trace rows, overall summary, and
side summary.

The saved side-summary CSV makes the next profile-setting experiment auditable:
future runs can compare lower-side cutoff reach and endpoint presence directly,
instead of recomputing the side split from raw trace rows.
