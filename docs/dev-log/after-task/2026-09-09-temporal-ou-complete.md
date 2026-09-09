# Gaussian temporal OU provider closeout

## 1. Goal

Deliver a Gaussian maximum-likelihood OU temporal random-effect provider for
irregular elapsed time, with an optional same-ID ordinary intercept, separate
stable/process/residual variation, deterministic oracle checks, honest
fixed-effect interval scope, reader documentation, and retained calibration
evidence.

## 2. Implemented

The implementation spans the temporal parser and layout, native TMB likelihood,
extractors, diagnostics, profiles, simulation, and tests in `R/`, `src/`, and
`tests/testthat/`. The reader-facing interface and limits are synchronized in
`README.md`, `NEWS.md`, the temporal vignette, formula and likelihood design
notes, and pkgdown navigation. The campaign route lives in
`tools/run-temporal-ou-*`, `tools/slurm/`,
`tools/mirror-temporal-ou-shard-to-totoro.sh`, and the immutable-shard
summarizer. The Unlazy ledger, campaign receipts, retained local pilot/recovery
artifacts, and the check log document the evidence.

## 3a. Decisions and Rejected Alternatives

The provider uses a continuous positive-decay OU process for irregular elapsed
time and retains the optional same-ID ordinary intercept. It reports calibrated
fixed-`mu` profile intervals, rather than claiming general Hessian-based Wald
inference. ARMA, Toeplitz, random walks, seasonal and Matérn structures were
not added because each requires a distinct likelihood contract and evidence.

## 4. Files Touched

The changed implementation, test, documentation, campaign, and evidence paths
are listed in the final `git diff --name-only
57c368109d583bd15e6d75694b2835909ad68d0e..HEAD` receipt. The principal
groups are `R/`, `src/drmTMB.cpp`, `tests/testthat/`, `tools/`,
`docs/design/`, `docs/dev-log/`, `vignettes/`, `README.md`, `NEWS.md`, and
`_pkgdown.yml`.

## 5. Checks Run

- Focused `temporal-ou` and `temporal-ou-dense-oracle` tests passed before
  closeout. The final standalone campaign-assessment suite passed after the
  `sys.source()` environment repair.
- Native `R CMD build` and `R CMD check --no-manual --no-build-vignettes` ran
  all executable checks and vignette code. It ended with two expected warnings
  because vignette rebuilding was deliberately skipped; all temporal vignette
  code ran successfully.
- `vignettes/temporal-random-effects.Rmd` rendered from the exact source using
  `devtools::load_all()`. The output HTML contained the title, the irregular
  elapsed-time OU workflow, and the interval-scope section. The in-app browser
  blocks local `file:` URLs, so this was a successful rendered-structure check,
  not a visual-browser inspection.
- Fir array `58908599` produced 60 sealed archives; `sacct` reported 180
  `COMPLETED|0:0` records. All 60 were checksum-mirrored to Totoro and passed
  tar readability checks.
- Recomputing the retained 3,000-data-set campaign from immutable shard
  archives emitted `TEMPORAL_OU_PROFILE_CAMPAIGN_SUMMARY_PASS`,
  `TEMPORAL_OU_PROFILE_CAMPAIGN_QUALIFIED`, and
  `TEMPORAL_OU_G15_PASS`. The durable summary SHA-256 is
  `e303d8c3c688baf5ea3655a459d8f8215d8e85326eb6db86aa5dfb353b191cc5`.

## 8. Consistency Audit

I searched `README.md`, `NEWS.md`, `docs/dev-log/internal-roadmap.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`vignettes/formula-grammar.Rmd`, `vignettes/temporal-random-effects.Rmd`, and
`_pkgdown.yml` with:

```sh
rg -n "OU.*(point estimates only|Wald)|profile.*(uncalibrated|coverage)|temporal\\(" \
  README.md NEWS.md docs/dev-log/internal-roadmap.md \
  docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md \
  vignettes/formula-grammar.Rmd vignettes/temporal-random-effects.Rmd _pkgdown.yml
rg -n "OU therefore exposes point estimates only" README.md NEWS.md docs vignettes _pkgdown.yml
```

The obsolete point-estimate-only claim is absent. The inventory consistently
states that temporal fixed `mu` profile intervals have campaign calibration,
while OU Wald covariance and Wald intervals remain deliberately deferred.

## 6. Tests of the Tests

The campaign-assessment helper test includes one qualifying reference and four
separate failures: coverage, availability, bias, and profile-width SE analogue.
The new subprocess regression test first failed because the standalone
summarizer tried to bind its helper in the base environment; it now passes and
observes the intended missing-input diagnostic. Dense-oracle and mutation tests
separately exercise gap preservation, independent series, normalizers, and the
OU likelihood rather than only the provider output.

## 9. What Did Not Go Smoothly

The original campaign summarizer used `sys.source()` without an environment,
which caused a standalone G15 startup failure. A narrow test-first repair now
sources the pure helper in the script environment. A first temporary vignette
render also loaded the installed older package rather than the worktree; loading
the exact source resolved that environment mismatch. Fir project storage was
inode-full, so sealed archives stayed transient on Fir and were preserved on
Totoro after checksum verification.

## 11. Team Learning

For a large retained campaign, stage one immutable archive per array shard,
mirror it checksum-first to durable storage, and make the reader fail closed on
both the complete denominator and source-worker fingerprint. Test command-line
tools through their actual `Rscript` entry point: sourcing a helper inside a
test does not prove standalone execution works. The local package check should
be paired with a source-faithful vignette render when vignette rebuilding is
deliberately skipped.

### Design-doc updates

`docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and the
random-effects design material now align the symbolic OU covariance
\(s_a^2\exp(-\\lambda|t-s|)\), parser contract, implementation, extraction,
and fixed-effect profile boundary. The implementation does not promote
variance, decay, or forecast intervals.

### Pkgdown/documentation updates

The temporal vignette gives a runnable repeated-site AR1 example and an
irregular elapsed-time OU example, explains stable intercepts versus temporal
deviations and residual noise, and directs readers to profile fixed `mu`
effects. The reader documentation explicitly labels profile coverage evidence
and the continuing OU Wald limitation.

## 7a. Issue Ledger

I inspected open issue [#1302](https://github.com/itchyshin/drmTMB/issues/1302),
which already tracks phylogenetically correlated temporal OU series and a
possible separable phylogeny-by-time field. It is the requested future scope,
so no duplicate issue or comment was created.

## 10. Known Residuals

This completion covers univariate Gaussian ML temporal intercepts only, with
one OU term and an optional same-ID ordinary intercept. OU Wald `vcov()` and
Wald intervals, temporal slopes, forecasts and `newdata`, non-Gaussian
families, ARMA/Toeplitz/random-walk/seasonal/Matérn structures, and
gllvmTMB implementation remain outside this task. The next temporal extension
should start from #1302: phylogenetically correlated stable intercepts, then a
separately validated phylogeny-by-OU field.

## 12. Cross-Product Coverage

This task covers the Gaussian ML, `sigma ~ 1`, univariate temporal-intercept
cell with either OU alone or an OU term plus the same-ID ordinary intercept.
It does NOT cover REML, non-Gaussian likelihoods, temporal slopes, multiple or
labelled temporal blocks, temporal correlation across responses, missing-data
extensions, Julia/gllvmTMB bridges, forecasts, or prediction on `newdata`.
Those combinations require their own formula, likelihood, extractor, and
calibration evidence rather than inheriting this OU result.
