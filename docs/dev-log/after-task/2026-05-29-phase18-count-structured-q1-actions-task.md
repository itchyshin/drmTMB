# After Task: Phase 18 Count Structured q1 Manual Actions Task

## Goal

Add a manual-only GitHub Actions dispatch task for the ordinary Poisson/NB2
count structured q=1 smoke artifact lane that merged in PR #367.

## Implemented

The workflow now accepts `task=count_structured_q1` in
`.github/workflows/phase18-simulation-grid.yaml`. The matrix row uses seed
`20260543` and `include_in_all: false`, so `task = "all"` still runs only the
default Phase 18 lanes.

The Actions runner now accepts `--task=count_structured_q1`, sources the five
count structured q=1 simulation files, and dispatches
`phase18_write_count_structured_q1_grid_outputs()`. Optional
`profile_parameters` and `profile_level` arguments pass through to the grid
writer so a manual run can request the direct `log_sd_phylo` profile target
without changing the default smoke surface.

## Mathematical Contract

This slice changes dispatch only. The fitted model remains the ordinary
non-zero-inflated Poisson/NB2 q=1 structured `mu` intercept lane recorded in
`docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`:

```text
eta_mu_i = beta0 + beta1 * x_i + b_g[i]
mu_i = exp(eta_mu_i)
```

where `b_g` is one `spatial()`, `animal()`, or `relmat()` structured
intercept. NB2 cells keep the fixed-effect scale formula
`sigma ~ z`; this slice does not add structured `sigma`.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `inst/sim/run/sim_run_actions_cell.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `inst/sim/README.md`
- `docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-actions-task.md`

## Checks Run

```sh
air format .github/workflows/phase18-simulation-grid.yaml inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-actions-runner.R inst/sim/README.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md
Rscript --vanilla -e "devtools::test(filter = '^phase18-actions-runner$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^(phase18-actions-runner|phase18-count-structured-q1)$', reporter = 'summary')"
air format tests/testthat/test-phase18-actions-runner.R
Rscript --vanilla -e "devtools::test(filter = '^(phase18-actions-runner|phase18-count-structured-q1)$', reporter = 'summary')"
rg -n 'count_structured_q1|count structured q1|count structured q=1|20260543|include_in_all|task = "all"' .github/workflows inst/sim/run tests/testthat inst/sim/README.md NEWS.md ROADMAP.md docs/design docs/dev-log --glob '!docs/dev-log/recovery-checkpoints/**'
rg -n 'count structured q1.*formal recovery|formal recovery.*count structured q1|count structured q1.*coverage claims|zero-inflated.*count structured q1.*(implemented|supported|admitted)|structured count slopes.*(implemented|supported|admitted)|count structured q1.*task = "all"|task = "all".*count_structured_q1' README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat .github/workflows --glob '!docs/dev-log/**'
gh issue list --repo itchyshin/drmTMB --state open --search 'count structured q1 Actions' --limit 20
Rscript --vanilla -e "pkgdown::check_pkgdown()"
git diff --check
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
Rscript --vanilla -e "pkgdown::build_site(preview = FALSE)"
rg -n 'count structured q1.*formal recovery|formal recovery.*count structured q1|count structured q1.*coverage claims|zero-inflated.*count structured q1.*(implemented|supported|admitted)|structured count slopes.*(implemented|supported|admitted)|count structured q1.*task = "all"|task = "all".*count_structured_q1' pkgdown-site README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat .github/workflows --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'
Rscript --vanilla -e "devtools::check()"
```

The focused Actions-runner test passed. The adjacent Actions-runner plus count
structured q=1 artifact test filter passed before and after tightening the
workflow test to assert the `include_in_all: false` guard.
`pkgdown::check_pkgdown()`, `git diff --check`, full `devtools::test()`, and
`pkgdown::build_site(preview = FALSE)` passed. `devtools::check()` completed
with 0 errors, 0 warnings, and 1 note in 7 minutes 6.2 seconds. The note was
the local future-file-timestamps clock check: `unable to verify current time`.

## Tests Of The Tests

The new tests exercise three failure-prone points: option parsing for
`--task=count_structured_q1`, dependency sourcing for the five artifact files,
and workflow exposure with seed `20260543` plus `include_in_all: false`. The
adjacent count structured q=1 artifact tests confirm that the task points at
the already-tested grid writer rather than an orphan workflow option.

## Consistency Audit

`inst/sim/README.md`, the Phase 18 programme, the count structured q=1 design
note, `ROADMAP.md`, and `NEWS.md` now describe the lane as a manual Actions
task for opt-in smoke artifacts. The prose keeps `task = "all"` exclusion
visible.

The stale-claim scans returned the intended NEWS and rendered-news boundary
wording plus the standing formula-grammar limitation row. They did not find a
new claim that this lane has formal recovery, zero-inflated structured count
support, structured count slopes, or default `task = "all"` inclusion.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --state open --search 'count structured q1 Actions' --limit 20`
returned no open issue to update. This slice follows PR #367 and only wires
the already-merged local smoke artifact lane into a manual workflow task.

## What Did Not Go Smoothly

The first workflow test only checked the task name and seed. Grace tightened it
to assert `include_in_all: false` directly because the manual-only guard is part
of the implemented contract.

## Team Learning

Actions task tests should check both discoverability and exclusion from
`task = "all"` whenever a simulation lane is manual-only. Rose should keep that
guard in the prose because manual workflow options can look like default
coverage infrastructure when the boundary is not stated.

## Known Limitations

This is still a smoke-artifact lane. The task does not add formal recovery,
coverage promotion, zero-inflated or hurdle structured count effects,
structured count slopes, labelled q=2/q=4 count covariance, simultaneous
structured count types, structured NB2 `sigma`, or condition sharding.

## Next Actions

Open the PR and watch CI. After the PR merges, dispatch one small manual
`count_structured_q1` Actions smoke run and audit the downloaded artifact
before claiming the workflow route operational.
