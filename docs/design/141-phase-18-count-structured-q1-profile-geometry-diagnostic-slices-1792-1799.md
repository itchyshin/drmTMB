# Phase 18 Count Structured q1 Profile Geometry Diagnostic: Slices 1792-1799

This note turns the formal-pilot profile-failure audit into the next diagnostic
contract. The reader is an R package contributor or statistical-method reviewer
who needs to decide what evidence is still missing before `count_structured_q1`
can leave `hold_interval_diagnostic`.

## Evidence Already in the Repository

GitHub Actions run `26669005577` ran the stable-set
`count_structured_q1` formal pilot from `main` at commit `f7e090f2`, with
100 replicates in each of 10 conditions and direct `log_sd_phylo` profile
intervals at `profile_level = 0.70`. The fit-level boundary gate passed: the
artifact had 10 SD-boundary warning fits out of 1000 fitted replicates and no
Hessian warnings. The profile gate did not pass: 27 requested profile intervals
failed, and `count_structured_q1_001` had 11 failed intervals out of 100,
crossing the 10% condition-level stop rule.

The follow-up artifact helpers keep the profile failure evidence local to the
downloaded artifact. `failure_summary` now reports failure classes, example
replicates, local RDS paths, and requested profile-row details. The
`example_geometry_summary` table from the same artifact says:

| Failure class | Failed intervals | Failure-summary rows | Missing lower endpoints | Missing upper endpoints | Minimum example estimate | Minimum-estimate example |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| `nonfinite_interval` | 22 | 7 | 7 | 0 | `1.906516e-05` | `count_structured_q1_006`, replicate 45 |
| `profile_crossing_failure` | 5 | 4 | 4 | 4 | `2.168574e-05` | `count_structured_q1_003`, replicate 33 |

All 11 example rows had `example_profile_detail_status = "ok"`,
`example_profile_status = "failed"`, and
`example_profile_target_parameter = "log_sd_phylo"`. The public structured-SD
truth for these examples is 0.6, so the minimum estimates are close to the
lower boundary on the public SD scale.

## Interpretation Boundary

The current artifact explains where to look, not why the profile failed. The
saved replicate RDS files contain fitted summary rows, profile interval status,
and profile messages. They do not contain the profile likelihood or likelihood
ratio curve. Therefore the team can say that many failed examples have very
small public structured-SD estimates and missing lower endpoints, but cannot yet
say whether the cause is boundary curvature, profile-grid width, `ystep`,
non-monotone likelihood-ratio geometry, or inner optimization failure.

This boundary matters because the next change could otherwise look like a
tuning fix when it is only a guess. The lane remains in
`hold_interval_diagnostic`; it does not permit a larger recovery grid,
bootstrap interval work, or broad profile-coverage claims.

## Next Diagnostic Questions

The next executable diagnostic should answer three questions on selected
examples before changing the formal-pilot design:

1. Does the likelihood-ratio curve approach the confidence cutoff on the lower
   side, or does it fail before meaningful lower-side support is evaluated?
2. Do `profile_crossing_failure` examples fail because both sides never cross
   the cutoff, because the stored grid is too narrow or coarse, or because an
   inner optimization fails?
3. For near-zero public structured-SD estimates, does a wider or denser profile
   grid change the status, or does the fitted example remain effectively
   boundary-limited?

The minimum examples in `example_geometry_summary` are the first candidates:
`count_structured_q1_006` replicate 45 for `nonfinite_interval` and
`count_structured_q1_003` replicate 33 for `profile_crossing_failure`. The
`count_structured_q1_001` profile-crossing example with estimate 0.4776729 is
also worth inspecting because it is not near zero but still has both endpoints
missing.

## Acceptable Next Slice

The next implementation slice should be a selected-example profile-trace
diagnostic. It should rerun only a small set of named examples, save or print
the likelihood-ratio points used for the interval decision, and compare the
current profile settings with one conservative alternative such as a wider
`parm.range` or smaller `ystep`. The output should include enough data for a
Florence/Fisher plot: estimate, truth, cutoff, profile points, endpoint status,
and elapsed time.

That slice should not change default profile settings, dispatch a larger
simulation, or relax the formal-pilot gate. A settings change needs a follow-up
comparison showing that the selected examples improve for an interpretable
reason without hiding a boundary or identifiability problem.

## Slice 1800 Addendum: Trace Plan Scaffold

`phase18_count_structured_q1_profile_trace_plan()` now records the first
selected-example scaffold for that diagnostic. It crosses the three examples
named above with two planned passes: the current `ystep = 0.50` setting and a
smaller `ystep = 0.25` setting. The scaffold uses exact seeds from artifact
`26669005577`, not regenerated registry seeds:

| Cell | Replicate | Seed | Profile target | Role |
| --- | ---: | ---: | --- | --- |
| `count_structured_q1_006` | 45 | 932584520 | `sd:mu:spatial(1 | site)` | Minimum nonfinite-interval estimate |
| `count_structured_q1_003` | 33 | 461195966 | `sd:mu:animal(1 | id)` | Minimum profile-crossing estimate |
| `count_structured_q1_001` | 25 | 32713190 | `sd:mu:spatial(1 | site)` | Larger profile-crossing estimate |

