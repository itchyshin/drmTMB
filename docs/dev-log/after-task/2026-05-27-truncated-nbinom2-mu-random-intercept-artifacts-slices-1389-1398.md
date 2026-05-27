# After Task: Truncated NB2 Mu Random-Intercept Artifacts, Slices 1389-1398

## Goal

Add the Phase 18 artifact lane for the fitted zero-truncated NB2 ordinary
`mu` random-intercept route:

```r
drmTMB(
  bf(count ~ x + (1 | id), sigma ~ z),
  family = truncated_nbinom2(),
  data = dat
)
```

The task should not widen the fitted surface to zero-truncated NB2 random
slopes, labelled covariance, `sigma` random effects, hurdle random effects,
zero-inflated zero-truncated models, structured effects, or bivariate count
models.

## Implemented

The new lane adds:

- `phase18_dgp_truncated_nbinom2_mu_ri()`;
- `phase18_summarise_truncated_nbinom2_mu_ri_fit()`;
- `phase18_run_truncated_nbinom2_mu_ri_smoke()`;
- `phase18_summarise_truncated_nbinom2_mu_ri_smoke()`;
- `phase18_write_truncated_nbinom2_mu_ri_grid_outputs()`;
- a focused test file for the DGP, smoke summary, grid writer, and malformed
  inputs;
- first-wave summary runner inclusion; and
- a manual `truncated_nbinom2_mu_random_intercept` Actions task.

The grid writer saves aggregate, replicate, manifest, failure-ledger,
fixed-effect Wald interval, Wald coverage, direct-SD profile interval, and
profile coverage CSV artifacts.

## Mathematical Contract

The DGP draws one ordinary group intercept for the untruncated NB2 log-mean
component, centres the realized intercept vector, and then conditions the
observed count on being positive:

```text
b_id ~ Normal(0, sd_id)
eta_mu_i = beta0 + beta1 * x_i + b_id[i]
mu_i = exp(eta_mu_i)
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
Y_i^* ~ NB2(mu_i, size_i = 1 / sigma_i^2)
Y_i = Y_i^* | Y_i^* > 0
```

The untruncated NB2 variance is
`Var(Y_i^*) = mu_i + sigma_i^2 * mu_i^2`. The public fitted mean for
`truncated_nbinom2()` is the positive-count conditional mean,
`E[Y_i | Y_i > 0] = mu_i / (1 - Pr(Y_i^* = 0))`.

