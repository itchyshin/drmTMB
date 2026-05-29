# After Task: Phase 18 Count Structured q1 Follow-Up Condition Sets

## Goal

Make the next `count_structured_q1` diagnostic follow-up executable by
separating the run `26631771105` pilot cells into stable, high-SD watchlist,
and low-SD boundary-stress condition sets.

## Implemented

`phase18_count_structured_q1_followup_conditions()` now starts from the same
24-cell table used by the manual `count_structured_q1` task and annotates each
cell with the pilot run, original pilot cell ID, pilot SD-boundary status,
Hessian-warning flag, warning-ledger flag, and condition role. The executable
sets are `all`, `stable`, `stable_watch`, and `boundary_stress`.

The manual Phase 18 Actions workflow and `sim_run_actions_cell.R` now accept
`condition_set`. The default `all` keeps the historical 24-cell behavior.
`condition_set=stable` selects the 10 clean high-`sd_structured` cells from the
pilot audit. `stable_watch` selects the two high-SD NB2 spatial cells with
lower-rate SD-boundary warnings. `boundary_stress` selects the 12 low-SD cells.

`docs/design/137-phase-18-count-structured-q1-followup-condition-sets-slices-1753-1760.md`
records the follow-up dispatch contract and makes the claim boundary explicit:
only the stable set can propose a later formal-pilot design, and a passing
stable diagnostic still cannot make recovery or coverage claims without direct
intervals and MCSE targets.

## Mathematical Contract

No likelihood, formula grammar, parameterization, fitted model surface, or
user-facing model syntax changed. The model remains an ordinary non-zero-
inflated Poisson or NB2 count model with one q=1 structured `mu` intercept on
the log-mean scale.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `inst/sim/dgp/sim_dgp_count_structured_q1.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `tests/testthat/test-phase18-count-structured-q1.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `docs/design/137-phase-18-count-structured-q1-followup-condition-sets-slices-1753-1760.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `inst/sim/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-followup-condition-sets.md`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_count_structured_q1.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-count-structured-q1.R tests/testthat/test-phase18-actions-runner.R docs/design/137-phase-18-count-structured-q1-followup-condition-sets-slices-1753-1760.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md .github/workflows/phase18-simulation-grid.yaml
Rscript --vanilla -e "devtools::test(filter = 'phase18-(count-structured-q1|actions-runner)', reporter = 'summary')"
gh issue list --repo itchyshin/drmTMB --state open --search 'count_structured_q1 condition_set OR count structured q1 stable boundary stress OR count structured q1 condition set' --limit 20 --json number,title,state,url,labels
rg -n 'count structured q1.*formal recovery|formal recovery.*count structured q1|count structured q1.*coverage claims|count structured q1.*coverage claim|count structured q1.*all clean|condition_set=stable.*coverage|condition_set=stable.*recovery claim|stable.*formal recovery claim|boundary_stress.*promot|task = "all".*count_structured_q1|count_structured_q1.*task = "all"' README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat .github/workflows --glob '!docs/dev-log/**'
git diff --check
Rscript --vanilla -e "pkgdown::check_pkgdown()"
```

The focused tests passed, the issue search returned `[]`, the stale-claim scan
returned only existing guardrails against `task = "all"` inclusion and formal
recovery claims, `git diff --check` was clean, and
`pkgdown::check_pkgdown()` reported no problems.

## Tests Of The Tests

The new condition-set test checks the intended split directly: 24 cells for
`all`, 10 for `stable`, 2 for `stable_watch`, and 12 for `boundary_stress`.
It also checks that the stable cells have no pilot SD-boundary warning, the
watchlist cells have lower-rate warnings, and six stress cells crossed the
condition-level trigger. The Actions-runner tests check both the accepted
`condition_set=stable` dry run and the failure path for using a non-`all`
condition set on another task.

## Consistency Audit

The roadmap, simulation programme, simulation README, check log, design note,
and after-task report now tell the same story: the count structured q1 lane
remains diagnostic after run `26631771105`, and the next stable-set dispatch is
a follow-up design step rather than a recovery or coverage claim. NEWS was not
updated because this is internal simulation and workflow infrastructure, not a
new user-facing package feature.

## GitHub Issue Maintenance

`gh issue list` found no overlapping open issue for the count structured q1
condition-set split. I did not open a new issue because the design note,
roadmap row, check-log entry, and this report provide the durable handoff.

## What Did Not Go Smoothly

The first focused test run failed because the test compared a `table()` object
directly with a named integer vector. The helper counts were correct; the test
now converts the role counts to integers before comparing them.

## Team Learning

Ada kept the slice to a follow-up condition-set design. Curie checked that the
set counts match the pilot audit. Fisher kept profile, MCSE, recovery, and
coverage claims out. Grace checked workflow wiring, focused tests, pkgdown, and
diff hygiene. Rose checked stale wording and issue overlap. No spawned
subagents were running.

## Known Limitations

The helper hard-codes the diagnostic roles from run `26631771105`; it is not a
general artifact classifier. The next run still needs an after-task audit, and
a later formal-pilot design must specify direct interval policy, MCSE targets,
runtime budget, and stop rules before making recovery or coverage claims.

## Next Actions

After this branch is reviewed and merged, dispatch the stable-set diagnostic
from `main` with `condition_set=stable`, `n_reps=20`, `cores=2`,
`backend=multicore`, and empty `profile_parameters`. Audit the artifact with
`phase18_audit_count_structured_q1_boundary_gate(require_complete = TRUE)`
before deciding whether a formal-pilot design note is justified.
