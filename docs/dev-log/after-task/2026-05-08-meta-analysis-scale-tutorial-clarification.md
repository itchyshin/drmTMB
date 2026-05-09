# After Task: Meta-Analysis Scale Tutorial Clarification

## Goal

Make the meta-analysis documentation clear about the difference between known
sampling covariance, residual heterogeneity, and group-level random-effect
heterogeneity.

## Implemented

- Added a `vignettes/meta-analysis.Rmd` section for
  `meta_known_V(V = V)` plus `(1 | study)` and `sd(study) ~ habitat`.
- Added paired symbolic equations for:
  - known sampling covariance `V`;
  - residual heterogeneity `sigma`;
  - study-level random-effect scale `omega_j`.
- Updated `docs/design/08-meta-analysis.md` to remove stale validation wording
  and add the marginal covariance equation.
- Updated `vignettes/source-map.Rmd` to state that the combination now has both
  a targeted validation test and a tutorial explanation.

## Mathematical Contract

The tutorial model is:

```text
y_i = mu_i + b_study[j[i]] + r_i + s_i
mu_i = X_mu[i, ] beta_mu
b_study,j ~ Normal(0, omega_j^2)
log(omega_j) = a0 + a1 habitat_j
r_i ~ Normal(0, sigma^2)
s ~ MVN(0, V)
```

The marginal covariance is:

```text
Omega = V + diag(sigma_i^2) + Z_study diag(omega_j^2) Z_study'
y ~ MVN(mu, Omega)
```

This keeps `V`, `sigma`, and `sd(study)` as three distinct quantities.

## Files Changed

- `vignettes/meta-analysis.Rmd`
- `docs/design/08-meta-analysis.md`
- `vignettes/source-map.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-meta-analysis-scale-tutorial-clarification.md`

## Checks Run

- `Rscript -e "rmarkdown::render('vignettes/meta-analysis.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`:
  passed.
- `rg -n 'remain a separate validation task|still needs validation|after adding the known sampling variance|after adding known sampling|sampling error that is known|The$|Normal\\(a, b\\) again' vignettes/meta-analysis.Rmd docs/design/08-meta-analysis.md vignettes/source-map.Rmd NEWS.md ROADMAP.md docs/dev-log/known-limitations.md`:
  no active hits.
- `git diff --check`: clean.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "devtools::test()"`: 646 passed, 0 failed.
- `Rscript -e "pkgdown::build_site()"`: completed successfully and rebuilt
  `articles/meta-analysis.html` and `articles/source-map.html`.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

No new unit test was added because no model code changed. The documentation now
points to the existing independent dense marginal-likelihood comparator for
known sampling variance plus `sd(id) ~ w`.

## Consistency Audit

- No `meta_gaussian()` family was introduced.
- No `tau ~` formula was introduced.
- `sigma` is described as residual heterogeneity.
- `sd(study)` is described as group-level heterogeneity in the location random
  effect.
- The design note and tutorial now agree that the implemented univariate
  Gaussian known-covariance path supports this combination.

## What Did Not Go Smoothly

The previous validation task left one stale design sentence behind. Pat and
Fisher/Noether both caught it immediately because it affected whether a user
would know the syntax was safe to try.

## Team Learning

- Pat should continue reviewing tutorials from the perspective of a first-time
  applied user.
- Noether should review every known-`V` plus random-effect-scale example for a
  matching marginal covariance equation.
- Rose should keep stale-status searches focused on active docs, not only
  after-task history.

## Known Limitations

- Sparse known covariance remains planned.
- Bivariate known-covariance models with random-effect scale formulas remain
  planned.
- This task improved explanation; it did not expand the likelihood.

## Next Actions

- Commit and push if clean.
- Watch CI before starting another implementation phase.
