# Figure Audit: Slices 1248-1253

Date: 2026-05-20

Active perspectives: Florence judged the plots; Fisher checked uncertainty and
data grain; Pat checked reader interpretation; Grace required rendered
evidence; Rose checked repeated failure patterns. These are role perspectives,
not spawned agents.

## Verdict

The figure-gallery and simulation-plot-grammar pages are better than the first
versions, but they are not yet a finished visual system. The most important
correction is process: no future figure change should be called done from
source code alone. The rendered image must be inspected one figure at a time,
with the error-bar meaning, data grain, and unsupported targets visible in the
caption, subtitle, or surrounding text.

## Current Pattern Checks

| Pattern | Status | Next action |
| --- | --- | --- |
| Error bars misaligned with bars | Improved in source after the rescue pass, but still needs rendered recheck after every change | Keep bar and interval layers on the same position object; if a plot uses dodged bars, its interval layer must use the same dodge width. |
| Overlap in coverage and power figures | Improved by faceting surfaces, but density/cloud layers can still distract in sparse fixtures | Simulation grammar should prefer points plus MCSE bars unless replicate-block data make a cloud honest. |
| Confidence distributions missing from inference plots | Partly improved with raindrop-style compatibility figures | Treat confidence-density displays as required for inference gallery examples, especially coefficients and correlations. |
| Raw or replicate data hidden | Partial | Bias plots may show replicate-level errors only when replicate rows exist; aggregate-only examples must say they are aggregate summaries. |
| Standardised-predictor comparability | Noted | Do not put slopes, ratios, and correlations on one visual scale unless the reporting scale and standardisation make comparison meaningful. |
| Unsupported or planned features appearing fitted | Ongoing risk | Use "planned" labels and boundary text for animal, relmat, skew, and unimplemented structural dependence examples. |

## Team Improvement

Florence owns final scientific figure quality, but she should not be left alone
with the problem. Fisher must ask whether the interval or density is the right
uncertainty object. Pat must ask whether a new user can tell what the bars or
clouds mean. Grace must ask whether the rendered page actually shows the figure
that source code intended. Rose must catch repeated mistakes such as
misaligned intervals, source-only signoff, or captions that make fixture data
sound like real simulation evidence.
