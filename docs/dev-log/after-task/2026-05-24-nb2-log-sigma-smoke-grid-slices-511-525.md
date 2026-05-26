# After Task: NB2 Log-Sigma Smoke Grid Slices 511-525

## Goal

Add a narrow Phase 18 smoke-grid evidence lane for ordinary NB2 grouped
overdispersion, using `bf(count ~ x, sigma ~ z + (1 | id))`, after the fitted
NB2 log-`sigma` random-intercept gate landed. The task should not expand the
likelihood, formula grammar, or public support boundary beyond the existing
ordinary non-zero-inflated NB2 `sigma` random intercept.

## Implemented

The slice adds a seeded DGP, fit wrapper, fit summariser, smoke runner, summary
helper, repeatable CSV grid writer, focused tests, ADEMP sheet, source-map
entry, readiness/programme synchronization, NEWS entry, ROADMAP rows 511-525,
and this after-task report.

The new grid writer saves aggregate, replicate, manifest, failure-ledger, Wald
interval, Wald coverage, direct `log_sd_sigma` profile-target, optional profile
interval, profile coverage, interval-evidence, interval-diagnostics, and
interval-failure CSVs beside resumable per-replicate RDS files.

## Mathematical Contract

For group `j` and observation `k`, the DGP is

```text
a_j ~ Normal(0, sd_sigma_intercept^2)
eta_mu_jk = beta0 + beta1 * x_jk
mu_jk = exp(eta_mu_jk)
eta_sigma_jk = gamma0 + gamma1 * z_jk + a_j
sigma_jk = exp(eta_sigma_jk)
count_jk ~ NB2(mu_jk, size = 1 / sigma_jk^2)
```

The fitted model is

```r
drmTMB(
  bf(count ~ x, sigma ~ z + (1 | id)),
  family = nbinom2(),
  data = dat
)
```

The estimands are fixed `mu`, fixed `sigma`, the public `sd:sigma:(1 | id)`
row, the direct TMB target `log_sd_sigma`, and the `check_drm()` replication
diagnostic for the ordinary grouped scale effect.

## Files Changed

