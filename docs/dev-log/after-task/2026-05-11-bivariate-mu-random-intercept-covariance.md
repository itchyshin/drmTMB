# After Task: Bivariate Mu Random-Intercept Covariance

## Goal

Resume the crashed `codex/biv-species-mu-covariance` work and finish the first
bivariate Gaussian group-level covariance slice without widening the package
beyond one-response and two-response models.

## Implemented

- `biv_gaussian()` now accepts matching labelled random-intercept terms in the
  `mu1` and `mu2` formulas, for example `(1 | p | id)` in both formulas.
- The bivariate builder strips those terms before fixed-effect model matrices
  are built, validates that the two responses use one matching intercept term,
  the same group, and the same non-empty covariance-block label, then builds a
  two-column `u_mu` structure.
- The TMB bivariate Gaussian branch adds the two group-level location effects
  before evaluating the residual bivariate likelihood.
- `sdpars$mu`, `corpars$mu`, `ranef()`, `predict()`, `fitted()`, and
  `corpairs()` now expose the fitted bivariate `mu1`/`mu2` random-intercept
  covariance block while keeping residual `rho12` separate.
- Bivariate random slopes, random effects in `sigma1`, `sigma2`, or `rho12`,
  structured covariance, and `meta_known_V(V = V)` plus bivariate random
  effects still reject before optimization.

## Mathematical Contract

For group `j`, the implemented random-intercept block is

```text
[b1_j, b2_j]' = diag(sd_mu1_id, sd_mu2_id) L_group [u1_j, u2_j]'
[u1_j, u2_j]' ~ Normal([0, 0]', I)
L_group =
  [1,          0;
   rho_group, sqrt(1 - rho_group^2)]
rho_group = 0.999999 * tanh(eta_cor_mu)
```

The row likelihood still uses residual `rho12_i` in
`Omega_i[1,2] = rho12_i sigma1_i sigma2_i`. The group-level `rho_group` is not
residual `rho12`.

## Files Changed

- Core implementation: `R/drmTMB.R`, `R/methods.R`, `src/drmTMB.cpp`.
- Tests: `tests/testthat/test-biv-gaussian.R`,
  `tests/testthat/test-gaussian-random-intercepts.R`.
- Generated reference docs: `man/drmTMB.Rd`, `man/corpairs.Rd`,
  `man/predict.drmTMB.Rd`.
- User and design docs: `README.md`, `NEWS.md`, `ROADMAP.md`,
  `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
  `docs/design/03-likelihoods.md`, `docs/design/04-random-effects.md`,
  `docs/design/17-correlated-random-effect-blocks.md`,
  `docs/design/20-coscale-correlation-pairs.md`,
  `docs/design/28-double-hierarchical-endpoint.md`,
  `vignettes/bivariate-coscale.Rmd`, `vignettes/distribution-families.Rmd`,
  `vignettes/drmTMB.Rmd`, `vignettes/formula-grammar.Rmd`,
  `vignettes/source-map.Rmd`, and `vignettes/which-scale.Rmd`.

## Checks Run

- `Rscript -e "devtools::load_all(quiet = TRUE)"`: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with 123
  expectations.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|gaussian-random-intercepts|corpairs')"`:
  passed with 338 expectations.
- `air format R/drmTMB.R R/methods.R tests/testthat/test-biv-gaussian.R tests/testthat/test-gaussian-random-intercepts.R README.md NEWS.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/04-random-effects.md docs/design/17-correlated-random-effect-blocks.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md vignettes/bivariate-coscale.Rmd vignettes/distribution-families.Rmd vignettes/drmTMB.Rmd vignettes/formula-grammar.Rmd vignettes/source-map.Rmd vignettes/which-scale.Rmd`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated the changed
  Rd files.
- `Rscript -e "devtools::test()"`: passed with 1669 expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `Rscript -e "pkgdown::build_home()"`: passed after the final ROADMAP wording
  update.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed again with no problems found.
- `git diff --check`: passed.

