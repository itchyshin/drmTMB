# After Task: Scale Tutorial Output Upgrade

## Goal

Upgrade the scale-comparison tutorial so applied users can see each modelling
choice as equations, R syntax, fitted output, and interpretation.

## Implemented

- Added a copy-run scale audit to `vignettes/which-scale.Rmd`.
- Added executed examples for:
  - residual scale, `sigma ~ temperature`;
  - likelihood row weights, `weights = reliability`;
  - known sampling variance, `meta_known_V(V = vi)`;
  - random-effect scale, `sd(population) ~ habitat`;
  - residual coscale, `rho12 ~ treatment`.
- Added `summary()`, `coef()`, `sigma()`, `weights()`,
  `predict(..., dpar = "sd(population)")`, and `rho12()` output where each
  extractor helps the reader interpret the fitted model.
- Moved the tiny internal `rho12` numerical guard out of the tutorial symbolic
  table and into an implementation-detail note.
- Made the README bivariate equation use the same teaching notation,
  `rho12_i = tanh(eta_rho12_i)`, with a short guard explanation after the
  equation.
- Made matching teaching-notation updates in the getting-started article and
  the adding-families developer article.
- Added a NEWS entry for the tutorial upgrade.

## Mathematical Contract

The tutorial now separates five quantities:

```text
sigma ~ x
  log(sigma_i) = X_sigma[i, ] beta_sigma
```

```text
weights = w
  logLik = sum_i w_i log f(y_i | theta_i)
```

```text
meta_known_V(V = V)
  y ~ MVN(mu, V + Omega_est)
```

```text
sd(group) ~ x_group
  log(sd_mu_group,j) = W_group[j, ] alpha_group
```

```text
rho12 ~ x
  rho12_i = tanh(X_rho12[i, ] beta_rho12)
```

The exact C++ guard for `rho12` remains documented as an implementation detail,
not the teaching equation.

## Files Changed

- `vignettes/which-scale.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/adding-families.Rmd`
- `README.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale|biv-gaussian|meta-known-v|random-effect-scale')"`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/drmTMB.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/adding-families.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n '0\\.99999999 \\* tanh|rho12_i = 0\\.99999999|tiny guard|scale audit|weights = reliability|meta_known_V\\(V = vi\\)' README.md vignettes pkgdown-site/index.html pkgdown-site/articles/which-scale.html docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-09-scale-tutorial-output-upgrade.md`

Current results:

- Changed tutorial rendered successfully.
- Getting-started and adding-families vignettes rendered successfully after
  the extra guard-notation cleanup.
- Targeted neighbouring tests: 268 passed.
- Full `devtools::test()`: 1215 passed.
- `pkgdown::check_pkgdown()` found no problems before and after site build.
- `pkgdown::build_site()` completed.
- `tools/fix-pkgdown-favicon-mime.R` completed.
- Final `devtools::check()` completed with 0 errors, 0 warnings, and 0 notes.
- Final post-cleanup `devtools::check()` completed with 0 errors, 0 warnings,
  and 0 notes.
- `git diff --check` is clean.

## Tests Of The Tests

- The executed tutorial chunks fit models that use the same neighbouring
  likelihood paths covered by targeted tests.
- The rendered tutorial confirms that outputs appear on the page, not only in
  source code.
- The bivariate section checks both link-scale `coef(fit, "rho12")` output and
  response-scale `rho12(fit)` output.

## Consistency Audit

- The tutorial uses `sigma`, `sd(population)`, `weights =`, `meta_known_V(V =
  V)`, and `rho12` consistently with `AGENTS.md`.
- The README now uses the readable `rho12_i = tanh(eta_rho12_i)` teaching
  equation and describes the guard separately.
- NEWS records the user-facing documentation change.
- `pkgdown::build_site()` regenerated the article and the site passed
  `pkgdown::check_pkgdown()`.
- Stale-guard scan found no exact `0.99999999 * tanh()` display in the README,
  `which-scale` source, site home page, or rendered `which-scale` article.
  Remaining exact-guard mentions are in historical log entries and
  implementation/developer contexts.

## What Did Not Go Smoothly

The earlier README still displayed the exact `0.99999999 * tanh()` guard inside
the symbolic bivariate equation. That was technically true but pedagogically
too distracting, so the README now mirrors the tutorial: clean teaching
equation first, implementation guard second.

## Team Learning

- Pat should keep pushing for tutorials that show output and interpretation,
  not just syntactically valid examples.
- Darwin should keep ecological examples concrete while leaving the package
  generally useful outside biology.
- Noether should police the distinction between mathematical teaching notation
  and exact guarded numerical implementation.
- Rose should search both source vignettes and top-level README pages when a
  wording issue appears in one public page.

## Known Limitations

- The scale audit uses simulated data. A future tutorial should add a fuller
  real-data or paper-style ecological example.
- The page still has no plots; tables and output are enough for this phase, but
  later tutorials should add compact visual summaries.
- The exact `rho12` guard still appears in design notes and source-map style
  pages where implementation detail is appropriate.

## Next Actions

1. Add a fuller tutorial with plots and biological interpretation for Gaussian
   location-scale models.
2. Add a fuller bivariate coscale tutorial with `summary()`, `rho12()`,
   `corpairs()`, and a response-scale interpretation table.
3. Consider a short FAQ entry: "Should I use `weights`, `meta_known_V`,
   `sigma`, or `sd(group)`?"
