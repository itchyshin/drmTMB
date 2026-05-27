# After Task: Phase 18 Positive-Continuous Mu Random-Intercept Artifacts

## Goal

Add the Phase 18 artifact lane for fitted positive-continuous ordinary
`mu` random intercepts in `lognormal()` and `Gamma(link = "log")` after the
source-test slice and fixed-effect positive-continuous artifacts were already
on `main`.

## Implemented

The new artifact surface is `positive_continuous_mu_random_intercept`. It
covers only:

```r
drmTMB(
  bf(y ~ x + (1 | id), sigma ~ z),
  family = lognormal(),
  data = dat
)

drmTMB(
  bf(y ~ x + (1 | id), sigma ~ z),
  family = Gamma(link = "log"),
  data = dat
)
```

The lane adds a DGP, fit summariser, smoke runner, summary helper, repeatable
grid writer, first-wave summary inclusion, manual GitHub Actions dispatch
task, focused tests, design note, readiness updates, NEWS, simulation README
entries, check-log evidence, and a team-improvement note.

## Mathematical Contract

For each group `id`, the DGP draws a Gaussian random intercept and centres the
realized intercept vector:

```text
b_id ~ Normal(0, sd_id)
eta_mu_i = beta0 + beta1 * x_i + b_id[i]
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
```

For lognormal data:

```text
y_i ~ LogNormal(meanlog = eta_mu_i, sdlog = sigma_i)
E[y_i] = exp(eta_mu_i + 0.5 * sigma_i^2)
```

For Gamma data:

```text
mu_i = exp(eta_mu_i)
y_i ~ Gamma(shape = 1 / sigma_i^2, scale = mu_i * sigma_i^2)
E[y_i] = mu_i
```

The estimands are the fixed `mu` and `sigma` formula coefficients on their
modelled link scales plus the public `sd:mu:(1 | id)` random-intercept SD.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/design/118-phase-18-positive-continuous-mu-random-intercept-artifacts-slices-1369-1378.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`
- `inst/sim/README.md`
- `inst/sim/dgp/sim_dgp_positive_continuous_mu_random_intercept.R`
- `inst/sim/fit/sim_summarise_positive_continuous_mu_random_intercept.R`
- `inst/sim/run/sim_run_positive_continuous_mu_random_intercept_smoke.R`
- `inst/sim/run/sim_summary_positive_continuous_mu_random_intercept_smoke.R`
- `inst/sim/run/sim_write_positive_continuous_mu_random_intercept_grid.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_run_first_wave_summary_smoke.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-first-wave-summary-smoke-runner.R`
- `tests/testthat/test-phase18-positive-continuous-mu-random-intercept.R`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_positive_continuous_mu_random_intercept.R inst/sim/fit/sim_summarise_positive_continuous_mu_random_intercept.R inst/sim/run/sim_run_positive_continuous_mu_random_intercept_smoke.R inst/sim/run/sim_summary_positive_continuous_mu_random_intercept_smoke.R inst/sim/run/sim_write_positive_continuous_mu_random_intercept_grid.R inst/sim/run/sim_run_first_wave_summary_smoke.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-positive-continuous-mu-random-intercept.R tests/testthat/test-phase18-first-wave-summary-smoke-runner.R tests/testthat/test-phase18-actions-runner.R .github/workflows/phase18-simulation-grid.yaml
air format NEWS.md README.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/118-phase-18-positive-continuous-mu-random-intercept-artifacts-slices-1369-1378.md inst/sim/README.md docs/dev-log/team-improvements.md docs/dev-log/after-task/2026-05-26-positive-continuous-mu-random-intercept-artifacts-slices-1369-1378.md
Rscript --vanilla -e "files <- c('inst/sim/dgp/sim_dgp_positive_continuous_mu_random_intercept.R','inst/sim/fit/sim_summarise_positive_continuous_mu_random_intercept.R','inst/sim/run/sim_run_positive_continuous_mu_random_intercept_smoke.R','inst/sim/run/sim_summary_positive_continuous_mu_random_intercept_smoke.R','inst/sim/run/sim_write_positive_continuous_mu_random_intercept_grid.R','inst/sim/run/sim_run_first_wave_summary_smoke.R','inst/sim/run/sim_run_actions_cell.R','tests/testthat/test-phase18-positive-continuous-mu-random-intercept.R','tests/testthat/test-phase18-first-wave-summary-smoke-runner.R','tests/testthat/test-phase18-actions-runner.R'); invisible(lapply(files, parse)); cat('ok parse\n')"
Rscript --vanilla -e "devtools::test(filter = '^(phase18-positive-continuous-mu-random-intercept|phase18-first-wave-summary-smoke-runner|phase18-actions-runner|lognormal-location-scale|gamma-location-scale)$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::build_site(preview = FALSE)"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'Ordinary `mu` random intercepts now have a separate source-test slice|ordinary `mu` random intercepts now have a separate source-test slice|Focused source tests cover the ordinary `mu` random-intercept slice|Ready as source-level first-slice evidence; random slopes' README.md NEWS.md ROADMAP.md docs/design inst/sim/README.md pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html -g '!*.json'
rg -n 'positive_continuous_mu_random_intercept|positive-continuous `mu` random-intercept artifact lane|phase18_dgp_positive_continuous_mu_ri\(\)|positive-continuous-mu-ri|positive_continuous_mu_random_intercept_grid' README.md NEWS.md ROADMAP.md docs/design inst/sim/README.md tests/testthat inst/sim .github/workflows pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html -g '!*.json'
gh issue list --repo itchyshin/drmTMB --state open --search "positive continuous random intercept Phase 18" --limit 20 --json number,title,state,url,labels
git diff --check
```

