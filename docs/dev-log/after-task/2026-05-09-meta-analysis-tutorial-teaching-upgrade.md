# After Task: Meta-Analysis Tutorial Teaching Upgrade

## Goal

Make the meta-analysis article teach the implemented Gaussian known-covariance
path with paired equations, R syntax, fitted output, and ecological
interpretation. Keep the public API aligned with the project rule that
meta-analysis is `family = gaussian()` plus `meta_known_V(V = V)`, not
`meta_gaussian()` or `tau ~`.

## Implemented

- Rewrote `vignettes/meta-analysis.Rmd` around a worked ecological restoration
  meta-analysis.
- Added a univariate diagonal-known-variance model with equations, runnable
  data simulation, `summary(fit_meta)`, response-scale `sigma` interpretation,
  and `check_drm(fit_meta)`.
- Added a practical distinction between ordinary likelihood `weights =` and
  known sampling covariance through `meta_known_V(V = V)`.
- Clarified that repeated-study `sd(study)` syntax is schematic in this
  article and requires a repeated-row dataset such as `dat_repeated`.
- Clarified bivariate meta-analysis wording so `rho12` is the estimated
  residual correlation after known within-study sampling covariance, and only
  has a between-study interpretation when the residual component represents
  between-study heterogeneity.
- Updated `docs/design/08-meta-analysis.md` to match the vignette wording and
  to show the clean statistical transform `rho12 = tanh(eta_rho12)`, with the
  numerical boundary guard documented as an implementation detail.
- Added a `NEWS.md` bullet for the tutorial upgrade.

## Mathematical Contract

For independent known sampling variances:

```text
y_i | mu_i, sigma_i, v_i ~ Normal(mu_i, v_i + sigma_i^2)
mu_i = x_mu_i' beta_mu
log(sigma_i) = x_sigma_i' beta_sigma
```

The matching syntax is:

```r
drmTMB(
  drm_formula(
    yi ~ habitat + duration + meta_known_V(V = vi),
    sigma ~ habitat
  ),
  family = gaussian(),
  data = dat
)
```

For bivariate known sampling covariance:

```text
y_i ~ MVN(mu_i, S_i + Omega_i)
Omega_i[1, 2] = rho12_i sigma1_i sigma2_i
rho12_i = tanh(eta_rho12_i)
```

The TMB likelihood still uses a small guard before evaluating the covariance
matrix. User-facing model equations show the statistical transform; the guard
belongs in implementation notes and tests.

## Files Changed

- `vignettes/meta-analysis.Rmd`
- `docs/design/08-meta-analysis.md`
- `docs/dev-log/check-log.md`
- `NEWS.md`
- `docs/dev-log/after-task/2026-05-09-meta-analysis-tutorial-teaching-upgrade.md`

## Checks Run

```sh
Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/meta-analysis.Rmd', output_dir = tempdir(), quiet = TRUE)"
Rscript -e "devtools::test(filter = 'meta')"
git diff --check
Rscript -e "devtools::test()"
Rscript -e "pkgdown::build_site()"
Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
```

Results:

- meta-analysis vignette render: passed;
- targeted meta tests: 57 passed, 0 failed, 0 warnings, 0 skips;
- `git diff --check`: clean;
- full tests: 1215 passed, 0 failed, 0 warnings, 0 skips;
- pkgdown build: passed;
- pkgdown check: no problems found;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

The tutorial executes the implemented univariate Gaussian known-variance path,
including `summary()`, `sigma()`, and `check_drm()`. The targeted test suite
also covers diagonal and dense known-`V` likelihoods, malformed known
covariance, missing-row filtering, random-effect scale combinations, and
`meta_vcov_bivariate()`.

## Consistency Audit

Searches run:

```sh
rg -n "residual or between-study|heterogeneous heterogeneity|rho12_i = 0\\.99999999|0\\.99999999 \\* tanh|O.Dea-style|O'Dea-style|meta_gaussian|tau ~" vignettes/meta-analysis.Rmd docs/design/08-meta-analysis.md NEWS.md README.md ROADMAP.md docs/dev-log/known-limitations.md
rg -n "Mean effects and residual heterogeneity|restoration|weights = 1 / vi|coscale means|between-study residual correlation|0\\.99999999" pkgdown-site/articles/meta-analysis.html pkgdown-site/news/index.html
```

Remaining `meta_gaussian()` and `tau ~` hits are intentional guardrails against
adding those APIs. The generated meta-analysis HTML contains the new title,
restoration example, weights clarification, coscale definition, and corrected
between-study residual-correlation wording. The only generated `0.99999999`
hit is in the NEWS entry for `rho12()`, where it documents the implemented
guarded transform rather than a tutorial equation.

## What Did Not Go Smoothly

Direct `rmarkdown::render()` failed before `devtools::load_all()` because the
development package was not installed in the render process. Rendering through
`devtools::load_all()` fixed the local check, and the later pkgdown build and
R CMD check both rebuilt the vignette successfully.

Pat's user review caught that the repeated-study `sd(study)` section could
look executable against the earlier one-row-per-study simulated data. The
article now names that section as schematic and uses `dat_repeated` in the
code block.

## Team Learning

- Ada should continue staggering tutorial edits with a Pat-style user review
  before broad checks.
- Noether should keep public equations clean and move numerical safeguards
  into implementation prose unless the safeguard changes the statistical
  interpretation.
- Rose should search design docs as well as vignettes, because ambiguous
  wording can survive in design notes after the user-facing page is fixed.

## Known Limitations

- The restoration example is simulated, not a real meta-analysis dataset.
- The repeated-study `sd(study)` example is schematic in this article.
- Bivariate known-`V` fitting remains dense and complete-row only.
- Sparse covariance, missing single outcomes in bivariate meta-analysis, and
  non-unit weights with dense full `V` need separate design and tests.

## Next Actions

1. Add a small real-data or paper-matched meta-analysis vignette when a stable
   public dataset is selected.
2. Add a compact plot of mean effects and response-scale heterogeneity for the
   restoration example.
3. Design the sparse known-covariance path before using this tutorial for large
   phylogenetic or spatial meta-analysis examples.