- `docs/design/73-phase-18-nbinom2-sigma-random-intercept-ademp.md`
- `inst/sim/dgp/sim_dgp_nbinom2_sigma_random_effect.R`
- `inst/sim/fit/sim_summarise_nbinom2_sigma_random_effect.R`
- `inst/sim/run/sim_run_nbinom2_sigma_random_effect_smoke.R`
- `inst/sim/run/sim_summary_nbinom2_sigma_random_effect_smoke.R`
- `inst/sim/run/sim_write_nbinom2_sigma_random_effect_grid.R`
- `tests/testthat/test-phase18-nbinom2-sigma-random-effect.R`
- `inst/sim/README.md`
- `vignettes/source-map.Rmd`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format NEWS.md ROADMAP.md inst/sim/README.md vignettes/source-map.Rmd docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/73-phase-18-nbinom2-sigma-random-intercept-ademp.md inst/sim/dgp/sim_dgp_nbinom2_sigma_random_effect.R inst/sim/fit/sim_summarise_nbinom2_sigma_random_effect.R inst/sim/run/sim_run_nbinom2_sigma_random_effect_smoke.R inst/sim/run/sim_summary_nbinom2_sigma_random_effect_smoke.R inst/sim/run/sim_write_nbinom2_sigma_random_effect_grid.R tests/testthat/test-phase18-nbinom2-sigma-random-effect.R
Rscript -e "invisible(parse(file = 'inst/sim/dgp/sim_dgp_nbinom2_sigma_random_effect.R')); invisible(parse(file = 'inst/sim/fit/sim_summarise_nbinom2_sigma_random_effect.R')); invisible(parse(file = 'inst/sim/run/sim_run_nbinom2_sigma_random_effect_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_summary_nbinom2_sigma_random_effect_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_write_nbinom2_sigma_random_effect_grid.R')); invisible(parse(file = 'tests/testthat/test-phase18-nbinom2-sigma-random-effect.R')); cat('parse ok\n')"
Rscript -e "devtools::test(filter = 'phase18-nbinom2-sigma-random-effect', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'nbinom2-location-scale|nongaussian-scale-boundary', reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n '511|525|nbinom2_sigma_random_effect|phase18_nbinom2_sigma_re|log_sd_sigma|nbinom2-sigma-re-profile-targets|Phase 18 NB2 Sigma' NEWS.md ROADMAP.md inst/sim/README.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/73-phase-18-nbinom2-sigma-random-intercept-ademp.md vignettes/source-map.Rmd tests/testthat/test-phase18-nbinom2-sigma-random-effect.R
rg -n 'NB2 `sigma`.*(formal coverage|formal recovery|broad.*parity|ready for broad|structured.*now fit|sigma slopes.*fit|joint `mu`/`sigma`.*fit|zero-inflated.*sigma.*random.*fit)|NB2 log-`sigma`.*(formal coverage|formal recovery|ready for broad)|keeping NB2 `sigma`' NEWS.md ROADMAP.md README.md inst/sim/README.md docs/design vignettes tests -g '!*.html'
rg -n '511|525|nbinom2_sigma_random_effect|log_sd_sigma|nbinom2-sigma-re-profile-targets|Phase 18 NB2|phase18_nbinom2_sigma_re|supersede only the ordinary NB2 log' pkgdown-site/ROADMAP.html pkgdown-site/articles/source-map.html pkgdown-site/news/index.html
rg -n 'keeping NB2 <code>sigma</code>|NB2 <code>sigma</code> random effects remain planned|NB2 log-<code>sigma</code>.*ready for broad|NB2 <code>sigma</code> slopes.*now fit|joint <code>mu</code>/<code>sigma</code> random effects.*now fit|zero-inflated/truncated/hurdle.*scale random effects.*now fit' pkgdown-site -g '*.html'
gh issue list --repo itchyshin/drmTMB --state open --search "NB2 sigma random" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "nbinom2 sigma" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "Phase 18 NB2" --limit 20 --json number,title,state,url,labels
git diff --check
```

Results: formatting and parse checks passed; the focused new test passed; the
adjacent NB2 and non-Gaussian scale-boundary tests passed; `pkgdown` check and
site build completed; source and rendered stale scans found no active false
claim after one old ROADMAP boundary sentence was patched; `git diff --check`
was clean.

## Tests Of The Tests

The focused test checks seeded DGP reproducibility, condition-grid row counts,
summary row names, convergence and Hessian fields, failed Wald status for the
public SD row, direct `log_sd_sigma` profile-target status, artifact row
counts, overwrite protection, malformed DGP inputs, malformed cell inputs, and
profile-parameter validation. The grid-writer test exercises real NB2 fitting
through `drmTMB()` rather than only schema construction.

## Consistency Audit

Source and rendered docs now keep three layers separate:

- ordinary NB2 `mu` random effects remain the paired count-`mu` lane;
- ordinary NB2 log-`sigma` random intercepts now have their own smoke-grid
  evidence lane;
- NB2 `sigma` slopes, joint `mu`/`sigma`, zero-inflated/truncated/hurdle scale
  random effects, structured NB2 `sigma`, and NB2 `sigma` phylogeny remain
  planned.

Rose found one ROADMAP sentence from Slice 245 that still implied NB2 `sigma`
was outside Wave A without acknowledging the new ordinary intercept gate. The
patched text now says Slices 511-525 supersede only the ordinary NB2
log-`sigma` random-intercept part of that older boundary.

## GitHub Issue Maintenance

Issue searches:

- `"nbinom2 sigma"` returned no open issues.
- `"NB2 sigma random"` returned #128 and #57.
- `"Phase 18 NB2"` returned #60, #128, and #59.

No issue was opened or updated. #59 is the broad Phase 18 framework issue, #128
is about random-effect slope capacity, #60 is a later comparator-benchmark
issue, and #57 is not a direct NB2 log-`sigma` smoke-grid issue. The local
change is a narrow ledger slice; issue mutation can wait until the branch is
pushed or a broader Phase 18 milestone is being closed.

## What Did Not Go Smoothly

The first rendered stale scan matched a very long generated ROADMAP line. That
was noisy, but it surfaced a real stale sentence from the old Slice 245
boundary. The fix was small and worth the extra pkgdown rebuild.

## Team Learning

Rose should keep checking historical ROADMAP prose when a formerly blocked
feature receives a narrow first-slice admission. The stale claim may not be in
the current status table; it can sit in a slice narrative that pkgdown renders
as one long line.

## Known Limitations

This is smoke-grid evidence, not a formal operating-characteristic study.
Routine tests request no profile interval by default; they assert the direct
`log_sd_sigma` profile-target status and keep optional profile interval rows as
`not_requested`. Formal coverage still needs a larger replicate budget, profile
runtime review, and artifact review. NB2 `sigma` slopes, joint `mu`/`sigma`
random effects, zero-inflated/truncated/hurdle scale random effects, structured
NB2 `sigma`, and NB2 `sigma` phylogeny remain planned.

## Next Actions

Start the next requested lane, Slices 526-540, only after treating NB2
phylogenetic q1 as a separate overdispersion-aware recovery problem. That lane
should not borrow the NB2 log-`sigma` smoke-grid evidence for structured SD
recovery.