## Tests Of The Tests

- The new simulation test fits a labelled bivariate `mu1`/`mu2` random
  intercept block from known SDs, a known group-level correlation, and a
  separate residual `rho12`.
- The test checks convergence, fixed effects, residual scales, group-level SDs,
  group-level correlation, residual `rho12`, conditional fitted predictions,
  population-level `newdata` predictions, `ranef()` sizing, and `corpairs()`
  row semantics.
- Negative tests cover one-sided random terms, matching unlabelled terms,
  mismatched covariance labels, bivariate random slopes, structured terms, and
  `meta_known_V(V = V)` plus bivariate random effects.

## Consistency Audit

- `rg -n 'bivariate random effects planned|Bivariate group-level random effects and double-hierarchical correlation pairs are planned only|Random effects remain future work|shared bivariate .*remain future|no bivariate random effects|bivariate `mu1`/`mu2` random effects are later|Random effects in bivariate `mu1`' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes man pkgdown-site --glob '!pkgdown-site/search.json'`:
  no matches after the final docs and generated-site update.
- `rg -n 'matching labelled|mu1.*mu2.*random-intercept|cor\(mu1:\(Intercept\),mu2:\(Intercept\)|rho12.*group-level' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man pkgdown-site --glob '!pkgdown-site/search.json'`:
  confirmed the new implemented-scope wording in source docs, generated docs,
  and tests.
- `rg -n 'rho ~|meta_gaussian|tau ~|meta_known_V\([^V]' README.md ROADMAP.md NEWS.md docs vignettes R tests man pkgdown-site --glob '!docs/dev-log/after-task/*' --glob '!pkgdown-site/search.json'`:
  remaining hits are guardrails, historical check-log entries, or intentional
  meta-analysis wording; no new `rho ~`, `meta_gaussian()`, or `tau ~` syntax
  was introduced.

## What Did Not Go Smoothly

- The crash left `R/drmTMB.R` half-wired: the bivariate builder had started to
  pass `re_mu`, but `biv_gaussian_start()`, `biv_gaussian_map()`, the TMB data
  branch, the C++ likelihood branch, and the extractors still ignored it.
- One stale-wording scan initially used backticks inside a double-quoted shell
  pattern, which triggered shell command substitution. The scan was rerun with
  single quotes before recording the audit result.
- The ROADMAP source was corrected after the full pkgdown site build, so
  `pkgdown::build_home()` was rerun to refresh `pkgdown-site/ROADMAP.html`.

## Team Learning

- For future bivariate covariance work, finish the data contract in this order:
  R formula extraction, TMB data, start values, map, C++ likelihood, splitters,
  prediction, `corpairs()`, simulation recovery, then docs.
- Keep requiring an explicit covariance-block label for cross-response random
  effects. It prevents unlabelled `(1 | id)` from silently changing meaning
  between univariate and bivariate models.
- Rose should always scan generated pkgdown pages after source docs change;
  source-only scans missed one rendered ROADMAP sentence until `build_home()`
  refreshed it.

## Known Limitations

- Only matching labelled bivariate random intercepts in `mu1` and `mu2` are
  implemented.
- Bivariate random slopes, random effects in `sigma1`, `sigma2`, or `rho12`,
  structured bivariate covariance, and bivariate `meta_known_V(V = V)` plus
  random effects remain planned.
- Profile intervals for the new group-level bivariate SDs and correlation use
  the existing direct-parameter machinery where applicable, but derived
  interval summaries were not expanded in this task.

## Next Actions

- Done in
  `docs/dev-log/after-task/2026-05-11-bivariate-mu-covariance-check-drm-diagnostics.md`:
  add `check_drm()` diagnostics specific to bivariate group-level covariance,
  especially weak SDs and poorly replicated groups.
- Add profile-target coverage for the new bivariate group-level SD and
  correlation labels if the existing inventory does not expose the exact names
  users need.
- Keep bivariate random slopes as the next covariance expansion only after a
  separate simulation plan is written.
