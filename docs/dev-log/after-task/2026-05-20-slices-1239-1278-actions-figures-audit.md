# After Task: Slices 1239-1278 Actions, Figures, And Audit Closure

## Goal

Ada merged PR #263, opened the next integration branch, and closed the next
process slice: make Phase 18 larger grids dispatchable from GitHub Actions,
keep the figure-quality promises visible, and record the reference,
structural-dependence, convergence, bootstrap, and issue-maintenance trail
without pretending planned model classes are already fitted.

## Implemented

- Merged PR #263, "Consolidate Ayumi stress evidence and Phase 18 staging".
- Added `.github/workflows/phase18-simulation-grid.yaml`, a manual
  `workflow_dispatch` workflow for first-wave and interval-heavy Phase 18
  simulation tasks.
- Added `inst/sim/run/sim_run_actions_cell.R`, the CLI entrypoint used by the
  workflow. It supports dry-runs, first-wave summary grids,
  interval-heavy grids, profile targets, bootstrap draws, artifact output
  directories, and the project 10-core cap.
- Added tests for dry-run parsing, core capping, and nested multicore
  rejection.
- Repaired the Phase 18 Actions runner test after PR #264's first R-CMD-check
  run failed under the installed-package layout.
- Rebuilt and re-audited the rendered figure gallery after the user pointed out
  that the earlier visual pass had still missed sparse, mislabelled, or
  under-informative figures.
- Updated `inst/sim/README.md`,
  `docs/design/41-phase-18-simulation-programme.md`,
  `docs/dev-log/forgotten-promises-status-2026-05-20.md`, and
  `docs/dev-log/team-improvements.md`.
- Added a figure-audit note and a structural-dependence parity snapshot.

## GitHub Actions Design

The new workflow is manual only. It does not run on every push or pull request.
That keeps ordinary CI fast while giving Grace and Curie a reproducible place
to run larger Phase 18 grids when the branch is ready.

The workflow mirrors the useful part of the sibling `gllvmTMB` M3 production
grid: one matrix task per artifact, `fail-fast: false`, bounded
`max-parallel`, explicit artifact retention, and a run summary. The `drmTMB`
version adds a runner-side 10-core cap and rejects nested
replicate-plus-bootstrap multicore requests.

## Team Roles

- Ada integrated the branch and kept PR, CI, docs, tests, and issues in view.
- Grace watched post-merge Actions and translated the `gllvmTMB` long-run
  pattern into a `drmTMB` workflow.
- Curie and Fisher kept simulation artifacts, interval provenance, bootstrap
  scope, and no-nested-parallel behaviour explicit.
- Florence, Pat, and Rose turned the figure complaints into a reusable audit
  gate rather than a one-off rescue.
- Darwin kept structural-dependence examples tied to real biological use
  without claiming planned `animal()` or `relmat()` support.

These were role perspectives, not spawned agents.

## Consistency Audit

The workflow and runner do not implement public bootstrap confidence intervals.
They only make the private Phase 18 bootstrap/profile evidence reproducible as
simulation artifacts. Public `confint(method = "bootstrap")` still requires a
separate target-extraction, refit, failure-ledger, and documentation slice.

The structural-dependence parity note keeps `animal()`, `spatial()`, and
`relmat()` aligned with the phylogenetic target without upgrading planned
syntax into fitted support.

## Checks Run

```sh
Rscript --vanilla inst/sim/run/sim_run_actions_cell.R --task=first_wave_summary --dry-run=true --cores=30 --backend=multicore
Rscript --vanilla inst/sim/run/sim_run_actions_cell.R --task=interval_heavy_summary --dry-run=true --backend=none --cores=10 --bootstrap-backend=multicore --bootstrap-cores=30 --bootstrap-nsim=2 --profile-parameters=fixef:nu:w,fixef:rho12:w
Rscript -e "devtools::test(filter = '^phase18-actions-runner$|^phase18-sim-runner$|^phase18-sim-bootstrap$')"
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = TRUE)"
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('simulation-plot-grammar', new_process = FALSE, quiet = TRUE)"
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/phase18-simulation-grid.yaml"); puts "ok"'
gh api repos/actions/upload-artifact/releases --jq '.[0].tag_name'
git diff --check
```

- First-wave dry-run passed and capped a 30-core request to 10.
- Interval-heavy dry-run passed and capped a 30-core bootstrap request to 10.
- Focused tests passed locally after the CI repair: 104 expectations,
  0 failures, 0 warnings, 0 skips.
- The figure gallery and simulation grammar articles rebuilt locally after the
  rendered-figure repairs.
- YAML parsing passed for the new workflow and both existing workflows.
- `actions/upload-artifact` latest release check returned `v7.0.1`, matching
  the workflow's `actions/upload-artifact@v7` major pin.
- `git diff --check` was clean.

## Deployment Watch

After PR #263 merged to `main`, the post-merge R-CMD-check run
`26169859911` passed on macOS, Windows, and Ubuntu. The chained pkgdown run
`26170628794` passed.

PR #264's first R-CMD-check run, `26171357996`, failed on macOS, Windows, and
Ubuntu. The failure was not a package build problem or a transient runner
outage. The new test called
`../../inst/sim/run/sim_run_actions_cell.R`, which works from the source tree
but fails in `R CMD check` because `inst/` is installed as package files and
the script is reached via `system.file("sim", "run", ...)`. The local path also
contains a space, so the repaired test now quotes the `Rscript` argument with
`shQuote()`.

Grace's process correction is to test installed-file helpers through
`system.file()` before treating a runner test as CI-ready.

## Figure Audit Follow-Up

The first figure audit was not strong enough. It mixed source review, selected
rendered images, and contact-sheet navigation, but did not force a
one-figure-at-a-time rendered visual gate. Florence and Rose recorded the
failure mode in
`docs/dev-log/figure-audits/2026-05-20-full-gallery-visual-audit/figure-audit.md`.

Immediate gallery repairs converted the coefficient-interval display to
raindrop-style Wald compatibility displays, made discrete and emmeans examples
use compact horizontal interval layouts, clarified the residual-magnitude
display, and added visible points to the fitted among-site SD surface. Remaining
watch items are logged for the emmeans support strip, convergence/runtime
summary, and failure ledger.

Once the gallery grammar is stable, every substantive worked example should
include a model-output figure that helps readers see what the fitted model says
and names the estimand, reporting scale, and uncertainty source.

## Issue Maintenance

- Updated #59 with the new manual Phase 18 Actions dispatch route.
- Updated #58 with the figure-audit gate and shared Florence/Fisher/Pat/Grace/
  Rose responsibilities.
- Updated #147 with the structural-dependence parity snapshot for `animal()`,
  `spatial()`, and `relmat()`.
- Updated #255 with the artifact-preservation link for replicate-level
  simulation displays.
- Updated #31 with the future structural-dependence learning-path split.
- Updated #4 to clarify that this PR prepares infrastructure for future
  Ayumi-scale stress runs but does not rerun the full 6196-species model.
- Opened #265 for the missing public bootstrap confidence-interval design,
  because no focused issue existed for that API and failure-ledger work.
