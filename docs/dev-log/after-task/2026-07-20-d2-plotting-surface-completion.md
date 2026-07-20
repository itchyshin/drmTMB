# After-task: D2 — plotting-surface completion (issue #58)

Meta: 2026-07-20 · Claude, solo lane · branch `claude/docs-figure-gallery-58`

## 1. Goal

Bring the five undemonstrated public plotting functions into the existing mature figure gallery, and
label its hand-typed fixtures honestly, without adding a seventh helper, `autoplot()`, a new
dependency, or restructuring the gallery. Documentation only: `R/`, `src/`, `tests/`, the capability
ledger, generated capability surfaces, `NEWS.md`, `DESCRIPTION`, `ROADMAP.md` and `AGENTS.md` are
fenced.

## 2. Implemented

Two new gallery sections — "Distributional adequacy diagnostics" and "Profile-likelihood curves" —
demonstrate `worm_plot()`, `qq_plot()`, `centile_chart()` and `plot.profile.drmTMB()`. The correlation
section now opens with a fitted `plot_corpairs()` example. All six public plotting functions are now
exercised; before this arc `plot_parameter_surface` had 8 occurrences and the other five had zero.

Every demonstration reuses an existing fit. The one addition is `fit_mis`, a one-line `sigma ~ 1`
variant of an existing model on the same data, because a worm plot on a correctly specified model is
featureless and teaches nothing. `fit_pair_const` (`rho12 ~ 1`) was added for the same reason: it is
the only route to a real correlation interval (see §3a).

Honesty repairs: the "Fitted correlation summaries" heading renamed; the fixture's `conf.status`
changed from `"profile"` to `"illustrative"`; in-image fixture titles on the correlation and both
simulation panels; the 2026-06-12 axis-label defect fixed; two redundant legends removed; the ordered
centile sequence given an ordered, colour-blind-safe palette; the gallery source map completed.

Also installed **Tufte**, the figure-design engineer, in `.claude/agents/` and `.codex/agents/`.

## 3a. Decisions and Rejected Alternatives

**Fixtures labelled, not replaced** (pre-approved). Rendering showed caption-level labelling is
insufficient: figures get screenshotted away from their captions. Escalated to in-image titles plus a
real computed example placed directly beside the invented one. The adjacency did more work than any
caption.

**`corpairs(conf.int = TRUE)` on a `rho12` regression returns no interval.** Smoke found
`conf.status = "newdata_required"` with `NA` bounds, and supplying `newdata` did not rescue it. A
constant-correlation model was the only route to a genuine profile interval. Rejected: fabricating
bounds, or showing a Confidence Eye with no interval behind it. **Logged as an Arc B input** — `R/` is
fenced here.

**Axis-label defect fixed rather than only re-checked.** The brief said re-check; leaving a confirmed
wrong axis label in a release-bound gallery was not defensible. Two lines, no fit touched.
Design-226 §7's "no R code edited" was read by recon as binding on D2; it is not — that clause scopes
the design note itself.

**`empirical-marginal-summary` legend fixed** though the figure is otherwise untouched by this arc.
Leaving a known FAIL after auditing it is worse than the small scope increase.

## 4. Files Touched

- `vignettes/figure-gallery.Rmd` — the arc
- `.claude/agents/figure-design-engineer.md`, `.codex/agents/figure-design-engineer.toml`, `CLAUDE.md` — Tufte
- `docs/dev-log/figure-audits/2026-07-19-reader-arc-d2/` — 8 PNGs + `figure-audit.md`
- this report

Fence audit: `git diff --name-only origin/main` contains no fenced path.

## 5. Checks Run

- `devtools::test()` → **FAIL 0, ERROR 0, PASS 39466, WARN 62, SKIP 24** — matches the documented baseline exactly
- `pkgdown::check_pkgdown()` → **No problems found**
- Full `pkgdown::build_site()` → see §10
- Vignette render → clean, log read directly (empty, not inferred from exit 0)
- 27 PNGs rendered and **each opened and inspected individually**
- `git diff --check` → clean
- Anchor check → no reference anywhere to the renamed `#fitted-correlation-summaries`

