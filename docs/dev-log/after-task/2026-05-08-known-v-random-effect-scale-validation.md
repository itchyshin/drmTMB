# After Task: Known-V Random-Effect Scale Validation

## Goal

Validate the implemented univariate Gaussian meta-analysis path where known
sampling variances are combined with an ordinary `mu` random intercept and a
random-effect scale formula.

## Implemented

- Added a targeted test for:

```r
drmTMB(
  drm_formula(
    yi ~ x + (1 | id) + meta_known_V(V = vi),
    sigma ~ 1,
    sd(id) ~ w
  ),
  family = gaussian(),
  data = dat
)
```

- Updated `docs/design/08-meta-analysis.md` to describe this combination as
  implemented and independently validated.
- Updated `vignettes/source-map.Rmd`, `ROADMAP.md`, and `NEWS.md` so status
  wording matches the new test coverage.
- Kept the source-map caution that this should become a headline tutorial
  example only after the interpretation is written carefully.

## Mathematical Contract

For observation `i` in group `g(i)`:

```text
y_i = x_i' beta + u_{g(i)} + e_i
u_g ~ Normal(0, sd_g^2)
sd_g = exp(a_0 + a_1 w_g)
e_i ~ Normal(0, v_i + sigma_i^2)
sigma_i = exp(z_i' gamma)
```

The marginal covariance used by the independent test is:

```text
Omega = diag(v_i + sigma_i^2) + Z diag(sd_g^2) Z'
```

The test compares the fitted log likelihood to a separate dense multivariate
normal calculation using this `Omega`.

## Files Changed

- `tests/testthat/test-meta-known-v.R`
- `docs/design/08-meta-analysis.md`
- `vignettes/source-map.Rmd`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-known-v-random-effect-scale-validation.md`

## Checks Run

- `Rscript -e "devtools::test(filter = '^meta-known-v$')"`: 40 passed, 0
  failed.
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`:
  passed.
- `Rscript -e "devtools::test()"`: 646 passed, 0 failed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.
- `rg -n 'meta_gaussian\\(\\)|tau ~|still need explicit validation|still needs validation|routine tutorial syntax|planned.*implemented|only diagonal' README.md ROADMAP.md NEWS.md docs vignettes tests`:
  no active obsolete "still needs validation" caveat; remaining hits are
  intentional guardrails, true planned features, or historical check-log and
  after-task records.
- `rg -n 'meta_known_V|sd\\(id\\)|sd\\(group\\)|known-covariance|known sampling' NEWS.md ROADMAP.md docs/design/08-meta-analysis.md vignettes/source-map.Rmd docs/dev-log/known-limitations.md`:
  status wording is synchronized across NEWS, roadmap, design docs, source map,
  and known limitations.
- `Rscript -e "pkgdown::build_site()"`: completed successfully.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

The new test does not only check that the fit converges. It recomputes the
dense marginal Gaussian log likelihood outside the TMB objective and checks it
against `logLik(fit)` to a tolerance of `1e-6`.

## Consistency Audit

- `meta_known_V(V = vi)` remains a covariance marker inside the Gaussian model,
  not a separate meta-analysis family.
- No `meta_gaussian()` or `tau ~` syntax was introduced.
- `sigma` remains residual heterogeneity.
- `sd(id)` remains group-level random-effect heterogeneity in the `mu` model.
- `rho12` terminology is untouched; bivariate meta-analysis remains a separate
  design and implementation target.

## What Did Not Go Smoothly

The source map showed that the ingredients were already implemented but the
specific combination was not independently tested. That is exactly the kind of
forest-and-trees discrepancy the after-task protocol is meant to catch.

## Team Learning

- Jason's source-map scan should remain part of model-surface expansion work.
- Rose's audit checklist should continue to require status updates in NEWS,
  ROADMAP, design docs, and vignettes whenever "planned" becomes "validated."
- Fisher's comparator principle worked well here: the new test compares
  against an independent dense likelihood rather than merely asserting
  convergence.

## Known Limitations

- The validation is for univariate Gaussian known sampling variances plus
  `sd(id) ~ w`.
- Sparse known covariance, bivariate known-covariance meta-analysis, and
  random-effect scale models for bivariate targets remain future work.
- The test is intentionally small and is not a benchmark for large
  meta-analytic covariance matrices.

## Next Actions

- Commit and push the validation checkpoint.
- Watch pkgdown and R CMD check on GitHub Actions.
- Continue with the next small phase only after CI is green.
