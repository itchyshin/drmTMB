# After Task: Zero-One Beta Fixed-Effect Artifacts, Slices 1339-1348

## Goal

Add a Phase 18 artifact lane for the implemented fixed-effect `zero_one_beta()`
surface while keeping zero-one random effects, covariance blocks, denominators,
known covariance, structured bounded responses, and bivariate bounded responses
closed.

## Implemented

The implemented claim is: `drmTMB` now has private Phase 18 smoke/artifact
helpers for fixed-effect `zero_one_beta()` models with `mu`, `sigma`, `zoi`,
and `coi` formulas.

The lane adds:

- `phase18_dgp_zero_one_beta_fe()`;
- `phase18_summarise_zero_one_beta_fe_fit()`;
- `phase18_run_zero_one_beta_fe_smoke()`;
- `phase18_summarise_zero_one_beta_fe_smoke()`;
- `phase18_write_zero_one_beta_fe_grid_outputs()`;
- `tests/testthat/test-phase18-zero-one-beta-fixed-effect.R`;
- first-wave summary runner inclusion; and
- a manual `zero_one_beta_fixed_effect` Actions task.

## Mathematical Contract

The DGP and fit use:

```text
logit(mu_i) = beta0 + beta1 * x_i
log(sigma_i) = gamma0 + gamma1 * z_i
logit(zoi_i) = zeta0 + zeta1 * w_i
logit(coi_i) = kappa0 + kappa1 * v_i
Pr(y_i = 0) = zoi_i * (1 - coi_i)
Pr(y_i = 1) = zoi_i * coi_i
Pr(0 < y_i < 1) = 1 - zoi_i
```

Interior observations are beta draws with precision `phi_i = 1 / sigma_i^2`.
The artifact estimands are the fixed formula coefficients on the fitted link
scales.

## Files Changed

Code and tests changed under `.github/workflows/`, `inst/sim/`, and
`tests/testthat/`. Documentation and ledgers changed in NEWS, ROADMAP,
`docs/design/`, `inst/sim/README.md`, `vignettes/implementation-map.Rmd`,
`docs/dev-log/check-log.md`, and `docs/dev-log/team-improvements.md`.

## Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = 'phase18-zero-one-beta-fixed-effect', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = 'phase18-actions-runner', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = 'phase18-first-wave-summary-smoke-runner', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = 'phase18-zero-one-beta-fixed-effect|phase18-actions-runner|phase18-first-wave-summary-smoke-runner', reporter = 'summary')"
Rscript --vanilla inst/sim/run/sim_run_actions_cell.R --task=zero_one_beta_fixed_effect --dry-run=true --n-reps=2 --cores=10 --backend=multicore --master-seed=20260536
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'zero-one beta.*(still needs its own artifact lane|no broad artifact lane|no artifact lane)|zero_one_beta\(\).*source-tested but still needs|add a zero-one beta artifact lane before|fixed-effect zero-one beta is source-tested|zero-one beta source-test' NEWS.md ROADMAP.md docs/design inst/sim/README.md vignettes -g '!*.html'
git diff --check
```

All commands passed. The stale-wording scan returned no matches.

## Tests Of The Tests

The new test file checks the DGP produces interior and exact-boundary values,
the summary smoke returns eight coefficient rows with Wald intervals and
coverage rows, the grid writer creates all table artifacts and enforces
overwrite rules, and malformed inputs are rejected.

The first-wave smoke-runner test caught a real integration miss: the new grid
output had been added to the runner but not to
`phase18_first_wave_parallel_summary()`. That failure was fixed before
closeout, and the team-improvements log now records the wiring checklist.

## Consistency Audit

The implementation, design note, simulation README, readiness matrix, supported
non-Gaussian evidence goal, family registry, ROADMAP, NEWS, implementation map,
and check log now agree that fixed-effect zero-one beta has artifact helpers.
They also keep `zoi`/`coi` random effects, covariance blocks, denominator
syntax, structured bounded responses, and mixed or bivariate bounded-response
models out of scope.

## GitHub Issue Maintenance

The overlapping issue search found #57, a broader proportion tutorial/pkgdown
issue. I commented there with the artifact-lane status:
<https://github.com/itchyshin/drmTMB/issues/57#issuecomment-4550273846>.
The issue remains open because reader-facing tutorial follow-through is still a
separate task.

## What Did Not Go Smoothly

I initially missed one first-wave summary connector after adding the new grid
output. The existing first-wave smoke-runner test caught the error quickly.

## Team Learning

Ada should keep first-wave additions as wiring checklists, not just per-surface
helpers. Curie should run the first-wave smoke-runner test before calling a new
artifact surface integrated. Grace should keep the manual Actions dry-run in
the validation bundle. Rose should scan both old false negatives and new false
positives after any fitted or artifact status changes.

## Known Limitations

This is smoke/artifact infrastructure, not a broad operating-characteristic
claim. Larger grids still need audited replicate counts and Monte Carlo
standard errors before recovery or coverage claims are made. No random effects,
known covariance, structured dependence, denominator syntax, or bivariate
bounded-response model was added.

## Next Actions

If the PR lands green, the next lane can either close the reader/tutorial/pkgdown
follow-through or add bounded-response ordinary `mu` random-intercept artifacts
for beta and beta-binomial as a separate slice.
