# After Task: Phase 18 Bounded-Response Mu Random-Intercept Artifacts

## Goal

Add the first Phase 18 artifact lane for fitted bounded-response ordinary
`mu` random intercepts after the fixed-effect zero-one beta artifacts and the
non-Gaussian tutorial gate merged.

## Implemented

The new artifact surface is `bounded_response_mu_random_intercept`. It covers
only:

```r
drmTMB(
  bf(prop ~ x + (1 | id), sigma ~ z),
  family = beta(),
  data = dat
)

drmTMB(
  bf(cbind(success, failure) ~ x + (1 | id), sigma ~ z),
  family = beta_binomial(),
  data = dat
)
```

The lane adds a DGP, fit summariser, smoke runner, summary helper, repeatable
grid writer, first-wave summary inclusion, manual GitHub Actions dispatch
task, focused tests, design note, readiness updates, `NEWS.md`, simulation
README entries, check-log evidence, and a team-improvement note.

## Mathematical Contract

For each group `id`, the DGP draws a Gaussian random intercept on the
logit-mean scale:

```text
b_id ~ Normal(0, sd_id)
eta_mu_i = beta0 + beta1 * x_i + b_id[i]
mu_i = logit^-1(eta_mu_i)
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
phi_i = 1 / sigma_i^2
```