The summary rows target `mu` and `sigma` formula coefficients on their modelled
log scales plus the public `sd:mu:(1 | id)` random-intercept SD.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/120-phase-18-truncated-nbinom2-mu-random-intercept-artifacts-slices-1389-1398.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`
- `inst/sim/dgp/sim_dgp_truncated_nbinom2_mu_random_intercept.R`
- `inst/sim/fit/sim_summarise_truncated_nbinom2_mu_random_intercept.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_run_first_wave_summary_smoke.R`
- `inst/sim/run/sim_run_truncated_nbinom2_mu_random_intercept_smoke.R`
- `inst/sim/run/sim_summary_truncated_nbinom2_mu_random_intercept_smoke.R`
- `inst/sim/run/sim_write_truncated_nbinom2_mu_random_intercept_grid.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-first-wave-summary-smoke-runner.R`
- `tests/testthat/test-phase18-truncated-nbinom2-mu-random-intercept.R`

## Checks Run

```sh
Rscript tools/codex-checkpoint.R --goal "resume truncated NB2 mu random-intercept artifact lane and plan profile-likelihood plotting capability" --next "inspect dirty tree, finish docs/check-log/after-task evidence, then scope profile-likelihood plotting helper against existing profile_targets/confint paths"
air format .github/workflows/phase18-simulation-grid.yaml inst/sim/dgp/sim_dgp_truncated_nbinom2_mu_random_intercept.R inst/sim/fit/sim_summarise_truncated_nbinom2_mu_random_intercept.R inst/sim/run/sim_run_truncated_nbinom2_mu_random_intercept_smoke.R inst/sim/run/sim_summary_truncated_nbinom2_mu_random_intercept_smoke.R inst/sim/run/sim_write_truncated_nbinom2_mu_random_intercept_grid.R inst/sim/run/sim_run_first_wave_summary_smoke.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-truncated-nbinom2-mu-random-intercept.R tests/testthat/test-phase18-first-wave-summary-smoke-runner.R tests/testthat/test-phase18-actions-runner.R NEWS.md README.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/120-phase-18-truncated-nbinom2-mu-random-intercept-artifacts-slices-1389-1398.md inst/sim/README.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-27-truncated-nbinom2-mu-random-intercept-artifacts-slices-1389-1398.md
Rscript --vanilla -e "files <- c('inst/sim/dgp/sim_dgp_truncated_nbinom2_mu_random_intercept.R','inst/sim/fit/sim_summarise_truncated_nbinom2_mu_random_intercept.R','inst/sim/run/sim_run_truncated_nbinom2_mu_random_intercept_smoke.R','inst/sim/run/sim_summary_truncated_nbinom2_mu_random_intercept_smoke.R','inst/sim/run/sim_write_truncated_nbinom2_mu_random_intercept_grid.R','inst/sim/run/sim_run_first_wave_summary_smoke.R','inst/sim/run/sim_run_actions_cell.R','tests/testthat/test-phase18-truncated-nbinom2-mu-random-intercept.R','tests/testthat/test-phase18-first-wave-summary-smoke-runner.R','tests/testthat/test-phase18-actions-runner.R'); invisible(lapply(files, parse)); cat('ok parse\n')"
Rscript --vanilla -e "devtools::test(filter = '^(phase18-truncated-nbinom2-mu-random-intercept|phase18-first-wave-summary-smoke-runner|phase18-actions-runner|truncated-nbinom2)$', reporter = 'summary')"
rg -n 'zero-truncated NB2.*source-test(ed)? only|zero-truncated NB2.*remain source-tested|zero-truncated NB2.*source-test lane|zero-truncated NB2.*random effects are blocked|ordinary zero-truncated NB2 `mu` random intercepts remain source-tested|Zero-truncated NB2 `mu` random effects \| Planned' README.md NEWS.md ROADMAP.md docs/design inst/sim/README.md -g '!*.html'
rg -n 'truncated_nbinom2_mu_random_intercept|zero-truncated NB2 `mu` random-intercept artifact lane|truncated-nb2-mu-ri|phase18_dgp_truncated_nbinom2_mu_ri\(\)|direct-SD profile interval' README.md NEWS.md ROADMAP.md docs/design inst/sim/README.md inst/sim/run tests/testthat .github/workflows/phase18-simulation-grid.yaml docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-27-truncated-nbinom2-mu-random-intercept-artifacts-slices-1389-1398.md -g '!*.html'
git diff --check
gh issue list --repo itchyshin/drmTMB --state open --search "truncated NB2 random intercept Phase 18 OR truncated_nbinom2_mu_random_intercept OR zero-truncated NB2 artifact" --limit 20 --json number,title,state,url,labels
Rscript --vanilla -e "pkgdown::build_site(preview = FALSE)"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'zero-truncated NB2.*source-test(ed)? only|zero-truncated NB2.*remain source-tested|zero-truncated NB2.*source-test lane|zero-truncated NB2.*random effects are blocked|ordinary zero-truncated NB2.*remain source-tested|Zero-truncated NB2.*Planned' pkgdown-site -g '*.html'
rg -n 'truncated_nbinom2_mu_random_intercept|zero-truncated NB2.*artifact lane|truncated-nb2-mu-ri|direct-SD profile interval|Zero-truncated NB2.*random-intercept artifacts' pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html -g '*.html'
```

- The recovery checkpoint was written before continuing from the interrupted
  run.
- Formatting completed without changes reported by `air`.
- Parse checks passed. The 2026-05-27 rerun also parsed the dirty-neighbour
  `R/profile.R` change separately so the unrelated profile-likelihood work
  would not hide a syntax failure while this count slice was being validated.
- The focused truncated NB2 artifact, first-wave summary, Actions runner, and
  neighbouring `truncated-nbinom2` test bundle passed.
- `pkgdown::build_site(preview = FALSE)` completed successfully.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.

## Tests Of The Tests

The focused test covers:

- DGP truth metadata, positive counts, positive `mu` and `sigma`, and the
  positive-count conditional mean;
- two one-replicate smoke cells with different true random-intercept SDs;
- real `drmTMB()` fits through the zero-truncated NB2 random-intercept formula;
- fixed-effect Wald artifact rows for `mu` and `sigma`;
- direct-SD profile artifact rows for `sd:mu:(1 | id)`;
- grid-writer path creation, overwrite protection, and parallel-cap recording;
  and
- malformed group-count, SD, cell, and output-directory inputs.

The first-wave summary smoke-runner test also checks that the shared runner
includes the `truncated_nbinom2_mu_random_intercept_grid` row and the updated
aggregate and Wald-coverage table sizes.

## Consistency Audit

The source ledgers now separate three count random-effect levels:

1. ordinary Poisson/NB2 `mu` random effects with paired count smoke/grid
   artifacts;
2. zero-truncated NB2 ordinary `mu` random-intercept artifacts; and
3. still-planned count neighbours such as zero-truncated random slopes,
   zero-inflation or hurdle random effects, count-side structured effects, and
   bivariate or mixed count models.

The source and rendered stale scans returned no matches:

```sh
rg -n 'zero-truncated NB2.*source-test(ed)? only|zero-truncated NB2.*remain source-tested|zero-truncated NB2.*source-test lane|zero-truncated NB2.*random effects are blocked|ordinary zero-truncated NB2 `mu` random intercepts remain source-tested|Zero-truncated NB2 `mu` random effects \| Planned' README.md NEWS.md ROADMAP.md docs/design inst/sim/README.md -g '!*.html'
rg -n 'zero-truncated NB2.*source-test(ed)? only|zero-truncated NB2.*remain source-tested|zero-truncated NB2.*source-test lane|zero-truncated NB2.*random effects are blocked|ordinary zero-truncated NB2.*remain source-tested|Zero-truncated NB2.*Planned' pkgdown-site -g '*.html'
```

The source and rendered positive-evidence scans found the expected source,
tests, workflow, NEWS, README/ROADMAP, design-doc, simulation README,
check-log, after-task, and rendered-site entries:

```sh
rg -n 'truncated_nbinom2_mu_random_intercept|zero-truncated NB2 `mu` random-intercept artifact lane|truncated-nb2-mu-ri|phase18_dgp_truncated_nbinom2_mu_ri\(\)|direct-SD profile interval' README.md NEWS.md ROADMAP.md docs/design inst/sim/README.md inst/sim/run tests/testthat .github/workflows/phase18-simulation-grid.yaml docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-27-truncated-nbinom2-mu-random-intercept-artifacts-slices-1389-1398.md -g '!*.html'
rg -n 'truncated_nbinom2_mu_random_intercept|zero-truncated NB2.*artifact lane|truncated-nb2-mu-ri|direct-SD profile interval|Zero-truncated NB2.*random-intercept artifacts' pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html -g '*.html'
```

## GitHub Issue Maintenance

The issue search was:

```sh
gh issue list --repo itchyshin/drmTMB --state open --search "truncated NB2 random intercept Phase 18 OR truncated_nbinom2_mu_random_intercept OR zero-truncated NB2 artifact" --limit 20 --json number,title,state,url,labels
```

It found #128, "Clarify random-effect slope capacity across location and scale
blocks." A 2026-05-27 rerun also found release-start issue #342 because that
issue mentions the current dirty worktree and the truncated-NB2 caveat. I did
not comment on either issue because this slice adds only an ordinary
zero-truncated NB2 random-intercept artifact lane and leaves zero-truncated
slopes explicitly planned.

## What Did Not Go Smoothly

This slice resumed after an interrupted run, so the first step was a recovery
checkpoint and dirty-tree audit before editing. The worktree also contains a
larger unrelated `R/profile.R` profile-likelihood plotting change. I kept that
out of this slice's file list and treated it as the next separate
inference/output lane. The count code lane itself followed the previous
bounded-response, positive-continuous, and Student-t artifact pattern.

## Team Learning

- Ada kept the lane to `truncated_nbinom2()` ordinary `(1 | id)` in `mu`.
- Boole checked the Actions task name and formula syntax.
- Gauss and Noether checked that the DGP, fitted formula, and public SD
  estimand all live on the documented untruncated NB2 log-mean scale.
- Fisher kept Wald, profile, and coverage artifacts method-separated.
- Curie added DGP, smoke, grid-writer, malformed-input, first-wave, and
  Actions tests.
- Grace owns the focused validation, pkgdown, stale/evidence scans, issue
  search, and diff hygiene.
- Rose checked the source-tested-to-artifact status transition.
- Pat kept the user-facing boundary to repeated positive counts with ordinary
  `(1 | id)`.
- No spawned subagents were running.

## Known Limitations

This is smoke/artifact evidence, not a formal coverage claim. Larger grids need
enough replicates to make Monte Carlo standard errors meaningful, especially in
cells with low means or strong truncation.

The slice does not implement zero-truncated NB2 random slopes, labelled
covariance, `sigma` random effects, hurdle random effects,
zero-inflated zero-truncated models, structured effects, or bivariate count
models.

## Next Actions

- Run the `truncated_nbinom2_mu_random_intercept` Actions task after merge if a
  larger remote artifact is needed.
- Start the profile-likelihood plotting design as a separate inference/output
  slice so visual diagnostics do not get bundled into this count artifact lane.
