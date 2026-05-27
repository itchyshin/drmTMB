# After Task: Student-t Mu Random-Intercept Artifacts, Slices 1379-1388

## Goal

Add the Phase 18 artifact lane for the fitted Student-t ordinary `mu`
random-intercept route:

```r
drmTMB(
  bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1),
  family = student(),
  data = dat
)
```

The task should not widen the fitted surface to Student-t random slopes,
labelled covariance, `sigma` random effects, `nu` random effects, structured
effects, known covariance, or bivariate Student-t models.

## Implemented

The new lane adds:

- `phase18_dgp_student_mu_ri()`;
- `phase18_summarise_student_mu_ri_fit()`;
- `phase18_run_student_mu_ri_smoke()`;
- `phase18_summarise_student_mu_ri_smoke()`;
- `phase18_write_student_mu_ri_grid_outputs()`;
- a focused test file for the DGP, smoke summary, grid writer, and malformed
  inputs;
- first-wave summary runner inclusion; and
- a manual `student_mu_random_intercept` Actions task.

The grid writer saves aggregate, replicate, manifest, failure-ledger,
fixed-effect Wald interval, Wald coverage, direct-SD profile interval, and
profile coverage CSV artifacts.

## Mathematical Contract

The DGP draws one ordinary group intercept for `mu`, centres the realized
intercept vector, and uses the fitted Student-t shape transform:

```text
b_id ~ Normal(0, sd_id)
mu_i = beta0 + beta1 * x_i + b_id[i]
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
eta_nu_i = delta0
nu_i = 2 + exp(eta_nu_i)
y_i = mu_i + sigma_i * t_i
t_i ~ Student-t(df = nu_i)
```

The summary rows target `mu`, `sigma`, and `nu` formula coefficients on their
modelled scales plus the public `sd:mu:(1 | id)` random-intercept SD.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/119-phase-18-student-mu-random-intercept-artifacts-slices-1379-1388.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`
- `inst/sim/dgp/sim_dgp_student_mu_random_intercept.R`
- `inst/sim/fit/sim_summarise_student_mu_random_intercept.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_run_first_wave_summary_smoke.R`
- `inst/sim/run/sim_run_student_mu_random_intercept_smoke.R`
- `inst/sim/run/sim_summary_student_mu_random_intercept_smoke.R`
- `inst/sim/run/sim_write_student_mu_random_intercept_grid.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-first-wave-summary-smoke-runner.R`
- `tests/testthat/test-phase18-student-mu-random-intercept.R`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_student_mu_random_intercept.R inst/sim/fit/sim_summarise_student_mu_random_intercept.R inst/sim/run/sim_run_student_mu_random_intercept_smoke.R inst/sim/run/sim_summary_student_mu_random_intercept_smoke.R inst/sim/run/sim_write_student_mu_random_intercept_grid.R inst/sim/run/sim_run_first_wave_summary_smoke.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-student-mu-random-intercept.R tests/testthat/test-phase18-first-wave-summary-smoke-runner.R tests/testthat/test-phase18-actions-runner.R
Rscript --vanilla -e "files <- c('inst/sim/dgp/sim_dgp_student_mu_random_intercept.R','inst/sim/fit/sim_summarise_student_mu_random_intercept.R','inst/sim/run/sim_run_student_mu_random_intercept_smoke.R','inst/sim/run/sim_summary_student_mu_random_intercept_smoke.R','inst/sim/run/sim_write_student_mu_random_intercept_grid.R','inst/sim/run/sim_run_first_wave_summary_smoke.R','inst/sim/run/sim_run_actions_cell.R','tests/testthat/test-phase18-student-mu-random-intercept.R','tests/testthat/test-phase18-first-wave-summary-smoke-runner.R','tests/testthat/test-phase18-actions-runner.R'); invisible(lapply(files, parse)); cat('ok parse\n')"
Rscript --vanilla -e "devtools::test(filter = '^phase18-student-mu-random-intercept$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^(phase18-student-mu-random-intercept|phase18-first-wave-summary-smoke-runner|phase18-actions-runner)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^(phase18-student-mu-random-intercept|student-location-scale)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
Rscript --vanilla -e "pkgdown::build_site(preview = FALSE)"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
git diff --check
```

All checks passed. `pkgdown::check_pkgdown()` reported no problems.

## Tests Of The Tests

The focused test covers:

- DGP truth metadata and the `nu = 2 + exp(eta_nu)` transform;
- two one-replicate smoke cells with different true `nu` values;
- real `drmTMB()` fits through the Student-t random-intercept formula;
- fixed-effect Wald artifact rows for `mu`, `sigma`, and `nu`;
- direct-SD profile artifact rows for `sd:mu:(1 | id)`;
- grid-writer path creation, overwrite protection, and parallel-cap recording;
  and
- malformed `n_group`, `beta_nu`, `sd`, and `output_dir` inputs.

The first-wave summary smoke-runner test also caught the shared integration
surface by requiring the parallel-summary row count to increase from 13 to 14.

## Consistency Audit

The source and rendered stale scan returned no matches:

```sh
rg -n 'Student-t remains source-tested only|Student-t.*source-test(ed)? only|source-level first-slice evidence.*Student-t|Ready as source-level first-slice evidence|Student-t.*needs.*artifact lane|student\(\).*needs.*artifact' README.md NEWS.md ROADMAP.md docs/design inst/sim/README.md pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html -g '!*.json'
```

The positive-evidence scan found the expected entries in source files, tests,
workflow YAML, NEWS, README/ROADMAP, design docs, the simulation README, and
rendered pkgdown pages:

```sh
rg -n 'Student-t `mu` random-intercept artifact|student_mu_random_intercept|student-mu-ri' README.md NEWS.md ROADMAP.md docs/design inst/sim/README.md inst/sim/run tests/testthat .github/workflows/phase18-simulation-grid.yaml pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html -g '!*.json'
```

## GitHub Issue Maintenance

The issue search was:

```sh
gh issue list --repo itchyshin/drmTMB --state open --search "Student-t random intercept Phase 18 OR student_mu_random_intercept OR Student-t artifact" --limit 20 --json number,title,state,url,labels
```

It found #128, "Clarify random-effect slope capacity across location and scale
blocks." I did not comment because this slice adds only an ordinary
random-intercept artifact lane and leaves Student-t slopes explicitly planned.

## What Did Not Go Smoothly

The implementation itself was direct. The main thing to watch is runtime: the
first-wave summary smoke runner now includes one more real fit plus a direct
SD profile, so future first-wave lanes should keep row-count and runtime
expectations in the tests.

## Team Learning

The existing first-wave wiring checklist worked: the new lane updated the
source list, runner body, parallel-summary connector, expected surfaces, and
row counts before closeout. No new team-improvement entry was needed.

## Known Limitations

This is smoke/artifact evidence, not a formal coverage claim. Larger grids need
enough replicates to make Monte Carlo standard errors meaningful, especially
for the Student-t tail-thickness coefficient.

The slice does not implement Student-t random slopes, labelled covariance,
`sigma` random effects, `nu` random effects, structured effects, known
covariance, bivariate Student-t models, skew-normal, or skew-t.

## Next Actions

- Run the `student_mu_random_intercept` Actions task after merge if a larger
  remote artifact is needed.
- Keep the next Slice D choice separate: skew-normal, Tweedie, or another
  count-family design gate should not be bundled into this Student-t artifact
  lane.