For strict continuous proportions, `prop_i` is drawn from
`Beta(mu_i * phi_i, (1 - mu_i) * phi_i)`. For successes out of known trials,
the DGP draws a latent `p_i` from the same beta component and then draws
`success_i ~ Binomial(trials_i, p_i)`.

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
- `docs/design/117-phase-18-bounded-response-mu-random-intercept-artifacts-slices-1359-1368.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`
- `inst/sim/README.md`
- `inst/sim/dgp/sim_dgp_bounded_response_mu_random_intercept.R`
- `inst/sim/fit/sim_summarise_bounded_response_mu_random_intercept.R`
- `inst/sim/run/sim_run_bounded_response_mu_random_intercept_smoke.R`
- `inst/sim/run/sim_summary_bounded_response_mu_random_intercept_smoke.R`
- `inst/sim/run/sim_write_bounded_response_mu_random_intercept_grid.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_run_first_wave_summary_smoke.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-bounded-response-mu-random-intercept.R`
- `tests/testthat/test-phase18-first-wave-summary-smoke-runner.R`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_bounded_response_mu_random_intercept.R inst/sim/fit/sim_summarise_bounded_response_mu_random_intercept.R inst/sim/run/sim_run_bounded_response_mu_random_intercept_smoke.R inst/sim/run/sim_summary_bounded_response_mu_random_intercept_smoke.R inst/sim/run/sim_write_bounded_response_mu_random_intercept_grid.R inst/sim/run/sim_run_first_wave_summary_smoke.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-bounded-response-mu-random-intercept.R tests/testthat/test-phase18-actions-runner.R
air format tests/testthat/test-phase18-first-wave-summary-smoke-runner.R inst/sim/run/sim_run_first_wave_summary_smoke.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-actions-runner.R
air format NEWS.md README.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/117-phase-18-bounded-response-mu-random-intercept-artifacts-slices-1359-1368.md inst/sim/README.md docs/dev-log/team-improvements.md
Rscript --vanilla -e "devtools::test(filter = '^(phase18-bounded-response-mu-random-intercept|phase18-first-wave-summary-smoke-runner|phase18-actions-runner|beta-location-scale|beta-binomial)$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::build_site(preview = FALSE)"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'bounded-response ordinary `mu` random-intercept slices still need|bounded-response `mu` random-intercept source-test lanes|bounded-response random-effect grids, random slopes|bounded-response random effects beyond the beta and beta-binomial ordinary `mu` intercept slices' README.md NEWS.md ROADMAP.md docs/design inst/sim/README.md pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html -g '!*.json'
rg -n 'bounded_response_mu_random_intercept|Phase 18 now has a bounded-response `mu` random-intercept artifact lane|bounded-response ordinary `mu` random-intercept artifact lane|phase18_dgp_bounded_response_mu_ri\(\)|direct-SD profile interval|bounded_response_mu_random_intercept_grid' README.md NEWS.md ROADMAP.md docs/design inst/sim/README.md tests/testthat inst/sim .github/workflows pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html -g '!*.json'
gh issue list --repo itchyshin/drmTMB --state open --search "bounded response random intercept Phase 18" --limit 20 --json number,title,state,url,labels
git diff --check
```

- Focused tests passed for the beta and beta-binomial source tests, the new
  bounded-response artifact lane, the first-wave summary runner, and the
  Actions dry-run parser.
- Full `pkgdown::build_site(preview = FALSE)` passed.
- `pkgdown::check_pkgdown()` reported no problems.
- The stale scan returned no matches after the fixed-effect proportion wording
  was tightened.
- The positive evidence scan found the new source, tests, Actions task,
  `NEWS.md`, README, ROADMAP, simulation README, design notes, and generated
  site mentions.
- `git diff --check` was clean.

## Tests Of The Tests

The new test file checks:

- family-specific DGP outputs for strict beta and beta-binomial data;
- smoke summaries with 10 parameter rows, no failures, fixed-effect Wald rows,
  and two direct-SD profile rows;
- grid-writer CSV artifacts, overwrite rejection, and overwrite success; and
- malformed family, trial-range, SD, and output-directory inputs.

The first-wave smoke-runner test now expects the
`bounded_response_mu_random_intercept_grid` surface, 12 parallel-summary rows,
and the larger aggregate and Wald-coverage table sizes. The Actions dry-run
test now accepts the standalone `bounded_response_mu_random_intercept` task.

## Consistency Audit

The docs now separate three bounded-response levels:

1. fixed-effect beta and beta-binomial artifacts;
2. beta and beta-binomial ordinary `mu` random-intercept artifacts; and
3. still-planned bounded-response neighbours such as random slopes, labelled
   covariance, `sigma` random effects, exact-boundary random effects, structured
   effects, known covariance, and mixed-response models.

Rose’s stale scan initially found two older fixed-effect-lane phrases that
made bounded-response random effects sound broadly excluded. Those were
tightened in `NEWS.md` and the readiness matrix before the final pkgdown build.

## GitHub Issue Maintenance

The search
`gh issue list --repo itchyshin/drmTMB --state open --search "bounded response random intercept Phase 18" --limit 20 --json number,title,state,url,labels`
returned no matching open issues. No duplicate issue was opened because the
artifact lane is complete in this PR-sized slice.

## What Did Not Go Smoothly

The first test run produced no summaries because the DGP reused
`phase18_named_pair()` for a one-SD vector. That helper is intentionally
two-valued for intercept-plus-slope surfaces. The fix added a
one-SD validator, and the team-improvement log now records that pattern.

## Team Learning

- Ada kept the lane to beta and beta-binomial ordinary `(1 | id)` in `mu`.
- Boole checked the Actions task name and source-order contract.
- Gauss and Noether checked that the DGP, fitted formulas, and public SD
  estimand all live on the same logit-mean/random-intercept scale.
- Curie kept the tests focused on DGP shape, artifact tables, overwrite
  safety, malformed inputs, and first-wave integration.
- Grace ran focused tests, pkgdown, stale/evidence scans, and diff hygiene.
- Rose caught the stale fixed-effect wording and the one-SD helper lesson.
- Pat’s reader route stays concrete: use `(1 | id)` only for repeated strict
  proportions or successes out of known trials.
- No spawned subagents were running.

## Known Limitations

The lane does not claim bounded-response random slopes, labelled covariance,
`sigma` random effects, exact 0/1 boundary mass in `beta()`, zero-one beta
random effects, structured bounded-response effects, known covariance, or
bivariate/mixed bounded-response models.

## Next Actions

If this PR passes CI and merges, the next safe Phase 18 choice is either a
positive-continuous ordinary `mu` random-intercept artifact lane or a smaller
follow-through doc/status lane if CI exposes drift.
