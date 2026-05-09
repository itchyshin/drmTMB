# After Task: Family Link and Response-Scale Contract

## Goal

Create a design contract that prevents future Gamma, count, beta, and ordinal
families from accidentally inheriting Gaussian identity-link assumptions.

## Implemented

- Added `docs/design/19-family-link-contract.md`.
- Updated the family registry with native-parameter, fitted-response, and
  variance-rule requirements.
- Updated the distribution roadmap with link-contract caveats for counts,
  proportions, and Gamma.
- Updated the adding-families vignette with a "do not assume identity links"
  section.
- Updated the roadmap to make the family-link contract a prerequisite for
  non-Gaussian family growth.
- Updated the project-local `add-family` skill so future family tasks ask for
  native parameter meanings, fitted-response rules, variance rules, and
  prediction/fitted tests.

## Mathematical Contract

The design separates:

```text
linear predictor -> inverse link -> distributional parameter
distributional parameter(s) -> fitted response summary
```

Implemented examples:

```text
Gaussian:   predict(mu) = E[y] = fitted()
Student-t:  predict(mu) = location; fitted() currently returns mu
Lognormal:  predict(mu) = E[log(y)]; fitted() = exp(mu + sigma^2 / 2)
```

Candidate Gamma contract:

```text
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
E[y_i] = mu_i
Var[y_i] = mu_i^2 sigma_i^2
```

This keeps `sigma` as a coefficient of variation, not a residual standard
deviation.

## Files Changed

- `docs/design/19-family-link-contract.md`
- `docs/design/02-family-registry.md`
- `docs/design/06-distribution-roadmap.md`
- `ROADMAP.md`
- `vignettes/adding-families.Rmd`
- `.agents/skills/add-family/SKILL.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-family-link-response-scale-contract.md`

## Checks Run

- `Rscript -e "rmarkdown::render('vignettes/adding-families.Rmd', output_dir = tempdir(), quiet = TRUE); cat('rendered adding-families\\n')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `sed -n '1,180p' .agents/skills/add-family/SKILL.md`

Results:

- adding-families vignette rendered successfully.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: clean.
- Hegel read-only review found no P0/P1 issues. P2/P3 consistency findings
  were fixed before closing the task.

## Tests Of The Tests

This was a design-only slice, so no likelihood tests were added. The direct
vignette render checks that the new contributor-facing equations and prose
compile.

## Consistency Audit

- The family registry and the new link contract now list the same future
  contract fields.
- The adding-families bivariate equation now uses the implemented guarded
  `rho12 = 0.99999999 * tanh(eta_rho12)` transform.
- The beta roadmap now says the scale or precision parameter name is undecided
  rather than implying `sigma` is already settled.
- The `sigma()` rule explicitly covers bivariate `sigma1` and `sigma2`.
- The project-local add-family skill now mirrors the new contract fields.

## What Did Not Go Smoothly

The first draft treated the new link contract as an add-on but did not update
the older required-fields list in the family registry. Hegel caught that, along
with one stale unguarded `rho12` equation.

## Team Learning

Design notes create obligations elsewhere. When a note says a future family
"must declare" something, Emmy and Rose should immediately check the registry,
developer vignette, roadmap, and add-family skill for the same requirement.

## Known Limitations

- This task did not implement a new likelihood.
- Gamma, count, beta, and ordinal parameterizations remain design proposals
  until each has code, simulation recovery tests, method support, and docs.

## Next Actions

- Use this contract before implementing `gamma()` or `nbinom2()`.
