# After Task: Ayumi/Santi No-Real-Data Simulation Slices

## Goal

Finish the first five Ayumi/Santi phylogenetic modeling slices without real
data by using simulated data to exercise the current `drmTMB` model routes,
diagnostic extractors, and handoff artifacts.

## Implemented

Added `tools/ayumi-santi-finish-sim-slices.R`. The script runs four simulated
model checks and writes one integrated artifact bundle under
`docs/dev-log/ayumi-santi/sim-slices/`:

1. q2 Objective 1 mini-grid.
2. univariate ecogeographic PLSM positive control.
3. q4 bivariate PLSM diagnostic positive control.
4. lifestyle or nest-habitat split-fit analogue.
5. integration README plus `all-results.rds`.

Added `docs/design/79-ayumi-santi-no-real-data-sim-slices.md` and linked it
from the improvement path and formula gallery.

## Results

All default slice fits returned convergence code 0 with `pdHess = TRUE`.

The q2 mini-grid ran three cells. The largest gradient was `0.000554`; the
default strong cell estimated the q2 phylogenetic correlation within `0.048`
and residual `rho12` within `0.022` of truth.

The univariate PLSM run used 120 species and 1440 rows. The truth `mu`-`sigma`
phylogenetic correlation was `0.70`; the estimate was `0.893`, with gradient
`0.000344`.

The q4 bivariate PLSM run used 32 species and 512 rows. It exported all six
phylogenetic correlation rows. The location-location truth was `0.50` and
estimate was `0.430`; the scale-scale truth was `0.55` and estimate was
`0.564`; residual `rho12` truth was `0.15` and estimate was `0.145`. The
gradient was `0.00262`.

The split-fit contrast ran terrestrial, aquatic, and aerial class analogues.
The estimated phylogenetic correlations were `-0.839`, `-0.271`, and `0.648`
for truths `-0.75`, `-0.20`, and `0.65`.

## Checks Run

```sh
air format tools/ayumi-santi-finish-sim-slices.R
Rscript --vanilla -e 'invisible(parse(file = "tools/ayumi-santi-finish-sim-slices.R")); cat("parse ok\n")'
Rscript --vanilla tools/ayumi-santi-finish-sim-slices.R --help
Rscript --vanilla tools/ayumi-santi-finish-sim-slices.R
sed -n '1,120p' docs/dev-log/ayumi-santi/sim-slices/README.md
sed -n '1,80p' docs/dev-log/ayumi-santi/sim-slices/q2-mini-grid-summary.csv
sed -n '1,80p' docs/dev-log/ayumi-santi/sim-slices/univariate-plsm/summary.csv
sed -n '1,80p' docs/dev-log/ayumi-santi/sim-slices/q4-positive-control/summary.csv
sed -n '1,100p' docs/dev-log/ayumi-santi/sim-slices/split-fit-class-contrast/summary.csv
```

Additional package and consistency checks are recorded in
`docs/dev-log/check-log.md`.

The local recovery checkpoint is
`docs/dev-log/recovery-checkpoints/2026-05-24-150036-codex-checkpoint.md`. The
checkpoint directory is gitignored, so it is a handoff aid rather than a
tracked package artifact.

## Tests Of The Tests

The q2 mini-grid calls `tools/ayumi-santi-q2-positive-control.R`, which calls
the Objective 1 runner through its CLI. That means the grid exercises the same
preflight, formula-writing, fit, and extractor path intended for prepared
mammal and avian data.

The univariate PLSM, q4 PLSM, and split-fit slices each compare fitted
correlations with known simulated truths and write the diagnostic tables that
Ayumi and Santi will need before biological interpretation.

## Consistency Audit

This task did not change package API, formula grammar, likelihood
parameterization, roxygen topics, pkgdown navigation, `NEWS.md`, or
`ROADMAP.md`. The new files are developer scripts, design notes, dev-log
artifacts, and after-task documentation.

The stale-claim scan returned only intentional boundary statements: no
biological claims from simulated data, `rho12` not being a phylogenetic
correlation, and q4 intervals remaining unavailable. `pkgdown::build_site()`
was not rerun because no pkgdown article, reference page, or navigation entry
changed in this slice.

## What Did Not Go Smoothly

The first q4 diagnostic cell was too brittle: it had a small gradient and
`pdHess = TRUE`, but the optimizer status or scale-correlation estimate was
not the cleanest positive-control story. A short seed and DGP tuning pass moved
the default q4 slice to a stronger simulated signal with convergence code 0
and all six `corpairs()` rows exported.

## Team Learning

For Ayumi/Santi handoffs, a single simulated-only bundle is more useful than
separate chat summaries. The bundle tells the next analyst which current model
routes are runnable, which diagnostics to read first, and which protocol
features are still outside the package surface.

## Standing Review

Ada kept the slice order tied to the protocol ladder. Boole checked that the
scripts use existing `bf()` grammar instead of inventing syntax. Gauss and
Noether kept q2 location-location, q4 location-scale, and residual `rho12`
separate. Fisher treated the runs as positive controls and diagnostics, not a
Monte Carlo performance study. Darwin and Pat checked that the outputs answer
the next applied question: what should run first when the prepared data arrive.
Grace checked that the work stays in developer scripts and docs rather than
changing package API or compiled code. Rose checked that unsupported features
remain named as boundaries.

No spawned subagents were running for this slice.

## Limitations

The results are simulated-only and make no biological claims. The q4 slice is
a diagnostic positive control: it shows that the current all-four phylogenetic
surface can export the six target rows away from boundaries, but q4 derived
intervals and full real-data behavior remain unresolved. The split-fit slice is
a workflow smoke, not a single-model class-specific covariance implementation.

## Next Actions

When real prepared data are available, run
`tools/ayumi-santi-q2-objective1-runner.R --dry-run true` for the mammal and
avian Objective 1 datasets. If preflight is clean, fit one representative tree
for each, then loop a small tree set for sensitivity before moving to q4 or
class-specific contrasts.
