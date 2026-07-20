# Figure audit — reader arc D2 (issue #58)

Date: 2026-07-20 · Lane: Claude, solo · Branch: `claude/docs-figure-gallery-58`
Source: `vignettes/figure-gallery.Rmd` · Rendered from `origin/main` @ `13667138` + this branch

## Method

Every one of the **27** rendered PNGs was opened individually with an image viewer and judged against
a concrete PASS/FAIL checklist, one question per check. No holistic "is this a good figure?" judgement
was used. Contact sheets were not used as evidence.

Namespace provenance was asserted first: the installed drmTMB predated PR #800 (built 2026-07-19
21:57 UTC, merged 2026-07-20 03:12 UTC), so the package was reinstalled from this exact checkout
before any rendering. The `R/family.R` delta between the stale build and HEAD proved to be roxygen
only — the reinstall was correct practice but would not have caused a render failure, and no such
claim is made here.

Render logs were read directly. The first render reported wrapper exit 0 with an empty log; that
emptiness was verified rather than assumed from the exit code.

## Checklist

1. Clipping · 2. Collision · 3. Axis title on the correct axis · 4. Redundant or missing legend ·
5. Crowding / dead space · 6. Uncertainty honesty · 7. Fixture declares itself in-image · 8. Colour

## Result

**27 inspected. 24 PASS, 3 FAIL on first pass. All 3 fixed and re-rendered to PASS.**

| Figure | Verdict | Notes |
|---|---|---|
| `worm-plot-adequate-1` | PASS (after fix) | see F1, F2, F3 |
| `worm-plot-misspecified-1` | PASS (after fix) | see F1 |
| `qq-plot-adequate-1` | PASS (after fix) | see F1 |
| `centile-chart-growth-1` | PASS (after fix) | see F4 |
| `profile-curve-sigma-slope-1` | PASS | limits 0.152 / 0.407 about MLE 0.280 — symmetric to 0.001 |
| `corpairs-fitted-1` | PASS (after fix) | see F5 |
| `correlation-display-1` | PASS (after fix) | see F6 |
| `simulation-operating-characteristics-1` | PASS (after fix) | see F7, F8 |
| `simulation-operating-characteristics-2` | PASS (after fix) | see F7, F8 |
| `empirical-marginal-summary-1` | PASS (after fix) | see F8 |
| remaining 17 | PASS | no defects found |

## Findings and fixes

**F1 — clipped subtitle (checks 1, 2).** `worm_plot()` and `qq_plot()` carry a 137-character subtitle
that is truncated at every figure width tried, including 8.4 in. At `fig.height=3.6` the long y-axis
title also collided with it. **Fix:** a local `wrap_subtitle()` helper wraps the subtitle at 78
characters, preserving the function's own honest guard ("Not a validity or calibration claim"), plus
`fig.width=7.4, fig.height=4.4`. Not fixable by width alone.

**F2 — caption described a visual element that does not exist (check 6).** The first draft caption and
alt text for both worm plots referred to points lying "inside the envelope" / "within the pointwise
envelope". `worm_plot()` draws no envelope: its layers are `GeomHline`, `GeomPoint`, `GeomSmooth`.
**Fix:** caption, alt text and prose rewritten to describe the dotted zero reference and smoothed
trend, and the prose now states explicitly that no envelope is drawn, so the trend is read
qualitatively rather than as a test. This class is invisible to code review and lands directly in the
accessibility layer.

**F3 — caption overstated flatness (check 6).** The adequate worm plot's trend holds near zero from
−3 to about +1.5 and then drifts down, driven by two outlying points. "Stays close to the zero
reference" was too strong. **Fix:** caption and alt text now say the trend holds near zero "across the
bulk" and drifts "in the sparse right tail", and new prose tells the reader to read the bulk rather
than the extremes, where few order statistics carry the smoother.

**F4 — categorical rainbow for an ordered quantity (check 8).** `centile_chart()` returns centiles
3/15/50/85/97 on a categorical red-olive-green-blue-magenta scale. Colour therefore conveyed no
ordering, and the red/green pairing is not colour-blind-safe. **Fix:** `scale_colour_viridis_d()`,
with prose explaining that an ordered sequence deserves an ordered, perceptually uniform palette.