- Focused tests passed for the lognormal/Gamma source tests, the new artifact
  lane, first-wave summary integration, and Actions dry-run parsing.
- Full `pkgdown::build_site(preview = FALSE)` passed after the ROADMAP stale
  wording correction, and `pkgdown::check_pkgdown()` reported no problems.
- The exact stale scan returned no matches.
- The positive evidence scan found the new source, tests, Actions task, docs,
  and generated-site mentions.
- `git diff --check` was clean.
- The overlapping open-issue search returned no matches.

## Tests Of The Tests

The new test file checks:

- family-specific DGP outputs for lognormal and Gamma positive responses;
- smoke summaries with 10 parameter rows, no failures, fixed-effect Wald rows,
  and two direct-SD profile rows;
- grid-writer CSV artifacts, overwrite rejection, and overwrite success; and
- malformed family, group-count, SD, and output-directory inputs.

The first-wave smoke-runner test now expects the
`positive_continuous_mu_random_intercept_grid` surface, 13 parallel-summary
rows, and the larger aggregate and Wald-coverage table sizes. The Actions
dry-run test now accepts the standalone
`positive_continuous_mu_random_intercept` task.

## Consistency Audit

The docs now separate three positive-continuous levels:

1. fixed-effect lognormal and Gamma artifacts;
2. lognormal and Gamma ordinary `mu` random-intercept artifacts; and
3. still-planned positive-continuous neighbours such as random slopes,
   labelled covariance, `sigma` random effects, structured effects, known
   covariance, Tweedie, generalized Gamma, and mixed-response models.

Rose's stale scan found two older ROADMAP rows that still made lognormal/Gamma
ordinary `mu` random intercepts sound source-test-only. Those rows and the
generated site were corrected before the final pkgdown check.

## GitHub Issue Maintenance

The search
`gh issue list --repo itchyshin/drmTMB --state open --search "positive continuous random intercept Phase 18" --limit 20 --json number,title,state,url,labels`
returned no matching open issues. No duplicate issue was opened because the
artifact lane is complete in this PR-sized slice.

## What Did Not Go Smoothly

The first implementation and test pass was clean. The only correction was
status-ledger drift: two ROADMAP rows lagged behind the newly added artifact
lane until the generated-site stale scan caught them.

## Team Learning

- Ada kept the lane to lognormal and Gamma ordinary `(1 | id)` in `mu`.
- Boole checked the Actions task name and formula syntax.
- Gauss and Noether checked that the DGP, fitted formulas, and public SD
  estimand all live on the documented log-location or log-mean scale.
- Curie added DGP, smoke, grid-writer, malformed-input, first-wave, and Actions
  tests.
- Grace ran focused tests, pkgdown, stale/evidence scans, and diff hygiene.
- Rose caught stale ROADMAP wording and recorded the stale-status scan lesson.
- Pat kept the user-facing boundary to repeated positive responses with
  ordinary `(1 | id)`.
- No spawned subagents were running.

## Known Limitations

The lane does not claim positive-continuous random slopes, labelled covariance,
`sigma` random effects, structured effects, known covariance, Tweedie,
generalized Gamma, or bivariate/mixed positive-continuous models.

## Next Actions

If this PR passes CI and merges, the next safe Phase 18 choice is either a
Student-t ordinary `mu` random-intercept artifact lane or a smaller
follow-through doc/status lane if CI exposes drift.
