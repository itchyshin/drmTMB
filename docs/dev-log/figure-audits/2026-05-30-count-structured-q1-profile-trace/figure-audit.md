# Count Structured q1 Profile Trace Figure Audit

## Figure

`profile-trace.png`

## Source

`/private/tmp/drmtmb-count-structured-q1-profile-trace-targets-20260530/tables/count-structured-q1-profile-trace.csv`

The companion summary table is `profile-trace-summary.csv`.

## Audit

| Check | Verdict |
| --- | --- |
| Visual data grain | Trace rows from the three selected formal-pilot examples, crossed with `current` and `smaller_ystep` profile passes. |
| Uncertainty source | Full likelihood-ratio profile curves from `stats::profile.drmTMB`; the dashed line is the 70% likelihood-ratio cutoff. |
| Missing-cell display | Interval endpoint availability is not encoded in the plot; `profile-trace-summary.csv` records missing lower and upper endpoints. |
| Reader risk | A rendered curve could be mistaken for a usable interval. The design note and after-task report state that curve availability is not interval success. |
| Verdict | Acceptable as an internal diagnostic plot for the next interpretation slice. Not a publication figure yet. |

## Role Notes

Florence: the log-SD x-axis avoids unreadable near-zero response-scale tick
labels, and the sqrt y-axis keeps both the cutoff region and high-tail spikes
visible.

Fisher: the plot shows likelihood-ratio trace rows only. Endpoint success must
be read from the summary CSV, not inferred from the curve.

Pat: the facet labels identify the selected example and replicate, but the role
labels are still developer-oriented. A public-facing figure would need friendlier
captions.

Rose: the figure does not relax the formal-pilot gate. It preserves the next
question: why the curves exist while lower or both interval endpoints remain
missing.