Namespace provenance asserted before rendering: the installed build (2026-07-19 21:57 UTC) predated
PR #800 (merged 2026-07-20 03:12 UTC), so the package was reinstalled from this checkout. The
`R/family.R` delta proved roxygen-only, so the stale install would **not** have caused a render
failure; no such claim is made.

## 6. Tests of the Tests

The visual audit is the test, so it was run twice with different eyes. The orchestrator's first pass
found three defects in the first figure opened. An independent 27-figure sweep under the Tufte brief
then found three more that the first pass had missed (two redundant legends, one fixture not
declaring itself), giving 24 PASS / 3 FAIL. Both passes used concrete PASS/FAIL questions, one per
check; neither asked "is this a good figure?"

The caption-versus-layers check is the sharper test: `sapply(p$layers, function(l) class(l$geom)[1])`
against `p$labels` catches captions asserting elements that do not exist. It caught one of mine.

## 7a. Issue Ledger

- **#58** — this arc closes the plotting-surface half. All six functions demonstrated.
- **New, for Arc B**: `corpairs(conf.int = TRUE)` cannot produce an interval for a regression-
  parameterised `rho12` even with `newdata`. Needs an issue.
- **Resolved**: the axis-label defect at `docs/dev-log/2026-06-12-drmtmb-full-audit-handoff.md:51`.
  That dated handoff was left unedited as a historical record.

## 8. Consistency Audit

The gallery source map claimed "every figure names its source object" while holding 23 rows for 26
figure chunks. Three pre-existing omissions were added alongside six new rows; it now holds 26 for 26
and the claim is true. Row counts verified mechanically across all five parallel vectors.

Alt-text framing corrected: the handover implied a gap, but **every** captioned chunk in all 33
vignettes already set `fig.alt`, none duplicated. The work was refinement, not creation.

## 9. What Did Not Go Smoothly

The first plan draft assigned the render-and-inspect loop to Florence, whose local charter checks that
a figure *builds*, not that anyone *looked* at it. Tufte — decided into the roster on 2026-07-04 —
existed in no per-repo agent directory. Shinichi caught it, not the system. Recorded upstream as
FAILURE-TAXONOMY incident #14. A second wrinkle: adding the agent file does not make it launchable
until the session reloads, so this arc's sweep ran the Tufte brief through a general agent.

Separately, the first version of §10 in the ultra-plan argued the zero-one-beta leak was harmless
using a strictly-interior subset comparison. Fisher's review showed the filter conditions on the
latent tail that identifies the estimand, making the null result an arithmetic identity with no power.
Reasoning discarded and recorded, not deleted.

## 10. Known Residuals

- Full `pkgdown::build_site()` was still running when this report was written; its result and the
  33/33 article count must be confirmed before merge.
- **Florence's independent QA on the final render has not run.** Tufte made and self-checked; the
  second pair of eyes is outstanding.
- Figures render at dpi 144, below the ≥300 raster bar for print. Not addressed; gallery-appropriate.
- Greyscale legibility unchecked.
- 16 of 33 vignettes have no captioned figures at all; giving them figures is a named follow-up, not
  this arc.

## 11. Team Learning

**Tufte** — the render → see → fix loop is not optional and is not substitutable by code review. It
found a clipped 137-character subtitle no width fixes, a colliding axis title, a month-old inverted
axis label, and a caption of mine describing a pointwise envelope that does not exist.

**Florence** — caption-level fixture labelling fails the screenshot test. A fixture must declare
itself inside the image, and the strongest correction is a real example beside it.

**Fisher** — a sensitivity analysis that conditions on a variable correlated with the estimand is not
a sensitivity analysis.

**Rose** — a roster decision held in the hub is not an available agent until it is a file in the
target repo; and installing the file is still not availability until the session reloads.

## 12. Cross-Product Coverage

The plotting lessons were written up for the **gllvmTMB** lane, which measures worse: ~13 public
plotting exports, 3 of 9 non-method ones demonstrated across 18 vignettes, **`ordiplot` — the flagship
ordination plot — demonstrated zero times**, and 21 `fig.cap` against 6 `fig.alt`. Filed in the brain
as `projects/gllvmTMB plotting arc — handoff from the drmTMB D2 figure arc`, with an explicit §7
listing what was not verified (no gllvmTMB figure was rendered; `man/` examples unchecked).