**F5 — dead space and redundant legend (checks 4, 5).** `corpairs-fitted` rendered one row in a tall
panel with a legend reading "level: residual", duplicating the y-axis label. **Fix:**
`fig.height=2.1` and `theme(legend.position = "none")`.

**F6 — fixture indistinguishable from a result (check 7).** `correlation-display` is built from a
hand-typed `pair_table` that set `conf.status = "profile"` — byte-identical to the value `corpairs()`
emits for a genuine profile interval (`R/methods.R:1029`). The only differentiator was
`interval_source = "illustrative_profile"`, in a column the figure never displays, while the adjacent
prose instructed readers to keep the interval provenance columns. **Fix:** the fixture now reports
`conf.status = "illustrative"`; the heading changed from "Fitted correlation summaries" to
"Correlation summaries"; the figure carries an in-image title "ILLUSTRATIVE FIXTURE - not a fitted
result"; and a genuinely computed `corpairs(conf.int = TRUE)` example now sits directly above it, so
the contrast is visible rather than asserted.

**F7 — simulation fixtures did not declare themselves in-image (check 7).** Both simulation panels
said only "fixture" inside a subtitle — jargon a non-package reader will not parse as "hand-typed".
Captions are insufficient because figures are screenshotted away from them. **Fix:** in-image title
"ILLUSTRATIVE FIXTURE - not a simulation result" on both panels, with a subtitle stating every value
is a typed constant.

**F8 — legends duplicating direct labelling (check 4).** Three figures carried legends repeating
information already present: `simulation-operating-characteristics` 1 and 2 duplicated their facet
column headers; `empirical-marginal-summary` duplicated its x-axis category ticks. **Fix:**
`guides(colour = "none")` added in each. The last is a pre-existing figure this arc did not otherwise
change; it was fixed rather than left as a known FAIL after audit.

**F9 — axis labels on the wrong axis (check 3).** Confirmed still present, as documented on
2026-06-12 (`docs/dev-log/2026-06-12-drmtmb-full-audit-handoff.md:51`). The bias panel mapped
`aes(bias_error, estimand_label)` while `labs()` set `x = NULL, y = "Estimate minus truth"`, so the
categorical parameter axis carried the bias label and the numeric axis had none. **Fix:** swapped.
Settleable from source, but it survived over a month because reviewers read the code, where it looks
correct.

## Coverage achieved

All six public plotting functions are now demonstrated. Before this arc:
`plot_parameter_surface` 8 occurrences; `plot_corpairs`, `worm_plot`, `qq_plot`, `centile_chart`,
`plot.profile.drmTMB` zero each.

The gallery source map, which claimed every figure names its source object, held 23 rows for 26
figures. Three pre-existing omissions (`residual-scale-observed-check`,
`confidence-distribution-slopes`, `coefficient-intervals`) were added alongside the six new rows; it
now holds 26 rows for 26 figure chunks and the claim is true.

## Retained evidence

Eight PNGs are retained here: the six new figures plus the two whose honesty labelling changed. The
remaining 19 are unchanged by this arc and are reproducible by rendering the vignette.

## Role notes

**Tufte** (figure-design engineer) ran the render → see → fix loop and the independent 27-figure
PASS/FAIL sweep that produced F8. This role was **installed during this arc** — the 2026-07-04
roster decision that figures need both Tufte and Florence had never been written into any per-repo
agent directory, so the visual audit was initially scoped around Florence alone, whose local charter
checks that a figure *builds* rather than that anyone *looked* at it. Recorded upstream as
FAILURE-TAXONOMY incident #14.

**Florence** (figure QA): independent review of the final render is outstanding and should run against
this branch before merge.

**Pat / Darwin** (reader): the adequacy section deliberately pairs a correct and a mis-specified fit
because a diagnostic on a correctly specified model is featureless. The contrast reads at a glance:
the mis-specified trend sweeps a full S across the middle of the distribution, where the data are.

## Gates

- `pkgdown::check_pkgdown()` → **No problems found**
- `devtools::test()` → see the after-task report
- `git diff --check` → clean
- Fence audit → no fenced path touched (`R/`, `src/`, `tests/`, ledger, generated surfaces, `NEWS.md`,
  `DESCRIPTION`, `ROADMAP.md`, `AGENTS.md` all untouched)