This addendum still does not rerun profiles or change settings. It only fixes
the selected examples, public profile target labels, and control labels for the
next executable helper.

## Slice 1801 Addendum: Trace Plan Table

`phase18_write_count_structured_q1_profile_trace_plan()` now writes the scaffold
to `tables/count-structured-q1-profile-trace-plan.csv` with overwrite
protection. The CSV is the planned input for a selected-example rerun helper.
It is intentionally separate from the main grid artifact manifest because it
does not summarize a simulation run.

## Slice 1802 Addendum: Trace Result Contract

`phase18_count_structured_q1_profile_trace_result()` now defines the per-row
result contract for the selected-example rerun. A successful profile call
returns the profile rows with plan metadata attached: cell id, replicate, seed,
example role, profile pass, profile target, confidence level, `ystep`, status,
message, and elapsed time. A failed profile call returns one metadata row with
`trace_status = "failed"` and the profile error message.

The tests inject fake profile functions, so this addendum verifies the result
shape without spending CI time on the selected formal-pilot examples. The next
slice can connect this wrapper to the DGP/fit rerun.

## Slice 1803 Addendum: Trace Run Plan

`phase18_count_structured_q1_profile_trace_run_plan()` now connects the
selected-example plan to the DGP, fit, and profile steps. For each planned row,
it uses `cell_index` to select the matching stable condition, regenerates the
replicate with the recorded artifact seed, fits the model, and then delegates
to `phase18_count_structured_q1_profile_trace_result()`.

DGP and fit errors are returned as failed trace rows with the same metadata
shape as profile failures. Mixed success and failure rows are column-aligned
before binding, so a failed fit can sit beside successful likelihood-ratio
trace rows without losing the profile columns. The focused tests inject fake
DGP, fit, and profile functions; this addendum still does not rerun the three
selected formal-pilot examples or change profile settings.

## Slice 1804 Addendum: Trace Run Tables

`phase18_write_count_structured_q1_profile_trace_run()` now writes the selected
plan and the bound trace rows as a compact two-table artifact:
`tables/count-structured-q1-profile-trace-plan.csv` and
`tables/count-structured-q1-profile-trace.csv`. The helper applies overwrite
protection across both files, then returns the paths, plan, and trace data.

This writer makes the next real selected-example rerun auditable without
changing the simulation grid artifact layout. The focused tests still inject
fake DGP, fit, and profile functions, so this slice records the artifact
contract rather than new likelihood-profile evidence.

## Slice 1805 Addendum: Public Trace Targets

The first real trace-writer smoke exposed a target-label mismatch. The
formal-pilot interval tables record the mapped TMB parameter as `log_sd_phylo`,
but `profile()` expects the public direct target labels returned by
`profile_targets()`. The selected examples now store those public labels:
`sd:mu:spatial(1 | site)` for the spatial examples and
`sd:mu:animal(1 | id)` for the animal example.

After this fix, a real local trace writer smoke at
`/private/tmp/drmtmb-count-structured-q1-profile-trace-targets-20260530` wrote both
trace CSVs and produced profile rows for all six planned passes:

| Profile pass | Trace rows | Trace status |
| --- | ---: | --- |
| `current` | 116 | `ok` |
| `smaller_ystep` | 125 | `ok` |

This result means the profile curves are now available for visual and numerical
inspection. It does not mean the selected examples have usable two-sided
intervals. The nonfinite-interval example still has missing lower endpoints,
and both profile-crossing examples still have missing lower and upper endpoints
in `conf.low`, `conf.high`, and `conf.status`.

## Slice 1806 Addendum: Trace Summary Table

`phase18_count_structured_q1_profile_trace_summary()` now reduces the trace CSV
to one row per selected example and profile pass. The summary reports how many
trace rows were produced, how many failed, whether lower or upper interval
endpoints are missing, the response-scale profile-value range, the maximum
likelihood-ratio distance (`delta_deviance`), and the interval status.

This summary table is the handoff from raw trace rows to the next visual
diagnostic. It keeps curve availability separate from interval availability:
the trace may be `ok` while `conf.low`, `conf.high`, or `conf.status` still
show why the selected examples stopped the formal-pilot profile gate.

## Slice 1807 Addendum: Trace Plot Helper

`phase18_plot_count_structured_q1_profile_trace()` now turns the selected
trace rows into a likelihood-ratio diagnostic plot. The x-axis is the log
structured-SD profile value, which makes the near-boundary traces readable
without scientific-notation tick labels. The y-axis is `delta_deviance` on a
sqrt scale, so the 70% cutoff region and the high-tail spikes are visible in
the same panel. The plot facets by selected example, colours and linetypes the
current and smaller-`ystep` passes, marks the fitted estimate, and draws the
70% likelihood-ratio cutoff.

The plot is a curve diagnostic, not an interval-success claim. The summary
table remains responsible for showing missing lower and upper endpoints.

## Slice 1808 Addendum: Summary CSV in Trace Artifacts

`phase18_write_count_structured_q1_profile_trace_run()` now writes
`tables/count-structured-q1-profile-trace-summary.csv` beside the selected plan
and raw trace rows. The writer returns the summary table too, so downstream
plotting, reporting, and handoff notes can use the same endpoint-missingness
table without recomputing it from the trace CSV.
